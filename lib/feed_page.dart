import 'dart:async';

import 'package:app/app.dart';
import 'package:app/main.dart';
import 'package:app/model/post.dart';
import 'package:app/model/user.dart';
import 'package:app/state.dart';
import 'package:app/widget/create_post.dart';
import 'package:app/widget/login_hint.dart';
import 'package:app/widget/notifications.dart';
import 'package:app/widget/post.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class FeedPage extends StatefulWidget {
  final String userId;
  final String postId;
  final bool showBackButton;
  final double sidePadding;
  final bool isNotificationsPage;

  FeedPage(
    this.userId,
    this.postId, {
    this.isNotificationsPage = false,
    this.showBackButton = false,
    this.sidePadding = 0,
    Key key,
  }) : super(key: key);

  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  bool get isMobile => rd.isMobile;

  List<Post> posts;

  // ScrollController _controller;
  //PageStorageBucket bucket;

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
/*     bucket = PageStorageBucket(); */
/*     _controller = ScrollController(
      //initialScrollOffset: 100
      keepScrollOffset: true,
    ); */

    bool _isItemScrollInitialized = false;

    //final localKey = '${widget.userId}/${widget.postId}';

    itemPositionsListener.itemPositions.addListener(() {
      itemPositions = itemPositionsListener.itemPositions.value.toList();
      if (itemScrollController.isAttached) {
        if (_isItemScrollInitialized) {
          rd.setScrollCache(itemPositionsListener.itemPositions.value.first);
        } else {
          _isItemScrollInitialized = true;

          if (!rd.isMobile) {
            final item = rd.scrollCache;

            if (item != null)
              itemScrollController.jumpTo(
                index: item.index,
                alignment: item.itemLeadingEdge,
              );
          }
        }
      }
    });

    _loadFeedData();
    /* _controller.addListener(() {
      print('pos ${_controller.position.keep}');
    }); */

    super.initState();
  }

  List<ItemPosition> itemPositions = [];

  void _handleKeyEvent(RawKeyEvent event) {
    final currentItem = itemPositions.firstWhere(
        (element) => element.itemLeadingEdge >= 0,
        orElse: () => null);

    var index = currentItem?.index ?? 0;
    var alignment = currentItem?.itemLeadingEdge ?? 0;

    // print('$index align $alignment');

    int newIndex;

    if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
      //setState(() {
      /*    _controller.animateTo(offset - 200,
          duration: Duration(milliseconds: 30), curve: Curves.ease); */
      //});
      if (index > 2) {
        newIndex = index - 1;
      } else {
        newIndex = 0;
      }
      /*     itemScrollController.scrollTo(
          alignment: 0.02,
          //alignment: alignment - 0.1,
          duration: Duration(milliseconds: 100),
        ); */
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
      if (index == 0) {
        newIndex = 2;
      } else {
        newIndex = index + 1;
      }
    }

    if (newIndex != null) {
      itemScrollController.scrollTo(
        index: newIndex,
        alignment: 0.02,
        //alignment: alignment + 0.1,
        duration: Duration(milliseconds: 100),
      );
    }
  }

  final int localId = dp.getLocalId();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    if (userFeedSub != null) userFeedSub.cancel();
    if (mainFeedSub != null) mainFeedSub.cancel();
    if (notificationsSub != null) notificationsSub.cancel();

    if (userSub != null) {
      userSub.cancel();

      dp.removeProfileStream(widget.userId, localId);
    }
    // _controller.dispose();

    super.dispose();
  }

  StreamSubscription userFeedSub;
  StreamSubscription mainFeedSub;
  StreamSubscription notificationsSub;

  StreamSubscription userSub;

  bool isCommentView = false;

  void _loadFeedData() async {
    print('_loadFeedData ${widget.userId}  ${widget.postId}');

    if (widget.userId != null) {
      if (widget.postId != null) {
        dp.log('feed/comments', widget.postId);

        isCommentView = true;

        posts = [
          await dp.getPost('${widget.userId}/feed/${widget.postId}'),
        ];

        setState(() {});
      } else {
        // ! User Feed
        loadCurrentUserFeedData();

        userFeedSub = dp.getFeedStream(userId: widget.userId).listen((_) {
          loadCurrentUserFeedData();
        });

        // print(dp.isFollowingUserPubliclyOrPrivately(widget.userId));

        if (!dp.isFollowingUserPubliclyOrPrivately(widget.userId)) {
          final User initialUser = users.get(widget.userId);

          if (initialUser?.skyfeedId == null) {
            userSub =
                dp.getProfileStream(widget.userId, localId).listen((event) {
              dp.checkFollowingUpdater();
            });
          }

          dp.addTemporaryUserForFeedPage(widget.userId);

          // TODO getProfileStream, then recheck

        }
      }
    } else {
      if (widget.isNotificationsPage) {
        // ! Notifications Page
        loadNotificationsData();

        mainFeedSub = dp.onNotificationsChange.stream.listen((_) {
          loadNotificationsData();
        });
      } else {
        // ! Home Feed
        loadHomeFeedData();

        mainFeedSub = dp.getFeedStream(userId: '*').listen((_) {
          loadHomeFeedData();
        });

        dp.checkFollowingUpdater();
      }
    }
  }

  void loadHomeFeedData() async {
    print('loadHomeFeedData');

    List<Post> tmpPosts = [];

    Future<void> loadUser(String userId) async {
      final int currentPostsPointer =
          pointerBox.get('${userId}/feed/posts') ?? 0;

      for (int i = currentPostsPointer; i > currentPostsPointer - 2; i--) {
        if (i < 0) continue;

        dp.log('feed/home/loadFeed', '$userId/feed/posts/$i');
        final Feed fp = await feedPages.get('${userId}/feed/posts/$i');

        if (fp != null) {
          fp.items.forEach((p) {
            p.feedId = 'posts/$i';
            p.userId = fp.userId;
          });
          tmpPosts.addAll(fp.items);
        }
      }
    }

    final futures = <Future>[];

    for (final userId in dp.getFollowKeys()) {
      futures.add(loadUser(userId));
    }

    await Future.wait(futures);

    tmpPosts.removeWhere((element) => element.isDeleted == true);
    tmpPosts.sort((a, b) => b.postedAt.compareTo(a.postedAt));

    if (posts?.length == tmpPosts.length) return; // TODO Better checksum :D

    posts = tmpPosts;

    print('loadHomeFeedData setState');

    if (mounted) setState(() {});
  }

  void loadNotificationsData() async {
    print('loadNotificationsData');

    List<Post> tmpPosts = [];

    for (final userId in dp.requestFollow.keys) {
      tmpPosts.add(Post()..followNotificationFor = userId);
    }

    for (final fullPostId in dp.requestMention.keys) {
      tmpPosts.add(Post()..mentionOf = fullPostId);
    }

    if (posts?.length == tmpPosts.length) return; // TODO Better checksum :D

    posts = tmpPosts;

    print('loadHomeFeedData setState');

    if (mounted) setState(() {});
  }

  void loadCurrentUserFeedData() async {
    dp.log('feed/user', 'load');

    List<Post> tmpPosts = [];

    final int currentPostsPointer =
        pointerBox.get('${widget.userId}/feed/posts') ?? 0;

    for (int i = currentPostsPointer; i > currentPostsPointer - 2; i--) {
      if (i < 0) continue;

      dp.log('feed/user', 'load ${widget.userId}/feed/posts/$i');

      final Feed fp = await feedPages.get('${widget.userId}/feed/posts/$i');

      if (fp != null) {
        fp.items.forEach((p) {
          p.feedId = 'posts/$i';
          p.userId = widget.userId;
        });

        tmpPosts.addAll(fp.items);

        dp.log('feed/user', 'add ${fp.items.length} items');
      }
    }
    tmpPosts.removeWhere((element) => element.isDeleted == true);
    tmpPosts.sort((a, b) => b.postedAt.compareTo(a.postedAt));

    if (posts?.length == tmpPosts.length) return; // TODO Better checksum :D

    posts = tmpPosts;

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (posts == null)
      return Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Align(
          alignment: Alignment.topCenter,
          child: CircularProgressIndicator(),
        ),
      );

    int itemCount = widget.postId != null ? 1 : posts.length;

    if (isMobile) {
      if (widget.userId != null && widget.postId == null) {
        itemCount++;
      }
    } else {
      if (widget.userId == null && !rd.isNotificationsPage) {
        itemCount++;
      }
      if (widget.showBackButton) {
        itemCount++;
      }
    }
    /* itemCount++; */

    print('[build] FeedPage ${widget.userId}');

    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: _handleKeyEvent,
      child: ScrollablePositionedList.separated(
        // key: PageStorageKey('list-${widget.userId}-${widget.postId}'),
        padding: EdgeInsets.only(
          top: (isMobile || widget.showBackButton) ? 0 : 32,
          left: widget.sidePadding,
          right: widget.sidePadding,
        ),
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        // controller: _controller,
        itemCount: itemCount, // TODO +1
        itemBuilder: (context, index) {
          if (widget.showBackButton && !rd.isMobile) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: SizedBox(
                  height: 24,
                  child: InkWell(
                    borderRadius: borderRadius,
                    onTap: () {
                      /*   if (rd.currentConfiguration.isPostPage) {
                        rd.setUserId(rd.selectedUserId);
                      } else { */

                      if (rd.history.length <= 1) {
                        rd.setHomePage();
                      } else {
                        rd.pop();
                      }

                      //}
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          UniconsLine.arrowLeft,
                          color: SkyColors.follow,
                          size: 22,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 1.0),
                          child: Text(
                            'Back',
                            style: TextStyle(
                              color: SkyColors.follow,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            index--;
          }
/*         if (index == 0) {
            return Text(widget.userId.toString());
          }
           */

          if (isMobile) {
            if (widget.userId != null && widget.postId == null) {
              if (index == 0) {
                return ContextPage();
              }
              index--;
            }
          } else {
            if (widget.userId == null && !rd.isNotificationsPage) {
              if (index == 0) {
                if (AppState.userId == null) {
                  return LoginHintWidget();
                } else {
                  return CreatePostWidget();
                }
              }
              index--;
            }
          }

          final p = posts[index];

          if (p.followNotificationFor != null) {
            return NotificationUserFollowWidget(
              userId: p.followNotificationFor,
            );
          }

          if (p.repostOf != null || p.mentionOf != null) {
            return FutureBuilder<Post>(
              future: dp.getPost(p.repostOf ?? p.mentionOf),
              builder: (context, snapshot) {
                if (snapshot.data == null)
                  return Container(
                    decoration: getCardDecoration(context),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Loading post...',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );

                print(snapshot.data.commentTo);

                if (p.mentionOf != null) {
                  return Stack(
                    children: [
                      PostWidget(
                        snapshot.data,
                        key: ValueKey(snapshot.data.fullPostId),
                        showMentionContext: true,
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: InkWell(
                          onTap: () async {
                            await dp.mention(
                              p.mentionOf,
                              AppState.userId,
                              remove: true,
                            );
                          },
                          child: Material(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(4),
                              topRight: Radius.circular(8),
                            ),
                            color: SkyColors.red,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return PostWidget(
                  snapshot.data,
                  key: ValueKey(snapshot.data.fullPostId),
                  repost: p,
                );
              },
            );
          }

          return PostWidget(
            p,
            showComments: isCommentView,
            key: ValueKey(p.fullPostId),
          );
        },
        separatorBuilder: (context, index) {
          if (isMobile) {
            return Divider(
              height: 1,
              thickness: 1,
            );
          } else {
            if (index == 0 && !rd.currentConfiguration.isHomePage) {
              return SizedBox();
            } else {
              return SizedBox(
                height: 12,
              );
            }
          }
        },
      ),
    );
  }
}
