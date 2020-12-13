import 'package:app/app.dart';

class EmojiReactionWidget extends StatelessWidget {
  final String emoji;
  final int count;
  final bool marked;
  final Function onAdd;
  final Function onRemove;

  EmojiReactionWidget(
    this.emoji,
    this.count,
    this.marked, {
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: marked
              ? SkyColors.red
              : Theme.of(context).scaffoldBackgroundColor,
        ),
        borderRadius: borderRadius,
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: marked ? onRemove : onAdd,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              '$emoji  $count',
              style: TextStyle(
                color: marked ? SkyColors.red : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
