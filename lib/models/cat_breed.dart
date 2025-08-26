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
  @JsonKey(name: 'life_span')
  final String lifeSpan;

  @HiveField(6)
  final String weight;

  @HiveField(7)
  @JsonKey(name: 'image_url')
  final String imageUrl;

  @HiveField(8)
  final List<String> colors;

  @HiveField(9)
  final List<String> characteristics;

  @HiveField(10)
  final String history;

  @HiveField(11)
  @JsonKey(name: 'energy_level')
  final int energyLevel; // 1-5 scale

  @HiveField(12)
  final int sheddingLevel; // 1-5 scale (default if not provided)

  @HiveField(13)
  @JsonKey(name: 'social_needs')
  final int socialNeeds; // 1-5 scale

  @HiveField(14)
  @JsonKey(name: 'grooming_needs')
  final int groomingNeeds; // 1-5 scale

  @HiveField(15)
  @JsonKey(name: 'is_hypoallergenic')
  final bool isHypoallergenic;

  @HiveField(16)
  @JsonKey(name: 'is_rare')
  final bool isRare;

  @HiveField(17)
  @JsonKey(name: 'ml_index')
  final int? mlIndex;

  @HiveField(18)
  @JsonKey(name: 'available_for_recognition')
  final bool? availableForRecognition;

  const CatBreed({
    required this.id,
    required this.name,
    required this.description,
    required this.origin,
    required this.temperament,
    required this.lifeSpan,
    required this.weight,
    required this.imageUrl,
    required this.colors,
    this.characteristics = const [],
    this.history = '',
    required this.energyLevel,
    this.sheddingLevel = 2,
    required this.socialNeeds,
    required this.groomingNeeds,
    required this.isHypoallergenic,
    required this.isRare,
    this.mlIndex,
    this.availableForRecognition,
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
    List<String>? colors,
    List<String>? characteristics,
    String? history,
    int? energyLevel,
    int? sheddingLevel,
    int? socialNeeds,
    int? groomingNeeds,
    bool? isHypoallergenic,
    bool? isRare,
    int? mlIndex,
    bool? availableForRecognition,
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
      colors: colors ?? this.colors,
      characteristics: characteristics ?? this.characteristics,
      history: history ?? this.history,
      energyLevel: energyLevel ?? this.energyLevel,
      sheddingLevel: sheddingLevel ?? this.sheddingLevel,
      socialNeeds: socialNeeds ?? this.socialNeeds,
      groomingNeeds: groomingNeeds ?? this.groomingNeeds,
      isHypoallergenic: isHypoallergenic ?? this.isHypoallergenic,
      isRare: isRare ?? this.isRare,
      mlIndex: mlIndex ?? this.mlIndex,
      availableForRecognition: availableForRecognition ?? this.availableForRecognition,
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