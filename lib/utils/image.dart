import 'dart:typed_data';

import 'package:app/model/post.dart';
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:image/image.dart' as img;

Future<PostContent> calculateImageStuff(Uint8List data) async {
  print('inBytes: ${data.length}');

  img.Image image = img.decodeImage(data);

  print(image.runtimeType);

  return PostContent()
    ..aspectRatio = image.width / image.height
    ..blurHash = encodeBlurHash(
      image.getBytes(format: img.Format.rgba),
      image.width,
      image.height,
    );
}
