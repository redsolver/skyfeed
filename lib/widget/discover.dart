import 'dart:async';

import 'package:app/app.dart';
import 'package:app/state.dart';
import 'package:app/widget/user.dart';

class DiscoverWidget extends StatefulWidget {
  @override
  _DiscoverWidgetState createState() => _DiscoverWidgetState();
}

class _DiscoverWidgetState extends State<DiscoverWidget> {
  StreamSubscription _followingSub;

  @override
  void initState() {
    super.initState();

    _loadSuggestions();

    _followingSub = dp.onFollowingChange.stream.listen((_) {
      _loadSuggestions();
    });
  }

  @override
  void dispose() {
    _followingSub.cancel();

    super.dispose();
  }

  _loadSuggestions() async {
    suggestedUsers = await dp.getSuggestedUsers();

    setState(() {});
  }

  List<String> suggestedUsers = [];

  @override
  Widget build(BuildContext context) {
    if (suggestedUsers.isEmpty) return SizedBox();

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
                  'Suggestions to follow',
                  style: titleTextStyle,
                ),
              ),
            for (final userId in suggestedUsers) ...[
              UserWidget(
                userId: userId,
                key: ValueKey(userId),
                onPressed: () {
                  rd.setUserId(userId);
                },
              ),
              /*       HashtagWidget(
                hashtag: 'cats',
              ), */
            ],
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
