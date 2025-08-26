import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/cat_breed.dart';

/// Service for managing comprehensive cat breed information and characteristics.
/// 
/// This service loads detailed breed profiles for all 40 supported breeds
/// and provides rich information like descriptions, history, temperament, etc.
/// 
/// This corresponds directly to the trained ML model breeds for accurate recognition.
class BreedDataService {
  static const String _breedsDataPath = 'assets/data/enhanced_breeds.json';
  
  List<CatBreed>? _breeds;
  Map<String, CatBreed>? _breedsByName;
  Map<String, CatBreed>? _breedsById;
  Map<String, CatBreed>? _breedsByLabel;
  bool _isInitialized = false;
  
  // Singleton pattern
  static final BreedDataService _instance = BreedDataService._internal();
  factory BreedDataService() => _instance;
  BreedDataService._internal();

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize breed data from assets
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      final breedsJson = await rootBundle.loadString(_breedsDataPath);
      final breedsData = json.decode(breedsJson) as List<dynamic>;
      
      _breeds = breedsData
          .map((breedJson) => CatBreed.fromJson(breedJson as Map<String, dynamic>))
          .toList();
      
      // Create lookup maps for efficient searching
      _breedsByName = {
        for (final breed in _breeds!) breed.name.toLowerCase(): breed
      };
      
      _breedsById = {
        for (final breed in _breeds!) breed.id: breed
      };
      
      _breedsByLabel = {
        for (final breed in _breeds!) breed.id.toLowerCase(): breed
      };
      
      _isInitialized = true;
      print('✅ Breed data service initialized with ${_breeds!.length} breed profiles for trained model recognition');
      return true;
    } catch (e) {
      print('❌ Error initializing breed data service: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Get all cat breeds
  List<CatBreed> getAllBreeds() {
    return _breeds ?? [];
  }

  /// Get breed by ID
  CatBreed? getBreedById(String id) {
    return _breedsById?[id];
  }

  /// Get breed by name (case-insensitive)
  CatBreed? getBreedByName(String name) {
    return _breedsByName?[name.toLowerCase()];
  }
  
  /// Get breed by ML label (for recognition results)
  CatBreed? getBreedByLabel(String label) {
    return _breedsByLabel?[label.toLowerCase()];
  }
  
  /// Get breed statistics
  Map<String, dynamic> getBreedStatistics() {
    if (_breeds == null) return {};
    
    final origins = <String, int>{};
    var totalHypoallergenic = 0;
    var totalRare = 0;
    var avgEnergyLevel = 0.0;
    var avgSocialNeeds = 0.0;
    
    for (final breed in _breeds!) {
      // Count origins
      origins[breed.origin] = (origins[breed.origin] ?? 0) + 1;
      
      // Count special characteristics
      if (breed.isHypoallergenic) totalHypoallergenic++;
      if (breed.isRare) totalRare++;
      
      // Sum for averages
      avgEnergyLevel += breed.energyLevel;
      avgSocialNeeds += breed.socialNeeds;
    }
    
    avgEnergyLevel /= _breeds!.length;
    avgSocialNeeds /= _breeds!.length;
    
    return {
      'total_breeds': _breeds!.length,
      'origins': origins,
      'hypoallergenic_count': totalHypoallergenic,
      'rare_count': totalRare,
      'average_energy_level': avgEnergyLevel,
      'average_social_needs': avgSocialNeeds,
    };
  }
}