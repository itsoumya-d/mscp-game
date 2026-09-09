import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/models/question_pool.dart';
import 'package:sp/core/services/progressive_difficulty_enhanced_service.dart';
import 'package:sp/core/services/question_pool_service.dart';

void main() {
  group('ProgressiveDifficultyEnhancedService Tests', () {
    late ProgressiveDifficultyEnhancedService service;
    late QuestionPoolService questionPoolService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      questionPoolService = QuestionPoolService();
      await questionPoolService.initialize();
      
      service = ProgressiveDifficultyEnhancedService();
      await service.initialize();
    });

    group('Initialization Tests', () {
      test('should initialize with default difficulty profile', () async {
        expect(service.difficultyProfile, isNotNull);
        expect(service.difficultyProfile!.subjectProfiles, isNotNull);
      });

      test('should create default profiles for new subjects', () async {
        final recommendation = await service.calculateOptimalDifficulty(
          SubjectType.math,
          'new_skill',
        );

        expect(recommendation, isNotNull);
        expect(recommendation.difficulty, greaterThan(0));
        expect(recommendation.difficulty, lessThanOrEqualTo(5.0));
      });
    });

    group('Difficulty Calculation Tests', () {
      test('should calculate appropriate difficulty for high performance', () async {
        final baseline = await service.calculateOptimalDifficulty(
          SubjectType.math,
          'test_skill',
        );

        // Record high performance
        final highPerformanceRecord = PerformanceRecord(
          subject: SubjectType.math,
          skillId: 'test_skill',
          category: QuestionCategory.computational,
          accuracy: 0.95,
          difficulty: 2.0,
          averageResponseTime: const Duration(seconds: 8),
          timestamp: DateTime.now(),
          questionsAnswered: 10,
          correctAnswers: 9,
        );

        await service.recordPerformance(highPerformanceRecord);

        final recommendation = await service.calculateOptimalDifficulty(
          SubjectType.math,
          'test_skill',
        );

        expect(recommendation.difficulty, greaterThan(baseline.difficulty), 
            reason: 'High performance should increase difficulty');
        expect(recommendation.confidence, greaterThan(0.5));
      });

      test('should calculate appropriate difficulty for low performance', () async {
        // Record low performance
        final lowPerformanceRecord = PerformanceRecord(
          subject: SubjectType.physics,
          skillId: 'mechanics',
          category: QuestionCategory.analytical,
          accuracy: 0.35,
          difficulty: 3.0,
          averageResponseTime: const Duration(seconds: 45),
          timestamp: DateTime.now(),
          questionsAnswered: 10,
          correctAnswers: 3,
        );

        await service.recordPerformance(lowPerformanceRecord);

        final recommendation = await service.calculateOptimalDifficulty(
          SubjectType.physics,
          'mechanics',
        );

        expect(recommendation.difficulty, lessThan(3.0), 
            reason: 'Low performance should decrease difficulty');
        expect(recommendation.reasoning, contains('Lower accuracy'));
      });

      test('should handle consistent performance appropriately', () async {
        // Record multiple consistent performances
        for (int i = 0; i < 5; i++) {
          final consistentRecord = PerformanceRecord(
            subject: SubjectType.chemistry,
            skillId: 'periodic_table',
            category: QuestionCategory.factual,
            accuracy: 0.75,
            difficulty: 2.5,
            averageResponseTime: const Duration(seconds: 15),
            timestamp: DateTime.now().subtract(Duration(days: i)),
            questionsAnswered: 8,
            correctAnswers: 6,
          );

          await service.recordPerformance(consistentRecord);
        }

        final recommendation = await service.calculateOptimalDifficulty(
          SubjectType.chemistry,
          'periodic_table',
        );

        expect(recommendation.confidence, greaterThan(0.7), 
            reason: 'Consistent performance should increase confidence');
        expect(recommendation.reasoning, contains('Consistent'));
      });
    });

    group('Category Recommendation Tests', () {
      test('should recommend appropriate categories for difficulty level', () async {
        // Test low difficulty recommendations
        final lowDifficultyRec = await service.calculateOptimalDifficulty(
          SubjectType.biology,
          'basic_concepts',
        );

        expect(lowDifficultyRec.categories, isNotEmpty);
        expect(lowDifficultyRec.categories, 
            anyElement(isIn([QuestionCategory.factual, QuestionCategory.conceptual])),
            reason: 'Low difficulty should include basic categories');

        final baseline = await service.calculateOptimalDifficulty(
          SubjectType.biology,
          'advanced_concepts',
        );

        // Record high performance to increase difficulty
        for (int i = 0; i < 3; i++) {
          await service.recordPerformance(PerformanceRecord(
            subject: SubjectType.biology,
            skillId: 'advanced_concepts',
            accuracy: 0.9,
            difficulty: 4.0,
            averageResponseTime: const Duration(seconds: 10),
            timestamp: DateTime.now().subtract(Duration(hours: i)),
            questionsAnswered: 10,
            correctAnswers: 9,
          ));
        }

        final highDifficultyRec = await service.calculateOptimalDifficulty(
          SubjectType.biology,
          'advanced_concepts',
        );

        expect(highDifficultyRec.difficulty, greaterThan(baseline.difficulty));
        expect(highDifficultyRec.categories, isNotEmpty);
      });

      test('should include weak categories for improvement', () async {
        // Record poor performance in specific category
        final weakCategoryRecord = PerformanceRecord(
          subject: SubjectType.math,
          skillId: 'algebra',
          category: QuestionCategory.analytical,
          accuracy: 0.4,
          difficulty: 2.0,
          averageResponseTime: const Duration(seconds: 30),
          timestamp: DateTime.now(),
          questionsAnswered: 10,
          correctAnswers: 4,
        );

        await service.recordPerformance(weakCategoryRecord);

        final recommendation = await service.calculateOptimalDifficulty(
          SubjectType.math,
          'algebra',
        );

        expect(recommendation.categories, contains(QuestionCategory.analytical),
            reason: 'Weak categories should be included for improvement');
      });
    });

    group('Performance Analysis Tests', () {
      test('should analyze trends correctly', () async {
        final baseline = await service.calculateOptimalDifficulty(
          SubjectType.geography,
          'world_capitals',
        );

        // Record improving trend
        final accuracies = [0.5, 0.6, 0.7, 0.8, 0.85];
        for (int i = 0; i < accuracies.length; i++) {
          await service.recordPerformance(PerformanceRecord(
            subject: SubjectType.geography,
            skillId: 'world_capitals',
            accuracy: accuracies[i],
            difficulty: 2.0,
            averageResponseTime: const Duration(seconds: 20),
            timestamp: DateTime.now().subtract(Duration(days: accuracies.length - i)),
            questionsAnswered: 10,
            correctAnswers: (accuracies[i] * 10).round(),
          ));
        }

        final recommendation = await service.calculateOptimalDifficulty(
          SubjectType.geography,
          'world_capitals',
        );

        expect(recommendation.reasoning.toLowerCase(), contains('improving'),
            reason: 'Should detect improving trend');
        expect(recommendation.difficulty, greaterThan(baseline.difficulty),
            reason: 'Improving trend should increase difficulty');
      });

      test('should handle declining performance', () async {
        // Record declining trend
        final accuracies = [0.85, 0.75, 0.65, 0.55, 0.45];
        for (int i = 0; i < accuracies.length; i++) {
          await service.recordPerformance(PerformanceRecord(
            subject: SubjectType.history,
            skillId: 'ancient_civilizations',
            accuracy: accuracies[i],
            difficulty: 3.0,
            averageResponseTime: const Duration(seconds: 25),
            timestamp: DateTime.now().subtract(Duration(days: accuracies.length - i)),
            questionsAnswered: 10,
            correctAnswers: (accuracies[i] * 10).round(),
          ));
        }

        final recommendation = await service.calculateOptimalDifficulty(
          SubjectType.history,
          'ancient_civilizations',
        );

        expect(recommendation.reasoning.toLowerCase(), contains('declining'),
            reason: 'Should detect declining trend');
        expect(recommendation.difficulty, lessThan(3.0),
            reason: 'Declining trend should decrease difficulty');
      });
    });

    group('Adaptive Factors Tests', () {
      test('should consider response time in difficulty calculation', () async {
        // Record fast responses (indicating readiness for harder questions)
        await service.recordPerformance(PerformanceRecord(
          subject: SubjectType.computerScience,
          skillId: 'algorithms',
          accuracy: 0.8,
          difficulty: 2.0,
          averageResponseTime: const Duration(seconds: 5), // Very fast
          timestamp: DateTime.now(),
          questionsAnswered: 10,
          correctAnswers: 8,
        ));

        final fastResponseRec = await service.calculateOptimalDifficulty(
          SubjectType.computerScience,
          'algorithms',
        );

        // Record slow responses
        await service.recordPerformance(PerformanceRecord(
          subject: SubjectType.computerScience,
          skillId: 'data_structures',
          accuracy: 0.8,
          difficulty: 2.0,
          averageResponseTime: const Duration(seconds: 60), // Very slow
          timestamp: DateTime.now(),
          questionsAnswered: 10,
          correctAnswers: 8,
        ));

        final slowResponseRec = await service.calculateOptimalDifficulty(
          SubjectType.computerScience,
          'data_structures',
        );

        expect(fastResponseRec.adaptiveFactors['response_time_factor'], 
            lessThan(slowResponseRec.adaptiveFactors['response_time_factor']!),
            reason: 'Fast responses should have lower response time factor');
      });

      test('should track mastery level progression', () async {
        // Record multiple sessions to build mastery
        for (int i = 0; i < 10; i++) {
          await service.recordPerformance(PerformanceRecord(
            subject: SubjectType.math,
            skillId: 'calculus',
            accuracy: 0.85 + (i * 0.01), // Gradually improving
            difficulty: 3.0,
            averageResponseTime: const Duration(seconds: 15),
            timestamp: DateTime.now().subtract(Duration(hours: i)),
            questionsAnswered: 10,
            correctAnswers: (8.5 + (i * 0.1)).round(),
          ));
        }

        final recommendation = await service.calculateOptimalDifficulty(
          SubjectType.math,
          'calculus',
        );

        expect(recommendation.adaptiveFactors['mastery_factor'], greaterThan(0.5),
            reason: 'Multiple good performances should build mastery');
      });
    });

    group('Confidence Level Tests', () {
      test('should have low confidence with insufficient data', () async {
        final recommendation = await service.calculateOptimalDifficulty(
          SubjectType.physics,
          'quantum_mechanics',
        );

        expect(recommendation.confidence, lessThan(0.7),
            reason: 'Should have low confidence with no performance data');
      });

      test('should increase confidence with more data points', () async {
        // Record multiple consistent performances
        for (int i = 0; i < 15; i++) {
          await service.recordPerformance(PerformanceRecord(
            subject: SubjectType.chemistry,
            skillId: 'organic_chemistry',
            accuracy: 0.8 + (0.05 * (i % 3 - 1)), // Slight variation around 0.8
            difficulty: 2.5,
            averageResponseTime: const Duration(seconds: 18),
            timestamp: DateTime.now().subtract(Duration(hours: i)),
            questionsAnswered: 10,
            correctAnswers: 8,
          ));
        }

        final recommendation = await service.calculateOptimalDifficulty(
          SubjectType.chemistry,
          'organic_chemistry',
        );

        expect(recommendation.confidence, greaterThan(0.8),
            reason: 'Should have high confidence with sufficient consistent data');
      });
    });

    group('Persistence Tests', () {
      test('should persist and load difficulty profiles', () async {
        // Record performance to create a profile
        await service.recordPerformance(PerformanceRecord(
          subject: SubjectType.biology,
          skillId: 'genetics',
          accuracy: 0.9,
          difficulty: 2.0,
          averageResponseTime: const Duration(seconds: 12),
          timestamp: DateTime.now(),
          questionsAnswered: 10,
          correctAnswers: 9,
        ));

        final originalProfile = service.difficultyProfile;
        expect(originalProfile, isNotNull);

        // Create new service instance (simulating app restart)
        final newService = ProgressiveDifficultyEnhancedService();
        await newService.initialize();

        final loadedProfile = newService.difficultyProfile;
        expect(loadedProfile, isNotNull);
        expect(loadedProfile!.subjectProfiles, contains(SubjectType.biology));
      });

      test('should maintain performance history across restarts', () async {
        // Record multiple performances
        for (int i = 0; i < 5; i++) {
          await service.recordPerformance(PerformanceRecord(
            subject: SubjectType.math,
            skillId: 'statistics',
            accuracy: 0.7 + (i * 0.05),
            difficulty: 2.0,
            averageResponseTime: const Duration(seconds: 20),
            timestamp: DateTime.now().subtract(Duration(days: i)),
            questionsAnswered: 10,
            correctAnswers: 7 + i,
          ));
        }

        // Create new service and check if history affects recommendations
        final newService = ProgressiveDifficultyEnhancedService();
        await newService.initialize();

        final recommendation = await newService.calculateOptimalDifficulty(
          SubjectType.math,
          'statistics',
        );

        expect(recommendation.confidence, greaterThan(0.5),
            reason: 'Loaded history should contribute to confidence');
      });
    });

    group('Edge Cases Tests', () {
      test('should handle extreme accuracy values', () async {
        // Test perfect accuracy
        await service.recordPerformance(PerformanceRecord(
          subject: SubjectType.math,
          skillId: 'perfect_skill',
          accuracy: 1.0,
          difficulty: 1.0,
          averageResponseTime: const Duration(seconds: 5),
          timestamp: DateTime.now(),
          questionsAnswered: 10,
          correctAnswers: 10,
        ));

        final perfectRec = await service.calculateOptimalDifficulty(
          SubjectType.math,
          'perfect_skill',
        );

        expect(perfectRec.difficulty, greaterThan(1.0));

        // Test zero accuracy
        await service.recordPerformance(PerformanceRecord(
          subject: SubjectType.math,
          skillId: 'zero_skill',
          accuracy: 0.0,
          difficulty: 3.0,
          averageResponseTime: const Duration(seconds: 60),
          timestamp: DateTime.now(),
          questionsAnswered: 10,
          correctAnswers: 0,
        ));

        final zeroRec = await service.calculateOptimalDifficulty(
          SubjectType.math,
          'zero_skill',
        );

        expect(zeroRec.difficulty, lessThan(3.0));
        expect(zeroRec.difficulty, greaterThanOrEqualTo(1.0));
      });

      test('should handle very old performance data', () async {
        // Record old performance
        await service.recordPerformance(PerformanceRecord(
          subject: SubjectType.physics,
          skillId: 'old_skill',
          accuracy: 0.5,
          difficulty: 2.0,
          averageResponseTime: const Duration(seconds: 30),
          timestamp: DateTime.now().subtract(const Duration(days: 30)), // Very old
          questionsAnswered: 10,
          correctAnswers: 5,
        ));

        final recommendation = await service.calculateOptimalDifficulty(
          SubjectType.physics,
          'old_skill',
        );

        expect(recommendation, isNotNull);
        expect(recommendation.confidence, lessThan(0.8),
            reason: 'Old data should reduce confidence');
      });
    });

    group('Performance Tests', () {
      test('should calculate recommendations efficiently', () async {
        final stopwatch = Stopwatch()..start();

        // Record some performance data
        for (int i = 0; i < 20; i++) {
          await service.recordPerformance(PerformanceRecord(
            subject: SubjectType.math,
            skillId: 'performance_test',
            accuracy: 0.7 + (0.01 * i),
            difficulty: 2.0,
            averageResponseTime: const Duration(seconds: 15),
            timestamp: DateTime.now().subtract(Duration(hours: i)),
            questionsAnswered: 10,
            correctAnswers: 7 + (i ~/ 5),
          ));
        }

        final recommendation = await service.calculateOptimalDifficulty(
          SubjectType.math,
          'performance_test',
        );

        stopwatch.stop();

        expect(recommendation, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason: 'Difficulty calculation should be fast');
      });
    });
  });
}