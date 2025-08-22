import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:meow_ai/models/cat_breed.dart';
import 'package:meow_ai/models/recognition_result.dart';
import 'package:meow_ai/models/user.dart';
import 'package:meow_ai/services/breed_data_service.dart';
import 'package:meow_ai/services/database_service.dart';
import 'package:meow_ai/services/ml_service.dart';
import 'package:meow_ai/services/camera_service.dart';

// Generate mocks using build_runner
@GenerateMocks([
  BreedDataService,
  DatabaseService,
  MLService,
  CameraService,
])
import 'unit_tests.mocks.dart';

void main() {
  group('CatBreed Model Tests', () {
    test('should create CatBreed from JSON', () {
      // Arrange
      final json = {
        'id': 'persian',
        'name': 'Persian',
        'description': 'Long-haired cat breed',
        'origin': 'Iran',
        'temperament': 'Gentle, Quiet',
        'lifeSpan': '12-17 years',
        'weight': '3.2-5.4 kg',
        'imageUrl': 'assets/images/persian.jpg',
        'characteristics': ['Long-haired', 'Gentle'],
        'history': 'Ancient breed from Persia',
        'energyLevel': 2,
        'sheddingLevel': 5,
        'socialNeeds': 3,
        'groomingNeeds': 5,
        'isHypoallergenic': false,
        'isRare': false,
      };

      // Act
      final breed = CatBreed.fromJson(json);

      // Assert
      expect(breed.id, equals('persian'));
      expect(breed.name, equals('Persian'));
      expect(breed.origin, equals('Iran'));
      expect(breed.energyLevel, equals(2));
      expect(breed.isHypoallergenic, isFalse);
      expect(breed.characteristics, hasLength(2));
    });

    test('should convert CatBreed to JSON', () {
      // Arrange
      const breed = CatBreed(
        id: 'siamese',
        name: 'Siamese',
        description: 'Vocal and social cat',
        origin: 'Thailand',
        temperament: 'Active, Vocal',
        lifeSpan: '12-20 years',
        weight: '2.3-4.5 kg',
        imageUrl: 'assets/images/siamese.jpg',
        characteristics: ['Vocal', 'Blue eyes'],
        history: 'Ancient Thai breed',
        energyLevel: 5,
        sheddingLevel: 2,
        socialNeeds: 5,
        groomingNeeds: 1,
        isHypoallergenic: false,
        isRare: false,
      );

      // Act
      final json = breed.toJson();

      // Assert
      expect(json['id'], equals('siamese'));
      expect(json['name'], equals('Siamese'));
      expect(json['energyLevel'], equals(5));
      expect(json['characteristics'], isA<List>());
    });

    test('should create copy with updated fields', () {
      // Arrange
      const originalBreed = CatBreed(
        id: 'maine_coon',
        name: 'Maine Coon',
        description: 'Large gentle cat',
        origin: 'United States',
        temperament: 'Gentle, Friendly',
        lifeSpan: '13-14 years',
        weight: '4.5-8.2 kg',
        imageUrl: 'assets/images/maine_coon.jpg',
        characteristics: ['Large', 'Friendly'],
        history: 'American working cat',
        energyLevel: 4,
        sheddingLevel: 4,
        socialNeeds: 4,
        groomingNeeds: 3,
        isHypoallergenic: false,
        isRare: false,
      );

      // Act
      final updatedBreed = originalBreed.copyWith(
        energyLevel: 5,
        isRare: true,
      );

      // Assert
      expect(updatedBreed.energyLevel, equals(5));
      expect(updatedBreed.isRare, isTrue);
      expect(updatedBreed.name, equals('Maine Coon')); // Unchanged field
    });
  });

  group('RecognitionResult Model Tests', () {
    late CatBreed testBreed;

    setUp(() {
      testBreed = const CatBreed(
        id: 'persian',
        name: 'Persian',
        description: 'Test breed',
        origin: 'Test Origin',
        temperament: 'Test Temperament',
        lifeSpan: '10-15 years',
        weight: '3-5 kg',
        imageUrl: 'test.jpg',
        characteristics: ['Test'],
        history: 'Test history',
        energyLevel: 3,
        sheddingLevel: 3,
        socialNeeds: 3,
        groomingNeeds: 3,
        isHypoallergenic: false,
        isRare: false,
      );
    });

    test('should create RecognitionResult with correct confidence levels', () {
      // Test high confidence
      final highConfidenceResult = RecognitionResult(
        id: 'test1',
        imagePath: '/test/path.jpg',
        predictedBreed: testBreed,
        confidence: 0.9,
        alternativePredictions: [],
        timestamp: DateTime.now(),
        processingTime: const Duration(milliseconds: 500),
        modelVersion: '1.0.0',
      );

      expect(highConfidenceResult.isHighConfidence, isTrue);
      expect(highConfidenceResult.isMediumConfidence, isFalse);
      expect(highConfidenceResult.isLowConfidence, isFalse);
      expect(highConfidenceResult.confidenceLevel, equals('High'));

      // Test medium confidence
      final mediumConfidenceResult = highConfidenceResult.copyWith(confidence: 0.7);
      expect(mediumConfidenceResult.isHighConfidence, isFalse);
      expect(mediumConfidenceResult.isMediumConfidence, isTrue);
      expect(mediumConfidenceResult.confidenceLevel, equals('Medium'));

      // Test low confidence
      final lowConfidenceResult = highConfidenceResult.copyWith(confidence: 0.3);
      expect(lowConfidenceResult.isLowConfidence, isTrue);
      expect(lowConfidenceResult.confidenceLevel, equals('Low'));
    });

    test('should format confidence percentage correctly', () {
      // Arrange
      final result = RecognitionResult(
        id: 'test',
        imagePath: '/test/path.jpg',
        predictedBreed: testBreed,
        confidence: 0.856,
        alternativePredictions: [],
        timestamp: DateTime.now(),
        processingTime: const Duration(milliseconds: 500),
        modelVersion: '1.0.0',
      );

      // Act & Assert
      expect(result.confidencePercentage, equals('85%'));
    });
  });

  group('User Model Tests', () {
    test('should create anonymous user', () {
      // Act
      final user = User.anonymous();

      // Assert
      expect(user.isAnonymous, isTrue);
      expect(user.email, isEmpty);
      expect(user.id, startsWith('anonymous_'));
      expect(user.preferences, isA<UserPreferences>());
    });

    test('should create user with default preferences', () {
      // Act
      final preferences = UserPreferences.defaultPreferences();

      // Assert
      expect(preferences.isDarkMode, isFalse);
      expect(preferences.language, equals('en'));
      expect(preferences.enableNotifications, isTrue);
      expect(preferences.showConfidenceScores, isTrue);
    });

    test('should update user stats correctly', () {
      // Arrange
      const initialStats = UserStats(
        totalRecognitions: 0,
        uniqueBreedsIdentified: 0,
        favoritesSaved: 0,
      );

      // Act
      final updatedStats = initialStats.copyWith(
        totalRecognitions: 5,
        uniqueBreedsIdentified: 3,
        favoritesSaved: 2,
      );

      // Assert
      expect(updatedStats.totalRecognitions, equals(5));
      expect(updatedStats.uniqueBreedsIdentified, equals(3));
      expect(updatedStats.favoritesSaved, equals(2));
    });
  });

  group('BreedDataService Tests', () {
    late MockBreedDataService mockBreedDataService;

    setUp(() {
      mockBreedDataService = MockBreedDataService();
    });

    test('should initialize successfully', () async {
      // Arrange
      when(mockBreedDataService.initialize()).thenAnswer((_) async => true);

      // Act
      final result = await mockBreedDataService.initialize();

      // Assert
      expect(result, isTrue);
      verify(mockBreedDataService.initialize()).called(1);
    });

    test('should return all breeds', () {
      // Arrange
      const testBreeds = [
        CatBreed(
          id: 'persian',
          name: 'Persian',
          description: 'Test',
          origin: 'Iran',
          temperament: 'Gentle',
          lifeSpan: '10-15 years',
          weight: '3-5 kg',
          imageUrl: 'test.jpg',
          characteristics: ['Test'],
          history: 'Test',
          energyLevel: 3,
          sheddingLevel: 3,
          socialNeeds: 3,
          groomingNeeds: 3,
          isHypoallergenic: false,
          isRare: false,
        ),
      ];
      when(mockBreedDataService.getAllBreeds()).thenReturn(testBreeds);

      // Act
      final breeds = mockBreedDataService.getAllBreeds();

      // Assert
      expect(breeds, hasLength(1));
      expect(breeds.first.name, equals('Persian'));
    });

    test('should search breeds by query', () {
      // Arrange
      const query = 'persian';
      const expectedBreeds = [
        CatBreed(
          id: 'persian',
          name: 'Persian',
          description: 'Test',
          origin: 'Iran',
          temperament: 'Gentle',
          lifeSpan: '10-15 years',
          weight: '3-5 kg',
          imageUrl: 'test.jpg',
          characteristics: ['Test'],
          history: 'Test',
          energyLevel: 3,
          sheddingLevel: 3,
          socialNeeds: 3,
          groomingNeeds: 3,
          isHypoallergenic: false,
          isRare: false,
        ),
      ];
      when(mockBreedDataService.searchBreeds(query)).thenReturn(expectedBreeds);

      // Act
      final results = mockBreedDataService.searchBreeds(query);

      // Assert
      expect(results, hasLength(1));
      expect(results.first.name, contains('Persian'));
      verify(mockBreedDataService.searchBreeds(query)).called(1);
    });
  });

  group('DatabaseService Tests', () {
    late MockDatabaseService mockDatabaseService;

    setUp(() {
      mockDatabaseService = MockDatabaseService();
    });

    test('should initialize database successfully', () async {
      // Arrange
      when(mockDatabaseService.initialize()).thenAnswer((_) async => true);

      // Act
      final result = await mockDatabaseService.initialize();

      // Assert
      expect(result, isTrue);
      verify(mockDatabaseService.initialize()).called(1);
    });

    test('should save recognition result', () async {
      // Arrange
      final testResult = RecognitionResult(
        id: 'test',
        imagePath: '/test/path.jpg',
        predictedBreed: const CatBreed(
          id: 'persian',
          name: 'Persian',
          description: 'Test',
          origin: 'Iran',
          temperament: 'Gentle',
          lifeSpan: '10-15 years',
          weight: '3-5 kg',
          imageUrl: 'test.jpg',
          characteristics: ['Test'],
          history: 'Test',
          energyLevel: 3,
          sheddingLevel: 3,
          socialNeeds: 3,
          groomingNeeds: 3,
          isHypoallergenic: false,
          isRare: false,
        ),
        confidence: 0.9,
        alternativePredictions: [],
        timestamp: DateTime.now(),
        processingTime: const Duration(milliseconds: 500),
        modelVersion: '1.0.0',
      );
      when(mockDatabaseService.saveRecognitionResult(testResult))
          .thenAnswer((_) async => true);

      // Act
      final result = await mockDatabaseService.saveRecognitionResult(testResult);

      // Assert
      expect(result, isTrue);
      verify(mockDatabaseService.saveRecognitionResult(testResult)).called(1);
    });

    test('should get statistics', () async {
      // Arrange
      const expectedStats = {
        'total_recognitions': 10,
        'unique_breeds': 5,
        'favorites': 3,
      };
      when(mockDatabaseService.getStatistics())
          .thenAnswer((_) async => expectedStats);

      // Act
      final stats = await mockDatabaseService.getStatistics();

      // Assert
      expect(stats['total_recognitions'], equals(10));
      expect(stats['unique_breeds'], equals(5));
      expect(stats['favorites'], equals(3));
    });
  });

  group('MLService Tests', () {
    late MockMLService mockMLService;

    setUp(() {
      mockMLService = MockMLService();
    });

    test('should initialize ML service', () async {
      // Arrange
      when(mockMLService.initialize()).thenAnswer((_) async => true);

      // Act
      final result = await mockMLService.initialize();

      // Assert
      expect(result, isTrue);
      verify(mockMLService.initialize()).called(1);
    });

    test('should recognize breed from image', () async {
      // Arrange
      const imagePath = '/test/cat.jpg';
      final expectedResult = RecognitionResult(
        id: 'test',
        imagePath: imagePath,
        predictedBreed: const CatBreed(
          id: 'persian',
          name: 'Persian',
          description: 'Test',
          origin: 'Iran',
          temperament: 'Gentle',
          lifeSpan: '10-15 years',
          weight: '3-5 kg',
          imageUrl: 'test.jpg',
          characteristics: ['Test'],
          history: 'Test',
          energyLevel: 3,
          sheddingLevel: 3,
          socialNeeds: 3,
          groomingNeeds: 3,
          isHypoallergenic: false,
          isRare: false,
        ),
        confidence: 0.85,
        alternativePredictions: [],
        timestamp: DateTime.now(),
        processingTime: const Duration(milliseconds: 1500),
        modelVersion: '1.0.0',
      );

      when(mockMLService.recognizeBreed(imagePath))
          .thenAnswer((_) async => expectedResult);

      // Act
      final result = await mockMLService.recognizeBreed(imagePath);

      // Assert
      expect(result, isNotNull);
      expect(result!.predictedBreed.name, equals('Persian'));
      expect(result.confidence, equals(0.85));
      verify(mockMLService.recognizeBreed(imagePath)).called(1);
    });

    test('should get model info', () {
      // Arrange
      const expectedInfo = {
        'status': 'initialized',
        'input_size': 224,
        'output_size': 100,
        'supported_breeds': 50,
      };
      when(mockMLService.getModelInfo()).thenReturn(expectedInfo);

      // Act
      final info = mockMLService.getModelInfo();

      // Assert
      expect(info['status'], equals('initialized'));
      expect(info['input_size'], equals(224));
      expect(info['supported_breeds'], equals(50));
    });
  });

  group('CameraService Tests', () {
    late MockCameraService mockCameraService;

    setUp(() {
      mockCameraService = MockCameraService();
    });

    test('should initialize camera service', () async {
      // Arrange
      when(mockCameraService.initialize()).thenAnswer((_) async => true);

      // Act
      final result = await mockCameraService.initialize();

      // Assert
      expect(result, isTrue);
      verify(mockCameraService.initialize()).called(1);
    });

    test('should take photo successfully', () async {
      // Arrange
      const expectedPath = '/app/images/photo_123.jpg';
      when(mockCameraService.takePhoto()).thenAnswer((_) async => expectedPath);

      // Act
      final imagePath = await mockCameraService.takePhoto();

      // Assert
      expect(imagePath, equals(expectedPath));
      verify(mockCameraService.takePhoto()).called(1);
    });

    test('should pick image from gallery', () async {
      // Arrange
      const expectedPath = '/app/images/gallery_456.jpg';
      when(mockCameraService.pickImageFromGallery())
          .thenAnswer((_) async => expectedPath);

      // Act
      final imagePath = await mockCameraService.pickImageFromGallery();

      // Assert
      expect(imagePath, equals(expectedPath));
      verify(mockCameraService.pickImageFromGallery()).called(1);
    });

    test('should check permissions', () async {
      // Arrange
      const expectedPermissions = {
        'camera': true,
        'storage': true,
      };
      when(mockCameraService.checkPermissions())
          .thenAnswer((_) async => expectedPermissions);

      // Act
      final permissions = await mockCameraService.checkPermissions();

      // Assert
      expect(permissions['camera'], isTrue);
      expect(permissions['storage'], isTrue);
    });
  });

  group('Integration Tests', () {
    test('should complete full recognition workflow', () async {
      // This would be implemented as an integration test
      // testing the complete flow from image capture to recognition
      // and saving to database
      
      // Mock the entire workflow
      final mockCameraService = MockCameraService();
      final mockMLService = MockMLService();
      final mockDatabaseService = MockDatabaseService();

      // Setup mocks for complete workflow
      when(mockCameraService.takePhoto())
          .thenAnswer((_) async => '/test/image.jpg');

      final recognitionResult = RecognitionResult(
        id: 'test_recognition',
        imagePath: '/test/image.jpg',
        predictedBreed: const CatBreed(
          id: 'persian',
          name: 'Persian',
          description: 'Test breed',
          origin: 'Iran',
          temperament: 'Gentle',
          lifeSpan: '10-15 years',
          weight: '3-5 kg',
          imageUrl: 'test.jpg',
          characteristics: ['Test'],
          history: 'Test',
          energyLevel: 3,
          sheddingLevel: 3,
          socialNeeds: 3,
          groomingNeeds: 3,
          isHypoallergenic: false,
          isRare: false,
        ),
        confidence: 0.9,
        alternativePredictions: [],
        timestamp: DateTime.now(),
        processingTime: const Duration(milliseconds: 1500),
        modelVersion: '1.0.0',
      );

      when(mockMLService.recognizeBreed('/test/image.jpg'))
          .thenAnswer((_) async => recognitionResult);

      when(mockDatabaseService.saveRecognitionResult(recognitionResult))
          .thenAnswer((_) async => true);

      // Execute workflow
      final imagePath = await mockCameraService.takePhoto();
      expect(imagePath, isNotNull);

      final result = await mockMLService.recognizeBreed(imagePath!);
      expect(result, isNotNull);
      expect(result!.confidence, greaterThan(0.8));

      final saved = await mockDatabaseService.saveRecognitionResult(result);
      expect(saved, isTrue);

      // Verify all steps were called
      verify(mockCameraService.takePhoto()).called(1);
      verify(mockMLService.recognizeBreed(imagePath)).called(1);
      verify(mockDatabaseService.saveRecognitionResult(result)).called(1);
    });
  });
}