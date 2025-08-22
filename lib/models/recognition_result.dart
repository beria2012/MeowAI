import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import 'cat_breed.dart';

part 'recognition_result.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class RecognitionResult {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imagePath;

  @HiveField(2)
  final CatBreed predictedBreed;

  @HiveField(3)
  final double confidence;

  @HiveField(4)
  final List<PredictionScore> alternativePredictions;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final bool isFavorite;

  @HiveField(7)
  final String? userNote;

  @HiveField(8)
  final Duration processingTime;

  @HiveField(9)
  final String modelVersion;

  @HiveField(10)
  final Map<String, dynamic> metadata;

  const RecognitionResult({
    required this.id,
    required this.imagePath,
    required this.predictedBreed,
    required this.confidence,
    required this.alternativePredictions,
    required this.timestamp,
    this.isFavorite = false,
    this.userNote,
    required this.processingTime,
    required this.modelVersion,
    this.metadata = const {},
  });

  factory RecognitionResult.fromJson(Map<String, dynamic> json) => 
      _$RecognitionResultFromJson(json);
  
  Map<String, dynamic> toJson() => _$RecognitionResultToJson(this);

  RecognitionResult copyWith({
    String? id,
    String? imagePath,
    CatBreed? predictedBreed,
    double? confidence,
    List<PredictionScore>? alternativePredictions,
    DateTime? timestamp,
    bool? isFavorite,
    String? userNote,
    Duration? processingTime,
    String? modelVersion,
    Map<String, dynamic>? metadata,
  }) {
    return RecognitionResult(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      predictedBreed: predictedBreed ?? this.predictedBreed,
      confidence: confidence ?? this.confidence,
      alternativePredictions: alternativePredictions ?? this.alternativePredictions,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
      userNote: userNote ?? this.userNote,
      processingTime: processingTime ?? this.processingTime,
      modelVersion: modelVersion ?? this.modelVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper getters
  String get confidencePercentage => '${(confidence * 100).toInt()}%';
  
  bool get isHighConfidence => confidence >= 0.8;
  
  bool get isMediumConfidence => confidence >= 0.5 && confidence < 0.8;
  
  bool get isLowConfidence => confidence < 0.5;

  String get confidenceLevel {
    if (isHighConfidence) return 'High';
    if (isMediumConfidence) return 'Medium';
    return 'Low';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecognitionResult && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RecognitionResult(id: $id, breed: ${predictedBreed.name}, confidence: ${confidencePercentage})';
  }
}

@HiveType(typeId: 2)
@JsonSerializable()
class PredictionScore {
  @HiveField(0)
  final CatBreed breed;

  @HiveField(1)
  final double confidence;

  @HiveField(2)
  final int rank;

  const PredictionScore({
    required this.breed,
    required this.confidence,
    required this.rank,
  });

  factory PredictionScore.fromJson(Map<String, dynamic> json) => 
      _$PredictionScoreFromJson(json);
  
  Map<String, dynamic> toJson() => _$PredictionScoreToJson(this);

  String get confidencePercentage => '${(confidence * 100).toInt()}%';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PredictionScore && 
           other.breed.id == breed.id && 
           other.rank == rank;
  }

  @override
  int get hashCode => breed.id.hashCode ^ rank.hashCode;

  @override
  String toString() {
    return 'PredictionScore(breed: ${breed.name}, confidence: ${confidencePercentage}, rank: $rank)';
  }
}