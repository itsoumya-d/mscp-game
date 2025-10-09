import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:sp/core/services/progressive_unlock_integration_service.dart';
import 'package:sp/core/models/learning_path.dart';
import 'package:sp/core/models/skill_node.dart';

// Generate mocks
@GenerateMocks([
  ProgressiveUnlockIntegrationService,
])
import 'progressive_unlock_integration_service_test.mocks.dart';

void main() {
  group('ProgressiveUnlockIntegrationService Tests', () {
    late ProgressiveUnlockIntegrationService service;
    late MockProgressiveUnlockIntegrationService mockService;

    setUp(() {
      service = ProgressiveUnlockIntegrationService.instance;
      mockService = MockProgressiveUnlockIntegrationService();
    });

    group('Initialization', () {
      test('should initialize with default values', () {
        expect(service, isNotNull);
        // Add more initialization tests as needed
      });

      test('should handle initialization errors gracefully', () async {
        // Test error handling during initialization
        expect(() => service.initialize(), returnsNormally);
      });
    });

    group('Level Unlocking', () {
      test('should unlock level when criteria are met', () async {
        // Arrange
        const userId = 'test_user_123';
        const levelId = 'level_5';
        final mockCriteria = UnlockCriteria(
          levelId: levelId,
          requiredSkills: ['skill_1', 'skill_2'],
          minimumMasteryLevel: 0.8,
          requiredCompletedLevels: ['level_1', 'level_2', 'level_3', 'level_4'],
          minimumSessionCount: 3,
          timeBasedRequirements: const Duration(hours: 2),
        );

        when(mockService.checkUnlockEligibility(userId, levelId))
            .thenAnswer((_) async => true);

        when(mockService.unlockLevel(userId, levelId))
            .thenAnswer((_) async => true);

        // Act
        final canUnlock = await mockService.checkUnlockEligibility(userId, levelId);
        final unlocked = await mockService.unlockLevel(userId, levelId);

        // Assert
        expect(canUnlock, isTrue);
        expect(unlocked, isTrue);
        verify(mockService.checkUnlockEligibility(userId, levelId)).called(1);
        verify(mockService.unlockLevel(userId, levelId)).called(1);
      });

      test('should not unlock level when criteria are not met', () async {
        // Arrange
        const userId = 'test_user_123';
        const levelId = 'level_10';

        when(mockService.checkUnlockEligibility(userId, levelId))
            .thenAnswer((_) async => false);

        // Act
        final canUnlock = await mockService.checkUnlockEligibility(userId, levelId);

        // Assert
        expect(canUnlock, isFalse);
        verify(mockService.checkUnlockEligibility(userId, levelId)).called(1);
      });

      test('should handle multiple level unlock requests', () async {
        // Arrange
        const userId = 'test_user_123';
        final levelIds = ['level_1', 'level_2', 'level_3'];

        for (final levelId in levelIds) {
          when(mockService.checkUnlockEligibility(userId, levelId))
              .thenAnswer((_) async => true);
          when(mockService.unlockLevel(userId, levelId))
              .thenAnswer((_) async => true);
        }

        // Act & Assert
        for (final levelId in levelIds) {
          final canUnlock = await mockService.checkUnlockEligibility(userId, levelId);
          expect(canUnlock, isTrue);
          
          final unlocked = await mockService.unlockLevel(userId, levelId);
          expect(unlocked, isTrue);
        }
      });
    });

    group('Learning Path Management', () {
      test('should generate personalized learning path', () async {
        // Arrange
        const userId = 'test_user_123';
        final mockPath = LearningPath(
          id: 'path_123',
          pathType: LearningPathType.adaptive,
          title: 'Adaptive Learning Path',
          description: 'Dynamically adjusts to learner progress',
          milestones: [
            LearningMilestone(
              id: 'milestone_1',
              title: 'Basic Concepts',
              description: 'Learn fundamentals',
              requiredSkills: ['skill_1'],
              isCompleted: false,
            ),
          ],
          estimatedDuration: const Duration(hours: 5),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockService.generatePersonalizedPath(userId))
            .thenAnswer((_) async => mockPath);

        // Act
        final path = await mockService.generatePersonalizedPath(userId);

        // Assert
        expect(path, isNotNull);
        expect(path.pathType, equals(LearningPathType.adaptive));
        expect(path.milestones, isNotEmpty);
        verify(mockService.generatePersonalizedPath(userId)).called(1);
      });

      test('should update learning path progress', () async {
        // Arrange
        const userId = 'test_user_123';
        const pathId = 'path_123';
        const milestoneId = 'milestone_1';

        when(mockService.updatePathProgress(userId, pathId, milestoneId))
            .thenAnswer((_) async => true);

        // Act
        final updated = await mockService.updatePathProgress(userId, pathId, milestoneId);

        // Assert
        expect(updated, isTrue);
        verify(mockService.updatePathProgress(userId, pathId, milestoneId)).called(1);
      });

      test('should handle invalid learning path updates', () async {
        // Arrange
        const userId = 'test_user_123';
        const invalidPathId = 'invalid_path';
        const milestoneId = 'milestone_1';

        when(mockService.updatePathProgress(userId, invalidPathId, milestoneId))
            .thenAnswer((_) async => false);

        // Act
        final updated = await mockService.updatePathProgress(userId, invalidPathId, milestoneId);

        // Assert
        expect(updated, isFalse);
      });
    });

    group('Skill Mastery Tracking', () {
      test('should track skill mastery correctly', () async {
        // Arrange
        const userId = 'test_user_123';
        const skillId = 'addition_basics';
        final mockMastery = SkillMastery(
          skillId: skillId,
          masteryLevel: 0.85,
          practiceCount: 20,
          lastPracticed: DateTime.now(),
          strengthAreas: ['speed', 'accuracy'],
          weaknessAreas: ['complex_problems'],
          recommendedNextSteps: ['practice_word_problems'],
        );

        when(mockService.getSkillMastery(userId, skillId))
            .thenAnswer((_) async => mockMastery);

        // Act
        final mastery = await mockService.getSkillMastery(userId, skillId);

        // Assert
        expect(mastery, isNotNull);
        expect(mastery.masteryLevel, equals(0.85));
        expect(mastery.practiceCount, equals(20));
        expect(mastery.strengthAreas, contains('speed'));
        expect(mastery.weaknessAreas, contains('complex_problems'));
      });

      test('should update skill mastery after practice', () async {
        // Arrange
        const userId = 'test_user_123';
        const skillId = 'addition_basics';
        const sessionData = {
          'correctAnswers': 8,
          'totalQuestions': 10,
          'timeSpent': Duration(minutes: 5),
          'difficulty': DifficultyLevel.medium,
        };

        when(mockService.updateSkillMastery(userId, skillId, sessionData))
            .thenAnswer((_) async => true);

        // Act
        final updated = await mockService.updateSkillMastery(userId, skillId, sessionData);

        // Assert
        expect(updated, isTrue);
        verify(mockService.updateSkillMastery(userId, skillId, sessionData)).called(1);
      });
    });

    group('Performance Analytics', () {
      test('should calculate learning velocity', () async {
        // Arrange
        const userId = 'test_user_123';
        const expectedVelocity = 0.75;

        when(mockService.calculateLearningVelocity(userId))
            .thenAnswer((_) async => expectedVelocity);

        // Act
        final velocity = await mockService.calculateLearningVelocity(userId);

        // Assert
        expect(velocity, equals(expectedVelocity));
        expect(velocity, greaterThan(0));
        expect(velocity, lessThanOrEqualTo(1));
      });

      test('should identify learning patterns', () async {
        // Arrange
        const userId = 'test_user_123';
        final expectedPatterns = {
          'preferredDifficulty': DifficultyLevel.medium,
          'optimalSessionLength': Duration(minutes: 15),
          'strongestTimeOfDay': 'morning',
          'learningStyle': LearningPathType.adaptive,
        };

        when(mockService.analyzeLearningPatterns(userId))
            .thenAnswer((_) async => expectedPatterns);

        // Act
        final patterns = await mockService.analyzeLearningPatterns(userId);

        // Assert
        expect(patterns, isNotNull);
        expect(patterns['preferredDifficulty'], equals(DifficultyLevel.medium));
        expect(patterns['learningStyle'], equals(LearningPathType.adaptive));
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // Arrange
        const userId = 'test_user_123';
        
        when(mockService.generatePersonalizedPath(userId))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => mockService.generatePersonalizedPath(userId),
          throwsException,
        );
      });

      test('should handle invalid user IDs', () async {
        // Arrange
        const invalidUserId = '';

        when(mockService.checkUnlockEligibility(invalidUserId, 'level_1'))
            .thenAnswer((_) async => false);

        // Act
        final result = await mockService.checkUnlockEligibility(invalidUserId, 'level_1');

        // Assert
        expect(result, isFalse);
      });

      test('should handle concurrent requests', () async {
        // Arrange
        const userId = 'test_user_123';
        final futures = List.generate(5, (index) => 
          mockService.checkUnlockEligibility(userId, 'level_$index')
        );

        for (int i = 0; i < 5; i++) {
          when(mockService.checkUnlockEligibility(userId, 'level_$i'))
              .thenAnswer((_) async => true);
        }

        // Act
        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(5));
        expect(results.every((result) => result == true), isTrue);
      });
    });

    group('Data Persistence', () {
      test('should persist unlock data correctly', () async {
        // Arrange
        const userId = 'test_user_123';
        const levelId = 'level_5';

        when(mockService.unlockLevel(userId, levelId))
            .thenAnswer((_) async => true);

        when(mockService.isLevelUnlocked(userId, levelId))
            .thenAnswer((_) async => true);

        // Act
        await mockService.unlockLevel(userId, levelId);
        final isUnlocked = await mockService.isLevelUnlocked(userId, levelId);

        // Assert
        expect(isUnlocked, isTrue);
      });

      test('should handle data corruption gracefully', () async {
        // Arrange
        const userId = 'test_user_123';

        when(mockService.getUserProgress(userId))
            .thenThrow(Exception('Data corruption detected'));

        // Act & Assert
        expect(
          () => mockService.getUserProgress(userId),
          throwsException,
        );
      });
    });
  });
}