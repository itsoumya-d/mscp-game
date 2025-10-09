import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/models/question.dart';
import 'package:sp/core/models/question_pool.dart';
import 'package:sp/core/services/question_validation_service.dart';

void main() {
  group('QuestionValidationService Tests', () {
    late QuestionValidationService service;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      service = QuestionValidationService();
    });

    tearDown(() async {
      // Clean up SharedPreferences after each test
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    group('Validation Result Tests', () {
      test('should create validation result correctly', () {
        final result = ValidationResult(
          isValid: true,
          message: 'Test message',
          category: 'test',
        );

        expect(result.isValid, isTrue);
        expect(result.message, equals('Test message'));
        expect(result.category, equals('test'));
        expect(result.timestamp, isA<DateTime>());
      });

      test('should serialize and deserialize validation result', () {
        final original = ValidationResult(
          isValid: false,
          message: 'Error message',
          category: 'error',
          timestamp: DateTime(2024, 1, 1),
        );

        final json = original.toJson();
        final restored = ValidationResult.fromJson(json);

        expect(restored.isValid, equals(original.isValid));
        expect(restored.message, equals(original.message));
        expect(restored.category, equals(original.category));
        expect(restored.timestamp, equals(original.timestamp));
      });
    });

    group('System Validation Tests', () {
      test('should validate complete system', () async {
        final report = await service.validateCompleteSystem();

        expect(report, isA<ValidationReport>());
        expect(report.timestamp, isA<DateTime>());
        expect(report.subjectResults, isA<Map<String, List<ValidationResult>>>());
        expect(report.typeCoverage, isA<Map<String, int>>());
        expect(report.qualityScores, isA<Map<String, double>>());
        expect(report.criticalIssues, isA<List<String>>());
        expect(report.recommendations, isA<List<String>>());
        expect(report.overallValid, isA<bool>());
      });

      test('should validate all subjects', () async {
        final report = await service.validateCompleteSystem();

        // Should have results for all subjects
        for (final subject in SubjectType.values) {
          expect(report.subjectResults.containsKey(subject.name), isTrue,
              reason: 'Missing validation results for ${subject.name}');
          expect(report.typeCoverage.containsKey(subject.name), isTrue,
              reason: 'Missing type coverage for ${subject.name}');
          expect(report.qualityScores.containsKey(subject.name), isTrue,
              reason: 'Missing quality score for ${subject.name}');
        }
      });

      test('should check question type coverage', () async {
        final report = await service.validateCompleteSystem();

        for (final subject in SubjectType.values) {
          final coverage = report.typeCoverage[subject.name] ?? 0;
          expect(coverage, greaterThanOrEqualTo(0));
          expect(coverage, lessThanOrEqualTo(7));
        }
      });

      test('should assess question quality', () async {
        final report = await service.validateCompleteSystem();

        for (final subject in SubjectType.values) {
          final quality = report.qualityScores[subject.name] ?? 0.0;
          expect(quality, greaterThanOrEqualTo(0.0));
          expect(quality, lessThanOrEqualTo(1.0));
        }
      });
    });

    group('Question Quality Assessment Tests', () {
      test('should assess multiple choice question quality correctly', () {
        final goodQuestion = Question(
          id: 'test_mc_1',
          type: QuestionType.multipleChoice,
          questionText: 'What is 2 + 2?',
          options: ['2', '3', '4', '5'],
          correctAnswer: '4',
          explanation: 'Two plus two equals four in basic arithmetic.',
          hint: 'Think about basic addition.',
          difficulty: 2,
          subject: SubjectType.math,
        );

        final score = service.assessQuestionQuality(goodQuestion);
        expect(score, greaterThan(0.7), reason: 'Good question should have high quality score');
      });

      test('should assess true/false question quality correctly', () {
        final goodQuestion = Question(
          id: 'test_tf_1',
          type: QuestionType.trueFalse,
          questionText: 'Is the Earth round?',
          options: ['True', 'False'],
          correctAnswer: 'True',
          explanation: 'The Earth is approximately spherical in shape.',
          hint: 'Think about the shape of our planet.',
          difficulty: 1,
          subject: SubjectType.geography,
        );

        final score = service.assessQuestionQuality(goodQuestion);
        expect(score, greaterThan(0.6), reason: 'Good true/false question should have decent quality score');
      });

      test('should assess numeric input question quality correctly', () {
        final goodQuestion = Question(
          id: 'test_num_1',
          type: QuestionType.numericInput,
          questionText: 'Calculate the area of a circle with radius 5.',
          options: [],
          correctAnswer: '78.54',
          explanation: 'Area = π × r² = π × 5² = 25π ≈ 78.54',
          hint: 'Use the formula A = πr²',
          difficulty: 3,
          subject: SubjectType.math,
        );

        final score = service.assessQuestionQuality(goodQuestion);
        expect(score, greaterThan(0.7), reason: 'Good numeric question should have high quality score');
      });

      test('should assess fill in the blank question quality correctly', () {
        final goodQuestion = Question(
          id: 'test_fib_1',
          type: QuestionType.fillInTheBlank,
          questionText: 'The capital of France is ___.',
          options: [],
          correctAnswer: 'Paris',
          explanation: 'Paris is the capital and largest city of France.',
          hint: 'It\'s known as the City of Light.',
          difficulty: 1,
          subject: SubjectType.geography,
        );

        final score = service.assessQuestionQuality(goodQuestion);
        expect(score, greaterThan(0.6), reason: 'Good fill-in-the-blank question should have decent quality score');
      });

      test('should assess drag and drop question quality correctly', () {
        final goodQuestion = Question(
          id: 'test_dd_1',
          type: QuestionType.dragDrop,
          questionText: 'Match the countries with their capitals.',
          options: ['LEFT:France|Germany|Italy', 'RIGHT:Paris|Berlin|Rome'],
          correctAnswer: 'France:Paris;Germany:Berlin;Italy:Rome',
          explanation: 'These are the capital cities of the respective countries.',
          hint: 'Think about European geography.',
          difficulty: 2,
          subject: SubjectType.geography,
        );

        final score = service.assessQuestionQuality(goodQuestion);
        expect(score, greaterThan(0.6), reason: 'Good drag-drop question should have decent quality score');
      });

      test('should assess clickable answer question quality correctly', () {
        final goodQuestion = Question(
          id: 'test_ca_1',
          type: QuestionType.clickableAnswer,
          questionText: 'Click on the correct chemical symbol for water.',
          options: ['H2O', 'CO2', 'NaCl', 'O2'],
          correctAnswer: 'H2O',
          explanation: 'Water is composed of two hydrogen atoms and one oxygen atom.',
          hint: 'Water contains hydrogen and oxygen.',
          difficulty: 1,
          subject: SubjectType.chemistry,
        );

        final score = service.assessQuestionQuality(goodQuestion);
        expect(score, greaterThan(0.7), reason: 'Good clickable answer question should have high quality score');
      });

      test('should assess short answer question quality correctly', () {
        final goodQuestion = Question(
          id: 'test_sa_1',
          type: QuestionType.shortAnswer,
          questionText: 'Explain the process of photosynthesis.',
          options: [],
          correctAnswer: 'Plants convert sunlight into energy using chlorophyll',
          explanation: 'Photosynthesis is the process by which plants use sunlight, water, and carbon dioxide to produce glucose and oxygen.',
          hint: 'Think about how plants make their own food.',
          difficulty: 3,
          subject: SubjectType.biology,
        );

        final score = service.assessQuestionQuality(goodQuestion);
        expect(score, greaterThan(0.6), reason: 'Good short answer question should have decent quality score');
      });

      test('should penalize low quality questions', () {
        final poorQuestion = Question(
          id: 'test_poor_1',
          type: QuestionType.multipleChoice,
          questionText: 'Q?',
          options: ['A'],
          correctAnswer: 'B', // Not in options
          explanation: '',
          hint: '',
          difficulty: 0, // Invalid difficulty
          subject: SubjectType.math,
        );

        final score = service.assessQuestionQuality(poorQuestion);
        expect(score, lessThan(0.5), reason: 'Poor question should have low quality score');
      });
    });

    group('Validation Report Tests', () {
      test('should save and load validation reports', () async {
        // Generate a report
        final originalReport = await service.validateCompleteSystem();
        
        // Load the saved report
        final loadedReport = await service.getLatestValidationReport();
        
        expect(loadedReport, isNotNull);
        expect(loadedReport!.timestamp.difference(originalReport.timestamp).inSeconds, lessThan(5));
        expect(loadedReport.overallValid, equals(originalReport.overallValid));
      });

      test('should maintain validation history', () async {
        // Generate multiple reports
        await service.validateCompleteSystem();
        await Future.delayed(const Duration(milliseconds: 100));
        await service.validateCompleteSystem();
        
        final history = await service.getValidationHistory();
        expect(history.length, greaterThanOrEqualTo(1));
        
        // History should be sorted by timestamp
        for (int i = 1; i < history.length; i++) {
          expect(history[i].timestamp.isAfter(history[i-1].timestamp) || 
                 history[i].timestamp.isAtSameMomentAs(history[i-1].timestamp), isTrue);
        }
      });

      test('should limit validation history size', () async {
        // Generate many reports (more than the limit of 10)
        for (int i = 0; i < 12; i++) {
          await service.validateCompleteSystem();
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        final history = await service.getValidationHistory();
        expect(history.length, lessThanOrEqualTo(10),
            reason: 'History should be limited to 10 reports');
      });
    });

    group('Recommendation Generation Tests', () {
      test('should generate coverage recommendations', () async {
        // Create a scenario with missing question types
        final prefs = await SharedPreferences.getInstance();
        
        // Mock incomplete coverage for math
        await prefs.setString('question_pool_math', '{"templates": []}');
        
        final report = await service.validateCompleteSystem();
        
        expect(report.recommendations, isNotEmpty);
        
        // Should recommend generating missing question types
        final coverageRecommendations = report.recommendations
            .where((r) => r.contains('missing question types'))
            .toList();
        expect(coverageRecommendations, isNotEmpty);
      });

      test('should generate quality recommendations', () async {
        final report = await service.validateCompleteSystem();
        
        // Check if quality recommendations are generated when needed
        final qualityRecommendations = report.recommendations
            .where((r) => r.contains('quality'))
            .toList();
        
        // Should have quality recommendations if scores are low
        final hasLowQuality = report.qualityScores.values.any((score) => score < 0.7);
        if (hasLowQuality) {
          expect(qualityRecommendations, isNotEmpty);
        }
      });

      test('should generate AI-specific recommendations', () async {
        final report = await service.validateCompleteSystem();
        
        // Check for AI-related recommendations
        final aiRecommendations = report.recommendations
            .where((r) => r.toLowerCase().contains('ai'))
            .toList();
        
        // Should have AI recommendations if there are AI issues
        final hasAIIssues = report.subjectResults.values
            .expand((results) => results)
            .any((r) => !r.isValid && r.category == 'ai');
        
        if (hasAIIssues) {
          expect(aiRecommendations, isNotEmpty);
        }
      });
    });

    group('Error Handling Tests', () {
      test('should handle missing question pools gracefully', () async {
        // Clear all stored data
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        final report = await service.validateCompleteSystem();
        
        expect(report, isNotNull);
        expect(report.criticalIssues, isNotEmpty);
        
        // Should identify missing question types as critical issues
        final missingTypeIssues = report.criticalIssues
            .where((issue) => issue.contains('Missing questions'))
            .toList();
        expect(missingTypeIssues, isNotEmpty);
      });

      test('should handle corrupted data gracefully', () async {
        // Add corrupted data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('question_pool_math', 'invalid json');
        
        final report = await service.validateCompleteSystem();
        
        expect(report, isNotNull);
        // Should complete validation despite corrupted data
      });

      test('should handle validation errors gracefully', () async {
        // This test ensures the service doesn't crash on unexpected errors
        final report = await service.validateCompleteSystem();
        
        expect(report, isNotNull);
        expect(report.timestamp, isA<DateTime>());
      });
    });

    group('Performance Tests', () {
      test('should complete validation within reasonable time', () async {
        final stopwatch = Stopwatch()..start();
        
        await service.validateCompleteSystem();
        
        stopwatch.stop();
        
        // Should complete within 30 seconds
        expect(stopwatch.elapsed.inSeconds, lessThan(30),
            reason: 'Validation should complete within reasonable time');
      });

      test('should handle concurrent validations', () async {
        // Test multiple simultaneous validations
        final futures = List.generate(3, (_) => service.validateCompleteSystem());
        final reports = await Future.wait(futures);
        
        expect(reports.length, equals(3));
        for (final report in reports) {
          expect(report, isA<ValidationReport>());
        }
      });
    });

    group('Integration Tests', () {
      test('should work with mock question data', () async {
        // Add some mock question data
        final prefs = await SharedPreferences.getInstance();
        
        final mockTemplate = QuestionTemplate(
          id: 'mock_1',
          type: QuestionType.multipleChoice,
          category: QuestionCategory.conceptual,
          questionPattern: 'What is {variable}?',
          optionPatterns: ['Option A', 'Option B', 'Option C', 'Option D'],
          correctAnswerPattern: 'Option A',
          explanationPattern: 'This is the explanation.',
          hintPattern: 'This is a hint.',
          baseDifficulty: 2,
          variables: {'variable': ['test']},
          tags: {'test'},
        );
        
        final mockPool = QuestionPool(
          id: 'mock_pool',
          subject: SubjectType.math,
          skillId: 'algebra',
          category: QuestionCategory.conceptual,
          templates: [mockTemplate],
          usedQuestionIds: <String>{},
          lastUsed: DateTime.now(),
        );
        
        await prefs.setString('question_pool_math', jsonEncode(mockPool.toJson()));
        
        final report = await service.validateCompleteSystem();
        
        expect(report, isNotNull);
        expect(report.typeCoverage['math'], greaterThan(0));
      });
    });
  });

  group('Validation Result Serialization Tests', () {
    test('should handle all validation result fields', () {
      final result = ValidationResult(
        isValid: true,
        message: 'Test validation message',
        category: 'test_category',
        timestamp: DateTime(2024, 1, 15, 10, 30, 45),
      );

      final json = result.toJson();
      
      expect(json['isValid'], equals(true));
      expect(json['message'], equals('Test validation message'));
      expect(json['category'], equals('test_category'));
      expect(json['timestamp'], equals('2024-01-15T10:30:45.000'));

      final restored = ValidationResult.fromJson(json);
      
      expect(restored.isValid, equals(result.isValid));
      expect(restored.message, equals(result.message));
      expect(restored.category, equals(result.category));
      expect(restored.timestamp, equals(result.timestamp));
    });

    test('should handle malformed JSON gracefully', () {
      final malformedJson = <String, dynamic>{
        'isValid': 'not_a_boolean',
        'message': null,
        'category': 123,
        'timestamp': 'invalid_date',
      };

      final result = ValidationResult.fromJson(malformedJson);
      
      expect(result.isValid, equals(false)); // Default value
      expect(result.message, equals('')); // Default value
      expect(result.category, equals('123')); // Converted to string
      expect(result.timestamp, isA<DateTime>()); // Should use current time
    });
  });
}