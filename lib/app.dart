export 'package:flutter/material.dart';

export 'package:app/icons.dart';

import 'dart:async';

import 'package:app/data.dart';
import 'package:app/main.dart';
import 'package:app/state.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:skynet/skynet.dart';

import 'global.dart';
import 'model/user.dart';

export 'global.dart';
export 'utils/skylink.dart';

typedef Widget UserCallback(User user); //function signature

class UserBuilder extends StatefulWidget {
  final String userId;
  final UserCallback callback;

  UserBuilder({
    @required this.userId,
    @required this.callback,
  });

  @override
  _UserBuilderState createState() => _UserBuilderState();
}

class _UserBuilderState extends State<UserBuilder> {
  Stream<User> stream;

  final int localId = dp.getLocalId();
  @override
  void initState() {
    super.initState();

    stream = processStream(getUserStream(widget.userId, localId));
  }

  @override
  void dispose() {
    // print('dispose');
    dp.removeProfileStream(widget.userId, localId);

    super.dispose();
  }

  User cachedUser;

  Stream<User> processStream(Stream<User> s) async* {
    await for (final u in s) {
      if (u == null) {
        yield cachedUser;
      } else {
        if (u.username != cachedUser?.username ||
            u.picture != cachedUser?.picture ||
            u.bio != cachedUser?.bio) {
          //print('OLD ${json.encode(cachedUser)}');
          // print('NEW ${json.encode(u)}');
          // TODO more efficient
          yield u;
          cachedUser = u;
        } else {
          //print('same');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User>(
      stream: stream,
      builder: (context, snapshot) => widget.callback(snapshot.data),
    );
  }
}

Stream<User> getUserStream(String userId, int localId) async* {
  // print('getUserStream $userId');

  // TODO optimize speed

  // print('local$localId ${DateTime.now()}');

  final initialUser = users.get(userId);
  // print('local$localId ${DateTime.now()}');

  if (initialUser != null) {
    initialUser.id = userId;

    yield initialUser;
  }

  yield* dp.getProfileStream(userId, localId);
}


final borderRadius = BorderRadius.circular(8);
final borderRadius4 = BorderRadius.circular(4);
final borderRadius6 = BorderRadius.circular(6);

const mobileBreakpoint = 740;
const tabletBreakpoint = 1260;

class SkyColorsDark extends SkyColors {}

class SkyColors {
  static const follow = Color(0xff19B417);
  static const private = Color(0xff248ADB);

  static const red = Color(0xffEC1873);

  static Color get black => rd.isDarkTheme ? Colors.white : Color(0xff000000);

  // rd.isDark

  static const grey1 = Color(0xff737373); // Dark
  static const grey2 = Color(0xff8c8c8c); // Normal

  static const grey3 = Color(0xff969696); // actions in dark theme

  static const grey4 = Color(0xffcccccc); // Light

  static Color get darkGrey => rd.isDarkTheme ? grey3 : grey1;
  static Color get grey => rd.isDarkTheme ? const Color(0xffA5A5A5) : grey2;
  // static Color get veryLightGrey =>

  static Color get headerGreen =>
      rd.isDarkTheme ? Color(0xff303030) : Color(0xffd5ecdb);
}

final minuteStream = StreamController<Null>.broadcast();

final titleTextStyle = TextStyle(
  fontWeight: FontWeight.bold,
  fontSize: 16,
);

Divider get appBarDivider => Divider(
      height: 1,
      thickness: 1,
      color: SkyColors.headerGreen,
    );

/* class GlobalNavigationState {
  String selectedUserId;
  String selectedPostId;

  void update() => streamCtrl.add(true);

  final streamCtrl = StreamController<bool>();
} */

SkyRouterDelegate rd;
SkyRouteInformationParser routeInformationParser;
/* 
final gns = GlobalNavigationState(); */

BoxDecoration getCardDecoration(BuildContext context,
    {bool roundedCard = false}) {
  return BoxDecoration(
    border: rd.isMobile && !roundedCard
        ? null
        : Border.all(
            color: Theme.of(context).dividerColor,
          ),
    borderRadius: rd.isMobile && !roundedCard ? null : borderRadius,
    color: Theme.of(context).cardColor,
  );
}

runAndHandleException(BuildContext context, Function f) {
  try {
    f();
  } catch (e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$e'),
        actions: [
          FlatButton(
            child: Text('Ok'),
            onPressed: Navigator.of(context).pop,
          ),
        ],
      ),
    );
  }
}

Widget buildUsernameWidget(
  User user,
  BuildContext context, {
  bool bold = false,
  bool italic = false,
  double fontSize,
}) {
  return Text(
    '${user.username}',
    style: TextStyle(
      color: user.id == AppState.userId
          ? SkyColors.red
          : dp.isFollowing(user.id)
              ? SkyColors.follow
              : dp.isFollowingPrivately(user.id)
                  ? SkyColors.private
                  : SkyColors.black,
      fontWeight: bold ? FontWeight.bold : null,
      fontStyle: italic ? FontStyle.italic : null,
      fontSize: fontSize,
    ),
  );
}
