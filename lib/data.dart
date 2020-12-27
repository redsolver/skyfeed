import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:app/model/post.dart';
import 'package:app/model/user.dart';
import 'package:app/state.dart';
import 'package:app/global.dart';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:skynet/skynet.dart';

import 'package:app/utils/string.dart';

// Every second in Data map
// Every minute on SkyDB (when changes)

const $skyfeedFollowing = 'skyfeed-following';
const $skyfeedPrivateFollowing = 'skyfeed-following-private';

const $skyfeedFollowers = 'skyfeed-followers';

const $skyfeedReactions = 'skyfeed-reactions';

const $skyfeedSaved = 'skyfeed-saved';

const $skyfeedMediaPositions = 'skyfeed-media-positions';

const $skyfeedUser = 'skyfeed-user';

const $skyfeedRequestFollow = 'skyfeed-req-follow-';
const $skyfeedRequestMention = 'skyfeed-req-mention-';

class DataProcesser {
  Future<void> init() async {
    Hive.registerAdapter(UserAdapter());

    Hive.registerAdapter(FeedAdapter());
    Hive.registerAdapter(PostAdapter());
    Hive.registerAdapter(PostContentAdapter());

    dataBox = await Hive.openBox('data');

    users = await Hive.openBox('users');
    followingBox = await Hive.openLazyBox('following');
    followersBox = await Hive.openLazyBox('followers');
    feedPages = await Hive.openLazyBox('feedPages');

    cacheBox = await Hive.openLazyBox('cache');
    commentsIndex = await Hive.openLazyBox('commentsIndex');

    reactionsBox = await Hive.openLazyBox('reactions');

    revisionCache =
        await Hive.openBox('revisionCache'); // TODO Can be cleared at any time

    pointerBox = await Hive.openBox('feed-pointer');
  }

  Future<void> loadEverything() async {
    print('userId ${AppState.userId}');
    print('skyfeedUserId ${AppState.skynetUser.id}');

    print('main() 2 ${DateTime.now()}');

    dp.initAccount();

    print('main() 3 ${DateTime.now()}');

    final cFollowing = await cacheBox.get('following');

    if (cFollowing != null) dp.following = cFollowing.cast<String, Map>();

    final cFollowers = await cacheBox.get('followers');

    if (cFollowers != null) dp.followers = cFollowers.cast<String, Map>();

    final cPrivateFollowing = await cacheBox.get('privateFollowing');

    if (cPrivateFollowing != null)
      dp.privateFollowing = cPrivateFollowing.cast<String, Map>();

    print('main() 4 ${DateTime.now()}');

    dp.checkFollowingUpdater();

    print('main() 5 ${DateTime.now()}');

    final cRequestFollow = await cacheBox.get('requestFollow');
    if (cRequestFollow != null)
      dp.requestFollow = cRequestFollow.cast<String, Map>();

    final cRequestMention = await cacheBox.get('requestMention');
    if (cRequestMention != null)
      dp.requestMention = cRequestMention.cast<String, Map>();

    final cReactions = await cacheBox.get('reactions');
    //print('cReactions $cReactions');
    if (cReactions != null)
      dp.reactions = cReactions.cast<String, List<String>>()

          /* json
          .decode(cReactions)
          .cast<String, List>()
          .map<String, List<String>>(
              (key, value) => MapEntry(key, value.cast<String>())) */
          ;

    final cMediaPositions = await cacheBox.get('mediaPositions');
    if (cMediaPositions != null)
      dp.mediaPositions = json.decode(cMediaPositions).cast<String, Map>();

    if (cacheBox.containsKey('saved')) {
      if (dp.saved == null) {
        dp.saved = (await cacheBox.get('saved')).cast<String, Map>();
      }
    }
  }
  // Map<String, ItemPosition> scrollCache = {};

  log(String path, String msg) {
    if (kDebugMode) print('$path $msg');
  }

  Map<String, StreamSubscription> _subbedProfilesInternal = {};

  final onFollowingChange = StreamController<Null>.broadcast();
  final onNotificationsChange = StreamController<Null>.broadcast();

  // Requests
  Map<String, Map> requestFollow = {};
  Map<String, Map> requestMention = {};

  // RT
  Map<String, StreamController<User>> subbedProfiles = {};

  Map<String, Set<int>> profileSubCount = {};

  Map<String, Map> following;
  Map<String, Map> followers = {};

  Map<String, List<String>> reactions = {};

  Map<String, Map> privateFollowing;

  Map<String, Map> saved;

  Map<String, Map> mediaPositions; // skylink: {int position}

  List<String> oldFollowing;
  List<String> oldPrivateFollowing;

  int getMediaPositonForSkylink(String skylink) {
    if (mediaPositions == null) return null;
    if (!mediaPositions.containsKey(skylink)) return null;

    return mediaPositions[skylink]['position'];
  }

  void setMediaPositonForSkylink(String skylink, int position) {
    if (mediaPositions == null) {
      mediaPositions = {
        skylink: {'position': position}
      };
      _updateMediaPositions(revision: 0);
    } else {
      mediaPositions[skylink] = {'position': position};
    }
  }

  void addReaction(String fullPostId, String reaction) {
    log('addReaction', '$reaction on $fullPostId');
/*     print('addReaction');
    print('current: $reactions'); */
    // reactions = {};

    if (!reactions.containsKey(fullPostId)) reactions[fullPostId] = <String>[];

    if (!reactions[fullPostId].contains(reaction))
      reactions[fullPostId].add(reaction);

    final subKey = 'reactions/$fullPostId';
    if (feedStreams.containsKey(subKey)) {
      log('addReaction', 'Notify reactions stream');
      feedStreams[subKey].add(null);
    }

    _updateReactions();
  }

  void removeReaction(String fullPostId, String reaction) {
    if (reactions[fullPostId].contains(reaction))
      reactions[fullPostId].remove(reaction);

    log('removeReaction', '$reaction on $fullPostId');

    final subKey = 'reactions/$fullPostId';
    if (feedStreams.containsKey(subKey)) {
      log('removeReaction', 'Notify reactions stream');
      feedStreams[subKey].add(null);
    }

    _updateReactions();
  }

  int _currentReactionsUpdateCount = 0;

  void _updateReactions() async {
    _currentReactionsUpdateCount++;
    final cCount = _currentReactionsUpdateCount;

    await Future.delayed(Duration(seconds: 6));
    if (cCount != _currentReactionsUpdateCount) return;

    log('update/reactions', '');

    _setFile(
      utf8.encode(json.encode(reactions)),
      $skyfeedReactions,
      revision: /*  reactions.length == 1 ? 0 : */ null, // TODO Do this better
    );
  }

  Future<Set<String>> getSuggestedUsers() async {
    final tmpSuggestions = <String>{
      'd448f1562c20dbafa42badd9f88560cd1adb2f177b30f0aa048cb243e55d37bd', // redsolver
      '70a3fffccae8618b12f8878f94f118350717e363b143f1d5d8df787ffb1c9ae7', // Julian
      '8126964b3bf6444862610b8da523189fe749c4d4fa8047dddb0f2ff33f65cbc3', // Skynet Labs
    };

    for (final mainUserId in getFollowKeys()) {
      final Map flw = await followingBox.get(mainUserId);
      if (flw == null) continue;

/*       if (flw.containsKey(
          '')) {
        
      } */
      tmpSuggestions.addAll(flw.keys.cast<String>());
    }

    tmpSuggestions.removeWhere(
        (element) => dp.isFollowingUserPubliclyOrPrivately(element));

    return tmpSuggestions;
  }

  bool isSaved(String postId) {
    //print('isSaved $postId');

    if (saved == null) return false;

    return saved.containsKey(postId);
  }

  bool isFollowing(String userId) {
    if (following == null) return false;

    return following.containsKey(userId);
  }

  bool isFollowingPrivately(String userId) {
    if (privateFollowing == null) return false;

    return privateFollowing.containsKey(userId);
  }

  List<String> followingAndUpdateSubscribed = [];

  // ARCHITECTURE

  // skyfeed-user (latest pointer feed)

  // skyfeed-feed/posts
  // skyfeed-feed/posts

  /// $userId/$type/$feed/$feedPage/$postId
  Future<Post> getPost(String postId) async {
    //print(postId);

    final parts = postId.split('/');
    //print(parts);
    final userId = parts[0];
    final type = parts[1];
    final feed = parts[2];
    final feedPageId = parts[3];
    final pId = int.parse(parts[4]);

    final fullFeedPageId = '$userId/$type/$feed/$feedPageId';

    Feed fp = await feedPages.get(fullFeedPageId);

    if (fp == null) {
      if (!users.containsKey(userId)) {
        final localId = getLocalId();

        await getProfileStream(userId, localId).single;

        removeProfileStream(userId, localId);
      }

      final User user = users.get(userId);

      subToPage(
        fullFeedPageId: '$feed/$feedPageId',
        skyfeedUser: SkynetUser.fromId(user.skyfeedId),
        mainUserId: userId,
      );
      while (!feedPages.containsKey(fullFeedPageId)) {
        await Future.delayed(Duration(milliseconds: 20));
      }

      fp = await feedPages.get(fullFeedPageId);
    }

    final post = fp.items.firstWhere((p) => p.id == pId, orElse: () => null);

    if (post == null) {
      print('ERROR $fullFeedPageId'); // TODO Error handling
      return null;
    }

    post.userId = userId;
    post.feedId = '$feed/$feedPageId';
    return post;
  }

  Future<void> deletePost(String postId) async {
    //print(postId);

    final parts = postId.split('/');
    //print(parts);
    final userId = parts[0];

    if (userId != AppState.userId) throw 'Not your post!';
    final type = parts[1];
    final feedId = parts[2];
    final feedPageId = parts[3];
    final pId = int.parse(parts[4]);

    final fullFeedPageId = '$userId/$type/$feedId/$feedPageId';

    Feed fp = await feedPages.get(fullFeedPageId);

    int lengthBefore = fp.items.length;

    fp.items.removeWhere((post) => post.id == pId);

    int lengthAfter = fp.items.length;

    if (lengthAfter != (lengthBefore - 1)) {
      throw 'Item not present in list';
    }
    fp.items.add(Post.deleted(id: pId));

    print(json.encode(fp));

    await ws.setFile(
      AppState.skynetUser,
      'skyfeed-feed/$feedId/$feedPageId',
      SkyFile(
        content: utf8.encode(json.encode(fp)),
        filename: 'skyfeed.json',
        type: 'application/json',
      ),
      revision: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> post({
    PostContent newPostContent,
    bool isRepost = false,
    bool isComment = false,
    String commentTo,
    String repostOf,
    Post parent,
    int postedAt,
  }) async {
    String feedId = isComment ? 'comments' : 'posts';
    final newPost = Post();

    //print('repostOf $repostOf');

    // return;

    final usersToMention = <String>[];

    if (isRepost) {
      newPost.repostOf = repostOf;
      newPost.parentHash =
          'sha256:${hex.encode(sha256.hashSync(utf8.encode(json.encode(parent))).bytes)}';
    } else {
      newPost.content = newPostContent;

      if (isComment) {
        newPost.commentTo = commentTo;
        newPost.parentHash =
            'sha256:${hex.encode(sha256.hashSync(utf8.encode(json.encode(parent))).bytes)}';

        newPost.mentions = parent.mentions ?? [];
        if (!newPost.mentions.contains(parent.userId)) {
          newPost.mentions.add(parent.userId);
        }
        newPost.mentions.remove(AppState.userId);

        usersToMention.addAll(newPost.mentions);
      }
    }

    newPost.id = 0;

    newPost.postedAt = postedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(postedAt)
        : DateTime.now();

    int currentPointer = pointerBox.get('${AppState.userId}/feed/$feedId') ?? 0;

    print('current{$feedId}Pointer $currentPointer');

    Feed fp =
        await feedPages.get('${AppState.userId}/feed/$feedId/$currentPointer');

    String newFullPostId;

    if (fp == null) {
      final newFeedPage = Feed(userId: AppState.userId);

      newFeedPage.items = [];

      newPost.id = newFeedPage.items.length;

      newFullPostId =
          '${AppState.userId}/feed/$feedId/$currentPointer/${newPost.id}';

      newFeedPage.items.add(newPost);

      print(json.encode(newFeedPage));

      await ws.setFile(
        AppState.skynetUser,
        'skyfeed-feed/$feedId/$currentPointer',
        SkyFile(
          content: utf8.encode(json.encode(newFeedPage)),
          filename: 'skyfeed.json',
          type: 'application/json',
        ),
        revision: 0,
      );
    } else {
      bool useRevisionZero = false;

      if (fp.items.length > 15) {
        currentPointer++;

        fp = Feed(userId: AppState.userId);

        fp.items = [];
        useRevisionZero = true;
      }

      newPost.id = fp.items.length;

      newFullPostId =
          '${AppState.userId}/feed/$feedId/$currentPointer/${newPost.id}';

      fp.items.add(newPost);

      print(json.encode(fp));

      await ws.setFile(
        AppState.skynetUser,
        'skyfeed-feed/$feedId/$currentPointer',
        SkyFile(
          content: utf8.encode(json.encode(fp)),
          filename: 'skyfeed.json',
          type: 'application/json',
        ),
        revision: useRevisionZero ? 0 : null,
      );
    }

    if (pointerBox.get('${AppState.userId}/feed/posts') !=
            currentPointer || // TODO
        pointerBox.get('${AppState.userId}/feed/comments') != currentPointer) {
      log('data/post', 'update pointer');

      final m = {
        'feed/$feedId/position': currentPointer,
      };

      for (final pointer in ['posts', 'comments']) {
        if (!m.containsKey('feed/$pointer/position')) {
          // ${mainUserId}/feed/posts
          final val = pointerBox.get('${AppState.userId}/feed/$pointer');

          if (val == null) continue;
          m['feed/$pointer/position'] = val;
        }
      }

      bool alreadyContainsPointer =
          pointerBox.containsKey('${AppState.userId}/feed/posts') ||
              pointerBox.containsKey('${AppState.userId}/feed/comments');

      await ws.setFile(
        AppState.skynetUser,
        $skyfeedUser,
        SkyFile(
          content: utf8.encode(json.encode(m)),
          filename: 'skyfeed.json',
          type: 'application/json',
        ),
        revision: alreadyContainsPointer ? null : 0,
      );

      await pointerBox.put('${AppState.userId}/feed/$feedId', currentPointer);
    }

    for (final userId in usersToMention) {
      print('notify $userId');
      try {
        await mention(newFullPostId, userId);
      } catch (e, st) {
        print(e);
        print(st);
      }
    }
  }

  Set<String> getFollowKeys() {
    if (AppState.userId == null) return <String>{};

    Set<String> keys = {
      AppState.userId,
    };

    if (privateFollowing != null) keys.addAll(privateFollowing.keys);
    if (following != null) keys.addAll(following.keys);

    // print('getFollowKeys $keys');

    return keys;
  }

  bool isFollowingUserPubliclyOrPrivately(String userId) {
    return getFollowKeys().contains(userId);
  }

  void addTemporaryUserForFeedPage(String userId) {
    if (!temporaryKeys.contains(userId)) {
      temporaryKeys.add(userId);
      checkFollowingUpdater();
    }
  }

  List<String> temporaryKeys = [];

  bool checkRevisionNumberCache(String key, int revision) {
    final x = revisionCache.get('$key');

    if (revision > (x ?? -1)) {
      print('no revision cache $revision > $x');
      return false;
    } else {
      return true;
    }
  }

  void setRevisionNumberCache(String key, int revision) async {
    return revisionCache.put('$key', revision);
  }

  bool isFollowingUpdaterRunning = false;

  final random = Random();

  void checkFollowingUpdater() async {
    while (isFollowingUpdaterRunning) {
      await Future.delayed(Duration(milliseconds: random.nextInt(300)));
    }
    isFollowingUpdaterRunning = true;
    /* if (privateFollowing != null) keys.addAll(privateFollowing.keys);
    if (following != null) keys.addAll(following.keys); */

    final allUserIds = [...getFollowKeys(), ...temporaryKeys];

    dp.log('checkFollowingUpdater', 'checkFollowingUpdater for ${allUserIds}');

    for (final mainUserId in allUserIds) {
      // print('checkFollowingUpdater: $mainUserId');
      try {
        //

        final User initialUser = users.get(mainUserId);

        // print('CHECK ID STREAM 2 $mainUserId');

        if (initialUser?.skyfeedId == null) {
          dp.log('checkFollowingUpdater',
              'Skipping $mainUserId because of no skyfeedId');

          continue;
        }
        initialUser.id = mainUserId;

        final user = SkynetUser.fromId(initialUser.skyfeedId);

        final key = Uint8List.fromList(
            [...user.publicKey.bytes, ...hashDatakey($skyfeedUser)]);

        //print('CHECK ID STREAM $mainUserId');
        if (!ws.streams.containsKey(String.fromCharCodes(key))) {
          dp.log('data/watch/feed', 'watch+ $mainUserId');

          ws.subscribe(user, $skyfeedUser).listen((event) async {
            /*      if (checkRevisionNumberCache(
                user.id + '#' + $skyfeedUser, event.entry.revision)) return; */

            final res = await ws.downloadFileFromRegistryEntry(event);
            final data = json.decode(res.asString);

            final int currentPostsPointer = data['feed/posts/position'] ?? 0;
            final int currentCommentsPointer =
                data['feed/comments/position'] ?? 0;

            // dp.log('data/watch/feed', 'got $data');

            // currentPostPointer 3

            pointerBox.put('${mainUserId}/feed/posts', currentPostsPointer);
            pointerBox.put(
                '${mainUserId}/feed/comments', currentCommentsPointer);

            for (final int feedPageId in [
              currentPostsPointer,
              if (currentPostsPointer > 0) currentPostsPointer - 1
            ]) {
              subToPage(
                fullFeedPageId: 'posts/${feedPageId}',
                skyfeedUser: user,
                mainUserId: mainUserId,
              );
            }

            for (final int feedPageId in [
              currentCommentsPointer,
              if (currentCommentsPointer > 0) currentCommentsPointer - 1
            ]) {
              subToPage(
                fullFeedPageId: 'comments/${feedPageId}',
                skyfeedUser: user,
                mainUserId: mainUserId,
              );
            }

            /*        setRevisionNumberCache(
                user.id + '#' + $skyfeedUser, event.entry.revision); */
          });
        }

        final followingKey = Uint8List.fromList(
            [...user.publicKey.bytes, ...hashDatakey($skyfeedFollowing)]);

        // dp.log('data/watch/following', 'watch? $mainUserId');

        if (!ws.streams.containsKey(String.fromCharCodes(followingKey))) {
          dp.log('data/watch/following', 'watch+ $mainUserId');

          ws.subscribe(user, $skyfeedFollowing).listen((event) async {
            if (checkRevisionNumberCache(
                user.id + '#' + $skyfeedFollowing, event.entry.revision))
              return;

            final res = await ws.downloadFileFromRegistryEntry(event);
            final data = json.decode(res.asString);

            dp.log('data/watch/following', 'got $data');

            if (mainUserId == AppState.userId) {
              following = data.cast<String, Map>();

              cacheBox.put('following', following);

              if (oldFollowing != null) {
                for (final oldKey in oldFollowing) {
                  if (!following.containsKey(oldKey)) {
                    if (subbedProfiles.containsKey(oldKey))
                      subbedProfiles[oldKey].add(null);
                  }
                }

                for (final key in following.keys) {
                  if (!oldFollowing.contains(key)) {
                    if (subbedProfiles.containsKey(key))
                      subbedProfiles[key].add(null);
                  }
                }
              }
              oldFollowing = following.keys.toList();

              checkFollowingUpdater();

              onFollowingChange.add(null);
            }

            await followingBox.put(mainUserId, data);

            if (subbedProfiles.containsKey(mainUserId))
              subbedProfiles[mainUserId].add(null);

            setRevisionNumberCache(
                user.id + '#' + $skyfeedFollowing, event.entry.revision);
          });
        }

        final followersKey = Uint8List.fromList(
            [...user.publicKey.bytes, ...hashDatakey($skyfeedFollowers)]);

        if (!ws.streams.containsKey(String.fromCharCodes(followersKey))) {
          dp.log('data/watch/followers', 'watch+ $mainUserId');

          ws.subscribe(user, $skyfeedFollowers).listen((event) async {
            if (checkRevisionNumberCache(
                user.id + '#' + $skyfeedFollowers, event.entry.revision))
              return;

            final res = await ws.downloadFileFromRegistryEntry(event);
            final data = json.decode(res.asString);

            dp.log('data/watch/followers', 'got $data');

            if (mainUserId == AppState.userId) {
              followers = data.cast<String, Map>();

              cacheBox.put('followers', followers);
            }

            await followersBox.put(mainUserId, data);

            if (subbedProfiles.containsKey(mainUserId))
              subbedProfiles[mainUserId].add(null);

            setRevisionNumberCache(
                user.id + '#' + $skyfeedFollowers, event.entry.revision);
          });

          final reactionsKey = Uint8List.fromList(
              [...user.publicKey.bytes, ...hashDatakey($skyfeedReactions)]);

          if (!ws.streams.containsKey(String.fromCharCodes(reactionsKey))) {
            dp.log('data/watch/reactions', 'watch+ $mainUserId');

            ws.subscribe(user, $skyfeedReactions).listen((event) async {
              if (checkRevisionNumberCache(
                  user.id + '#' + $skyfeedReactions, event.entry.revision))
                return;

              final res = await ws.downloadFileFromRegistryEntry(event);
              final Map data = json.decode(res.asString);

              dp.log('data/watch/reactions', 'got $data');

              if (mainUserId == AppState.userId) {
                // dp.log('data/watch/reactions', 'got AppState.userId $data');
                reactions = data.cast<String, List>().map<String, List<String>>(
                    (key, value) => MapEntry(key, value.cast<String>()));

                cacheBox.put('reactions', reactions);
              }

              for (final String fullPostId in data.keys) {
                final Map map = (await reactionsBox.get(fullPostId)) ?? {};

                if (!map.containsKey(mainUserId)) {
                  map[mainUserId] = [];
                }
                map[mainUserId] = data[fullPostId];

                reactionsBox.put(fullPostId, map);

                final subKey = 'reactions/$fullPostId';

                if (feedStreams.containsKey(subKey)) {
                  feedStreams[subKey].add(null);
                }
              }

              setRevisionNumberCache(
                  user.id + '#' + $skyfeedReactions, event.entry.revision);
            });
          }
        }
      } catch (e, st) {
        print('ERROR ' + e);
        print(st);
      }
    }
    isFollowingUpdaterRunning = false;
  }

  Stream<int> getCommentsCountStream(String fullPostId) async* {
    if (commentsIndex.containsKey(fullPostId)) {
      yield await getCommentCount(fullPostId, 0);
    }

    await for (final _ in dp.getFeedStream(key: 'comments/${fullPostId}')) {
      yield await getCommentCount(fullPostId, 0);
    }
  }

  Stream<Map<String, List<String>>> getReactionsStream(
      String fullPostId) async* {
/*     print(
        'getReactionsStream $fullPostId ${await reactionsBox.get(fullPostId)}'); */
    if (reactionsBox.containsKey(fullPostId)) {
      yield await getReactions(fullPostId);
    }

    // reactions/d73c16c364606a83fd93777ad74b21cd32ca11729c8573fe6654973a8308d56c/feed/posts/1/0
    // reactions/d73c16c364606a83fd93777ad74b21cd32ca11729c8573fe6654973a8308d56c/feed/posts/1/0

    await for (final _ in dp.getFeedStream(key: 'reactions/${fullPostId}')) {
      log('stream/reactions', 'got new event');
      yield await getReactions(fullPostId);
    }
  }

  Future<Map<String, List<String>>> getReactions(String fullPostId) async {
    try {
      final Map r = await reactionsBox.get(fullPostId);
      Map<String, List<String>> result = {};

      if (r != null) {
        for (final userId in r.keys) {
          if (userId == AppState.userId) continue;

          for (final reaction in r[userId]) {
            if (!result.containsKey(reaction)) result[reaction] = [];
            result[reaction].add(userId);
          }
        }
      }

      if (reactions.containsKey(fullPostId)) {
        for (final reaction in reactions[fullPostId]) {
          if (!result.containsKey(reaction)) result[reaction] = [];

          if (!result[reaction].contains(AppState.userId))
            result[reaction].add(AppState.userId);
        }
      }

      log('getReactions', result.toString());

      return result;
    } catch (e, st) {
      print(e);
      print(st);
    }

    return null;
  }

  Future<int> getCommentCount(String fullPostId, int deepness) async {
    if (deepness > 10) return 0;

    final List r = await commentsIndex.get(fullPostId);

    if (r == null) return 0;

    int count = r.length;

    for (final i in r) {
      count += await getCommentCount(i, deepness + 1);
    }

    return count;
  }

  void subToPage(
      {String mainUserId, SkynetUser skyfeedUser, String fullFeedPageId}) {
    final currentDatakey = 'skyfeed-feed/$fullFeedPageId';

    dp.log('sub/fullFeedPageId', '$fullFeedPageId');

    /*        final oldKey = Uint8List.fromList(
                [...user.publicKey.bytes, ...hashDatakey(oldDatakey)]); */

    final feedId = fullFeedPageId.split('/').first;

    final currentKey = Uint8List.fromList(
        [...skyfeedUser.publicKey.bytes, ...hashDatakey(currentDatakey)]);

    if (!ws.streams.containsKey(String.fromCharCodes(currentKey))) {
      dp.log('data/watch/feed/$feedId', 'watch+ $currentDatakey');

      ws.subscribe(skyfeedUser, currentDatakey).listen((event) async {
        // dp.log('data/watch/feed/$feedId', 'got event');

        if (checkRevisionNumberCache(
            skyfeedUser.id + '#' + currentDatakey, event.entry.revision))
          return;

        final res = await ws.downloadFileFromRegistryEntry(event);

        final data = json.decode(res.asString);
        // dp.log('data/watch/feed/$feedId', 'got $data');

        final feed = Feed.fromJson(data);

        //print(feed.items.first.content.text);

        if (feedId == 'comments') {
          for (final item in (feed.items ?? <Post>[])) {
            if (item.commentTo != null) {
              final List list = (await commentsIndex.get(item.commentTo)) ?? [];

              final commentId = '$mainUserId/feed/$fullFeedPageId/${item.id}';

              if (!list.contains(commentId)) {
                list.add(commentId);

                await commentsIndex.put(item.commentTo, list);

                final feedKey = 'comments/${item.commentTo}';

                if (feedStreams.containsKey(feedKey)) {
                  feedStreams[feedKey].add(null);
                }
              }
            }
          }
        }

        await feedPages.put('${mainUserId}/feed/$fullFeedPageId', feed);

        final feedKey = '${mainUserId}/feed/$feedId';

        if (feedStreams.containsKey(feedKey)) {
          feedStreams[feedKey].add(null);
        }

        if (feedStreams.containsKey('*/feed/$feedId')) {
          if (getFollowKeys().contains(mainUserId)) {
            feedStreams['*/feed/$feedId'].add(null);
          }
        }

        setRevisionNumberCache(
            skyfeedUser.id + '#' + currentDatakey, event.entry.revision);
      });

      /*       if (ws.streams.containsKey(String.fromCharCodes(oldKey))) {
              print('cancel sub ${oldDatakey}');
              ws.cancelSub(user, oldDatakey);
            } */
    }
  }

  Stream<Null> getFeedStream({String userId, String key}) {
    if (key == null) key = '${userId}/feed/posts';

    if (!feedStreams.containsKey(key)) {
      feedStreams[key] = StreamController<Null>.broadcast();
    }
    return feedStreams[key].stream;
  }

  Map<String, StreamController<Null>> feedStreams = {};

  void initAccount() {
    subToProfile(AppState.userId);
/* 
    ws.subscribe(AppState.skynetUser, $skyfeedFollowing).listen((event) async {
      print('got skyfeedFollowing');

      if (checkRevisionNumberCache(
          AppState.skynetUser.id + '#' + $skyfeedFollowing,
          event.entry.revision)) return;

      final res = await ws.downloadFileFromRegistryEntry(event);

      //print(res.asString);

    

      setRevisionNumberCache(AppState.skynetUser.id + '#' + $skyfeedFollowing,
          event.entry.revision);
    }); */

    /* ws.subscribe(AppState.skynetUser, $skyfeedFollowers).listen((event) async {
      print('got skyfeedFollowers');

      if (checkRevisionNumberCache(
          AppState.skynetUser.id + '#' + $skyfeedFollowers,
          event.entry.revision)) return;

      
/*       if (oldFollowing != null) {
        for (final oldKey in oldFollowing) {
          if (!following.containsKey(oldKey)) {
            if (subbedProfiles.containsKey(oldKey))
              subbedProfiles[oldKey].add(null);
          }
        }

        for (final key in following.keys) {
          if (!oldFollowing.contains(key)) {
            if (subbedProfiles.containsKey(key)) subbedProfiles[key].add(null);
          }
        }
      }
      oldFollowing = following.keys.toList();

      onFollowingChange.add(null); */

      setRevisionNumberCache(AppState.skynetUser.id + '#' + $skyfeedFollowers,
          event.entry.revision);
    }); */

    ws
        .subscribe(AppState.publicUser, $skyfeedRequestFollow + AppState.userId)
        .listen((event) async {
      print('got skyfeedRequestFollow');

      if (checkRevisionNumberCache(
          AppState.skynetUser.id + '#' + $skyfeedRequestFollow,
          event.entry.revision)) return;

      final res = await ws.downloadFileFromRegistryEntry(event);

      final val = json.decode(res.asString).cast<String, Map>();

      if (val == null) {
        print('null value!');
        return;
      }

      requestFollow = val;

      cacheBox.put('requestFollow', requestFollow);

      onNotificationsChange.add(null);

      setRevisionNumberCache(
          AppState.skynetUser.id + '#' + $skyfeedRequestFollow,
          event.entry.revision);
    });

    ws
        .subscribe(
            AppState.publicUser, $skyfeedRequestMention + AppState.userId)
        .listen((event) async {
      print('got skyfeedRequestMention');

      if (checkRevisionNumberCache(
          AppState.skynetUser.id + '#' + $skyfeedRequestMention,
          event.entry.revision)) return;

      final res = await ws.downloadFileFromRegistryEntry(event);

      final val = json.decode(res.asString).cast<String, Map>();

      if (val == null) {
        print('null value!');
        return;
      }

      requestMention = val;

      cacheBox.put('requestMention', requestMention);

      onNotificationsChange.add(null);

      setRevisionNumberCache(
          AppState.skynetUser.id + '#' + $skyfeedRequestMention,
          event.entry.revision);
    });

    ws
        .subscribe(AppState.skynetUser, $skyfeedPrivateFollowing)
        .listen((event) async {
      print('got skyfeedPrivateFollowing');

      if (checkRevisionNumberCache(
          AppState.skynetUser.id + '#' + $skyfeedPrivateFollowing,
          event.entry.revision)) return;

      final encryptedRes = await ws.downloadFileFromRegistryEntry(event);

      final decrypted = AppState.skynetUser
          .symDecrypt(AppState.skynetUser.sk, encryptedRes.content);

      privateFollowing =
          json.decode(utf8.decode(decrypted)).cast<String, Map>();
      /*   print('oldFollowing $oldFollowing');
      print('following $following'); */

      cacheBox.put('privateFollowing', privateFollowing);

      if (oldPrivateFollowing != null) {
        for (final oldKey in oldPrivateFollowing) {
          if (!privateFollowing.containsKey(oldKey)) {
            if (subbedProfiles.containsKey(oldKey))
              subbedProfiles[oldKey].add(null);
          }
        }

        for (final key in privateFollowing.keys) {
          if (!oldPrivateFollowing.contains(key)) {
            if (subbedProfiles.containsKey(key)) subbedProfiles[key].add(null);
          }
        }
      }
      oldPrivateFollowing = privateFollowing.keys.toList();
      checkFollowingUpdater();

      onFollowingChange.add(null);

      setRevisionNumberCache(
          AppState.skynetUser.id + '#' + $skyfeedPrivateFollowing,
          event.entry.revision);
    });

    ws.subscribe(AppState.skynetUser, $skyfeedSaved).listen((event) async {
      print('got skyfeedSaved');

      if (checkRevisionNumberCache(
          AppState.skynetUser.id + '#' + $skyfeedSaved, event.entry.revision))
        return;

      final encryptedRes = await ws.downloadFileFromRegistryEntry(event);

      final decrypted = AppState.skynetUser
          .symDecrypt(AppState.skynetUser.sk, encryptedRes.content);

      saved = json.decode(utf8.decode(decrypted)).cast<String, Map>();
      /*   print('oldFollowing $oldFollowing');
      print('following $following'); */

      await cacheBox.put('saved', saved);

      setRevisionNumberCache(
          AppState.skynetUser.id + '#' + $skyfeedSaved, event.entry.revision);
    });
    ws
        .subscribe(AppState.skynetUser, $skyfeedMediaPositions)
        .listen((event) async {
      print('got mediaPositions');

      if (checkRevisionNumberCache(
          AppState.skynetUser.id + '#' + $skyfeedMediaPositions,
          event.entry.revision)) return;

      final encryptedRes = await ws.downloadFileFromRegistryEntry(event);

      final decrypted = AppState.skynetUser
          .symDecrypt(AppState.skynetUser.sk, encryptedRes.content);

      mediaPositions = json.decode(utf8.decode(decrypted)).cast<String, Map>();
      /*   print('oldFollowing $oldFollowing');
      print('following $following'); */

      await cacheBox.put('mediaPositions', json.encode(mediaPositions));

      setRevisionNumberCache(
          AppState.skynetUser.id + '#' + $skyfeedMediaPositions,
          event.entry.revision);
    });

    /*    Stream.periodic(Duration(seconds: 10)).listen((event) {
      dp.checkFollowingUpdater();
    }); */

    Stream.periodic(Duration(seconds: 30)).listen((event) {
      _updateMediaPositions();
    });
  }

  void _updateMediaPositions({int revision}) async {
    if (AppState.userId == null) return;

    if (mediaPositions == null) return;

    final str = json.encode(mediaPositions);

    final cacheStr = await cacheBox.get('mediaPositions');

    if (str != cacheStr) {
      print('Updating mediaPositions...');

      final r = await _setEncryptedFile(
        utf8.encode(str),
        $skyfeedMediaPositions,
        revision: revision,
      );

      if (r != true) throw 'Could not update mediaPositions';

      await cacheBox.put('mediaPositions', str);
    }
  }

  Future<void> addUserToFollowers(String userId) async {
    followers[userId] = {};
    await _setFile(
      utf8.encode(json.encode(followers)),
      $skyfeedFollowers,
    );
  }

  Future<void> mention(
    String fullPostId,
    String userId, {
    bool remove = false,
  }) async {
    print('try mention $userId');

    final entry =
        await getEntry(AppState.publicUser, $skyfeedRequestMention + userId);

    log('rMention', 'entry: $entry');

    Map<String, Map> rMention = {};

    if (entry != null) {
      final res = await ws.downloadFileFromRegistryEntry(entry);

      rMention = json.decode(res.asString).cast<String, Map>();
    }
    if (remove) {
      rMention.remove(fullPostId);
    } else {
      rMention[fullPostId] = {};
    }

    log('rMention set', '$rMention');

    await ws.setFile(
      AppState.publicUser,
      $skyfeedRequestMention + userId,
      SkyFile(
        content: utf8.encode(json.encode(rMention)),
        filename: 'skyfeed.json',
        type: 'application/json',
      ),
      revision: entry == null ? 0 : DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> follow(String userId) async {
    await _follow(userId, following);

    log('follow', 'done $following');

    final entry =
        await getEntry(AppState.publicUser, $skyfeedRequestFollow + userId);

    log('rFollow', 'entry: $entry');

    Map<String, Map> rFollow = {};

    if (entry != null) {
      final res = await ws.downloadFileFromRegistryEntry(entry);

      rFollow = json.decode(res.asString).cast<String, Map>();
    }

    rFollow[AppState.userId] = {};

    await ws.setFile(
      AppState.publicUser,
      $skyfeedRequestFollow + userId,
      SkyFile(
        content: utf8.encode(json.encode(rFollow)),
        filename: 'skyfeed.json',
        type: 'application/json',
      ),
      revision: entry == null ? 0 : DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> removeUserFromPublicRequestFollow(String userId) async {
    requestFollow.remove(userId);

    await ws.setFile(
      AppState.publicUser,
      $skyfeedRequestFollow + AppState.userId,
      SkyFile(
        content: utf8.encode(json.encode(requestFollow)),
        filename: 'skyfeed.json',
        type: 'application/json',
      ),
    );
  }

  Future<void> unfollow(String userId) => _unfollow(userId, following);

  Future<void> followPrivately(String userId) => _follow(
        userId,
        privateFollowing,
        encrypted: true,
      );
  Future<void> unfollowPrivately(String userId) => _unfollow(
        userId,
        privateFollowing,
        encrypted: true,
      );

  Future<void> _follow(
    String userId,
    Map<String, Map> map, {
    bool encrypted = false,
  }) async {
    print('follow $userId, encrypted: $encrypted');

    // following = null;

    if (userId == null) throw Exception('user id is null');

    if (map == null) {
      final payload = utf8.encode('{"$userId":{}}');

      // log('follow', 'new map');

      final r = await (encrypted
          ? (_setEncryptedFile(
              payload,
              $skyfeedPrivateFollowing,
              revision: 0,
            ))
          : (_setFile(
              payload,
              $skyfeedFollowing,
              revision: 0,
            )));

      // log('follow', 'result $r');

      if (r) {
        map = {};

        map[userId] = {};

        if (encrypted) {
          privateFollowing = map;
        } else {
          following = map;
        }

        // log('follow', 'map result $map');
        return;
      } else if (!r) {
        throw Exception('Could not set SkyDB file');
      }
    } else {
      map[userId] = {};

      final payload = utf8.encode(json.encode(map));

      final r = await (encrypted
          ? (_setEncryptedFile(
              payload,
              $skyfeedPrivateFollowing,
            ))
          : (_setFile(
              payload,
              $skyfeedFollowing,
            )));

      if (!r) {
        throw Exception('Could not set SkyDB file');
      }
    }
  }

  Future<void> _unfollow(
    String userId,
    Map<String, Map> map, {
    bool encrypted = false,
  }) async {
    print('unfollow $userId');

    if (userId == null) throw Exception('user id is null');

    map.remove(userId);

    final payload = utf8.encode(json.encode(map));

    final r = await (encrypted
        ? (_setEncryptedFile(
            payload,
            $skyfeedPrivateFollowing,
          ))
        : (_setFile(
            payload,
            $skyfeedFollowing,
          )));

    if (!r) {
      throw Exception('Could not set SkyDB file');
    }
  }

  Future<bool> _setFile(List<int> content, String datakey, {int revision}) {
    return ws.setFile(
      AppState.skynetUser,
      datakey,
      SkyFile(
        content: content,
        filename: 'skyfeed.json',
        type: 'application/json',
      ),
      revision: revision,
    );
  }

  Future<void> savePost(
    String postId,
  ) async {
    print('save post $postId');

    if (postId == null) throw Exception('postId is null');

    if (saved == null) {
      final payload = utf8.encode('{"$postId":{}}');

      final r = await _setEncryptedFile(
        payload,
        $skyfeedSaved,
        revision: 0,
      );
      if (r) {
        saved = {};
        saved[postId] = {};
        return;
      } else if (!r) {
        throw Exception('Could not set SkyDB file');
      }
    } else {
      saved[postId] = {};
      final payload = utf8.encode(json.encode(saved));
      final r = await _setEncryptedFile(
        payload,
        $skyfeedSaved,
      );
      if (!r) {
        throw Exception('Could not set SkyDB file');
      }
    }
  }

  Future<void> unsavePost(
    String postId,
  ) async {
    print('unsave post $postId');

    if (postId == null) throw Exception('postId is null');

    saved.remove(postId);

    final payload = utf8.encode(json.encode(saved));

    final r = await _setEncryptedFile(
      payload,
      $skyfeedSaved,
    );

    if (!r) {
      throw Exception('Could not set SkyDB file');
    }
  }

  Future<bool> _setEncryptedFile(List<int> content, String datakey,
      {int revision}) {
    final encrypted =
        AppState.skynetUser.symEncrypt(AppState.skynetUser.sk, content);

    return ws.setFile(
      AppState.skynetUser,
      datakey,
      SkyFile(
        content: Uint8List.fromList(encrypted),
        filename: 'skyfeed-crypt',
        type: 'application/octet-stream',
      ),
      revision: revision,
    );
  }

  Stream<User> getProfileStream(String userId, int localId) {
    // print('getProfileStream $userId');
    // print(profileSubCount);

    if (!profileSubCount.containsKey(userId)) profileSubCount[userId] = {};

    profileSubCount[userId].add(localId);

    // print('getProfileStream');
    if (!subbedProfiles.containsKey(userId)) {
      subToProfile(userId);
    }

    return subbedProfiles[userId].stream;
  }

  void removeProfileStream(String userId, int localId) async {
    // print('removeProfileStream');

    if (!profileSubCount.containsKey(userId)) return;

    profileSubCount[userId].remove(localId);

    await Future.delayed(Duration(milliseconds: 500));

    if (!profileSubCount.containsKey(userId)) return;

    if (profileSubCount[userId].isEmpty) {
      if (_subbedProfilesInternal.containsKey(userId))
        await (_subbedProfilesInternal[userId].cancel());
      if (subbedProfiles.containsKey(userId))
        await (subbedProfiles[userId].close());

      _subbedProfilesInternal.remove(userId);
      subbedProfiles.remove(userId);

      profileSubCount.remove(userId);
    }
  }

  void subToProfile(String userId) {
    if (userId == null) throw 'userId is null';

    subbedProfiles[userId] = StreamController<User>.broadcast();

    _subbedProfilesInternal[userId] = ws
        .subscribe(SkynetUser.fromId(userId), 'profile')
        .listen((event) async {
      try {
        print('Downloading updated JSON...');

        if (checkRevisionNumberCache(
            userId + '#' + 'profile', event.entry.revision)) return;

        final res = await ws.downloadFileFromRegistryEntry(event);

        //print(res.asString);

        final data = json.decode(json.decode(res.asString));

        print(userId);

        print(data);

        String username = data['username'] ?? '';
        String aboutMe = data['aboutMe'] ?? '';
        String location = data['location'] ?? '';
        String avatar = data['avatar'];

        final user = User(
          id: userId,
          username: username.truncateTo(64),
          bio: aboutMe.truncateTo(2000),
          location: location.truncateTo(200),
          picture: avatar == null
              ? 'sia://CABdyKgcVLkjdsa0HIjBfNicRv0pqU7YL-tgrfCo23DmWw'
              : 'sia://$avatar/150',
        );

        final String skyfeedId = data['dapps']['skyfeed']['publicKey'];

        if (skyfeedId == null) throw Exception('User has no skyfeed key');

        user.skyfeedId = skyfeedId;

        subbedProfiles[userId].add(user);

        await users.put(userId, user);

        setRevisionNumberCache(userId + '#' + 'profile', event.entry.revision);
      } catch (e, st) {
        print(e);
        print(st);
      }
    });

/*     getFile(
            SkynetUser.fromId(
                '130bf68e5b9f83f6ad1c1d82dc69398353146b24f3355e9d8a9cfffb8ee5c5e5'),
            'profile')
        .then((value) {
      print(value.filename);
      print(value.asString);
    }); */
  }

  int maxLocalId = 0;

  int getLocalId() {
    // print('profileSubCount $profileSubCount');
    return maxLocalId++;
  }

  Future<int> getFollowingCount(String id) async {
    if (id == AppState.userId) {
      return dp.following?.length ?? 0;
    }

    final Map res = await followingBox.get(id);

    if (res == null) {
      return 0;
    } else {
      return res.length;
    }
  }

  Future<int> getFollowersCount(String id) async {
    if (id == AppState.userId) {
      return dp.followers?.length ?? 0;
    }

    final Map res = await followersBox.get(id);

    if (res == null) {
      return 0;
    } else {
      return res.length;
    }
  }

  Future<Map> getFollowingFor(String id) async {
    if (id == AppState.userId) {
      return dp.following ?? {};
    }

    final Map res = await followingBox.get(id);

    return res ?? {};
  }

  Future<Map> getFollowersFor(String id) async {
    if (id == AppState.userId) {
      return dp.followers ?? {};
    }

    final Map res = await followersBox.get(id);

    return res ?? {};
  }

  Future<void> logout() async {
    await dataBox.deleteAll(dataBox.keys);
    await cacheBox.deleteAll(cacheBox.keys);
    await revisionCache.deleteAll(revisionCache.keys);
    await users.deleteAll(users.keys);
    await followingBox.deleteAll(followingBox.keys);
    await followersBox.deleteAll(followersBox.keys);
    await reactionsBox.deleteAll(reactionsBox.keys);

    await feedPages.deleteAll(feedPages.keys);
    await commentsIndex.deleteAll(commentsIndex.keys);
    await pointerBox.deleteAll(pointerBox.keys);

/*     users = await Hive.openBox('users');
    followingBox = await Hive.openLazyBox('following');
    feedPages = await Hive.openLazyBox('feedPages');

    cacheBox = await Hive.openLazyBox('cache');
    commentsIndex = await Hive.openLazyBox('commentsIndex');

    revisionCache =
        await Hive.openBox('revisionCache'); // TODO Can be cleared at any time

    pointerBox = await Hive.openBox('feed-pointer'); */
  }

  int getNotificationsCount() {
    return requestFollow.length + requestMention.length;
  }
}
