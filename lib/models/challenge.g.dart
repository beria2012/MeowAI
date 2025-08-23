// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChallengeAdapter extends TypeAdapter<Challenge> {
  @override
  final int typeId = 7;

  @override
  Challenge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Challenge(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      type: fields[3] as ChallengeType,
      targetValue: fields[4] as int,
      currentProgress: fields[5] as int,
      startDate: fields[6] as DateTime,
      endDate: fields[7] as DateTime,
      isCompleted: fields[8] as bool,
      completedAt: fields[9] as DateTime?,
      iconName: fields[10] as String,
      reward: fields[11] as String?,
      difficulty: fields[12] as ChallengeDifficulty,
      requiredBreeds: (fields[13] as List).cast<String>(),
      metadata: (fields[14] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, Challenge obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.targetValue)
      ..writeByte(5)
      ..write(obj.currentProgress)
      ..writeByte(6)
      ..write(obj.startDate)
      ..writeByte(7)
      ..write(obj.endDate)
      ..writeByte(8)
      ..write(obj.isCompleted)
      ..writeByte(9)
      ..write(obj.completedAt)
      ..writeByte(10)
      ..write(obj.iconName)
      ..writeByte(11)
      ..write(obj.reward)
      ..writeByte(12)
      ..write(obj.difficulty)
      ..writeByte(13)
      ..write(obj.requiredBreeds)
      ..writeByte(14)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AchievementAdapter extends TypeAdapter<Achievement> {
  @override
  final int typeId = 10;

  @override
  Achievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Achievement(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      iconName: fields[3] as String,
      rarity: fields[4] as AchievementRarity,
      unlockedAt: fields[5] as DateTime,
      metadata: (fields[6] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, Achievement obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.iconName)
      ..writeByte(4)
      ..write(obj.rarity)
      ..writeByte(5)
      ..write(obj.unlockedAt)
      ..writeByte(6)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChallengeTypeAdapter extends TypeAdapter<ChallengeType> {
  @override
  final int typeId = 8;

  @override
  ChallengeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ChallengeType.recognition;
      case 1:
        return ChallengeType.breeds;
      case 2:
        return ChallengeType.daily;
      case 3:
        return ChallengeType.accuracy;
      case 4:
        return ChallengeType.exploration;
      case 5:
        return ChallengeType.social;
      case 6:
        return ChallengeType.knowledge;
      case 7:
        return ChallengeType.special;
      default:
        return ChallengeType.recognition;
    }
  }

  @override
  void write(BinaryWriter writer, ChallengeType obj) {
    switch (obj) {
      case ChallengeType.recognition:
        writer.writeByte(0);
        break;
      case ChallengeType.breeds:
        writer.writeByte(1);
        break;
      case ChallengeType.daily:
        writer.writeByte(2);
        break;
      case ChallengeType.accuracy:
        writer.writeByte(3);
        break;
      case ChallengeType.exploration:
        writer.writeByte(4);
        break;
      case ChallengeType.social:
        writer.writeByte(5);
        break;
      case ChallengeType.knowledge:
        writer.writeByte(6);
        break;
      case ChallengeType.special:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChallengeDifficultyAdapter extends TypeAdapter<ChallengeDifficulty> {
  @override
  final int typeId = 9;

  @override
  ChallengeDifficulty read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ChallengeDifficulty.easy;
      case 1:
        return ChallengeDifficulty.medium;
      case 2:
        return ChallengeDifficulty.hard;
      case 3:
        return ChallengeDifficulty.expert;
      default:
        return ChallengeDifficulty.easy;
    }
  }

  @override
  void write(BinaryWriter writer, ChallengeDifficulty obj) {
    switch (obj) {
      case ChallengeDifficulty.easy:
        writer.writeByte(0);
        break;
      case ChallengeDifficulty.medium:
        writer.writeByte(1);
        break;
      case ChallengeDifficulty.hard:
        writer.writeByte(2);
        break;
      case ChallengeDifficulty.expert:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeDifficultyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AchievementRarityAdapter extends TypeAdapter<AchievementRarity> {
  @override
  final int typeId = 11;

  @override
  AchievementRarity read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AchievementRarity.common;
      case 1:
        return AchievementRarity.uncommon;
      case 2:
        return AchievementRarity.rare;
      case 3:
        return AchievementRarity.epic;
      case 4:
        return AchievementRarity.legendary;
      default:
        return AchievementRarity.common;
    }
  }

  @override
  void write(BinaryWriter writer, AchievementRarity obj) {
    switch (obj) {
      case AchievementRarity.common:
        writer.writeByte(0);
        break;
      case AchievementRarity.uncommon:
        writer.writeByte(1);
        break;
      case AchievementRarity.rare:
        writer.writeByte(2);
        break;
      case AchievementRarity.epic:
        writer.writeByte(3);
        break;
      case AchievementRarity.legendary:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementRarityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Challenge _$ChallengeFromJson(Map<String, dynamic> json) => Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$ChallengeTypeEnumMap, json['type']),
      targetValue: (json['targetValue'] as num).toInt(),
      currentProgress: (json['currentProgress'] as num?)?.toInt() ?? 0,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      iconName: json['iconName'] as String,
      reward: json['reward'] as String?,
      difficulty: $enumDecode(_$ChallengeDifficultyEnumMap, json['difficulty']),
      requiredBreeds: (json['requiredBreeds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$ChallengeToJson(Challenge instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'type': _$ChallengeTypeEnumMap[instance.type]!,
      'targetValue': instance.targetValue,
      'currentProgress': instance.currentProgress,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'isCompleted': instance.isCompleted,
      'completedAt': instance.completedAt?.toIso8601String(),
      'iconName': instance.iconName,
      'reward': instance.reward,
      'difficulty': _$ChallengeDifficultyEnumMap[instance.difficulty]!,
      'requiredBreeds': instance.requiredBreeds,
      'metadata': instance.metadata,
    };

const _$ChallengeTypeEnumMap = {
  ChallengeType.recognition: 'recognition',
  ChallengeType.breeds: 'breeds',
  ChallengeType.daily: 'daily',
  ChallengeType.accuracy: 'accuracy',
  ChallengeType.exploration: 'exploration',
  ChallengeType.social: 'social',
  ChallengeType.knowledge: 'knowledge',
  ChallengeType.special: 'special',
};

const _$ChallengeDifficultyEnumMap = {
  ChallengeDifficulty.easy: 'easy',
  ChallengeDifficulty.medium: 'medium',
  ChallengeDifficulty.hard: 'hard',
  ChallengeDifficulty.expert: 'expert',
};

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconName: json['iconName'] as String,
      rarity: $enumDecode(_$AchievementRarityEnumMap, json['rarity']),
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'iconName': instance.iconName,
      'rarity': _$AchievementRarityEnumMap[instance.rarity]!,
      'unlockedAt': instance.unlockedAt.toIso8601String(),
      'metadata': instance.metadata,
    };

const _$AchievementRarityEnumMap = {
  AchievementRarity.common: 'common',
  AchievementRarity.uncommon: 'uncommon',
  AchievementRarity.rare: 'rare',
  AchievementRarity.epic: 'epic',
  AchievementRarity.legendary: 'legendary',
};
