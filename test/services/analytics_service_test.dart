import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp/core/services/analytics_service.dart';
import 'package:sp/core/models/question_pool.dart';

void main() {
  group('AnalyticsService Tests', () {
    late AnalyticsService analyticsService;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      analyticsService = AnalyticsService();
    });

    tearDown(() async {
        analyticsService.dispose();
      });

    group('Initialization', () {
      test('should initialize successfully with empty data', () async {
        await analyticsService.initialize();
        
        final engagement = analyticsService.getEngagementSummary();
        final patterns = analyticsService.getLearningPatterns();
        
        expect(engagement, isEmpty);
        expect(patterns, isEmpty);
      });

      test('should load existing data on initialization', () async {
        // Pre-populate SharedPreferences
        SharedPreferences.setMockInitialValues({
          'engagement_metrics': '{"total_sessions": 5, "total_time_seconds": 3600}',
          'learning_patterns': '{"current_streak": 3, "subject_counts": {"math": 10}}',
        });

        await analyticsService.initialize();
        
        final engagement = analyticsService.getEngagementSummary();
        final patterns = analyticsService.getLearningPatterns();
        
        expect(engagement['total_sessions'], equals(5));
        expect(engagement['total_time_seconds'], equals(3600));
        expect(patterns['current_streak'], equals(3));
        expect(patterns['subject_counts']['math'], equals(10));
      });

      test('should handle corrupted data gracefully', () async {
        SharedPreferences.setMockInitialValues({
          'engagement_metrics': 'invalid_json',
          'learning_patterns': '{"invalid": json}',
        });

        await analyticsService.initialize();
        
        final engagement = analyticsService.getEngagementSummary();
        final patterns = analyticsService.getLearningPatterns();
        
        expect(engagement, isEmpty);
        expect(patterns, isEmpty);
      });
    });

    group('Session Management', () {
      test('should start session automatically on initialization', () async {
        await analyticsService.initialize();
        
        final sessionInfo = analyticsService.getCurrentSessionInfo();
        
        expect(sessionInfo, isNotEmpty);
        expect(sessionInfo['start_time'], isNotNull);
        expect(sessionInfo['duration_seconds'], isA<int>());
        expect(sessionInfo['events_count'], equals(0));
      });

      test('should end session and calculate duration', () async {
        // Use a fresh service instance to avoid interference
        final testService = AnalyticsService();
        await testService.initialize();
        
        // Clear any existing data to start fresh
        await testService.clearAllData();
        await testService.initialize();
        
        // Wait a bit to ensure duration > 0
        await Future.delayed(const Duration(milliseconds: 1500));
        
        await testService.endSession();
        
        // Add a small delay to ensure async operations complete
        await Future.delayed(const Duration(milliseconds: 100));

        final engagement = testService.getEngagementSummary();
        expect(engagement['total_sessions'], equals(1));
        expect(engagement['total_time_seconds'], greaterThan(0));
        
        testService.dispose();
      });

      test('should handle multiple session cycles', () async {
        await analyticsService.initialize();
        await analyticsService.endSession();
        
        // Start new session
        await analyticsService.initialize();
        await analyticsService.endSession();
        
        final engagement = analyticsService.getEngagementSummary();
        expect(engagement['total_sessions'], equals(2));
      });
    });

    group('Event Tracking', () {
      setUp(() async {
        await analyticsService.initialize();
      });

      test('should track question answered events', () async {
        analyticsService.trackQuestionAnswered(
           subject: 'math',
           category: QuestionCategory.conceptual,
           difficulty: 'medium',
           isCorrect: true,
           responseTimeMs: 5000,
         );

        final sessionInfo = analyticsService.getCurrentSessionInfo();
        expect(sessionInfo['events_count'], equals(1));
      });

      test('should track skill practice events', () async {
        analyticsService.trackSkillPractice(
          subject: 'science',
          skill: 'algebra',
          questionsAttempted: 10,
          questionsCorrect: 8,
          totalTimeMs: 300000,
        );

        final sessionInfo = analyticsService.getCurrentSessionInfo();
        expect(sessionInfo['events_count'], equals(1));
      });

      test('should track achievement unlocked events', () async {
        analyticsService.trackAchievementUnlocked(
          achievementId: 'streak_7',
          achievementType: 'streak',
          subject: 'math',
        );

        final sessionInfo = analyticsService.getCurrentSessionInfo();
        expect(sessionInfo['events_count'], equals(1));
      });

      test('should track video watched events', () async {
        analyticsService.trackVideoWatched(
          videoId: 'video_123',
          subject: 'physics',
          category: 'mechanics',
          watchDurationMs: 120000,
          totalDurationMs: 180000,
        );

        final sessionInfo = analyticsService.getCurrentSessionInfo();
        expect(sessionInfo['events_count'], equals(1));
      });

      test('should limit event history to prevent excessive storage', () async {
        // Add more than 1000 events
        for (int i = 0; i < 1100; i++) {
          analyticsService.trackEvent('test_event', {'index': i});
        }

        final sessionInfo = analyticsService.getCurrentSessionInfo();
        expect(sessionInfo['events_count'], equals(1000));
      });
    });

    group('Learning Patterns Analysis', () {
      setUp(() async {
        await analyticsService.initialize();
      });

      test('should track subject preferences', () async {
        analyticsService.trackQuestionAnswered(
          subject: 'math',
          category: QuestionCategory.conceptual,
          difficulty: 'easy',
          isCorrect: true,
          responseTimeMs: 3000,
        );
        
        analyticsService.trackQuestionAnswered(
          subject: 'math',
          category: QuestionCategory.factual,
          difficulty: 'medium',
          isCorrect: false,
          responseTimeMs: 5000,
        );
        
        analyticsService.trackQuestionAnswered(
          subject: 'science',
          category: QuestionCategory.analytical,
          difficulty: 'hard',
          isCorrect: true,
          responseTimeMs: 8000,
        );

        await analyticsService.endSession();

        final preferences = analyticsService.getSubjectPreferences();
        expect(preferences['math'], closeTo(0.67, 0.01));
        expect(preferences['science'], closeTo(0.33, 0.01));
      });

      test('should track category preferences', () async {
        analyticsService.trackQuestionAnswered(
          subject: 'math',
          category: QuestionCategory.conceptual,
          difficulty: 'easy',
          isCorrect: true,
          responseTimeMs: 3000,
        );
        
        analyticsService.trackQuestionAnswered(
          subject: 'science',
          category: QuestionCategory.conceptual,
          difficulty: 'medium',
          isCorrect: true,
          responseTimeMs: 4000,
        );

        await analyticsService.endSession();

        final preferences = analyticsService.getCategoryPreferences();
        expect(preferences['conceptual'], equals(1.0));
      });

      test('should calculate learning streaks', () async {
        await analyticsService.endSession();

        final consistency = analyticsService.getLearningConsistency();
        expect(consistency['current_streak'], equals(1));
        expect(consistency['longest_streak'], equals(1));
      });

      test('should update engagement metrics', () async {
        // Use a fresh service instance to avoid interference
        final testService = AnalyticsService();
        await testService.initialize();
        
        // Clear any existing data to start fresh
        await testService.clearAllData();
        await testService.initialize();
        
        testService.trackQuestionAnswered(
          subject: 'math',
          category: QuestionCategory.conceptual,
          difficulty: 'easy',
          isCorrect: true,
          responseTimeMs: 3000,
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        await testService.endSession();
        
        // Add a small delay to ensure async operations complete
        await Future.delayed(const Duration(milliseconds: 100));

        final engagement = testService.getEngagementSummary();
        expect(engagement['total_sessions'], equals(1));
        expect(engagement['total_time_seconds'], greaterThan(0));
        expect(engagement['event_counts']['question_answered'], equals(1));
        expect(engagement['average_session_duration'], greaterThan(0));
        
        testService.dispose();
      });
    });

    group('Data Persistence', () {
      test('should persist engagement metrics across restarts', () async {
        await analyticsService.initialize();
        
        analyticsService.trackQuestionAnswered(
          subject: 'math',
          category: QuestionCategory.conceptual,
          difficulty: 'easy',
          isCorrect: true,
          responseTimeMs: 3000,
        );
        
        await analyticsService.endSession();

        // Create new service instance
        final newService = AnalyticsService();
        await newService.initialize();

        final engagement = newService.getEngagementSummary();
        expect(engagement['total_sessions'], equals(1));
        expect(engagement['event_counts']['question_answered'], equals(1));

        newService.dispose();
      });

      test('should persist learning patterns across restarts', () async {
        await analyticsService.initialize();
        
        analyticsService.trackQuestionAnswered(
          subject: 'math',
          category: QuestionCategory.conceptual,
          difficulty: 'easy',
          isCorrect: true,
          responseTimeMs: 3000,
        );
        
        await analyticsService.endSession();

        // Create new service instance
        final newService = AnalyticsService();
        await newService.initialize();

        final patterns = newService.getLearningPatterns();
        expect(patterns['subject_counts']['math'], equals(1));
        expect(patterns['category_counts']['conceptual'], equals(1));

        newService.dispose();
      });
    });

    group('Privacy Compliance', () {
      setUp(() async {
        await analyticsService.initialize();
      });

      test('should provide privacy-compliant summary', () async {
        analyticsService.trackQuestionAnswered(
          subject: 'math',
          category: QuestionCategory.conceptual,
          difficulty: 'easy',
          isCorrect: true,
          responseTimeMs: 3000,
        );
        
        await analyticsService.endSession();

        final summary = analyticsService.getPrivacyCompliantSummary();
        
        expect(summary, containsPair('total_learning_time_hours', anything));
        expect(summary, containsPair('learning_streak_days', anything));
        expect(summary, containsPair('favorite_subjects', anything));
        expect(summary, containsPair('preferred_categories', anything));
        expect(summary, containsPair('learning_consistency', anything));
        
        // Should not contain raw event data or timestamps
        expect(summary, isNot(containsPair('events', anything)));
        expect(summary, isNot(containsPair('timestamps', anything)));
      });

      test('should export all data for user requests', () async {
        analyticsService.trackQuestionAnswered(
          subject: 'math',
          category: QuestionCategory.conceptual,
          difficulty: 'easy',
          isCorrect: true,
          responseTimeMs: 3000,
        );

        final exportData = analyticsService.exportData();
        
        expect(exportData, containsPair('engagement_metrics', anything));
        expect(exportData, containsPair('learning_patterns', anything));
        expect(exportData, containsPair('current_session', anything));
        expect(exportData, containsPair('export_timestamp', anything));
      });

      test('should clear all data for privacy compliance', () async {
        analyticsService.trackQuestionAnswered(
          subject: 'math',
          category: QuestionCategory.conceptual,
          difficulty: 'easy',
          isCorrect: true,
          responseTimeMs: 3000,
        );
        
        await analyticsService.endSession();
        await analyticsService.clearAllData();

        final engagement = analyticsService.getEngagementSummary();
        final patterns = analyticsService.getLearningPatterns();
        
        expect(engagement, isEmpty);
        expect(patterns, isEmpty);
      });
    });

    group('Performance and Edge Cases', () {
      setUp(() async {
        await analyticsService.initialize();
      });

      test('should handle rapid event tracking efficiently', () async {
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 100; i++) {
          analyticsService.trackQuestionAnswered(
            subject: 'math',
            category: QuestionCategory.conceptual,
            difficulty: 'easy',
            isCorrect: i % 2 == 0,
            responseTimeMs: 3000 + i,
          );
        }
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        
        final sessionInfo = analyticsService.getCurrentSessionInfo();
        expect(sessionInfo['events_count'], equals(100));
      });

      test('should handle empty subject preferences gracefully', () async {
        final preferences = analyticsService.getSubjectPreferences();
        expect(preferences, isEmpty);
      });

      test('should handle empty category preferences gracefully', () async {
        final preferences = analyticsService.getCategoryPreferences();
        expect(preferences, isEmpty);
      });

      test('should calculate consistency score correctly', () async {
        await analyticsService.endSession();
        
        final consistency = analyticsService.getLearningConsistency();
        expect(consistency['current_streak'], equals(1));
        expect(consistency['longest_streak'], equals(1));
        expect(consistency['total_sessions'], equals(1));
      });

      test('should handle session without events', () async {
        await analyticsService.endSession();
        
        final engagement = analyticsService.getEngagementSummary();
        expect(engagement['total_sessions'], equals(1));
        expect(engagement['event_counts'], isEmpty);
      });

      test('should handle multiple dispose calls safely', () async {
        analyticsService.dispose();
        analyticsService.dispose(); // Should not throw
      });
    });

    group('Consistency Score Calculation', () {
      setUp(() async {
        await analyticsService.initialize();
      });

      test('should return 0.0 for no sessions', () async {
        final summary = analyticsService.getPrivacyCompliantSummary();
        expect(summary['learning_consistency'], equals(0.0));
      });

      test('should calculate score based on streak and sessions', () async {
        // Simulate multiple sessions to build up data
        for (int i = 0; i < 5; i++) {
          analyticsService.trackQuestionAnswered(
            subject: 'math',
            category: QuestionCategory.conceptual,
            difficulty: 'easy',
            isCorrect: true,
            responseTimeMs: 3000,
          );
          await analyticsService.endSession();
          
          if (i < 4) {
            await analyticsService.initialize();
          }
        }

        final summary = analyticsService.getPrivacyCompliantSummary();
        expect(summary['learning_consistency'], greaterThan(0.0));
        expect(summary['learning_consistency'], lessThanOrEqualTo(1.0));
      });
    });
  });
}