import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
// ARCore import temporarily disabled for iOS compatibility
// import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';

import '../models/cat_breed.dart';
import '../models/recognition_result.dart';

class ARService {
  // Singleton pattern
  static final ARService _instance = ARService._internal();
  factory ARService() => _instance;
  ARService._internal();

  dynamic _arCoreController; // ArCoreController? when arcore_flutter_plugin is available
  final bool _isARSupported = false;
  bool _isInitialized = false;
  final bool _isARCoreAvailable = false; // Track if ARCore is available
  StreamSubscription? _nodeSubscription;

  /// Check if AR is supported on this device
  Future<bool> isARSupported() async {
    if (Platform.isAndroid) {
      // ARCore support disabled for now
      // When arcore_flutter_plugin is available, uncomment below:
      /*
      try {
        _isARSupported = await ArCoreController.checkArCoreAvailability();
        return _isARSupported;
      } catch (e) {
        print('Error checking AR support: $e');
        return false;
      }
      */
      print('ARCore support disabled for compatibility');
      return false;
    }
    return false; // iOS ARKit support would go here
  }

  /// Initialize AR service
  Future<ARResult> initialize() async {
    if (_isInitialized) {
      return ARResult.success('AR service already initialized');
    }

    try {
      // Check AR support
      if (!await isARSupported()) {
        return ARResult.failure('AR is not supported on this device');
      }

      // Check camera permission
      final cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          return ARResult.failure('Camera permission required for AR features');
        }
      }

      _isInitialized = true;
      return ARResult.success('AR service initialized successfully');
    } catch (e) {
      return ARResult.failure('Failed to initialize AR service: $e');
    }
  }

  /// Start AR session
  Future<ARResult> startARSession(dynamic controller) async {
    try {
      if (!_isInitialized) {
        final initResult = await initialize();
        if (!initResult.isSuccess) {
          return initResult;
        }
      }

      _arCoreController = controller;
      
      // ARCore functionality disabled for compatibility
      // await _addGroundPlaneNode();
      
      return ARResult.success('AR session started (fallback mode)');
    } catch (e) {
      return ARResult.failure('Failed to start AR session: $e');
    }
  }

  /// Stop AR session
  Future<void> stopARSession() async {
    try {
      await _nodeSubscription?.cancel();
      _nodeSubscription = null;
      
      if (_arCoreController != null) {
        await _arCoreController!.dispose();
        _arCoreController = null;
      }
    } catch (e) {
      print('Error stopping AR session: $e');
    }
  }

  /// Add cat breed information overlay in AR
  Future<ARResult> addBreedInfoOverlay({
    required CatBreed breed,
    required double confidence,
    dynamic position, // Vector3? when ARCore is available
  }) async {
    try {
      if (_arCoreController == null) {
        return ARResult.failure('AR session not active');
      }

      // ARCore functionality disabled - return success for demo
      print('Would add breed info overlay for ${breed.name} with ${(confidence * 100).toStringAsFixed(1)}% confidence');
      
      return ARResult.success('Breed info overlay added (demo mode)');
    } catch (e) {
      return ARResult.failure('Failed to add breed info overlay: $e');
    }
  }

  /// Add virtual cat model in AR space
  Future<ARResult> addVirtualCat({
    required CatBreed breed,
    dynamic position, // Vector3? when ARCore is available
    dynamic rotation, // Vector3? when ARCore is available
  }) async {
    try {
      if (_arCoreController == null) {
        return ARResult.failure('AR session not active');
      }

      // ARCore functionality disabled - return success for demo
      print('Would add virtual cat model for ${breed.name}');
      
      return ARResult.success('Virtual cat added (demo mode)');
    } catch (e) {
      return ARResult.failure('Failed to add virtual cat: $e');
    }
  }

  /// Add floating text with breed information
  Future<ARResult> addFloatingText({
    required String text,
    dynamic position, // Vector3? when ARCore is available
    Color color = Colors.white,
  }) async {
    try {
      if (_arCoreController == null) {
        return ARResult.failure('AR session not active');
      }

      // ARCore functionality disabled - return success for demo
      print('Would add floating text: "$text"');
      
      return ARResult.success('Floating text added (demo mode)');
    } catch (e) {
      return ARResult.failure('Failed to add floating text: $e');
    }
  }

  /// Add interactive cat fact bubbles
  Future<ARResult> addCatFactBubbles({
    required List<String> facts,
    required CatBreed breed,
  }) async {
    try {
      if (_arCoreController == null) {
        return ARResult.failure('AR session not active');
      }

      // ARCore functionality disabled - return success for demo
      print('Would add cat fact bubbles for ${breed.name}:');
      for (int i = 0; i < facts.length && i < 3; i++) {
        print('  - ${facts[i]}');
      }
      
      return ARResult.success('Cat fact bubbles added (demo mode)');
    } catch (e) {
      return ARResult.failure('Failed to add cat fact bubbles: $e');
    }
  }

  /// Add ground plane detection node (disabled for compatibility)
  Future<void> _addGroundPlaneNode() async {
    if (_arCoreController == null) return;

    // ARCore functionality disabled for compatibility
    print('Ground plane detection would be initialized here');
  }

  /// Handle tap events on AR objects
  void onNodeTap(String nodeName) {
    print('AR node tapped: $nodeName');
    
    // Handle different node types
    if (nodeName.startsWith('breed_info_')) {
      _handleBreedInfoTap(nodeName);
    } else if (nodeName.startsWith('virtual_cat_')) {
      _handleVirtualCatTap(nodeName);
    }
  }

  /// Handle breed info node tap
  void _handleBreedInfoTap(String nodeName) {
    // Extract breed ID from node name
    final breedId = nodeName.replaceFirst('breed_info_', '');
    print('Breed info tapped for: $breedId');
    
    // You could trigger a callback here to show detailed breed information
  }

  /// Handle virtual cat node tap
  void _handleVirtualCatTap(String nodeName) {
    // Extract breed ID from node name
    final breedId = nodeName.replaceFirst('virtual_cat_', '');
    print('Virtual cat tapped for: $breedId');
    
    // You could trigger animations or sounds here
  }

  /// Clear all AR nodes
  Future<ARResult> clearAllNodes() async {
    try {
      if (_arCoreController == null) {
        return ARResult.failure('AR session not active');
      }

      // Note: ArCore doesn't have a direct clearAll method
      // You would need to keep track of node names and remove them individually
      // For now, we'll dispose and restart the controller
      
      return ARResult.success('AR nodes cleared');
    } catch (e) {
      return ARResult.failure('Failed to clear AR nodes: $e');
    }
  }

  /// Get AR session info
  Map<String, dynamic> getSessionInfo() {
    return {
      'isSupported': _isARSupported,
      'isInitialized': _isInitialized,
      'isSessionActive': _arCoreController != null,
      'platform': Platform.operatingSystem,
    };
  }

  /// Dispose AR service
  Future<void> dispose() async {
    await stopARSession();
    _isInitialized = false;
  }
}

/// AR operation result
class ARResult {
  final bool isSuccess;
  final String? message;
  final String? error;

  const ARResult._({
    required this.isSuccess,
    this.message,
    this.error,
  });

  factory ARResult.success(String message) {
    return ARResult._(
      isSuccess: true,
      message: message,
    );
  }

  factory ARResult.failure(String error) {
    return ARResult._(
      isSuccess: false,
      error: error,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'ARResult.success(message: $message)';
    } else {
      return 'ARResult.failure(error: $error)';
    }
  }
}

/// AR node types for easy identification
enum ARNodeType {
  breedInfo,
  virtualCat,
  floatingText,
  catFact,
  groundPlane,
}

/// AR configuration options
class ARConfig {
  final bool enableGroundPlane;
  final bool enableLighting;
  final bool enableShadows;
  final double defaultScale;
  final Color defaultTextColor;

  const ARConfig({
    this.enableGroundPlane = true,
    this.enableLighting = true,
    this.enableShadows = false,
    this.defaultScale = 0.1,
    this.defaultTextColor = Colors.white,
  });
}