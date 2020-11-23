import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app/app.dart';
import 'package:app/model/post.dart';
import 'package:app/state.dart';
import 'package:app/widget/sky_button.dart';
import 'package:app/widget/video/play_button.dart';

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_link_preview/flutter_link_preview.dart';
import 'package:image/image.dart' as img;

import 'package:emojis/emoji.dart';
import 'package:file_picker/file_picker.dart' as fp;

import 'package:mime/mime.dart';

import 'package:video_player/video_player.dart';
import 'package:skynet/skynet.dart';

import 'link.dart';

class CreatePostWidget extends StatefulWidget {
  final Post parent;
  final String commentTo;

  final bool autofocus;

  CreatePostWidget({
    this.parent,
    this.commentTo,
    this.autofocus = false,
  });

  @override
  _CreatePostWidgetState createState() => _CreatePostWidgetState();
}

const maxTextLength = 512;

class SendIntent extends ActivateIntent {
  const SendIntent();
}

class _CreatePostWidgetState extends State<CreatePostWidget> {
  bool _isEmojiPickerExpanded = false;
  bool _isEmojiPickerAnimationInProgress = false;

  final _textCtrl = TextEditingController();

  final textStream = StreamController<Null>.broadcast();
  int textLength = 0;

  PostContent newPostContent = PostContent();

  Uint8List _imageBytes;

  bool _posting = false;

  @override
  void initState() {
    _textCtrl.addListener(() {
      textStream.add(null);
    });

    // _textCtrl.

    int lastLength = 0;

    textStream.stream.listen((_) {
      textLength = _textCtrl.text.length;

      if (textLength == lastLength) return;

      if (_error.isNotEmpty) setError('');

      if (textLength > 0 && lastLength == 0) {
        setState(() {});
      } else if (textLength == 0 && lastLength > 0) {
        setState(() {});
      } else if (textLength > maxTextLength && lastLength <= maxTextLength) {
        setState(() {});
      } else if (textLength <= maxTextLength && lastLength > maxTextLength) {
        setState(() {});
      }

      lastLength = textLength;
    });

    _actionMap = <Type, Action<Intent>>{
      SendIntent: CallbackAction(
        onInvoke: (Intent intent) {
          //print(intent);
          _post();
          return;
        },
      ),
    };
    _shortcutMap = <LogicalKeySet, Intent>{
      LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.enter,
      ): const SendIntent(),
    };

    super.initState();
  }

  @override
  void dispose() {
    textStream.close();
    super.dispose();
  }

  _handleUploadError(e) {}

  String _info = '';
  String _error = '';

  void setInfo(String msg) {
    setState(() {
      _info = msg;
    });
  }

  void setError(String msg) {
    setState(() {
      _info = '';
      _error = msg;
    });
  }

/*   bool _focused = false;
  bool _hovering = false; */

  Map<Type, Action<Intent>> _actionMap;
  Map<LogicalKeySet, Intent> _shortcutMap;

/*   Color get color {
    Color baseColor = Colors.lightBlue;
    if (_focused) {
      baseColor = Color.alphaBlend(Colors.black.withOpacity(0.25), baseColor);
    }
    if (_hovering) {
      baseColor = Color.alphaBlend(Colors.black.withOpacity(0.1), baseColor);
    }
    return baseColor;
  } */

  // bool get sendOnEnter => dataBox.get('pref_send_on_enter') ?? false;

/*   void _toggleState() {
    setState(() {
      dataBox.put('pref_send_on_enter', !sendOnEnter);
    });
  } */
/* 
  void _handleFocusHighlight(bool value) {
    setState(() {
      _focused = value;
    });
  }

  void _handleHoveHighlight(bool value) {
    setState(() {
      _hovering = value;
    });
  } */

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.commentTo != null ? null : getCardDecoration(context),
      padding: widget.commentTo != null
          ? const EdgeInsets.only(
              left: 8,
              right: 8,
              top: 16,
            )
          : const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 8,
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              rd.setUserId(AppState.userId);
            },
            child: ClipRRect(
              borderRadius: borderRadius,
              child: UserBuilder(
                userId: AppState.userId,
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
          ),
          SizedBox(
            width: 16,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FocusableActionDetector(
                  actions: _actionMap,
                  shortcuts: _shortcutMap,
                  /*       onShowFocusHighlight: _handleFocusHighlight,
                  onShowHoverHighlight: _handleHoveHighlight, */
                  child: TextField(
                    autofocus: widget.autofocus,
                    controller: _textCtrl,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      hintText: widget.commentTo == null
                          ? 'Express yourself, share and embrace your ideas...'
                          : 'Comment something...',
                      contentPadding: const EdgeInsets.only(
                        left: 16,
                        right: 19,
                        top: 19,
                        bottom: 19,
                      ),
                      errorText: textLength > maxTextLength
                          ? 'Your post text is too long!'
                          : null,
                    ),
                    style: TextStyle(
                      fontSize: 15,
                    ),
                    cursorColor: SkyColors.follow,
                    minLines: 1,
                    maxLines: 10,
                    /*  textInputAction: sendOnEnter
                        ? TextInputAction.send
                        : TextInputAction.newline,

                    onSubmitted: (s) {
                      print(s);
                    }, */
                  ),
                ),
                SizedBox(
                  height: 4,
                ),
                if (newPostContent.image != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      bottom: 4,
                    ),
                    child: ClipRRect(
                      borderRadius: borderRadius4,
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.memory(
                            _imageBytes,
                          ),
                          if (newPostContent.video != null) ...[
                            Positioned.fill(
                              child: Center(
                                child: PlayButtonWidget(),
                              ),
                            ),
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: VideoLengthWidget(
                                    newPostContent.mediaDuration),
                              ),
                            ),
                          ],
                          Align(
                            alignment: Alignment.topRight,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  newPostContent.mediaDuration = null;
                                  newPostContent.video = null;

                                  newPostContent.blurHash = null;
                                  newPostContent.aspectRatio = null;
                                  newPostContent.image = null;
                                  _imageBytes = null;
                                });
                              },
                              child: Material(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(4),
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
                      ),
                    ),
                  ),
                if (newPostContent.audio != null) ...[
                  SizedBox(
                    height: 4,
                  ),
                  Stack(
                    children: [
                      Container(
                        decoration:
                            getCardDecoration(context, roundedCard: true),
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Icon(
                              UniconsLine.music,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text('Audio'),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              newPostContent.audio = null;
                            });
                          },
                          child: Material(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(8),
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
                  ),
                ],
                if (newPostContent.link != null) ...[
                  SizedBox(
                    height: 4,
                  ),
                  ClipRRect(
                    borderRadius: borderRadius,
                    child: Stack(
                      children: [
                        LinkWidget(
                          link: newPostContent.link,
                          linkTitle: newPostContent.linkTitle,
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                newPostContent.link = null;
                                newPostContent.linkTitle = null;
                              });
                            },
                            child: Material(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(8),
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
                    ),
                  ),
                ],
                Material(
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_info.isNotEmpty) ...[
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Text(_info),
                      ],
                      if (_error.isNotEmpty) ...[
                        Icon(
                          UniconsLine.exclamationTriangle,
                          color: SkyColors.red,
                          size: 16,
                        ),
                        SizedBox(
                          width: 4,
                        ),
                        Text(
                          _error,
                          style: TextStyle(
                            color: SkyColors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      Spacer(),
                      if (newPostContent.link == null)
                        _buildIconButton(
                          // Add link
                          iconData: UniconsLine.linkAdd,
                          onTap: () async {
                            try {
                              final _ctrl = TextEditingController();

                              String _url = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                        title: Text('Paste your link'),
                                        content: TextField(
                                          controller: _ctrl,
                                          autofocus: true,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(),
                                            hintText: 'https://...',
                                          ),
                                        ),
                                        actions: [
                                          FlatButton(
                                            onPressed:
                                                Navigator.of(context).pop,
                                            child: Text('Cancel'),
                                          ),
                                          FlatButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(_ctrl.text),
                                            child: Text('Add link'),
                                          ),
                                        ],
                                      ));

                              if ((_url ?? '').isNotEmpty) {
                                final uri = Uri.parse(_url);

                                String hnsDomain;

                                if (uri.host.contains('.hns.')) {
                                  final parts = uri.host.split('.hns.');
                                  _url =
                                      _url.replaceFirst(uri.host, parts.last);
                                  hnsDomain = parts.first;
                                }
                                //  print('_url $_url');

                                for (final portal in [
                                  'siasky.net',
                                  'skyportal.xyz',
                                  'skynethub.io',
                                  'siacdn.com',
                                  'skydrain.net',
                                  'sialoop.net',
                                ]) {
                                  _url = _url
                                      .replaceFirst(
                                          'https://$portal/', 'sia://')
                                      .replaceFirst(
                                          'https://$portal', 'sia://');
                                }

                                //print('_url $_url');

                                if (hnsDomain != null) {
                                  _url = _url.replaceFirst(
                                      'sia://', 'sia://$hnsDomain.hns/');
                                }

                                if (kIsWeb) {
                                  setState(() {
                                    newPostContent.link = _url;
                                  });
                                } else {
                                  final WebInfo info =
                                      await WebAnalyzer.getInfo(
                                    resolveSkylink(_url),
                                    multimedia: false,
                                    useMultithread: true,
                                  );

                                  if (info != null) {
                                    setState(() {
                                      newPostContent.link = _url;
                                      newPostContent.linkTitle = info.title;
                                    });
                                  }
                                }
                              }
                            } catch (e, st) {
                              print(e);
                              print(st);
                            }

                            //final file = result.files.single;
                            /*        FilePickerCross result =
                              await FilePickerCross.platform.pickFiles(
                            allowMultiple: false,
                            type: FileType.image,
                          ); */
                            /*        print(file.name);
                            print(file.path);
                            print(file.extension);
                            print(file.size); */
                          },
                        ),
                      if (newPostContent.image == null)
                        _buildIconButton(
                          // Upload image
                          iconData: UniconsLine.image,
                          onTap: () async {
                            try {
                              final result =
                                  await fp.FilePicker.platform.pickFiles(
                                type: fp.FileType.image,
                                withData: true,
                              );

                              if (result != null) {
                                // TODO package:exif

                                final file = result.files.first;

                                _imageBytes = file.bytes;

                                print(_imageBytes.length);

                                final type = lookupMimeType(
                                  file.name,
                                  headerBytes: _imageBytes.sublist(0, 12),
                                );

                                print(type);
                                setInfo('Converting image...');
                                await Future.delayed(
                                    Duration(milliseconds: 200));

                                try {
                                  final PostContent res = await compute(
                                      calculateImageStuff, _imageBytes);

                                  print(res.aspectRatio);

                                  setInfo('Uploading image...');

                                  final skylink = await uploadFile(SkyFile(
                                    content: _imageBytes,
                                    filename: file.name,
                                    type: type,
                                  ));

                                  print(skylink);

                                  newPostContent.aspectRatio = res.aspectRatio;
                                  newPostContent.blurHash = res.blurHash;

                                  newPostContent.image = 'sia://$skylink';
                                } catch (e, st) {
                                  print(e);
                                  print(st);
                                  _handleUploadError(e);
                                }

                                setInfo('');
                                setState(() {});
                              }
                            } catch (e, st) {
                              print(e);
                              print(st);
                            }
                          },
                        ),
                      if (newPostContent.video == null &&
                          newPostContent.audio == null)
                        _buildIconButton(
                          // Upload video
                          iconData: UniconsLine.film,

                          tooltip: newPostContent.image == null
                              ? 'You need to upload a thumbnail before uploading a video'
                              : '.mp4 and .webm only',

                          enabled: newPostContent.image != null,

                          onTap: () async {
                            try {
                              final result =
                                  await fp.FilePicker.platform.pickFiles(
                                type: fp.FileType.video,
                                allowedExtensions: [
                                  'mp4',
                                  'webm',
                                ],
                                withData: false,
                                withReadStream: true,
                              );

                              if (result != null) {
                                // TODO package:exif

                                /*   final type = lookupMimeType(
                                  result.fileName,
                                  headerBytes:
                                      result.toUint8List().sublist(0, 12),
                                ); */

                                final file = result.files.first;

                                setInfo('Uploading video...');

                                try {
                                  final skylink = await uploadFileWithStream(
                                    SkyFile(
                                      filename: file.name,
                                    ),
                                    file.size,
                                    file.readStream,
                                  );

                                  print(skylink);

                                  setInfo('Generating metadata...');

                                  VideoPlayerController controller =
                                      new VideoPlayerController.network(
                                          resolveSkylink('sia://$skylink'));

                                  await controller.initialize();

                                  print(controller.value.duration);

                                  newPostContent.mediaDuration =
                                      controller.value.duration.inMilliseconds;

                                  newPostContent.video = 'sia://$skylink';

                                  controller.dispose();
                                } catch (e, st) {
                                  print(e);
                                  print(st);
                                  _handleUploadError(e);
                                }

                                setInfo('');
                                setState(() {});
                              }
                            } catch (e, st) {
                              print(e);
                              print(st);
                            }
                          },
                        ),
                      if (newPostContent.video == null &&
                          newPostContent.audio == null)
                        _buildIconButton(
                          // Upload audio
                          iconData: UniconsLine.music,
                          onTap: () async {
                            try {
                              final result =
                                  await fp.FilePicker.platform.pickFiles(
                                type: fp.FileType.audio,
                                withData: false,
                                withReadStream: true,
                              );

                              if (result != null) {
                                final file = result.files.first;

                                setInfo('Uploading audio...');

                                try {
                                  final skylink = await uploadFileWithStream(
                                    SkyFile(
                                      filename: file.name,
                                    ),
                                    file.size,
                                    file.readStream,
                                  );

                                  print(skylink);

                                  newPostContent.audio = 'sia://$skylink';
                                } catch (e, st) {
                                  print(e);
                                  print(st);
                                  _handleUploadError(e);
                                }

                                setInfo('');
                                setState(() {});
                              }
                            } catch (e, st) {
                              print(e);
                              print(st);
                            }
                          },
                        ),
                      _buildIconButton(
                        // Emoji picker
                        iconData: UniconsLine.smile,
                        onTap: () async {
                          setState(() {
                            _isEmojiPickerAnimationInProgress = true;
                            _isEmojiPickerExpanded = !_isEmojiPickerExpanded;
                          });
                        },
                      ),
                      /*  SizedBox(
                        // 0xe930 OLD
                        width: 8,
                      ), */
                      SizedBox(
                        width: 52,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: StreamBuilder<Null>(
                              stream: textStream.stream,
                              builder: (context, snapshot) {
                                return Text(
                                  '${_textCtrl.text.length}/$maxTextLength',
                                  style: TextStyle(
                                    color: textLength > maxTextLength
                                        ? SkyColors.red
                                        : SkyColors.darkGrey,
                                    fontSize: 12,
                                  ),
                                );
                              }),
                        ),
                      ),
                      SizedBox(
                        width: 8,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 4,
                ),
                AnimatedContainer(
                  height: _isEmojiPickerExpanded ? 128 : 0,
                  child: _isEmojiPickerExpanded ||
                          _isEmojiPickerAnimationInProgress
                      ? Container(
                          decoration: getCardDecoration(
                            context,
                            roundedCard: true,
                          ),
                          margin: const EdgeInsets.only(bottom: 4),
                          child: Material(
                            color: Colors.transparent,
                            child: GridView.count(
                              padding: const EdgeInsets.all(8),
                              crossAxisCount: 10,
                              children: [
                                for (final emoji
                                    in Emoji.byGroup(EmojiGroup.smileysEmotion))
                                  InkWell(
                                    borderRadius: borderRadius,
                                    onTap: () {
                                      int position = _textCtrl.selection.start;

                                      if (position == -1) position = 0;

                                      _textCtrl.text = _textCtrl.text
                                              .substring(0, position) +
                                          emoji.char +
                                          _textCtrl.text.substring(position);

                                      _textCtrl.selection = TextSelection(
                                        baseOffset:
                                            position + emoji.char.length,
                                        extentOffset:
                                            position + emoji.char.length,
                                      );
                                    },
                                    child: Center(
                                      child: Text(
                                        emoji.char,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(),
                  onEnd: () {
                    setState(() {
                      _isEmojiPickerAnimationInProgress = false;
                    });
                  },
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOutCubic,
                ),
                /* SizedBox(
                  height: 4,
                ), */

                if (rd.isMobile) ...[
                  SizedBox(
                    height: 2,
                  ),
                  SizedBox(
                    height: 48,
                    child: SkyButton(
                      enabled: textLength > 0 &&
                          textLength <= maxTextLength, // TODO Check this
                      filled: true,
                      label: widget.commentTo == null ? 'Post' : 'Comment',
                      color: SkyColors.follow,
                      onPressed: _posting ? null : _post,
                    ),
                  ),
                  SizedBox(
                    height: 6,
                  ),
                ],
              ],
            ),
          ),
          if (!rd.isMobile) ...[
            SizedBox(
              width: 8,
            ),
            SizedBox(
              width: widget.commentTo == null ? 72 : 100,
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: SkyButton(
                      enabled: textLength > 0 &&
                          textLength <= maxTextLength, // TODO Check this
                      filled: true,
                      label: widget.commentTo == null ? 'Post' : 'Comment',
                      color: SkyColors.follow,
                      onPressed: _posting ? null : _post,
                    ),
                  ),
                  /*      if (sendOnEnter)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Post on Enter is enabled',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ), */
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _post() async {
    if (_posting) return;
    if (_info.isNotEmpty) return;
    try {
      setError('');
      newPostContent.text = _textCtrl.text;

      if (newPostContent.text.trim().length == 0) {
        if (newPostContent.audio == null &&
            newPostContent.image == null &&
            newPostContent.link == null) {
          throw Exception('Empty text');
        }
      } else if (newPostContent.text.length > maxTextLength) {
        throw Exception('Text too long');
      }

      print(newPostContent.toJson());
      print(json.encode(newPostContent));

      setState(() {
        _posting = true;
      });

      setInfo('Posting...');
      /* try { */

      // ! ~/dev/flutter/.pub-cache/hosted/pub.dartlang.org/cryptography-1.4.1/lib/src/algorithms/sha1_sha2.dart:243 to :255

      if (widget.commentTo != null) {
        await dp.post(
          newPostContent: newPostContent,
          isComment: true,
          commentTo: widget.commentTo,
          parent: widget.parent,
        );
      } else {
        await dp.post(
          newPostContent: newPostContent,
        );
      }

      if (widget.autofocus == true) {
        rd.pop();
      }
      /*     } catch (e, st) {
                                print(e);
                                print(st);
                              } */

      setState(() {
        _info = '';
        _posting = false;
        _textCtrl.clear();

        /*        newPostContent.mediaDuration = null;
                                newPostContent.video = null;

                                newPostContent.blurHash = null;
                                newPostContent.aspectRatio = null;
                                newPostContent.image = null; */

        _imageBytes = null;

        newPostContent = PostContent();
      });
    } catch (e, st) {
      print(e);
      print(st);
      _posting = false;

      setError(e.toString().split(':').last.trim());
    }
  }

  Widget _buildIconButton({
    IconData iconData,
    Function onTap,
    bool enabled = true,
    String tooltip,
  }) {
    final widget = InkWell(
      borderRadius: borderRadius,
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(
          iconData,
          color: rd.isDarkTheme
              ? (enabled ? SkyColors.grey2 : Theme.of(context).dividerColor)
              : (enabled ? SkyColors.darkGrey : SkyColors.grey),
          size: 22,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: widget,
      );
    }
    return widget;
  }
}

Future<PostContent> calculateImageStuff(Uint8List data) async {
  img.Image image = img.decodeImage(data);

  return PostContent()
    ..aspectRatio = image.width / image.height
    ..blurHash = encodeBlurHash(
      image.getBytes(format: img.Format.rgba),
      image.width,
      image.height,
    );
}
