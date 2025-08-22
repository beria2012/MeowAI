import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@HiveType(typeId: 3)
@JsonSerializable()
class User {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String? displayName;

  @HiveField(3)
  final String? photoUrl;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime lastLoginAt;

  @HiveField(6)
  final UserPreferences preferences;

  @HiveField(7)
  final UserStats stats;

  @HiveField(8)
  final bool isAnonymous;

  @HiveField(9)
  final String? locale;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    required this.preferences,
    required this.stats,
    this.isAnonymous = false,
    this.locale,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserToJson(this);

  factory User.anonymous() {
    final now = DateTime.now();
    return User(
      id: 'anonymous_${now.millisecondsSinceEpoch}',
      email: '',
      createdAt: now,
      lastLoginAt: now,
      preferences: UserPreferences.defaultPreferences(),
      stats: const UserStats(),
      isAnonymous: true,
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserPreferences? preferences,
    UserStats? stats,
    bool? isAnonymous,
    String? locale,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      locale: locale ?? this.locale,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName)';
  }
}

@HiveType(typeId: 4)
@JsonSerializable()
class UserPreferences {
  @HiveField(0)
  final bool isDarkMode;

  @HiveField(1)
  final String language;

  @HiveField(2)
  final bool enableNotifications;

  @HiveField(3)
  final bool enableChallenges;

  @HiveField(4)
  final bool autoSaveToGooglePhotos;

  @HiveField(5)
  final bool enableHapticFeedback;

  @HiveField(6)
  final bool enableSoundEffects;

  @HiveField(7)
  final double cameraFlashIntensity;

  @HiveField(8)
  final bool showConfidenceScores;

  @HiveField(9)
  final bool showAlternativePredictions;

  @HiveField(10)
  final bool enableAR;

  @HiveField(11)
  final NotificationFrequency challengeFrequency;

  @HiveField(12)
  final NotificationFrequency factFrequency;

  const UserPreferences({
    this.isDarkMode = false,
    this.language = 'en',
    this.enableNotifications = true,
    this.enableChallenges = true,
    this.autoSaveToGooglePhotos = false,
    this.enableHapticFeedback = true,
    this.enableSoundEffects = true,
    this.cameraFlashIntensity = 0.5,
    this.showConfidenceScores = true,
    this.showAlternativePredictions = true,
    this.enableAR = true,
    this.challengeFrequency = NotificationFrequency.weekly,
    this.factFrequency = NotificationFrequency.daily,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) => 
      _$UserPreferencesFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);

  factory UserPreferences.defaultPreferences() {
    return const UserPreferences();
  }

  UserPreferences copyWith({
    bool? isDarkMode,
    String? language,
    bool? enableNotifications,
    bool? enableChallenges,
    bool? autoSaveToGooglePhotos,
    bool? enableHapticFeedback,
    bool? enableSoundEffects,
    double? cameraFlashIntensity,
    bool? showConfidenceScores,
    bool? showAlternativePredictions,
    bool? enableAR,
    NotificationFrequency? challengeFrequency,
    NotificationFrequency? factFrequency,
  }) {
    return UserPreferences(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableChallenges: enableChallenges ?? this.enableChallenges,
      autoSaveToGooglePhotos: autoSaveToGooglePhotos ?? this.autoSaveToGooglePhotos,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      enableSoundEffects: enableSoundEffects ?? this.enableSoundEffects,
      cameraFlashIntensity: cameraFlashIntensity ?? this.cameraFlashIntensity,
      showConfidenceScores: showConfidenceScores ?? this.showConfidenceScores,
      showAlternativePredictions: showAlternativePredictions ?? this.showAlternativePredictions,
      enableAR: enableAR ?? this.enableAR,
      challengeFrequency: challengeFrequency ?? this.challengeFrequency,
      factFrequency: factFrequency ?? this.factFrequency,
    );
  }
}

@HiveType(typeId: 5)
@JsonSerializable()
class UserStats {
  @HiveField(0)
  final int totalRecognitions;

  @HiveField(1)
  final int uniqueBreedsIdentified;

  @HiveField(2)
  final int favoritesSaved;

  @HiveField(3)
  final int challengesCompleted;

  @HiveField(4)
  final int streakDays;

  @HiveField(5)
  final DateTime? lastRecognitionDate;

  @HiveField(6)
  final Map<String, int> breedCounts;

  @HiveField(7)
  final List<String> achievements;

  @HiveField(8)
  final double averageConfidence;

  const UserStats({
    this.totalRecognitions = 0,
    this.uniqueBreedsIdentified = 0,
    this.favoritesSaved = 0,
    this.challengesCompleted = 0,
    this.streakDays = 0,
    this.lastRecognitionDate,
    this.breedCounts = const {},
    this.achievements = const [],
    this.averageConfidence = 0.0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) => 
      _$UserStatsFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserStatsToJson(this);

  UserStats copyWith({
    int? totalRecognitions,
    int? uniqueBreedsIdentified,
    int? favoritesSaved,
    int? challengesCompleted,
    int? streakDays,
    DateTime? lastRecognitionDate,
    Map<String, int>? breedCounts,
    List<String>? achievements,
    double? averageConfidence,
  }) {
    return UserStats(
      totalRecognitions: totalRecognitions ?? this.totalRecognitions,
      uniqueBreedsIdentified: uniqueBreedsIdentified ?? this.uniqueBreedsIdentified,
      favoritesSaved: favoritesSaved ?? this.favoritesSaved,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      streakDays: streakDays ?? this.streakDays,
      lastRecognitionDate: lastRecognitionDate ?? this.lastRecognitionDate,
      breedCounts: breedCounts ?? this.breedCounts,
      achievements: achievements ?? this.achievements,
      averageConfidence: averageConfidence ?? this.averageConfidence,
    );
  }

  // Helper methods
  String get mostIdentifiedBreed {
    if (breedCounts.isEmpty) return 'None';
    final maxEntry = breedCounts.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return maxEntry.key;
  }

  bool get hasStreakToday {
    if (lastRecognitionDate == null) return false;
    final today = DateTime.now();
    final lastDate = lastRecognitionDate!;
    return today.year == lastDate.year &&
           today.month == lastDate.month &&
           today.day == lastDate.day;
  }
}

@HiveType(typeId: 6)
enum NotificationFrequency {
  @HiveField(0)
  never,
  
  @HiveField(1)
  daily,
  
  @HiveField(2)
  weekly,
  
  @HiveField(3)
  monthly;
}