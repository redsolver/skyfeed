import 'package:skynet/skynet.dart';

class AppState {
  static SkynetUser skynetUser;

  static String userId;

  static final publicUser =
      SkynetUser.fromSeed(List.generate(32, (index) => 0));

  static bool get isLoggedIn => userId != null;
}
