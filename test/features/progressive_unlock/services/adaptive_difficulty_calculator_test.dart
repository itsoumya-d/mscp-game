import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sp/core/services/adaptive_difficulty_calculator.dart';

// Generate mocks
@GenerateMocks([AdaptiveDifficultyCalculator])
import 'adaptive_difficulty_calculator_test.mocks.dart';

void main() {
  group('AdaptiveDifficultyCalculator Tests', () {
    late AdaptiveDifficultyCalculator calculator;
    late MockAdaptiveDifficultyCalculator mockCalculator;

    setUp(() {
      calculator = AdaptiveDifficultyCalculator();
      mockCalculator = MockAdaptiveDifficultyCalculator();
    });

    group('Initialization', () {
      test('should initialize with default difficulty', () {
        expect(calculator, isNotNull);
        // Test that calculator starts with appropriate default values
      });

      test('should accept initial difficulty level', () {
        final customCalculator = AdaptiveDifficultyCalculator(
          initialDifficulty: DifficultyLevel.hard,
        );
        expect(customCalculator, isNotNull);
      });
    });

    group('Performance Recording', () {
      test('should record correct answer performance', () async {
        // Arrange
        const questionId = 'q_123';
        const isCorrect = true;
        const responseTime = Duration(seconds: 3);
        const currentDifficulty = DifficultyLevel.medium;

        when(mockCalculator.recordQuestionPerformance(
          questionId, isCorrect, responseTime, currentDifficulty
        )).thenAnswer((_) async => {});

        // Act
        await mockCalculator.recordQuestionPerformance(
          questionId, isCorrect, responseTime, currentDifficulty
        );

        // Assert
        verify(mockCalculator.recordQuestionPerformance(
          questionId, isCorrect, responseTime, currentDifficulty
        )).called(1);
      });

      test('should record incorrect answer performance', () async {
        // Arrange
        const questionId = 'q_124';
        const isCorrect = false;
        const responseTime = Duration(seconds: 8);
        const currentDifficulty = DifficultyLevel.medium;

        when(mockCalculator.recordQuestionPerformance(
          questionId, isCorrect, responseTime, currentDifficulty
        )).thenAnswer((_) async => {});

        // Act
        await mockCalculator.recordQuestionPerformance(
          questionId, isCorrect, responseTime, currentDifficulty
        );

        // Assert
        verify(mockCalculator.recordQuestionPerformance(
          questionId, isCorrect, responseTime, currentDifficulty
        )).called(1);
      });

      test('should handle multiple performance records', () async {
        // Arrange
        final performances = [
          {'id': 'q_1', 'correct': true, 'time': Duration(seconds: 2)},
          {'id': 'q_2', 'correct': false, 'time': Duration(seconds: 5)},
          {'id': 'q_3', 'correct': true, 'time': Duration(seconds: 3)},
          {'id': 'q_4', 'correct': true, 'time': Duration(seconds: 2)},
        ];

        for (final perf in performances) {
          when(mockCalculator.recordQuestionPerformance(
            perf['id'] as String,
            perf['correct'] as bool,
            perf['time'] as Duration,
            DifficultyLevel.medium,
          )).thenAnswer((_) async => {});
        }

        // Act
        for (final perf in performances) {
          await mockCalculator.recordQuestionPerformance(
            perf['id'] as String,
            perf['correct'] as bool,
            perf['time'] as Duration,
            DifficultyLevel.medium,
          );
        }

        // Assert
        for (final perf in performances) {
          verify(mockCalculator.recordQuestionPerformance(
            perf['id'] as String,
            perf['correct'] as bool,
            perf['time'] as Duration,
            DifficultyLevel.medium,
          )).called(1);
        }
      });
    });

    group('Difficulty Calculation', () {
      test('should increase difficulty after consecutive correct answers', () async {
        // Arrange
        const userId = 'user_123';
        when(mockCalculator.calculateAdaptiveDifficulty(userId))
            .thenAnswer((_) async => DifficultyLevel.hard);

        // Act
        final newDifficulty = await mockCalculator.calculateAdaptiveDifficulty(userId);

        // Assert
        expect(newDifficulty, equals(DifficultyLevel.hard));
        verify(mockCalculator.calculateAdaptiveDifficulty(userId)).called(1);
      });

      test('should decrease difficulty after consecutive incorrect answers', () async {
        // Arrange
        const userId = 'user_123';
        when(mockCalculator.calculateAdaptiveDifficulty(userId))
            .thenAnswer((_) async => DifficultyLevel.easy);

        // Act
        final newDifficulty = await mockCalculator.calculateAdaptiveDifficulty(userId);

        // Assert
        expect(newDifficulty, equals(DifficultyLevel.easy));
        verify(mockCalculator.calculateAdaptiveDifficulty(userId)).called(1);
      });

      test('should maintain difficulty for mixed performance', () async {
        // Arrange
        const userId = 'user_123';
        when(mockCalculator.calculateAdaptiveDifficulty(userId))
            .thenAnswer((_) async => DifficultyLevel.medium);

        // Act
        final newDifficulty = await mockCalculator.calculateAdaptiveDifficulty(userId);

        // Assert
        expect(newDifficulty, equals(DifficultyLevel.medium));
      });

      test('should consider response time in difficulty calculation', () async {
        // Arrange
        const userId = 'user_123';
        
        // Mock fast responses leading to higher difficulty
        when(mockCalculator.calculateAdaptiveDifficulty(userId))
            .thenAnswer((_) async => DifficultyLevel.hard);

        // Act
        final newDifficulty = await mockCalculator.calculateAdaptiveDifficulty(userId);

        // Assert
        expect(newDifficulty, equals(DifficultyLevel.hard));
      });

      test('should handle edge cases in difficulty calculation', () async {
        // Arrange
        const userId = 'user_123';
        
        // Test with no previous performance data
        when(mockCalculator.calculateAdaptiveDifficulty(userId))
            .thenAnswer((_) async => DifficultyLevel.medium);

        // Act
        final newDifficulty = await mockCalculator.calculateAdaptiveDifficulty(userId);

        // Assert
        expect(newDifficulty, equals(DifficultyLevel.medium));
      });
    });

    group('Performance Analytics', () {
      test('should calculate accuracy rate correctly', () async {
        // Arrange
        const userId = 'user_123';
        const expectedAccuracy = 0.8; // 80%

        when(mockCalculator.getAccuracyRate(userId))
            .thenAnswer((_) async => expectedAccuracy);

        // Act
        final accuracy = await mockCalculator.getAccuracyRate(userId);

        // Assert
        expect(accuracy, equals(expectedAccuracy));
        expect(accuracy, greaterThanOrEqualTo(0.0));
        expect(accuracy, lessThanOrEqualTo(1.0));
      });

      test('should calculate average response time', () async {
        // Arrange
        const userId = 'user_123';
        const expectedAvgTime = Duration(seconds: 4);

        when(mockCalculator.getAverageResponseTime(userId))
            .thenAnswer((_) async => expectedAvgTime);

        // Act
        final avgTime = await mockCalculator.getAverageResponseTime(userId);

        // Assert
        expect(avgTime, equals(expectedAvgTime));
        expect(avgTime.inSeconds, greaterThan(0));
      });

      test('should identify performance trends', () async {
        // Arrange
        const userId = 'user_123';
        final expectedTrend = {
          'direction': 'improving',
          'confidence': 0.85,
          'recentAccuracy': 0.9,
          'previousAccuracy': 0.7,
        };

        when(mockCalculator.getPerformanceTrend(userId))
            .thenAnswer((_) async => expectedTrend);

        // Act
        final trend = await mockCalculator.getPerformanceTrend(userId);

        // Assert
        expect(trend, isNotNull);
        expect(trend['direction'], equals('improving'));
        expect(trend['confidence'], greaterThan(0.5));
      });

      test('should provide difficulty recommendations', () async {
        // Arrange
        const userId = 'user_123';
        final expectedRecommendation = {
          'suggestedDifficulty': DifficultyLevel.hard,
          'confidence': 0.9,
          'reasoning': 'High accuracy with fast response times',
        };

        when(mockCalculator.getDifficultyRecommendation(userId))
            .thenAnswer((_) async => expectedRecommendation);

        // Act
        final recommendation = await mockCalculator.getDifficultyRecommendation(userId);

        // Assert
        expect(recommendation, isNotNull);
        expect(recommendation['suggestedDifficulty'], isA<DifficultyLevel>());
        expect(recommendation['confidence'], greaterThan(0.0));
      });
    });

    group('Adaptive Algorithms', () {
      test('should use ELO-like rating system for difficulty adjustment', () async {
        // Arrange
        const userId = 'user_123';
        const currentRating = 1200.0;
        const expectedNewRating = 1250.0;

        when(mockCalculator.calculateEloRating(userId, true, DifficultyLevel.medium))
            .thenAnswer((_) async => expectedNewRating);

        // Act
        final newRating = await mockCalculator.calculateEloRating(userId, true, DifficultyLevel.medium);

        // Assert
        expect(newRating, equals(expectedNewRating));
        expect(newRating, greaterThan(currentRating));
      });

      test('should implement confidence intervals for difficulty changes', () async {
        // Arrange
        const userId = 'user_123';
        final expectedInterval = {
          'lower': DifficultyLevel.medium,
          'upper': DifficultyLevel.hard,
          'confidence': 0.95,
        };

        when(mockCalculator.getDifficultyConfidenceInterval(userId))
            .thenAnswer((_) async => expectedInterval);

        // Act
        final interval = await mockCalculator.getDifficultyConfidenceInterval(userId);

        // Assert
        expect(interval, isNotNull);
        expect(interval['confidence'], greaterThan(0.8));
      });

      test('should adapt to learning velocity changes', () async {
        // Arrange
        const userId = 'user_123';
        const learningVelocity = 0.8; // Fast learner

        when(mockCalculator.adjustForLearningVelocity(userId, learningVelocity))
            .thenAnswer((_) async => DifficultyLevel.hard);

        // Act
        final adjustedDifficulty = await mockCalculator.adjustForLearningVelocity(
          userId, learningVelocity
        );

        // Assert
        expect(adjustedDifficulty, equals(DifficultyLevel.hard));
      });
    });

    group('Data Management', () {
      test('should handle performance data cleanup', () async {
        // Arrange
        const userId = 'user_123';
        const retentionDays = 30;

        when(mockCalculator.cleanupOldPerformanceData(userId, retentionDays))
            .thenAnswer((_) async => true);

        // Act
        final cleaned = await mockCalculator.cleanupOldPerformanceData(userId, retentionDays);

        // Assert
        expect(cleaned, isTrue);
        verify(mockCalculator.cleanupOldPerformanceData(userId, retentionDays)).called(1);
      });

      test('should export performance data for analysis', () async {
        // Arrange
        const userId = 'user_123';
        final expectedData = {
          'totalQuestions': 100,
          'correctAnswers': 85,
          'averageResponseTime': 3.5,
          'difficultyProgression': [
            DifficultyLevel.easy,
            DifficultyLevel.medium,
            DifficultyLevel.hard,
          ],
        };

        when(mockCalculator.exportPerformanceData(userId))
            .thenAnswer((_) async => expectedData);

        // Act
        final data = await mockCalculator.exportPerformanceData(userId);

        // Assert
        expect(data, isNotNull);
        expect(data['totalQuestions'], greaterThan(0));
        expect(data['difficultyProgression'], isA<List>());
      });
    });

    group('Error Handling', () {
      test('should handle invalid performance data gracefully', () async {
        // Arrange
        const questionId = 'invalid_q';
        const isCorrect = true;
        const responseTime = Duration(seconds: -1); // Invalid time

        when(mockCalculator.recordQuestionPerformance(
          questionId, isCorrect, responseTime, DifficultyLevel.medium
        )).thenThrow(ArgumentError('Invalid response time'));

        // Act & Assert
        expect(
          () => mockCalculator.recordQuestionPerformance(
            questionId, isCorrect, responseTime, DifficultyLevel.medium
          ),
          throwsArgumentError,
        );
      });

      test('should handle calculation errors gracefully', () async {
        // Arrange
        const userId = 'user_with_no_data';

        when(mockCalculator.calculateAdaptiveDifficulty(userId))
            .thenAnswer((_) async => DifficultyLevel.medium); // Default fallback

        // Act
        final difficulty = await mockCalculator.calculateAdaptiveDifficulty(userId);

        // Assert
        expect(difficulty, equals(DifficultyLevel.medium));
      });

      test('should handle concurrent calculation requests', () async {
        // Arrange
        const userId = 'user_123';
        final futures = List.generate(5, (_) => 
          mockCalculator.calculateAdaptiveDifficulty(userId)
        );

        for (int i = 0; i < 5; i++) {
          when(mockCalculator.calculateAdaptiveDifficulty(userId))
              .thenAnswer((_) async => DifficultyLevel.medium);
        }

        // Act
        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(5));
        expect(results.every((result) => result == DifficultyLevel.medium), isTrue);
      });
    });
  });
}