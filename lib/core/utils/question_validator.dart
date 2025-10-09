import 'package:flutter/foundation.dart';
import 'package:sp/core/models/question.dart';

/// Runtime question validator to ensure questions can be displayed properly
class QuestionValidator {
  /// Validate a question and return whether it's displayable
  static bool isQuestionValid(Question question) {
    return validateQuestion(question).isValid;
  }

  /// Validate a question and return detailed result
  static QuestionValidationResult validateQuestion(Question question) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check question text
    if (question.questionText.trim().isEmpty) {
      errors.add('Question text is empty');
    }

    // Check question type specific requirements
    switch (question.type) {
      case QuestionType.multipleChoice:
        if (question.options.isEmpty) {
          errors.add('Multiple choice question has no options');
        } else if (question.options.length < 2) {
          errors.add('Multiple choice question must have at least 2 options');
        }
        if (question.correctAnswer.isEmpty) {
          errors.add('Multiple choice question has no correct answer');
        } else if (!question.options.contains(question.correctAnswer)) {
          errors.add('Correct answer "${question.correctAnswer}" not found in options');
        }
        break;

      case QuestionType.trueFalse:
        if (question.options.isEmpty) {
          errors.add('True/False question has no options');
        } else if (question.options.length != 2) {
          warnings.add('True/False question should have exactly 2 options');
        }
        if (question.correctAnswer.isEmpty) {
          errors.add('True/False question has no correct answer');
        }
        break;

      case QuestionType.dragDrop:
        if (question.options.isEmpty) {
          errors.add('Drag & Drop question has no options');
        } else {
          // Check for LEFT: and RIGHT: format
          final hasLeft = question.options.any((opt) => opt.startsWith('LEFT:'));
          final hasRight = question.options.any((opt) => opt.startsWith('RIGHT:'));
          if (!hasLeft || !hasRight) {
            errors.add('Drag & Drop question must have LEFT: and RIGHT: options');
          }
        }
        if (question.correctAnswer.isEmpty) {
          errors.add('Drag & Drop question has no correct answer');
        }
        break;

      case QuestionType.clickableAnswer:
        if (question.options.isEmpty) {
          errors.add('Clickable answer question has no options');
        }
        if (question.correctAnswer.isEmpty) {
          errors.add('Clickable answer question has no correct answer');
        }
        break;

      case QuestionType.fillInTheBlank:
        if (question.correctAnswer.isEmpty) {
          errors.add('Fill in the blank question has no correct answer');
        }
        break;

      case QuestionType.numericInput:
        if (question.correctAnswer.isEmpty) {
          errors.add('Numeric input question has no correct answer');
        }
        break;

      case QuestionType.shortAnswer:
        if (question.correctAnswer.isEmpty) {
          errors.add('Short answer question has no correct answer');
        }
        break;
    }

    return QuestionValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      question: question,
    );
  }

  /// Filter out invalid questions from a list
  static List<Question> filterValidQuestions(List<Question> questions) {
    final validQuestions = <Question>[];
    
    for (final question in questions) {
      final result = validateQuestion(question);
      if (result.isValid) {
        validQuestions.add(question);
      } else if (kDebugMode) {
        print('⚠️ Invalid question filtered out: ${question.id}');
        print('   Type: ${question.type.name}');
        print('   Errors: ${result.errors.join(', ')}');
      }
    }
    
    return validQuestions;
  }

  /// Attempt to fix common question issues
  static Question fixQuestion(Question question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        if (question.options.isEmpty && question.correctAnswer.isNotEmpty) {
          // Generate default options based on correct answer
          final correct = question.correctAnswer;
          return question.copyWith(
            options: [correct, 'Option A', 'Option B', 'Option C'],
          );
        }
        break;

      case QuestionType.trueFalse:
        if (question.options.isEmpty) {
          return question.copyWith(options: ['True', 'False']);
        }
        if (question.options.length == 1) {
          final existing = question.options.first;
          final other = existing.toLowerCase() == 'true' ? 'False' : 'True';
          return question.copyWith(options: [existing, other]);
        }
        break;

      case QuestionType.clickableAnswer:
        if (question.options.isEmpty && question.correctAnswer.isNotEmpty) {
          // Generate options from correct answer (comma-separated)
          final answers = question.correctAnswer.split(',').map((s) => s.trim()).toList();
          final allOptions = [...answers, 'Option A', 'Option B', 'Option C'];
          return question.copyWith(options: allOptions);
        }
        break;

      case QuestionType.dragDrop:
      case QuestionType.numericInput:
      case QuestionType.fillInTheBlank:
      case QuestionType.shortAnswer:
        // Cannot auto-fix these types
        break;
    }

    return question;
  }

  /// Validate and fix a list of questions
  static List<Question> validateAndFixQuestions(List<Question> questions) {
    final fixedQuestions = <Question>[];
    
    for (final question in questions) {
      final result = validateQuestion(question);
      
      if (result.isValid) {
        fixedQuestions.add(question);
      } else {
        // Try to fix the question
        final fixed = fixQuestion(question);
        final fixedResult = validateQuestion(fixed);
        
        if (fixedResult.isValid) {
          if (kDebugMode) {
            print('✅ Fixed question: ${question.id}');
          }
          fixedQuestions.add(fixed);
        } else {
          if (kDebugMode) {
            print('❌ Could not fix question: ${question.id}');
            print('   Errors: ${fixedResult.errors.join(', ')}');
          }
        }
      }
    }
    
    return fixedQuestions;
  }

  /// Log validation summary for debugging
  static void logValidationSummary(List<Question> questions) {
    if (!kDebugMode) return;

    final results = questions.map((q) => validateQuestion(q)).toList();
    final validCount = results.where((r) => r.isValid).length;
    final invalidCount = results.length - validCount;
    final warningCount = results.where((r) => r.warnings.isNotEmpty).length;

    print('');
    print('═══════════════════════════════════════');
    print('📊 Question Validation Summary');
    print('═══════════════════════════════════════');
    print('Total questions: ${questions.length}');
    print('✅ Valid: $validCount');
    print('❌ Invalid: $invalidCount');
    print('⚠️  With warnings: $warningCount');
    
    if (invalidCount > 0) {
      print('');
      print('Invalid Questions:');
      for (final result in results.where((r) => !r.isValid)) {
        print('  • ${result.question.id} (${result.question.type.name})');
        for (final error in result.errors) {
          print('    - $error');
        }
      }
    }
    
    print('═══════════════════════════════════════');
    print('');
  }
}

/// Result of question validation
class QuestionValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Question question;

  const QuestionValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.question,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  String get summary {
    if (isValid && !hasWarnings) {
      return 'Valid';
    } else if (isValid && hasWarnings) {
      return 'Valid with ${warnings.length} warning(s)';
    } else {
      return 'Invalid: ${errors.length} error(s)';
    }
  }
}

