import 'package:flutter/foundation.dart';
import '../models/question.dart';

/// Validation result for AI-generated content quality
/// Enhanced AI Content Generation - Category E Task E2
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final double qualityScore;
  final List<String> suggestions;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.qualityScore,
    required this.suggestions,
  });

  /// Create a passing validation result
  factory ValidationResult.pass({
    List<String> warnings = const [],
    double qualityScore = 1.0,
    List<String> suggestions = const [],
  }) {
    return ValidationResult(
      isValid: true,
      errors: [],
      warnings: warnings,
      qualityScore: qualityScore,
      suggestions: suggestions,
    );
  }

  /// Create a failing validation result
  factory ValidationResult.fail({
    required List<String> errors,
    List<String> warnings = const [],
    double qualityScore = 0.0,
    List<String> suggestions = const [],
  }) {
    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
      qualityScore: qualityScore,
      suggestions: suggestions,
    );
  }

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, qualityScore: $qualityScore, '
        'errors: ${errors.length}, warnings: ${warnings.length})';
  }
}

/// Batch validation summary for multiple questions
class BatchValidationSummary {
  final int totalQuestions;
  final int validQuestions;
  final int invalidQuestions;
  final double passRate;
  final double averageQualityScore;
  final Map<String, int> commonIssues;
  final List<ValidationResult> results;

  BatchValidationSummary({
    required this.totalQuestions,
    required this.validQuestions,
    required this.invalidQuestions,
    required this.passRate,
    required this.averageQualityScore,
    required this.commonIssues,
    required this.results,
  });

  @override
  String toString() {
    return 'BatchValidationSummary(total: $totalQuestions, valid: $validQuestions, '
        'passRate: ${(passRate * 100).toStringAsFixed(1)}%, '
        'avgQuality: ${(averageQualityScore * 100).toStringAsFixed(1)}%)';
  }
}

/// Content Quality Validator for AI-generated questions
/// Focuses on AI-specific quality issues (placeholders, explanations, etc.)
/// Works alongside QuestionValidator which handles runtime validation
class ContentQualityValidator {
  // Placeholder patterns to detect
  static final List<RegExp> _placeholderPatterns = [
    RegExp(r'\[INSERT\s+\w+\]', caseSensitive: false),
    RegExp(r'\bTODO\b', caseSensitive: false),
    RegExp(r'\bPLACEHOLDER\b', caseSensitive: false),
    RegExp(r'\bXXX\b'),
    RegExp(r'\.\.\.+'),
    RegExp(r'\bTBD\b', caseSensitive: false),
    RegExp(r'\bN/?A\b', caseSensitive: false),
    RegExp(r'\b___+\b'),
    RegExp(r'\?\s*\+\s*\?\s*=\s*\?'),
    RegExp(r'x\s*=\s*___'),
  ];

  // Generic option patterns
  static final List<RegExp> _genericOptionPatterns = [
    RegExp(r'^Option\s+[A-D]$', caseSensitive: false),
    RegExp(r'^[A-D]$'),
    RegExp(r'^Answer\s+here$', caseSensitive: false),
    RegExp(r'^Fill\s+in\s+the\s+blank$', caseSensitive: false),
    RegExp(r'^Your\s+answer$', caseSensitive: false),
  ];

  /// Validate question structure
  /// Checks that all required fields are present and properly formatted
  static ValidationResult validateQuestionStructure(Question question) {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];
    int score = 20; // Start with full structure score

    // Check question text
    if (question.questionText.isEmpty) {
      errors.add('Question text is empty');
      score -= 10;
    } else if (question.questionText.length < 10) {
      warnings.add('Question text is very short (${question.questionText.length} chars)');
      suggestions.add('Consider adding more context to the question');
      score -= 3;
    }

    // Check options based on question type
    final expectedOptionCount = _getExpectedOptionCount(question.type);
    if (question.options.length != expectedOptionCount) {
      errors.add('Expected $expectedOptionCount options for ${question.type.name}, got ${question.options.length}');
      score -= 5;
    }

    // Check that options are not empty
    for (int i = 0; i < question.options.length; i++) {
      if (question.options[i].trim().isEmpty) {
        errors.add('Option ${i + 1} is empty');
        score -= 2;
      }
    }

    // Check correct answer format
    if (question.correctAnswer.isEmpty) {
      errors.add('Correct answer is empty');
      score -= 5;
    } else {
      // Validate correct answer matches question type
      if (!_validateCorrectAnswerFormat(question)) {
        errors.add('Correct answer format does not match question type ${question.type.name}');
        score -= 3;
      }
    }

    // Check explanation exists (basic check, detailed check in verifyExplanationsExist)
    if (question.explanation == null || question.explanation!.isEmpty) {
      warnings.add('Explanation is missing');
      score -= 2;
    }

    final qualityScore = (score / 20.0).clamp(0.0, 1.0);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      qualityScore: qualityScore,
      suggestions: suggestions,
    );
  }

  /// Check for placeholder text in question
  /// Detects common placeholder patterns and incomplete content
  static ValidationResult checkForPlaceholderText(Question question) {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];
    int score = 20; // Start with full placeholder score

    // Check question text for placeholders
    for (final pattern in _placeholderPatterns) {
      if (pattern.hasMatch(question.questionText)) {
        errors.add('Placeholder detected in question text: "${pattern.pattern}"');
        score -= 5;
      }
    }

    // Check options for placeholders
    for (int i = 0; i < question.options.length; i++) {
      final option = question.options[i];
      for (final pattern in _placeholderPatterns) {
        if (pattern.hasMatch(option)) {
          errors.add('Placeholder detected in option ${i + 1}: "${pattern.pattern}"');
          score -= 3;
        }
      }

      // Check for generic option text
      for (final pattern in _genericOptionPatterns) {
        if (pattern.hasMatch(option.trim())) {
          errors.add('Generic placeholder option detected: "$option"');
          score -= 4;
        }
      }
    }

    // Check explanation for placeholders
    if (question.explanation != null) {
      for (final pattern in _placeholderPatterns) {
        if (pattern.hasMatch(question.explanation!)) {
          warnings.add('Placeholder detected in explanation');
          score -= 2;
        }
      }
    }

    // Check hint for placeholders
    if (question.hint != null) {
      for (final pattern in _placeholderPatterns) {
        if (pattern.hasMatch(question.hint!)) {
          warnings.add('Placeholder detected in hint');
          score -= 1;
        }
      }
    }

    if (errors.isNotEmpty) {
      suggestions.add('Remove all placeholder text and provide actual content');
    }

    final qualityScore = (score / 20.0).clamp(0.0, 1.0);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      qualityScore: qualityScore,
      suggestions: suggestions,
    );
  }

  /// Ensure options are valid and substantive
  /// Checks for duplicates, plausibility, and quality
  static ValidationResult ensureValidOptions(Question question) {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];
    int score = 20; // Start with full options score

    // Skip validation for question types without options
    if (question.type == QuestionType.shortAnswer || 
        question.type == QuestionType.numericInput) {
      return ValidationResult.pass(qualityScore: 1.0);
    }

    // Check for duplicate options
    final uniqueOptions = question.options.toSet();
    if (uniqueOptions.length != question.options.length) {
      errors.add('Duplicate options detected');
      score -= 8;
    }

    // Check that correct answer exists in options (for multiple choice types)
    if (question.type == QuestionType.multipleChoice || 
        question.type == QuestionType.trueFalse ||
        question.type == QuestionType.clickableAnswer) {
      if (!question.options.contains(question.correctAnswer)) {
        errors.add('Correct answer "${question.correctAnswer}" not found in options');
        score -= 10;
      }
    }

    // Check option substantiveness (not just single letters)
    int shortOptions = 0;
    for (final option in question.options) {
      if (option.trim().length <= 2 && !_isValidShortOption(option, question.type)) {
        shortOptions++;
      }
    }
    if (shortOptions > 0 && question.type != QuestionType.trueFalse) {
      warnings.add('$shortOptions option(s) are very short - may not be substantive');
      score -= shortOptions * 2;
    }

    // Check for obvious patterns (all options start with same word)
    if (question.options.length >= 3) {
      final firstWords = question.options
          .map((opt) => opt.trim().split(' ').first.toLowerCase())
          .toList();
      final uniqueFirstWords = firstWords.toSet();
      if (uniqueFirstWords.length == 1 && firstWords.first.length > 3) {
        warnings.add('All options start with the same word - may indicate pattern');
        suggestions.add('Vary the structure of answer options');
        score -= 2;
      }
    }

    // For numeric questions, check reasonable range
    if (question.type == QuestionType.numericInput) {
      try {
        final correctNum = double.parse(question.correctAnswer);
        if (correctNum.abs() > 1000000) {
          warnings.add('Numeric answer is very large - ensure it\'s reasonable');
          score -= 1;
        }
      } catch (e) {
        // Not a valid number, will be caught by structure validation
      }
    }

    final qualityScore = (score / 20.0).clamp(0.0, 1.0);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      qualityScore: qualityScore,
      suggestions: suggestions,
    );
  }

  /// Verify explanations exist and are educational
  /// Checks explanation quality and helpfulness
  static ValidationResult verifyExplanationsExist(Question question) {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];
    int score = 20; // Start with full explanation score

    // Check if explanation exists
    if (question.explanation == null || question.explanation!.isEmpty) {
      errors.add('Explanation is missing');
      score = 0;
      suggestions.add('Add a clear explanation of why the answer is correct');
      
      return ValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        qualityScore: 0.0,
        suggestions: suggestions,
      );
    }

    final explanation = question.explanation!;

    // Check minimum length
    if (explanation.length < 20) {
      warnings.add('Explanation is very short (${explanation.length} chars)');
      suggestions.add('Provide more detailed explanation');
      score -= 5;
    }

    // Check that explanation doesn't just restate the answer
    final answerLower = question.correctAnswer.toLowerCase();
    final explanationLower = explanation.toLowerCase();
    if (explanationLower == answerLower || 
        explanationLower == 'the answer is $answerLower') {
      warnings.add('Explanation just restates the answer without explaining why');
      suggestions.add('Explain the reasoning or concept behind the correct answer');
      score -= 8;
    }

    // Check that explanation references the correct answer
    final containsAnswer = explanationLower.contains(answerLower) ||
        _containsAnswerConcept(explanation, question.correctAnswer);
    if (!containsAnswer && question.type != QuestionType.numericInput) {
      warnings.add('Explanation may not reference the correct answer');
      score -= 3;
    }

    // Check for educational keywords
    final educationalKeywords = [
      'because', 'therefore', 'thus', 'since', 'as', 'so',
      'this means', 'which shows', 'demonstrates', 'indicates'
    ];
    final hasEducationalLanguage = educationalKeywords.any(
      (keyword) => explanationLower.contains(keyword)
    );
    if (!hasEducationalLanguage && explanation.length > 30) {
      suggestions.add('Consider using explanatory language (because, therefore, etc.)');
      score -= 2;
    }

    final qualityScore = (score / 20.0).clamp(0.0, 1.0);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      qualityScore: qualityScore,
      suggestions: suggestions,
    );
  }

  /// Check difficulty appropriateness
  /// Validates that question complexity matches stated difficulty
  static ValidationResult checkDifficultyAppropriateness(Question question, int difficulty) {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];
    int score = 20; // Start with full difficulty score

    // Validate difficulty range
    if (difficulty < 1 || difficulty > 10) {
      errors.add('Difficulty $difficulty is out of valid range (1-10)');
      score -= 10;
    }

    // Analyze question complexity
    final complexity = _analyzeQuestionComplexity(question);

    // Check if complexity matches difficulty level
    if (difficulty <= 3) {
      // Low difficulty: should be simple
      if (complexity > 5) {
        warnings.add('Question seems complex for difficulty level $difficulty');
        suggestions.add('Simplify the question or increase difficulty level');
        score -= 5;
      }
    } else if (difficulty <= 6) {
      // Medium difficulty: moderate complexity
      if (complexity < 3) {
        warnings.add('Question seems too simple for difficulty level $difficulty');
        suggestions.add('Add complexity or decrease difficulty level');
        score -= 3;
      } else if (complexity > 8) {
        warnings.add('Question seems too complex for difficulty level $difficulty');
        suggestions.add('Simplify or increase difficulty level');
        score -= 3;
      }
    } else {
      // High difficulty: should be complex
      if (complexity < 6) {
        warnings.add('Question seems too simple for difficulty level $difficulty');
        suggestions.add('Increase complexity or decrease difficulty level');
        score -= 5;
      }
    }

    final qualityScore = (score / 20.0).clamp(0.0, 1.0);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      qualityScore: qualityScore,
      suggestions: suggestions,
    );
  }

  /// Validate a single question comprehensively
  /// Runs all validation checks and combines results
  static ValidationResult validateQuestion(Question question, {int difficulty = 5}) {
    final structureResult = validateQuestionStructure(question);
    final placeholderResult = checkForPlaceholderText(question);
    final optionsResult = ensureValidOptions(question);
    final explanationResult = verifyExplanationsExist(question);
    final difficultyResult = checkDifficultyAppropriateness(question, difficulty);

    // Combine all errors, warnings, and suggestions
    final allErrors = <String>[
      ...structureResult.errors,
      ...placeholderResult.errors,
      ...optionsResult.errors,
      ...explanationResult.errors,
      ...difficultyResult.errors,
    ];

    final allWarnings = <String>[
      ...structureResult.warnings,
      ...placeholderResult.warnings,
      ...optionsResult.warnings,
      ...explanationResult.warnings,
      ...difficultyResult.warnings,
    ];

    final allSuggestions = <String>[
      ...structureResult.suggestions,
      ...placeholderResult.suggestions,
      ...optionsResult.suggestions,
      ...explanationResult.suggestions,
      ...difficultyResult.suggestions,
    ];

    // Calculate overall quality score (weighted average)
    final overallScore = (
      structureResult.qualityScore * 0.20 +
      placeholderResult.qualityScore * 0.20 +
      optionsResult.qualityScore * 0.20 +
      explanationResult.qualityScore * 0.20 +
      difficultyResult.qualityScore * 0.20
    );

    return ValidationResult(
      isValid: allErrors.isEmpty,
      errors: allErrors,
      warnings: allWarnings,
      qualityScore: overallScore,
      suggestions: allSuggestions,
    );
  }

  /// Validate multiple questions and return summary
  static BatchValidationSummary validateQuestions(
    List<Question> questions, {
    int difficulty = 5,
  }) {
    final results = <ValidationResult>[];
    final commonIssues = <String, int>{};

    for (final question in questions) {
      final result = validateQuestion(question, difficulty: difficulty);
      results.add(result);

      // Track common issues
      for (final error in result.errors) {
        commonIssues[error] = (commonIssues[error] ?? 0) + 1;
      }
      for (final warning in result.warnings) {
        commonIssues[warning] = (commonIssues[warning] ?? 0) + 1;
      }
    }

    final validCount = results.where((r) => r.isValid).length;
    final invalidCount = results.length - validCount;
    final passRate = results.isEmpty ? 0.0 : validCount / results.length;
    final avgQuality = results.isEmpty 
        ? 0.0 
        : results.map((r) => r.qualityScore).reduce((a, b) => a + b) / results.length;

    final summary = BatchValidationSummary(
      totalQuestions: questions.length,
      validQuestions: validCount,
      invalidQuestions: invalidCount,
      passRate: passRate,
      averageQualityScore: avgQuality,
      commonIssues: commonIssues,
      results: results,
    );

    if (kDebugMode) {
      _logBatchValidationSummary(summary);
    }

    return summary;
  }

  // Helper methods

  static int _getExpectedOptionCount(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 4;
      case QuestionType.trueFalse:
        return 2;
      case QuestionType.clickableAnswer:
        return 4;
      case QuestionType.dragDrop:
        return 4; // Typically 4 items to match
      case QuestionType.numericInput:
      case QuestionType.shortAnswer:
      case QuestionType.fillInTheBlank:
        return 0; // No options needed
    }
  }

  static bool _validateCorrectAnswerFormat(Question question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
      case QuestionType.clickableAnswer:
        return question.options.contains(question.correctAnswer);
      
      case QuestionType.numericInput:
        // Should be a valid number
        return double.tryParse(question.correctAnswer) != null;
      
      case QuestionType.dragDrop:
        // Should contain LEFT: and RIGHT: format
        return question.correctAnswer.contains('LEFT:') && 
               question.correctAnswer.contains('RIGHT:');
      
      case QuestionType.fillInTheBlank:
      case QuestionType.shortAnswer:
        // Any non-empty string is valid
        return question.correctAnswer.isNotEmpty;
    }
  }

  static bool _isValidShortOption(String option, QuestionType type) {
    // True/False questions can have short options
    if (type == QuestionType.trueFalse) {
      return option.toLowerCase() == 'true' || option.toLowerCase() == 'false';
    }
    
    // Single letters or numbers might be valid for some questions
    return false;
  }

  static bool _containsAnswerConcept(String explanation, String answer) {
    // Check if explanation contains key words from the answer
    final answerWords = answer.toLowerCase().split(RegExp(r'\W+'));
    final explanationLower = explanation.toLowerCase();
    
    int matchCount = 0;
    for (final word in answerWords) {
      if (word.length > 3 && explanationLower.contains(word)) {
        matchCount++;
      }
    }
    
    return matchCount >= (answerWords.length * 0.5).ceil();
  }

  static int _analyzeQuestionComplexity(Question question) {
    int complexity = 0;

    // Length-based complexity
    if (question.questionText.length > 100) complexity += 2;
    if (question.questionText.length > 200) complexity += 2;

    // Word count
    final wordCount = question.questionText.split(RegExp(r'\s+')).length;
    if (wordCount > 20) complexity += 1;
    if (wordCount > 40) complexity += 2;

    // Contains numbers or formulas
    if (RegExp(r'\d+').hasMatch(question.questionText)) complexity += 1;
    if (RegExp(r'[+\-*/=]').hasMatch(question.questionText)) complexity += 1;

    // Multi-step indicators
    if (question.questionText.toLowerCase().contains('first') ||
        question.questionText.toLowerCase().contains('then') ||
        question.questionText.toLowerCase().contains('next')) {
      complexity += 2;
    }

    // Question type complexity
    switch (question.type) {
      case QuestionType.trueFalse:
        complexity += 0;
        break;
      case QuestionType.multipleChoice:
        complexity += 1;
        break;
      case QuestionType.fillInTheBlank:
        complexity += 2;
        break;
      case QuestionType.numericInput:
        complexity += 2;
        break;
      case QuestionType.dragDrop:
        complexity += 3;
        break;
      case QuestionType.clickableAnswer:
        complexity += 2;
        break;
      case QuestionType.shortAnswer:
        complexity += 3;
        break;
    }

    return complexity.clamp(0, 10);
  }

  static void _logBatchValidationSummary(BatchValidationSummary summary) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📊 Content Quality Validation Summary');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Total Questions: ${summary.totalQuestions}');
    debugPrint('Valid Questions: ${summary.validQuestions}');
    debugPrint('Invalid Questions: ${summary.invalidQuestions}');
    debugPrint('Pass Rate: ${(summary.passRate * 100).toStringAsFixed(1)}%');
    debugPrint('Average Quality Score: ${(summary.averageQualityScore * 100).toStringAsFixed(1)}%');
    
    if (summary.commonIssues.isNotEmpty) {
      debugPrint('\n🔍 Common Issues:');
      final sortedIssues = summary.commonIssues.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sortedIssues.take(5)) {
        debugPrint('  • ${entry.key}: ${entry.value} occurrence(s)');
      }
    }
    debugPrint('═══════════════════════════════════════════════════════\n');
  }
}

