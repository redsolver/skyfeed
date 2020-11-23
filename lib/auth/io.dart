import 'dart:convert';
import 'dart:typed_data';

import 'package:app/app.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:skynet/skynet.dart';

import 'auth.dart';

class AuthService {
  AuthService._();

  static Future<AuthResult> login(BuildContext context) async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Login with Sky ID'),
              content: Text(
                  '1. Open ${resolveSkylink('sia://sky-id.hns/connect.html')} on your computer\n2. Register or login\n3. Click on QR-Code login in the left side bar\n4. Enter "skyfeed" in the text field'),
              actions: [
                FlatButton(
                  child: Text('Ok'),
                  onPressed: Navigator.of(context).pop,
                ),
              ],
            ));
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
      '#19B417',
      'Cancel',
      false,
      ScanMode.QR,
    );

    if (barcodeScanRes == null) {
      return AuthResult(eventCode: 'cancel');
    }

    final data = json.decode(barcodeScanRes);

    // print(data);

    if (data['sender'] == 'skyid') {
      final String eventCode = data['eventCode'];

      print(eventCode);

      if (eventCode == 'login_success') {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: ListTile(
              leading: SpinKitCubeGrid(
                color: SkyColors.follow,
                size: 28,
              ),
              title: Text('Logging in...'),
            ),
          ),
          barrierDismissible: false,
        );
        try {
          final appData = data['appData'];

          final seedStrInBase64 = appData['seed'];

          final seed = SkynetUser.skyIdSeedToEd25519Seed(seedStrInBase64);

          final res =
              await getFile(SkynetUser.fromId(appData['userId']), 'profile');

          final profile = json.decode(json.decode(res.asString));

          String publicKey;

          try {
            publicKey = profile['dapps']['skyfeed']['publicKey'];
          } catch (e) {}

          if (publicKey != SkynetUser.fromSeed(seed).id) {
            Navigator.of(context).pop();
            await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      title: Text('Login Error'),
                      content: Text(
                          'Invalid appId or you need to login on web first'),
                      actions: [
                        FlatButton(
                          child: Text('Ok'),
                          onPressed: Navigator.of(context).pop,
                        ),
                      ],
                    ));
            return AuthResult(
              eventCode: 'invalid_appid',
            );
          }

          Navigator.of(context).pop();
          return AuthResult(
            eventCode: eventCode,
            seed: seed,
            userId: appData['userId'],
          );
        } catch (e, st) {
          print(e);
          Navigator.of(context).pop();
        }
      } else {
        return AuthResult(
          eventCode: eventCode,
        );
      }
    }
    return AuthResult(
      eventCode: 'error',
    );
  }

  static void logout() {
    throw 'AUTH not on io yet';
  }

  static String getPortal() {
    return 'siasky.net';
  }
}
