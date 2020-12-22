import 'package:app/data.dart';
import 'package:hive/hive.dart';
import 'package:skynet/skynet.dart';

LazyBox cacheBox;
Box revisionCache;

Box users;

LazyBox followingBox;
LazyBox followersBox;

LazyBox feedPages;

LazyBox commentsIndex;

LazyBox reactionsBox;

Box pointerBox;

Box dataBox;

final ws = SkyDBoverWS();

final dp = DataProcesser();
