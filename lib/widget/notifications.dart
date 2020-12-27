import 'dart:async';

import 'package:app/app.dart';
import 'package:app/widget/user.dart';

/* class NotificationsPageOld extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPageOld> {
  StreamSubscription _sub;

  @override
  void initState() {
    super.initState();

    _sub = dp.onNotificationsChange.stream.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _sub.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (dp.requestFollow.isEmpty && dp.requestMention.isEmpty)
      return SizedBox(
        width: double.infinity,
      );

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: getCardDecoration(context),
        child: ListView(
          // TODO Scrollbar
          shrinkWrap: true,
          padding: const EdgeInsets.all(8.0),
          children: [
            if (!rd.isMobile)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Notifications',
                  style: titleTextStyle,
                ),
              ),
            /*   Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  'SkyFeed is currently in beta. This card will soon show all your important notifications.\n\nBeta 0.2.1'),
            ), */

            // TODO Notifications (comments on your posts, new followers) only for people you're following!

            for (final userId in dp.requestFollow.keys)
              NotificationUserFollowWidget(userId: userId),
            if (rd.isMobile)
              SizedBox(
                height: 72,
              ),
          ],
        ),
      ),
    );
  }
}
 */
class NotificationUserFollowWidget extends StatefulWidget {
  const NotificationUserFollowWidget({
    Key key,
    @required this.userId,
  }) : super(key: key);

  final String userId;

  @override
  _NotificationUserFollowWidgetState createState() =>
      _NotificationUserFollowWidgetState();
}

class _NotificationUserFollowWidgetState
    extends State<NotificationUserFollowWidget> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: getCardDecoration(context),
      child: UserWidget(
        userId: widget.userId,
        key: ValueKey(widget.userId),
        onPressed: () {
          rd.setUserId(widget.userId);
        },
        details: 'followed you',
        isLoading: _loading == true,
        onAccept: _loading == null
            ? null
            : () async {
                setState(() {
                  _loading = true;
                });
                await dp.addUserToFollowers(widget.userId);

                await dp.removeUserFromPublicRequestFollow(widget.userId);

                setState(() {
                  _loading = null;
                });
              },
        onReject: _loading == null
            ? null
            : () async {
                setState(() {
                  _loading = true;
                });
                await dp.removeUserFromPublicRequestFollow(widget.userId);
                setState(() {
                  _loading = null;
                });
              },
      ),
    );
  }
}
