import 'package:app/app.dart';

class PlayButtonWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: 64,
      child: Material(
        borderRadius: BorderRadius.circular(32),
        color: SkyColors.darkGrey.withOpacity(0.8),
        child: Icon(
          UniconsLine.play,
          size: 42,
          color: Colors.white,
        ),
      ),
    );
  }
}

String renderDuration(int x) {
  String secs = (x % 60).toString();
  if (secs.length == 1) secs = '0$secs';

  String mins = ((x % 3600) / 60).floor().toString();
  if (mins.length == 1) mins = '0$mins';

  String str = '$mins:$secs';

  if (x >= 3600) {
    str = '${(x / 3600).floor()}:$str';
  }

  return str;
}

class VideoLengthWidget extends StatelessWidget {
  final int duration;

  VideoLengthWidget(this.duration);

  @override
  Widget build(BuildContext context) {
    /* final d = Duration(milliseconds: duration); */

    return SizedBox(
      child: Material(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(4),
        ),
        color: SkyColors.darkGrey.withOpacity(0.8),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(
            renderDuration((duration / 1000).round()),
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
