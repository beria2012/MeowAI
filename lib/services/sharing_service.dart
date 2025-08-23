import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../models/cat_breed.dart';
import '../models/recognition_result.dart';
import '../utils/theme.dart';

class SharingService {
  // Singleton pattern
  static final SharingService _instance = SharingService._internal();
  factory SharingService() => _instance;
  SharingService._internal();

  /// Share recognition result with breed information
  Future<ShareResult> shareRecognitionResult({
    required RecognitionResult result,
    String? customMessage,
    bool includeImage = true,
    bool includeAppPromo = true,
  }) async {
    try {
      final message = _buildRecognitionMessage(
        result, 
        customMessage, 
        includeAppPromo,
      );

      if (includeImage && await File(result.imagePath).exists()) {
        final xFile = XFile(result.imagePath);
        await Share.shareXFiles(
          [xFile],
          text: message,
          subject: 'Cat Breed Recognition Result',
        );
      } else {
        await Share.share(
          message,
          subject: 'Cat Breed Recognition Result',
        );
      }

      return ShareResult.success('Recognition result shared successfully');
    } catch (e) {
      return ShareResult.failure('Failed to share recognition result: $e');
    }
  }

  /// Share breed information
  Future<ShareResult> shareBreedInfo({
    required CatBreed breed,
    String? customMessage,
    bool includeAppPromo = true,
  }) async {
    try {
      final message = _buildBreedMessage(breed, customMessage, includeAppPromo);
      
      await Share.share(
        message,
        subject: 'Cat Breed Information: ${breed.name}',
      );

      return ShareResult.success('Breed information shared successfully');
    } catch (e) {
      return ShareResult.failure('Failed to share breed information: $e');
    }
  }

  /// Share app recommendation
  Future<ShareResult> shareApp({String? customMessage}) async {
    try {
      final message = customMessage ?? _buildAppRecommendationMessage();
      
      await Share.share(
        message,
        subject: 'Check out MeowAI - Cat Breed Recognition App',
      );

      return ShareResult.success('App recommendation shared successfully');
    } catch (e) {
      return ShareResult.failure('Failed to share app recommendation: $e');
    }
  }

  /// Create and share custom image with breed info overlay
  Future<ShareResult> shareCustomImage({
    required String imagePath,
    required CatBreed breed,
    required double confidence,
    String? customMessage,
    bool includeWatermark = true,
  }) async {
    try {
      final customImagePath = await _createCustomShareImage(
        imagePath,
        breed,
        confidence,
        includeWatermark,
      );

      if (customImagePath != null) {
        final message = customMessage ?? _buildRecognitionShareMessage(breed, confidence);
        final xFile = XFile(customImagePath);
        
        await Share.shareXFiles(
          [xFile],
          text: message,
          subject: 'Cat Breed Recognition by MeowAI',
        );

        return ShareResult.success('Custom image shared successfully');
      } else {
        return ShareResult.failure('Failed to create custom share image');
      }
    } catch (e) {
      return ShareResult.failure('Failed to share custom image: $e');
    }
  }

  /// Share to specific platform
  Future<ShareResult> shareToSpecificPlatform({
    required String text,
    String? imagePath,
    SharePlatform platform = SharePlatform.system,
  }) async {
    try {
      switch (platform) {
        case SharePlatform.instagram:
          return await _shareToInstagram(text, imagePath);
        case SharePlatform.twitter:
          return await _shareToTwitter(text, imagePath);
        case SharePlatform.facebook:
          return await _shareToFacebook(text, imagePath);
        case SharePlatform.whatsapp:
          return await _shareToWhatsApp(text, imagePath);
        case SharePlatform.system:
        default:
          if (imagePath != null) {
            final xFile = XFile(imagePath);
            await Share.shareXFiles([xFile], text: text);
          } else {
            await Share.share(text);
          }
          return ShareResult.success('Shared successfully');
      }
    } catch (e) {
      return ShareResult.failure('Failed to share to platform: $e');
    }
  }

  /// Copy text to clipboard
  Future<ShareResult> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return ShareResult.success('Copied to clipboard');
    } catch (e) {
      return ShareResult.failure('Failed to copy to clipboard: $e');
    }
  }

  /// Build recognition result message
  String _buildRecognitionMessage(
    RecognitionResult result, 
    String? customMessage, 
    bool includeAppPromo,
  ) {
    final buffer = StringBuffer();
    
    if (customMessage != null && customMessage.isNotEmpty) {
      buffer.writeln(customMessage);
      buffer.writeln();
    }
    
    buffer.writeln('🐱 Cat Breed Recognition Result');
    buffer.writeln();
    buffer.writeln('Breed: ${result.predictedBreed.name}');
    buffer.writeln('Confidence: ${result.confidencePercentage}');
    buffer.writeln('Origin: ${result.predictedBreed.origin}');
    buffer.writeln();
    buffer.writeln(result.predictedBreed.description);
    
    if (includeAppPromo) {
      buffer.writeln();
      buffer.writeln('📱 Recognized using MeowAI - Cat Breed Recognition App');
      buffer.writeln('Download now to identify your cat\'s breed!');
    }
    
    return buffer.toString();
  }

  /// Build breed information message
  String _buildBreedMessage(
    CatBreed breed, 
    String? customMessage, 
    bool includeAppPromo,
  ) {
    final buffer = StringBuffer();
    
    if (customMessage != null && customMessage.isNotEmpty) {
      buffer.writeln(customMessage);
      buffer.writeln();
    }
    
    buffer.writeln('🐱 ${breed.name} Cat Breed Information');
    buffer.writeln();
    buffer.writeln('Origin: ${breed.origin}');
    buffer.writeln('Temperament: ${breed.temperament}');
    buffer.writeln('Life Span: ${breed.lifeSpan}');
    buffer.writeln('Weight: ${breed.weight}');
    buffer.writeln();
    buffer.writeln('Description:');
    buffer.writeln(breed.description);
    
    if (breed.isRare) {
      buffer.writeln();
      buffer.writeln('🌟 This is a rare breed!');
    }
    
    if (breed.isHypoallergenic) {
      buffer.writeln();
      buffer.writeln('✨ Hypoallergenic breed');
    }
    
    if (includeAppPromo) {
      buffer.writeln();
      buffer.writeln('📱 Learn more about cat breeds with MeowAI!');
    }
    
    return buffer.toString();
  }

  /// Build app recommendation message
  String _buildAppRecommendationMessage() {
    return '''
🐱 Discover MeowAI - Cat Breed Recognition App!

Ever wondered what breed your cat is? MeowAI uses advanced AI to identify cat breeds from photos in seconds!

✨ Features:
• Offline AI recognition
• 50+ cat breeds supported
• Detailed breed encyclopedia
• Beautiful cat-themed interface
• Multi-language support

📸 Just take a photo and discover your cat's breed!

Download MeowAI today and unlock the secrets of your feline friend! 🐾

#MeowAI #CatLovers #CatBreeds #AI #PetApp
''';
  }

  /// Build simple recognition share message
  String _buildRecognitionShareMessage(CatBreed breed, double confidence) {
    return 'My cat is a ${breed.name} (${(confidence * 100).toInt()}% confidence)! 🐱 Discovered with MeowAI app 📱 #MeowAI #${breed.name.replaceAll(' ', '')}';
  }

  /// Create custom share image with overlay
  Future<String?> _createCustomShareImage(
    String imagePath,
    CatBreed breed,
    double confidence,
    bool includeWatermark,
  ) async {
    try {
      // This is a simplified version - in a real implementation,
      // you would use image manipulation libraries or custom painting
      // to overlay text and graphics on the image
      
      final file = File(imagePath);
      if (!await file.exists()) return null;
      
      // For now, just copy the original image
      // In a real implementation, you would:
      // 1. Load the image
      // 2. Create a custom painter to overlay breed info
      // 3. Render to a new image file
      // 4. Return the new file path
      
      final directory = await getTemporaryDirectory();
      final newFileName = 'share_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = path.join(directory.path, newFileName);
      
      await file.copy(newPath);
      return newPath;
    } catch (e) {
      print('Error creating custom share image: $e');
      return null;
    }
  }

  /// Share to Instagram
  Future<ShareResult> _shareToInstagram(String text, String? imagePath) async {
    try {
      // Instagram sharing is limited on mobile - usually just opens Instagram
      if (imagePath != null) {
        final xFile = XFile(imagePath);
        await Share.shareXFiles([xFile], text: text);
      } else {
        await Share.share(text);
      }
      return ShareResult.success('Opening Instagram...');
    } catch (e) {
      return ShareResult.failure('Failed to share to Instagram: $e');
    }
  }

  /// Share to Twitter
  Future<ShareResult> _shareToTwitter(String text, String? imagePath) async {
    try {
      // Twitter sharing - limited to text in most cases
      final twitterText = text.length > 280 ? '${text.substring(0, 270)}...' : text;
      
      if (imagePath != null) {
        final xFile = XFile(imagePath);
        await Share.shareXFiles([xFile], text: twitterText);
      } else {
        await Share.share(twitterText);
      }
      return ShareResult.success('Opening Twitter...');
    } catch (e) {
      return ShareResult.failure('Failed to share to Twitter: $e');
    }
  }

  /// Share to Facebook
  Future<ShareResult> _shareToFacebook(String text, String? imagePath) async {
    try {
      if (imagePath != null) {
        final xFile = XFile(imagePath);
        await Share.shareXFiles([xFile], text: text);
      } else {
        await Share.share(text);
      }
      return ShareResult.success('Opening Facebook...');
    } catch (e) {
      return ShareResult.failure('Failed to share to Facebook: $e');
    }
  }

  /// Share to WhatsApp
  Future<ShareResult> _shareToWhatsApp(String text, String? imagePath) async {
    try {
      if (imagePath != null) {
        final xFile = XFile(imagePath);
        await Share.shareXFiles([xFile], text: text);
      } else {
        await Share.share(text);
      }
      return ShareResult.success('Opening WhatsApp...');
    } catch (e) {
      return ShareResult.failure('Failed to share to WhatsApp: $e');
    }
  }

  /// Generate shareable widget screenshot
  Future<String?> captureWidget(GlobalKey key) async {
    try {
      final RenderRepaintBoundary boundary = 
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        
        final directory = await getTemporaryDirectory();
        final fileName = 'widget_share_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(path.join(directory.path, fileName));
        
        await file.writeAsBytes(pngBytes);
        return file.path;
      }
      return null;
    } catch (e) {
      print('Error capturing widget: $e');
      return null;
    }
  }

  /// Get available sharing platforms
  List<SharePlatform> getAvailablePlatforms() {
    // In a real implementation, you would check which apps are installed
    return SharePlatform.values;
  }

  /// Build hashtags for social media
  String buildHashtags(CatBreed breed) {
    final hashtags = <String>[
      '#MeowAI',
      '#CatBreeds',
      '#${breed.name.replaceAll(' ', '')}',
      '#CatLovers',
      '#PetApp',
    ];
    
    if (breed.isRare) {
      hashtags.add('#RareCatBreed');
    }
    
    if (breed.isHypoallergenic) {
      hashtags.add('#HypoallergenicCat');
    }
    
    return hashtags.join(' ');
  }
}

/// Share operation result
class ShareResult {
  final bool isSuccess;
  final String? message;
  final String? error;

  const ShareResult._({
    required this.isSuccess,
    this.message,
    this.error,
  });

  factory ShareResult.success(String message) {
    return ShareResult._(
      isSuccess: true,
      message: message,
    );
  }

  factory ShareResult.failure(String error) {
    return ShareResult._(
      isSuccess: false,
      error: error,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'ShareResult.success(message: $message)';
    } else {
      return 'ShareResult.failure(error: $error)';
    }
  }
}

/// Supported sharing platforms
enum SharePlatform {
  system,
  instagram,
  twitter,
  facebook,
  whatsapp,
}

/// Share platform extension for display names
extension SharePlatformExtension on SharePlatform {
  String get displayName {
    switch (this) {
      case SharePlatform.system:
        return 'More Options';
      case SharePlatform.instagram:
        return 'Instagram';
      case SharePlatform.twitter:
        return 'Twitter';
      case SharePlatform.facebook:
        return 'Facebook';
      case SharePlatform.whatsapp:
        return 'WhatsApp';
    }
  }

  IconData get icon {
    switch (this) {
      case SharePlatform.system:
        return Icons.share;
      case SharePlatform.instagram:
        return Icons.camera_alt;
      case SharePlatform.twitter:
        return Icons.alternate_email;
      case SharePlatform.facebook:
        return Icons.facebook;
      case SharePlatform.whatsapp:
        return Icons.chat;
    }
  }

  Color get color {
    switch (this) {
      case SharePlatform.system:
        return AppTheme.primaryColor;
      case SharePlatform.instagram:
        return const Color(0xFFE4405F);
      case SharePlatform.twitter:
        return const Color(0xFF1DA1F2);
      case SharePlatform.facebook:
        return const Color(0xFF1877F2);
      case SharePlatform.whatsapp:
        return const Color(0xFF25D366);
    }
  }
}