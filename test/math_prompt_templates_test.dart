import 'package:flutter_test/flutter_test.dart';
import 'package:sp/core/services/prompt_template_registry.dart';
import 'package:sp/core/services/math_prompt_templates.dart';
import 'package:sp/core/models/subject.dart';

/// Test suite for Phase C Task C2: Mathematics Prompt Templates
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase C Task C2: Mathematics Prompt Templates', () {
    late PromptTemplateRegistry registry;

    setUp(() {
      registry = PromptTemplateRegistry.instance;
      registry.clearAll();
      MathPromptTemplates.registerAll(registry);
    });

    test('All 6 math templates are registered', () {
      expect(registry.templateCount, equals(6));

      expect(registry.hasTemplate('addition_subtraction'), isTrue);
      expect(registry.hasTemplate('multiplication_division'), isTrue);
      expect(registry.hasTemplate('fractions'), isTrue);
      expect(registry.hasTemplate('decimals'), isTrue);
      expect(registry.hasTemplate('algebra'), isTrue);
      expect(registry.hasTemplate('geometry'), isTrue);
    });

    test('Addition/Subtraction template has correct structure', () {
      final template = registry.getTemplate('addition_subtraction');

      expect(template, isNotNull);
      expect(template!.skillName, equals('Addition and Subtraction'));
      expect(template.gradeLevel, equals('Grades 1-5'));
      expect(template.subject, equals(SubjectType.math));
      expect(template.conceptsToTest.length, greaterThan(5));
      expect(template.questionFormats.length, greaterThan(3));
      expect(template.difficultyScaling.length, equals(3));
      expect(template.exampleQuestions.containsKey(1), isTrue);
      expect(template.exampleQuestions.containsKey(5), isTrue);
      expect(template.exampleQuestions.containsKey(10), isTrue);
    });

    test('Multiplication/Division template has correct structure', () {
      final template = registry.getTemplate('multiplication_division');

      expect(template, isNotNull);
      expect(template!.skillName, equals('Multiplication and Division'));
      expect(template.gradeLevel, equals('Grades 3-6'));
      expect(template.conceptsToTest.length, greaterThan(5));
      expect(template.formulas, isNotNull);
      expect(template.formulas!.length, greaterThan(0));
      expect(template.commonMistakes, isNotNull);
      expect(template.commonMistakes!.length, greaterThan(0));
    });

    test('Fractions template has correct structure', () {
      final template = registry.getTemplate('fractions');

      expect(template, isNotNull);
      expect(template!.skillName, equals('Fractions'));
      expect(template.gradeLevel, equals('Grades 4-7'));
      expect(template.conceptsToTest.length, greaterThan(5));
    });

    test('Decimals template has correct structure', () {
      final template = registry.getTemplate('decimals');

      expect(template, isNotNull);
      expect(template!.skillName, equals('Decimals'));
      expect(template.gradeLevel, equals('Grades 4-7'));
    });

    test('Algebra template has correct structure', () {
      final template = registry.getTemplate('algebra');

      expect(template, isNotNull);
      expect(template!.skillName, equals('Algebra'));
      expect(template.gradeLevel, equals('Grades 6-9'));
    });

    test('Geometry template has correct structure', () {
      final template = registry.getTemplate('geometry');

      expect(template, isNotNull);
      expect(template!.skillName, equals('Geometry'));
      expect(template.gradeLevel, equals('Grades 5-9'));
    });

    test('generatePrompt generates comprehensive prompt for level 1', () {
      final template = registry.getTemplate('addition_subtraction')!;
      final prompt = template.generatePrompt(level: 1, questionCount: 7);

      expect(prompt.contains('SKILL: Addition and Subtraction'), isTrue);
      expect(prompt.contains('GRADE LEVEL: Grades 1-5'), isTrue);
      expect(prompt.contains('DIFFICULTY: Numbers 0-20'), isTrue);
      expect(prompt.contains('CONCEPTS TO TEST:'), isTrue);
      expect(prompt.contains('QUESTION FORMATS:'), isTrue);
      expect(prompt.contains('EXAMPLE QUESTIONS:'), isTrue);
      expect(prompt.contains('Generate 7 questions'), isTrue);

      expect(prompt.contains('What is 5 + 3?'), isTrue);
      expect(prompt.contains('A: 8'), isTrue);
    });

    test('generatePrompt generates comprehensive prompt for level 5', () {
      final template = registry.getTemplate('multiplication_division')!;
      final prompt = template.generatePrompt(level: 5, questionCount: 7);

      expect(prompt.contains('DIFFICULTY: Tables 1-10'), isTrue);
      expect(prompt.contains('EXAMPLE QUESTIONS:'), isTrue);
      expect(prompt.contains('What is 8 × 7?'), isTrue);
      expect(prompt.contains('RELEVANT FORMULAS:'), isTrue);
      expect(prompt.contains('COMMON MISTAKES TO AVOID:'), isTrue);
    });

    test('generatePrompt generates comprehensive prompt for level 10', () {
      final template = registry.getTemplate('algebra')!;
      final prompt = template.generatePrompt(level: 10, questionCount: 7);

      expect(prompt.contains('DIFFICULTY:'), isTrue);
      expect(prompt.contains('EXAMPLE QUESTIONS:'), isTrue);
      expect(prompt.contains('Generate 7 questions'), isTrue);
    });

    test('Difficulty scaling works correctly', () {
      final template = registry.getTemplate('addition_subtraction')!;

      // Level 1-3 should use first difficulty range
      final prompt1 = template.generatePrompt(level: 1, questionCount: 7);
      expect(prompt1.contains('Numbers 0-20'), isTrue);
      expect(prompt1.contains('single-digit operations'), isTrue);

      // Level 5 should use second difficulty range
      final prompt5 = template.generatePrompt(level: 5, questionCount: 7);
      expect(prompt5.contains('Numbers 0-100'), isTrue);
      expect(prompt5.contains('two-digit operations'), isTrue);

      // Level 10 should use third difficulty range
      final prompt10 = template.generatePrompt(level: 10, questionCount: 7);
      expect(prompt10.contains('Numbers 0-1000'), isTrue);
      expect(prompt10.contains('three-digit operations'), isTrue);
    });

    test('Example questions are appropriate for each level', () {
      final template = registry.getTemplate('multiplication_division')!;

      // Level 1 examples should be simple
      final examples1 = template.exampleQuestions[1]!;
      expect(examples1.length, greaterThan(0));
      expect(examples1[0].question.contains('3 × 4'), isTrue);

      // Level 5 examples should be intermediate
      final examples5 = template.exampleQuestions[5]!;
      expect(examples5.length, greaterThan(0));
      expect(examples5[0].question.contains('8 × 7') || examples5[0].question.contains('23 × 4'), isTrue);

      // Level 10 examples should be advanced
      final examples10 = template.exampleQuestions[10]!;
      expect(examples10.length, greaterThan(0));
      expect(examples10[0].question.contains('34 × 27') || examples10[0].question.contains('456 ÷ 12'), isTrue);
    });

    test('Formulas are included where appropriate', () {
      final multiplicationTemplate = registry.getTemplate('multiplication_division')!;
      expect(multiplicationTemplate.formulas, isNotNull);
      expect(multiplicationTemplate.formulas!.length, greaterThan(0));
      expect(multiplicationTemplate.formulas!.any((f) => f.contains('commutative')), isTrue);

      final geometryTemplate = registry.getTemplate('geometry')!;
      expect(geometryTemplate.formulas, isNotNull);
      expect(geometryTemplate.formulas!.any((f) => f.contains('Pythagorean')), isTrue);
    });

    test('Common mistakes are included to help create distractors', () {
      final template = registry.getTemplate('addition_subtraction')!;
      expect(template.commonMistakes, isNotNull);
      expect(template.commonMistakes!.length, greaterThan(0));
      expect(template.commonMistakes!.any((m) => m.contains('carry') || m.contains('borrow')), isTrue);
    });

    test('Prompt includes question generation guidelines', () {
      final template = registry.getTemplate('fractions')!;
      final prompt = template.generatePrompt(level: 5, questionCount: 7);

      expect(prompt.contains('following these guidelines'), isTrue);
      expect(prompt.contains('Match the difficulty level'), isTrue);
      expect(prompt.contains('Cover the specified concepts'), isTrue);
      expect(prompt.contains('Provide multiple choice options'), isTrue);
    });

    test('All templates have unique skill IDs', () {
      final templates = registry.getTemplatesForSubject(SubjectType.math);
      final skillIds = templates.map((t) => t.skillId).toSet();

      expect(skillIds.length, equals(templates.length),
        reason: 'All skill IDs should be unique');
    });

    test('getTemplatesForSubject returns only math templates', () {
      final mathTemplates = registry.getTemplatesForSubject(SubjectType.math);

      expect(mathTemplates.length, equals(6));
      expect(mathTemplates.every((t) => t.subject == SubjectType.math), isTrue);
    });

    test('Prompt lists all concepts and question formats', () {
      final template = registry.getTemplate('decimals')!;
      final prompt = template.generatePrompt(level: 3, questionCount: 7);

      for (final concept in template.conceptsToTest) {
        expect(prompt.contains(concept), isTrue);
      }
      for (final format in template.questionFormats) {
        expect(prompt.contains(format), isTrue);
      }
    });

    test('Prompt includes level-specific difficulty guidance', () {
      final template = registry.getTemplate('algebra')!;
      final prompt = template.generatePrompt(level: 7, questionCount: 7);

      expect(prompt.contains('Level 7'), isTrue);
      expect(prompt.contains('Match the difficulty level'), isTrue);
    });
  });

  group('Phase C Task C2: Template Quality Checks', () {
    late PromptTemplateRegistry registry;

    setUp(() {
      registry = PromptTemplateRegistry.instance;
      registry.clearAll();
      MathPromptTemplates.registerAll(registry);
    });

    test('All templates have at least 5 concepts to test', () {
      final templates = registry.getTemplatesForSubject(SubjectType.math);

      for (final template in templates) {
        expect(template.conceptsToTest.length, greaterThanOrEqualTo(5),
          reason: '${template.skillName} should have at least 5 concepts');
      }
    });

    test('All templates have at least 3 question formats', () {
      final templates = registry.getTemplatesForSubject(SubjectType.math);

      for (final template in templates) {
        expect(template.questionFormats.length, greaterThanOrEqualTo(3),
          reason: '${template.skillName} should have at least 3 question formats');
      }
    });

    test('All templates have difficulty scaling for 3 ranges', () {
      final templates = registry.getTemplatesForSubject(SubjectType.math);

      for (final template in templates) {
        expect(template.difficultyScaling.length, equals(3),
          reason: '${template.skillName} should have 3 difficulty ranges');
      }
    });

    test('All templates have example questions for levels 1, 5, and 10', () {
      final templates = registry.getTemplatesForSubject(SubjectType.math);

      for (final template in templates) {
        expect(template.exampleQuestions.containsKey(1), isTrue,
          reason: '${template.skillName} should have level 1 examples');
        expect(template.exampleQuestions.containsKey(5), isTrue,
          reason: '${template.skillName} should have level 5 examples');
        expect(template.exampleQuestions.containsKey(10), isTrue,
          reason: '${template.skillName} should have level 10 examples');
      }
    });

    test('Example questions have all required fields', () {
      final template = registry.getTemplate('addition_subtraction')!;
      final examples = template.exampleQuestions[1]!;

      for (final example in examples) {
        expect(example.question, isNotEmpty);
        expect(example.correctAnswer, isNotEmpty);
        // Explanation and options are optional but recommended
      }
    });
  });
}
