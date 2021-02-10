import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart';

// 0-0
// 0-1
// 0-2
// 0-3
// 0-4
// 0-5
// 0-6
// 1-0

// datakey: skyfeed-p-0 (posts and reposts)
// datakey: skyfeed-c-0 (comments)

// p: Post/repost
// c: comment

@HiveType(typeId: 11)
@JsonSerializable()
class Feed {
  String $type = 'feed';

  @HiveField(10)
  String userId;

  @JsonKey(ignore: true)
  String id;

  /* String nextPageToken;
  String prevPageToken; */

  @HiveField(11)
  List<Post> items;

  Feed({this.userId, this.id});

  factory Feed.fromJson(Map<String, dynamic> json) => _$FeedFromJson(json);

  Map<String, dynamic> toJson() => _$FeedToJson(this);
}

@HiveType(typeId: 12)
@JsonSerializable(includeIfNull: false)
class Post {
  String $type = 'post';

  Post.deleted({this.id}) {
    isDeleted = true;
  }

  @JsonKey(ignore: true)
  String get fullPostId => '$userId/feed/$feedId/$id';

  @JsonKey(ignore: true)
  String userId;

  @JsonKey(ignore: true)
  String mentionOf;

  @JsonKey(ignore: true)
  String followNotificationFor;

  /* String id; */
  @JsonKey(ignore: true)
  String feedId;

  @HiveField(10)
  int id;

  @HiveField(11)
  String commentTo; // USERID-p-FEEDID-POSTID
  @HiveField(12)
  String repostOf; // USERID-c-FEEDID-POSTID
  @HiveField(13)
  String parentHash; // sha256:a89fjs3a893fj8f93
  // ! Hash everything (can be used for reposts or comments)

  @HiveField(14)
  PostContent content;

  @HiveField(17)
  bool isDeleted;

  @JsonKey(name: 'postedAt')
  @HiveField(15)
  DateTime postedAtOld; // 1264353454

  @JsonKey(ignore: true)
  DateTime get postedAt {
    if (ts != null) {
      return DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return postedAtOld;
  }

  @JsonKey(ignore: true)
  set postedAt(DateTime dt) {
    ts = dt.millisecondsSinceEpoch;

    if (postedAtOld != null) {
      postedAtOld = null;
    }
  }

  @HiveField(16)
  int ts; // 1264353454

  @HiveField(18)
  List<String> mentions;

  Post();

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJson() => _$PostToJson(this);
}

/* class Repost extends Post {
  static const type = 'repost';
} */

@HiveType(typeId: 13)
@JsonSerializable(includeIfNull: false)
class PostContent {
  @HiveField(10)
  String text; // Hello, world!
  @HiveField(11)
  String image; // sia://g894jg98js98djf389jf98jf89jsd89fj3dasld02adl0d2
  @HiveField(12)
  String video; // sia://adw90fka90gk309gk39g3
  @HiveField(13)
  String audio; // sia://asdmniad92mida2dimi

  @HiveField(14)
  double aspectRatio; // image and video aspect ratio *must* be the same
  @HiveField(15)
  String
      blurHash; // First blurhash, then image (can also be thumbnail), then video if one exists

  @HiveField(16)
  int mediaDuration; // in milliseconds

  @HiveField(17)
  String link;

  @HiveField(18)
  String linkTitle;
  // TODO maybe add link.description|icon|image

  @HiveField(19)
  Map<String, String> pollOptions;

  @JsonKey(ignore: true)
  Uint8List bytes;

  PostContent();

  factory PostContent.fromJson(Map<String, dynamic> json) =>
      _$PostContentFromJson(json);

  Map<String, dynamic> toJson() => _$PostContentToJson(this);
}
