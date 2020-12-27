import 'package:app/app.dart';
import 'package:app/model/post.dart';
import 'package:app/state.dart';
import 'package:app/utils/parse_md.dart';
import 'package:app/widget/comments.dart';
import 'package:app/widget/custom_popup_menu.dart';
import 'package:app/widget/emoji_popup_menu.dart';
import 'package:app/widget/emoji_reaction.dart';
import 'package:app/widget/link.dart';
import 'package:app/widget/video/play_button.dart';

import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:just_audio/just_audio.dart';
import 'package:regexpattern/regexpattern.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:app/utils/string.dart';

class PostWidget extends StatefulWidget {
  final Post post;
  final Post repost;

  final bool noDecoration;
  final bool indentContent;

  final bool showComments;

  final bool showMentionContext;

  PostWidget(this.post,
      {this.repost,
      this.showComments = false,
      this.noDecoration = false,
      this.indentContent = false,
      this.showMentionContext = false,
      @required Key key})
      : super(key: key);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

enum PostMenuOption { delete }

class _PostWidgetState extends State<PostWidget> {
  bool reposted = false;

  Post get post => widget.post;

  VideoPlayerController _videoPlayerController;
  ChewieController chewieController;

  AudioPlayer audioPlayer;
  Duration audioDuration;

  @override
  void initState() {
    fullPostId = '${post.userId}/feed/${post.feedId}/${post.id}';

    if (post.content != null && post.content.link == null) {
      // print('trying to extract link...');
      post.content.link = RegExp(
              r"((((H|h)(T|t)|(F|f))(T|t)(P|p)((S|s)?))\://)?(www.|[a-zA-Z0-9].)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,6}(\:[0-9]{1,5})*(/($|[a-zA-Z0-9\.\,\;\?\'\\\+&amp;%\$#\=~_\-@]+))*")
          .stringMatch(post.content.text ?? '');
    }

    // print('[init] PostWidget ${fullPostId}');

    if (cacheBox.containsKey('repost-$fullPostId')) {
      reposted = true;
    }

    if (post.isDeleted != true) {
      if (post.content.video != null) {
        _videoPlayerController = VideoPlayerController.network(
          resolveSkylink(post.content.video),
        );

        if (kIsWeb) {
        } else {
          chewieController = ChewieController(
            videoPlayerController: _videoPlayerController,
            aspectRatio: post.content.aspectRatio,
            autoInitialize: false,
            allowFullScreen: true,
            autoPlay: false,
            looping: false,
          );
        }

        _videoPlayerController.initialize().then((value) {
          print('initialize');
          _initVideo();
          setState(() {});
        });

        /* ..initialize().then((_) {
          print('initialize');
          setState(() {});

          /*     _controller.videoPlayerOptions
              . */

          // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
          /*      setState(() {}); */
          /* 
              _controller.play();
              setState(() {}); */
        }); */
      } else if (post.content.audio != null) {
        audioPlayer = AudioPlayer();

        audioPlayer.setUrl(resolveSkylink(post.content.audio)).then((value) {
          final position = dp.getMediaPositonForSkylink(post.content.audio);

          if (position != null) {
            audioPlayer.seek(Duration(milliseconds: position));
          }

          audioPlayer.setVolume(0.5); // TODO Volume

          // TODO audioPlayer.playbackEvent.

          bool settingPosition = false;

          audioPlayer.positionStream.listen((event) async {
            if (settingPosition) return;
            settingPosition = true;
            try {
              // print('pos ${event}');
              dp.setMediaPositonForSkylink(
                  post.content.audio, event.inMilliseconds);

              await Future.delayed(Duration(seconds: 1));
            } catch (e, st) {
              print(e);
              print(st);
            }
            settingPosition = false;
          });

          setState(() {
            audioDuration = value;
          });
        });
      }
    }

    super.initState();
  }

  void _initVideo() {
    print('_initVideo');
    bool settingPosition = false;

    final position = dp.getMediaPositonForSkylink(post.content.video);

    if (position != null)
      _videoPlayerController.seekTo(Duration(milliseconds: position));

    _videoPlayerController.addListener(() async {
      if (settingPosition) return;
      settingPosition = true;
      try {
        /*       print(
              '${post.content.video} ${await _videoPlayerController.position}'); */

        dp.setMediaPositonForSkylink(post.content.video,
            (await _videoPlayerController.position).inMilliseconds);

        await Future.delayed(Duration(seconds: 1));
      } catch (e, st) {
        print(e);
        print(st);
      }
      settingPosition = false;
    });
  }

  @override
  void dispose() {
    if (_videoPlayerController != null) _videoPlayerController.dispose();
    if (chewieController != null) chewieController.dispose();

    if (audioPlayer != null) audioPlayer.dispose();

    super.dispose();
  }

  bool showImage = true;

  String fullPostId;

  bool _isReposting = false;
  bool _isSaving = false;

  bool _isDeleted = false;

  final _emojiPopupController = CustomPopupMenuController();

  bool _showPollResults = false;

  @override
  Widget build(BuildContext context) {
    final saved = dp.isSaved(fullPostId);

    final leftContentIndent = widget.indentContent ? 8.0 + 48 + 8 : 8.0;

    // print('[build] PostWidget ${fullPostId}');

    if (_isDeleted || (post.isDeleted == true)) {
      return Container(
        decoration: widget.noDecoration
            ? null
            : getCardDecoration(
                context,
              ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'This post has been deleted',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: SkyColors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          decoration: widget.noDecoration
              ? null
              : getCardDecoration(
                  context,
                ),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 8.0,
                  right: 8,
                  bottom: 4, // TODO Check to 8
                ),
                child: GestureDetector(
                  onTap: () {
                    rd.setPostId(
                        post.userId, '${post.feedId}/${post.id}'); // TODO check
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.repost != null ||
                            widget.showMentionContext) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 2,
                                ),
                                Icon(
                                  widget.showMentionContext
                                      ? UniconsLine.commentAlt
                                      : UniconsLine.repeat,
                                  size: 16,
                                ),
                                if (widget.showMentionContext)
                                  SizedBox(
                                    width: 4,
                                  ),
                                if (!widget.showMentionContext)
                                  InkWell(
                                    borderRadius: borderRadius,
                                    onTap: () {
                                      rd.setUserId(widget.repost.userId);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: UserBuilder(
                                        userId: widget.repost.userId,
                                        callback: (user) {
                                          if (user == null) return SizedBox();

                                          return buildUsernameWidget(
                                            user,
                                            context,
                                            fontSize: 13,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(
                                    widget.showMentionContext
                                        ? 'Comment on'
                                        : 'reposted',
                                    style: TextStyle(
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (widget.showMentionContext)
                                  InkWell(
                                    borderRadius: borderRadius,
                                    onTap: () {
                                      final s = post.commentTo;

                                      final userId = s.split('/').first;

                                      rd.setPostId(userId,
                                          s.substring(userId.length + 6));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text(
                                        'your post',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (post.commentTo != null &&
                              !widget.showMentionContext)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  if (!widget.showMentionContext) ...[
                                    SizedBox(
                                      width: 2,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      child: Text(
                                        'Comment on',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                  InkWell(
                                    borderRadius: borderRadius,
                                    onTap: () {
                                      final s = post.commentTo;

                                      final userId = s.split('/').first;

                                      rd.setPostId(userId,
                                          s.substring(userId.length + 6));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text(
                                        'this post',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'from',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  InkWell(
                                    borderRadius: borderRadius,
                                    onTap: () {
                                      //print(post.commentTo);
                                      rd.setUserId(
                                          post.commentTo.split('/').first);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: UserBuilder(
                                        userId: post.commentTo.split('/').first,
                                        callback: (user) {
                                          if (user == null) return SizedBox();

                                          return buildUsernameWidget(
                                            user,
                                            context,
                                            italic: true,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                            height: 4,
                          ),
                        ],
                        if (widget.repost == null)
                          SizedBox(
                            height: 10, // TODO Maybe change
                          ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: InkWell(
                            borderRadius: borderRadius,
                            onTap: () {
                              rd.setUserId(post.userId);
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: borderRadius,
                                  child: UserBuilder(
                                    userId: post.userId,
                                    callback: (user) {
                                      if (user == null)
                                        return SizedBox(
                                          height: 48,
                                          width: 48,
                                        );

                                      return Image.network(
                                        resolveSkylink(
                                          user.picture,
                                        ),
                                        width: 48,
                                        height: 48,
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    UserBuilder(
                                      userId: post.userId,
                                      callback: (user) {
                                        if (user == null) return Text('');

                                        return buildUsernameWidget(
                                            user, context,
                                            bold: true);
                                      },
                                    ),
                                    SizedBox(
                                      height: 2,
                                    ),
                                    /*, */
                                    Tooltip(
                                      message: post.postedAt
                                          .toIso8601String(), // TODO Check
                                      child: StreamBuilder<Null>(
                                          stream: minuteStream.stream,
                                          builder: (context, snapshot) {
                                            return Text(
                                              timeago.format(post.postedAt),
                                              style: TextStyle(
                                                  fontSize: 12), // TODO check
                                            );
                                          }),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 4,
                        ),
                        if ((post.content.text ?? '').isNotEmpty)
                          /*   ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 1000),
                            child: */
                          Padding(
                            padding: EdgeInsets.only(
                              left: leftContentIndent, // 24
                              right: 40,
                              top: 8.0,
                            ),
                            child: /* post.content.text.contains('#_markdown') */
                                // TODO Markdown Text Type (need to enable)
                                /*  MarkdownBody( 
                              data: post.content.text
                                  .truncateTo(
                                    1024,
                                  )
                                  .replaceAll('\n', '\n\n'),
                              selectable: true,
                              imageBuilder: (uri, title, alt) => SizedBox(),
                              onTapLink: (text, href, title) async {
                                if (await canLaunch(href)) {
                                  launch(href);
                                }
                              },
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  height: 1.4,
                                ),
                                blockSpacing: 0,
                                a: TextStyle(
                                  height: 1.4,
                                ),
                              ),

                              // extensionSet: md.ExtensionSet.gitHubFlavored,
                            ), */
                                //Listener(
                                /* onPointerSignal: (event) {
                                print(event);
                              }, */

                                SelectableText(
                              post.content.text.truncateTo(1024),
                              // scrollPhysics: NeverScrollableScrollPhysics(),

                              //'A decentralized Twitter/Reddit/Facebook/Instagram in one? But packed with powerful tools like Skynet Send? Yes it’s possible. Stay tuned. 😀  👩🏼‍🚒 👮🏼 👮🏼‍♂️ 👮🏼‍♀️ 🕵🏼 🕵🏼‍♂️ 🕵🏼‍♀️ 💂🏼 💂🏼‍♂️ 💂🏼‍♀️ 👷🏼 👷🏼‍♂️ 👷🏼‍♀️ 🤴🏼 👸🏼 👳🏼 👳🏼‍♂️', //
                              style: TextStyle(
                                height: 1.4,
                                /* fontFamilyFallback: [
                                    'Twitter Color Emoji',
                                  ], */

                                //color: Colors.black,
                              ),
                            ),
                            /*    ), */
                          ),
                        if (audioPlayer != null) ...[
                          Container(
                            decoration: getCardDecoration(
                              context,
                              roundedCard: true,
                            ),
                            width: double.infinity,
                            margin: EdgeInsets.only(
                              left: leftContentIndent,
                              top: 8,
                              right: 8.0,
                            ),
                            padding: const EdgeInsets.all(0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /*        StreamBuilder<IcyMetadata>(
                                    stream: audioPlayer.icyMetadataStream,
                                    builder: (context, snapshot) {
                                      final meta = snapshot.data ??
                                          audioPlayer.icyMetadata;
                                      if (meta == null) return SizedBox();
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8.0, right: 8.0, top: 8.0),
                                        child: Text(
                                          '${meta?.headers?.genre} by ${meta?.info?.url}',
                                          style: TextStyle(
                                            color: SkyColors.red,
                                            fontSize: 15,
                                          ),
                                        ),
                                      );
                                    }), */
                                audioDuration == null
                                    ? Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          'Loading audio...',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.only(
                                          left: 4.0,
                                          bottom: 8,
                                        ),
                                        child: StreamBuilder<bool>(
                                            stream: audioPlayer.playingStream,
                                            builder: (context, snapshot) {
                                              return Stack(
                                                alignment: Alignment.centerLeft,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 24.0),
                                                    child:
                                                        StreamBuilder<Duration>(
                                                            stream: audioPlayer
                                                                .positionStream,
                                                            builder: (context,
                                                                snapshot) {
                                                              final pos = snapshot
                                                                      .data ??
                                                                  Duration(
                                                                      seconds:
                                                                          0);

                                                              //print(pos);

                                                              // dp.setMediaPositonForSkylink(skylink, position)
                                                              return Stack(
                                                                alignment: Alignment
                                                                    .bottomRight,
                                                                children: [
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                            .only(
                                                                        right:
                                                                            24.0),
                                                                    child: Text(
                                                                      '${renderDuration(pos.inSeconds)}/${renderDuration(audioDuration.inSeconds)}',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: SkyColors
                                                                            .grey,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Slider(
                                                                    activeColor:
                                                                        SkyColors
                                                                            .follow,
                                                                    inactiveColor:
                                                                        SkyColors
                                                                            .headerGreen,
                                                                    value: pos
                                                                            .inMilliseconds /
                                                                        audioDuration
                                                                            .inMilliseconds,
                                                                    onChanged:
                                                                        (val) {
                                                                      audioPlayer.seek(Duration(
                                                                          milliseconds:
                                                                              (audioDuration.inMilliseconds * val).round()));
                                                                    },
                                                                  ),
                                                                ],
                                                              );
                                                            }),

                                                    /* ), */
                                                  ),
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          borderRadius,
                                                      onTap: () async {
                                                        // print(audioPlayer.state);

                                                        if (audioPlayer
                                                            .playerState
                                                            .playing) {
                                                          await audioPlayer
                                                              .pause();
                                                        } else {
                                                          /*      if (audioPlayer.state == null) {
                                                        await audioPlayer.play(
                                                          resolveSkylink(post.content.audio),
                                                        );
                                                      } else { */
                                                          await audioPlayer
                                                              .play();

                                                          /*     } */
                                                        }

                                                        // setState(() {});
                                                      },
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Icon(
                                                          audioPlayer
                                                                  .playerState
                                                                  .playing
                                                              ? UniconsLine
                                                                  .pause
                                                              : UniconsLine
                                                                  .play,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }),
                                      ),
                              ],
                            ),
                          ),
                        ],
                        if (post.content.image != null ||
                            post.content.video != null)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: leftContentIndent,
                                right: 8.0,
                                top: 8,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: 460),
                                child: ClipRRect(
                                  borderRadius: borderRadius4,
                                  child: AspectRatio(
                                    aspectRatio: post.content.aspectRatio,
                                    child: (post.content.video != null &&
                                            !showImage)
                                        ? (chewieController == null
                                            ? VideoPlayer(
                                                _videoPlayerController)
                                            : Chewie(
                                                controller: chewieController,
                                              ))
                                        : GestureDetector(
                                            onTap: post.content.video != null
                                                ? null
                                                : () {
                                                    launch(
                                                      resolveSkylink(
                                                          post.content.image),
                                                    );
                                                  },
                                            child: Stack(
                                              children: [
                                                BlurHash(
                                                  hash: post.content.blurHash,
                                                  image: resolveSkylink(
                                                      post.content.image),
                                                ),
                                                if (post.content.video !=
                                                    null) ...[
                                                  InkWell(
                                                    onTap: () async {
                                                      setState(() {
                                                        showImage = false;
                                                      });
                                                      if (chewieController !=
                                                          null) {
                                                        await chewieController
                                                            .play();
                                                      } else {
                                                        await _videoPlayerController
                                                            .play();
                                                      }
                                                    },
                                                    child: Center(
                                                      child: PlayButtonWidget(),
                                                    ),
                                                  ),
                                                  if (post.content
                                                          .mediaDuration !=
                                                      null)
                                                    Positioned.fill(
                                                      child: Align(
                                                        alignment: Alignment
                                                            .bottomLeft,
                                                        child:
                                                            VideoLengthWidget(
                                                          post.content
                                                              .mediaDuration,
                                                        ),
                                                      ),
                                                    )
                                                ]
                                              ],
                                            ),
                                          ),
                                    /* FadeInImage.memoryNetwork(
                                    image: resolveSkylink(post.content.image),
                                    placeholder:
                                        decodeBlurHash(post.content.blurHash, 4, 3),
                                  ), */
                                  ),
                                ),
                              ),
                            ),
                          ),
                        /*     AspectRatio(
                            aspectRatio: 16 / 9,
                            child: BlurHash(hash: r"LhMGhT$$?Gay~VIokBs:M|oeNGoe"),
                          ), */

                        if (post.content.link != null)
                          Padding(
                            padding: EdgeInsets.only(
                              left: leftContentIndent,
                              top: 8,
                              right: 8.0,
                            ),
                            child: LinkWidget(
                              link: post.content.link,
                              linkTitle: post.content.linkTitle,
                            ),
                          ),
                        if (post.content.pollOptions != null)
                          Padding(
                            padding: EdgeInsets.only(
                              left: leftContentIndent,
                              top: 8,
                              right: 8.0,
                            ),
                            child: StreamBuilder<Map<String, List<String>>>(
                              stream: dp.getReactionsStream(fullPostId),
                              builder: (context, snapshot) {
                                if ((dp.reactions.containsKey(fullPostId) &&
                                        snapshot.data != null) ||
                                    _showPollResults) {
                                  final data = snapshot.data ?? {};

                                  int totalVotes = 0;

                                  for (final key in data.keys) {
                                    if (RegExp(r'^[0-9]+$').hasMatch(key)) {
                                      totalVotes += data[key].length;
                                    }
                                  }
                                  final _totalVotes =
                                      totalVotes == 0 ? 1 : totalVotes;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      for (final key
                                          in post.content.pollOptions.keys)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: _buildPollResultItem(
                                            post.content.pollOptions[key],
                                            (data[key] ?? []).length /
                                                _totalVotes,
                                            (data[key] ?? [])
                                                .contains(AppState.userId),
                                          ),
                                        ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          '$totalVotes votes total',
                                          style: TextStyle(
                                            color: SkyColors.follow,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      for (final key
                                          in post.content.pollOptions.keys)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .dividerColor,
                                            ),
                                            borderRadius: borderRadius,
                                            color: Theme.of(context).cardColor,
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: borderRadius,
                                              onTap: () {
                                                dp.addReaction(fullPostId, key);
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Text(
                                                  post.content.pollOptions[key],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: SkyColors.follow,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _showPollResults = true;
                                            });
                                          },
                                          child: Text(
                                            'View results',
                                            style: TextStyle(
                                              color: SkyColors.follow,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ),
                        SizedBox(
                          height: (post.content.link != null ||
                                  post.content.pollOptions != null ||
                                  post.content.image != null ||
                                  audioPlayer != null)
                              ? 6
                              : 4,
                        ),
                        StreamBuilder<Map<String, List<String>>>(
                          stream: dp.getReactionsStream(fullPostId),
                          builder: (context, snapshot) {
                            final data = snapshot.data;

                            if (data == null) return SizedBox();

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 2.0,
                                top: 8.0,
                                left: 8,
                                right: 8,
                              ),
                              child: Wrap(
                                runSpacing: 8,
                                children: [
                                  for (final key in data.keys.where((element) =>
                                      !RegExp(r'^[0-9]+$').hasMatch(element)))
                                    EmojiReactionWidget(
                                      key,
                                      data[key].length,
                                      data[key].contains(AppState.userId),
                                      onAdd: () {
                                        //print('onAdd $key');
                                        dp.addReaction(fullPostId, key);
                                      },
                                      onRemove: () {
                                        //print('onRemove $key');
                                        dp.removeReaction(fullPostId, key);
                                      },
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: leftContentIndent - 8),
                          child: Row(
                            children: [
                              if (AppState.isLoggedIn) ...[
                                InkWell(
                                  borderRadius: borderRadius,
                                  onTap: () async {},
                                  child: CustomPopupMenu(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        UniconsLine.smile,
                                        size: 16,
                                        color: SkyColors.darkGrey,
                                      ),
                                    ),
                                    menuBuilder: () => EmojiPopupMenuWidget(
                                      _emojiPopupController,
                                      callback: (emoji) {
                                        print(emoji);
                                        dp.addReaction(fullPostId, emoji);
                                      },
                                    ),
                                    pressType: PressType.singleClick,
                                    verticalMargin: -10,
                                    controller: _emojiPopupController,
                                  ),
                                ),
                                SizedBox(
                                  width: 4,
                                ),
                              ],
                              InkWell(
                                borderRadius: borderRadius,
                                onTap: () {
                                  rd.setPostId(
                                      post.userId, '${post.feedId}/${post.id}');
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        UniconsLine.commentAlt,
                                        size: 16,
                                        color: SkyColors.darkGrey,
                                      ),
                                      StreamBuilder<int>(
                                        stream: dp
                                            .getCommentsCountStream(fullPostId),
                                        builder: (context, snapshot) {
                                          String str = '  Comment';

                                          if (snapshot.data != null) {
                                            str = '  ${snapshot.data}' + str;
                                          }
                                          return Text(
                                            str, //'  17  Comment',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: SkyColors.darkGrey,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              /*         Padding(
                                            padding: const EdgeInsets.only(top: 2.0),
                                            child: Text(
                                              '🔁',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontFamily: 'OpenMoji',
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ), */

                              if (AppState.isLoggedIn) ...[
                                InkWell(
                                  borderRadius: borderRadius,
                                  onTap: (_isReposting || reposted)
                                      ? null
                                      : () async {
                                          setState(() {
                                            _isReposting = true;
                                          });
                                          try {
                                            await dp.post(
                                              isRepost: true,
                                              repostOf: fullPostId,
                                              parent: post,
                                            );

                                            reposted = true;

                                            await cacheBox.put(
                                                'repost-$fullPostId', null);
                                          } catch (e, st) {
                                            // TODO show error

                                            print(e);
                                            print(st);
                                          }

                                          //await Future.delayed(Duration(seconds: 4));

                                          setState(() {
                                            _isReposting = false;
                                          });
                                        },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        _isReposting
                                            ? SpinKitDoubleBounce(
                                                color: SkyColors.follow,
                                                size: 16,
                                              )
                                            : Icon(
                                                UniconsLine.repeat,
                                                size: 16,
                                                color: reposted
                                                    ? SkyColors.follow
                                                    : SkyColors.darkGrey,
                                              ),
                                        Text(
                                          '  Repost', //'  12  Repost',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: reposted
                                                ? SkyColors.follow
                                                : SkyColors.darkGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                InkWell(
                                  borderRadius: borderRadius,
                                  onTap: _isSaving
                                      ? null
                                      : () async {
                                          setState(() {
                                            _isSaving = true;
                                          });
                                          try {
                                            if (saved) {
                                              await dp.unsavePost(fullPostId);
                                            } else {
                                              await dp.savePost(fullPostId);
                                            }
                                          } catch (e, st) {
                                            // TODO show error

                                            print(e);
                                            print(st);
                                          }
                                          if (mounted)
                                            setState(() {
                                              _isSaving = false;
                                            });
                                          /*  setState(() {
                                      saved = !saved;
                                    }); */
                                        },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        _isSaving
                                            ? SpinKitDoubleBounce(
                                                color: SkyColors.private,
                                                size: 16,
                                              )
                                            : Icon(
                                                saved
                                                    ? UniconsSolid.bookmark
                                                    : UniconsLine.bookmark,
                                                size: 16,
                                                color: saved
                                                    ? SkyColors.private
                                                    : SkyColors.darkGrey,
                                              ),
                                        Text(
                                          '  Save',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: saved
                                                ? SkyColors.private
                                                : SkyColors.darkGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  /*  ), */
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.showComments) ...[
                          CommentsWidget(
                            fullPostId,
                            post,
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
              if (post.userId == AppState.userId)
                Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: PopupMenuButton<PostMenuOption>(
                      icon: Icon(
                        UniconsLine.ellipsisV,
                        color: SkyColors.grey,
                        size: 20,
                      ),
                      onSelected: (option) async {
                        if (option == PostMenuOption.delete) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              content: ListTile(
                                leading: SpinKitFadingGrid(
                                  color: SkyColors.red,
                                  size: 28,
                                ),
                                title: Text('Deleting your post...'),
                              ),
                            ),
                            barrierDismissible: false,
                          );
                          try {
                            await dp.deletePost(fullPostId);

                            Navigator.of(context).pop();
                            setState(() {
                              _isDeleted = true;
                            });
                          } catch (e, st) {
                            print(e);
                            print(st);
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                content: Text('Error: $e'),
                                actions: [
                                  FlatButton(
                                    child: Text('Ok'),
                                    onPressed: Navigator.of(context).pop,
                                  )
                                ],
                              ),
                            );
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<PostMenuOption>>[
                        PopupMenuItem<PostMenuOption>(
                          value: PostMenuOption.delete,
                          child: Text(
                            'Delete post',
                            style: TextStyle(
                              color: SkyColors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        /*       if (widget.showComments) ...[
          /* Padding(
            padding: const EdgeInsets.only(left: 32),
            child: */
          CommentsWidget(
            fullPostId,
          ),
          /*   ), */
        ] */
      ],
    );
  }

  Widget _buildPollResultItem(
    String label,
    double rate,
    bool voted,
  ) {
    if (rate == 0) {
      rate = 0.004;
      // rate = 0.5;
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: constraints.maxWidth,
          ),
          Text(
            label,
            style: TextStyle(
              fontWeight: voted ? FontWeight.bold : null,
            ),
          ),
          SizedBox(
            height: 4,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius4,
                  color: voted ? SkyColors.follow : Color(0xff73BF71),
                ),
                width: (constraints.maxWidth - 66) * rate,
                height: 24,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '${(rate * 100).round()}%',
                  style: TextStyle(
                    color: SkyColors.follow,
                  ),
                ),
              ),
              if (voted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Icon(
                    UniconsLine.checkCircle,
                    color: SkyColors.follow,
                    size: 20,
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }
}
