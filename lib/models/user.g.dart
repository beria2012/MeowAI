// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 3;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as String,
      email: fields[1] as String,
      displayName: fields[2] as String?,
      photoUrl: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      lastLoginAt: fields[5] as DateTime,
      preferences: fields[6] as UserPreferences,
      stats: fields[7] as UserStats,
      isAnonymous: fields[8] as bool,
      locale: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.photoUrl)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.lastLoginAt)
      ..writeByte(6)
      ..write(obj.preferences)
      ..writeByte(7)
      ..write(obj.stats)
      ..writeByte(8)
      ..write(obj.isAnonymous)
      ..writeByte(9)
      ..write(obj.locale);
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

class UserPreferencesAdapter extends TypeAdapter<UserPreferences> {
  @override
  final int typeId = 4;

  @override
  UserPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreferences(
      isDarkMode: fields[0] as bool,
      language: fields[1] as String,
      enableNotifications: fields[2] as bool,
      enableChallenges: fields[3] as bool,
      autoSaveToGooglePhotos: fields[4] as bool,
      enableHapticFeedback: fields[5] as bool,
      enableSoundEffects: fields[6] as bool,
      cameraFlashIntensity: fields[7] as double,
      showConfidenceScores: fields[8] as bool,
      showAlternativePredictions: fields[9] as bool,
      enableAR: fields[10] as bool,
      challengeFrequency: fields[11] as NotificationFrequency,
      factFrequency: fields[12] as NotificationFrequency,
    );
  }

  @override
  void write(BinaryWriter writer, UserPreferences obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.isDarkMode)
      ..writeByte(1)
      ..write(obj.language)
      ..writeByte(2)
      ..write(obj.enableNotifications)
      ..writeByte(3)
      ..write(obj.enableChallenges)
      ..writeByte(4)
      ..write(obj.autoSaveToGooglePhotos)
      ..writeByte(5)
      ..write(obj.enableHapticFeedback)
      ..writeByte(6)
      ..write(obj.enableSoundEffects)
      ..writeByte(7)
      ..write(obj.cameraFlashIntensity)
      ..writeByte(8)
      ..write(obj.showConfidenceScores)
      ..writeByte(9)
      ..write(obj.showAlternativePredictions)
      ..writeByte(10)
      ..write(obj.enableAR)
      ..writeByte(11)
      ..write(obj.challengeFrequency)
      ..writeByte(12)
      ..write(obj.factFrequency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserStatsAdapter extends TypeAdapter<UserStats> {
  @override
  final int typeId = 5;

  @override
  UserStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserStats(
      totalRecognitions: fields[0] as int,
      uniqueBreedsIdentified: fields[1] as int,
      favoritesSaved: fields[2] as int,
      challengesCompleted: fields[3] as int,
      streakDays: fields[4] as int,
      lastRecognitionDate: fields[5] as DateTime?,
      breedCounts: (fields[6] as Map).cast<String, int>(),
      achievements: (fields[7] as List).cast<String>(),
      averageConfidence: fields[8] as double,
    );
  }

  @override
  void write(BinaryWriter writer, UserStats obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.totalRecognitions)
      ..writeByte(1)
      ..write(obj.uniqueBreedsIdentified)
      ..writeByte(2)
      ..write(obj.favoritesSaved)
      ..writeByte(3)
      ..write(obj.challengesCompleted)
      ..writeByte(4)
      ..write(obj.streakDays)
      ..writeByte(5)
      ..write(obj.lastRecognitionDate)
      ..writeByte(6)
      ..write(obj.breedCounts)
      ..writeByte(7)
      ..write(obj.achievements)
      ..writeByte(8)
      ..write(obj.averageConfidence);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationFrequencyAdapter extends TypeAdapter<NotificationFrequency> {
  @override
  final int typeId = 6;

  @override
  NotificationFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NotificationFrequency.never;
      case 1:
        return NotificationFrequency.daily;
      case 2:
        return NotificationFrequency.weekly;
      case 3:
        return NotificationFrequency.monthly;
      default:
        return NotificationFrequency.never;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationFrequency obj) {
    switch (obj) {
      case NotificationFrequency.never:
        writer.writeByte(0);
        break;
      case NotificationFrequency.daily:
        writer.writeByte(1);
        break;
      case NotificationFrequency.weekly:
        writer.writeByte(2);
        break;
      case NotificationFrequency.monthly:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      preferences:
          UserPreferences.fromJson(json['preferences'] as Map<String, dynamic>),
      stats: UserStats.fromJson(json['stats'] as Map<String, dynamic>),
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      locale: json['locale'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'displayName': instance.displayName,
      'photoUrl': instance.photoUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastLoginAt': instance.lastLoginAt.toIso8601String(),
      'preferences': instance.preferences,
      'stats': instance.stats,
      'isAnonymous': instance.isAnonymous,
      'locale': instance.locale,
    };

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) =>
    UserPreferences(
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      enableChallenges: json['enableChallenges'] as bool? ?? true,
      autoSaveToGooglePhotos: json['autoSaveToGooglePhotos'] as bool? ?? false,
      enableHapticFeedback: json['enableHapticFeedback'] as bool? ?? true,
      enableSoundEffects: json['enableSoundEffects'] as bool? ?? true,
      cameraFlashIntensity:
          (json['cameraFlashIntensity'] as num?)?.toDouble() ?? 0.5,
      showConfidenceScores: json['showConfidenceScores'] as bool? ?? true,
      showAlternativePredictions:
          json['showAlternativePredictions'] as bool? ?? true,
      enableAR: json['enableAR'] as bool? ?? true,
      challengeFrequency: $enumDecodeNullable(
              _$NotificationFrequencyEnumMap, json['challengeFrequency']) ??
          NotificationFrequency.weekly,
      factFrequency: $enumDecodeNullable(
              _$NotificationFrequencyEnumMap, json['factFrequency']) ??
          NotificationFrequency.daily,
    );

Map<String, dynamic> _$UserPreferencesToJson(UserPreferences instance) =>
    <String, dynamic>{
      'isDarkMode': instance.isDarkMode,
      'language': instance.language,
      'enableNotifications': instance.enableNotifications,
      'enableChallenges': instance.enableChallenges,
      'autoSaveToGooglePhotos': instance.autoSaveToGooglePhotos,
      'enableHapticFeedback': instance.enableHapticFeedback,
      'enableSoundEffects': instance.enableSoundEffects,
      'cameraFlashIntensity': instance.cameraFlashIntensity,
      'showConfidenceScores': instance.showConfidenceScores,
      'showAlternativePredictions': instance.showAlternativePredictions,
      'enableAR': instance.enableAR,
      'challengeFrequency':
          _$NotificationFrequencyEnumMap[instance.challengeFrequency]!,
      'factFrequency': _$NotificationFrequencyEnumMap[instance.factFrequency]!,
    };

const _$NotificationFrequencyEnumMap = {
  NotificationFrequency.never: 'never',
  NotificationFrequency.daily: 'daily',
  NotificationFrequency.weekly: 'weekly',
  NotificationFrequency.monthly: 'monthly',
};

UserStats _$UserStatsFromJson(Map<String, dynamic> json) => UserStats(
      totalRecognitions: (json['totalRecognitions'] as num?)?.toInt() ?? 0,
      uniqueBreedsIdentified:
          (json['uniqueBreedsIdentified'] as num?)?.toInt() ?? 0,
      favoritesSaved: (json['favoritesSaved'] as num?)?.toInt() ?? 0,
      challengesCompleted: (json['challengesCompleted'] as num?)?.toInt() ?? 0,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      lastRecognitionDate: json['lastRecognitionDate'] == null
          ? null
          : DateTime.parse(json['lastRecognitionDate'] as String),
      breedCounts: (json['breedCounts'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      averageConfidence: (json['averageConfidence'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$UserStatsToJson(UserStats instance) => <String, dynamic>{
      'totalRecognitions': instance.totalRecognitions,
      'uniqueBreedsIdentified': instance.uniqueBreedsIdentified,
      'favoritesSaved': instance.favoritesSaved,
      'challengesCompleted': instance.challengesCompleted,
      'streakDays': instance.streakDays,
      'lastRecognitionDate': instance.lastRecognitionDate?.toIso8601String(),
      'breedCounts': instance.breedCounts,
      'achievements': instance.achievements,
      'averageConfidence': instance.averageConfidence,
    };
