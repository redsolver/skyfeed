import 'package:app/data.dart';
import 'package:app/model/user.dart';
import 'package:hive/hive.dart';
import 'package:skynet/skynet.dart';

LazyBox cacheBox;
Box revisionCache;

Box<User> users;

LazyBox followingBox;
LazyBox followersBox;

LazyBox feedPages;

LazyBox commentsIndex;

LazyBox reactionsBox;

Box pointerBox;

Box dataBox;

final ws = SkyDBoverWS();

final dp = DataProcesser();
