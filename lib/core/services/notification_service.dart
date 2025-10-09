import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Types of notifications supported by the app
enum NotificationType {
  learningReminder,
  achievementUnlocked,
  streakReminder,
  weeklyProgress,
  skillImprovement,
  videoRecommendation,
  practiceReminder,
}

/// Priority levels for notifications
enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

/// Notification frequency settings
enum NotificationFrequency {
  never,
  daily,
  weekly,
  biweekly,
  monthly,
}

/// Represents a scheduled notification
class ScheduledNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final NotificationPriority priority;
  final Map<String, dynamic> data;
  final bool isRecurring;
  final Duration? recurringInterval;

  ScheduledNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.priority = NotificationPriority.medium,
    this.data = const {},
    this.isRecurring = false,
    this.recurringInterval,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'body': body,
      'scheduled_time': scheduledTime.toIso8601String(),
      'priority': priority.toString(),
      'data': data,
      'is_recurring': isRecurring,
      'recurring_interval_ms': recurringInterval?.inMilliseconds,
    };
  }

  factory ScheduledNotification.fromJson(Map<String, dynamic> json) {
    return ScheduledNotification(
      id: json['id'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      title: json['title'],
      body: json['body'],
      scheduledTime: DateTime.parse(json['scheduled_time']),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
      ),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      isRecurring: json['is_recurring'] ?? false,
      recurringInterval: json['recurring_interval_ms'] != null
          ? Duration(milliseconds: json['recurring_interval_ms'])
          : null,
    );
  }
}

/// User notification preferences
class NotificationPreferences {
  final Map<NotificationType, bool> enabledTypes;
  final Map<NotificationType, NotificationFrequency> frequencies;
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;
  final bool enableQuietHours;
  final bool enableSounds;
  final bool enableVibration;
  final int maxDailyNotifications;

  NotificationPreferences({
    required this.enabledTypes,
    required this.frequencies,
    this.quietHoursStart = const TimeOfDay(hour: 22, minute: 0),
    this.quietHoursEnd = const TimeOfDay(hour: 8, minute: 0),
    this.enableQuietHours = true,
    this.enableSounds = true,
    this.enableVibration = true,
    this.maxDailyNotifications = 5,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled_types': enabledTypes.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'frequencies': frequencies.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      'quiet_hours_start': '${quietHoursStart.hour}:${quietHoursStart.minute}',
      'quiet_hours_end': '${quietHoursEnd.hour}:${quietHoursEnd.minute}',
      'enable_quiet_hours': enableQuietHours,
      'enable_sounds': enableSounds,
      'enable_vibration': enableVibration,
      'max_daily_notifications': maxDailyNotifications,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final enabledTypes = <NotificationType, bool>{};
    final enabledTypesJson = json['enabled_types'] as Map<String, dynamic>? ?? {};
    for (final entry in enabledTypesJson.entries) {
      final type = NotificationType.values.firstWhere(
        (e) => e.toString() == entry.key,
      );
      enabledTypes[type] = entry.value as bool;
    }

    final frequencies = <NotificationType, NotificationFrequency>{};
    final frequenciesJson = json['frequencies'] as Map<String, dynamic>? ?? {};
    for (final entry in frequenciesJson.entries) {
      final type = NotificationType.values.firstWhere(
        (e) => e.toString() == entry.key,
      );
      final frequency = NotificationFrequency.values.firstWhere(
        (e) => e.toString() == entry.value,
      );
      frequencies[type] = frequency;
    }

    final quietStartParts = (json['quiet_hours_start'] as String? ?? '22:0').split(':');
    final quietEndParts = (json['quiet_hours_end'] as String? ?? '8:0').split(':');

    return NotificationPreferences(
      enabledTypes: enabledTypes,
      frequencies: frequencies,
      quietHoursStart: TimeOfDay(
        hour: int.parse(quietStartParts[0]),
        minute: int.parse(quietStartParts[1]),
      ),
      quietHoursEnd: TimeOfDay(
        hour: int.parse(quietEndParts[0]),
        minute: int.parse(quietEndParts[1]),
      ),
      enableQuietHours: json['enable_quiet_hours'] ?? true,
      enableSounds: json['enable_sounds'] ?? true,
      enableVibration: json['enable_vibration'] ?? true,
      maxDailyNotifications: json['max_daily_notifications'] ?? 5,
    );
  }

  static NotificationPreferences defaultPreferences() {
    return NotificationPreferences(
      enabledTypes: {
        for (final type in NotificationType.values) type: true,
      },
      frequencies: {
        NotificationType.learningReminder: NotificationFrequency.daily,
        NotificationType.achievementUnlocked: NotificationFrequency.never,
        NotificationType.streakReminder: NotificationFrequency.daily,
        NotificationType.weeklyProgress: NotificationFrequency.weekly,
        NotificationType.skillImprovement: NotificationFrequency.weekly,
        NotificationType.videoRecommendation: NotificationFrequency.weekly,
        NotificationType.practiceReminder: NotificationFrequency.daily,
      },
    );
  }
}

/// Helper class for TimeOfDay serialization
class TimeOfDayHelper {
  static Map<String, int> toJson(TimeOfDay timeOfDay) {
    return {
      'hour': timeOfDay.hour,
      'minute': timeOfDay.minute,
    };
  }

  static TimeOfDay fromJson(Map<String, dynamic> json) {
    return TimeOfDay(
      hour: json['hour'] as int,
      minute: json['minute'] as int,
    );
  }
}

/// Service for managing educational notifications
class NotificationService {
  static const String _preferencesKey = 'notification_preferences';
  static const String _scheduledKey = 'scheduled_notifications';
  static const String _historyKey = 'notification_history';
  static const String _dailyCountKey = 'daily_notification_count';

  late SharedPreferences _prefs;
  NotificationPreferences _preferences = NotificationPreferences.defaultPreferences();
  final List<ScheduledNotification> _scheduledNotifications = [];
  final List<Map<String, dynamic>> _notificationHistory = [];
  Timer? _schedulerTimer;
  int _dailyNotificationCount = 0;
  DateTime _lastCountReset = DateTime.now();
  int _notificationCounter = 0; // Add counter for unique IDs

  /// Initialize the notification service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPreferences();
    await _loadScheduledNotifications();
    await _loadNotificationHistory();
    _loadDailyCount();
    _startScheduler();
  }

  /// Load user notification preferences
  Future<void> _loadPreferences() async {
    try {
      final prefsJson = _prefs.getString(_preferencesKey);
      if (prefsJson != null) {
        _preferences = NotificationPreferences.fromJson(jsonDecode(prefsJson));
      }
    } catch (e) {
      print('Error loading notification preferences: $e');
      _preferences = NotificationPreferences.defaultPreferences();
    }
  }

  /// Save user notification preferences
  Future<void> _savePreferences() async {
    try {
      await _prefs.setString(_preferencesKey, jsonEncode(_preferences.toJson()));
    } catch (e) {
      print('Error saving notification preferences: $e');
    }
  }

  /// Load scheduled notifications
  Future<void> _loadScheduledNotifications() async {
    try {
      final scheduledJson = _prefs.getString(_scheduledKey);
      if (scheduledJson != null) {
        final List<dynamic> scheduledList = jsonDecode(scheduledJson);
        _scheduledNotifications.clear();
        for (final item in scheduledList) {
          _scheduledNotifications.add(ScheduledNotification.fromJson(item));
        }
      }
    } catch (e) {
      print('Error loading scheduled notifications: $e');
    }
  }

  /// Save scheduled notifications
  Future<void> _saveScheduledNotifications() async {
    try {
      final scheduledList = _scheduledNotifications.map((n) => n.toJson()).toList();
      await _prefs.setString(_scheduledKey, jsonEncode(scheduledList));
    } catch (e) {
      print('Error saving scheduled notifications: $e');
    }
  }

  /// Load notification history
  Future<void> _loadNotificationHistory() async {
    try {
      final historyJson = _prefs.getString(_historyKey);
      if (historyJson != null) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        _notificationHistory.clear();
        _notificationHistory.addAll(historyList.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      print('Error loading notification history: $e');
    }
  }

  /// Save notification history
  Future<void> _saveNotificationHistory() async {
    try {
      // Keep only last 100 notifications
      if (_notificationHistory.length > 100) {
        _notificationHistory.removeRange(0, _notificationHistory.length - 100);
      }
      await _prefs.setString(_historyKey, jsonEncode(_notificationHistory));
    } catch (e) {
      print('Error saving notification history: $e');
    }
  }

  /// Load daily notification count
  void _loadDailyCount() {
    final today = DateTime.now();
    final lastResetString = _prefs.getString('${_dailyCountKey}_date');
    
    if (lastResetString != null) {
      _lastCountReset = DateTime.parse(lastResetString);
      if (_isSameDay(today, _lastCountReset)) {
        _dailyNotificationCount = _prefs.getInt(_dailyCountKey) ?? 0;
      } else {
        _resetDailyCount();
      }
    } else {
      _resetDailyCount();
    }
  }

  /// Reset daily notification count
  void _resetDailyCount() {
    _dailyNotificationCount = 0;
    _lastCountReset = DateTime.now();
    _prefs.setInt(_dailyCountKey, 0);
    _prefs.setString('${_dailyCountKey}_date', _lastCountReset.toIso8601String());
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Start the notification scheduler
  void _startScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _processScheduledNotifications(),
    );
  }

  /// Process scheduled notifications
  void _processScheduledNotifications() {
    final now = DateTime.now();
    final toRemove = <ScheduledNotification>[];
    
    // Reset daily count if it's a new day
    if (!_isSameDay(now, _lastCountReset)) {
      _resetDailyCount();
    }

    for (final notification in _scheduledNotifications) {
      if (notification.scheduledTime.isBefore(now) || 
          notification.scheduledTime.isAtSameMomentAs(now)) {
        
        if (_shouldShowNotification(notification)) {
          _showNotification(notification);
        }

        if (notification.isRecurring && notification.recurringInterval != null) {
          // Reschedule recurring notification
          final nextTime = notification.scheduledTime.add(notification.recurringInterval!);
          final rescheduled = ScheduledNotification(
            id: notification.id,
            type: notification.type,
            title: notification.title,
            body: notification.body,
            scheduledTime: nextTime,
            priority: notification.priority,
            data: notification.data,
            isRecurring: true,
            recurringInterval: notification.recurringInterval,
          );
          _scheduledNotifications.add(rescheduled);
        }

        toRemove.add(notification);
      }
    }

    // Remove processed notifications
    for (final notification in toRemove) {
      _scheduledNotifications.remove(notification);
    }

    if (toRemove.isNotEmpty) {
      _saveScheduledNotifications();
    }
  }

  /// Check if notification should be shown based on preferences
  bool _shouldShowNotification(ScheduledNotification notification) {
    // Check if notification type is enabled
    if (!(_preferences.enabledTypes[notification.type] ?? false)) {
      return false;
    }

    // Check daily limit
    if (_dailyNotificationCount >= _preferences.maxDailyNotifications) {
      return false;
    }

    // Check quiet hours
    if (_preferences.enableQuietHours && _isInQuietHours()) {
      return false;
    }

    return true;
  }

  /// Check if current time is in quiet hours
  bool _isInQuietHours() {
    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
    
    final startMinutes = _preferences.quietHoursStart.hour * 60 + _preferences.quietHoursStart.minute;
    final endMinutes = _preferences.quietHoursEnd.hour * 60 + _preferences.quietHoursEnd.minute;
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;

    if (startMinutes <= endMinutes) {
      // Same day quiet hours
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Overnight quiet hours
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  /// Show notification (mock implementation - would integrate with platform notifications)
  void _showNotification(ScheduledNotification notification) {
    print('Showing notification: ${notification.title} - ${notification.body}');
    
    // Add to history
    _notificationHistory.add({
      'id': notification.id,
      'type': notification.type.toString(),
      'title': notification.title,
      'body': notification.body,
      'shown_at': DateTime.now().toIso8601String(),
      'priority': notification.priority.toString(),
    });

    // Increment daily count
    _dailyNotificationCount++;
    _prefs.setInt(_dailyCountKey, _dailyNotificationCount);

    // Save history
    _saveNotificationHistory();
  }

  /// Schedule a notification
  Future<void> scheduleNotification(ScheduledNotification notification) async {
    _scheduledNotifications.add(notification);
    await _saveScheduledNotifications();
  }

  /// Schedule learning reminder
  Future<void> scheduleLearningReminder({
    required String subject,
    required DateTime scheduledTime,
    String? customMessage,
  }) async {
    final notification = ScheduledNotification(
      id: 'learning_reminder_${DateTime.now().millisecondsSinceEpoch}_${++_notificationCounter}',
      type: NotificationType.learningReminder,
      title: 'Time to Learn!',
      body: customMessage ?? 'Ready to practice $subject? Let\'s keep your learning streak going!',
      scheduledTime: scheduledTime,
      priority: NotificationPriority.medium,
      data: {'subject': subject},
    );

    await scheduleNotification(notification);
  }

  /// Schedule achievement notification
  Future<void> scheduleAchievementNotification({
    required String achievementTitle,
    required String achievementDescription,
    DateTime? scheduledTime,
  }) async {
    final notification = ScheduledNotification(
      id: 'achievement_${DateTime.now().millisecondsSinceEpoch}_${++_notificationCounter}',
      type: NotificationType.achievementUnlocked,
      title: 'Achievement Unlocked! 🏆',
      body: '$achievementTitle - $achievementDescription',
      scheduledTime: scheduledTime ?? DateTime.now(),
      priority: NotificationPriority.high,
    );

    await scheduleNotification(notification);
  }

  /// Schedule streak reminder
  Future<void> scheduleStreakReminder({
    required int currentStreak,
    required DateTime scheduledTime,
  }) async {
    final notification = ScheduledNotification(
      id: 'streak_reminder_${DateTime.now().millisecondsSinceEpoch}_${++_notificationCounter}',
      type: NotificationType.streakReminder,
      title: 'Keep Your Streak! 🔥',
      body: 'You\'re on a $currentStreak day learning streak! Don\'t break it now!',
      scheduledTime: scheduledTime,
      priority: NotificationPriority.medium,
      data: {'streak': currentStreak},
    );

    await scheduleNotification(notification);
  }

  /// Schedule weekly progress notification
  Future<void> scheduleWeeklyProgress({
    required Map<String, dynamic> progressData,
    required DateTime scheduledTime,
  }) async {
    final totalQuestions = progressData['total_questions'] ?? 0;
    final accuracy = progressData['accuracy'] ?? 0.0;
    
    final notification = ScheduledNotification(
      id: 'weekly_progress_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.weeklyProgress,
      title: 'Weekly Progress Report 📊',
      body: 'This week: $totalQuestions questions answered with ${(accuracy * 100).toInt()}% accuracy!',
      scheduledTime: scheduledTime,
      priority: NotificationPriority.low,
      data: progressData,
    );

    await scheduleNotification(notification);
  }

  /// Schedule video recommendation notification
  Future<void> scheduleVideoRecommendation({
    required String videoTitle,
    required String subject,
    required DateTime scheduledTime,
  }) async {
    final notification = ScheduledNotification(
      id: 'video_rec_${DateTime.now().millisecondsSinceEpoch}_${++_notificationCounter}',
      type: NotificationType.videoRecommendation,
      title: 'New Video Recommendation 🎥',
      body: 'Check out "$videoTitle" to improve your $subject skills!',
      scheduledTime: scheduledTime,
      priority: NotificationPriority.low,
      data: {'video_title': videoTitle, 'subject': subject},
    );

    await scheduleNotification(notification);
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(String notificationId) async {
    _scheduledNotifications.removeWhere((n) => n.id == notificationId);
    await _saveScheduledNotifications();
  }

  /// Cancel all notifications of a specific type
  Future<void> cancelNotificationsByType(NotificationType type) async {
    _scheduledNotifications.removeWhere((n) => n.type == type);
    await _saveScheduledNotifications();
  }

  /// Update notification preferences
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    _preferences = preferences;
    await _savePreferences();
  }

  /// Get current notification preferences
  NotificationPreferences getPreferences() {
    return _preferences;
  }

  /// Get scheduled notifications
  List<ScheduledNotification> getScheduledNotifications() {
    return List.unmodifiable(_scheduledNotifications);
  }

  /// Get notification history
  List<Map<String, dynamic>> getNotificationHistory({int? limit}) {
    final history = List<Map<String, dynamic>>.from(_notificationHistory);
    history.sort((a, b) => DateTime.parse(b['shown_at']).compareTo(DateTime.parse(a['shown_at'])));
    
    if (limit != null && history.length > limit) {
      return history.take(limit).toList();
    }
    
    return history;
  }

  /// Get daily notification count
  int getDailyNotificationCount() {
    return _dailyNotificationCount;
  }

  /// Clear all notification data
  Future<void> clearAllData() async {
    _scheduledNotifications.clear();
    _notificationHistory.clear();
    _dailyNotificationCount = 0;
    
    await _prefs.remove(_preferencesKey);
    await _prefs.remove(_scheduledKey);
    await _prefs.remove(_historyKey);
    await _prefs.remove(_dailyCountKey);
    await _prefs.remove('${_dailyCountKey}_date');
    
    _preferences = NotificationPreferences.defaultPreferences();
  }

  /// Export notification data
  Map<String, dynamic> exportData() {
    return {
      'preferences': _preferences.toJson(),
      'scheduled_notifications': _scheduledNotifications.map((n) => n.toJson()).toList(),
      'notification_history': List.from(_notificationHistory),
      'daily_count': _dailyNotificationCount,
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Dispose of resources
  void dispose() {
    _schedulerTimer?.cancel();
  }
}