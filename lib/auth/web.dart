import 'dart:html';

import 'package:app/app.dart';
import 'package:skynet/skynet.dart';

import 'auth.dart';

class AuthService {
  AuthService._();

  static AuthResult _result;

  static void logout() {
    window.location.reload();
  }

  static String getPortal() {
    String portal = window.location.hostname;

    if (portal == 'localhost') portal = 'siasky.net';

    if (portal.contains('.hns.')) {
      portal = portal.split('.hns.')[1];
    }

    if (portal.split('.').length == 3) {
      portal = portal.substring(portal.split('.').first.length + 1);
    }
    return portal;
  }

  static Future<AuthResult> login(BuildContext context) async {
    _result = null;

    window.onMessage.listen((event) {
      try {
        //print(event.data.runtimeType);
        print(event.data);

        if (event.data['sender'] == 'skyid') {
          final String eventCode = event.data['eventCode'];

          print(eventCode);

          if (eventCode == 'login_success') {
            final appData = event.data['appData'];

            final seedStrInBase64 = appData['seed'];

            final seed = SkynetUser.skyIdSeedToEd25519Seed(seedStrInBase64);

            _result = AuthResult(
              eventCode: eventCode,
              seed: seed,
              userId: appData['userId'],
            );

            print('''  _result = AuthResult(
              eventCode: $eventCode,
              seed: $seed,
              userId: ${appData['userId']},
            );''');
          } else {
            _result = AuthResult(
              eventCode: eventCode,
            );
          }
        }
      } catch (e, st) {
        print(e);
        print(st);
      }
    });

    final skyIdEndpoint = resolveSkylink('sia://sky-id.hns/connect.html');

    print(skyIdEndpoint);

    final windowObjectReference =
        popupCenter('$skyIdEndpoint?appId=' + appId, 'SkyID', 400, 500);

    while (_result == null) {
      await Future.delayed(Duration(milliseconds: 20));
    }
    return _result;
  }
}

WindowBase popupCenter(url, title, w, h) {
  // Fixes dual-screen position                             Most browsers      Firefox
  final dualScreenLeft =
      window.screenLeft != null ? window.screenLeft : window.screenX;
  final dualScreenTop =
      window.screenTop != null ? window.screenTop : window.screenY;

  final width = window.innerWidth ??
      document.documentElement.clientWidth ??
      window.screen.width;

  final height = window.innerHeight ??
      document.documentElement.clientHeight ??
      window.screen.height;

  final systemZoom = width / window.screen.available.width;

  final left = (width - w) / 2 / systemZoom + dualScreenLeft;
  final top = (height - h) / 2 / systemZoom + dualScreenTop;
  final newWindow = window.open(url, title, '''
		scrollbars=yes,
		width=${w / systemZoom}, 
		height=${h / systemZoom}, 
		top=$top, 
		left=$left
		''');

  return newWindow;
}
