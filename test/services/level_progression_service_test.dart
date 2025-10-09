import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/core/services/level_progression_service.dart';
import '../../lib/core/models/subject.dart';

void main() {
  group('LevelProgressionService Tests', () {
    late LevelProgressionService service;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      service = LevelProgressionService.getInstance();
    });

    group('Level Unlocking', () {
      test('should have level 1 unlocked by default', () async {
        final isUnlocked = await service.isLevelUnlocked(
          subject: SubjectType.math,
          level: 1,
        );
        expect(isUnlocked, true);
      });

      test('should not have level 2 unlocked by default', () async {
        final isUnlocked = await service.isLevelUnlocked(
          subject: SubjectType.math,
          level: 2,
        );
        expect(isUnlocked, false);
      });

      test('should return highest unlocked level correctly', () async {
        final highestLevel = await service.getHighestUnlockedLevel(
          subject: SubjectType.math,
        );
        expect(highestLevel, 1);
      });
    });

    group('Game Completion and Progression', () {
      test('should record game completion and award XP', () async {
        final result = await service.recordGameCompletion(
          subject: SubjectType.math,
          level: 1,
          accuracy: 0.8,
          score: 100,
          totalTime: 60,
        );

        expect(result['xpAwarded'], greaterThan(0));
        expect(result['currentXP'], greaterThan(0));
        expect(result['currentPlayerLevel'], greaterThanOrEqualTo(1));
        expect(result['canProgress'], true);
      });

      test('should not allow progression with low accuracy', () async {
        final result = await service.recordGameCompletion(
          subject: SubjectType.math,
          level: 1,
          accuracy: 0.5, // Below 70% threshold
          score: 50,
          totalTime: 120,
        );

        expect(result['canProgress'], false);
      });

      test('should unlock next level after meeting requirements', () async {
        // Play multiple games with good accuracy to meet requirements
        for (int i = 0; i < 5; i++) {
          await service.recordGameCompletion(
            subject: SubjectType.math,
            level: 1,
            accuracy: 0.85,
            score: 100,
            totalTime: 60,
          );
        }

        final highestLevel = await service.getHighestUnlockedLevel(
          subject: SubjectType.math,
        );
        
        // Should unlock level 2 after meeting XP and performance requirements
        expect(highestLevel, greaterThanOrEqualTo(2));
      });
    });

    group('XP System', () {
      test('should award XP correctly', () async {
        await service.awardXP(
          subject: SubjectType.math,
          skillId: 'algebra',
          accuracy: 0.9,
          gamesPlayed: 1,
        );

        final currentXP = await service.getCurrentXP(
          subject: SubjectType.math,
          skillId: 'algebra',
        );

        expect(currentXP, greaterThan(0));
      });

      test('should track XP separately for different subjects and skills', () async {
        await service.awardXP(
          subject: SubjectType.math,
          skillId: 'algebra',
          accuracy: 0.9,
          gamesPlayed: 1,
        );

        await service.awardXP(
          subject: SubjectType.physics,
          skillId: 'mechanics',
          accuracy: 0.8,
          gamesPlayed: 1,
        );

        final mathXP = await service.getCurrentXP(
          subject: SubjectType.math,
          skillId: 'algebra',
        );

        final physicsXP = await service.getCurrentXP(
          subject: SubjectType.physics,
          skillId: 'mechanics',
        );

        expect(mathXP, greaterThan(0));
        expect(physicsXP, greaterThan(0));
        expect(mathXP, isNot(equals(physicsXP)));
      });
    });

    group('Performance Analytics', () {
      test('should track performance analytics correctly', () async {
        // Record multiple game sessions
        await service.recordGameCompletion(
          subject: SubjectType.math,
          level: 1,
          accuracy: 0.8,
          score: 80,
          totalTime: 60,
        );

        await service.recordGameCompletion(
          subject: SubjectType.math,
          level: 1,
          accuracy: 0.9,
          score: 90,
          totalTime: 50,
        );

        final analytics = await service.getPerformanceAnalytics(
          subject: SubjectType.math,
        );

        expect(analytics['gamesPlayed'], 2);
        expect(analytics['averageAccuracy'], closeTo(0.85, 0.01));
        expect(analytics['averageScore'], closeTo(85.0, 0.1));
        expect(analytics['totalTime'], 110);
      });
    });

    group('Level Recommendations', () {
      test('should provide appropriate level recommendations', () async {
        // Record some games to build performance history
        for (int i = 0; i < 3; i++) {
          await service.recordGameCompletion(
            subject: SubjectType.math,
            level: 1,
            accuracy: 0.85,
            score: 85,
            totalTime: 60,
          );
        }

        final recommendation = await service.getRecommendedNextLevel(
          subject: SubjectType.math,
        );

        expect(recommendation['recommendedLevel'], greaterThanOrEqualTo(1));
        expect(recommendation['recommendation'], isA<String>());
        expect(recommendation['currentLevel'], greaterThanOrEqualTo(1));
        expect(recommendation['canProgress'], true);
      });

      test('should recommend practice for poor performance', () async {
        // Record games with poor accuracy
        for (int i = 0; i < 3; i++) {
          await service.recordGameCompletion(
            subject: SubjectType.math,
            level: 1,
            accuracy: 0.5, // Below threshold
            score: 50,
            totalTime: 120,
          );
        }

        final recommendation = await service.getRecommendedNextLevel(
          subject: SubjectType.math,
        );

        expect(recommendation['canProgress'], false);
        expect(recommendation['recommendation'], contains('Practice'));
      });
    });

    group('Level Unlock Checks', () {
      test('should check and return newly unlocked levels', () async {
        // Build up performance to unlock new levels
        for (int i = 0; i < 5; i++) {
          await service.recordGameCompletion(
            subject: SubjectType.math,
            level: 1,
            accuracy: 0.9,
            score: 90,
            totalTime: 45,
            skillId: 'algebra',
          );
        }

        final unlockedLevels = await service.checkLevelUnlocks(
          subject: SubjectType.math,
          skillId: 'algebra',
        );

        expect(unlockedLevels, isA<List<int>>());
      });

      test('should provide detailed next level recommendations', () async {
        final recommendation = await service.getNextLevelRecommendation(
          subject: SubjectType.math,
          skillId: 'algebra',
        );

        expect(recommendation, isA<Map<String, dynamic>>());
        expect(recommendation.containsKey('recommendedLevel'), true);
        expect(recommendation.containsKey('recommendation'), true);
        expect(recommendation.containsKey('currentLevel'), true);
        expect(recommendation.containsKey('canProgress'), true);
      });
    });

    group('Edge Cases', () {
      test('should handle missing data gracefully', () async {
        final analytics = await service.getPerformanceAnalytics(
          subject: SubjectType.chemistry,
          skillId: 'nonexistent',
        );

        expect(analytics['gamesPlayed'], 0);
        expect(analytics['averageAccuracy'], 0.0);
        expect(analytics['averageScore'], 0.0);
        expect(analytics['totalTime'], 0);
      });

      test('should handle level bounds correctly', () async {
        final isLevel0Unlocked = await service.isLevelUnlocked(
          subject: SubjectType.math,
          level: 0,
        );
        expect(isLevel0Unlocked, false);

        final isLevel11Unlocked = await service.isLevelUnlocked(
          subject: SubjectType.math,
          level: 11,
        );
        expect(isLevel11Unlocked, false);
      });
    });
  });
}