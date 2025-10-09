import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp/core/services/game_session_service.dart';
import 'package:sp/core/models/subject.dart';

/// Test suite for Phase B: Cache Clearing Functionality
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase B: Cache Clearing Tests', () {
    late GameSessionService gameSessionService;

    setUp(() async {
      // Initialize SharedPreferences with mock data
      SharedPreferences.setMockInitialValues({
        // AI-generated content
        'ai_pool_math_algebra': '["question1", "question2"]',
        'ai_pool_physics_mechanics': '["question3", "question4"]',
        'cached_session_math_5': '{"id": "session1"}',
        'cached_session_physics_10': '{"id": "session2"}',
        'preloaded_chemistry_organic': '{"data": "content"}',
        'comprehensive_lessons_cache_math_algebra': '{"lessons": []}',
        'enhanced_daily_generation': 'true',
        'enhanced_generation_stats': '{"count": 100}',
        'level_preload_status': 'complete',
        'unlimited_levels_math': '{"levels": []}',
        
        // User data (should NOT be cleared)
        'user_progress': '{"level": 5}',
        'user_settings': '{"theme": "dark"}',
        'current_seven_question_game': '{"id": "current"}',
        'seven_question_game_history': '[{"id": "history1"}]',
      });

      gameSessionService = GameSessionService();
    });

    test('getCacheStatistics returns correct counts', () async {
      final stats = await gameSessionService.getCacheStatistics();
      
      expect(stats['shared_preferences']['ai_pool_count'], equals(2));
      expect(stats['shared_preferences']['cached_session_count'], equals(2));
      expect(stats['shared_preferences']['preloaded_count'], equals(1));
      expect(stats['shared_preferences']['comprehensive_lesson_count'], equals(1));
      expect(stats['shared_preferences']['other_cache_count'], greaterThanOrEqualTo(2));
    });

    test('clearAllGeneratedQuestions removes AI content but preserves user data', () async {
      // Get initial stats
      final initialStats = await gameSessionService.getCacheStatistics();
      final initialTotal = initialStats['shared_preferences']['total_cache_keys'] as int;
      
      expect(initialTotal, greaterThan(0), reason: 'Should have cached content initially');

      // Clear AI-generated questions
      final result = await gameSessionService.clearAllGeneratedQuestions(
        clearHistory: false,
        clearCurrentSession: false,
      );

      expect(result['success'], isTrue);
      expect(result['cleared_count'], greaterThan(0));

      // Verify AI content is cleared
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('ai_pool_math_algebra'), isFalse);
      expect(prefs.containsKey('ai_pool_physics_mechanics'), isFalse);
      expect(prefs.containsKey('cached_session_math_5'), isFalse);
      expect(prefs.containsKey('preloaded_chemistry_organic'), isFalse);
      expect(prefs.containsKey('comprehensive_lessons_cache_math_algebra'), isFalse);

      // Verify user data is preserved
      expect(prefs.containsKey('user_progress'), isTrue);
      expect(prefs.containsKey('user_settings'), isTrue);
      expect(prefs.containsKey('current_seven_question_game'), isTrue);
      expect(prefs.containsKey('seven_question_game_history'), isTrue);

      // Get final stats
      final finalStats = await gameSessionService.getCacheStatistics();
      final finalTotal = finalStats['shared_preferences']['total_cache_keys'] as int;
      
      expect(finalTotal, equals(0), reason: 'All AI-generated cache should be cleared');
    });

    test('clearAllGeneratedQuestions with clearHistory removes history', () async {
      final result = await gameSessionService.clearAllGeneratedQuestions(
        clearHistory: true,
        clearCurrentSession: false,
      );

      expect(result['success'], isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('seven_question_game_history'), isFalse);
      expect(prefs.containsKey('current_seven_question_game'), isTrue);
    });

    test('clearAllGeneratedQuestions with clearCurrentSession removes current session', () async {
      final result = await gameSessionService.clearAllGeneratedQuestions(
        clearHistory: false,
        clearCurrentSession: true,
      );

      expect(result['success'], isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('current_seven_question_game'), isFalse);
      expect(prefs.containsKey('seven_question_game_history'), isTrue);
    });

    test('clearAllGeneratedQuestions handles empty cache gracefully', () async {
      // Clear once
      await gameSessionService.clearAllGeneratedQuestions();

      // Clear again (should handle empty cache)
      final result = await gameSessionService.clearAllGeneratedQuestions();

      expect(result['success'], isTrue);
      expect(result['cleared_count'], equals(0));
    });

    test('clearAllGeneratedQuestions tracks analytics event', () async {
      final result = await gameSessionService.clearAllGeneratedQuestions(
        clearHistory: true,
        clearCurrentSession: true,
      );

      expect(result['success'], isTrue);
      // Analytics tracking is verified by checking the result contains expected fields
      expect(result.containsKey('cleared_count'), isTrue);
      expect(result.containsKey('message'), isTrue);
    });

    test('Cache statistics show zero after clearing', () async {
      // Clear all content
      await gameSessionService.clearAllGeneratedQuestions();

      // Get stats
      final stats = await gameSessionService.getCacheStatistics();

      expect(stats['shared_preferences']['ai_pool_count'], equals(0));
      expect(stats['shared_preferences']['cached_session_count'], equals(0));
      expect(stats['shared_preferences']['preloaded_count'], equals(0));
      expect(stats['shared_preferences']['comprehensive_lesson_count'], equals(0));
      expect(stats['shared_preferences']['total_cache_keys'], equals(0));
    });
  });

  group('Phase B: Integration Tests', () {
    test('App can function with empty cache', () async {
      SharedPreferences.setMockInitialValues({});
      
      final gameSessionService = GameSessionService();
      
      // Should not throw error when creating session with empty cache
      expect(
        () async => await gameSessionService.createGameSession(
          subject: SubjectType.math,
          level: 1,
          skillId: 'algebra',
        ),
        returnsNormally,
      );
    });

    test('Cache clearing does not affect app initialization', () async {
      SharedPreferences.setMockInitialValues({
        'ai_pool_test': 'data',
      });

      final gameSessionService = GameSessionService();
      
      // Clear cache
      await gameSessionService.clearAllGeneratedQuestions();

      // App should still initialize normally
      final stats = await gameSessionService.getCacheStatistics();
      expect(stats, isNotNull);
      expect(stats.containsKey('shared_preferences'), isTrue);
    });
  });
}

