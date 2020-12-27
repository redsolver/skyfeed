import 'package:app/app.dart';

class NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Function onTap;
  final Color color;
  final int notificationCount;

  NavigationItem({
    this.icon,
    this.label,
    this.onTap,
    this.color,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Row(
        children: [
          Container(
            decoration: getCardDecoration(context),
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              top: 6.0,
              bottom: 10.0,
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          SizedBox(
            width: 12,
          ),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            /* ), */
          ),
          if (notificationCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Material(
                shape: CircleBorder(),
                elevation: 0,
                color: SkyColors.red,
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    notificationCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
