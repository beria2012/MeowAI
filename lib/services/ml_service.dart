import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import '../models/cat_breed.dart';
import '../models/recognition_result.dart';
import 'breed_data_service.dart';

class MLService {
  static const String _modelPath = 'assets/models/cat_breed_classifier.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';
  static const int _inputSize = 224;
  static const int _outputSize = 100; // Number of cat breeds supported
  static const double _confidenceThreshold = 0.1;
  
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isInitialized = false;
  
  // Singleton pattern
  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();

  /// Initialize the ML model and labels
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Load the TensorFlow Lite model
      _interpreter = await _loadModel();
      
      // Load class labels
      _labels = await _loadLabels();
      
      if (_interpreter != null && _labels != null) {
        _isInitialized = true;
        print('ML Service initialized successfully');
        return true;
      }
    } catch (e) {
      print('Error initializing ML Service: $e');
    }
    
    return false;
  }

  /// Load the TensorFlow Lite model
  Future<Interpreter?> _loadModel() async {
    try {
      final options = InterpreterOptions();
      
      // Use GPU delegate if available
      if (Platform.isAndroid) {
        options.addDelegate(GpuDelegateV2());
      } else if (Platform.isIOS) {
        options.addDelegate(GpuDelegate());
      }
      
      // Use NNAPI delegate on Android for better performance
      if (Platform.isAndroid) {
        options.addDelegate(NnApiDelegate());
      }
      
      return await Interpreter.fromAsset(_modelPath, options: options);
    } catch (e) {
      print('Error loading model: $e');
      // Fallback to CPU-only execution
      try {
        return await Interpreter.fromAsset(_modelPath);
      } catch (fallbackError) {
        print('Error loading model with CPU fallback: $fallbackError');
        return null;
      }
    }
  }

  /// Load class labels from assets
  Future<List<String>?> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString(_labelsPath);
      return labelsData.split('\n').where((label) => label.isNotEmpty).toList();
    } catch (e) {
      print('Error loading labels: $e');
      return null;
    }
  }

  /// Preprocess image for model input
  Float32List _preprocessImage(img.Image image) {
    // Resize image to model input size
    final resizedImage = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Convert to Float32List and normalize
    final inputBuffer = Float32List(_inputSize * _inputSize * 3);
    var bufferIndex = 0;

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resizedImage.getPixel(x, y);
        
        // Extract RGB values and normalize to [0, 1]
        final r = img.getRed(pixel) / 255.0;
        final g = img.getGreen(pixel) / 255.0;
        final b = img.getBlue(pixel) / 255.0;
        
        // Store in RGB order
        inputBuffer[bufferIndex++] = r;
        inputBuffer[bufferIndex++] = g;
        inputBuffer[bufferIndex++] = b;
      }
    }

    return inputBuffer;
  }

  /// Post-process model output to get predictions
  List<PredictionScore> _postprocessOutput(List<double> output) {
    final predictions = <PredictionScore>[];
    
    for (int i = 0; i < output.length && i < _labels!.length; i++) {
      if (output[i] > _confidenceThreshold) {
        final breedName = _labels![i];
        final breed = BreedDataService().getBreedByName(breedName);
        
        if (breed != null) {
          predictions.add(PredictionScore(
            breed: breed,
            confidence: output[i],
            rank: predictions.length + 1,
          ));
        }
      }
    }
    
    // Sort by confidence (highest first)
    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    // Update ranks
    for (int i = 0; i < predictions.length; i++) {
      predictions[i] = PredictionScore(
        breed: predictions[i].breed,
        confidence: predictions[i].confidence,
        rank: i + 1,
      );
    }
    
    return predictions;
  }

  /// Recognize cat breed from image file
  Future<RecognitionResult?> recognizeBreed(String imagePath) async {
    if (!_isInitialized || _interpreter == null || _labels == null) {
      throw Exception('ML Service not initialized');
    }

    final stopwatch = Stopwatch()..start();
    
    try {
      // Load and decode image
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Preprocess image
      final inputBuffer = _preprocessImage(image);
      
      // Prepare input and output tensors
      final input = inputBuffer.reshape([1, _inputSize, _inputSize, 3]);
      final output = List.filled(1 * _outputSize, 0.0).reshape([1, _outputSize]);
      
      // Run inference
      _interpreter!.run(input, output);
      
      stopwatch.stop();
      
      // Process results
      final predictions = _postprocessOutput(output[0].cast<double>());
      
      if (predictions.isEmpty) {
        return null;
      }
      
      // Create recognition result
      final result = RecognitionResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: imagePath,
        predictedBreed: predictions.first.breed,
        confidence: predictions.first.confidence,
        alternativePredictions: predictions.skip(1).take(4).toList(),
        timestamp: DateTime.now(),
        processingTime: stopwatch.elapsed,
        modelVersion: '1.0.0',
        metadata: {
          'image_size': '${image.width}x${image.height}',
          'total_predictions': predictions.length,
        },
      );
      
      return result;
    } catch (e) {
      print('Error during breed recognition: $e');
      return null;
    }
  }

  /// Get model information
  Map<String, dynamic> getModelInfo() {
    if (!_isInitialized) {
      return {'status': 'not_initialized'};
    }
    
    return {
      'status': 'initialized',
      'input_size': _inputSize,
      'output_size': _outputSize,
      'supported_breeds': _labels?.length ?? 0,
      'confidence_threshold': _confidenceThreshold,
    };
  }

  /// Check if model supports a specific breed
  bool supportsBreed(String breedName) {
    return _labels?.contains(breedName.toLowerCase()) ?? false;
  }

  /// Get all supported breed names
  List<String> getSupportedBreeds() {
    return _labels ?? [];
  }

  /// Benchmark model performance
  Future<Map<String, dynamic>> benchmark({int iterations = 10}) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('ML Service not initialized');
    }

    final times = <Duration>[];
    
    // Create a dummy input for benchmarking
    final dummyInput = Float32List(_inputSize * _inputSize * 3);
    for (int i = 0; i < dummyInput.length; i++) {
      dummyInput[i] = math.Random().nextDouble();
    }
    
    final input = dummyInput.reshape([1, _inputSize, _inputSize, 3]);
    final output = List.filled(1 * _outputSize, 0.0).reshape([1, _outputSize]);
    
    // Warm up
    for (int i = 0; i < 3; i++) {
      _interpreter!.run(input, output);
    }
    
    // Benchmark iterations
    for (int i = 0; i < iterations; i++) {
      final stopwatch = Stopwatch()..start();
      _interpreter!.run(input, output);
      stopwatch.stop();
      times.add(stopwatch.elapsed);
    }
    
    // Calculate statistics
    final totalMs = times.fold<int>(0, (sum, time) => sum + time.inMilliseconds);
    final avgMs = totalMs / iterations;
    final minMs = times.map((t) => t.inMilliseconds).reduce(math.min);
    final maxMs = times.map((t) => t.inMilliseconds).reduce(math.max);
    
    return {
      'iterations': iterations,
      'average_ms': avgMs,
      'min_ms': minMs,
      'max_ms': maxMs,
      'total_ms': totalMs,
    };
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
    _isInitialized = false;
  }
}