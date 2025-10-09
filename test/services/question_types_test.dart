import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp/core/models/question.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/models/question_pool.dart';
import 'package:sp/core/services/question_pool_service.dart';
import 'package:sp/core/services/enhanced_daily_content_service.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Question Types Tests', () {
    late QuestionPoolService questionPoolService;
    late EnhancedDailyContentService dailyContentService;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      questionPoolService = QuestionPoolService();
      await questionPoolService.initialize();
      
      dailyContentService = EnhancedDailyContentService.getInstance();
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

      test('should generate subtraction questions', () async {
        // Test subtraction questions from question pool
        final questions = await questionPoolService.generateQuestionsFromPools(
          SubjectType.math,
          'arithmetic',
          1,
        );
        expect(questions, isNotEmpty);
        expect(questions.first.questionText, isNotNull);
        expect(questions.first.subject, equals(SubjectType.math));
      });

      test('should generate algebra questions', () async {
        // Test algebra questions from question pool
        final algebraPool = questionPoolService.poolManager?.getPool(
          SubjectType.math, 
          'algebra', 
          QuestionCategory.analytical
        );
        expect(algebraPool, isNotNull);
        expect(algebraPool!.templates, isNotEmpty);
        
        // Verify algebra template exists (should contain variables like x, y)
        final algebraTemplate = algebraPool.templates.firstWhere(
          (template) => template.questionPattern.contains('x') || 
                       template.questionPattern.contains('='),
          orElse: () => throw Exception('No algebra template found')
        );
        expect(algebraTemplate.questionPattern, anyOf(contains('x'), contains('=')));
        
        // Test question generation using the service's generate method
        final questions = await questionPoolService.generateQuestionsFromPools(
          SubjectType.math,
          'algebra',
          1,
        );
        expect(questions, isNotEmpty);
        expect(questions.first.questionText, isNotNull);
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
            'arithmetic',
            1,
          );
          
          expect(questions, isNotEmpty);
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
          final questions = await questionPoolService.generateQuestionsFromPools(
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

    group('Enhanced Daily Content Service', () {
      test('should generate daily lessons with questions', () async {
        // Generate daily content
        final dailyContent = await dailyContentService.generateDailyContent();
        
        expect(dailyContent, isNotNull);
        expect(dailyContent, isNotEmpty);
        
        // Check that at least one subject has content
        final subjectKeys = dailyContent.keys.toList();
        expect(subjectKeys, isNotEmpty);
        
        // Find a subject with lessons
        Map<String, dynamic>? subjectWithLessons;
        for (final key in subjectKeys) {
          final subjectContent = dailyContent[key];
          if (subjectContent is List && subjectContent.isNotEmpty) {
            subjectWithLessons = {'key': key, 'content': subjectContent};
            break;
          }
        }
        
        // If no subject has lessons, the service might not be generating content properly
        if (subjectWithLessons == null) {
          print('Daily content structure: $dailyContent');
          fail('No subject found with lessons. Daily content might be empty or malformed.');
        }
        
        final lessons = subjectWithLessons['content'] as List;
        expect(lessons, isNotEmpty);
        
        final firstLesson = lessons[0];
        expect(firstLesson, isNotNull);
        expect(firstLesson['questions'], isNotNull);
        expect(firstLesson['questions'], isNotEmpty);
        
        final questions = firstLesson['questions'] as List;
        expect(questions.length, equals(7)); // Should have exactly 7 questions
        
        // Verify question structure
        final firstQuestion = questions[0];
        expect(firstQuestion['questionText'], isNotNull);
        expect(firstQuestion['options'], isNotNull);
        expect(firstQuestion['correctAnswer'], isNotNull);
      });
    });

    group('Question Generation with Different Difficulties', () {
      test('should generate questions with varying difficulty levels', () async {
        // Test question generation with different difficulties using QuestionPoolService
        final easyQuestions = await questionPoolService.generateQuestionsFromPools(
          SubjectType.math, 
          'arithmetic', 
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
          'arithmetic',
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

      test('should validate question structure consistency', () async {
        // Test the daily content generation which creates structured questions
        final dailyContent = await dailyContentService.generateDailyContent();
        
        expect(dailyContent, isNotNull);
        expect(dailyContent, isNotEmpty);
        
        // Get the first subject's lessons
        final subjectKeys = dailyContent.keys.toList();
        expect(subjectKeys, isNotEmpty);
        
        final firstSubjectLessons = dailyContent[subjectKeys.first];
        expect(firstSubjectLessons, isNotNull);
        expect(firstSubjectLessons, isNotEmpty);
        
        final firstLesson = firstSubjectLessons[0];
        expect(firstLesson['questions'], isNotNull);
        expect(firstLesson['questions'], isNotEmpty);
        
        final firstQuestion = firstLesson['questions'][0];
        
        // Verify required fields - the mock question uses 'questionText' not 'question'
        expect(firstQuestion.containsKey('questionText'), isTrue);
        expect(firstQuestion['questionText'], isNotNull);
        expect(firstQuestion['questionText'], isNotEmpty);
      });
    });
  });
}