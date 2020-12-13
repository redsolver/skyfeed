import 'dart:math';

import 'package:app/app.dart';
import 'package:app/utils/emoji_groups.dart';
import 'package:app/widget/custom_popup_menu.dart';

import 'package:emojis/emoji.dart';

class EmojiPopupMenuWidget extends StatelessWidget {
  final CustomPopupMenuController _emojiPopupController;

  final Function callback;

  EmojiPopupMenuWidget(this._emojiPopupController, {this.callback});

  final textFieldController = TextEditingController();

  void _select(
    String emoji,
  ) {
    _emojiPopupController.hideMenu();
    callback(emoji);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        color: Theme.of(context).cardColor,
        child: IntrinsicWidth(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _emojiPopupController.hideMenu,
            child: Container(
              height: 300,
              width: 300,
              child: Material(
                  color: Colors.transparent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: emojiGroups.length,
                    itemBuilder: (context, index) {
                      final emojiGroup = emojiGroups[index];

                      final emojis = Emoji.byGroup(emojiGroup.group).toList();
                      if (emojiGroup.group == EmojiGroup.smileysEmotion) {
                        emojis.addAll(
                            //Emoji.byShortName('thumbsup'),
                            Emoji.bySubgroup(EmojiSubgroup.handFingersClosed)

                            /* Emoji.byGroup(EmojiGroup.peopleBody) */);
                      }

                      final List<List<Emoji>> rows = [];

                      while (emojis.isNotEmpty) {
                        // print('TAKE');

                        final count = min(10, emojis.length);

                        rows.add(emojis.take(count).toList());
                        emojis.removeRange(0, count);
                      }
                      // print(rows);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 4,
                              left: 4,
                            ),
                            child: Text(
                              '${emojiGroup.name}',
                              style: titleTextStyle,
                            ),
                          ),
                          Table(
                            children: [
                              for (final row in rows)
                                TableRow(
                                  children: [
                                    for (final item in row)
                                      TableCell(
                                        child: InkWell(
                                          borderRadius: borderRadius,
                                          onTap: () => _select(item.char),
                                          child: Center(
                                            child: Container(
                                              height: 28,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(4.0),
                                                child: Text(item.char),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    for (int i = 0; i < (10 - row.length); i++)
                                      TableCell(child: SizedBox()),
                                  ],
                                )
                            ],
                          ),

                          /*                    GridView.count(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            primary: true,
                            crossAxisCount: 10,
                            children: [
                              for (final emoji
                                  in )
                                InkWell(
                                  borderRadius: borderRadius,
                                  onTap: () {
                                    print(emoji.char);
                                    /*     int position = _textCtrl.selection.start;

                              if (position == -1) position = 0;

                              _textCtrl.text = _textCtrl.text.substring(0, position) +
                                  emoji.char +
                                  _textCtrl.text.substring(position);

                              _textCtrl.selection = TextSelection(
                                baseOffset: position + emoji.char.length,
                                extentOffset: position + emoji.char.length,
                              ); */
                                  },
                                  child: Center(
                                    child: Text(
                                      emoji.char,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ), */
                          SizedBox(
                            height: 8,
                          ),
                        ],
                      );
                    },
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
