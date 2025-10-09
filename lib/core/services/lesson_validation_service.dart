import 'dart:convert';
import '../models/subject.dart';
import '../models/question.dart';

/// Comprehensive validation service for lesson completeness and quality
/// Ensures each lesson contains exactly one question of each of the 7 types
class LessonValidationService {
  
  /// Validation result structure
  static const List<QuestionType> requiredQuestionTypes = QuestionType.values;
  
  /// Validate a complete lesson for all requirements
  Future<LessonValidationResult> validateLesson({
    required List<Question> questions,
    required SubjectType subject,
    required String skillId,
    required int difficulty,
    Map<String, dynamic>? metadata,
  }) async {
    final result = LessonValidationResult();
    
    try {
      // Basic validation
      result.basicValidation = await _performBasicValidation(questions);
      
      // Question type completeness validation
      result.typeCompletenessValidation = await _validateQuestionTypeCompleteness(questions);
      
      // Question quality validation
      result.qualityValidation = await _validateQuestionQuality(questions);
      
      // Subject alignment validation
      result.subjectAlignmentValidation = await _validateSubjectAlignment(questions, subject);
      
      // Difficulty consistency validation
      result.difficultyValidation = await _validateDifficultyConsistency(questions, difficulty);
      
      // Content uniqueness validation
      result.uniquenessValidation = await _validateContentUniqueness(questions);
      
      // Calculate overall validation score
      result.overallScore = _calculateOverallScore(result);
      result.isValid = result.overallScore >= 0.8; // 80% threshold
      
      // Generate recommendations
      result.recommendations = _generateRecommendations(result);
      
      result.validationTimestamp = DateTime.now();
      
    } catch (e) {
      result.validationError = 'Validation failed: $e';
      result.isValid = false;
    }
    
    return result;
  }

  /// Perform basic validation checks
  Future<BasicValidationResult> _performBasicValidation(List<Question> questions) async {
    final result = BasicValidationResult();
    
    // Check if questions list is not empty
    result.hasQuestions = questions.isNotEmpty;
    
    // Check if we have exactly 7 questions (one for each type)
    result.hasCorrectCount = questions.length == requiredQuestionTypes.length;
    
    // Check if all questions have required fields
    result.allQuestionsComplete = questions.every((q) => 
        q.questionText.isNotEmpty &&
        q.correctAnswer.isNotEmpty &&
        q.type != null
    );
    
    // Check for null or invalid questions
    result.noNullQuestions = questions.every((q) => q.questionText.isNotEmpty);
    
    result.isValid = result.hasQuestions && 
                    result.hasCorrectCount && 
                    result.allQuestionsComplete && 
                    result.noNullQuestions;
    
    return result;
  }

  /// Validate question type completeness
  Future<TypeCompletenessValidationResult> _validateQuestionTypeCompleteness(List<Question> questions) async {
    final result = TypeCompletenessValidationResult();
    
    final presentTypes = questions.map((q) => q.type).toSet();
    final requiredTypesSet = requiredQuestionTypes.toSet();
    
    result.presentTypes = presentTypes.map((t) => t.name).toList();
    result.requiredTypes = requiredTypesSet.map((t) => t.name).toList();
    result.missingTypes = requiredTypesSet.difference(presentTypes).map((t) => t.name).toList();
    result.extraTypes = presentTypes.difference(requiredTypesSet).map((t) => t.name).toList();
    
    // Check for duplicates
    final typeCounts = <QuestionType, int>{};
    for (final question in questions) {
      typeCounts[question.type] = (typeCounts[question.type] ?? 0) + 1;
    }
    
    result.duplicateTypes = typeCounts.entries
        .where((entry) => entry.value > 1)
        .map((entry) => '${entry.key.name} (${entry.value} times)')
        .toList();
    
    result.hasAllRequiredTypes = result.missingTypes.isEmpty;
    result.hasNoDuplicates = result.duplicateTypes.isEmpty;
    result.hasNoExtraTypes = result.extraTypes.isEmpty;
    
    result.completenessScore = result.hasAllRequiredTypes ? 1.0 : 
        (requiredTypesSet.length - result.missingTypes.length) / requiredTypesSet.length;
    
    result.isValid = result.hasAllRequiredTypes && 
                    result.hasNoDuplicates && 
                    result.hasNoExtraTypes;
    
    return result;
  }

  /// Validate question quality
  Future<QualityValidationResult> _validateQuestionQuality(List<Question> questions) async {
    final result = QualityValidationResult();
    
    final qualityIssues = <String>[];
    double totalQualityScore = 0.0;
    
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      double questionScore = 0.0;
      
      // Check question text quality
      if (question.questionText.length < 10) {
        qualityIssues.add('Question ${i + 1}: Question text too short');
      } else if (question.questionText.length > 500) {
        qualityIssues.add('Question ${i + 1}: Question text too long');
      } else {
        questionScore += 0.2;
      }
      
      // Check answer quality
      if (question.correctAnswer.isEmpty) {
        qualityIssues.add('Question ${i + 1}: Missing correct answer');
      } else {
        questionScore += 0.2;
      }
      
      // Check options for multiple choice questions
      if (question.type == QuestionType.multipleChoice) {
        if (question.options.length < 2) {
          qualityIssues.add('Question ${i + 1}: Multiple choice needs at least 2 options');
        } else if (question.options.length > 6) {
          qualityIssues.add('Question ${i + 1}: Too many options for multiple choice');
        } else {
          questionScore += 0.2;
        }
        
        // Check if correct answer is in options
        if (!question.options.contains(question.correctAnswer)) {
          qualityIssues.add('Question ${i + 1}: Correct answer not in options');
        } else {
          questionScore += 0.2;
        }
      } else {
        questionScore += 0.4; // Non-multiple choice questions get full score for options
      }
      
      // Check explanation quality
      if (question.explanation.isEmpty) {
        qualityIssues.add('Question ${i + 1}: Missing explanation');
      } else if (question.explanation.length < 20) {
        qualityIssues.add('Question ${i + 1}: Explanation too brief');
      } else {
        questionScore += 0.2;
      }
      
      totalQualityScore += questionScore;
    }
    
    result.qualityIssues = qualityIssues;
    result.averageQualityScore = questions.isNotEmpty ? totalQualityScore / questions.length : 0.0;
    result.hasQualityIssues = qualityIssues.isNotEmpty;
    result.isValid = result.averageQualityScore >= 0.7; // 70% quality threshold
    
    return result;
  }

  /// Validate subject alignment
  Future<SubjectAlignmentValidationResult> _validateSubjectAlignment(
      List<Question> questions, SubjectType subject) async {
    final result = SubjectAlignmentValidationResult();
    
    final alignmentIssues = <String>[];
    int alignedQuestions = 0;
    
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      
      // Check if question content seems aligned with subject
      // This is a basic check - in a real implementation, you might use NLP or keyword matching
      final isAligned = _checkSubjectAlignment(question, subject);
      
      if (isAligned) {
        alignedQuestions++;
      } else {
        alignmentIssues.add('Question ${i + 1}: May not be aligned with ${subject.name}');
      }
    }
    
    result.alignmentIssues = alignmentIssues;
    result.alignmentScore = questions.isNotEmpty ? alignedQuestions / questions.length : 0.0;
    result.isValid = result.alignmentScore >= 0.8; // 80% alignment threshold
    
    return result;
  }

  /// Validate difficulty consistency
  Future<DifficultyValidationResult> _validateDifficultyConsistency(
      List<Question> questions, int targetDifficulty) async {
    final result = DifficultyValidationResult();
    
    final difficultyIssues = <String>[];
    double totalDifficultyScore = 0.0;
    
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      
      // Estimate question difficulty based on various factors
      final estimatedDifficulty = _estimateQuestionDifficulty(question);
      final difficultyDifference = (estimatedDifficulty - targetDifficulty).abs();
      
      if (difficultyDifference > 2) {
        difficultyIssues.add(
            'Question ${i + 1}: Difficulty mismatch (estimated: $estimatedDifficulty, target: $targetDifficulty)');
      }
      
      // Score based on how close the difficulty is
      final difficultyScore = 1.0 - (difficultyDifference / 5.0).clamp(0.0, 1.0);
      totalDifficultyScore += difficultyScore;
    }
    
    result.difficultyIssues = difficultyIssues;
    result.averageDifficultyScore = questions.isNotEmpty ? totalDifficultyScore / questions.length : 0.0;
    result.targetDifficulty = targetDifficulty;
    result.isValid = result.averageDifficultyScore >= 0.7; // 70% difficulty consistency threshold
    
    return result;
  }

  /// Validate content uniqueness
  Future<UniquenessValidationResult> _validateContentUniqueness(List<Question> questions) async {
    final result = UniquenessValidationResult();
    
    final duplicateIssues = <String>[];
    final questionTexts = <String>[];
    final similarityThreshold = 0.8;
    
    for (int i = 0; i < questions.length; i++) {
      final currentQuestion = questions[i].questionText.toLowerCase().trim();
      
      for (int j = 0; j < questionTexts.length; j++) {
        final similarity = _calculateTextSimilarity(currentQuestion, questionTexts[j]);
        
        if (similarity > similarityThreshold) {
          duplicateIssues.add('Question ${i + 1} is too similar to Question ${j + 1}');
        }
      }
      
      questionTexts.add(currentQuestion);
    }
    
    result.duplicateIssues = duplicateIssues;
    result.uniquenessScore = duplicateIssues.isEmpty ? 1.0 : 
        1.0 - (duplicateIssues.length / questions.length);
    result.isValid = duplicateIssues.isEmpty;
    
    return result;
  }

  /// Check if question content aligns with subject
  bool _checkSubjectAlignment(Question question, SubjectType subject) {
    // Basic keyword-based alignment check
    final questionContent = '${question.questionText} ${question.explanation}'.toLowerCase();
    
    final subjectKeywords = _getSubjectKeywords(subject);
    final matchingKeywords = subjectKeywords.where((keyword) => 
        questionContent.contains(keyword.toLowerCase())).length;
    
    return matchingKeywords > 0 || subjectKeywords.isEmpty;
  }

  /// Get keywords associated with a subject
  List<String> _getSubjectKeywords(SubjectType subject) {
    switch (subject) {
      case SubjectType.math:
        return ['number', 'calculate', 'equation', 'solve', 'formula', 'arithmetic', 'algebra'];
      case SubjectType.physics:
        return ['force', 'energy', 'motion', 'velocity', 'acceleration', 'gravity', 'physics'];
      case SubjectType.chemistry:
        return ['element', 'compound', 'reaction', 'molecule', 'atom', 'chemical', 'chemistry'];
      case SubjectType.biology:
        return ['cell', 'organism', 'evolution', 'genetics', 'ecosystem', 'species', 'biology'];
      case SubjectType.science:
        return ['scientific', 'method', 'experiment', 'hypothesis', 'observation', 'theory', 'research'];
      case SubjectType.english:
        return ['grammar', 'vocabulary', 'literature', 'writing', 'reading', 'language', 'poetry'];
      case SubjectType.art:
        return ['color', 'drawing', 'painting', 'sculpture', 'design', 'creativity', 'visual'];
      case SubjectType.music:
        return ['rhythm', 'melody', 'harmony', 'instrument', 'composer', 'note', 'musical'];
      case SubjectType.physicalEducation:
        return ['fitness', 'exercise', 'sport', 'health', 'physical', 'training', 'activity'];
      case SubjectType.history:
        return ['ancient', 'medieval', 'civilization', 'empire', 'revolution', 'historical'];
      case SubjectType.geography:
        return ['continent', 'climate', 'population', 'region', 'country', 'geographical'];
      case SubjectType.computerScience:
        return ['algorithm', 'programming', 'data', 'computer', 'software', 'technology'];
      default:
        return [];
    }
  }

  /// Estimate question difficulty based on various factors
  int _estimateQuestionDifficulty(Question question) {
    int difficulty = 1;
    
    // Factor in question text complexity
    final wordCount = question.questionText.split(' ').length;
    if (wordCount > 20) difficulty += 1;
    if (wordCount > 40) difficulty += 1;
    
    // Factor in question type complexity
    switch (question.type) {
      case QuestionType.trueFalse:
        difficulty += 0;
        break;
      case QuestionType.multipleChoice:
        difficulty += 1;
        break;
      case QuestionType.fillInTheBlank:
        difficulty += 2;
        break;
      case QuestionType.shortAnswer:
        difficulty += 3;
        break;
      case QuestionType.numericInput:
        difficulty += 2;
        break;
      case QuestionType.dragDrop:
        difficulty += 2;
        break;
      case QuestionType.clickableAnswer:
        difficulty += 1;
        break;
    }
    
    // Factor in number of options for multiple choice
    if (question.type == QuestionType.multipleChoice && question.options.length > 4) {
      difficulty += 1;
    }
    
    return difficulty.clamp(1, 5);
  }

  /// Calculate text similarity (simple implementation)
  double _calculateTextSimilarity(String text1, String text2) {
    final words1 = text1.split(' ').toSet();
    final words2 = text2.split(' ').toSet();
    
    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;
    
    return union > 0 ? intersection / union : 0.0;
  }

  /// Calculate overall validation score
  double _calculateOverallScore(LessonValidationResult result) {
    double score = 0.0;
    int components = 0;
    
    if (result.basicValidation != null) {
      score += result.basicValidation!.isValid ? 1.0 : 0.0;
      components++;
    }
    
    if (result.typeCompletenessValidation != null) {
      score += result.typeCompletenessValidation!.completenessScore;
      components++;
    }
    
    if (result.qualityValidation != null) {
      score += result.qualityValidation!.averageQualityScore;
      components++;
    }
    
    if (result.subjectAlignmentValidation != null) {
      score += result.subjectAlignmentValidation!.alignmentScore;
      components++;
    }
    
    if (result.difficultyValidation != null) {
      score += result.difficultyValidation!.averageDifficultyScore;
      components++;
    }
    
    if (result.uniquenessValidation != null) {
      score += result.uniquenessValidation!.uniquenessScore;
      components++;
    }
    
    return components > 0 ? score / components : 0.0;
  }

  /// Generate recommendations based on validation results
  List<String> _generateRecommendations(LessonValidationResult result) {
    final recommendations = <String>[];
    
    if (result.basicValidation != null && !result.basicValidation!.isValid) {
      if (!result.basicValidation!.hasCorrectCount) {
        recommendations.add('Ensure lesson has exactly 7 questions (one for each question type)');
      }
      if (!result.basicValidation!.allQuestionsComplete) {
        recommendations.add('Complete all required fields for each question');
      }
    }
    
    if (result.typeCompletenessValidation != null && !result.typeCompletenessValidation!.isValid) {
      if (result.typeCompletenessValidation!.missingTypes.isNotEmpty) {
        recommendations.add('Add questions for missing types: ${result.typeCompletenessValidation!.missingTypes.join(', ')}');
      }
      if (result.typeCompletenessValidation!.duplicateTypes.isNotEmpty) {
        recommendations.add('Remove duplicate question types: ${result.typeCompletenessValidation!.duplicateTypes.join(', ')}');
      }
    }
    
    if (result.qualityValidation != null && !result.qualityValidation!.isValid) {
      recommendations.add('Improve question quality - check explanations, answer options, and question clarity');
    }
    
    if (result.subjectAlignmentValidation != null && !result.subjectAlignmentValidation!.isValid) {
      recommendations.add('Ensure all questions are properly aligned with the subject matter');
    }
    
    if (result.difficultyValidation != null && !result.difficultyValidation!.isValid) {
      recommendations.add('Adjust question difficulty to match target level');
    }
    
    if (result.uniquenessValidation != null && !result.uniquenessValidation!.isValid) {
      recommendations.add('Ensure all questions are unique and not too similar to each other');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Lesson validation passed - no improvements needed');
    }
    
    return recommendations;
  }

  /// Quick validation for basic completeness
  Future<bool> quickValidateCompleteness(List<Question> questions) async {
    if (questions.length != requiredQuestionTypes.length) return false;
    
    final presentTypes = questions.map((q) => q.type).toSet();
    return presentTypes.length == requiredQuestionTypes.length &&
           requiredQuestionTypes.every((type) => presentTypes.contains(type));
  }

  /// Validate single question
  Future<SingleQuestionValidationResult> validateSingleQuestion(Question question) async {
    final result = SingleQuestionValidationResult();
    
    result.hasValidText = question.questionText.isNotEmpty && question.questionText.length >= 10;
    result.hasValidAnswer = question.correctAnswer.isNotEmpty;
    result.hasValidExplanation = question.explanation.isNotEmpty && question.explanation.length >= 10;
    
    if (question.type == QuestionType.multipleChoice) {
      result.hasValidOptions = question.options.length >= 2 && 
                              question.options.contains(question.correctAnswer);
    } else {
      result.hasValidOptions = true; // Non-multiple choice questions don't need options validation
    }
    
    result.isValid = result.hasValidText && 
                    result.hasValidAnswer && 
                    result.hasValidExplanation && 
                    result.hasValidOptions;
    
    return result;
  }
}

/// Main validation result class
class LessonValidationResult {
  bool isValid = false;
  double overallScore = 0.0;
  DateTime? validationTimestamp;
  String? validationError;
  List<String> recommendations = [];
  
  BasicValidationResult? basicValidation;
  TypeCompletenessValidationResult? typeCompletenessValidation;
  QualityValidationResult? qualityValidation;
  SubjectAlignmentValidationResult? subjectAlignmentValidation;
  DifficultyValidationResult? difficultyValidation;
  UniquenessValidationResult? uniquenessValidation;
  
  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'overallScore': overallScore,
      'validationTimestamp': validationTimestamp?.toIso8601String(),
      'validationError': validationError,
      'recommendations': recommendations,
      'basicValidation': basicValidation?.toJson(),
      'typeCompletenessValidation': typeCompletenessValidation?.toJson(),
      'qualityValidation': qualityValidation?.toJson(),
      'subjectAlignmentValidation': subjectAlignmentValidation?.toJson(),
      'difficultyValidation': difficultyValidation?.toJson(),
      'uniquenessValidation': uniquenessValidation?.toJson(),
    };
  }
}

/// Basic validation result
class BasicValidationResult {
  bool isValid = false;
  bool hasQuestions = false;
  bool hasCorrectCount = false;
  bool allQuestionsComplete = false;
  bool noNullQuestions = false;
  
  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'hasQuestions': hasQuestions,
      'hasCorrectCount': hasCorrectCount,
      'allQuestionsComplete': allQuestionsComplete,
      'noNullQuestions': noNullQuestions,
    };
  }
}

/// Type completeness validation result
class TypeCompletenessValidationResult {
  bool isValid = false;
  bool hasAllRequiredTypes = false;
  bool hasNoDuplicates = false;
  bool hasNoExtraTypes = false;
  double completenessScore = 0.0;
  List<String> presentTypes = [];
  List<String> requiredTypes = [];
  List<String> missingTypes = [];
  List<String> extraTypes = [];
  List<String> duplicateTypes = [];
  
  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'hasAllRequiredTypes': hasAllRequiredTypes,
      'hasNoDuplicates': hasNoDuplicates,
      'hasNoExtraTypes': hasNoExtraTypes,
      'completenessScore': completenessScore,
      'presentTypes': presentTypes,
      'requiredTypes': requiredTypes,
      'missingTypes': missingTypes,
      'extraTypes': extraTypes,
      'duplicateTypes': duplicateTypes,
    };
  }
}

/// Quality validation result
class QualityValidationResult {
  bool isValid = false;
  bool hasQualityIssues = false;
  double averageQualityScore = 0.0;
  List<String> qualityIssues = [];
  
  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'hasQualityIssues': hasQualityIssues,
      'averageQualityScore': averageQualityScore,
      'qualityIssues': qualityIssues,
    };
  }
}

/// Subject alignment validation result
class SubjectAlignmentValidationResult {
  bool isValid = false;
  double alignmentScore = 0.0;
  List<String> alignmentIssues = [];
  
  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'alignmentScore': alignmentScore,
      'alignmentIssues': alignmentIssues,
    };
  }
}

/// Difficulty validation result
class DifficultyValidationResult {
  bool isValid = false;
  double averageDifficultyScore = 0.0;
  int targetDifficulty = 1;
  List<String> difficultyIssues = [];
  
  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'averageDifficultyScore': averageDifficultyScore,
      'targetDifficulty': targetDifficulty,
      'difficultyIssues': difficultyIssues,
    };
  }
}

/// Uniqueness validation result
class UniquenessValidationResult {
  bool isValid = false;
  double uniquenessScore = 0.0;
  List<String> duplicateIssues = [];
  
  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'uniquenessScore': uniquenessScore,
      'duplicateIssues': duplicateIssues,
    };
  }
}

/// Single question validation result
class SingleQuestionValidationResult {
  bool isValid = false;
  bool hasValidText = false;
  bool hasValidAnswer = false;
  bool hasValidExplanation = false;
  bool hasValidOptions = false;
  
  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'hasValidText': hasValidText,
      'hasValidAnswer': hasValidAnswer,
      'hasValidExplanation': hasValidExplanation,
      'hasValidOptions': hasValidOptions,
    };
  }
}