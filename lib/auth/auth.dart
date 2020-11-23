export 'unsupported.dart'
    if (dart.library.html) 'web.dart'
    if (dart.library.io) 'io.dart';

import 'dart:typed_data';

class AuthResult {
  String eventCode;
  Uint8List seed;
  String userId;

  AuthResult({
    this.eventCode,
    this.seed,
    this.userId,
  });
}

const appId = 'skyfeed';
