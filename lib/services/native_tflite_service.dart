import 'package:flutter/services.dart';
import 'dart:io';

/// Native TensorFlow Lite implementation using platform channels
/// Bypasses Flutter package dependency issues by using native Android/iOS code
class NativeTFLiteService {
  static const MethodChannel _channel = MethodChannel('native_tflite');
  
  static final NativeTFLiteService _instance = NativeTFLiteService._internal();
  factory NativeTFLiteService() => _instance;
  NativeTFLiteService._internal();
  
  bool _isInitialized = false;
  
  /// Initialize the native TensorFlow Lite interpreter
  Future<bool> initialize() async {
    try {
      print('🤖 NativeTFLite: Initializing native TensorFlow Lite...');
      
      final result = await _channel.invokeMethod('initializeModel', {
        'modelPath': 'assets/models/model.tflite',
        'labelsPath': 'assets/models/labels.txt',
        'inputSize': 384,
        'outputSize': 40,
      });
      
      _isInitialized = result['success'] ?? false;
      
      if (_isInitialized) {
        print('✅ NativeTFLite: Successfully initialized with native implementation');
        print('📋 NativeTFLite: Model ready for ${result['numLabels']} cat breeds');
        return true;
      } else {
        print('❌ NativeTFLite: Failed to initialize: ${result['error']}');
        return false;
      }
      
    } catch (e) {
      print('❌ NativeTFLite: Platform channel error: $e');
      _isInitialized = false;
      return false;
    }
  }
  
  /// Run inference on image using native TensorFlow Lite
  Future<Map<String, dynamic>?> runInference(String imagePath) async {
    if (!_isInitialized) {
      print('❌ NativeTFLite: Service not initialized');
      return null;
    }
    
    try {
      print('🔍 NativeTFLite: Running native inference...');
      
      // Read image file as bytes
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      
      final result = await _channel.invokeMethod('runInference', {
        'imageBytes': imageBytes,
        'imagePath': imagePath,
      });
      
      if (result['success'] == true) {
        print('✅ NativeTFLite: Inference completed successfully');
        return {
          'predictions': result['predictions'], // List of {label, confidence}
          'processingTime': result['processingTime'], // milliseconds
          'imageSize': result['imageSize'], // {width, height}
        };
      } else {
        print('❌ NativeTFLite: Inference failed: ${result['error']}');
        return null;
      }
      
    } catch (e) {
      print('❌ NativeTFLite: Inference error: $e');
      return null;
    }
  }
  
  /// Check if native implementation is available
  Future<bool> isNativeSupported() async {
    try {
      final result = await _channel.invokeMethod('isSupported');
      return result['supported'] ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// Get native implementation info
  Future<Map<String, dynamic>> getNativeInfo() async {
    try {
      final result = await _channel.invokeMethod('getInfo');
      return {
        'platform': result['platform'] ?? 'unknown',
        'version': result['version'] ?? 'unknown', 
        'capabilities': result['capabilities'] ?? [],
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
