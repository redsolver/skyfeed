import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@HiveType(typeId: 10)
@JsonSerializable()
class User {
  @JsonKey(ignore: true)
  String id;

  @HiveField(10)
  String skyfeedId;

  @HiveField(1)
  String username;

  @HiveField(2)
  String picture; // sia://g34g43tg

  @HiveField(3)
  String bio;

  @HiveField(4)
  String location;

  User({this.id, this.username, this.bio, this.picture, this.location});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
