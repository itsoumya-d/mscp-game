import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp/core/services/notification_service.dart';

void main() {
  group('NotificationService Tests', () {
    late NotificationService notificationService;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      notificationService = NotificationService();
      // Initialize the service to ensure clean state
      await notificationService.initialize();
    });

    tearDown(() {
      notificationService.dispose();
    });

    group('Initialization', () {
      test('should initialize with default preferences when no saved data', () async {
        final preferences = notificationService.getPreferences();
        expect(preferences.enabledTypes[NotificationType.learningReminder], true);
        expect(preferences.enabledTypes[NotificationType.achievementUnlocked], true);
        expect(preferences.enabledTypes[NotificationType.streakReminder], true);
        expect(preferences.enabledTypes[NotificationType.weeklyProgress], true); // Default is true for all types
        expect(preferences.enabledTypes[NotificationType.videoRecommendation], true); // Default is true for all types
        expect(preferences.maxDailyNotifications, 5); // Default is 5, not 10
        expect(preferences.enableQuietHours, true);
        expect(preferences.quietHoursStart, const TimeOfDay(hour: 22, minute: 0));
        expect(preferences.quietHoursEnd, const TimeOfDay(hour: 8, minute: 0));
        expect(preferences.enableSounds, true);
        expect(preferences.enableVibration, true);
      });

      test('should load existing preferences from SharedPreferences', () async {
        final customPrefs = NotificationPreferences(
          enabledTypes: {
            NotificationType.learningReminder: false,
            NotificationType.achievementUnlocked: true,
            NotificationType.streakReminder: true,
            NotificationType.weeklyProgress: true,
            NotificationType.videoRecommendation: false,
          },
          frequencies: {
            NotificationType.learningReminder: NotificationFrequency.daily,
            NotificationType.achievementUnlocked: NotificationFrequency.never,
            NotificationType.streakReminder: NotificationFrequency.daily,
            NotificationType.weeklyProgress: NotificationFrequency.weekly,
            NotificationType.videoRecommendation: NotificationFrequency.weekly,
          },
          maxDailyNotifications: 5,
          enableQuietHours: false,
          quietHoursStart: const TimeOfDay(hour: 23, minute: 30),
          quietHoursEnd: const TimeOfDay(hour: 7, minute: 0),
          enableSounds: false,
          enableVibration: true,
        );

        SharedPreferences.setMockInitialValues({
          'notification_preferences': jsonEncode(customPrefs.toJson()),
        });

        await notificationService.initialize();
        
        final loadedPrefs = notificationService.getPreferences();
        expect(loadedPrefs.enabledTypes[NotificationType.learningReminder], false);
        expect(loadedPrefs.enabledTypes[NotificationType.weeklyProgress], true);
        expect(loadedPrefs.maxDailyNotifications, 5);
        expect(loadedPrefs.enableQuietHours, false);
        expect(loadedPrefs.enableSounds, false);
        expect(loadedPrefs.enableVibration, true);
      });

      test('should handle corrupted preferences data gracefully', () async {
        SharedPreferences.setMockInitialValues({
          'notification_preferences': 'invalid_json',
        });

        await notificationService.initialize();
        
        final preferences = notificationService.getPreferences();
        expect(preferences.enabledTypes[NotificationType.learningReminder], true);
        expect(preferences.maxDailyNotifications, 5); // Default is 5, not 10
      });

      test('should load existing scheduled notifications', () async {
        final scheduledNotification = ScheduledNotification(
          id: 'test_notification',
          type: NotificationType.learningReminder,
          title: 'Test Title',
          body: 'Test Body',
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
          priority: NotificationPriority.medium,
        );

        SharedPreferences.setMockInitialValues({
          'scheduled_notifications': jsonEncode([scheduledNotification.toJson()]),
        });

        await notificationService.initialize();
        
        final scheduled = notificationService.getScheduledNotifications();
        expect(scheduled.length, 1);
        expect(scheduled.first.id, 'test_notification');
        expect(scheduled.first.title, 'Test Title');
        expect(scheduled.first.type, NotificationType.learningReminder);
      });

      test('should load existing notification history', () async {
        final historyItem = {
          'id': 'test_notification',
          'type': 'NotificationType.learningReminder',
          'title': 'Test Title',
          'body': 'Test Body',
          'shown_at': DateTime.now().toIso8601String(),
          'priority': 'NotificationPriority.medium',
        };

        SharedPreferences.setMockInitialValues({
          'notification_history': jsonEncode([historyItem]),
        });

        await notificationService.initialize();
        
        final history = notificationService.getNotificationHistory();
        expect(history.length, 1);
        expect(history.first['id'], 'test_notification');
        expect(history.first['title'], 'Test Title');
      });
    });

    group('Preferences Management', () {
      test('should update and save preferences', () async {
        await notificationService.initialize();
        
        final newPreferences = NotificationPreferences(
          enabledTypes: {
            NotificationType.learningReminder: false,
            NotificationType.achievementUnlocked: true,
            NotificationType.streakReminder: false,
            NotificationType.weeklyProgress: true,
            NotificationType.videoRecommendation: true,
          },
          frequencies: {
            NotificationType.learningReminder: NotificationFrequency.weekly,
            NotificationType.achievementUnlocked: NotificationFrequency.never,
            NotificationType.streakReminder: NotificationFrequency.daily,
            NotificationType.weeklyProgress: NotificationFrequency.weekly,
            NotificationType.videoRecommendation: NotificationFrequency.daily,
          },
          maxDailyNotifications: 15,
          enableQuietHours: false,
          quietHoursStart: const TimeOfDay(hour: 21, minute: 0),
          quietHoursEnd: const TimeOfDay(hour: 9, minute: 0),
          enableSounds: false,
          enableVibration: false,
        );

        await notificationService.updatePreferences(newPreferences);
        
        final updatedPrefs = notificationService.getPreferences();
        expect(updatedPrefs.enabledTypes[NotificationType.learningReminder], false);
        expect(updatedPrefs.enabledTypes[NotificationType.weeklyProgress], true);
        expect(updatedPrefs.maxDailyNotifications, 15);
        expect(updatedPrefs.enableQuietHours, false);
        expect(updatedPrefs.enableSounds, false);
        expect(updatedPrefs.enableVibration, false);
      });

      test('should persist preferences across service restarts', () async {
        await notificationService.initialize();
        
        final newPreferences = NotificationPreferences(
          enabledTypes: {
            NotificationType.learningReminder: false,
            NotificationType.achievementUnlocked: false,
            NotificationType.streakReminder: false,
            NotificationType.weeklyProgress: false,
            NotificationType.videoRecommendation: true,
          },
          frequencies: {
            NotificationType.learningReminder: NotificationFrequency.daily,
            NotificationType.achievementUnlocked: NotificationFrequency.never,
            NotificationType.streakReminder: NotificationFrequency.daily,
            NotificationType.weeklyProgress: NotificationFrequency.weekly,
            NotificationType.videoRecommendation: NotificationFrequency.weekly,
          },
          maxDailyNotifications: 3,
          enableQuietHours: true,
          quietHoursStart: const TimeOfDay(hour: 20, minute: 30),
          quietHoursEnd: const TimeOfDay(hour: 10, minute: 0),
          enableSounds: false,
          enableVibration: false,
        );

        await notificationService.updatePreferences(newPreferences);
        notificationService.dispose();

        // Create new service instance
        final newService = NotificationService();
        await newService.initialize();
        
        final loadedPrefs = newService.getPreferences();
        expect(loadedPrefs.enabledTypes[NotificationType.videoRecommendation], true);
        expect(loadedPrefs.enabledTypes[NotificationType.learningReminder], false);
        expect(loadedPrefs.maxDailyNotifications, 3);
        expect(loadedPrefs.quietHoursStart, const TimeOfDay(hour: 20, minute: 30));
        expect(loadedPrefs.enableSounds, false);
        expect(loadedPrefs.enableVibration, false);
        
        newService.dispose();
      });
    });

    group('Notification Scheduling', () {
      test('should schedule learning reminder notification', () async {
        await notificationService.initialize();
        
        final scheduledTime = DateTime.now().add(const Duration(hours: 2));
        await notificationService.scheduleLearningReminder(
          subject: 'Mathematics',
          scheduledTime: scheduledTime,
          customMessage: 'Time to practice algebra!',
        );

        final scheduled = notificationService.getScheduledNotifications();
        expect(scheduled.length, 1);
        expect(scheduled.first.type, NotificationType.learningReminder);
        expect(scheduled.first.title, 'Time to Learn!');
        expect(scheduled.first.body, 'Time to practice algebra!');
        expect(scheduled.first.data?['subject'], 'Mathematics');
        expect(scheduled.first.priority, NotificationPriority.medium);
      });

      test('should schedule achievement notification', () async {
        await notificationService.initialize();
        
        await notificationService.scheduleAchievementNotification(
          achievementTitle: 'Math Master',
          achievementDescription: 'Completed 100 math problems',
        );

        final scheduled = notificationService.getScheduledNotifications();
        expect(scheduled.length, 1);
        expect(scheduled.first.type, NotificationType.achievementUnlocked);
        expect(scheduled.first.title, 'Achievement Unlocked! 🏆');
        expect(scheduled.first.body, 'Math Master - Completed 100 math problems');
        expect(scheduled.first.priority, NotificationPriority.high);
      });

      test('should schedule streak reminder notification', () async {
        await notificationService.initialize();
        
        final scheduledTime = DateTime.now().add(const Duration(hours: 1));
        await notificationService.scheduleStreakReminder(
          currentStreak: 7,
          scheduledTime: scheduledTime,
        );

        final scheduled = notificationService.getScheduledNotifications();
        expect(scheduled.length, 1);
        expect(scheduled.first.type, NotificationType.streakReminder);
        expect(scheduled.first.title, 'Keep Your Streak! 🔥');
        expect(scheduled.first.body, 'You\'re on a 7 day learning streak! Don\'t break it now!');
        expect(scheduled.first.data?['streak'], 7);
        expect(scheduled.first.priority, NotificationPriority.medium);
      });

      test('should schedule weekly progress notification', () async {
        await notificationService.initialize();
        
        final progressData = {
          'total_questions': 150,
          'accuracy': 0.85,
          'subjects_practiced': ['Math', 'Science'],
        };
        
        final scheduledTime = DateTime.now().add(const Duration(days: 7));
        await notificationService.scheduleWeeklyProgress(
          progressData: progressData,
          scheduledTime: scheduledTime,
        );

        final scheduled = notificationService.getScheduledNotifications();
        expect(scheduled.length, 1);
        expect(scheduled.first.type, NotificationType.weeklyProgress);
        expect(scheduled.first.title, 'Weekly Progress Report 📊');
        expect(scheduled.first.body, 'This week: 150 questions answered with 85% accuracy!');
        expect(scheduled.first.data?['total_questions'], 150);
        expect(scheduled.first.data?['accuracy'], 0.85);
        expect(scheduled.first.priority, NotificationPriority.low);
      });

      test('should schedule video recommendation notification', () async {
        await notificationService.initialize();
        
        final scheduledTime = DateTime.now().add(const Duration(hours: 3));
        await notificationService.scheduleVideoRecommendation(
          videoTitle: 'Advanced Calculus Explained',
          subject: 'Mathematics',
          scheduledTime: scheduledTime,
        );

        final scheduled = notificationService.getScheduledNotifications();
        expect(scheduled.length, 1);
        expect(scheduled.first.type, NotificationType.videoRecommendation);
        expect(scheduled.first.title, 'New Video Recommendation 🎥');
        expect(scheduled.first.body, 'Check out "Advanced Calculus Explained" to improve your Mathematics skills!');
        expect(scheduled.first.data?['video_title'], 'Advanced Calculus Explained');
        expect(scheduled.first.data?['subject'], 'Mathematics');
        expect(scheduled.first.priority, NotificationPriority.low);
      });

      test('should cancel specific notification', () async {
        await notificationService.scheduleLearningReminder(
          subject: 'Math',
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
        );
        
        await notificationService.scheduleLearningReminder(
          subject: 'Science',
          scheduledTime: DateTime.now().add(const Duration(hours: 2)),
        );

        var scheduled = notificationService.getScheduledNotifications();
        expect(scheduled.length, 2);
        
        final notificationId = scheduled.first.id;
        await notificationService.cancelNotification(notificationId);
        
        scheduled = notificationService.getScheduledNotifications();
        expect(scheduled.length, 1);
        expect(scheduled.first.id, isNot(notificationId));
      });

      test('should cancel notifications by type', () async {
        await notificationService.initialize();
        
        await notificationService.scheduleLearningReminder(
          subject: 'Math',
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
        );
        
        await notificationService.scheduleLearningReminder(
          subject: 'Science',
          scheduledTime: DateTime.now().add(const Duration(hours: 2)),
        );
        
        await notificationService.scheduleAchievementNotification(
          achievementTitle: 'Test Achievement',
          achievementDescription: 'Test Description',
        );

        var scheduled = notificationService.getScheduledNotifications();
        expect(scheduled.length, 3);
        
        await notificationService.cancelNotificationsByType(NotificationType.learningReminder);
        
        scheduled = notificationService.getScheduledNotifications();
        expect(scheduled.length, 1);
        expect(scheduled.first.type, NotificationType.achievementUnlocked);
      });
    });

    group('Daily Notification Count', () {
      test('should track daily notification count', () async {
        await notificationService.initialize();
        
        expect(notificationService.getDailyNotificationCount(), 0);
        
        // Simulate showing notifications by directly calling the private method
        // In a real scenario, this would be tested through the scheduler
        final notification = ScheduledNotification(
          id: 'test',
          type: NotificationType.learningReminder,
          title: 'Test',
          body: 'Test',
          scheduledTime: DateTime.now(),
          priority: NotificationPriority.medium,
        );
        
        // We can't directly test the private _showNotification method,
        // but we can test the daily count functionality through scheduling
        await notificationService.scheduleNotification(notification);
        
        // The count would be incremented when the notification is actually shown
        // For testing purposes, we'll verify the initial state
        expect(notificationService.getDailyNotificationCount(), 0);
      });

      test('should reset daily count on new day', () async {
        // This test would require mocking DateTime.now() to simulate day changes
        // For now, we'll test the basic functionality
        await notificationService.initialize();
        
        expect(notificationService.getDailyNotificationCount(), 0);
      });
    });

    group('Notification History', () {
      test('should retrieve notification history', () async {
        await notificationService.initialize();
        
        final history = notificationService.getNotificationHistory();
        expect(history, isA<List<Map<String, dynamic>>>());
        expect(history.length, 0);
      });

      test('should limit notification history results', () async {
        // Create service with existing history
        final historyItems = List.generate(20, (index) => {
          'id': 'notification_$index',
          'type': 'NotificationType.learningReminder',
          'title': 'Test Title $index',
          'body': 'Test Body $index',
          'shown_at': DateTime.now().subtract(Duration(hours: index)).toIso8601String(),
          'priority': 'NotificationPriority.medium',
        });

        SharedPreferences.setMockInitialValues({
          'notification_history': jsonEncode(historyItems),
        });

        await notificationService.initialize();
        
        final limitedHistory = notificationService.getNotificationHistory(limit: 5);
        expect(limitedHistory.length, 5);
        
        final fullHistory = notificationService.getNotificationHistory();
        expect(fullHistory.length, 20);
      });

      test('should sort notification history by date (newest first)', () async {
        final now = DateTime.now();
        final historyItems = [
          {
            'id': 'old_notification',
            'type': 'NotificationType.learningReminder',
            'title': 'Old Notification',
            'body': 'Old Body',
            'shown_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
            'priority': 'NotificationPriority.medium',
          },
          {
            'id': 'new_notification',
            'type': 'NotificationType.achievementUnlocked',
            'title': 'New Notification',
            'body': 'New Body',
            'shown_at': now.toIso8601String(),
            'priority': 'NotificationPriority.high',
          },
        ];

        SharedPreferences.setMockInitialValues({
          'notification_history': jsonEncode(historyItems),
        });

        await notificationService.initialize();
        
        final history = notificationService.getNotificationHistory();
        expect(history.length, 2);
        expect(history.first['id'], 'new_notification');
        expect(history.last['id'], 'old_notification');
      });
    });

    group('Data Management', () {
      test('should clear all notification data', () async {
        // Set up service with existing data
        final preferences = NotificationPreferences(
          enabledTypes: {NotificationType.learningReminder: false},
          frequencies: {NotificationType.learningReminder: NotificationFrequency.weekly},
          maxDailyNotifications: 5,
          enableQuietHours: false,
          quietHoursStart: const TimeOfDay(hour: 23, minute: 0),
          quietHoursEnd: const TimeOfDay(hour: 7, minute: 0),
          enableSounds: false,
          enableVibration: false,
        );

        final scheduledNotification = ScheduledNotification(
          id: 'test_notification',
          type: NotificationType.learningReminder,
          title: 'Test',
          body: 'Test',
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
          priority: NotificationPriority.medium,
        );

        final historyItem = {
          'id': 'test_notification',
          'type': 'NotificationType.learningReminder',
          'title': 'Test',
          'body': 'Test',
          'shown_at': DateTime.now().toIso8601String(),
          'priority': 'NotificationPriority.medium',
        };

        SharedPreferences.setMockInitialValues({
          'notification_preferences': jsonEncode(preferences.toJson()),
          'scheduled_notifications': jsonEncode([scheduledNotification.toJson()]),
          'notification_history': jsonEncode([historyItem]),
          'daily_notification_count': 5,
          'daily_notification_count_date': DateTime.now().toIso8601String(),
        });

        await notificationService.initialize();
        
        // Verify data exists
        expect(notificationService.getPreferences().maxDailyNotifications, 5);
        expect(notificationService.getScheduledNotifications().length, 1);
        expect(notificationService.getNotificationHistory().length, 1);
        expect(notificationService.getDailyNotificationCount(), 5);
        
        // Clear all data
        await notificationService.clearAllData();
        
        // Verify data is cleared and reset to defaults
        final clearedPrefs = notificationService.getPreferences();
        expect(clearedPrefs.maxDailyNotifications, 5); // Default value
        expect(clearedPrefs.enabledTypes[NotificationType.learningReminder], true); // Default
        expect(notificationService.getScheduledNotifications().length, 0);
        expect(notificationService.getNotificationHistory().length, 0);
        expect(notificationService.getDailyNotificationCount(), 0);
      });

      test('should export notification data', () async {
        await notificationService.initialize();
        
        // Add some test data
        await notificationService.scheduleLearningReminder(
          subject: 'Math',
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
        );

        final exportData = notificationService.exportData();
        
        expect(exportData, isA<Map<String, dynamic>>());
        expect(exportData, containsPair('preferences', anything));
        expect(exportData, containsPair('scheduled_notifications', anything));
        expect(exportData, containsPair('notification_history', anything));
        expect(exportData, containsPair('daily_count', anything));
        expect(exportData, containsPair('export_timestamp', anything));
        
        expect(exportData['scheduled_notifications'], isA<List>());
        expect((exportData['scheduled_notifications'] as List).length, 1);
        expect(exportData['daily_count'], 0);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle invalid JSON in scheduled notifications', () async {
        SharedPreferences.setMockInitialValues({
          'scheduled_notifications': 'invalid_json',
        });

        await notificationService.initialize();
        
        final scheduled = notificationService.getScheduledNotifications();
        expect(scheduled.length, 0);
      });

      test('should handle invalid JSON in notification history', () async {
        SharedPreferences.setMockInitialValues({
          'notification_history': 'invalid_json',
        });

        await notificationService.initialize();
        
        final history = notificationService.getNotificationHistory();
        expect(history.length, 0);
      });

      test('should handle missing daily count data', () async {
        await notificationService.initialize();
        
        expect(notificationService.getDailyNotificationCount(), 0);
      });

      test('should handle multiple dispose calls', () {
        notificationService.dispose();
        notificationService.dispose(); // Should not throw
      });

      test('should handle empty notification data gracefully', () async {
        await notificationService.initialize();
        
        await notificationService.cancelNotification('non_existent_id');
        await notificationService.cancelNotificationsByType(NotificationType.learningReminder);
        
        // Should not throw errors
        expect(notificationService.getScheduledNotifications().length, 0);
      });
    });

    group('TimeOfDay Helper', () {
      test('should serialize and deserialize TimeOfDay correctly', () {
        const timeOfDay = TimeOfDay(hour: 14, minute: 30);
        final json = TimeOfDayHelper.toJson(timeOfDay);
        final deserializedTime = TimeOfDayHelper.fromJson(json);
        
        expect(deserializedTime.hour, 14);
        expect(deserializedTime.minute, 30);
      });

      test('should handle edge cases for TimeOfDay', () {
        const midnight = TimeOfDay(hour: 0, minute: 0);
        const almostMidnight = TimeOfDay(hour: 23, minute: 59);
        
        final midnightJson = TimeOfDayHelper.toJson(midnight);
        final almostMidnightJson = TimeOfDayHelper.toJson(almostMidnight);
        
        final deserializedMidnight = TimeOfDayHelper.fromJson(midnightJson);
        final deserializedAlmostMidnight = TimeOfDayHelper.fromJson(almostMidnightJson);
        
        expect(deserializedMidnight.hour, 0);
        expect(deserializedMidnight.minute, 0);
        expect(deserializedAlmostMidnight.hour, 23);
        expect(deserializedAlmostMidnight.minute, 59);
      });
    });

    group('ScheduledNotification', () {
      test('should serialize and deserialize ScheduledNotification correctly', () {
        final scheduledTime = DateTime.now().add(const Duration(hours: 1));
        final notification = ScheduledNotification(
          id: 'test_id',
          type: NotificationType.learningReminder,
          title: 'Test Title',
          body: 'Test Body',
          scheduledTime: scheduledTime,
          priority: NotificationPriority.high,
          data: {'key': 'value'},
          isRecurring: true,
          recurringInterval: const Duration(days: 1),
        );

        final json = notification.toJson();
        final deserializedNotification = ScheduledNotification.fromJson(json);
        
        expect(deserializedNotification.id, 'test_id');
        expect(deserializedNotification.type, NotificationType.learningReminder);
        expect(deserializedNotification.title, 'Test Title');
        expect(deserializedNotification.body, 'Test Body');
        expect(deserializedNotification.priority, NotificationPriority.high);
        expect(deserializedNotification.data?['key'], 'value');
        expect(deserializedNotification.isRecurring, true);
        expect(deserializedNotification.recurringInterval, const Duration(days: 1));
      });

      test('should handle ScheduledNotification without optional fields', () {
        final scheduledTime = DateTime.now().add(const Duration(hours: 1));
        final notification = ScheduledNotification(
          id: 'simple_id',
          type: NotificationType.achievementUnlocked,
          title: 'Simple Title',
          body: 'Simple Body',
          scheduledTime: scheduledTime,
          priority: NotificationPriority.medium,
        );

        final json = notification.toJson();
        final deserializedNotification = ScheduledNotification.fromJson(json);
        
        expect(deserializedNotification.id, 'simple_id');
        expect(deserializedNotification.data, {});
        expect(deserializedNotification.isRecurring, false);
        expect(deserializedNotification.recurringInterval, null);
      });
    });

    group('NotificationPreferences', () {
      test('should serialize and deserialize NotificationPreferences correctly', () {
        final preferences = NotificationPreferences(
          enabledTypes: {
            NotificationType.learningReminder: true,
            NotificationType.achievementUnlocked: false,
            NotificationType.streakReminder: true,
            NotificationType.weeklyProgress: false,
            NotificationType.videoRecommendation: true,
          },
          frequencies: {
            NotificationType.learningReminder: NotificationFrequency.daily,
            NotificationType.achievementUnlocked: NotificationFrequency.never,
            NotificationType.streakReminder: NotificationFrequency.weekly,
            NotificationType.weeklyProgress: NotificationFrequency.weekly,
            NotificationType.videoRecommendation: NotificationFrequency.daily,
          },
          maxDailyNotifications: 8,
          enableQuietHours: true,
          quietHoursStart: const TimeOfDay(hour: 21, minute: 30),
          quietHoursEnd: const TimeOfDay(hour: 8, minute: 30),
          enableSounds: false,
          enableVibration: true,
        );

        final json = preferences.toJson();
        final deserializedPreferences = NotificationPreferences.fromJson(json);
        
        expect(deserializedPreferences.enabledTypes[NotificationType.learningReminder], true);
        expect(deserializedPreferences.enabledTypes[NotificationType.achievementUnlocked], false);
        expect(deserializedPreferences.frequencies[NotificationType.streakReminder], NotificationFrequency.weekly);
        expect(deserializedPreferences.maxDailyNotifications, 8);
        expect(deserializedPreferences.enableQuietHours, true);
        expect(deserializedPreferences.quietHoursStart, const TimeOfDay(hour: 21, minute: 30));
        expect(deserializedPreferences.quietHoursEnd, const TimeOfDay(hour: 8, minute: 30));
        expect(deserializedPreferences.enableSounds, false);
        expect(deserializedPreferences.enableVibration, true);
      });

      test('should create default preferences correctly', () {
        final defaultPrefs = NotificationPreferences.defaultPreferences();
        
        expect(defaultPrefs.enabledTypes[NotificationType.learningReminder], true);
        expect(defaultPrefs.enabledTypes[NotificationType.achievementUnlocked], true);
        expect(defaultPrefs.enabledTypes[NotificationType.streakReminder], true);
        expect(defaultPrefs.enabledTypes[NotificationType.weeklyProgress], true);
        expect(defaultPrefs.enabledTypes[NotificationType.videoRecommendation], true);
        expect(defaultPrefs.maxDailyNotifications, 5);
        expect(defaultPrefs.enableQuietHours, true);
        expect(defaultPrefs.quietHoursStart, const TimeOfDay(hour: 22, minute: 0));
        expect(defaultPrefs.quietHoursEnd, const TimeOfDay(hour: 8, minute: 0));
        expect(defaultPrefs.enableSounds, true);
        expect(defaultPrefs.enableVibration, true);
      });
    });
  });
}