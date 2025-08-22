import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'challenge.g.dart';

@HiveType(typeId: 7)
@JsonSerializable()
class Challenge {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final ChallengeType type;

  @HiveField(4)
  final int targetValue;

  @HiveField(5)
  final int currentProgress;

  @HiveField(6)
  final DateTime startDate;

  @HiveField(7)
  final DateTime endDate;

  @HiveField(8)
  final bool isCompleted;

  @HiveField(9)
  final DateTime? completedAt;

  @HiveField(10)
  final String iconName;

  @HiveField(11)
  final String? reward;

  @HiveField(12)
  final ChallengeDifficulty difficulty;

  @HiveField(13)
  final List<String> requiredBreeds;

  @HiveField(14)
  final Map<String, dynamic> metadata;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    this.currentProgress = 0,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
    this.completedAt,
    required this.iconName,
    this.reward,
    required this.difficulty,
    this.requiredBreeds = const [],
    this.metadata = const {},
  });

  factory Challenge.fromJson(Map<String, dynamic> json) => 
      _$ChallengeFromJson(json);
  
  Map<String, dynamic> toJson() => _$ChallengeToJson(this);

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeType? type,
    int? targetValue,
    int? currentProgress,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    DateTime? completedAt,
    String? iconName,
    String? reward,
    ChallengeDifficulty? difficulty,
    List<String>? requiredBreeds,
    Map<String, dynamic>? metadata,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      iconName: iconName ?? this.iconName,
      reward: reward ?? this.reward,
      difficulty: difficulty ?? this.difficulty,
      requiredBreeds: requiredBreeds ?? this.requiredBreeds,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper getters
  double get progressPercentage => 
      targetValue > 0 ? (currentProgress / targetValue).clamp(0.0, 1.0) : 0.0;

  bool get isActive => 
      DateTime.now().isAfter(startDate) && 
      DateTime.now().isBefore(endDate) && 
      !isCompleted;

  bool get isExpired => DateTime.now().isAfter(endDate) && !isCompleted;

  Duration get timeRemaining => endDate.difference(DateTime.now());

  String get timeRemainingText {
    if (isCompleted) return 'Completed';
    if (isExpired) return 'Expired';
    
    final remaining = timeRemaining;
    if (remaining.inDays > 0) {
      return '${remaining.inDays} days left';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours} hours left';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes} minutes left';
    } else {
      return 'Less than a minute left';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Challenge && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Challenge(id: $id, title: $title, progress: $currentProgress/$targetValue)';
  }
}

@HiveType(typeId: 8)
enum ChallengeType {
  @HiveField(0)
  recognition, // Recognize X cats
  
  @HiveField(1)
  breeds, // Identify X different breeds
  
  @HiveField(2)
  daily, // Daily streak
  
  @HiveField(3)
  accuracy, // Achieve X% average accuracy
  
  @HiveField(4)
  exploration, // Find specific rare breeds
  
  @HiveField(5)
  social, // Share X results
  
  @HiveField(6)
  knowledge, // Learn about X breeds
  
  @HiveField(7)
  special; // Special event challenges
}

@HiveType(typeId: 9)
enum ChallengeDifficulty {
  @HiveField(0)
  easy,
  
  @HiveField(1)
  medium,
  
  @HiveField(2)
  hard,
  
  @HiveField(3)
  expert;
}

@HiveType(typeId: 10)
@JsonSerializable()
class Achievement {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String iconName;

  @HiveField(4)
  final AchievementRarity rarity;

  @HiveField(5)
  final DateTime unlockedAt;

  @HiveField(6)
  final Map<String, dynamic> metadata;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.rarity,
    required this.unlockedAt,
    this.metadata = const {},
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => 
      _$AchievementFromJson(json);
  
  Map<String, dynamic> toJson() => _$AchievementToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Achievement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Achievement(id: $id, title: $title, rarity: $rarity)';
  }
}

@HiveType(typeId: 11)
enum AchievementRarity {
  @HiveField(0)
  common,
  
  @HiveField(1)
  uncommon,
  
  @HiveField(2)
  rare,
  
  @HiveField(3)
  epic,
  
  @HiveField(4)
  legendary;
}