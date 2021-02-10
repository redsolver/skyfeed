import 'dart:typed_data';

import 'package:app/model/post.dart';
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:image/image.dart' as img;
import 'package:image/src/exif_data.dart' as exif;
import 'package:tuple/tuple.dart';

Future<PostContent> calculateImageStuff(Tuple2<Uint8List, String> tuple) async {
  final data = tuple.item1;
  final contentType = tuple.item2;

  //print('inBytes: ${data.length}');

  img.Image image = img.decodeImage(data);

  image.exif = exif.ExifData();

  // TODO 'image/gif'

  final bytes =
      contentType == 'image/png' ? img.encodePng(image) : img.encodeJpg(image);

  return PostContent()
    ..aspectRatio = image.width / image.height
    ..blurHash = encodeBlurHash(
      image.getBytes(format: img.Format.rgba),
      image.width,
      image.height,
    )
    ..bytes = bytes;
}
// lofty likewise napkin semifinal puddle dotted ahead attire smidgen exult altitude shocking jubilee juggled uttered fountain friendly radar gawk dangerous code examine metro threaten nuns abyss inroads navy abyss
