import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class CameraService {
  final ImagePicker _picker = ImagePicker();
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  
  // Singleton pattern
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  /// Initialize camera service and request permissions
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Request camera permission
      final cameraPermission = await Permission.camera.request();
      if (!cameraPermission.isGranted) {
        throw Exception('Camera permission not granted');
      }

      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      _isInitialized = true;
      print('Camera service initialized with ${_cameras!.length} cameras');
      return true;
    } catch (e) {
      print('Error initializing camera service: $e');
      return false;
    }
  }

  /// Initialize camera controller for a specific camera
  Future<CameraController?> initializeCameraController({
    int cameraIndex = 0,
    ResolutionPreset resolution = ResolutionPreset.high,
  }) async {
    if (!_isInitialized || _cameras == null || _cameras!.isEmpty) {
      await initialize();
    }

    if (_cameras == null || cameraIndex >= _cameras!.length) {
      return null;
    }

    try {
      // Dispose existing controller if any
      await _cameraController?.dispose();

      // Create new controller
      _cameraController = CameraController(
        _cameras![cameraIndex],
        resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Initialize the controller
      await _cameraController!.initialize();
      
      return _cameraController;
    } catch (e) {
      print('Error initializing camera controller: $e');
      return null;
    }
  }

  /// Take a photo using camera
  Future<String?> takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    try {
      // Take picture
      final XFile image = await _cameraController!.takePicture();
      
      // Save to app directory
      final String savedPath = await _saveImageToAppDirectory(image.path);
      
      return savedPath;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  /// Pick image from gallery
  Future<String?> pickImageFromGallery() async {
    try {
      // Request storage permission
      final storagePermission = await Permission.photos.request();
      if (!storagePermission.isGranted) {
        throw Exception('Storage permission not granted');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image == null) return null;
      
      // Save to app directory
      final String savedPath = await _saveImageToAppDirectory(image.path);
      
      return savedPath;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick image using image picker with source selection
  Future<String?> pickImage({required ImageSource source}) async {
    try {
      // Request appropriate permissions
      PermissionStatus permission;
      if (source == ImageSource.camera) {
        permission = await Permission.camera.request();
      } else {
        permission = await Permission.photos.request();
      }
      
      if (!permission.isGranted) {
        throw Exception('Permission not granted for ${source.name}');
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (image == null) return null;
      
      // Save to app directory
      final String savedPath = await _saveImageToAppDirectory(image.path);
      
      return savedPath;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Save image to app's document directory
  Future<String> _saveImageToAppDirectory(String originalPath) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String fileName = 'cat_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String newPath = path.join(appDir.path, 'images', fileName);
    
    // Create images directory if it doesn't exist
    final Directory imagesDir = Directory(path.dirname(newPath));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    // Copy file to new location
    final File originalFile = File(originalPath);
    await originalFile.copy(newPath);
    
    return newPath;
  }

  /// Get available cameras
  List<CameraDescription>? getAvailableCameras() {
    return _cameras;
  }

  /// Get current camera controller
  CameraController? getCameraController() {
    return _cameraController;
  }

  /// Check if camera is available
  bool get hasCamera => _cameras != null && _cameras!.isNotEmpty;

  /// Check if front camera is available
  bool get hasFrontCamera => _cameras?.any(
    (camera) => camera.lensDirection == CameraLensDirection.front,
  ) ?? false;

  /// Check if back camera is available
  bool get hasBackCamera => _cameras?.any(
    (camera) => camera.lensDirection == CameraLensDirection.back,
  ) ?? false;

  /// Switch between front and back camera
  Future<CameraController?> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return _cameraController;

    try {
      final currentLensDirection = _cameraController?.description.lensDirection;
      final newCameraIndex = _cameras!.indexWhere(
        (camera) => camera.lensDirection != currentLensDirection,
      );

      if (newCameraIndex != -1) {
        return await initializeCameraController(cameraIndex: newCameraIndex);
      }
    } catch (e) {
      print('Error switching camera: $e');
    }

    return _cameraController;
  }

  /// Set flash mode
  Future<void> setFlashMode(FlashMode mode) async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      await _cameraController!.setFlashMode(mode);
    }
  }

  /// Set zoom level
  Future<void> setZoomLevel(double zoom) async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      final maxZoom = await _cameraController!.getMaxZoomLevel();
      final minZoom = await _cameraController!.getMinZoomLevel();
      final clampedZoom = zoom.clamp(minZoom, maxZoom);
      await _cameraController!.setZoomLevel(clampedZoom);
    }
  }

  /// Get max zoom level
  Future<double> getMaxZoomLevel() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      return await _cameraController!.getMaxZoomLevel();
    }
    return 1.0;
  }

  /// Get min zoom level
  Future<double> getMinZoomLevel() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      return await _cameraController!.getMinZoomLevel();
    }
    return 1.0;
  }

  /// Check camera permissions
  Future<Map<String, bool>> checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final storageStatus = await Permission.photos.status;
    
    return {
      'camera': cameraStatus.isGranted,
      'storage': storageStatus.isGranted,
    };
  }

  /// Request camera permissions
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request storage permissions
  Future<bool> requestStoragePermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  /// Clean up old images (older than specified days)
  Future<void> cleanupOldImages({int olderThanDays = 30}) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory(path.join(appDir.path, 'images'));
      
      if (!await imagesDir.exists()) return;
      
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
      final files = await imagesDir.list().toList();
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            print('Deleted old image: ${file.path}');
          }
        }
      }
    } catch (e) {
      print('Error cleaning up old images: $e');
    }
  }

  /// Get storage usage information
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory(path.join(appDir.path, 'images'));
      
      if (!await imagesDir.exists()) {
        return {'total_files': 0, 'total_size_mb': 0.0};
      }
      
      int totalFiles = 0;
      int totalSizeBytes = 0;
      
      final files = await imagesDir.list().toList();
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalFiles++;
          totalSizeBytes += stat.size;
        }
      }
      
      return {
        'total_files': totalFiles,
        'total_size_mb': totalSizeBytes / (1024 * 1024),
        'directory_path': imagesDir.path,
      };
    } catch (e) {
      print('Error getting storage info: $e');
      return {'total_files': 0, 'total_size_mb': 0.0};
    }
  }

  /// Dispose camera controller
  Future<void> dispose() async {
    await _cameraController?.dispose();
    _cameraController = null;
  }
}