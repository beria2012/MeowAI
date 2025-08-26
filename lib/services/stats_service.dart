import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/recognition_result.dart';

/// Service for tracking and managing user statistics
/// 
/// Tracks recognition activity, breed discoveries, usage patterns,
/// and provides insights about user engagement with the app.
class StatsService {
  static const String _statsBoxName = 'user_stats';
  static const String _recognitionsCountKey = 'recognitions_count';
  static const String _uniqueBreedsKey = 'unique_breeds';
  static const String _lastUsedDateKey = 'last_used_date';
  static const String _streakDaysKey = 'streak_days';
  static const String _firstUseKey = 'first_use_date';
  static const String _totalTimeSpentKey = 'total_time_spent';
  static const String _favoriteBreedKey = 'favorite_breed';
  static const String _weeklyGoalKey = 'weekly_goal';
  
  Box<dynamic>? _statsBox;
  bool _isInitialized = false;
  
  // Singleton pattern
  static final StatsService _instance = StatsService._internal();
  factory StatsService() => _instance;
  StatsService._internal();

  /// Initialize the stats service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _statsBox = await Hive.openBox(_statsBoxName);
      _isInitialized = true;
      
      // Initialize first use date if not set
      if (_statsBox!.get(_firstUseKey) == null) {
        await _statsBox!.put(_firstUseKey, DateTime.now().toIso8601String());
      }
      
      print('✅ Stats service initialized');
      return true;
    } catch (e) {
      print('❌ Error initializing stats service: $e');
      return false;
    }
  }

  /// Record a new recognition
  Future<void> recordRecognition(RecognitionResult result) async {
    if (!_isInitialized) return;
    
    try {
      // Increment total recognitions
      final currentCount = getTotalRecognitions();
      await _statsBox!.put(_recognitionsCountKey, currentCount + 1);
      
      // Add breed to unique breeds set
      final uniqueBreeds = Set<String>.from(_statsBox!.get(_uniqueBreedsKey, defaultValue: <String>[]));
      uniqueBreeds.add(result.predictedBreed.id);
      await _statsBox!.put(_uniqueBreedsKey, uniqueBreeds.toList());
      
      // Update streak
      await _updateStreakDays();
      
      print('📊 Recognition recorded: ${result.predictedBreed.name}');
    } catch (e) {
      print('❌ Error recording recognition: $e');
    }
  }

  /// Get total number of recognitions
  int getTotalRecognitions() {
    if (!_isInitialized) return 0;
    return _statsBox!.get(_recognitionsCountKey, defaultValue: 0) as int;
  }

  /// Get number of unique breeds discovered
  int getUniqueBreedsCount() {
    if (!_isInitialized) return 0;
    final uniqueBreeds = _statsBox!.get(_uniqueBreedsKey, defaultValue: <String>[]) as List;
    return uniqueBreeds.length;
  }

  /// Get current streak days
  int getStreakDays() {
    if (!_isInitialized) return 0;
    return _statsBox!.get(_streakDaysKey, defaultValue: 0) as int;
  }

  /// Get days since first use
  int getDaysSinceFirstUse() {
    if (!_isInitialized) return 0;
    
    final firstUseStr = _statsBox!.get(_firstUseKey);
    if (firstUseStr == null) return 0;
    
    final firstUse = DateTime.parse(firstUseStr);
    final now = DateTime.now();
    return now.difference(firstUse).inDays;
  }

  /// Get total time spent in app (in minutes)
  int getTotalTimeSpent() {
    if (!_isInitialized) return 0;
    return _statsBox!.get(_totalTimeSpentKey, defaultValue: 0) as int;
  }

  /// Get recognition activity level
  String getActivityLevel() {
    final recognitions = getTotalRecognitions();
    final days = getDaysSinceFirstUse();
    
    if (days == 0) return 'New User';
    
    final avgPerDay = recognitions / days;
    
    if (avgPerDay >= 5) return 'Super Active';
    if (avgPerDay >= 2) return 'Very Active';
    if (avgPerDay >= 1) return 'Active';
    if (avgPerDay >= 0.5) return 'Moderate';
    return 'Beginner';
  }

  /// Get most discovered breed category
  String getFavoriteBreedOrigin() {
    // This would require breed data analysis
    // For now, return a placeholder
    return 'International';
  }

  /// Get weekly goal progress
  Map<String, dynamic> getWeeklyProgress() {
    final goal = _statsBox?.get(_weeklyGoalKey, defaultValue: 7) as int;
    final currentWeekRecognitions = _getCurrentWeekRecognitions();
    
    return {
      'goal': goal,
      'current': currentWeekRecognitions,
      'percentage': (currentWeekRecognitions / goal * 100).clamp(0, 100).round(),
      'remaining': (goal - currentWeekRecognitions).clamp(0, goal),
    };
  }

  /// Update streak days based on usage
  Future<void> _updateStreakDays() async {
    if (!_isInitialized) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastUsedStr = _statsBox!.get(_lastUsedDateKey);
    
    if (lastUsedStr == null) {
      // First use
      await _statsBox!.put(_streakDaysKey, 1);
      await _statsBox!.put(_lastUsedDateKey, today.toIso8601String());
      return;
    }
    
    final lastUsed = DateTime.parse(lastUsedStr);
    final lastUsedDay = DateTime(lastUsed.year, lastUsed.month, lastUsed.day);
    final daysDiff = today.difference(lastUsedDay).inDays;
    
    if (daysDiff == 0) {
      // Same day, no change to streak
      return;
    } else if (daysDiff == 1) {
      // Consecutive day, increment streak
      final currentStreak = getStreakDays();
      await _statsBox!.put(_streakDaysKey, currentStreak + 1);
    } else {
      // Streak broken, reset to 1
      await _statsBox!.put(_streakDaysKey, 1);
    }
    
    await _statsBox!.put(_lastUsedDateKey, today.toIso8601String());
  }

  /// Get recognitions for current week
  int _getCurrentWeekRecognitions() {
    // This would require storing recognition timestamps
    // For now, return a calculated value
    final total = getTotalRecognitions();
    final days = getDaysSinceFirstUse();
    
    if (days <= 7) return total;
    
    // Estimate current week based on average
    final avgPerDay = total / days;
    return (avgPerDay * 7).round().clamp(0, total);
  }

  /// Set weekly goal
  Future<void> setWeeklyGoal(int goal) async {
    if (!_isInitialized) return;
    await _statsBox!.put(_weeklyGoalKey, goal);
  }

  /// Add time spent in app
  Future<void> addTimeSpent(int minutes) async {
    if (!_isInitialized) return;
    
    final currentTime = getTotalTimeSpent();
    await _statsBox!.put(_totalTimeSpentKey, currentTime + minutes);
  }

  /// Get comprehensive stats summary
  Map<String, dynamic> getStatsOverview() {
    return {
      'totalRecognitions': getTotalRecognitions(),
      'uniqueBreeds': getUniqueBreedsCount(),
      'streakDays': getStreakDays(),
      'daysSinceFirstUse': getDaysSinceFirstUse(),
      'activityLevel': getActivityLevel(),
      'favoriteOrigin': getFavoriteBreedOrigin(),
      'weeklyProgress': getWeeklyProgress(),
      'totalTimeSpent': getTotalTimeSpent(),
    };
  }

  /// Reset all stats (for testing or user request)
  Future<void> resetStats() async {
    if (!_isInitialized) return;
    
    await _statsBox!.clear();
    await _statsBox!.put(_firstUseKey, DateTime.now().toIso8601String());
    print('📊 Stats reset');
  }

  /// Get achievement status
  List<Map<String, dynamic>> getAchievements() {
    final recognitions = getTotalRecognitions();
    final breeds = getUniqueBreedsCount();
    final streak = getStreakDays();
    
    return [
      {
        'title': 'First Recognition',
        'description': 'Recognize your first cat breed',
        'achieved': recognitions >= 1,
        'icon': Icons.camera_alt,
        'target': 1,
        'current': recognitions,
      },
      {
        'title': 'Breed Explorer',
        'description': 'Discover 10 different breeds',
        'achieved': breeds >= 10,
        'icon': Icons.explore,
        'target': 10,
        'current': breeds,
      },
      {
        'title': 'Week Warrior',
        'description': 'Use app for 7 consecutive days',
        'achieved': streak >= 7,
        'icon': Icons.local_fire_department,
        'target': 7,
        'current': streak,
      },
      {
        'title': 'Cat Expert',
        'description': 'Recognize 100 cats',
        'achieved': recognitions >= 100,
        'icon': Icons.star,
        'target': 100,
        'current': recognitions,
      },
      {
        'title': 'Breed Master',
        'description': 'Discover 25 different breeds',
        'achieved': breeds >= 25,
        'icon': Icons.emoji_events,
        'target': 25,
        'current': breeds,
      },
    ];
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}