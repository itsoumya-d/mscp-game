import 'package:flutter_test/flutter_test.dart';
import 'package:sp/core/utils/content_quality_validator.dart';
import 'package:sp/core/models/question.dart';
import 'package:sp/core/models/subject.dart';

/// Test suite for Phase C Task C8: Content Quality Validation
void main() {
  group('Phase C Task C8: Meta-Question Detection', () {
    test('Detects meta-questions with "important for"', () {
      expect(ContentQualityValidator.detectMetaQuestion(
        'Which of the following is important for multiplication?'
      ), isTrue);
    });

    test('Detects meta-questions with "relative to"', () {
      expect(ContentQualityValidator.detectMetaQuestion(
        'Which is relative to division in mathematics?'
      ), isTrue);
    });

    test('Detects meta-questions with "concept in"', () {
      expect(ContentQualityValidator.detectMetaQuestion(
        'What concept in physics relates to force?'
      ), isTrue);
    });

    test('Detects meta-questions with "used for"', () {
      expect(ContentQualityValidator.detectMetaQuestion(
        'What is multiplication used for?'
      ), isTrue);
    });

    test('Does NOT flag actual math questions', () {
      expect(ContentQualityValidator.detectMetaQuestion(
        'What is 7 × 8?'
      ), isFalse);
      
      expect(ContentQualityValidator.detectMetaQuestion(
        'If 6 boxes have 4 apples each, how many apples total?'
      ), isFalse);
    });

    test('Does NOT flag actual physics questions', () {
      expect(ContentQualityValidator.detectMetaQuestion(
        'What is the force when mass is 5kg and acceleration is 2m/s²?'
      ), isFalse);
    });
  });

  group('Phase C Task C8: Subject Content Verification', () {
    test('Verifies math content with numbers', () {
      final question = Question(
        id: '1',
        questionText: 'What is 15 + 27?',
        options: ['40', '42', '44', '46'],
        correctAnswer: '42',
        type: QuestionType.multipleChoice,
        explanation: '15 + 27 = 42',
        subject: SubjectType.math,
      );

      expect(ContentQualityValidator.verifySubjectContent(question, SubjectType.math), isTrue);
    });

    test('Verifies math content with operators', () {
      final question = Question(
        id: '2',
        questionText: 'Solve: 2x + 5 = 13',
        options: ['3', '4', '5', '6'],
        correctAnswer: '4',
        type: QuestionType.multipleChoice,
        explanation: '2x = 8, x = 4',
        subject: SubjectType.math,
      );

      expect(ContentQualityValidator.verifySubjectContent(question, SubjectType.math), isTrue);
    });

    test('Rejects math questions without mathematical content', () {
      final question = Question(
        id: '3',
        questionText: 'Which is important for mathematics?',
        options: ['Addition', 'Subtraction', 'Both', 'Neither'],
        correctAnswer: 'Both',
        type: QuestionType.multipleChoice,
        explanation: 'Both are important',
        subject: SubjectType.math,
      );

      expect(ContentQualityValidator.verifySubjectContent(question, SubjectType.math), isFalse);
    });

    test('Verifies physics content with units', () {
      final question = Question(
        id: '4',
        questionText: 'What is the velocity if distance is 100m and time is 10s?',
        options: ['5 m/s', '10 m/s', '15 m/s', '20 m/s'],
        correctAnswer: '10 m/s',
        type: QuestionType.multipleChoice,
        explanation: 'v = d/t = 100/10 = 10 m/s',
        subject: SubjectType.physics,
      );

      expect(ContentQualityValidator.verifySubjectContent(question, SubjectType.physics), isTrue);
    });

    test('Verifies chemistry content with formulas', () {
      final question = Question(
        id: '5',
        questionText: 'What is the chemical formula for water?',
        options: ['H2O', 'CO2', 'O2', 'H2'],
        correctAnswer: 'H2O',
        type: QuestionType.multipleChoice,
        explanation: 'Water is H2O',
        subject: SubjectType.chemistry,
      );

      expect(ContentQualityValidator.verifySubjectContent(question, SubjectType.chemistry), isTrue);
    });

    test('Verifies biology content with biological terms', () {
      final question = Question(
        id: '6',
        questionText: 'What is the powerhouse of the cell?',
        options: ['Nucleus', 'Mitochondria', 'Ribosome', 'Chloroplast'],
        correctAnswer: 'Mitochondria',
        type: QuestionType.multipleChoice,
        explanation: 'Mitochondria produces energy',
        subject: SubjectType.biology,
      );

      expect(ContentQualityValidator.verifySubjectContent(question, SubjectType.biology), isTrue);
    });
  });

  group('Phase C Task C8: Option Quality Checks', () {
    test('Accepts meaningful options', () {
      final options = ['42', '43', '44', '45'];
      expect(ContentQualityValidator.checkOptionQuality(options), isTrue);
    });

    test('Rejects generic single-letter options', () {
      final options = ['A', 'B', 'C', 'D'];
      expect(ContentQualityValidator.checkOptionQuality(options), isFalse);
    });

    test('Rejects duplicate options', () {
      final options = ['42', '42', '43', '44'];
      expect(ContentQualityValidator.checkOptionQuality(options), isFalse);
    });

    test('Rejects too few options', () {
      final options = ['42'];
      expect(ContentQualityValidator.checkOptionQuality(options), isFalse);
    });

    test('Accepts options with context', () {
      final options = ['10 meters', '20 meters', '30 meters', '40 meters'];
      expect(ContentQualityValidator.checkOptionQuality(options), isTrue);
    });
  });

  group('Phase C Task C8: Quality Score Calculation', () {
    test('High-quality math question scores 100+', () {
      final question = Question(
        id: '1',
        questionText: 'What is 7 × 8?',
        options: ['54', '56', '58', '60'],
        correctAnswer: '56',
        type: QuestionType.multipleChoice,
        explanation: '7 × 8 = 56',
        hint: 'Think of 7 groups of 8',
        subject: SubjectType.math,
      );

      final score = ContentQualityValidator.calculateQualityScore(question, SubjectType.math);
      expect(score, greaterThanOrEqualTo(100));
    });

    test('Meta-question scores low', () {
      final question = Question(
        id: '2',
        questionText: 'Which is important for multiplication?',
        options: ['Numbers', 'Addition', 'Both', 'Neither'],
        correctAnswer: 'Both',
        type: QuestionType.multipleChoice,
        explanation: 'Both are important',
        subject: SubjectType.math,
      );

      final score = ContentQualityValidator.calculateQualityScore(question, SubjectType.math);
      expect(score, lessThan(70));
    });

    test('Question without subject content scores low', () {
      final question = Question(
        id: '3',
        questionText: 'What is the concept?',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'A',
        type: QuestionType.multipleChoice,
        explanation: 'Generic answer',
        subject: SubjectType.math,
      );

      final score = ContentQualityValidator.calculateQualityScore(question, SubjectType.math);
      expect(score, lessThan(70));
    });

    test('Question with poor options scores low', () {
      final question = Question(
        id: '4',
        questionText: 'What is 5 + 3?',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'A',
        type: QuestionType.multipleChoice,
        explanation: '5 + 3 = 8',
        subject: SubjectType.math,
      );

      final score = ContentQualityValidator.calculateQualityScore(question, SubjectType.math);
      expect(score, lessThan(90));
    });
  });

  group('Phase C Task C8: Question Filtering', () {
    test('Filters out low-quality questions', () {
      final questions = <Question>[
        Question(
          id: '1',
          questionText: 'What is 7 × 8?',
          options: ['54', '56', '58', '60'],
          correctAnswer: '56',
          type: QuestionType.multipleChoice,
          explanation: '7 × 8 = 56',
          subject: SubjectType.math,
        ),
        Question(
          id: '2',
          questionText: 'Which is important for multiplication?',
          options: ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          type: QuestionType.multipleChoice,
          explanation: 'Generic',
          subject: SubjectType.math,
        ),
        Question(
          id: '3',
          questionText: 'What is 12 ÷ 3?',
          options: ['3', '4', '5', '6'],
          correctAnswer: '4',
          type: QuestionType.multipleChoice,
          explanation: '12 ÷ 3 = 4',
          subject: SubjectType.math,
        ),
      ];

      final filtered = ContentQualityValidator.filterHighQualityQuestions(
        questions,
        SubjectType.math,
        minScore: 70,
      );

      expect(filtered.length, equals(2)); // Should keep questions 1 and 3
      expect(filtered[0].id, equals('1'));
      expect(filtered[1].id, equals('3'));
    });

    test('Keeps all high-quality questions', () {
      final questions = <Question>[
        Question(
          id: '1',
          questionText: 'What is 7 × 8?',
          options: ['54', '56', '58', '60'],
          correctAnswer: '56',
          type: QuestionType.multipleChoice,
          explanation: '7 × 8 = 56',
          subject: SubjectType.math,
        ),
        Question(
          id: '2',
          questionText: 'What is 12 ÷ 3?',
          options: ['3', '4', '5', '6'],
          correctAnswer: '4',
          type: QuestionType.multipleChoice,
          explanation: '12 ÷ 3 = 4',
          subject: SubjectType.math,
        ),
      ];

      final filtered = ContentQualityValidator.filterHighQualityQuestions(
        questions,
        SubjectType.math,
        minScore: 70,
      );

      expect(filtered.length, equals(2));
    });
  });

  group('Phase C Task C8: Validation Reports', () {
    test('Generates detailed validation report', () {
      final question = Question(
        id: '1',
        questionText: 'What is 7 × 8?',
        options: ['54', '56', '58', '60'],
        correctAnswer: '56',
        type: QuestionType.multipleChoice,
        explanation: '7 × 8 = 56',
        hint: 'Think of 7 groups of 8',
        subject: SubjectType.math,
      );

      final report = ContentQualityValidator.getValidationReport(question, SubjectType.math);

      expect(report['question_text'], equals('What is 7 × 8?'));
      expect(report['quality_score'], greaterThanOrEqualTo(100));
      expect(report['is_meta_question'], isFalse);
      expect(report['has_subject_content'], isTrue);
      expect(report['has_good_options'], isTrue);
      expect(report['has_explanation'], isTrue);
      expect(report['has_hint'], isTrue);
      expect(report['passes_validation'], isTrue);
    });

    test('Report identifies meta-question', () {
      final question = Question(
        id: '2',
        questionText: 'Which is important for multiplication?',
        options: ['Numbers', 'Addition', 'Both', 'Neither'],
        correctAnswer: 'Both',
        type: QuestionType.multipleChoice,
        explanation: 'Both are important',
        subject: SubjectType.math,
      );

      final report = ContentQualityValidator.getValidationReport(question, SubjectType.math);

      expect(report['is_meta_question'], isTrue);
      expect(report['passes_validation'], isFalse);
    });
  });
}

