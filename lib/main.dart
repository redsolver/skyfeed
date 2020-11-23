import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:app/app.dart';
import 'package:app/auth/auth.dart';
import 'package:app/model/post.dart';
import 'package:app/model/user.dart';
import 'package:app/state.dart';
import 'package:app/utils/theme.dart';
import 'package:app/utils/web.dart';
import 'package:app/widget/chat.dart';
import 'package:app/widget/create_post.dart';
import 'package:app/widget/discover.dart';
import 'package:app/widget/login_hint.dart';
import 'package:app/widget/logo.dart';
import 'package:app/widget/navigation_item.dart';
import 'package:app/widget/notifications.dart';
import 'package:app/widget/post.dart';
import 'package:app/widget/sky_button.dart';
import 'package:app/widget/user_info.dart';
import 'package:badges/badges.dart';
import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:skynet/skynet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
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

  Hive.registerAdapter(UserAdapter());

  Hive.registerAdapter(FeedAdapter());
  Hive.registerAdapter(PostAdapter());
  Hive.registerAdapter(PostContentAdapter());

  dataBox = await Hive.openBox('data');

  users = await Hive.openBox('users');
  followingBox = await Hive.openLazyBox('following');
  followersBox = await Hive.openLazyBox('followers');
  feedPages = await Hive.openLazyBox('feedPages');

  cacheBox = await Hive.openLazyBox('cache');
  commentsIndex = await Hive.openLazyBox('commentsIndex');

  revisionCache =
      await Hive.openBox('revisionCache'); // TODO Can be cleared at any time

  pointerBox = await Hive.openBox('feed-pointer');

  // final user = AppState.loggedInUser;

  minuteStream.addStream(Stream<Null>.periodic(Duration(minutes: 1)));

  print('main() 1 ${DateTime.now()}');

  ws.connect();

  if (dataBox.containsKey('login')) {
    final data = dataBox.get('login');

    print('Auto login with ${data['id']}');

    AppState.skynetUser = SkynetUser.fromSeed(data['seed'].cast<int>());
    AppState.userId = data['id'];

    print('userId ${AppState.userId}');
    print('skyfeedUserId ${AppState.skynetUser.id}');

    print('main() 2 ${DateTime.now()}');

    dp.initAccount();

    print('main() 3 ${DateTime.now()}');

    final cFollowing = await cacheBox.get('following');

    if (cFollowing != null) dp.following = cFollowing.cast<String, Map>();

    final cFollowers = await cacheBox.get('followers');

    if (cFollowers != null) dp.followers = cFollowers.cast<String, Map>();

    final cPrivateFollowing = await cacheBox.get('privateFollowing');

    if (cPrivateFollowing != null)
      dp.privateFollowing = cPrivateFollowing.cast<String, Map>();

    print('main() 4 ${DateTime.now()}');

    dp.checkFollowingUpdater();

    print('main() 5 ${DateTime.now()}');

    final cRequestFollow = await cacheBox.get('requestFollow');
    if (cRequestFollow != null)
      dp.requestFollow = cRequestFollow.cast<String, Map>();

    final cMediaPositions = await cacheBox.get('mediaPositions');

    if (cMediaPositions != null)
      dp.mediaPositions = json.decode(cMediaPositions).cast<String, Map>();

    if (cacheBox.containsKey('saved')) {
      if (dp.saved == null) {
        dp.saved = (await cacheBox.get('saved')).cast<String, Map>();
      }
    }
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

  ItemPosition scrollCache;

  SkyRoutePath.home({this.createPost = false})
      : userId = null,
        postId = null,
        isUnknown = false;

  SkyRoutePath.userPage(this.userId)
      : postId = null,
        createPost = false,
        isUnknown = false;

  SkyRoutePath.postPage(
    this.userId,
    this.postId,
  )   : isUnknown = false,
        createPost = false;

  SkyRoutePath.unknown()
      : userId = null,
        postId = null,
        createPost = false,
        isUnknown = true;

  bool get isHomePage =>
      userId == null && postId == null && createPost == false;

  bool get isUserPage => userId != null && postId == null;

  bool get isPostPage => userId != null && postId != null;
  bool get isCreatePostPage =>
      userId == null && postId == null && createPost == true;

  String toString() => 'SkyRoutePath{scrollCache: $scrollCache}';
}

class SkyRouterDelegate extends RouterDelegate<SkyRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<SkyRoutePath> {
  final GlobalKey<NavigatorState> navigatorKey;

  String selectedUserId;
  String selectedPostId;
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

    final path = selectedUserId == null
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
    createPost = false;

    _addToHistory();

    notifyListeners();
  }

  void setCreatePostPage() {
    selectedUserId = null;
    selectedPostId = null;
    scrollCache = null;
    createPost = true;

    _addToHistory();

    notifyListeners();
  }

  void setUserId(String userId) {
    selectedUserId = userId;
    selectedPostId = null;
    scrollCache = null;

    _addToHistory();

    notifyListeners();
  }

  void setPostId(String userId, String postId) {
    print('setPostId');
    selectedUserId = userId;
    selectedPostId = postId;
    scrollCache = null;

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
      return SkyRoutePath.home(createPost: true);
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
                        final result = await AuthService.login(context);

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
                  offset: Offset(0, 96),
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
                        'Version Beta 0.4.2',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
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
            child: (_mobilePageIndex == 0 || !rd.isMobile)
                ? Row(
                    mainAxisAlignment: width > tabletBreakpoint
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!rd.isMobile) ...[
                        SizedBox(
                          width: 332,
                          child: ListView(
                            padding: const EdgeInsets.only(
                              left: 32,
                              top: 32,
                              bottom: 32,
                            ),
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
                                NavigationItem(
                                  onTap: () {
                                    rd.setUserId(AppState.userId);
                                  },
                                  icon: UniconsLine.user,
                                  label: 'My profile',
                                  color: SkyColors.red,
                                ),
                              ],
                              NotificationsWidget(),
                              if (width <= tabletBreakpoint) ...[
                                SizedBox(
                                  height: 32,
                                ),
                                ChatWidget(),
                                SizedBox(
                                  height: 32,
                                ),
                                DiscoverWidget(),
                              ]
                            ],
                          ),
                        ),
                      ],
                      Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: rd.isMobile
                                  ? 1000
                                  : (useBigFeedPadding ? 748 : 684)),
                          child: FeedPage(
                            rd.isMobile ? null : rd.selectedUserId,
                            rd.isMobile ? null : rd.selectedPostId,
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
                        ),
                      ),
                      if (width > tabletBreakpoint) ...[
                        SizedBox(
                          width: 332,
                          child: ListView(
                            padding: const EdgeInsets.only(
                              top: 32,
                              bottom: 32,
                              right: 32,
                            ),
                            children: [
                              ChatWidget(),
                              SizedBox(
                                height: 32,
                              ),
                              DiscoverWidget(),
                            ],
                          ),
                        ),
                      ],
                    ],
                  )
                : _mobilePageIndex == 1
                    ? SizedBox(
                        width: double.infinity,
                        child: NotificationsWidget(),
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

class FeedPage extends StatefulWidget {
  final String userId;
  final String postId;
  final bool showBackButton;
  final double sidePadding;

  FeedPage(
    this.userId,
    this.postId, {
    this.showBackButton = false,
    this.sidePadding = 0,
    Key key,
  }) : super(key: key);

  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  bool get isMobile => rd.isMobile;

  List<Post> posts;

  // ScrollController _controller;
  //PageStorageBucket bucket;

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
/*     bucket = PageStorageBucket(); */
/*     _controller = ScrollController(
      //initialScrollOffset: 100
      keepScrollOffset: true,
    ); */

    bool _isItemScrollInitialized = false;

    //final localKey = '${widget.userId}/${widget.postId}';

    itemPositionsListener.itemPositions.addListener(() {
      itemPositions = itemPositionsListener.itemPositions.value.toList();
      if (itemScrollController.isAttached) {
        if (_isItemScrollInitialized) {
          rd.setScrollCache(itemPositionsListener.itemPositions.value.first);
        } else {
          _isItemScrollInitialized = true;

          if (!rd.isMobile) {
            final item = rd.scrollCache;

            if (item != null)
              itemScrollController.jumpTo(
                index: item.index,
                alignment: item.itemLeadingEdge,
              );
          }
        }
      }
    });

    _loadFeedData();
    /* _controller.addListener(() {
      print('pos ${_controller.position.keep}');
    }); */

    super.initState();
  }

  List<ItemPosition> itemPositions = [];

  void _handleKeyEvent(RawKeyEvent event) {
    final currentItem = itemPositions.firstWhere(
        (element) => element.itemLeadingEdge >= 0,
        orElse: () => null);

    var index = currentItem?.index ?? 0;
    var alignment = currentItem?.itemLeadingEdge ?? 0;

    print('$index align $alignment');

    int newIndex;

    if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
      //setState(() {
      /*    _controller.animateTo(offset - 200,
          duration: Duration(milliseconds: 30), curve: Curves.ease); */
      //});
      if (index > 2) {
        newIndex = index - 1;
      } else {
        newIndex = 0;
      }
      /*     itemScrollController.scrollTo(
          alignment: 0.02,
          //alignment: alignment - 0.1,
          duration: Duration(milliseconds: 100),
        ); */
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
      if (index == 0) {
        newIndex = 2;
      } else {
        newIndex = index + 1;
      }
    }

    if (newIndex != null) {
      itemScrollController.scrollTo(
        index: newIndex,
        alignment: 0.02,
        //alignment: alignment + 0.1,
        duration: Duration(milliseconds: 100),
      );
    }
  }

  final int localId = dp.getLocalId();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    if (userFeedSub != null) userFeedSub.cancel();
    if (mainFeedSub != null) mainFeedSub.cancel();

    if (userSub != null) {
      userSub.cancel();

      dp.removeProfileStream(widget.userId, localId);
    }
    // _controller.dispose();

    super.dispose();
  }

  StreamSubscription userFeedSub;
  StreamSubscription mainFeedSub;

  StreamSubscription userSub;

  bool isCommentView = false;

  void _loadFeedData() async {
    print('_loadFeedData ${widget.userId}  ${widget.postId}');

    if (widget.userId != null) {
      if (widget.postId != null) {
        dp.log('feed/comments', widget.postId);

        isCommentView = true;

        posts = [
          await dp.getPost('${widget.userId}/feed/${widget.postId}'),
        ];

        setState(() {});
      } else {
        // ! User Feed
        loadCurrentUserFeedData();

        userFeedSub = dp.getFeedStream(userId: widget.userId).listen((_) {
          loadCurrentUserFeedData();
        });

        // print(dp.isFollowingUserPubliclyOrPrivately(widget.userId));

        if (!dp.isFollowingUserPubliclyOrPrivately(widget.userId)) {
          final User initialUser = users.get(widget.userId);

          if (initialUser?.skyfeedId == null) {
            userSub =
                dp.getProfileStream(widget.userId, localId).listen((event) {
              dp.checkFollowingUpdater();
            });
          }

          dp.addTemporaryUserForFeedPage(widget.userId);

          // TODO getProfileStream, then recheck

        }
      }
    } else {
      // ! Home Feed

      loadHomeFeedData();

      mainFeedSub = dp.getFeedStream(userId: '*').listen((_) {
        loadHomeFeedData();
      });

      dp.checkFollowingUpdater();
    }
  }

  void loadHomeFeedData() async {
    print('loadHomeFeedData');

    List<Post> tmpPosts = [];

    Future<void> loadUser(String userId) async {
      final int currentPostsPointer =
          pointerBox.get('${userId}/feed/posts') ?? 0;

      for (int i = currentPostsPointer; i > currentPostsPointer - 2; i--) {
        if (i < 0) continue;

        dp.log('feed/home/loadFeed', '$userId/feed/posts/$i');
        final Feed fp = await feedPages.get('${userId}/feed/posts/$i');

        if (fp != null) {
          fp.items.forEach((p) {
            p.feedId = 'posts/$i';
            p.userId = fp.userId;
          });
          tmpPosts.addAll(fp.items);
        }
      }
    }

    final futures = <Future>[];

    for (final userId in dp.getFollowKeys()) {
      futures.add(loadUser(userId));
    }

    await Future.wait(futures);

    tmpPosts.removeWhere((element) => element.isDeleted == true);
    tmpPosts.sort((a, b) => b.postedAt.compareTo(a.postedAt));

    if (posts?.length == tmpPosts.length) return; // TODO Better checksum :D

    posts = tmpPosts;

    print('loadHomeFeedData setState');

    if (mounted) setState(() {});
  }

  void loadCurrentUserFeedData() async {
    dp.log('feed/user', 'load');

    List<Post> tmpPosts = [];

    final int currentPostsPointer =
        pointerBox.get('${widget.userId}/feed/posts') ?? 0;

    for (int i = currentPostsPointer; i > currentPostsPointer - 2; i--) {
      if (i < 0) continue;

      dp.log('feed/user', 'load ${widget.userId}/feed/posts/$i');

      final Feed fp = await feedPages.get('${widget.userId}/feed/posts/$i');

      if (fp != null) {
        fp.items.forEach((p) {
          p.feedId = 'posts/$i';
          p.userId = widget.userId;
        });

        tmpPosts.addAll(fp.items);

        dp.log('feed/user', 'add ${fp.items.length} items');
      }
    }
    tmpPosts.removeWhere((element) => element.isDeleted == true);
    tmpPosts.sort((a, b) => b.postedAt.compareTo(a.postedAt));

    if (posts?.length == tmpPosts.length) return; // TODO Better checksum :D

    posts = tmpPosts;

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (posts == null)
      return Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Align(
          alignment: Alignment.topCenter,
          child: CircularProgressIndicator(),
        ),
      );

    int itemCount = widget.postId != null ? 1 : posts.length;

    if (isMobile) {
      if (widget.userId != null && widget.postId == null) {
        itemCount++;
      }
    } else {
      if (widget.userId == null) {
        itemCount++;
      }
      if (widget.showBackButton) {
        itemCount++;
      }
    }
    /* itemCount++; */

    print('[build] FeedPage ${widget.userId}');

    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: _handleKeyEvent,
      child: ScrollablePositionedList.separated(
        // key: PageStorageKey('list-${widget.userId}-${widget.postId}'),
        padding: EdgeInsets.only(
          top: (isMobile || widget.showBackButton) ? 0 : 32,
          left: widget.sidePadding,
          right: widget.sidePadding,
        ),
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        // controller: _controller,
        itemCount: itemCount, // TODO +1
        itemBuilder: (context, index) {
          if (widget.showBackButton && !rd.isMobile) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: SizedBox(
                  height: 24,
                  child: InkWell(
                    borderRadius: borderRadius,
                    onTap: () {
                      /*   if (rd.currentConfiguration.isPostPage) {
                        rd.setUserId(rd.selectedUserId);
                      } else { */

                      rd.pop();

                      //}
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          UniconsLine.arrowLeft,
                          color: SkyColors.follow,
                          size: 22,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 1.0),
                          child: Text(
                            'Back',
                            style: TextStyle(
                              color: SkyColors.follow,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            index--;
          }
/*         if (index == 0) {
            return Text(widget.userId.toString());
          }
           */

          if (isMobile) {
            if (widget.userId != null && widget.postId == null) {
              if (index == 0) {
                return ContextPage();
              }
              index--;
            }
          } else {
            if (widget.userId == null) {
              if (index == 0) {
                if (AppState.userId == null) {
                  return LoginHintWidget();
                } else {
                  return CreatePostWidget();
                }
              }
              index--;
            }
          }

          final p = posts[index];

          if (p.repostOf != null) {
            return FutureBuilder<Post>(
              future: dp.getPost(p.repostOf),
              builder: (context, snapshot) {
                if (snapshot.data == null)
                  return Container(
                    decoration: getCardDecoration(context),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Loading post...',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );

                return PostWidget(
                  snapshot.data,
                  key: ValueKey(p),
                  repost: p,
                );
              },
            );
          }

          return PostWidget(
            p,
            showComments: isCommentView,
            key: ValueKey(p),
          );
        },
        separatorBuilder: (context, index) {
          if (isMobile) {
            return Divider(
              height: 1,
              thickness: 1,
            );
          } else {
            if (index == 0 && !rd.currentConfiguration.isHomePage) {
              return SizedBox();
            } else {
              return SizedBox(
                height: 12,
              );
            }
          }
        },
      ),
    );
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
            stream: dp.onRequestFollowChange.stream,
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
          label: // TODO
              'Notifications', // TODO mentions (people you're following), comment on your post
        ),
        BottomNavigationBarItem(
          icon: StreamBuilder(
            stream: dp.onFollowingChange.stream,
            builder: (context, snapshot) {
              return FutureBuilder<Set>(
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
