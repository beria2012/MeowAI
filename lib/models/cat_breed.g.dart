// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cat_breed.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CatBreedAdapter extends TypeAdapter<CatBreed> {
  @override
  final int typeId = 0;

  @override
  CatBreed read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CatBreed(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      origin: fields[3] as String,
      temperament: fields[4] as String,
      lifeSpan: fields[5] as String,
      weight: fields[6] as String,
      imageUrl: fields[7] as String,
      colors: (fields[8] as List).cast<String>(),
      characteristics: (fields[9] as List).cast<String>(),
      history: fields[10] as String,
      energyLevel: fields[11] as int,
      sheddingLevel: fields[12] as int,
      socialNeeds: fields[13] as int,
      groomingNeeds: fields[14] as int,
      isHypoallergenic: fields[15] as bool,
      isRare: fields[16] as bool,
      mlIndex: fields[17] as int?,
      availableForRecognition: fields[18] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, CatBreed obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.origin)
      ..writeByte(4)
      ..write(obj.temperament)
      ..writeByte(5)
      ..write(obj.lifeSpan)
      ..writeByte(6)
      ..write(obj.weight)
      ..writeByte(7)
      ..write(obj.imageUrl)
      ..writeByte(8)
      ..write(obj.colors)
      ..writeByte(9)
      ..write(obj.characteristics)
      ..writeByte(10)
      ..write(obj.history)
      ..writeByte(11)
      ..write(obj.energyLevel)
      ..writeByte(12)
      ..write(obj.sheddingLevel)
      ..writeByte(13)
      ..write(obj.socialNeeds)
      ..writeByte(14)
      ..write(obj.groomingNeeds)
      ..writeByte(15)
      ..write(obj.isHypoallergenic)
      ..writeByte(16)
      ..write(obj.isRare)
      ..writeByte(17)
      ..write(obj.mlIndex)
      ..writeByte(18)
      ..write(obj.availableForRecognition);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatBreedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatBreed _$CatBreedFromJson(Map<String, dynamic> json) => CatBreed(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      origin: json['origin'] as String,
      temperament: json['temperament'] as String,
      lifeSpan: json['life_span'] as String,
      weight: json['weight'] as String,
      imageUrl: json['image_url'] as String,
      colors:
          (json['colors'] as List<dynamic>).map((e) => e as String).toList(),
      characteristics: (json['characteristics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      history: json['history'] as String? ?? '',
      energyLevel: (json['energy_level'] as num).toInt(),
      sheddingLevel: (json['sheddingLevel'] as num?)?.toInt() ?? 2,
      socialNeeds: (json['social_needs'] as num).toInt(),
      groomingNeeds: (json['grooming_needs'] as num).toInt(),
      isHypoallergenic: json['is_hypoallergenic'] as bool,
      isRare: json['is_rare'] as bool,
      mlIndex: (json['ml_index'] as num?)?.toInt(),
      availableForRecognition: json['available_for_recognition'] as bool?,
    );

Map<String, dynamic> _$CatBreedToJson(CatBreed instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'origin': instance.origin,
      'temperament': instance.temperament,
      'life_span': instance.lifeSpan,
      'weight': instance.weight,
      'image_url': instance.imageUrl,
      'colors': instance.colors,
      'characteristics': instance.characteristics,
      'history': instance.history,
      'energy_level': instance.energyLevel,
      'sheddingLevel': instance.sheddingLevel,
      'social_needs': instance.socialNeeds,
      'grooming_needs': instance.groomingNeeds,
      'is_hypoallergenic': instance.isHypoallergenic,
      'is_rare': instance.isRare,
      'ml_index': instance.mlIndex,
      'available_for_recognition': instance.availableForRecognition,
    };
