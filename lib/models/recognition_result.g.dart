// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recognition_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecognitionResultAdapter extends TypeAdapter<RecognitionResult> {
  @override
  final int typeId = 1;

  @override
  RecognitionResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecognitionResult(
      id: fields[0] as String,
      imagePath: fields[1] as String,
      predictedBreed: fields[2] as CatBreed,
      confidence: fields[3] as double,
      alternativePredictions: (fields[4] as List).cast<PredictionScore>(),
      timestamp: fields[5] as DateTime,
      isFavorite: fields[6] as bool,
      userNote: fields[7] as String?,
      processingTime: fields[8] as Duration,
      modelVersion: fields[9] as String,
      metadata: (fields[10] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, RecognitionResult obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.predictedBreed)
      ..writeByte(3)
      ..write(obj.confidence)
      ..writeByte(4)
      ..write(obj.alternativePredictions)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.isFavorite)
      ..writeByte(7)
      ..write(obj.userNote)
      ..writeByte(8)
      ..write(obj.processingTime)
      ..writeByte(9)
      ..write(obj.modelVersion)
      ..writeByte(10)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecognitionResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PredictionScoreAdapter extends TypeAdapter<PredictionScore> {
  @override
  final int typeId = 2;

  @override
  PredictionScore read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PredictionScore(
      breed: fields[0] as CatBreed,
      confidence: fields[1] as double,
      rank: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PredictionScore obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.breed)
      ..writeByte(1)
      ..write(obj.confidence)
      ..writeByte(2)
      ..write(obj.rank);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PredictionScoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecognitionResult _$RecognitionResultFromJson(Map<String, dynamic> json) =>
    RecognitionResult(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      predictedBreed:
          CatBreed.fromJson(json['predictedBreed'] as Map<String, dynamic>),
      confidence: (json['confidence'] as num).toDouble(),
      alternativePredictions: (json['alternativePredictions'] as List<dynamic>)
          .map((e) => PredictionScore.fromJson(e as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      userNote: json['userNote'] as String?,
      processingTime:
          Duration(microseconds: (json['processingTime'] as num).toInt()),
      modelVersion: json['modelVersion'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$RecognitionResultToJson(RecognitionResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'imagePath': instance.imagePath,
      'predictedBreed': instance.predictedBreed,
      'confidence': instance.confidence,
      'alternativePredictions': instance.alternativePredictions,
      'timestamp': instance.timestamp.toIso8601String(),
      'isFavorite': instance.isFavorite,
      'userNote': instance.userNote,
      'processingTime': instance.processingTime.inMicroseconds,
      'modelVersion': instance.modelVersion,
      'metadata': instance.metadata,
    };

PredictionScore _$PredictionScoreFromJson(Map<String, dynamic> json) =>
    PredictionScore(
      breed: CatBreed.fromJson(json['breed'] as Map<String, dynamic>),
      confidence: (json['confidence'] as num).toDouble(),
      rank: (json['rank'] as num).toInt(),
    );

Map<String, dynamic> _$PredictionScoreToJson(PredictionScore instance) =>
    <String, dynamic>{
      'breed': instance.breed,
      'confidence': instance.confidence,
      'rank': instance.rank,
    };
