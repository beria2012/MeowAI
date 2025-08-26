import 'package:flutter_test/flutter_test.dart';
import 'package:meow_ai/services/ml_service.dart';
import 'package:meow_ai/services/breed_data_service.dart';

void main() {
  group('ML Service Integration Tests', () {
    late MLService mlService;
    late BreedDataService breedService;

    setUpAll(() async {
      // Initialize Flutter binding for testing
      TestWidgetsFlutterBinding.ensureInitialized();
      
      mlService = MLService();
      breedService = BreedDataService();
      
      // Initialize services
      await breedService.initialize();
      await mlService.initialize();
    });

    test('ML Service should initialize successfully', () async {
      final isInitialized = await mlService.initialize();
      expect(isInitialized, true);
    });

    test('ML Service should load 223 breed labels', () async {
      await mlService.initialize();
      final supportedBreeds = mlService.getSupportedBreeds();
      
      print('Number of supported breeds: ${supportedBreeds.length}');
      print('First 10 breeds: ${supportedBreeds.take(10).join(", ")}');
      
      // Verify we have 223 breeds from our advanced model
      expect(supportedBreeds.length, 223);
      
      // Check for some expected breeds
      expect(supportedBreeds.contains('Abyssinian'), true);
      expect(supportedBreeds.contains('Maine_Coon'), true);
      expect(supportedBreeds.contains('Persian'), true);
      expect(supportedBreeds.contains('Siamese'), true);
    });

    test('ML Service model info should show correct parameters', () async {
      await mlService.initialize();
      final modelInfo = mlService.getModelInfo();
      
      print('Model info: $modelInfo');
      
      expect(modelInfo['status'], 'initialized');
      expect(modelInfo['input_size'], 224);
      expect(modelInfo['output_size'], 223);
      expect(modelInfo['supported_breeds'], 223);
    });

    test('Breed Data Service should handle missing breeds with fallbacks', () async {
      await breedService.initialize();
      
      // Test with a breed that exists in our model but not in JSON
      final breed = breedService.getBreedByName('Abyssinian_Blue');
      
      // Should return a fallback breed object
      expect(breed, isNotNull);
      expect(breed!.name, 'Abyssinian Blue');
      expect(mlService.supportsBreed('Abyssinian_Blue'), true);
    });

    test('Should handle breed name variations', () async {
      await mlService.initialize();
      
      // Test different naming conventions (case-insensitive matching)
      expect(mlService.supportsBreed('maine_coon'), true); // Case-insensitive
      expect(mlService.supportsBreed('Maine_Coon'), true);
      expect(mlService.supportsBreed('bengal'), true); // Case-insensitive
      expect(mlService.supportsBreed('Bengal'), true);
    });

    test('Breed Data Service should create appropriate fallback breeds', () async {
      await breedService.initialize();
      
      // Test various breed patterns
      final persianBlue = breedService.getBreedByName('Persian_Blue_Point');
      expect(persianBlue, isNotNull);
      expect(persianBlue!.origin, 'Iran');
      
      final britishSilver = breedService.getBreedByName('British_Silver');
      expect(britishSilver, isNotNull);
      expect(britishSilver!.origin, 'United Kingdom');
      
      final cosmicCat = breedService.getBreedByName('Cosmic_Cat');
      expect(cosmicCat, isNotNull);
      expect(cosmicCat!.isRare, true);
    });

    tearDownAll(() {
      mlService.dispose();
    });
  });
}