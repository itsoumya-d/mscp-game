import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';

import 'package:sp/main.dart' as app;
import 'package:sp/features/progressive_unlock/services/progressive_unlock_integration_service.dart';
import 'package:sp/features/progressive_unlock/services/adaptive_difficulty_calculator.dart';
import 'package:sp/core/services/personalized_path_generator.dart';
import 'package:sp/core/models/learning_path.dart';
import 'package:sp/features/progressive_unlock/models/difficulty_level.dart';
import 'package:sp/features/progressive_unlock/models/skill_mastery.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Progressive Unlock System Integration Tests', () {
    late ProgressiveUnlockIntegrationService progressiveService;
    late AdaptiveDifficultyCalculator difficultyCalculator;
    late PersonalizedPathGenerator pathGenerator;

    setUpAll(() async {
      // Initialize services
      progressiveService = ProgressiveUnlockIntegrationService();
      difficultyCalculator = AdaptiveDifficultyCalculator();
      pathGenerator = PersonalizedPathGenerator();
      
      // Initialize the services
      await progressiveService.initialize();
      await difficultyCalculator.initialize();
    });

    tearDownAll(() async {
      // Clean up services
      await progressiveService.dispose();
      await difficultyCalculator.dispose();
    });

    testWidgets('Complete user journey: registration to skill mastery', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Test user registration and initial setup
      await _testUserRegistration(tester);
      
      // Test initial learning path generation
      await _testInitialPathGeneration(tester);
      
      // Test adaptive difficulty in game session
      await _testAdaptiveDifficultyInGame(tester);
      
      // Test skill mastery progression
      await _testSkillMasteryProgression(tester);
      
      // Test level unlocking
      await _testLevelUnlocking(tester);
    });

    testWidgets('Adaptive difficulty system integration', (tester) async {
      const userId = 'integration_test_user_1';
      
      // Initialize user performance tracking
      await difficultyCalculator.initializeUserPerformance(userId);
      
      // Simulate a series of correct answers
      for (int i = 0; i < 5; i++) {
        await difficultyCalculator.recordQuestionPerformance(
          userId,
          questionId: 'question_$i',
          isCorrect: true,
          responseTime: const Duration(seconds: 2),
          currentDifficulty: DifficultyLevel.easy,
        );
      }
      
      // Check that difficulty increased
      final newDifficulty = await difficultyCalculator.calculateAdaptiveDifficulty(userId);
      expect(newDifficulty, equals(DifficultyLevel.medium));
      
      // Simulate some incorrect answers
      for (int i = 0; i < 3; i++) {
        await difficultyCalculator.recordQuestionPerformance(
          userId,
          questionId: 'question_${i + 5}',
          isCorrect: false,
          responseTime: const Duration(seconds: 8),
          currentDifficulty: DifficultyLevel.medium,
        );
      }
      
      // Check that difficulty adjusted appropriately
      final adjustedDifficulty = await difficultyCalculator.calculateAdaptiveDifficulty(userId);
      expect(adjustedDifficulty, isIn([DifficultyLevel.easy, DifficultyLevel.medium]));
    });

    testWidgets('Learning path personalization integration', (tester) async {
      const userId = 'integration_test_user_2';
      
      // Generate initial learning path
      final learningStyle = await pathGenerator.detectLearningStyle(userId);
      final personalizedPath = await pathGenerator.generatePersonalizedPath(userId, learningStyle);
      
      expect(personalizedPath, isNotNull);
      expect(personalizedPath.milestones, isNotEmpty);
      
      // Simulate skill mastery progress
      final skillMasteries = [
        SkillMastery(
          skillId: 'basic_math',
          masteryLevel: 0.8,
          practiceCount: 25,
          lastPracticed: DateTime.now(),
          strengthAreas: ['addition', 'subtraction'],
          weaknessAreas: ['multiplication'],
          recommendedNextSteps: ['practice_multiplication'],
        ),
      ];
      
      // Customize path based on skill mastery
      final customizedPath = await pathGenerator.customizePathForSkillLevel(userId, skillMasteries);
      
      expect(customizedPath, isNotNull);
      expect(customizedPath.id, isNot(equals(personalizedPath.id)));
    });

    testWidgets('Progressive unlock service integration', (tester) async {
      const userId = 'integration_test_user_3';
      
      // Initialize user in progressive unlock system
      await progressiveService.initializeUser(userId);
      
      // Check initial unlocked levels
      final initialLevels = await progressiveService.getUnlockedLevels(userId);
      expect(initialLevels, isNotEmpty);
      
      // Simulate completing a level
      await progressiveService.recordLevelCompletion(
        userId,
        levelId: initialLevels.first,
        score: 85,
        timeSpent: const Duration(minutes: 5),
        skillsUsed: ['basic_math', 'problem_solving'],
      );
      
      // Check if new levels were unlocked
      final updatedLevels = await progressiveService.getUnlockedLevels(userId);
      expect(updatedLevels.length, greaterThan(initialLevels.length));
      
      // Check skill mastery update
      final skillMastery = await progressiveService.getSkillMastery(userId, 'basic_math');
      expect(skillMastery, isNotNull);
      expect(skillMastery!.practiceCount, greaterThan(0));
    });

    testWidgets('Cross-service data synchronization', (tester) async {
      const userId = 'integration_test_user_4';
      
      // Initialize all services for the user
      await progressiveService.initializeUser(userId);
      await difficultyCalculator.initializeUserPerformance(userId);
      
      // Record performance in difficulty calculator
      await difficultyCalculator.recordQuestionPerformance(
        userId,
        questionId: 'sync_test_question',
        isCorrect: true,
        responseTime: const Duration(seconds: 3),
        currentDifficulty: DifficultyLevel.medium,
      );
      
      // Record level completion in progressive service
      await progressiveService.recordLevelCompletion(
        userId,
        levelId: 'sync_test_level',
        score: 90,
        timeSpent: const Duration(minutes: 3),
        skillsUsed: ['pattern_recognition'],
      );
      
      // Verify data consistency across services
      final performanceAnalytics = await difficultyCalculator.getPerformanceAnalytics(userId);
      final skillMastery = await progressiveService.getSkillMastery(userId, 'pattern_recognition');
      
      expect(performanceAnalytics, isNotNull);
      expect(skillMastery, isNotNull);
      expect(performanceAnalytics['total_questions'], greaterThan(0));
      expect(skillMastery!.practiceCount, greaterThan(0));
    });

    testWidgets('Performance under load', (tester) async {
      const int userCount = 10;
      const int operationsPerUser = 20;
      
      final stopwatch = Stopwatch()..start();
      
      // Simulate multiple users performing operations concurrently
      final futures = <Future>[];
      
      for (int userId = 0; userId < userCount; userId++) {
        futures.add(_simulateUserActivity('load_test_user_$userId', operationsPerUser));
      }
      
      await Future.wait(futures);
      
      stopwatch.stop();
      
      // Verify performance is acceptable (should complete within reasonable time)
      expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // 30 seconds max
      
      // Verify all users have data
      for (int userId = 0; userId < userCount; userId++) {
        final unlockedLevels = await progressiveService.getUnlockedLevels('load_test_user_$userId');
        expect(unlockedLevels, isNotEmpty);
      }
    });

    testWidgets('Error recovery and data consistency', (tester) async {
      const userId = 'error_test_user';
      
      // Initialize user
      await progressiveService.initializeUser(userId);
      
      // Simulate network interruption during level completion
      try {
        await progressiveService.recordLevelCompletion(
          userId,
          levelId: 'invalid_level_id',
          score: 100,
          timeSpent: const Duration(minutes: 5),
          skillsUsed: ['invalid_skill'],
        );
      } catch (e) {
        // Expected to fail
      }
      
      // Verify system is still functional
      final unlockedLevels = await progressiveService.getUnlockedLevels(userId);
      expect(unlockedLevels, isNotEmpty);
      
      // Verify valid operations still work
      await progressiveService.recordLevelCompletion(
        userId,
        levelId: unlockedLevels.first,
        score: 75,
        timeSpent: const Duration(minutes: 4),
        skillsUsed: ['basic_math'],
      );
      
      final skillMastery = await progressiveService.getSkillMastery(userId, 'basic_math');
      expect(skillMastery, isNotNull);
    });

    testWidgets('Real-time updates and notifications', (tester) async {
      const userId = 'realtime_test_user';
      
      // Initialize user and start listening for updates
      await progressiveService.initializeUser(userId);
      
      final updates = <String>[];
      progressiveService.onLevelUnlocked.listen((levelId) {
        updates.add('unlocked:$levelId');
      });
      
      progressiveService.onSkillMasteryUpdated.listen((skillId) {
        updates.add('skill:$skillId');
      });
      
      // Perform actions that should trigger updates
      final initialLevels = await progressiveService.getUnlockedLevels(userId);
      await progressiveService.recordLevelCompletion(
        userId,
        levelId: initialLevels.first,
        score: 95,
        timeSpent: const Duration(minutes: 3),
        skillsUsed: ['math_basics', 'logic'],
      );
      
      // Wait for async updates
      await tester.pump(const Duration(milliseconds: 500));
      
      // Verify updates were received
      expect(updates, isNotEmpty);
      expect(updates.any((update) => update.startsWith('skill:')), isTrue);
    });
  });

  // Helper methods for integration tests
  Future<void> _testUserRegistration(WidgetTester tester) async {
    // Navigate to registration screen
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    
    // Fill registration form
    await tester.enterText(find.byKey(const Key('username_field')), 'integration_test_user');
    await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
    
    // Submit registration
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    
    // Verify successful registration
    expect(find.text('Welcome'), findsOneWidget);
  }

  Future<void> _testInitialPathGeneration(WidgetTester tester) async {
    // Navigate to learning path setup
    await tester.tap(find.text('Set Up Learning Path'));
    await tester.pumpAndSettle();
    
    // Complete learning style assessment
    await tester.tap(find.text('Visual Learner'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    
    // Verify path was generated
    expect(find.text('Your Learning Path'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  }

  Future<void> _testAdaptiveDifficultyInGame(WidgetTester tester) async {
    // Navigate to game session
    await tester.tap(find.text('Start Learning'));
    await tester.pumpAndSettle();
    
    // Answer several questions correctly
    for (int i = 0; i < 3; i++) {
      await tester.tap(find.text('Answer A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    
    // Verify adaptive difficulty indicator appears
    expect(find.text('ADAPTIVE'), findsOneWidget);
  }

  Future<void> _testSkillMasteryProgression(WidgetTester tester) async {
    // Continue answering questions to build skill mastery
    for (int i = 0; i < 5; i++) {
      await tester.tap(find.text('Answer A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    
    // Check skill progress
    await tester.tap(find.byIcon(Icons.assessment));
    await tester.pumpAndSettle();
    
    // Verify skill mastery is tracked
    expect(find.textContaining('Mastery'), findsOneWidget);
  }

  Future<void> _testLevelUnlocking(WidgetTester tester) async {
    // Complete current level
    await tester.tap(find.text('Complete Level'));
    await tester.pumpAndSettle();
    
    // Verify level completion celebration
    expect(find.text('Level Complete!'), findsOneWidget);
    
    // Check if new levels are unlocked
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    
    // Verify new levels are available
    expect(find.text('New Level Unlocked!'), findsOneWidget);
  }

  Future<void> _simulateUserActivity(String userId, int operationCount) async {
    // Initialize user
    final progressiveService = ProgressiveUnlockIntegrationService();
    final difficultyCalculator = AdaptiveDifficultyCalculator();
    
    await progressiveService.initializeUser(userId);
    await difficultyCalculator.initializeUserPerformance(userId);
    
    // Perform multiple operations
    for (int i = 0; i < operationCount; i++) {
      // Record question performance
      await difficultyCalculator.recordQuestionPerformance(
        userId,
        questionId: 'question_${userId}_$i',
        isCorrect: i % 3 != 0, // 2/3 correct rate
        responseTime: Duration(seconds: 2 + (i % 5)),
        currentDifficulty: DifficultyLevel.medium,
      );
      
      // Occasionally complete a level
      if (i % 5 == 0) {
        final unlockedLevels = await progressiveService.getUnlockedLevels(userId);
        if (unlockedLevels.isNotEmpty) {
          await progressiveService.recordLevelCompletion(
            userId,
            levelId: unlockedLevels.first,
            score: 70 + (i % 30),
            timeSpent: Duration(minutes: 3 + (i % 5)),
            skillsUsed: ['skill_${i % 3}'],
          );
        }
      }
    }
  }
}