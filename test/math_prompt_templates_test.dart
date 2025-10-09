import 'package:flutter_test/flutter_test.dart';
import 'package:sp/core/services/ai_prompt_templates.dart';
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
      
      expect(registry.hasTemplate(SubjectType.math, 'addition_subtraction'), isTrue);
      expect(registry.hasTemplate(SubjectType.math, 'multiplication_division'), isTrue);
      expect(registry.hasTemplate(SubjectType.math, 'fractions'), isTrue);
      expect(registry.hasTemplate(SubjectType.math, 'decimals'), isTrue);
      expect(registry.hasTemplate(SubjectType.math, 'algebra'), isTrue);
      expect(registry.hasTemplate(SubjectType.math, 'geometry'), isTrue);
    });

    test('Addition/Subtraction template has correct structure', () {
      final template = registry.getTemplate(SubjectType.math, 'addition_subtraction');
      
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
      final template = registry.getTemplate(SubjectType.math, 'multiplication_division');
      
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
      final template = registry.getTemplate(SubjectType.math, 'fractions');
      
      expect(template, isNotNull);
      expect(template!.skillName, equals('Fractions'));
      expect(template.gradeLevel, equals('Grades 4-7'));
      expect(template.conceptsToTest.length, greaterThan(5));
    });

    test('Decimals template has correct structure', () {
      final template = registry.getTemplate(SubjectType.math, 'decimals');
      
      expect(template, isNotNull);
      expect(template!.skillName, equals('Decimals'));
      expect(template.gradeLevel, equals('Grades 4-7'));
    });

    test('Algebra template has correct structure', () {
      final template = registry.getTemplate(SubjectType.math, 'algebra');
      
      expect(template, isNotNull);
      expect(template!.skillName, equals('Algebra'));
      expect(template.gradeLevel, equals('Grades 6-9'));
    });

    test('Geometry template has correct structure', () {
      final template = registry.getTemplate(SubjectType.math, 'geometry');
      
      expect(template, isNotNull);
      expect(template!.skillName, equals('Geometry'));
      expect(template.gradeLevel, equals('Grades 5-9'));
    });

    test('buildPrompt generates comprehensive prompt for level 1', () {
      final template = registry.getTemplate(SubjectType.math, 'addition_subtraction')!;
      final prompt = template.buildPrompt(level: 1, questionCount: 7);
      
      // Check prompt contains key sections
      expect(prompt.contains('SKILL: Addition and Subtraction'), isTrue);
      expect(prompt.contains('GRADE LEVEL: Grades 1-5'), isTrue);
      expect(prompt.contains('DIFFICULTY: Level 1'), isTrue);
      expect(prompt.contains('CONCEPTS TO TEST:'), isTrue);
      expect(prompt.contains('QUESTION FORMATS:'), isTrue);
      expect(prompt.contains('EXAMPLE QUESTIONS FOR LEVEL 1:'), isTrue);
      expect(prompt.contains('CRITICAL REQUIREMENTS:'), isTrue);
      
      // Check critical instructions are present
      expect(prompt.contains('Test actual math knowledge, NOT meta-knowledge'), isTrue);
      expect(prompt.contains('Use specific numbers'), isTrue);
      expect(prompt.contains('Avoid meta-questions'), isTrue);
      
      // Check example questions are included
      expect(prompt.contains('What is 5 + 3?'), isTrue);
      expect(prompt.contains('Answer: 8'), isTrue);
    });

    test('buildPrompt generates comprehensive prompt for level 5', () {
      final template = registry.getTemplate(SubjectType.math, 'multiplication_division')!;
      final prompt = template.buildPrompt(level: 5, questionCount: 7);
      
      expect(prompt.contains('DIFFICULTY: Level 5'), isTrue);
      expect(prompt.contains('EXAMPLE QUESTIONS FOR LEVEL 5:'), isTrue);
      expect(prompt.contains('What is 8 × 7?'), isTrue);
      expect(prompt.contains('RELEVANT FORMULAS:'), isTrue);
      expect(prompt.contains('COMMON STUDENT MISTAKES'), isTrue);
    });

    test('buildPrompt generates comprehensive prompt for level 10', () {
      final template = registry.getTemplate(SubjectType.math, 'algebra')!;
      final prompt = template.buildPrompt(level: 10, questionCount: 7);
      
      expect(prompt.contains('DIFFICULTY: Level 10'), isTrue);
      expect(prompt.contains('EXAMPLE QUESTIONS FOR LEVEL 10:'), isTrue);
      expect(prompt.contains('Generate exactly 7 questions'), isTrue);
    });

    test('Difficulty scaling works correctly', () {
      final template = registry.getTemplate(SubjectType.math, 'addition_subtraction')!;
      
      // Level 1-3 should use first difficulty range
      final prompt1 = template.buildPrompt(level: 1, questionCount: 7);
      expect(prompt1.contains('Numbers 0-20'), isTrue);
      expect(prompt1.contains('single-digit operations'), isTrue);
      
      // Level 5 should use second difficulty range
      final prompt5 = template.buildPrompt(level: 5, questionCount: 7);
      expect(prompt5.contains('Numbers 0-100'), isTrue);
      expect(prompt5.contains('two-digit operations'), isTrue);
      
      // Level 10 should use third difficulty range
      final prompt10 = template.buildPrompt(level: 10, questionCount: 7);
      expect(prompt10.contains('Numbers 0-1000'), isTrue);
      expect(prompt10.contains('three-digit operations'), isTrue);
    });

    test('Example questions are appropriate for each level', () {
      final template = registry.getTemplate(SubjectType.math, 'multiplication_division')!;
      
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
      final multiplicationTemplate = registry.getTemplate(SubjectType.math, 'multiplication_division')!;
      expect(multiplicationTemplate.formulas, isNotNull);
      expect(multiplicationTemplate.formulas!.length, greaterThan(0));
      expect(multiplicationTemplate.formulas!.any((f) => f.contains('commutative')), isTrue);
      
      final geometryTemplate = registry.getTemplate(SubjectType.math, 'geometry')!;
      expect(geometryTemplate.formulas, isNotNull);
      expect(geometryTemplate.formulas!.any((f) => f.contains('Pythagorean')), isTrue);
    });

    test('Common mistakes are included to help create distractors', () {
      final template = registry.getTemplate(SubjectType.math, 'addition_subtraction')!;
      expect(template.commonMistakes, isNotNull);
      expect(template.commonMistakes!.length, greaterThan(0));
      expect(template.commonMistakes!.any((m) => m.contains('carry') || m.contains('borrow')), isTrue);
    });

    test('Prompt includes JSON output format specification', () {
      final template = registry.getTemplate(SubjectType.math, 'fractions')!;
      final prompt = template.buildPrompt(level: 5, questionCount: 7);
      
      expect(prompt.contains('Return as JSON array'), isTrue);
      expect(prompt.contains('"question":'), isTrue);
      expect(prompt.contains('"options":'), isTrue);
      expect(prompt.contains('"correctAnswer":'), isTrue);
      expect(prompt.contains('"explanation":'), isTrue);
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

    test('Prompt explicitly forbids meta-questions', () {
      final template = registry.getTemplate(SubjectType.math, 'decimals')!;
      final prompt = template.buildPrompt(level: 3, questionCount: 7);
      
      expect(prompt.contains('NOT meta-knowledge'), isTrue);
      expect(prompt.contains('Avoid meta-questions'), isTrue);
      expect(prompt.contains('What is important about'), isTrue); // Shows example of what NOT to do
    });

    test('Prompt requires specific numbers and calculations', () {
      final template = registry.getTemplate(SubjectType.math, 'algebra')!;
      final prompt = template.buildPrompt(level: 7, questionCount: 7);
      
      expect(prompt.contains('specific numbers'), isTrue);
      expect(prompt.contains('concrete scenarios'), isTrue);
      expect(prompt.contains('not generic placeholders'), isTrue);
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
      final template = registry.getTemplate(SubjectType.math, 'addition_subtraction')!;
      final examples = template.exampleQuestions[1]!;
      
      for (final example in examples) {
        expect(example.question, isNotEmpty);
        expect(example.correctAnswer, isNotEmpty);
        // Explanation and options are optional but recommended
      }
    });
  });
}

