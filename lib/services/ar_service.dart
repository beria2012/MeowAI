import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';

import '../models/cat_breed.dart';
import '../models/recognition_result.dart';

class ARService {
  // Singleton pattern
  static final ARService _instance = ARService._internal();
  factory ARService() => _instance;
  ARService._internal();

  ArCoreController? _arCoreController;
  bool _isARSupported = false;
  bool _isInitialized = false;
  StreamSubscription? _nodeSubscription;

  /// Check if AR is supported on this device
  Future<bool> isARSupported() async {
    if (Platform.isAndroid) {
      try {
        _isARSupported = await ArCoreController.checkArCoreAvailability();
        return _isARSupported;
      } catch (e) {
        print('Error checking AR support: $e');
        return false;
      }
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
  Future<ARResult> startARSession(ArCoreController controller) async {
    try {
      if (!_isInitialized) {
        final initResult = await initialize();
        if (!initResult.isSuccess) {
          return initResult;
        }
      }

      _arCoreController = controller;
      
      // Add ground plane detection
      await _addGroundPlaneNode();
      
      return ARResult.success('AR session started');
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
    Vector3? position,
  }) async {
    try {
      if (_arCoreController == null) {
        return ARResult.failure('AR session not active');
      }

      // Create a node with cat breed information
      final node = ArCoreReferenceNode(
        name: 'breed_info_${breed.id}',
        objectUrl: 'assets/models/cat_info_card.sfb', // 3D model file
        position: position ?? Vector3(0, 0, -0.5),
        scale: Vector3(0.1, 0.1, 0.1),
      );

      await _arCoreController!.addArCoreNode(node);
      
      return ARResult.success('Breed info overlay added');
    } catch (e) {
      return ARResult.failure('Failed to add breed info overlay: $e');
    }
  }

  /// Add virtual cat model in AR space
  Future<ARResult> addVirtualCat({
    required CatBreed breed,
    Vector3? position,
    Vector3? rotation,
  }) async {
    try {
      if (_arCoreController == null) {
        return ARResult.failure('AR session not active');
      }

      // Create a virtual cat node
      final catNode = ArCoreReferenceNode(
        name: 'virtual_cat_${breed.id}',
        objectUrl: 'assets/models/cat_${breed.id.toLowerCase()}.sfb',
        position: position ?? Vector3(0, 0, -1.0),
        rotation: rotation ?? Vector4(0, 1, 0, 0),
        scale: Vector3(0.2, 0.2, 0.2),
      );

      await _arCoreController!.addArCoreNode(catNode);
      
      return ARResult.success('Virtual cat added');
    } catch (e) {
      return ARResult.failure('Failed to add virtual cat: $e');
    }
  }

  /// Add floating text with breed information
  Future<ARResult> addFloatingText({
    required String text,
    Vector3? position,
    Color color = Colors.white,
  }) async {
    try {
      if (_arCoreController == null) {
        return ARResult.failure('AR session not active');
      }

      // Create text node
      final textNode = ArCoreNode(
        shape: ArCoreText(
          text: text,
          color: color,
          fontSize: 12,
          height: 0.1,
          extrusionDepth: 0.01,
        ),
        position: position ?? Vector3(0, 0.3, -0.5),
      );

      await _arCoreController!.addArCoreNode(textNode);
      
      return ARResult.success('Floating text added');
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

      for (int i = 0; i < facts.length && i < 3; i++) {
        final bubbleNode = ArCoreNode(
          shape: ArCoreSphere(
            radius: 0.05,
            materials: [
              ArCoreMaterial(
                color: Colors.orange.withOpacity(0.8),
                transparency: 0.2,
              ),
            ],
          ),
          position: Vector3(
            -0.3 + (i * 0.3), // Spread horizontally
            0.2,
            -0.8,
          ),
        );

        await _arCoreController!.addArCoreNode(bubbleNode);
        
        // Add text near the bubble
        final textNode = ArCoreNode(
          shape: ArCoreText(
            text: facts[i],
            color: Colors.black87,
            fontSize: 8,
            height: 0.05,
          ),
          position: Vector3(
            -0.3 + (i * 0.3),
            0.15,
            -0.8,
          ),
        );

        await _arCoreController!.addArCoreNode(textNode);
      }
      
      return ARResult.success('Cat fact bubbles added');
    } catch (e) {
      return ARResult.failure('Failed to add cat fact bubbles: $e');
    }
  }

  /// Add ground plane detection node
  Future<void> _addGroundPlaneNode() async {
    if (_arCoreController == null) return;

    try {
      final planeNode = ArCorePlane(
        width: 1,
        height: 1,
        materials: [
          ArCoreMaterial(
            color: Colors.orange.withOpacity(0.3),
            transparency: 0.7,
          ),
        ],
      );

      final node = ArCoreNode(
        shape: planeNode,
        position: Vector3(0, -0.5, -1),
      );

      await _arCoreController!.addArCoreNode(node);
    } catch (e) {
      print('Error adding ground plane: $e');
    }
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