import 'package:app/app.dart';

class EmojiReactionWidget extends StatelessWidget {
  final String emoji;
  final int count;
  final bool marked;
  final Function onAdd;
  final Function onRemove;

  final List<String> userIds;

  EmojiReactionWidget(
    this.emoji,
    this.count,
    this.marked, {
    this.onAdd,
    this.onRemove,
    this.userIds,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = rd.isDarkTheme
        ? (marked
            ? const Color(
                0xff3d232e,
              )
            : const Color(
                0xff303030,
              ))
        : (marked
            ? const Color(
                0xffFFF6FA,
              )
            : const Color(
                0xffF5F5F5,
              ));

    final borderColor =
        rd.isDarkTheme ? const Color(0xff902251) : const Color(0xffFFA4CB);
    String tooltip;
    if (userIds != null) {
      for (final userId in userIds) {
        final user = users.get(userId);

        if (user != null) {
          if (tooltip != null) {
            tooltip += ', ';
          } else {
            tooltip = '';
          }
          tooltip += user?.username ?? '';
        }
      }
    }

    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: marked ? borderColor : backgroundColor,
          ),
          borderRadius: borderRadius,
          color: backgroundColor,
        ),
        margin: const EdgeInsets.only(right: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius6,
            onTap: marked ? onRemove : onAdd,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$emoji',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Noto Color Emoji',
                    ),
                  ),
                  SizedBox(
                    width: 4,
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: marked
                          ? (/* borderMagenta */ rd.isDarkTheme
                              ? null
                              : SkyColors.red)
                          : (rd.isDarkTheme ? null : const Color(0xff545454)),
                      fontSize: 12,
                      //fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(
                    width: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
