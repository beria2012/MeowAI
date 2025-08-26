import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:path/path.dart' as path;

/// Custom exception for permission-related errors
class PermissionException implements Exception {
  final String message;
  final ph.PermissionStatus status;
  
  const PermissionException(this.message, this.status);
  
  @override
  String toString() => 'PermissionException: $message';
  
  bool get isPermanentlyDenied => status == ph.PermissionStatus.permanentlyDenied;
  bool get canOpenSettings => isPermanentlyDenied || status == ph.PermissionStatus.restricted;
}

class CameraService {
  final ImagePicker _picker = ImagePicker();
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  
  // Singleton pattern
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  /// Initialize camera service (without requesting permissions)
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Get available cameras without requesting permissions yet
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      _isInitialized = true;
      print('Camera service initialized with ${_cameras!.length} cameras (permissions will be requested when needed)');
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
      // Request camera permission when actually needed
      final cameraPermission = await ph.Permission.camera.request();
      if (!cameraPermission.isGranted) {
        throw Exception('Camera permission not granted');
      }

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

  /// Pick image from gallery with comprehensive permission handling
  Future<String?> pickImageFromGallery() async {
    try {
      print('🖼️ Gallery: Initiating gallery picker...');
      
      // For Android, we need to handle different permission types based on API level
      ph.Permission targetPermission;
      if (Platform.isAndroid) {
        // Android 13+ (API 33+) uses granular media permissions
        targetPermission = ph.Permission.photos;
      } else {
        // iOS uses photos permission
        targetPermission = ph.Permission.photos;
      }
      
      // Check current permission status
      final currentStatus = await targetPermission.status;
      print('🔐 Gallery: Current permission status: $currentStatus');
      
      if (currentStatus.isGranted || currentStatus.isLimited) {
        // Permission granted or limited access (iOS) - proceed directly
        print('✅ Gallery: Permission already granted, proceeding...');
        return await _pickImageFromGalleryInternal();
      }
      
      if (currentStatus.isPermanentlyDenied) {
        // User has permanently denied permission
        print('❌ Gallery: Permission permanently denied');
        final message = Platform.isAndroid 
            ? 'Photo access has been permanently denied. '
              'Please enable it in Settings > Apps > MeowAI > Permissions > Photos'
            : 'Photo library access has been permanently denied. '
              'Please enable it in Settings > Privacy & Security > Photos > MeowAI';
        throw PermissionException(message, ph.PermissionStatus.permanentlyDenied);
      }
      
      if (currentStatus.isRestricted) {
        // Permission is restricted (parental controls, etc.)
        print('⚠️ Gallery: Permission is restricted');
        throw PermissionException(
          'Photo access is restricted on this device. Please check parental controls or device restrictions.',
          ph.PermissionStatus.restricted,
        );
      }
      
      // Request permission
      print('📱 Gallery: Requesting permission...');
      final permissionResult = await targetPermission.request();
      print('🔐 Gallery: Permission request result: $permissionResult');
      
      switch (permissionResult) {
        case ph.PermissionStatus.granted:
        case ph.PermissionStatus.limited: // iOS limited access is acceptable
          print('✅ Gallery: Permission granted, proceeding...');
          return await _pickImageFromGalleryInternal();
          
        case ph.PermissionStatus.denied:
          print('❌ Gallery: Permission denied');
          throw PermissionException(
            'Photo library access is required to select images from your gallery. '
            'Please allow access when prompted.',
            ph.PermissionStatus.denied,
          );
          
        case ph.PermissionStatus.permanentlyDenied:
          print('❌ Gallery: Permission permanently denied after request');
          final message = Platform.isAndroid 
              ? 'Photo access has been permanently denied. '
                'Please enable it in Settings > Apps > MeowAI > Permissions > Photos'
              : 'Photo library access has been permanently denied. '
                'Please enable it in Settings > Privacy & Security > Photos > MeowAI';
          throw PermissionException(message, ph.PermissionStatus.permanentlyDenied);
          
        case ph.PermissionStatus.restricted:
          print('⚠️ Gallery: Permission is restricted after request');
          throw PermissionException(
            'Photo library access is restricted on this device. Please check device restrictions.',
            ph.PermissionStatus.restricted,
          );
          
        case ph.PermissionStatus.provisional:
          // iOS provisional permission, should work
          print('📱 Gallery: Provisional permission granted (iOS)');
          return await _pickImageFromGalleryInternal();
      }
    } on PermissionException {
      // Re-throw permission exceptions as-is
      rethrow;
    } catch (e) {
      print('❌ Gallery: Unexpected error accessing gallery: $e');
      // Wrap other exceptions in a user-friendly message
      throw Exception('Failed to access photo gallery: ${e.toString()}');
    }
  }
  
  /// Internal method to pick image from gallery (assumes permission is granted)
  Future<String?> _pickImageFromGalleryInternal() async {
    try {
      print('🖼️ Gallery: Opening image picker...');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image == null) {
        print('📷 Gallery: User cancelled selection');
        return null;
      }
      
      print('🖼️ Gallery: Image selected: ${image.path}');
      
      // Verify file exists and is readable
      final file = File(image.path);
      if (!await file.exists()) {
        print('❌ Gallery: Selected file does not exist: ${image.path}');
        throw Exception('Selected image file is not accessible. Please try again.');
      }
      
      // Check file size (basic validation)
      final fileSize = await file.length();
      print('📊 Gallery: Image size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      
      if (fileSize == 0) {
        print('❌ Gallery: Selected file is empty');
        throw Exception('Selected image file is empty. Please choose a different image.');
      }
      
      // Save to app directory
      final String savedPath = await _saveImageToAppDirectory(image.path);
      print('✅ Gallery: Image successfully saved: $savedPath');
      
      return savedPath;
    } on Exception catch (e) {
      print('❌ Gallery: Exception during image selection: $e');
      rethrow; // Re-throw exceptions as-is for UI handling
    } catch (e) {
      print('❌ Gallery: Unexpected error during image selection: $e');
      throw Exception('Failed to select image from gallery: ${e.toString()}');
    }
  }

  /// Pick image using image picker with source selection and on-demand permissions
  Future<String?> pickImage({required ImageSource source}) async {
    try {
      // Request appropriate permissions when actually needed
      ph.PermissionStatus permission;
      String permissionType;
      
      if (source == ImageSource.camera) {
        permission = await ph.Permission.camera.request();
        permissionType = 'camera';
      } else {
        permission = await ph.Permission.photos.request();
        permissionType = 'photo library';
      }
      
      if (!permission.isGranted) {
        throw Exception('$permissionType access is required to ${source == ImageSource.camera ? "take photos" : "select images"}');
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
      print('Error picking image from ${source.name}: $e');
      rethrow; // Re-throw to allow UI to handle the error
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
    final cameraStatus = await ph.Permission.camera.status;
    final storageStatus = await ph.Permission.photos.status;
    
    return {
      'camera': cameraStatus.isGranted,
      'storage': storageStatus.isGranted,
    };
  }

  /// Request camera permissions
  Future<bool> requestCameraPermission() async {
    final status = await ph.Permission.camera.request();
    return status.isGranted;
  }

  /// Request storage permissions
  Future<bool> requestStoragePermission() async {
    final status = await ph.Permission.photos.request();
    return status.isGranted;
  }

  /// Open app settings for permission management
  Future<bool> openAppSettings() async {
    try {
      return await ph.openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
      return false;
    }
  }

  /// Check if we can request photo permission
  Future<bool> canRequestPhotoPermission() async {
    final status = await ph.Permission.photos.status;
    return !status.isPermanentlyDenied && !status.isRestricted;
  }
  
  /// Get detailed photo permission status with platform-specific information
  Future<Map<String, dynamic>> getPhotoPermissionStatus() async {
    final status = await ph.Permission.photos.status;
    
    return {
      'status': status,
      'isGranted': status.isGranted,
      'isLimited': status.isLimited,
      'isDenied': status.isDenied,
      'isPermanentlyDenied': status.isPermanentlyDenied,
      'isRestricted': status.isRestricted,
      'canRequest': !status.isPermanentlyDenied && !status.isRestricted,
      'shouldShowRationale': Platform.isAndroid ? await ph.Permission.photos.shouldShowRequestRationale : false,
      'platform': Platform.operatingSystem,
    };
  }
  
  /// Request gallery permission with comprehensive error handling
  Future<ph.PermissionStatus> requestGalleryPermissionWithFeedback() async {
    try {
      print('🔐 Requesting gallery permission...');
      
      // Check if we should show rationale (Android)
      if (Platform.isAndroid) {
        final shouldShow = await ph.Permission.photos.shouldShowRequestRationale;
        if (shouldShow) {
          print('📱 Android: Should show permission rationale to user');
        }
      }
      
      // Request the permission
      final result = await ph.Permission.photos.request();
      print('🔐 Gallery permission request result: $result');
      
      return result;
    } catch (e) {
      print('❌ Error requesting gallery permission: $e');
      return ph.PermissionStatus.denied;
    }
  }
  
  /// Check if gallery access is currently available (permission granted)
  Future<bool> isGalleryAccessAvailable() async {
    final status = await ph.Permission.photos.status;
    return status.isGranted || status.isLimited;
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