import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cat_breed.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class CatBreed {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String origin;

  @HiveField(4)
  final String temperament;

  @HiveField(5)
  final String lifeSpan;

  @HiveField(6)
  final String weight;

  @HiveField(7)
  final String imageUrl;

  @HiveField(8)
  final List<String> characteristics;

  @HiveField(9)
  final String history;

  @HiveField(10)
  final int energyLevel; // 1-5 scale

  @HiveField(11)
  final int sheddingLevel; // 1-5 scale

  @HiveField(12)
  final int socialNeeds; // 1-5 scale

  @HiveField(13)
  final int groomingNeeds; // 1-5 scale

  @HiveField(14)
  final bool isHypoallergenic;

  @HiveField(15)
  final bool isRare;

  const CatBreed({
    required this.id,
    required this.name,
    required this.description,
    required this.origin,
    required this.temperament,
    required this.lifeSpan,
    required this.weight,
    required this.imageUrl,
    required this.characteristics,
    required this.history,
    required this.energyLevel,
    required this.sheddingLevel,
    required this.socialNeeds,
    required this.groomingNeeds,
    required this.isHypoallergenic,
    required this.isRare,
  });

  factory CatBreed.fromJson(Map<String, dynamic> json) => 
      _$CatBreedFromJson(json);
  
  Map<String, dynamic> toJson() => _$CatBreedToJson(this);

  CatBreed copyWith({
    String? id,
    String? name,
    String? description,
    String? origin,
    String? temperament,
    String? lifeSpan,
    String? weight,
    String? imageUrl,
    List<String>? characteristics,
    String? history,
    int? energyLevel,
    int? sheddingLevel,
    int? socialNeeds,
    int? groomingNeeds,
    bool? isHypoallergenic,
    bool? isRare,
  }) {
    return CatBreed(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      origin: origin ?? this.origin,
      temperament: temperament ?? this.temperament,
      lifeSpan: lifeSpan ?? this.lifeSpan,
      weight: weight ?? this.weight,
      imageUrl: imageUrl ?? this.imageUrl,
      characteristics: characteristics ?? this.characteristics,
      history: history ?? this.history,
      energyLevel: energyLevel ?? this.energyLevel,
      sheddingLevel: sheddingLevel ?? this.sheddingLevel,
      socialNeeds: socialNeeds ?? this.socialNeeds,
      groomingNeeds: groomingNeeds ?? this.groomingNeeds,
      isHypoallergenic: isHypoallergenic ?? this.isHypoallergenic,
      isRare: isRare ?? this.isRare,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatBreed && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CatBreed(id: $id, name: $name, origin: $origin)';
  }
}