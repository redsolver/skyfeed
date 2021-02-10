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
                    itemCount: emojiGroups.length + 1,
                    itemBuilder: (context, index) {
                      String emojiGroupName;

                      final emojis = <String>[];

                      if (index == 0) {
                        emojiGroupName = 'Frequently used';
                        final Map<String, int> usage = {};

                        for (final reacts in dp.reactions.values) {
                          for (final r in reacts) {
                            if (RegExp(r'^[0-9]+$').hasMatch(r)) continue;
                            usage.putIfAbsent(r, () => 0);
                            usage[r]++;
                          }
                        }
                        emojis.addAll(usage.keys);
                        emojis.sort((a, b) => -usage[a].compareTo(usage[b]));
                      } else {
                        final emojiGroup = emojiGroups[index - 1];
                        emojiGroupName = emojiGroup.name;

                        emojis.addAll(
                            Emoji.byGroup(emojiGroup.group).map((e) => e.char));
                        if (emojiGroup.group == EmojiGroup.smileysEmotion) {
                          emojis.addAll(
                              //Emoji.byShortName('thumbsup'),
                              Emoji.bySubgroup(EmojiSubgroup.handFingersClosed)
                                  .map((e) => e.char)

                              /* Emoji.byGroup(EmojiGroup.peopleBody) */);
                        }
                      }

                      final List<List<String>> rows = [];

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
                              '${emojiGroupName}',
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
                                          onTap: () => _select(item),
                                          child: Center(
                                            child: Container(
                                              height: 28,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(4.0),
                                                child: Text(
                                                  item,
                                                  style: TextStyle(
                                                    fontFamily:
                                                        'Noto Color Emoji',
                                                  ),
                                                ),
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
