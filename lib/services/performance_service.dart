import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PerformanceService {
  static const String _channelName = 'com.meowai.performance';
  static const MethodChannel _channel = MethodChannel(_channelName);
  
  // Singleton pattern
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<String, DateTime> _traceStartTimes = {};
  final Map<String, int> _counters = {};
  late DeviceInfoPlugin _deviceInfoPlugin;
  late PackageInfo _packageInfo;
  bool _isInitialized = false;

  /// Initialize performance monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _deviceInfoPlugin = DeviceInfoPlugin();
      _packageInfo = await PackageInfo.fromPlatform();
      
      // Log app start performance
      await logAppStart();
      
      _isInitialized = true;
      print('Performance monitoring initialized');
    } catch (e) {
      print('Error initializing performance monitoring: $e');
    }
  }

  /// Start a performance trace
  Future<void> startTrace(String traceName) async {
    _traceStartTimes[traceName] = DateTime.now();
    
    if (kDebugMode) {
      print('Performance trace started: $traceName');
    }
  }

  /// Stop a performance trace and log the duration
  Future<Duration?> stopTrace(String traceName) async {
    final startTime = _traceStartTimes.remove(traceName);
    if (startTime == null) {
      print('Warning: No start time found for trace: $traceName');
      return null;
    }
    
    final duration = DateTime.now().difference(startTime);
    
    // Log the performance metric
    await _logPerformanceMetric(traceName, duration);
    
    if (kDebugMode) {
      print('Performance trace completed: $traceName - ${duration.inMilliseconds}ms');
    }
    
    return duration;
  }

  /// Increment a performance counter
  void incrementCounter(String counterName, [int value = 1]) {
    _counters[counterName] = (_counters[counterName] ?? 0) + value;
    
    if (kDebugMode) {
      print('Counter incremented: $counterName = ${_counters[counterName]}');
    }
  }

  /// Get current counter value
  int getCounter(String counterName) {
    return _counters[counterName] ?? 0;
  }

  /// Log app startup performance
  Future<void> logAppStart() async {
    try {
      final startTime = DateTime.now();
      
      // Measure various startup metrics
      final metrics = {
        'app_start_time': startTime.millisecondsSinceEpoch,
        'platform': Platform.operatingSystem,
        'app_version': _packageInfo.version,
        'build_number': _packageInfo.buildNumber,
      };
      
      // Add device information
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        metrics.addAll({
          'device_model': androidInfo.model,
          'android_version': androidInfo.version.release,
          'api_level': androidInfo.version.sdkInt.toString(),
        });
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        metrics.addAll({
          'device_model': iosInfo.model,
          'ios_version': iosInfo.systemVersion,
          'device_name': iosInfo.name,
        });
      }
      
      if (kDebugMode) {
        print('App start metrics: $metrics');
      }
    } catch (e) {
      print('Error logging app start: $e');
    }
  }

  /// Log memory usage
  Future<void> logMemoryUsage(String context) async {
    try {
      // Get memory information from platform
      final memoryInfo = await _getMemoryInfo();
      
      if (memoryInfo != null) {
        final metrics = {
          'context': context,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...memoryInfo,
        };
        
        if (kDebugMode) {
          print('Memory usage ($context): ${memoryInfo['used_memory_mb']}MB');
        }
      }
    } catch (e) {
      print('Error logging memory usage: $e');
    }
  }

  /// Log network performance
  Future<void> logNetworkPerformance({
    required String endpoint,
    required Duration duration,
    required int statusCode,
    required int responseSize,
  }) async {
    final metrics = {
      'endpoint': endpoint,
      'duration_ms': duration.inMilliseconds,
      'status_code': statusCode,
      'response_size_bytes': responseSize,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    if (kDebugMode) {
      print('Network performance: $endpoint - ${duration.inMilliseconds}ms');
    }
  }

  /// Log ML model performance
  Future<void> logMLPerformance({
    required String modelName,
    required Duration inferenceTime,
    required String inputSize,
    required double confidence,
  }) async {
    final metrics = {
      'model_name': modelName,
      'inference_time_ms': inferenceTime.inMilliseconds,
      'input_size': inputSize,
      'confidence': confidence,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    incrementCounter('ml_inferences');
    
    if (kDebugMode) {
      print('ML performance: $modelName - ${inferenceTime.inMilliseconds}ms');
    }
  }

  /// Log navigation performance
  Future<void> logNavigationPerformance({
    required String fromRoute,
    required String toRoute,
    required Duration duration,
  }) async {
    final metrics = {
      'from_route': fromRoute,
      'to_route': toRoute,
      'duration_ms': duration.inMilliseconds,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    incrementCounter('navigation_events');
    
    if (kDebugMode) {
      print('Navigation: $fromRoute → $toRoute - ${duration.inMilliseconds}ms');
    }
  }

  /// Log user interaction performance
  Future<void> logUserInteraction({
    required String interaction,
    required Duration responseTime,
    Map<String, dynamic>? additionalData,
  }) async {
    final metrics = {
      'interaction': interaction,
      'response_time_ms': responseTime.inMilliseconds,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      if (additionalData != null) ...additionalData,
    };
    
    incrementCounter('user_interactions');
    
    if (kDebugMode) {
      print('User interaction: $interaction - ${responseTime.inMilliseconds}ms');
    }
  }

  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    return {
      'active_traces': _traceStartTimes.keys.toList(),
      'counters': Map.from(_counters),
      'initialized': _isInitialized,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Clear all performance data
  void clearData() {
    _traceStartTimes.clear();
    _counters.clear();
    
    if (kDebugMode) {
      print('Performance data cleared');
    }
  }

  /// Log a custom performance metric
  Future<void> _logPerformanceMetric(String name, Duration duration) async {
    // In a real implementation, you would send this to:
    // - Firebase Performance Monitoring
    // - Custom analytics service
    // - APM tools like New Relic, DataDog, etc.
    
    final metric = {
      'name': name,
      'duration_ms': duration.inMilliseconds,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    // For now, just log to console in debug mode
    if (kDebugMode) {
      print('Performance metric: $metric');
    }
  }

  /// Get memory information from platform
  Future<Map<String, dynamic>?> _getMemoryInfo() async {
    try {
      if (Platform.isAndroid) {
        // On Android, you could use method channels to get memory info
        // For now, return mock data
        return {
          'total_memory_mb': 4096,
          'available_memory_mb': 2048,
          'used_memory_mb': 2048,
          'memory_pressure': false,
        };
      } else if (Platform.isIOS) {
        // On iOS, you could use method channels to get memory info
        // For now, return mock data
        return {
          'total_memory_mb': 4096,
          'available_memory_mb': 2048,
          'used_memory_mb': 2048,
          'memory_pressure': false,
        };
      }
    } catch (e) {
      print('Error getting memory info: $e');
    }
    
    return null;
  }

  /// Monitor frame rendering performance
  void startFrameMonitoring() {
    if (!kDebugMode) return;
    
    // Monitor frame rendering in debug mode
    WidgetsBinding.instance.addPersistentFrameCallback((timeStamp) {
      final frameTime = timeStamp.inMicroseconds / 1000; // Convert to milliseconds
      
      // Log slow frames (> 16.67ms for 60fps)
      if (frameTime > 16.67) {
        print('Slow frame detected: ${frameTime.toStringAsFixed(2)}ms');
        incrementCounter('slow_frames');
      }
      
      incrementCounter('total_frames');
    });
  }

  /// Get average FPS over a period
  double getAverageFPS() {
    final totalFrames = getCounter('total_frames');
    final slowFrames = getCounter('slow_frames');
    
    if (totalFrames == 0) return 0.0;
    
    final goodFrames = totalFrames - slowFrames;
    return (goodFrames / totalFrames) * 60.0;
  }
}