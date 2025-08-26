
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/theme.dart';
import '../services/camera_service.dart';
import '../services/ml_service.dart';
import '../widgets/cat_paw_button.dart';
import 'basic_screens.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  final CameraService _cameraService = CameraService();
  final MLService _mlService = MLService();
  
  bool _isInitialized = false;
  bool _isProcessing = false;
  double _currentZoom = 1.0;
  double _maxZoom = 1.0;
  double _minZoom = 1.0;
  FlashMode _flashMode = FlashMode.auto;
  
  late AnimationController _flashAnimationController;
  late AnimationController _shutterAnimationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _flashAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _shutterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _flashAnimationController.dispose();
    _shutterAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final controller = await _cameraService.initializeCameraController();
      
      if (controller != null && mounted) {
        setState(() {
          _cameraController = controller;
          _isInitialized = true;
        });
        
        // Get zoom levels
        _maxZoom = await _cameraService.getMaxZoomLevel();
        _minZoom = await _cameraService.getMinZoomLevel();
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        _showErrorDialog('Failed to initialize camera: $e');
      }
    }
  }

  Future<void> _takePicture() async {
    if (!_isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Animation feedback
      HapticFeedback.mediumImpact();
      _shutterAnimationController.forward().then((_) {
        _shutterAnimationController.reverse();
      });

      // Take picture
      final imagePath = await _cameraService.takePhoto();
      
      if (imagePath != null) {
        // Process with ML
        await _processImage(imagePath);
      } else {
        throw Exception('Failed to capture image');
      }
    } catch (e) {
      print('Error taking picture: $e');
      _showErrorDialog('Failed to take picture: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final imagePath = await _cameraService.pickImageFromGallery();
      
      if (imagePath != null) {
        await _processImage(imagePath);
      }
    } on PermissionException catch (permissionError) {
      _showPermissionErrorDialog(
        title: 'Photo Access Required',
        message: permissionError.message,
        canOpenSettings: permissionError.canOpenSettings,
      );
    } catch (e) {
      print('Error picking from gallery: $e');
      _showErrorDialog('Failed to pick image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processImage(String imagePath) async {
    try {
      // Navigate to result screen with loading state
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RecognitionResultScreen(
              imagePath: imagePath,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error processing image: $e');
      _showErrorDialog('Failed to process image: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionErrorDialog({
    required String title,
    required String message,
    required bool canOpenSettings,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.accentColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.headline3.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            if (canOpenSettings)
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final cameraService = CameraService();
                  await cameraService.openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Open Settings'),
              )
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickFromGallery(); // Retry
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
          ],
        );
      },
    );
  }

  void _switchCamera() async {
    if (!_isInitialized) return;

    try {
      final newController = await _cameraService.switchCamera();
      if (newController != null && mounted) {
        setState(() {
          _cameraController = newController;
        });
      }
    } catch (e) {
      print('Error switching camera: $e');
    }
  }

  void _toggleFlash() async {
    if (!_isInitialized) return;

    FlashMode newMode;
    switch (_flashMode) {
      case FlashMode.auto:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.off;
        break;
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      default:
        newMode = FlashMode.auto;
    }

    try {
      await _cameraService.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
      });
      
      _flashAnimationController.forward().then((_) {
        _flashAnimationController.reverse();
      });
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  void _onZoomChanged(double zoom) async {
    if (!_isInitialized) return;

    try {
      await _cameraService.setZoomLevel(zoom);
      setState(() {
        _currentZoom = zoom;
      });
    } catch (e) {
      print('Error setting zoom: $e');
    }
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
        return Icons.flash_off;
      default:
        return Icons.flash_auto;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _cameraController != null)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: LoadingPawAnimation(
                message: 'Initializing camera...',
              ),
            ),

          // Flash overlay
          AnimatedBuilder(
            animation: _flashAnimationController,
            builder: (context, child) {
              return _flashAnimationController.value > 0
                  ? Container(
                      color: Colors.white.withOpacity(_flashAnimationController.value * 0.8),
                    )
                  : const SizedBox.shrink();
            },
          ),

          // Shutter overlay
          AnimatedBuilder(
            animation: _shutterAnimationController,
            builder: (context, child) {
              return _shutterAnimationController.value > 0
                  ? Container(
                      color: Colors.black.withOpacity(_shutterAnimationController.value * 0.3),
                    )
                  : const SizedBox.shrink();
            },
          ),

          // Top controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  _ControlButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  
                  // Flash toggle
                  _ControlButton(
                    icon: _flashIcon,
                    onPressed: _toggleFlash,
                  ),
                  
                  // Switch camera
                  if (_cameraService.hasFrontCamera && _cameraService.hasBackCamera)
                    _ControlButton(
                      icon: Icons.flip_camera_ios,
                      onPressed: _switchCamera,
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zoom slider
                    if (_isInitialized && _maxZoom > _minZoom) ...[
                      Container(
                        width: 200,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_minZoom.toStringAsFixed(1)}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: _currentZoom,
                                min: _minZoom,
                                max: _maxZoom,
                                onChanged: _onZoomChanged,
                                activeColor: AppTheme.primaryColor,
                                inactiveColor: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            Text(
                              '${_maxZoom.toStringAsFixed(1)}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Camera controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery button
                        _ActionButton(
                          icon: Icons.photo_library,
                          onPressed: _pickFromGallery,
                        ),

                        // Capture button
                        GestureDetector(
                          onTap: _takePicture,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: AppTheme.primaryColor,
                                width: 4,
                              ),
                            ),
                            child: _isProcessing
                                ? const LoadingPawAnimation(size: 30)
                                : const Icon(
                                    Icons.camera_alt,
                                    color: AppTheme.primaryColor,
                                    size: 32,
                                  ),
                          ),
                        )
                            .animate(target: _isProcessing ? 1 : 0)
                            .scale(begin: const Offset(1.0, 1.0), end: const Offset(0.9, 0.9)),

                        // Info button
                        _ActionButton(
                          icon: Icons.info_outline,
                          onPressed: () => _showInfoDialog(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Tips'),
        content: const Text(
          '• Ensure good lighting\n'
          '• Keep the cat in focus\n'
          '• Try to capture the whole face\n'
          '• Avoid blurry images\n'
          '• Multiple angles may help',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}