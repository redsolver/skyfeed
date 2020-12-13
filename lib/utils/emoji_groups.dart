import 'package:emojis/emoji.dart';

const emojiGroups = [
  FullEmojiGroup(
    'Smileys',
    EmojiGroup.smileysEmotion,
  ),
  FullEmojiGroup(
    'Nature & Animals',
    EmojiGroup.animalsNature,
  ),
  FullEmojiGroup(
    'Food & Drink',
    EmojiGroup.foodDrink,
  ),
  FullEmojiGroup(
    'Activities',
    EmojiGroup.activities,
  ),
  FullEmojiGroup(
    'Travel & Places',
    EmojiGroup.travelPlaces,
  ),
  FullEmojiGroup(
    'Objects',
    EmojiGroup.objects,
  ),
  FullEmojiGroup(
    'Symbols',
    EmojiGroup.symbols,
  ),
  FullEmojiGroup(
    'Flags',
    EmojiGroup.flags,
  ),
];

class FullEmojiGroup {
  final String name;
  final EmojiGroup group;
  const FullEmojiGroup(this.name, this.group);
}
