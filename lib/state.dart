import 'dart:convert';

import 'package:app/app.dart';
import 'package:app/model/user.dart';
import 'package:flutter/material.dart';
import 'package:skynet/skynet.dart';

class AppState {
  static SkynetUser skynetUser;

  static String userId;

  static final publicUser =
      SkynetUser.fromSeed(List.generate(32, (index) => 0));

  static bool get isLoggedIn => userId != null;
}

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
