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
      characteristics: (fields[8] as List).cast<String>(),
      history: fields[9] as String,
      energyLevel: fields[10] as int,
      sheddingLevel: fields[11] as int,
      socialNeeds: fields[12] as int,
      groomingNeeds: fields[13] as int,
      isHypoallergenic: fields[14] as bool,
      isRare: fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CatBreed obj) {
    writer
      ..writeByte(16)
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
      ..write(obj.characteristics)
      ..writeByte(9)
      ..write(obj.history)
      ..writeByte(10)
      ..write(obj.energyLevel)
      ..writeByte(11)
      ..write(obj.sheddingLevel)
      ..writeByte(12)
      ..write(obj.socialNeeds)
      ..writeByte(13)
      ..write(obj.groomingNeeds)
      ..writeByte(14)
      ..write(obj.isHypoallergenic)
      ..writeByte(15)
      ..write(obj.isRare);
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
      lifeSpan: json['lifeSpan'] as String,
      weight: json['weight'] as String,
      imageUrl: json['imageUrl'] as String,
      characteristics: (json['characteristics'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      history: json['history'] as String,
      energyLevel: (json['energyLevel'] as num).toInt(),
      sheddingLevel: (json['sheddingLevel'] as num).toInt(),
      socialNeeds: (json['socialNeeds'] as num).toInt(),
      groomingNeeds: (json['groomingNeeds'] as num).toInt(),
      isHypoallergenic: json['isHypoallergenic'] as bool,
      isRare: json['isRare'] as bool,
    );

Map<String, dynamic> _$CatBreedToJson(CatBreed instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'origin': instance.origin,
      'temperament': instance.temperament,
      'lifeSpan': instance.lifeSpan,
      'weight': instance.weight,
      'imageUrl': instance.imageUrl,
      'characteristics': instance.characteristics,
      'history': instance.history,
      'energyLevel': instance.energyLevel,
      'sheddingLevel': instance.sheddingLevel,
      'socialNeeds': instance.socialNeeds,
      'groomingNeeds': instance.groomingNeeds,
      'isHypoallergenic': instance.isHypoallergenic,
      'isRare': instance.isRare,
    };
