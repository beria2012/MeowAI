import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/cat_breed.dart';
import '../models/recognition_result.dart';

class AccessibilityService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isTtsInitialized = false;
  bool _isTtsEnabled = true;
  bool _isHighContrastEnabled = false;
  bool _isLargeTextEnabled = false;
  double _textScaleFactor = 1.0;
  
  // Singleton pattern
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  /// Initialize accessibility service
  Future<void> initialize() async {
    await _initializeTts();
    _loadAccessibilityPreferences();
  }

  /// Initialize Text-to-Speech
  Future<void> _initializeTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(0.8);
      await _flutterTts.setPitch(1.0);
      
      _isTtsInitialized = true;
      print('Text-to-Speech initialized successfully');
    } catch (e) {
      print('Error initializing TTS: $e');
      _isTtsInitialized = false;
    }
  }

  /// Load accessibility preferences
  void _loadAccessibilityPreferences() {
    // In a real implementation, load from shared preferences or database
    _textScaleFactor = 1.0;
    _isHighContrastEnabled = false;
    _isLargeTextEnabled = false;
    _isTtsEnabled = true;
  }

  /// Speak text aloud
  Future<void> speak(String text, {bool interrupt = false}) async {
    if (!_isTtsInitialized || !_isTtsEnabled || text.isEmpty) return;
    
    try {
      if (interrupt) {
        await _flutterTts.stop();
      }
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error speaking text: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (_isTtsInitialized) {
      await _flutterTts.stop();
    }
  }

  /// Speak recognition result
  Future<void> speakRecognitionResult(RecognitionResult result) async {
    final text = '''
    Recognition complete. 
    Detected breed: ${result.predictedBreed.name}. 
    Confidence: ${result.confidencePercentage}. 
    Origin: ${result.predictedBreed.origin}. 
    ${result.predictedBreed.description}
    ''';
    await speak(text);
  }

  /// Speak breed information
  Future<void> speakBreedInfo(CatBreed breed) async {
    final text = '''
    ${breed.name}. 
    Origin: ${breed.origin}. 
    Temperament: ${breed.temperament}. 
    Life span: ${breed.lifeSpan}. 
    Weight: ${breed.weight}. 
    ${breed.description}
    ${breed.isRare ? 'This is a rare breed.' : ''}
    ${breed.isHypoallergenic ? 'This breed is hypoallergenic.' : ''}
    ''';
    await speak(text);
  }

  /// Speak navigation instructions
  Future<void> speakNavigation(String instruction) async {
    await speak(instruction, interrupt: true);
  }

  /// Speak button or action description
  Future<void> speakAction(String action) async {
    await speak(action);
  }

  /// Enable/disable TTS
  void setTtsEnabled(bool enabled) {
    _isTtsEnabled = enabled;
    if (!enabled) {
      stopSpeaking();
    }
  }

  /// Check if TTS is enabled
  bool get isTtsEnabled => _isTtsEnabled && _isTtsInitialized;

  /// Enable/disable high contrast mode
  void setHighContrastEnabled(bool enabled) {
    _isHighContrastEnabled = enabled;
    // Notify UI to update colors
  }

  /// Check if high contrast is enabled
  bool get isHighContrastEnabled => _isHighContrastEnabled;

  /// Set text scale factor
  void setTextScaleFactor(double factor) {
    _textScaleFactor = factor.clamp(0.8, 2.0);
    _isLargeTextEnabled = _textScaleFactor > 1.2;
  }

  /// Get current text scale factor
  double get textScaleFactor => _textScaleFactor;

  /// Check if large text is enabled
  bool get isLargeTextEnabled => _isLargeTextEnabled;

  /// Provide haptic feedback
  void provideFeedback(HapticFeedbackType type) {
    switch (type) {
      case HapticFeedbackType.success:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.warning:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.error:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }

  /// Get accessible button widget
  Widget buildAccessibleButton({
    required Widget child,
    required VoidCallback onPressed,
    required String semanticsLabel,
    String? semanticsHint,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      label: semanticsLabel,
      hint: semanticsHint,
      button: true,
      enabled: true,
      excludeSemantics: excludeSemantics,
      child: GestureDetector(
        onTap: () {
          provideFeedback(HapticFeedbackType.selection);
          onPressed();
        },
        child: child,
      ),
    );
  }

  /// Get accessible text widget
  Widget buildAccessibleText({
    required String text,
    TextStyle? style,
    String? semanticsLabel,
    bool readOnly = false,
  }) {
    return Semantics(
      label: semanticsLabel ?? text,
      readOnly: readOnly,
      child: Text(
        text,
        style: style?.copyWith(fontSize: (style?.fontSize ?? 14) * _textScaleFactor),
      ),
    );
  }

  /// Get accessible image widget
  Widget buildAccessibleImage({
    required Widget image,
    required String semanticsLabel,
    String? semanticsHint,
  }) {
    return Semantics(
      label: semanticsLabel,
      hint: semanticsHint,
      image: true,
      child: image,
    );
  }

  /// Get accessible progress indicator
  Widget buildAccessibleProgress({
    required double value,
    String? semanticsLabel,
    String? semanticsValue,
  }) {
    return Semantics(
      label: semanticsLabel,
      value: semanticsValue ?? '${(value * 100).round()}%',
      child: LinearProgressIndicator(value: value),
    );
  }

  /// Build accessible card with proper semantics
  Widget buildAccessibleCard({
    required Widget child,
    required VoidCallback? onTap,
    required String semanticsLabel,
    String? semanticsHint,
  }) {
    if (onTap != null) {
      return Semantics(
        label: semanticsLabel,
        hint: semanticsHint ?? 'Double tap to open',
        button: true,
        child: GestureDetector(
          onTap: () {
            provideFeedback(HapticFeedbackType.selection);
            onTap();
          },
          child: child,
        ),
      );
    } else {
      return Semantics(
        label: semanticsLabel,
        readOnly: true,
        child: child,
      );
    }
  }

  /// Get high contrast colors
  AccessibleColors getAccessibleColors(BuildContext context) {
    if (_isHighContrastEnabled) {
      return AccessibleColors.highContrast();
    } else {
      final brightness = Theme.of(context).brightness;
      return brightness == Brightness.dark 
          ? AccessibleColors.dark()
          : AccessibleColors.light();
    }
  }

  /// Announce live region update
  void announceUpdate(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Focus on specific widget
  void focusWidget(FocusNode focusNode) {
    focusNode.requestFocus();
  }

  /// Get accessibility settings
  AccessibilitySettings getSettings() {
    return AccessibilitySettings(
      isTtsEnabled: _isTtsEnabled,
      isHighContrastEnabled: _isHighContrastEnabled,
      isLargeTextEnabled: _isLargeTextEnabled,
      textScaleFactor: _textScaleFactor,
    );
  }

  /// Update accessibility settings
  void updateSettings(AccessibilitySettings settings) {
    _isTtsEnabled = settings.isTtsEnabled;
    _isHighContrastEnabled = settings.isHighContrastEnabled;
    _isLargeTextEnabled = settings.isLargeTextEnabled;
    _textScaleFactor = settings.textScaleFactor;
    
    // Save to preferences
    // In a real implementation, save to shared preferences or database
  }

  /// Dispose resources
  void dispose() {
    _flutterTts.stop();
  }
}

/// Accessibility settings model
class AccessibilitySettings {
  final bool isTtsEnabled;
  final bool isHighContrastEnabled;
  final bool isLargeTextEnabled;
  final double textScaleFactor;

  const AccessibilitySettings({
    required this.isTtsEnabled,
    required this.isHighContrastEnabled,
    required this.isLargeTextEnabled,
    required this.textScaleFactor,
  });

  AccessibilitySettings copyWith({
    bool? isTtsEnabled,
    bool? isHighContrastEnabled,
    bool? isLargeTextEnabled,
    double? textScaleFactor,
  }) {
    return AccessibilitySettings(
      isTtsEnabled: isTtsEnabled ?? this.isTtsEnabled,
      isHighContrastEnabled: isHighContrastEnabled ?? this.isHighContrastEnabled,
      isLargeTextEnabled: isLargeTextEnabled ?? this.isLargeTextEnabled,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
    );
  }
}

/// Accessible color scheme
class AccessibleColors {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color text;
  final Color textSecondary;
  final Color border;
  final Color error;
  final Color success;

  const AccessibleColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.text,
    required this.textSecondary,
    required this.border,
    required this.error,
    required this.success,
  });

  factory AccessibleColors.light() {
    return const AccessibleColors(
      primary: Color(0xFFFF8A65),
      secondary: Color(0xFF81C784),
      background: Color(0xFFFFF8E1),
      surface: Color(0xFFFFFFFF),
      text: Color(0xFF424242),
      textSecondary: Color(0xFF757575),
      border: Color(0xFFE0E0E0),
      error: Color(0xFFE57373),
      success: Color(0xFF4CAF50),
    );
  }

  factory AccessibleColors.dark() {
    return const AccessibleColors(
      primary: Color(0xFFFF8A65),
      secondary: Color(0xFF81C784),
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      text: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFBDBDBD),
      border: Color(0xFF424242),
      error: Color(0xFFEF5350),
      success: Color(0xFF66BB6A),
    );
  }

  factory AccessibleColors.highContrast() {
    return const AccessibleColors(
      primary: Color(0xFF000000),
      secondary: Color(0xFF000000),
      background: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      text: Color(0xFF000000),
      textSecondary: Color(0xFF000000),
      border: Color(0xFF000000),
      error: Color(0xFFFF0000),
      success: Color(0xFF008000),
    );
  }
}

/// Haptic feedback types
enum HapticFeedbackType {
  success,
  warning,
  error,
  selection,
}

/// Accessibility helper widget
class AccessibilityHelper extends StatelessWidget {
  final Widget child;
  final String? semanticsLabel;
  final String? semanticsHint;
  final VoidCallback? onTap;

  const AccessibilityHelper({
    super.key,
    required this.child,
    this.semanticsLabel,
    this.semanticsHint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    if (onTap != null) {
      return accessibilityService.buildAccessibleButton(
        onPressed: onTap!,
        semanticsLabel: semanticsLabel ?? '',
        semanticsHint: semanticsHint,
        child: child,
      );
    } else {
      return Semantics(
        label: semanticsLabel,
        hint: semanticsHint,
        child: child,
      );
    }
  }
}