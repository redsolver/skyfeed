import 'dart:async';

import 'package:app/app.dart';
import 'package:app/widget/user.dart';

class ChatWidget extends StatefulWidget {
  @override
  _ChatWidgetState createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  StreamSubscription _followingSub;

  @override
  void initState() {
    super.initState();

    _followingSub = dp.onFollowingChange.stream.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _followingSub.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keys = dp.getFollowKeys();
    //if (keys.isEmpty) return SizedBox();

    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: rd.isMobile ? double.infinity : 256),
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
                  'Following',
                  style: titleTextStyle,
                ),
              ),
            for (final userId in keys)
              UserWidget(
                userId: userId,
                key: ValueKey(userId),
                onPressed: () {
                  rd.setUserId(userId);
                },
              ),
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
