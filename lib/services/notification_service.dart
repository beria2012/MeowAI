import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

import '../models/challenge.dart';
import '../models/user.dart';

class NotificationService {
  static const String _channelId = 'meow_ai_notifications';
  static const String _channelName = 'MeowAI Notifications';
  static const String _channelDescription = 'Notifications for challenges, facts, and reminders';
  
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Initialize the notification service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Android initialization
      const androidInitialize = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization
      const iosInitialize = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: androidInitialize,
        iOS: iosInitialize,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
      print('Notification service initialized successfully');
      return true;
    } catch (e) {
      print('Error initializing notification service: $e');
      return false;
    }
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }
    return true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle navigation based on notification type
    // This would typically use a navigation service or callback
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    if (!_isInitialized) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: _getAndroidImportance(priority),
        priority: _getAndroidPriority(priority),
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: const BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  /// Schedule a notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    if (!_isInitialized) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: _getAndroidImportance(priority),
        priority: _getAndroidPriority(priority),
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails();

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  /// Schedule daily cat fact notifications
  Future<void> scheduleDailyCatFacts(UserPreferences preferences) async {
    if (!preferences.enableNotifications || 
        preferences.factFrequency == NotificationFrequency.never) {
      return;
    }

    // Cancel existing cat fact notifications
    await cancelNotificationsByType('cat_fact');

    final catFacts = _getCatFacts();
    final now = DateTime.now();
    
    // Schedule based on frequency
    int daysInterval;
    switch (preferences.factFrequency) {
      case NotificationFrequency.daily:
        daysInterval = 1;
        break;
      case NotificationFrequency.weekly:
        daysInterval = 7;
        break;
      case NotificationFrequency.monthly:
        daysInterval = 30;
        break;
      default:
        return;
    }

    // Schedule next 30 notifications
    for (int i = 0; i < 30; i++) {
      final scheduleDate = now.add(Duration(days: i * daysInterval));
      final fact = catFacts[Random().nextInt(catFacts.length)];
      
      await scheduleNotification(
        id: 1000 + i, // Cat fact IDs start from 1000
        title: '🐱 Cat Fact of the Day',
        body: fact,
        scheduledDate: DateTime(
          scheduleDate.year,
          scheduleDate.month,
          scheduleDate.day,
          9, // 9 AM
          0,
        ),
        payload: 'cat_fact',
        priority: NotificationPriority.low,
      );
    }
  }

  /// Schedule challenge notifications
  Future<void> scheduleChallengeNotifications(List<Challenge> challenges, UserPreferences preferences) async {
    if (!preferences.enableNotifications || !preferences.enableChallenges) {
      return;
    }

    // Cancel existing challenge notifications
    await cancelNotificationsByType('challenge');

    for (final challenge in challenges) {
      if (challenge.isActive) {
        // Notify about new challenges
        await scheduleNotification(
          id: 2000 + int.parse(challenge.id.substring(0, 4)), // Challenge IDs start from 2000
          title: '🏆 New Challenge Available!',
          body: challenge.title,
          scheduledDate: DateTime.now().add(const Duration(minutes: 5)),
          payload: 'challenge_${challenge.id}',
        );

        // Remind about expiring challenges
        if (challenge.timeRemaining.inHours <= 24 && challenge.timeRemaining.inHours > 0) {
          await scheduleNotification(
            id: 3000 + int.parse(challenge.id.substring(0, 4)), // Expiring challenge IDs start from 3000
            title: '⏰ Challenge Expiring Soon!',
            body: '${challenge.title} expires in ${challenge.timeRemainingText}',
            scheduledDate: challenge.endDate.subtract(const Duration(hours: 2)),
            payload: 'challenge_expiring_${challenge.id}',
            priority: NotificationPriority.high,
          );
        }
      }
    }
  }

  /// Schedule recognition streak reminders
  Future<void> scheduleStreakReminders(UserPreferences preferences) async {
    if (!preferences.enableNotifications) return;

    // Cancel existing streak notifications
    await cancelNotificationsByType('streak');

    // Schedule daily reminder at 8 PM
    final now = DateTime.now();
    final reminderTime = DateTime(now.year, now.month, now.day, 20, 0);
    final scheduleDate = reminderTime.isBefore(now) 
        ? reminderTime.add(const Duration(days: 1))
        : reminderTime;

    await scheduleNotification(
      id: 4000, // Streak reminder ID
      title: '📸 Don\'t Break Your Streak!',
      body: 'Take a photo of a cat today to maintain your recognition streak!',
      scheduledDate: scheduleDate,
      payload: 'streak_reminder',
    );
  }

  /// Schedule achievement notifications
  Future<void> showAchievementNotification(Achievement achievement) async {
    await showNotification(
      id: 5000 + Random().nextInt(1000), // Achievement IDs start from 5000
      title: '🎉 Achievement Unlocked!',
      body: achievement.title,
      payload: 'achievement_${achievement.id}',
      priority: NotificationPriority.high,
    );
  }

  /// Cancel notifications by type
  Future<void> cancelNotificationsByType(String type) async {
    final pendingNotifications = await _notificationsPlugin.pendingNotificationRequests();
    
    for (final notification in pendingNotifications) {
      if (notification.payload?.contains(type) == true) {
        await _notificationsPlugin.cancel(notification.id);
      }
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    } else if (Platform.isIOS) {
      // For iOS, we assume they're enabled if initialization succeeded
      return _isInitialized;
    }
    return false;
  }

  /// Get Android importance level
  Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
    }
  }

  /// Get Android priority level
  Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
    }
  }

  /// Get list of cat facts
  List<String> _getCatFacts() {
    return [
      'Cats have five toes on their front paws, but only four toes on their back paws.',
      'A group of cats is called a "clowder."',
      'Cats can rotate their ears 180 degrees.',
      'A cat\'s purr vibrates at a frequency that promotes bone healing.',
      'Cats sleep 12-16 hours per day.',
      'A cat\'s nose print is unique, just like a human\'s fingerprint.',
      'Cats have a third eyelid called a "nictitating membrane."',
      'The oldest known pet cat existed 9,000 years ago.',
      'Cats have 32 muscles that control their outer ear.',
      'A cat\'s whiskers are roughly as wide as its body.',
      'Cats can make over 100 vocal sounds.',
      'A cat\'s heart beats twice as fast as a human heart.',
      'Cats have a special scent organ called the Jacobson\'s organ.',
      'The richest cat in the world inherited \$7 million.',
      'Cats have excellent night vision and can see at one-sixth the light level required for human vision.',
      'A cat\'s brain is 90% similar to a human brain.',
      'Cats have scent glands in their faces.',
      'The longest cat ever measured was 48.5 inches long.',
      'Cats have a survival instinct that makes them land on their feet.',
      'A cat\'s spine is extremely flexible with 53 vertebrae.',
      'Cats spend 30-50% of their waking hours grooming.',
      'The average cat can jump 8 feet in a single bound.',
      'Cats have excellent memories and can remember things for up to 10 years.',
      'A cat\'s tongue has backward-facing hooks called papillae.',
      'Cats can see some colors, but not as many as humans.',
      'The average indoor cat lives 12-18 years.',
      'Cats have a special reflective layer behind their retinas called the tapetum lucidum.',
      'A cat\'s collar bone doesn\'t connect to other bones.',
      'Cats sweat only through their paw pads.',
      'The ancient Egyptians worshipped cats and considered them sacred.',
    ];
  }

  /// Dispose of the service
  void dispose() {
    _isInitialized = false;
  }
}

/// Notification priority levels
enum NotificationPriority {
  low,
  normal,
  high,
}