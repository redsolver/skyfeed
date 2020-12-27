// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeedAdapter extends TypeAdapter<Feed> {
  @override
  final int typeId = 11;

  @override
  Feed read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Feed(
      userId: fields[10] as String,
    )..items = (fields[11] as List)?.cast<Post>();
  }

  @override
  void write(BinaryWriter writer, Feed obj) {
    writer
      ..writeByte(2)
      ..writeByte(10)
      ..write(obj.userId)
      ..writeByte(11)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PostAdapter extends TypeAdapter<Post> {
  @override
  final int typeId = 12;

  @override
  Post read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Post()
      ..id = fields[10] as int
      ..commentTo = fields[11] as String
      ..repostOf = fields[12] as String
      ..parentHash = fields[13] as String
      ..content = fields[14] as PostContent
      ..isDeleted = fields[17] as bool
      ..postedAtOld = fields[15] as DateTime
      ..ts = fields[16] as int
      ..mentions = (fields[18] as List)?.cast<String>();
  }

  @override
  void write(BinaryWriter writer, Post obj) {
    writer
      ..writeByte(9)
      ..writeByte(10)
      ..write(obj.id)
      ..writeByte(11)
      ..write(obj.commentTo)
      ..writeByte(12)
      ..write(obj.repostOf)
      ..writeByte(13)
      ..write(obj.parentHash)
      ..writeByte(14)
      ..write(obj.content)
      ..writeByte(17)
      ..write(obj.isDeleted)
      ..writeByte(15)
      ..write(obj.postedAtOld)
      ..writeByte(16)
      ..write(obj.ts)
      ..writeByte(18)
      ..write(obj.mentions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PostContentAdapter extends TypeAdapter<PostContent> {
  @override
  final int typeId = 13;

  @override
  PostContent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PostContent()
      ..text = fields[10] as String
      ..image = fields[11] as String
      ..video = fields[12] as String
      ..audio = fields[13] as String
      ..aspectRatio = fields[14] as double
      ..blurHash = fields[15] as String
      ..mediaDuration = fields[16] as int
      ..link = fields[17] as String
      ..linkTitle = fields[18] as String
      ..pollOptions = (fields[19] as Map)?.cast<String, String>();
  }

  @override
  void write(BinaryWriter writer, PostContent obj) {
    writer
      ..writeByte(10)
      ..writeByte(10)
      ..write(obj.text)
      ..writeByte(11)
      ..write(obj.image)
      ..writeByte(12)
      ..write(obj.video)
      ..writeByte(13)
      ..write(obj.audio)
      ..writeByte(14)
      ..write(obj.aspectRatio)
      ..writeByte(15)
      ..write(obj.blurHash)
      ..writeByte(16)
      ..write(obj.mediaDuration)
      ..writeByte(17)
      ..write(obj.link)
      ..writeByte(18)
      ..write(obj.linkTitle)
      ..writeByte(19)
      ..write(obj.pollOptions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostContentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Feed _$FeedFromJson(Map<String, dynamic> json) {
  return Feed(
    userId: json['userId'] as String,
  )
    ..$type = json[r'$type'] as String
    ..items = (json['items'] as List)
        ?.map(
            (e) => e == null ? null : Post.fromJson(e as Map<String, dynamic>))
        ?.toList();
}

Map<String, dynamic> _$FeedToJson(Feed instance) => <String, dynamic>{
      r'$type': instance.$type,
      'userId': instance.userId,
      'items': instance.items,
    };

Post _$PostFromJson(Map<String, dynamic> json) {
  return Post()
    ..$type = json[r'$type'] as String
    ..id = json['id'] as int
    ..commentTo = json['commentTo'] as String
    ..repostOf = json['repostOf'] as String
    ..parentHash = json['parentHash'] as String
    ..content = json['content'] == null
        ? null
        : PostContent.fromJson(json['content'] as Map<String, dynamic>)
    ..isDeleted = json['isDeleted'] as bool
    ..postedAtOld = json['postedAt'] == null
        ? null
        : DateTime.parse(json['postedAt'] as String)
    ..ts = json['ts'] as int
    ..mentions = (json['mentions'] as List)?.map((e) => e as String)?.toList();
}

Map<String, dynamic> _$PostToJson(Post instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(r'$type', instance.$type);
  writeNotNull('id', instance.id);
  writeNotNull('commentTo', instance.commentTo);
  writeNotNull('repostOf', instance.repostOf);
  writeNotNull('parentHash', instance.parentHash);
  writeNotNull('content', instance.content);
  writeNotNull('isDeleted', instance.isDeleted);
  writeNotNull('postedAt', instance.postedAtOld?.toIso8601String());
  writeNotNull('ts', instance.ts);
  writeNotNull('mentions', instance.mentions);
  return val;
}

PostContent _$PostContentFromJson(Map<String, dynamic> json) {
  return PostContent()
    ..text = json['text'] as String
    ..image = json['image'] as String
    ..video = json['video'] as String
    ..audio = json['audio'] as String
    ..aspectRatio = (json['aspectRatio'] as num)?.toDouble()
    ..blurHash = json['blurHash'] as String
    ..mediaDuration = json['mediaDuration'] as int
    ..link = json['link'] as String
    ..linkTitle = json['linkTitle'] as String
    ..pollOptions = (json['pollOptions'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as String),
    );
}

Map<String, dynamic> _$PostContentToJson(PostContent instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('text', instance.text);
  writeNotNull('image', instance.image);
  writeNotNull('video', instance.video);
  writeNotNull('audio', instance.audio);
  writeNotNull('aspectRatio', instance.aspectRatio);
  writeNotNull('blurHash', instance.blurHash);
  writeNotNull('mediaDuration', instance.mediaDuration);
  writeNotNull('link', instance.link);
  writeNotNull('linkTitle', instance.linkTitle);
  writeNotNull('pollOptions', instance.pollOptions);
  return val;
}
