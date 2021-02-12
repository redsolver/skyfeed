import 'dart:async';

import 'package:app/app.dart';
import 'package:app/auth/auth.dart';
import 'package:app/feed_page.dart';
import 'package:app/state.dart';
import 'package:app/utils/theme.dart';
// import 'package:app/widget/auth_dialog.dart';
import 'package:app/widget/chat.dart';
import 'package:app/widget/create_post.dart';
import 'package:app/widget/discover.dart';
import 'package:app/widget/logo.dart';
import 'package:app/widget/navigation_item.dart';
import 'package:app/widget/sky_button.dart';
import 'package:app/widget/user_info.dart';
import 'package:badges/badges.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:skynet/skynet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  // TODO GestureBinding.instance.resamplingEnabled = true;

  print('main() { ${DateTime.now()}');

  await Hive.initFlutter('skyfeed');

  //print(hex.encode(hashDatakey('profile-page')));

  if (kIsWeb) {
    final portal = AuthService.getPortal();
    print('Portal $portal');

    SkynetConfig.host = portal;
  }

  // print(await getApplicationDocumentsDirectory());

  await dp.init();

  // final user = AppState.loggedInUser;

  minuteStream.addStream(Stream<Null>.periodic(Duration(minutes: 1)));

  print('main() 1 ${DateTime.now()}');

  ws.connect();

  if (dataBox.containsKey('login')) {
    final data = dataBox.get('login');

    print('Auto login with ${data['id']}');

    AppState.skynetUser = SkynetUser.fromSeed(data['seed'].cast<int>());
    AppState.userId = data['id'];

    await dp.loadEverything();
  }

  print('main() } ${DateTime.now()}');

  runApp(SkyFeedApp());
}

// final _loginStreamCtrl = StreamController<String>.broadcast();

// final router = FluroRouter();

class SkyFeedApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _SkyFeedAppState createState() => _SkyFeedAppState();
}

class SkyRoutePath {
  final String userId;

  final String postId;
  final bool isUnknown;

  final bool createPost;
  final bool notificationsPage;

  ItemPosition scrollCache;

  SkyRoutePath.home({this.createPost = false, this.notificationsPage = false})
      : userId = null,
        postId = null,
        isUnknown = false;

  SkyRoutePath.userPage(this.userId)
      : postId = null,
        createPost = false,
        notificationsPage = false,
        isUnknown = false;

  SkyRoutePath.postPage(
    this.userId,
    this.postId,
  )   : isUnknown = false,
        notificationsPage = false,
        createPost = false;

  SkyRoutePath.unknown()
      : userId = null,
        postId = null,
        createPost = false,
        notificationsPage = false,
        isUnknown = true;

  bool get isHomePage =>
      userId == null &&
      postId == null &&
      createPost == false &&
      notificationsPage == false;

  bool get isUserPage => userId != null && postId == null;

  bool get isPostPage => userId != null && postId != null;
  bool get isCreatePostPage =>
      userId == null && postId == null && createPost == true;

  bool get isNotificationsPage =>
      userId == null && postId == null && notificationsPage == true;

  String toString() => 'SkyRoutePath{scrollCache: $scrollCache}';
}

class SkyRouterDelegate extends RouterDelegate<SkyRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<SkyRoutePath> {
  final GlobalKey<NavigatorState> navigatorKey;

  String selectedUserId;
  String selectedPostId;

  bool isNotificationsPage = false;

  bool show404 = false;

  ItemPosition scrollCache;

  void setScrollCache(ItemPosition position) {
    scrollCache = position;

    history.last.scrollCache = position;
  }

  SkyRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>();
  SkyRoutePath get currentConfiguration {
    if (show404) {
      return SkyRoutePath.unknown();
    }

    final path = isNotificationsPage
        ? SkyRoutePath.home(notificationsPage: true)
        : selectedUserId == null
            ? SkyRoutePath.home(createPost: createPost ?? false)
            : selectedPostId == null
                ? SkyRoutePath.userPage(selectedUserId)
                : SkyRoutePath.postPage(selectedUserId, selectedPostId);

    path.scrollCache = scrollCache;

    return path;
  }

  bool isMobile = false;

  List<SkyRoutePath> history = [
    SkyRoutePath.home(),
  ];

  @override
  void notifyListeners() {
    print('history $history');
    super.notifyListeners();
  }

  final themeNotifier = ValueNotifier<ThemeModel>(ThemeModel(
    (dataBox.get('theme') ?? 'system') == 'system'
        ? ThemeMode.system
        : (dataBox.get('theme') == 'light')
            ? ThemeMode.light
            : ThemeMode.dark,
  ));

  updateTheme() {
    themeNotifier.value = ThemeModel(
      (dataBox.get('theme') ?? 'system') == 'system'
          ? ThemeMode.system
          : (dataBox.get('theme') == 'light')
              ? ThemeMode.light
              : ThemeMode.dark,
    );
  }

  bool isDarkTheme = false;

  @override
  Widget build(BuildContext context) {
    isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    isMobile = width < mobileBreakpoint;

    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(
          key: ValueKey('home'),
          child: HomePage(),
        ),
        if (isMobile) ..._buildMobilePages(),
      ],
      onPopPage: (route, result) {
        print('onPopPage');

        if (!route.didPop(result)) {
          return false;
        }

        pop(); // TODO Better navigation check

        return true;
      },
    );
  }

  List<MaterialPage> _buildMobilePages() {
    // TODO Add Create post page? only pop no universal?
    List<MaterialPage> pages = [];

    for (final path in history) {
      if (path.isHomePage) continue;
      if (path.isCreatePostPage) {
        pages.add(
          MaterialPage(
            key: ValueKey('create-post'),
            child: MobileCreatePostPage(),
          ),
        );
      }

      if (path.isUserPage) {
        pages.add(
          MaterialPage(
            key: ValueKey(path.userId),
            child: MobileUserPage(
              path.userId,
            ),
          ),
        );
      }

      if (path.isPostPage) {
        pages.add(
          MaterialPage(
            key: ValueKey(path.userId + path.postId),
            child: MobileUserPostPage(
              userId: path.userId,
              postId: path.postId,
            ),
          ),
        );
      }
    }

    return pages;
  }

  void pop() {
    if (history.length > 1) {
      history.removeLast();
      setNewRoutePath(history.last);

      print(
          '[pop] ${routeInformationParser.restoreRouteInformation(history.last).location}');
    } else {}

    notifyListeners();
  }

  @override
  Future<void> setNewRoutePath(SkyRoutePath path) async {
    if (path.isUnknown) {
      selectedUserId = null;
      isNotificationsPage = false;
      show404 = true;
      return;
    }

    //print('setNewRoutePath history $history');

    while (history.length > 1) {
      if (routeInformationParser
              .restoreRouteInformation(history.last)
              .location ==
          routeInformationParser.restoreRouteInformation(path).location) {
        break;
      }
      history.removeLast();
    }

    //  print('setNewRoutePath history $history');
    scrollCache = history.last.scrollCache;

    createPost = false;
    isNotificationsPage = false;

    // print('setNewRoutePath scrollCache $scrollCache');

    if (path.isUserPage) {
      selectedUserId = path.userId;
      selectedPostId = null;
    } else if (path.isPostPage) {
      selectedUserId = path.userId;
      selectedPostId = path.postId;
    } else {
      selectedUserId = null;
      selectedPostId = null;

      if (path.isCreatePostPage) {
        createPost = true;
      } else if (path.isNotificationsPage) {
        isNotificationsPage = true;
      }
    }

    show404 = false;
  }

  bool createPost;

  void _addToHistory() {
    if (history.isNotEmpty) {
      if (routeInformationParser
              .restoreRouteInformation(history.last)
              .location ==
          routeInformationParser
              .restoreRouteInformation(currentConfiguration)
              .location) return;
    }
    history.add(currentConfiguration);
  }

  void setHomePage() {
    selectedUserId = null;
    selectedPostId = null;
    scrollCache = null;
    isNotificationsPage = false;
    createPost = false;

    _addToHistory();

    notifyListeners();
  }

  void setNotificationsPage() {
    selectedUserId = null;
    selectedPostId = null;
    scrollCache = null;
    createPost = false;
    isNotificationsPage = true;

    _addToHistory();

    notifyListeners();
  }

  void setCreatePostPage() {
    selectedUserId = null;
    selectedPostId = null;
    scrollCache = null;
    createPost = true;
    isNotificationsPage = false;

    _addToHistory();

    notifyListeners();
  }

  void setUserId(String userId) {
    selectedUserId = userId;
    selectedPostId = null;
    scrollCache = null;
    createPost = false;
    isNotificationsPage = false;

    _addToHistory();

    notifyListeners();
  }

  void setPostId(String userId, String postId) {
    print('setPostId');
    selectedUserId = userId;
    selectedPostId = postId;
    scrollCache = null;
    createPost = false;
    isNotificationsPage = false;

    _addToHistory();

    notifyListeners();
  }

  void rebuild() {
    notifyListeners();
  }
}

class MobileCreatePostPage extends StatelessWidget {
  MobileCreatePostPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(UniconsLine.arrowLeft),
            onPressed: () {
              rd.pop();
            },
          ),
          title: Text('Create post'),
          backgroundColor: Theme.of(context).cardColor,
          elevation: 0,
        ),
        body: CreatePostWidget(
          autofocus: true,
        ));
  }
}

class MobileUserPage extends StatelessWidget {
  final String userId;

  MobileUserPage(this.userId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(UniconsLine.arrowLeft),
          onPressed: () {
            rd.pop();

            /* rd.popRoute(); */
          },
        ),
        title: Text('User'),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          appBarDivider,
          Expanded(
            child: FeedPage(
              userId,
              null,
              key: ValueKey(userId),
            ),
          )
        ],
      ),
    );
  }
}

class MobileUserPostPage extends StatelessWidget {
  final String userId;
  final String postId;

  MobileUserPostPage({this.userId, this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(UniconsLine.arrowLeft),
          onPressed: () {
            rd.pop();
          },
        ),
        title: Text('Post'),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          appBarDivider,
          Expanded(
            child: FeedPage(
              userId,
              postId,
              key: ValueKey('$userId/$postId'),
            ),
          ),
        ],
      ),
    );
  }
}

class SkyRouteInformationParser extends RouteInformationParser<SkyRoutePath> {
  @override
  Future<SkyRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location);
    // Handle '/'
    if (uri.pathSegments.length == 0) {
      return SkyRoutePath.home();
    }

    if (uri.pathSegments.length == 1) {
      if (uri.pathSegments.first == 'create') {
        return SkyRoutePath.home(createPost: true);
      } else {
        return SkyRoutePath.home(notificationsPage: true);
      }
    }

    if (uri.pathSegments.length >= 2) {
      if (uri.pathSegments[0] != 'user') return SkyRoutePath.unknown();
      var userId = uri.pathSegments[1];
      if (userId.length != 64) return SkyRoutePath.unknown();
/*       var id = int.tryParse(remaining);
      if (id == null) return BookRoutePath.unknown(); */

      if (uri.pathSegments.length == 2) {
        return SkyRoutePath.userPage(userId);
      } else {
        var postId = uri.pathSegments.sublist(2).join('/');

        print('[nav] $postId');

        return SkyRoutePath.postPage(userId, postId);
      }
    }

    // Handle unknown routes
    return SkyRoutePath.unknown();
  }

  @override
  RouteInformation restoreRouteInformation(SkyRoutePath path) {
    if (path.isUnknown) {
      return RouteInformation(location: '/404');
    }
    if (path.isHomePage) {
      return RouteInformation(location: '/');
    }
    if (path.isCreatePostPage) {
      return RouteInformation(location: '/create');
    }
    if (path.isNotificationsPage) {
      return RouteInformation(location: '/notifications');
    }
    if (path.isUserPage) {
      return RouteInformation(location: '/user/${path.userId}');
    }
    if (path.isPostPage) {
      return RouteInformation(location: '/user/${path.userId}/${path.postId}');
    }
    return null;
  }
}

class _SkyFeedAppState extends State<SkyFeedApp> {
  @override
  void initState() {
    super.initState();
    rd = SkyRouterDelegate();
    routeInformationParser = SkyRouteInformationParser();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeModel>(
      valueListenable: rd.themeNotifier,
      builder: (_, model, __) {
        return MaterialApp.router(
          title: 'SkyFeed',
          themeMode: model.mode,
          theme: buildThemeData(
            context,
            'light',
          ),
          darkTheme: buildThemeData(context, 'dark'),
          routerDelegate: rd,
          routeInformationParser: routeInformationParser,
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    ws.onConnectionStateChange = () {
      print('Home setState (ConnectionState)');
      setState(() {});
    };

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // tabletBreakpoint

    print('HomePage: FeedPage(${rd.isMobile} ? null : ${rd.selectedUserId}');

    final width = MediaQuery.of(context).size.width;

    final useBigFeedPadding = width > 1500;

    return Scaffold(
      body: Column(
        children: [
          AppBar(
            backgroundColor: Theme.of(context).cardColor,
            elevation: 0,
            title: rd.isMobile
                ? LogoWidget()
                : Row(
                    key: ValueKey(rd.selectedUserId),
                    children: [
                      InkWell(
                        borderRadius: borderRadius,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: LogoWidget(),
                        ),
                        onTap: () {
                          rd.setHomePage();
                        },
                      ),
                      if (rd.isNotificationsPage == true) ...[
                        Text('/'),
                        InkWell(
                          borderRadius: borderRadius,
                          /*   onTap: () {
                            rd.setUserId(rd.selectedUserId);
                          }, */
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Notifications'),
                          ),
                        ),
                      ],
                      if (rd.selectedUserId != null) ...[
                        Text('/'),
                        InkWell(
                          borderRadius: borderRadius,
                          onTap: () {
                            rd.setUserId(rd.selectedUserId);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: UserBuilder(
                                userId: rd.selectedUserId,
                                callback: (user) {
                                  if (user == null) return Text('');

                                  return buildUsernameWidget(user, context);
                                }),
                          ),
                        ),
                      ],
                      if (rd.selectedPostId != null) ...[
                        Text('/'),
                        InkWell(
                          borderRadius: borderRadius,
                          /*   onTap: () {
                            rd.setUserId(rd.selectedUserId);
                          }, */
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Post'),
                          ),
                        ),
                      ],
                    ],
                  ),
            actions: [
              /* 
              StreamBuilder<Object>(
                  stream: _loginStreamCtrl.stream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return SizedBox();

                    return Text(snapshot.data);
                  }), */
              if (AppState.userId == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SkyButton(
                      label: 'Login',
                      color: SkyColors.follow,
                      onPressed: () async {
                        /* final AuthResult result = await showDialog(
                            context: context,
                            builder: (context) => AuthDialog()); */

                        final result = await AuthService.login(context);

                        if (result == null) return;

                        if (result.eventCode == 'login_success') {
                          AppState.skynetUser =
                              SkynetUser.fromSeed(result.seed);
                          AppState.userId = result.userId;

                          dp.initAccount();

                          dataBox.put('login', {
                            'seed': result.seed,
                            'id': result.userId,
                          });

                          setState(() {});
                        } else if (result.eventCode == 'login_fail') {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Login failed'),
                              actions: [
                                FlatButton(
                                  child: Text('Ok'),
                                  onPressed: Navigator.of(context).pop,
                                )
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              if (AppState.userId != null)
                PopupMenuButton<String>(
                  elevation: 4,
                  onSelected: (s) async {
                    if (s == 'edit_profile') {
                      final s = resolveSkylink(
                          'sia://sky-id.hns/dashboard.html#profile');

                      launch(s);
                    } else if (s == 'toggle_dark_mode') {
                      //final theme = dataBox.get('theme') ?? 'light';

                      await dataBox.put(
                        'theme',
                        Theme.of(context).brightness == Brightness.light
                            ? 'dark'
                            : 'light',
                      );

                      rd.updateTheme();
                    } else if (s == 'use_system_theme') {
                      await dataBox.put(
                        'theme',
                        'system',
                      );

                      rd.updateTheme();
                    } else if (s == 'logout') {
                      await dp.logout();
                      AuthService.logout();
                    }
                  },
                  //offset: Offset(0, 96),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text('Edit profile'),
                      value: 'edit_profile',
                    ),
                    PopupMenuItem(
                      child: Text('Toggle dark mode'),
                      value: 'toggle_dark_mode',
                    ),
                    if ((dataBox.get('theme') ?? 'system') != 'system')
                      PopupMenuItem(
                        child: Text('Use system theme'),
                        value: 'use_system_theme',
                      ),
                    PopupMenuItem(
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          color: SkyColors.red,
                        ),
                      ),
                      value: 'logout',
                    ),
                    PopupMenuItem(
                        child: Text(
                      'Version Beta 0.6.0',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    )),
                  ],
                  child: Row(
                    children: [
                      SizedBox(
                        width: 8,
                      ),
                      ClipRRect(
                        borderRadius: borderRadius,
                        child: UserBuilder(
                          userId: AppState.userId,
                          callback: (user) {
                            if (user == null)
                              return SizedBox(
                                height: 40,
                                width: 40,
                              );

                            return Image.network(
                              resolveSkylink(
                                user.picture,
                              ),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: 2,
                      ),
                      Icon(UniconsLine.angleDown),
                    ],
                  ),
                ),
            ],
          ),
          if (ws.connectionState.type != ConnectionStateType.connected)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('${ws.connectionState.type}: Trying to reconnect...'),
            ),
          appBarDivider,
          /*       if (!isMobile)
          SizedBox(
            height: 32,
          ), */
          Expanded(
            child: (_mobilePageIndex == 0 ||
                    _mobilePageIndex == 1 ||
                    !rd.isMobile)
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      (rd.isNotificationsPage || _mobilePageIndex == 1)
                          ? FeedPage(
                              null,
                              null,
                              maxWidth: rd.isMobile
                                  ? 1000
                                  : (useBigFeedPadding ? 748 : 684),
                              isNotificationsPage: true,
                              sidePadding: rd.isMobile
                                  ? 0
                                  : useBigFeedPadding
                                      ? 64
                                      : 32,
                              center: width > tabletBreakpoint,
                              key: ValueKey(
                                'page-notifications',
                              ),
                              showBackButton: true,
                            )
                          : FeedPage(
                              rd.isMobile ? null : rd.selectedUserId,
                              rd.isMobile ? null : rd.selectedPostId,
                              maxWidth: rd.isMobile
                                  ? 1000
                                  : (useBigFeedPadding ? 748 : 684),
                              center: width > tabletBreakpoint,
                              sidePadding: rd.isMobile
                                  ? 0
                                  : useBigFeedPadding
                                      ? 64
                                      : 32,
                              key: ValueKey(
                                rd.isMobile
                                    ? null
                                    : rd.currentConfiguration.isHomePage
                                        ? null
                                        : rd.currentConfiguration.isUserPage
                                            ? rd.selectedUserId
                                            : rd.selectedUserId +
                                                rd.selectedPostId,
                              ),
                              showBackButton: rd.currentConfiguration.isHomePage
                                  ? false
                                  : true,
                            ),
                      if (!rd.isMobile)
                        Row(
                          mainAxisAlignment: width > tabletBreakpoint
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!rd.isMobile) ...[
                              SizedBox(
                                width: 332,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 32,
                                    top: 32,
                                    bottom: 32,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (rd.selectedUserId != null) ...[
                                        ContextPage(),
                                        SizedBox(
                                          height: 32,
                                        ),
                                      ],
                                      if (AppState.isLoggedIn) ...[
                                        NavigationItem(
                                          onTap: () {
                                            rd.setHomePage();
                                          },
                                          icon: UniconsLine.estate,
                                          label: 'Overview',
                                          color: SkyColors.follow,
                                        ),
                                        SizedBox(
                                          height: 16,
                                        ),
                                        StreamBuilder(
                                          stream:
                                              dp.onNotificationsChange.stream,
                                          builder: (context, snapshot) {
                                            final notificationsCount =
                                                dp.getNotificationsCount();

                                            return NavigationItem(
                                              onTap: () {
                                                rd.setNotificationsPage();
                                              },
                                              icon: UniconsLine.bell,
                                              label: 'Notifications',
                                              color: SkyColors.red,
                                              notificationCount:
                                                  notificationsCount,
                                            );
                                          },
                                        ),
                                        SizedBox(
                                          height: 16,
                                        ),
                                        NavigationItem(
                                          onTap: () {
                                            rd.setUserId(AppState.userId);
                                          },
                                          icon: UniconsLine.user,
                                          label: 'My profile',
                                          color: SkyColors.red,
                                        ),
                                        SizedBox(
                                          height: 32,
                                        ),
                                      ],
                                      // NotificationsWidget(),
                                      if (width <= tabletBreakpoint) ...[
                                        /* SizedBox(
                                        height: 32,
                                      ), */
                                        ChatWidget(),
                                        SizedBox(
                                          height: 32,
                                        ),
                                        DiscoverWidget(),
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            Flexible(
                              child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxWidth: rd.isMobile
                                          ? 1000
                                          : (useBigFeedPadding ? 748 : 684)),
                                  child: SizedBox(
                                    width: double.infinity,
                                  )),
                            ),
                            if (width > tabletBreakpoint) ...[
                              SizedBox(
                                width: 332,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 32,
                                    bottom: 32,
                                    right: 32,
                                  ),
                                  child: Column(
                                    children: [
                                      ChatWidget(),
                                      SizedBox(
                                        height: 32,
                                      ),
                                      DiscoverWidget(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  )
                : _mobilePageIndex == 2
                    ? SizedBox(
                        width: double.infinity,
                        child: DiscoverWidget(),
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ChatWidget(),
                      ),
          ),
        ],
      ),
      floatingActionButton: (rd.isMobile && AppState.isLoggedIn)
          ? FloatingActionButton(
              onPressed: () {
                rd.setCreatePostPage();
              },
              child: Icon(UniconsLine.commentAltPlus),
            )
          : null,
      //floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: (rd.isMobile)
          ? NavigationBar(
              mobilePageIndex: _mobilePageIndex,
              setMobilePageIndex: _setMobilePageIndex,
            )
          : null,
    );
  }

  int _mobilePageIndex = 0;

  _setMobilePageIndex(int index) {
    setState(() {
      _mobilePageIndex = index;
    });
  }
}

class ContextPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return UserInfoWidget(
      rd.selectedUserId,
      key: ValueKey(rd.selectedUserId),
    );
  }
}

class NavigationBar extends StatelessWidget {
  final int mobilePageIndex;
  final Function setMobilePageIndex;

  NavigationBar({this.mobilePageIndex, this.setMobilePageIndex});
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: mobilePageIndex,
      onTap: setMobilePageIndex,
      // mouseCursor: MouseCursor.defer,
      selectedItemColor: SkyColors.follow,
      showUnselectedLabels: false,

      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: Icon(UniconsLine.home),
          label: 'Your feed',
        ),
        BottomNavigationBarItem(
          icon: StreamBuilder(
            stream: dp.onNotificationsChange.stream,
            builder: (context, snapshot) {
              final notificationsCount = dp.getNotificationsCount();
              return Badge(
                showBadge: notificationsCount > 0,
                badgeContent: Text(
                  notificationsCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                toAnimate: false,
                badgeColor: SkyColors.red,
                child: Icon(
                  UniconsLine.bell,
                ),
              );
            },
          ),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(
          icon: StreamBuilder(
            stream: dp.onFollowingChange.stream,
            builder: (context, snapshot) {
              return FutureBuilder<List>(
                future: dp.getSuggestedUsers(),
                builder: (context, snapshot) {
                  final suggestionsCount =
                      snapshot.hasData ? snapshot.data.length : 0;
                  return Badge(
                    showBadge: suggestionsCount > 0,
                    badgeContent: Text(
                      suggestionsCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    toAnimate: false,
                    badgeColor: SkyColors.follow,
                    child: Icon(
                      UniconsLine.compass,
                    ),
                  );
                },
              );
            },
          ),
          label: 'Discover',
        ),
        BottomNavigationBarItem(
          icon: Icon(UniconsLine.usersAlt),
          label: 'Following',
        ),
      ],
    );
  }
}
