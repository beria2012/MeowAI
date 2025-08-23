import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
// ARCore import temporarily disabled for iOS compatibility
// import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';

import '../services/ar_service.dart';
import '../models/cat_breed.dart';
import '../models/recognition_result.dart';
import '../utils/theme.dart';
import '../widgets/cat_paw_button.dart';

class ARScreen extends StatefulWidget {
  final CatBreed? breed;
  final RecognitionResult? recognitionResult;

  const ARScreen({
    super.key,
    this.breed,
    this.recognitionResult,
  });

  @override
  State<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> with TickerProviderStateMixin {
  final ARService _arService = ARService();
  
  dynamic _arController; // ArCoreController? when arcore_flutter_plugin is available
  bool _isARSupported = false;
  bool _isARActive = false;
  bool _isLoading = true;
  String _statusMessage = 'Checking AR support...';
  
  late AnimationController _pulseController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _initializeAR();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _arService.dispose();
    super.dispose();
  }

  Future<void> _initializeAR() async {
    try {
      setState(() {
        _statusMessage = 'Checking AR support...';
      });

      _isARSupported = await _arService.isARSupported();
      
      if (!_isARSupported) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'AR is not supported on this device';
        });
        return;
      }

      setState(() {
        _statusMessage = 'Initializing AR...';
      });

      final result = await _arService.initialize();
      
      if (!result.isSuccess) {
        setState(() {
          _isLoading = false;
          _statusMessage = result.error ?? 'Failed to initialize AR';
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _statusMessage = 'AR ready! Tap to start AR session';
      });
      
      _slideController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _startARSession() async {
    if (!_isARSupported || _arController == null) return;

    try {
      setState(() {
        _statusMessage = 'Starting AR session...';
      });

      final result = await _arService.startARSession(_arController!);
      
      if (result.isSuccess) {
        setState(() {
          _isARActive = true;
          _statusMessage = 'AR session active';
        });

        // Add breed information if available
        if (widget.breed != null) {
          await _addBreedContent();
        }
      } else {
        setState(() {
          _statusMessage = result.error ?? 'Failed to start AR session';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error starting AR: $e';
      });
    }
  }

  Future<void> _addBreedContent() async {
    if (widget.breed == null || !_isARActive) return;

    final breed = widget.breed!;
    
    try {
      // Add breed info overlay
      await _arService.addBreedInfoOverlay(
        breed: breed,
        confidence: widget.recognitionResult?.confidence ?? 0.0,
      );

      // Add floating text with breed name
      await _arService.addFloatingText(
        text: breed.name,
        position: null, // Vector3(0, 0.4, -0.7) when ARCore is available
        color: AppTheme.primaryColor,
      );

      // Add cat facts if available
      if (breed.characteristics.isNotEmpty) {
        await _arService.addCatFactBubbles(
          facts: breed.characteristics,
          breed: breed,
        );
      }

      // Try to add virtual cat (will fail gracefully if model doesn't exist)
      await _arService.addVirtualCat(breed: breed);
      
    } catch (e) {
      print('Error adding breed content: $e');
    }
  }

  void _onArCoreViewCreated(dynamic controller) {
    _arController = controller;
    
    if (_isARSupported) {
      _startARSession();
    }
  }

  void _toggleAR() {
    if (_isARActive) {
      _stopARSession();
    } else if (_isARSupported) {
      _startARSession();
    }
  }

  void _stopARSession() {
    _arService.stopARSession();
    setState(() {
      _isARActive = false;
      _statusMessage = 'AR session stopped';
    });
  }

  void _clearARContent() {
    if (_isARActive) {
      _arService.clearAllNodes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'AR View',
          style: AppTextStyles.headline2.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isARActive)
            IconButton(
              onPressed: _clearARContent,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear AR content',
            ),
        ],
      ),
      body: Stack(
        children: [
          // AR View or Placeholder
          if (_isARSupported && !_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: const Center(
                  child: Text(
                    'AR View\n(ARCore disabled for compatibility)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            )
          else
            _buildPlaceholderView(),

          // Status overlay
          _buildStatusOverlay(),

          // Control buttons
          _buildControlButtons(),

          // Breed information panel
          if (widget.breed != null)
            _buildBreedInfoPanel(),
        ],
      ),
    );
  }

  Widget _buildPlaceholderView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + (_pulseController.value * 0.4),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.view_in_ar,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              _isLoading ? 'Loading...' : 'AR Not Available',
              style: AppTextStyles.headline2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOverlay() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _slideController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -50 * (1 - _slideController.value)),
            child: Opacity(
              opacity: _slideController.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isARActive ? AppTheme.successColor : AppTheme.primaryColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isARActive ? AppTheme.successColor : AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_isARSupported)
            _buildControlButton(
              icon: _isARActive ? Icons.stop : Icons.play_arrow,
              label: _isARActive ? 'Stop AR' : 'Start AR',
              onPressed: _toggleAR,
              color: _isARActive ? AppTheme.errorColor : AppTheme.successColor,
            ),
          
          if (widget.breed != null)
            _buildControlButton(
              icon: Icons.info_outline,
              label: 'Breed Info',
              onPressed: () => _showBreedInfoDialog(),
              color: AppTheme.secondaryColor,
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildBreedInfoPanel() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.pets,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.breed!.name,
                    style: AppTextStyles.headline3.copyWith(color: Colors.white),
                  ),
                ),
                if (widget.recognitionResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.recognitionResult!.confidencePercentage,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.breed!.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1.0, end: 0.0, duration: 600.ms);
  }

  void _showBreedInfoDialog() {
    if (widget.breed == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          widget.breed!.name,
          style: AppTextStyles.headline2,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Origin: ${widget.breed!.origin}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Temperament: ${widget.breed!.temperament}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              widget.breed!.description,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}