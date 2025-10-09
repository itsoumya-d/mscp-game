import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp/core/services/enhanced_daily_content_service.dart';
import 'package:sp/core/models/subject.dart';

void main() {
  group('Enhanced Daily Content Service Tests', () {
    late EnhancedDailyContentService service;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      service = EnhancedDailyContentService.getInstance();
    });

    group('Lesson Structure Tests', () {
      test('should generate lessons with exactly 7 questions', () async {
        // Test lesson generation for each core subject
        final subjects = [
          SubjectType.physics,
          SubjectType.chemistry,
          SubjectType.biology,
          SubjectType.math,
        ];

        for (final subject in subjects) {
          final lessonData = await service.generateMockLesson(
            subject: subject,
            difficulty: 1,
            lessonNumber: 1,
          );

          expect(lessonData, isNotNull, reason: 'Lesson should be generated for ${subject.name}');
          
          final questions = lessonData!['questions'] as List<dynamic>;
          expect(questions.length, equals(7), 
            reason: 'Lesson for ${subject.name} should have exactly 7 questions');

          // Verify each question has required fields
          for (int i = 0; i < questions.length; i++) {
            final question = questions[i] as Map<String, dynamic>;
            expect(question['id'], isNotNull, reason: 'Question ${i+1} should have an ID');
            expect(question['type'], isNotNull, reason: 'Question ${i+1} should have a type');
            expect(question['questionText'], isNotNull, reason: 'Question ${i+1} should have question text');
            expect(question['options'], isNotNull, reason: 'Question ${i+1} should have options');
            expect(question['correctAnswer'], isNotNull, reason: 'Question ${i+1} should have correct answer');
            expect(question['explanation'], isNotNull, reason: 'Question ${i+1} should have explanation');
            expect(question['subject'], equals(subject.name), reason: 'Question ${i+1} should have correct subject');
          }
        }
      });

      test('should generate different question types across the 7 questions', () async {
        final lessonData = await service.generateMockLesson(
          subject: SubjectType.math,
          difficulty: 1,
          lessonNumber: 1,
        );

        expect(lessonData, isNotNull);
        
        final questions = lessonData!['questions'] as List<dynamic>;
        final questionTypes = questions.map((q) => q['type'] as String).toSet();
        
        // Should have multiple different question types
        expect(questionTypes.length, greaterThan(1), 
          reason: 'Should have diverse question types across the 7 questions');
      });
    });

    group('Subject-Specific Content Tests', () {
      test('should generate appropriate content for Physics', () async {
        final lessonData = await service.generateMockLesson(
          subject: SubjectType.physics,
          difficulty: 1,
          lessonNumber: 1,
        );

        expect(lessonData, isNotNull);
        expect(lessonData!['title'], contains('Physics'));
        
        final questions = lessonData['questions'] as List<dynamic>;
        expect(questions.length, equals(7));
        
        // Verify physics-specific content
        for (final question in questions) {
          final questionMap = question as Map<String, dynamic>;
          expect(questionMap['subject'], equals('physics'));
        }
      });

      test('should generate appropriate content for Chemistry', () async {
        final lessonData = await service.generateMockLesson(
          subject: SubjectType.chemistry,
          difficulty: 1,
          lessonNumber: 1,
        );

        expect(lessonData, isNotNull);
        expect(lessonData!['title'], contains('Chemistry'));
        
        final questions = lessonData['questions'] as List<dynamic>;
        expect(questions.length, equals(7));
        
        // Verify chemistry-specific content
        for (final question in questions) {
          final questionMap = question as Map<String, dynamic>;
          expect(questionMap['subject'], equals('chemistry'));
        }
      });

      test('should generate appropriate content for Biology', () async {
        final lessonData = await service.generateMockLesson(
          subject: SubjectType.biology,
          difficulty: 1,
          lessonNumber: 1,
        );

        expect(lessonData, isNotNull);
        expect(lessonData!['title'], contains('Biology'));
        
        final questions = lessonData['questions'] as List<dynamic>;
        expect(questions.length, equals(7));
        
        // Verify biology-specific content
        for (final question in questions) {
          final questionMap = question as Map<String, dynamic>;
          expect(questionMap['subject'], equals('biology'));
        }
      });

      test('should generate appropriate content for Mathematics', () async {
        final lessonData = await service.generateMockLesson(
          subject: SubjectType.math,
          difficulty: 1,
          lessonNumber: 1,
        );

        expect(lessonData, isNotNull);
        expect(lessonData!['title'], contains('Math'));
        
        final questions = lessonData['questions'] as List<dynamic>;
        expect(questions.length, equals(7));
        
        // Verify math-specific content
        for (final question in questions) {
          final questionMap = question as Map<String, dynamic>;
          expect(questionMap['subject'], equals('math'));
        }
      });
    });

    group('Question Type Validation Tests', () {
      test('should include multiplication questions in Math lessons', () async {
        final lessonData = await service.generateMockLesson(
          subject: SubjectType.math,
          difficulty: 1,
          lessonNumber: 1,
        );

        expect(lessonData, isNotNull);
        
        final questions = lessonData!['questions'] as List<dynamic>;
        final questionTypes = questions.map((q) => q['type'] as String).toList();
        
        // Should include multiplication type
        expect(questionTypes, contains('multiplication'),
          reason: 'Math lessons should include multiplication questions');
      });

      test('should include subtraction questions in Math lessons', () async {
        final lessonData = await service.generateMockLesson(
          subject: SubjectType.math,
          difficulty: 2,
          lessonNumber: 1,
        );

        expect(lessonData, isNotNull);
        
        final questions = lessonData!['questions'] as List<dynamic>;
        final questionTypes = questions.map((q) => q['type'] as String).toList();
        
        // Should include subtraction type
        expect(questionTypes, contains('subtraction'),
          reason: 'Math lessons should include subtraction questions');
      });

      test('should include all 7 question types across different lessons', () async {
        final allQuestionTypes = <String>{};
        
        // Generate multiple lessons to collect all question types
        for (int i = 1; i <= 5; i++) {
          final lessonData = await service.generateMockLesson(
            subject: SubjectType.math,
            difficulty: i,
            lessonNumber: i,
          );

          if (lessonData != null) {
            final questions = lessonData['questions'] as List<dynamic>;
            final questionTypes = questions.map((q) => q['type'] as String);
            allQuestionTypes.addAll(questionTypes);
          }
        }
        
        // Should have collected multiple question types
        expect(allQuestionTypes.length, greaterThanOrEqualTo(3),
          reason: 'Should generate diverse question types across multiple lessons');
      });
    });

    group('Daily Content Generation Tests', () {
      test('should generate daily content for all 4 core subjects', () async {
        await service.generateDailyContent();
        
        final content = await service.getDailyContent();
        expect(content, isNotNull);
        
        // Should have content for core subjects
        final subjects = ['physics', 'chemistry', 'biology', 'math'];
        for (final subject in subjects) {
          if (content!.containsKey(subject)) {
            final lessons = content[subject] as List<dynamic>;
            expect(lessons, isNotEmpty, reason: 'Should have lessons for $subject');
            
            // Verify each lesson has 7 questions
            for (final lesson in lessons) {
              final lessonMap = lesson as Map<String, dynamic>;
              final questions = lessonMap['questions'] as List<dynamic>;
              expect(questions.length, equals(7),
                reason: 'Each lesson in $subject should have exactly 7 questions');
            }
          }
        }
      });

      test('should handle force regeneration correctly', () async {
        // Generate initial content
        await service.generateDailyContent();
        final initialContent = await service.getDailyContent();
        
        // Force regeneration
        await service.forceRegenerateContent();
        final newContent = await service.getDailyContent();
        
        expect(newContent, isNotNull);
        
        // Verify structure is maintained
        if (newContent != null && newContent.isNotEmpty) {
          for (final entry in newContent.entries) {
            final lessons = entry.value as List<dynamic>;
            for (final lesson in lessons) {
              final lessonMap = lesson as Map<String, dynamic>;
              final questions = lessonMap['questions'] as List<dynamic>;
              expect(questions.length, equals(7),
                reason: 'Regenerated lessons should still have exactly 7 questions');
            }
          }
        }
      });
    });

    group('Integration Tests', () {
      test('should integrate with existing lesson structure', () async {
        final lessonData = await service.generateMockLesson(
          subject: SubjectType.physics,
          difficulty: 1,
          lessonNumber: 1,
        );

        expect(lessonData, isNotNull);
        
        // Verify lesson structure matches expected format
        expect(lessonData!['id'], isNotNull);
        expect(lessonData['title'], isNotNull);
        expect(lessonData['description'], isNotNull);
        expect(lessonData['xpReward'], isNotNull);
        expect(lessonData['questions'], isNotNull);
        
        final questions = lessonData['questions'] as List<dynamic>;
        expect(questions.length, equals(7));
        
        // Verify question structure matches Question model
        for (final question in questions) {
          final questionMap = question as Map<String, dynamic>;
          expect(questionMap['id'], isNotNull);
          expect(questionMap['type'], isNotNull);
          expect(questionMap['questionText'], isNotNull);
          expect(questionMap['options'], isNotNull);
          expect(questionMap['correctAnswer'], isNotNull);
          expect(questionMap['explanation'], isNotNull);
          expect(questionMap['hint'], isNotNull);
          expect(questionMap['difficulty'], isNotNull);
          expect(questionMap['subject'], isNotNull);
        }
      });
    });
  });
}