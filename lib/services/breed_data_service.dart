import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/cat_breed.dart';

class BreedDataService {
  static const String _breedsDataPath = 'assets/data/cat_breeds.json';
  
  List<CatBreed>? _breeds;
  Map<String, CatBreed>? _breedsByName;
  Map<String, CatBreed>? _breedsById;
  bool _isInitialized = false;
  
  // Singleton pattern
  static final BreedDataService _instance = BreedDataService._internal();
  factory BreedDataService() => _instance;
  BreedDataService._internal();

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
      
      _isInitialized = true;
      print('Breed data service initialized with ${_breeds!.length} breeds');
      return true;
    } catch (e) {
      print('Error initializing breed data service: $e');
      
      // Fallback to hardcoded data if assets fail
      _breeds = _getHardcodedBreeds();
      _breedsByName = {
        for (final breed in _breeds!) breed.name.toLowerCase(): breed
      };
      _breedsById = {
        for (final breed in _breeds!) breed.id: breed
      };
      _isInitialized = true;
      return true;
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

  /// Search breeds by name or characteristics
  List<CatBreed> searchBreeds(String query) {
    if (_breeds == null || query.isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    
    return _breeds!.where((breed) {
      return breed.name.toLowerCase().contains(lowercaseQuery) ||
             breed.origin.toLowerCase().contains(lowercaseQuery) ||
             breed.temperament.toLowerCase().contains(lowercaseQuery) ||
             breed.characteristics.any((char) => 
                 char.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// Get breeds by origin country
  List<CatBreed> getBreedsByOrigin(String origin) {
    if (_breeds == null) return [];
    
    return _breeds!.where((breed) => 
        breed.origin.toLowerCase() == origin.toLowerCase()).toList();
  }

  /// Get breeds by energy level
  List<CatBreed> getBreedsByEnergyLevel(int energyLevel) {
    if (_breeds == null) return [];
    
    return _breeds!.where((breed) => breed.energyLevel == energyLevel).toList();
  }

  /// Get hypoallergenic breeds
  List<CatBreed> getHypoallergenicBreeds() {
    if (_breeds == null) return [];
    
    return _breeds!.where((breed) => breed.isHypoallergenic).toList();
  }

  /// Get rare breeds
  List<CatBreed> getRareBreeds() {
    if (_breeds == null) return [];
    
    return _breeds!.where((breed) => breed.isRare).toList();
  }

  /// Get popular breeds (non-rare, high social needs)
  List<CatBreed> getPopularBreeds() {
    if (_breeds == null) return [];
    
    return _breeds!.where((breed) => 
        !breed.isRare && breed.socialNeeds >= 4).toList();
  }

  /// Get breeds suitable for families (high social needs, medium energy)
  List<CatBreed> getFamilyFriendlyBreeds() {
    if (_breeds == null) return [];
    
    return _breeds!.where((breed) => 
        breed.socialNeeds >= 4 && 
        breed.energyLevel >= 3 && 
        breed.energyLevel <= 4).toList();
  }

  /// Get breeds suitable for apartments (low energy, low shedding)
  List<CatBreed> getApartmentFriendlyBreeds() {
    if (_breeds == null) return [];
    
    return _breeds!.where((breed) => 
        breed.energyLevel <= 3 && 
        breed.sheddingLevel <= 3).toList();
  }

  /// Get random breed of the day
  CatBreed? getBreedOfTheDay() {
    if (_breeds == null || _breeds!.isEmpty) return null;
    
    // Use date as seed for consistent daily breed
    final now = DateTime.now();
    final daysSinceEpoch = now.difference(DateTime(1970, 1, 1)).inDays;
    final random = daysSinceEpoch % _breeds!.length;
    
    return _breeds![random];
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

  /// Hardcoded fallback breed data
  List<CatBreed> _getHardcodedBreeds() {
    return [
      const CatBreed(
        id: 'persian',
        name: 'Persian',
        description: 'Known for their long, luxurious coat and sweet personality.',
        origin: 'Iran (Persia)',
        temperament: 'Quiet, Sweet, Docile',
        lifeSpan: '10-17 years',
        weight: '3.2-5.4 kg',
        imageUrl: 'assets/images/breeds/persian.jpg',
        characteristics: ['Long-haired', 'Flat face', 'Gentle', 'Indoor cat'],
        history: 'The Persian cat is one of the oldest known breeds of cats.',
        energyLevel: 2,
        sheddingLevel: 5,
        socialNeeds: 3,
        groomingNeeds: 5,
        isHypoallergenic: false,
        isRare: false,
      ),
      const CatBreed(
        id: 'maine_coon',
        name: 'Maine Coon',
        description: 'Large, gentle giants known for their intelligence and playful nature.',
        origin: 'United States',
        temperament: 'Gentle, Friendly, Intelligent',
        lifeSpan: '13-14 years',
        weight: '4.5-8.2 kg',
        imageUrl: 'assets/images/breeds/maine_coon.jpg',
        characteristics: ['Large size', 'Tufted ears', 'Long tail', 'Water-resistant fur'],
        history: 'Originally working cats, Maine Coons are native to the state of Maine.',
        energyLevel: 4,
        sheddingLevel: 4,
        socialNeeds: 4,
        groomingNeeds: 3,
        isHypoallergenic: false,
        isRare: false,
      ),
      const CatBreed(
        id: 'siamese',
        name: 'Siamese',
        description: 'Elegant and vocal cats with striking blue eyes and color points.',
        origin: 'Thailand',
        temperament: 'Active, Vocal, Social',
        lifeSpan: '12-20 years',
        weight: '2.3-4.5 kg',
        imageUrl: 'assets/images/breeds/siamese.jpg',
        characteristics: ['Color points', 'Blue eyes', 'Vocal', 'Slender build'],
        history: 'One of the first distinctly recognized breeds of Asian cat.',
        energyLevel: 5,
        sheddingLevel: 2,
        socialNeeds: 5,
        groomingNeeds: 1,
        isHypoallergenic: false,
        isRare: false,
      ),
      const CatBreed(
        id: 'british_shorthair',
        name: 'British Shorthair',
        description: 'Robust cats with a distinctive round face and dense coat.',
        origin: 'United Kingdom',
        temperament: 'Calm, Easy-going, Loyal',
        lifeSpan: '12-20 years',
        weight: '3.2-7.7 kg',
        imageUrl: 'assets/images/breeds/british_shorthair.jpg',
        characteristics: ['Round face', 'Dense coat', 'Sturdy build', 'Independent'],
        history: 'Pedigreed version of traditional British domestic cat.',
        energyLevel: 2,
        sheddingLevel: 3,
        socialNeeds: 3,
        groomingNeeds: 2,
        isHypoallergenic: false,
        isRare: false,
      ),
      const CatBreed(
        id: 'ragdoll',
        name: 'Ragdoll',
        description: 'Large, docile cats that go limp when picked up.',
        origin: 'United States',
        temperament: 'Docile, Placid, Quiet',
        lifeSpan: '13-18 years',
        weight: '4.5-9.1 kg',
        imageUrl: 'assets/images/breeds/ragdoll.jpg',
        characteristics: ['Large size', 'Blue eyes', 'Semi-long fur', 'Docile nature'],
        history: 'Developed in the 1960s by American breeder Ann Baker.',
        energyLevel: 2,
        sheddingLevel: 4,
        socialNeeds: 4,
        groomingNeeds: 3,
        isHypoallergenic: false,
        isRare: false,
      ),
    ];
  }
}