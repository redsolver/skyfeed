import 'package:app/app.dart';
import 'package:app/state.dart';
import 'package:app/widget/sky_button.dart';
import 'package:app/widget/user.dart';

class UserInfoWidget extends StatefulWidget {
  final String userId;

  UserInfoWidget(this.userId, {Key key}) : super(key: key);

  @override
  _UserInfoWidgetState createState() => _UserInfoWidgetState();
}

class _UserInfoWidgetState extends State<UserInfoWidget> {
  String get userId => widget.userId;

  @override
  void initState() {
    super.initState();
  }

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    // final userId = rd.selectedUserId;

    return Container(
      decoration: getCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 16.0,
          right: 16,
          bottom: 16,
          left: 8,
        ),
        child: Column(
          children: [
            UserBuilder(
                userId: widget.userId,
                callback: (user) {
                  if (user == null) return SizedBox();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: borderRadius,
                              child: Image.network(
                                resolveSkylink(
                                  user.picture,
                                ),
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 2,
                                ),
                                buildUsernameWidget(
                                  user,
                                  context,
                                  bold: true,
                                  fontSize: 16,
                                ),
                                SizedBox(
                                  height: 4,
                                ),

                                /*, */
                                /*     Text(
                                  userId.substring(0, 7) + '...',
                                  style: TextStyle(fontSize: 13), // TODO check
                                ), */
                                Text(
                                  user.location ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: SkyColors.grey,
                                  ),
                                ),
                                /* Text(
                                  '<\$[LOCATION]\$>', 
                                  style: TextStyle(fontSize: 13),
                                ), */
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Material(
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            InkWell(
                              borderRadius: borderRadius,
                              onTap: () async {
                                showUsersDialog(
                                  context: context,
                                  userIds: (await dp.getFollowingFor(userId))
                                      .keys
                                      .toList()
                                      .cast<String>(),
                                  title: 'Following',
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: FutureBuilder<int>(
                                    future: dp.getFollowingCount(userId),
                                    builder: (context, snapshot) {
                                      if (snapshot.data == null)
                                        return SizedBox();
                                      return Text(
                                        '${snapshot.data} following',
                                        style: TextStyle(
                                          color: SkyColors.follow,
                                          // fontSize: 13,
                                        ),
                                      );
                                    }),
                              ),
                            ),
                            InkWell(
                              borderRadius: borderRadius,
                              onTap: () async {
                                showUsersDialog(
                                  context: context,
                                  userIds: (await dp.getFollowersFor(userId))
                                      .keys
                                      .toList()
                                      .cast<String>(),
                                  title: 'Followers',
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: FutureBuilder<int>(
                                    future: dp.getFollowersCount(userId),
                                    builder: (context, snapshot) {
                                      if (snapshot.data == null)
                                        return SizedBox();
                                      return Text(
                                        '${snapshot.data} followers',
                                        style: TextStyle(
                                          color: SkyColors.follow,
                                          // fontSize: 13,
                                        ),
                                      );
                                    }),
                              ),
                            ),
                            /* TODO InkWell(
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '${dp.getFollowersCount(userId)} followers',
                                  style: TextStyle(
                                    color: SkyColors.follow,
                                  ),
                                ),
                              ),
                            ), */
                          ],
                        ),
                      ),
                      if ((user.bio ?? '').isNotEmpty) ...[
                        SizedBox(
                          height: 4,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            '${user.bio}',
                            /*   style: TextStyle(
                              fontSize: 14,
                            ), */
                          ),
                        ),
                      ],
                    ],
                  );
                }),
            if (AppState.userId != userId && AppState.isLoggedIn) ...[
              SizedBox(
                height: 16,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  children: [
                    if (_loading)
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    if (!dp.isFollowingPrivately(userId)) ...[
                      SkyButton(
                        filled: dp.isFollowing(userId),
                        label: dp.isFollowing(userId) ? 'Following' : 'Follow',
                        color: SkyColors.follow,
                        onPressed: _loading
                            ? null
                            : dp.isFollowing(userId)
                                ? () async {
                                    setState(() {
                                      _loading = true;
                                    });
                                    await dp.unfollow(userId);
                                    if (mounted)
                                      setState(() {
                                        _loading = false;
                                      });
                                  }
                                : () async {
                                    setState(() {
                                      _loading = true;
                                    });
                                    await dp.follow(userId);

                                    /*   dp.log(
                                        'following', dp.following.toString()); */

                                    if (mounted)
                                      setState(() {
                                        _loading = false;
                                      });
                                  },
                      ),
                      SizedBox(
                        width: 16,
                      ),
                    ],
                    if (!dp.isFollowing(userId))
                      SkyButton(
                        tooltip:
                            'Follow someone without anyone knowing. Useful for private contacts',
                        filled: dp.isFollowingPrivately(userId),
                        label: dp.isFollowingPrivately(userId)
                            ? 'Following privately'
                            : 'Private follow',
                        color: SkyColors.private,
                        onPressed: _loading
                            ? null
                            : dp.isFollowingPrivately(userId)
                                ? () async {
                                    setState(() {
                                      _loading = true;
                                    });
                                    await dp.unfollowPrivately(userId);
                                    setState(() {
                                      _loading = false;
                                    });
                                  }
                                : () async {
                                    setState(() {
                                      _loading = true;
                                    });
                                    await dp.followPrivately(userId);
                                    setState(() {
                                      _loading = false;
                                    });
                                  },
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void showUsersDialog({
    BuildContext context,
    List<String> userIds,
    String title,
  }) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height - 200,
                  minHeight: 100,
                  minWidth: 300,
                  maxWidth: 300,
                ),
                child: ListView.builder(
                  itemCount: userIds.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return UserWidget(
                      userId: userIds[index],
                      key: ValueKey(userIds[index]),
                      onPressed: () {
                        Navigator.of(context).pop();
                        rd.setUserId(userIds[index]);
                      },
                    );
                  },
                ),
              ),
              actions: [
                FlatButton(
                  onPressed: Navigator.of(context).pop,
                  child: Text('Close'),
                )
              ],
            ));
  }
}
