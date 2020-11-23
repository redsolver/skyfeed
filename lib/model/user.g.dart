// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 10;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      username: fields[1] as String,
      bio: fields[3] as String,
      picture: fields[2] as String,
      location: fields[4] as String,
    )..skyfeedId = fields[10] as String;
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(5)
      ..writeByte(10)
      ..write(obj.skyfeedId)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.picture)
      ..writeByte(3)
      ..write(obj.bio)
      ..writeByte(4)
      ..write(obj.location);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  return User(
    username: json['username'] as String,
    bio: json['bio'] as String,
    picture: json['picture'] as String,
    location: json['location'] as String,
  )..skyfeedId = json['skyfeedId'] as String;
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'skyfeedId': instance.skyfeedId,
      'username': instance.username,
      'picture': instance.picture,
      'bio': instance.bio,
      'location': instance.location,
    };
