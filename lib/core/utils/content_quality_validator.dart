import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../models/subject.dart';

/// Content Quality Validator for Phase C Task C8
/// Detects meta-questions and validates subject-specific content quality
class ContentQualityValidator {
  // Meta-question detection patterns
  static const List<String> _metaQuestionPhrases = [
    'important for',
    'relative to',
    'concept in',
    'used for',
    'helps with',
    'related to',
    'associated with',
    'relevant to',
    'connected to',
    'applies to',
    'which of the following is',
    'what is the importance',
    'why is it important',
    'what makes it important',
    'how does it relate',
  ];

  // Generic/placeholder option patterns
  static const List<String> _genericOptionPatterns = [
    r'^[A-D]$',  // Just single letters A, B, C, D
    'option a',
    'option b',
    'option c',
    'option d',
    'answer 1',
    'answer 2',
    'choice 1',
    'choice 2',
  ];

  /// Detect if a question is a meta-question (asks ABOUT the subject rather than testing knowledge)
  static bool detectMetaQuestion(String questionText) {
    final lowerQuestion = questionText.toLowerCase();
    
    for (final phrase in _metaQuestionPhrases) {
      if (lowerQuestion.contains(phrase)) {
        if (kDebugMode) {
          debugPrint('[ContentQualityValidator] ⚠️ Meta-question detected: "$phrase" in "$questionText"');
        }
        return true;
      }
    }
    
    return false;
  }

  /// Verify that question contains subject-specific content
  static bool verifySubjectContent(Question question, SubjectType subject) {
    final questionText = question.questionText.toLowerCase();
    final allOptions = question.options.join(' ').toLowerCase();
    final allText = '$questionText $allOptions';
    
    switch (subject) {
      case SubjectType.math:
        return _verifyMathContent(allText);
      
      case SubjectType.physics:
        return _verifyPhysicsContent(allText);
      
      case SubjectType.chemistry:
        return _verifyChemistryContent(allText);
      
      case SubjectType.biology:
        return _verifyBiologyContent(allText);
      
      default:
        // For other subjects, do basic validation
        return questionText.length > 10 && question.options.length >= 2;
    }
  }

  /// Verify math-specific content
  static bool _verifyMathContent(String text) {
    // Math questions should contain numbers or mathematical symbols
    final mathPatterns = [
      RegExp(r'\d+'),                    // Contains numbers
      RegExp(r'[+\-×÷=<>]'),            // Contains math operators
      RegExp(r'\b(add|subtract|multiply|divide|sum|difference|product|quotient)\b'),
      RegExp(r'\b(fraction|decimal|percent|equation|formula)\b'),
      RegExp(r'\b(area|perimeter|volume|angle|triangle|circle|square)\b'),
      RegExp(r'[xy]='),                  // Contains variables/equations
    ];
    
    for (final pattern in mathPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    
    if (kDebugMode) {
      debugPrint('[ContentQualityValidator] ⚠️ Math question lacks mathematical content');
    }
    return false;
  }

  /// Verify physics-specific content
  static bool _verifyPhysicsContent(String text) {
    // Physics questions should contain units, formulas, or physics terms
    final physicsPatterns = [
      RegExp(r'\b(meter|kilogram|second|newton|joule|watt|volt|ampere)\b'),
      RegExp(r'\b(m/s|kg|N|J|W|V|A|Hz)\b'),
      RegExp(r'\b(force|energy|power|velocity|acceleration|mass|momentum)\b'),
      RegExp(r'\b(gravity|friction|motion|speed|distance|time)\b'),
      RegExp(r'\d+\s*(m|kg|s|N|J|W)'),  // Number with unit
    ];
    
    for (final pattern in physicsPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    
    if (kDebugMode) {
      debugPrint('[ContentQualityValidator] ⚠️ Physics question lacks physics-specific content');
    }
    return false;
  }

  /// Verify chemistry-specific content
  static bool _verifyChemistryContent(String text) {
    // Chemistry questions should contain chemical formulas, elements, or chemistry terms
    final chemistryPatterns = [
      RegExp(r'\b(h2o|co2|nacl|o2|h2|n2)\b', caseSensitive: false),  // Common formulas
      RegExp(r'\b(hydrogen|oxygen|carbon|nitrogen|sodium|chlorine)\b', caseSensitive: false),
      RegExp(r'\b(atom|molecule|element|compound|reaction|bond)\b', caseSensitive: false),
      RegExp(r'\b(acid|base|ph|ion|electron|proton|neutron)\b', caseSensitive: false),
      RegExp(r'\b(water|chemical|formula)\b', caseSensitive: false),
    ];

    for (final pattern in chemistryPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }

    if (kDebugMode) {
      debugPrint('[ContentQualityValidator] ⚠️ Chemistry question lacks chemistry-specific content');
    }
    return false;
  }

  /// Verify biology-specific content
  static bool _verifyBiologyContent(String text) {
    // Biology questions should contain biological terms
    final biologyPatterns = [
      RegExp(r'\b(cell|DNA|RNA|gene|protein|enzyme|organism)\b'),
      RegExp(r'\b(plant|animal|bacteria|virus|fungi)\b'),
      RegExp(r'\b(photosynthesis|respiration|evolution|ecosystem)\b'),
      RegExp(r'\b(heart|lung|brain|blood|tissue|organ)\b'),
    ];
    
    for (final pattern in biologyPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    
    if (kDebugMode) {
      debugPrint('[ContentQualityValidator] ⚠️ Biology question lacks biology-specific content');
    }
    return false;
  }

  /// Check if options are meaningful (not just generic placeholders)
  static bool checkOptionQuality(List<String> options) {
    if (options.length < 2) {
      if (kDebugMode) {
        debugPrint('[ContentQualityValidator] ⚠️ Too few options: ${options.length}');
      }
      return false;
    }
    
    // Check for generic patterns
    int genericCount = 0;
    for (final option in options) {
      final lowerOption = option.toLowerCase().trim();
      
      // Check if option is too short (likely generic)
      if (lowerOption.length < 2) {
        genericCount++;
        continue;
      }
      
      // Check against generic patterns
      for (final pattern in _genericOptionPatterns) {
        if (RegExp(pattern, caseSensitive: false).hasMatch(lowerOption)) {
          genericCount++;
          break;
        }
      }
    }
    
    // If more than half the options are generic, fail
    if (genericCount > options.length / 2) {
      if (kDebugMode) {
        debugPrint('[ContentQualityValidator] ⚠️ Too many generic options: $genericCount/${options.length}');
      }
      return false;
    }
    
    // Check for duplicate options
    final uniqueOptions = options.map((o) => o.toLowerCase().trim()).toSet();
    if (uniqueOptions.length < options.length) {
      if (kDebugMode) {
        debugPrint('[ContentQualityValidator] ⚠️ Duplicate options detected');
      }
      return false;
    }
    
    return true;
  }

  /// Calculate overall quality score (0-100)
  static int calculateQualityScore(Question question, SubjectType subject) {
    int score = 100;
    
    // Check 1: Meta-question detection (-50 points)
    if (detectMetaQuestion(question.questionText)) {
      score -= 50;
    }

    // Check 2: Subject-specific content (-30 points if missing)
    if (!verifySubjectContent(question, subject)) {
      score -= 30;
    }

    // Check 3: Option quality (-20 points if poor)
    if (!checkOptionQuality(question.options)) {
      score -= 20;
    }

    // Check 4: Question length (too short = -10 points)
    if (question.questionText.length < 15) {
      score -= 10;
    }

    // Check 5: Has explanation (+10 bonus if present)
    if (question.explanation.isNotEmpty) {
      score += 10;
    }

    // Check 6: Has hint (+5 bonus if present)
    if (question.hint != null && question.hint!.isNotEmpty) {
      score += 5;
    }

    // Clamp score to 0-100 range
    score = score.clamp(0, 100);

    if (kDebugMode && score < 70) {
      debugPrint('[ContentQualityValidator] ⚠️ Low quality score: $score for "${question.questionText}"');
    }
    
    return score;
  }

  /// Validate a list of questions and return only high-quality ones
  static List<Question> filterHighQualityQuestions(
    List<Question> questions,
    SubjectType subject, {
    int minScore = 70,
  }) {
    final highQuality = <Question>[];
    
    for (final question in questions) {
      final score = calculateQualityScore(question, subject);
      
      if (score >= minScore) {
        highQuality.add(question);
      } else {
        if (kDebugMode) {
          debugPrint('[ContentQualityValidator] ❌ Rejected question (score: $score): "${question.questionText}"');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('[ContentQualityValidator] ✅ Filtered ${questions.length} questions → ${highQuality.length} high-quality (${(highQuality.length / questions.length * 100).toStringAsFixed(1)}%)');
    }

    return highQuality;
  }

  /// Get detailed validation report for a question
  static Map<String, dynamic> getValidationReport(Question question, SubjectType subject) {
    final isMetaQuestion = detectMetaQuestion(question.questionText);
    final hasSubjectContent = verifySubjectContent(question, subject);
    final hasGoodOptions = checkOptionQuality(question.options);
    final qualityScore = calculateQualityScore(question, subject);

    return {
      'question_text': question.questionText,
      'quality_score': qualityScore,
      'is_meta_question': isMetaQuestion,
      'has_subject_content': hasSubjectContent,
      'has_good_options': hasGoodOptions,
      'question_length': question.questionText.length,
      'option_count': question.options.length,
      'has_explanation': question.explanation.isNotEmpty,
      'has_hint': question.hint != null && question.hint!.isNotEmpty,
      'passes_validation': qualityScore >= 70,
    };
  }
}

