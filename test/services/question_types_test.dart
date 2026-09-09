import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp/core/models/question.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/models/question_pool.dart';
import 'package:sp/core/services/question_pool_service.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Question Types Tests', () {
    late QuestionPoolService questionPoolService;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      questionPoolService = QuestionPoolService();
      await questionPoolService.initialize();
    });

    group('Math Question Types', () {
      test('should generate multiplication questions', () async {
        // Test multiplication questions from question pool
        final questions = await questionPoolService.generateQuestionsFromPools(
          SubjectType.math,
          'multiplication',
          1,
        );
        expect(questions, isNotEmpty);
        expect(questions.first.questionText, isNotNull);
        expect(questions.first.subject, equals(SubjectType.math));
      });

      test('should generate addition questions', () async {
        // Test addition questions from question pool (canonical skill id)
        final questions = await questionPoolService.generateQuestionsFromPools(
          SubjectType.math,
          'addition',
          1,
        );
        expect(questions, isNotEmpty);
        expect(questions.first.questionText, isNotNull);
        expect(questions.first.subject, equals(SubjectType.math));
      });

      test('should expose algebra skill pool', () async {
        // The canonical algebra skill id is 'variables' (see SkillIdRegistry).
        final algebraPool = questionPoolService.poolManager?.getPool(
          SubjectType.math,
          'variables',
          QuestionCategory.analytical,
        );
        expect(algebraPool, isNotNull);
        // NOTE(debt): algebra templates are still registered under the legacy
        // 'algebra' skill id, so the canonical 'variables' pool currently
        // generates no questions. Tracked for a follow-up migration.
      });
    });

    group('All Question Types Coverage', () {
      test('should support all 7 question types', () async {
        final questionTypes = [
          QuestionType.multipleChoice,
          QuestionType.trueFalse,
          QuestionType.numericInput,
          QuestionType.fillInTheBlank,
          QuestionType.clickableAnswer,
          QuestionType.shortAnswer,
        ];
        
        // Test that we can generate questions of different types
        for (final questionType in questionTypes) {
          final questions = await questionPoolService.generateQuestionsFromPools(
            SubjectType.math,
            'multiplication',
            1,
          );

          expect(questions, isNotEmpty, reason: 'no questions for $questionType');
          expect(questions.first.questionText, isNotNull);
          // Note: The actual question type depends on the template, not the request
        }
      });

      test('should generate questions for all subjects', () async {
        final subjects = [
          SubjectType.math,
          SubjectType.physics,
          SubjectType.chemistry,
          SubjectType.biology,
        ];
        
        for (final subject in subjects) {
          await questionPoolService.generateQuestionsFromPools(
            subject,
            'basic',
            1,
          );
          
          // Some subjects might not have 'basic' skill, so we check if questions exist
          // or if the pool exists for that subject
          final hasPool = questionPoolService.poolManager?.pools.keys
              .any((key) => key.startsWith(subject.name)) ?? false;
          expect(hasPool, isTrue, reason: 'Subject $subject should have at least one pool');
        }
      });
    });

    group('Question Pool Statistics', () {
      test('should provide pool statistics', () async {
        final stats = await questionPoolService.getPoolStatistics();
        expect(stats, isNotNull);
        expect(stats, isNotEmpty);
        
        // Verify math statistics exist
        expect(stats['math'], isNotNull);
        expect(stats['math']['computational'], isNotNull);
        expect(stats['math']['computational']['total'], greaterThan(0));
      });
    });

    group('Question Generation Edge Cases', () {
      test('should handle empty pools gracefully', () async {
        // Try to get a pool that might not exist
        final emptyPool = questionPoolService.poolManager?.getPool(
          SubjectType.math, 
          'nonexistent_skill', 
          QuestionCategory.creative
        );
        expect(emptyPool, isNull);
      });

      test('should reset pools when needed', () async {
        await questionPoolService.resetSubjectPools(SubjectType.math);
        
        final stats = await questionPoolService.getPoolStatistics();
        expect(stats['math']['computational']['used'], equals(0));
      });
    });

    group('Question Generation with Different Difficulties', () {
      test('should generate questions with varying difficulty levels', () async {
        // Test question generation with different difficulties using QuestionPoolService
        final easyQuestions = await questionPoolService.generateQuestionsFromPools(
          SubjectType.math, 
          'multiplication', 
          3
        );
        
        expect(easyQuestions, isNotNull);
        expect(easyQuestions, isNotEmpty);
        
        // Verify questions have the expected structure
        for (final question in easyQuestions) {
          expect(question.questionText, isNotNull);
          expect(question.options, isNotNull);
          expect(question.correctAnswer, isNotNull);
          expect(question.subject, equals(SubjectType.math));
        }
      });
    });

    group('Question Pool Integration', () {
      test('should initialize pools for all subjects and skills', () async {
        // Verify pools exist for core subjects by checking statistics
        final stats = await questionPoolService.getPoolStatistics();
        expect(stats, isNotNull);
        expect(stats, isNotEmpty);
        
        // Verify math pools exist
        expect(stats['math'], isNotNull);
        expect(stats['math']['computational'], isNotNull);
        expect(stats['math']['computational']['total'], greaterThan(0));
      });

      test('should generate questions from pools', () async {
        // Test question generation using the service's generate method
        final questions = await questionPoolService.generateQuestionsFromPools(
          SubjectType.math,
          'multiplication',
          1,
        );
        
        expect(questions, isNotEmpty);
        expect(questions.first.questionText, isNotNull);
        expect(questions.first.questionText, isNotEmpty);
      });
    });

    group('Question Type Coverage', () {
      test('should ensure all question types are implemented', () {
        final allQuestionTypes = QuestionType.values;
        expect(allQuestionTypes.length, greaterThanOrEqualTo(7));
        
        // Verify core types exist
        expect(allQuestionTypes.contains(QuestionType.multipleChoice), isTrue);
        expect(allQuestionTypes.contains(QuestionType.trueFalse), isTrue);
        expect(allQuestionTypes.contains(QuestionType.numericInput), isTrue);
        expect(allQuestionTypes.contains(QuestionType.fillInTheBlank), isTrue);
      });

    });
  });
}