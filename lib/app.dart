export 'package:flutter/material.dart';

export 'package:app/icons.dart';

import 'dart:async';

import 'package:app/data.dart';
import 'package:app/main.dart';
import 'package:app/state.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:skynet/skynet.dart';

import 'model/user.dart';

LazyBox cacheBox;
Box revisionCache;

Box users;

LazyBox followingBox;
LazyBox followersBox;

LazyBox feedPages;

LazyBox commentsIndex;

LazyBox reactionsBox;

Box pointerBox;

Box dataBox;

extension StringExtension on String {
  String truncateTo(int maxLength) =>
      (this.length <= maxLength) ? this : '${this.substring(0, maxLength)}...';
}

String resolveSkylink(String link, {bool trusted = false}) {
  // TODO Tests
  if (link.startsWith('sia://')) {
    final uri = Uri.tryParse(link);

    if (uri == null) return null;

    final host = uri.host;

    if (host.endsWith('.hns')) {
      return 'https://${host.split(".").first}.hns.${SkynetConfig.host}/${link.substring(6 + host.length + 1)}';
    } else {
      return 'https://${SkynetConfig.host}/' + link.substring(6);
    }
  }

  if (trusted) {
    return link;
  } else {
    return '';
  }

/*       msgText = msgText.replaceAllMapped('sia://', (match) {
          final str =
              msgText.substring(match.end).split(' ').first.split('/').first;

          if (str.length < 46) {
            return 'https://${SkynetConfig.host}/hns/';
          } else {
            return 'https://${SkynetConfig.host}/';
          }
        }); */
}

final borderRadius = BorderRadius.circular(8);
final borderRadius4 = BorderRadius.circular(4);

const mobileBreakpoint = 740;
const tabletBreakpoint = 1260;

final ws = SkyDBoverWS();

final dp = DataProcesser();

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
      rd.isDarkTheme ? Color(0xff3F3F3F) : Color(0xffd5ecdb);
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
