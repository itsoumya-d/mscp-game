import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/models/question_pool.dart';
import 'package:sp/core/models/question.dart';
import 'skill_id_registry.dart';

/// Validation result structure
class ValidationResult {
  final bool isValid;
  final String message;
  final String category;
  final DateTime timestamp;
  
  ValidationResult({
    required this.isValid,
    required this.message,
    required this.category,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'isValid': isValid,
    'message': message,
    'category': category,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory ValidationResult.fromJson(Map<String, dynamic> json) => ValidationResult(
    isValid: json['isValid'] is bool ? json['isValid'] : (json['isValid'] == 'true'),
    message: json['message']?.toString() ?? '',
    category: json['category']?.toString() ?? '',
    timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
  );
}

/// Comprehensive validation report
class ValidationReport {
  final DateTime timestamp;
  final Map<String, List<ValidationResult>> subjectResults;
  final Map<String, int> typeCoverage;
  final Map<String, double> qualityScores;
  final List<String> criticalIssues;
  final List<String> recommendations;
  final bool overallValid;
  
  ValidationReport({
    required this.timestamp,
    required this.subjectResults,
    required this.typeCoverage,
    required this.qualityScores,
    required this.criticalIssues,
    required this.recommendations,
    required this.overallValid,
  });
  
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'subjectResults': subjectResults.map((k, v) => MapEntry(k, v.map((r) => r.toJson()).toList())),
    'typeCoverage': typeCoverage,
    'qualityScores': qualityScores,
    'criticalIssues': criticalIssues,
    'recommendations': recommendations,
    'overallValid': overallValid,
  };
}

/// Comprehensive Question Validation Service
/// Validates question generation functionality and ensures quality
class QuestionValidationService {
  static const String _validationHistoryKey = 'validation_history';
  static const String _validationStatsKey = 'validation_stats';
  
  final Random _rng = Random();
  
  /// Validate all question types for all subjects
  Future<ValidationReport> validateCompleteSystem() async {
    final timestamp = DateTime.now();
    final subjectResults = <String, List<ValidationResult>>{};
    final typeCoverage = <String, int>{};
    final qualityScores = <String, double>{};
    final criticalIssues = <String>[];
    final recommendations = <String>[];
    
    // Validate each subject
    for (final subject in SubjectType.values) {
      final subjectKey = subject.name;
      subjectResults[subjectKey] = [];
      
      // Validate question type coverage
      final coverageResult = await _validateQuestionTypeCoverage(subject);
      subjectResults[subjectKey]!.addAll(coverageResult.results);
      typeCoverage[subjectKey] = coverageResult.coverage;
      
      // Validate question quality
      final qualityResult = await _validateQuestionQuality(subject);
      subjectResults[subjectKey]!.addAll(qualityResult.results);
      qualityScores[subjectKey] = qualityResult.score;
      
      // Validate AI generation capability
      final aiResult = await _validateAIGeneration(subject);
      subjectResults[subjectKey]!.addAll(aiResult.results);
      
      // Check for critical issues
      final subjectIssues = subjectResults[subjectKey]!
          .where((r) => !r.isValid && r.category == 'critical')
          .map((r) => '${subject.name}: ${r.message}')
          .toList();
      criticalIssues.addAll(subjectIssues);
    }
    
    // Generate recommendations
    recommendations.addAll(_generateRecommendations(subjectResults, typeCoverage, qualityScores));
    
    // Determine overall validity
    final overallValid = criticalIssues.isEmpty && 
                        typeCoverage.values.every((coverage) => coverage >= 7) &&
                        qualityScores.values.every((score) => score >= 0.7);
    
    final report = ValidationReport(
      timestamp: timestamp,
      subjectResults: subjectResults,
      typeCoverage: typeCoverage,
      qualityScores: qualityScores,
      criticalIssues: criticalIssues,
      recommendations: recommendations,
      overallValid: overallValid,
    );
    
    // Save validation history
    await _saveValidationReport(report);
    
    return report;
  }
  
  /// Validate question type coverage for a subject
  Future<({List<ValidationResult> results, int coverage})> _validateQuestionTypeCoverage(SubjectType subject) async {
    final results = <ValidationResult>[];
    int coverage = 0;
    
    for (final questionType in QuestionType.values) {
      final hasQuestions = await _hasQuestionsOfType(subject, questionType);
      
      if (hasQuestions) {
        coverage++;
        results.add(ValidationResult(
          isValid: true,
          message: 'Found questions of type ${questionType.name} for ${subject.name}',
          category: 'coverage',
        ));
      } else {
        results.add(ValidationResult(
          isValid: false,
          message: 'Missing questions of type ${questionType.name} for ${subject.name}',
          category: 'critical',
        ));
      }
    }
    
    // Overall coverage validation
    if (coverage == QuestionType.values.length) {
      results.add(ValidationResult(
        isValid: true,
        message: 'Complete question type coverage for ${subject.name} (${coverage}/7)',
        category: 'coverage',
      ));
    } else {
      results.add(ValidationResult(
        isValid: false,
        message: 'Incomplete question type coverage for ${subject.name} (${coverage}/7)',
        category: 'critical',
      ));
    }
    
    return (results: results, coverage: coverage);
  }
  
  /// Validate question quality for a subject
  Future<({List<ValidationResult> results, double score})> _validateQuestionQuality(SubjectType subject) async {
    final results = <ValidationResult>[];
    double totalScore = 0.0;
    int questionCount = 0;
    
    for (final questionType in QuestionType.values) {
      final questions = await _getQuestionsOfType(subject, questionType);
      
      for (final question in questions.take(5)) { // Sample 5 questions per type
        final qualityScore = assessQuestionQuality(question);
        totalScore += qualityScore;
        questionCount++;
        
        if (qualityScore >= 0.8) {
          results.add(ValidationResult(
            isValid: true,
            message: 'High quality question: ${question.id} (score: ${qualityScore.toStringAsFixed(2)})',
            category: 'quality',
          ));
        } else if (qualityScore >= 0.6) {
          results.add(ValidationResult(
            isValid: true,
            message: 'Acceptable quality question: ${question.id} (score: ${qualityScore.toStringAsFixed(2)})',
            category: 'quality',
          ));
        } else {
          results.add(ValidationResult(
            isValid: false,
            message: 'Low quality question: ${question.id} (score: ${qualityScore.toStringAsFixed(2)})',
            category: 'quality',
          ));
        }
      }
    }
    
    final averageScore = questionCount > 0 ? totalScore / questionCount : 0.0;
    
    results.add(ValidationResult(
      isValid: averageScore >= 0.7,
      message: 'Average quality score for ${subject.name}: ${averageScore.toStringAsFixed(2)}',
      category: 'quality',
    ));
    
    return (results: results, score: averageScore);
  }
  
  /// Validate procedural generation capability
  Future<({List<ValidationResult> results})> _validateAIGeneration(SubjectType subject) async {
    final results = <ValidationResult>[];
    
    try {
      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();
      
      // Procedural generation is always available
      results.add(ValidationResult(
        isValid: true,
        message: 'Procedural generation is available',
        category: 'ai',
      ));
      
      // Check daily generation status
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastGeneration = prefs.getString('enhanced_last_generation_date');
      
      if (lastGeneration == today) {
        results.add(ValidationResult(
          isValid: true,
          message: 'AI questions generated today for ${subject.name}',
          category: 'ai',
        ));
      } else {
        results.add(ValidationResult(
          isValid: false,
          message: 'No AI questions generated today for ${subject.name}',
          category: 'warning',
        ));
      }
      
      // Check AI-generated question quality
      final aiQuestions = await _getAIGeneratedQuestions(subject);
      if (aiQuestions.isNotEmpty) {
        final validAI = aiQuestions.where((q) => assessQuestionQuality(q) >= 0.6).length;
        final aiQualityRatio = validAI / aiQuestions.length;
        
        results.add(ValidationResult(
          isValid: aiQualityRatio >= 0.7,
          message: 'AI question quality ratio for ${subject.name}: ${aiQualityRatio.toStringAsFixed(2)}',
          category: 'ai',
        ));
      }
      
    } catch (e) {
      results.add(ValidationResult(
        isValid: false,
        message: 'AI validation error for ${subject.name}: $e',
        category: 'critical',
      ));
    }
    
    return (results: results);
  }
  
  /// Check if questions of a specific type exist
  Future<bool> _hasQuestionsOfType(SubjectType subject, QuestionType questionType) async {
    try {
      final questions = await _getQuestionsOfType(subject, questionType);
      return questions.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Get questions of a specific type
  Future<List<Question>> _getQuestionsOfType(SubjectType subject, QuestionType questionType) async {
    final questions = <Question>[];
    
    try {
      // Check regular question pools
      final prefs = await SharedPreferences.getInstance();
      final poolKey = 'question_pool_${subject.name}';
      final poolData = prefs.getString(poolKey);
      
      if (poolData != null) {
        final poolJson = jsonDecode(poolData);
        final pool = QuestionPool.fromJson(poolJson);
        
        for (final template in pool.templates) {
          if (template.type == questionType) {
            final question = template.generateQuestion(subject, _rng);
            questions.add(question);
          }
        }
      }
      
      // Check AI-generated questions
      final skillIds = _getSkillIdsForSubject(subject);
      for (final skillId in skillIds) {
        final aiKey = 'ai_pool_${subject.name}_$skillId';
        final aiTemplates = prefs.getStringList(aiKey) ?? [];
        
        for (final templateString in aiTemplates) {
          try {
            final templateJson = jsonDecode(templateString);
            final template = QuestionTemplate.fromJson(templateJson);
            
            if (template.type == questionType) {
              final question = template.generateQuestion(subject, _rng);
              questions.add(question);
            }
          } catch (e) {
            // Skip invalid templates
          }
        }
      }
      
    } catch (e) {
      print('Error getting questions of type ${questionType.name}: $e');
    }
    
    return questions;
  }
  
  /// Get AI-generated questions for a subject
  Future<List<Question>> _getAIGeneratedQuestions(SubjectType subject) async {
    final questions = <Question>[];
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final skillIds = _getSkillIdsForSubject(subject);
      
      for (final skillId in skillIds) {
        final aiKey = 'ai_pool_${subject.name}_$skillId';
        final aiTemplates = prefs.getStringList(aiKey) ?? [];
        
        for (final templateString in aiTemplates) {
          try {
            final templateJson = jsonDecode(templateString);
            final template = QuestionTemplate.fromJson(templateJson);
            final question = template.generateQuestion(subject, _rng);
            questions.add(question);
          } catch (e) {
            // Skip invalid templates
          }
        }
      }
    } catch (e) {
      print('Error getting AI questions: $e');
    }
    
    return questions;
  }
  
  /// Assess question quality (0.0 to 1.0)
  double assessQuestionQuality(Question question) {
    double score = 0.0;
    
    // Basic structure validation (30%)
    if (question.questionText.trim().isNotEmpty) score += 0.1;
    if (question.correctAnswer.trim().isNotEmpty) score += 0.1;
    if (question.explanation != null && question.explanation!.trim().isNotEmpty) score += 0.1;
    
    // Content quality (40%)
    if (question.questionText.length >= 10) score += 0.1;
    if ((question.explanation?.length ?? 0) >= 20) score += 0.1;
    if (question.hint != null && question.hint!.trim().isNotEmpty) score += 0.1;
    if (question.difficulty >= 1 && question.difficulty <= 5) score += 0.1;
    
    // Type-specific validation (30%)
    switch (question.type) {
      case QuestionType.multipleChoice:
        if (question.options.length >= 3) score += 0.1;
        if (question.options.contains(question.correctAnswer)) score += 0.1;
        if (question.options.every((opt) => opt.trim().isNotEmpty)) score += 0.1;
        break;
        
      case QuestionType.trueFalse:
        if (['True', 'False', 'true', 'false'].contains(question.correctAnswer)) score += 0.2;
        if (question.questionText.contains('?')) score += 0.1;
        break;
        
      case QuestionType.numericInput:
        if (double.tryParse(question.correctAnswer) != null) score += 0.2;
        if (question.questionText.toLowerCase().contains('calculate') || 
            question.questionText.contains('=')) score += 0.1;
        break;
        
      case QuestionType.fillInTheBlank:
        if (question.questionText.contains('___') || question.questionText.contains('_')) score += 0.2;
        if (question.correctAnswer.length >= 2) score += 0.1;
        break;
        
      case QuestionType.dragDrop:
        if (question.options.length >= 2) score += 0.1;
        if (question.correctAnswer.contains(':')) score += 0.1;
        if (question.correctAnswer.split(';').length >= 2) score += 0.1;
        break;
        
      case QuestionType.clickableAnswer:
        if (question.options.isNotEmpty) score += 0.1;
        if (question.options.contains(question.correctAnswer)) score += 0.1;
        if (question.questionText.toLowerCase().contains('click') || 
            question.questionText.toLowerCase().contains('select')) score += 0.1;
        break;
        
      case QuestionType.shortAnswer:
        if (question.correctAnswer.length >= 3) score += 0.1;
        if (question.correctAnswer.split(' ').length >= 2) score += 0.1;
        if (question.questionText.contains('?')) score += 0.1;
        break;
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  /// Generate recommendations based on validation results
  List<String> _generateRecommendations(
    Map<String, List<ValidationResult>> subjectResults,
    Map<String, int> typeCoverage,
    Map<String, double> qualityScores,
  ) {
    final recommendations = <String>[];
    
    // Coverage recommendations
    for (final entry in typeCoverage.entries) {
      if (entry.value < 7) {
        final missing = 7 - entry.value;
        recommendations.add('Generate $missing missing question types for ${entry.key}');
      }
    }
    
    // Quality recommendations
    for (final entry in qualityScores.entries) {
      if (entry.value < 0.7) {
        recommendations.add('Improve question quality for ${entry.key} (current: ${entry.value.toStringAsFixed(2)})');
      }
    }
    
    // AI-specific recommendations
    final aiIssues = subjectResults.values
        .expand((results) => results)
        .where((r) => !r.isValid && r.category == 'ai')
        .length;
    
    if (aiIssues > 0) {
      recommendations.add('Address $aiIssues AI generation issues');
      recommendations.add('Verify API key configuration and daily generation limits');
    }
    
    // General recommendations
    if (recommendations.isEmpty) {
      recommendations.add('System validation passed - continue monitoring daily generation');
    } else {
      recommendations.add('Run validation again after implementing fixes');
    }
    
    return recommendations;
  }
  
  /// Save validation report
  Future<void> _saveValidationReport(ValidationReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save latest report
      await prefs.setString(_validationStatsKey, jsonEncode(report.toJson()));
      
      // Save to history
      final historyKey = _validationHistoryKey;
      final history = prefs.getStringList(historyKey) ?? [];
      history.add(jsonEncode(report.toJson()));
      
      // Keep only last 10 reports
      if (history.length > 10) {
        history.removeRange(0, history.length - 10);
      }
      
      await prefs.setStringList(historyKey, history);
      
    } catch (e) {
      print('Error saving validation report: $e');
    }
  }
  
  /// Get latest validation report
  Future<ValidationReport?> getLatestValidationReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportString = prefs.getString(_validationStatsKey);
      
      if (reportString != null) {
        final reportJson = jsonDecode(reportString);
        return ValidationReport(
          timestamp: DateTime.parse(reportJson['timestamp']),
          subjectResults: (reportJson['subjectResults'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, (v as List).map((r) => ValidationResult.fromJson(r)).toList()),
          ),
          typeCoverage: Map<String, int>.from(reportJson['typeCoverage']),
          qualityScores: Map<String, double>.from(reportJson['qualityScores']),
          criticalIssues: List<String>.from(reportJson['criticalIssues']),
          recommendations: List<String>.from(reportJson['recommendations']),
          overallValid: reportJson['overallValid'] ?? false,
        );
      }
    } catch (e) {
      print('Error loading validation report: $e');
    }
    
    return null;
  }
  
  /// Get validation history
  Future<List<ValidationReport>> getValidationHistory() async {
    final reports = <ValidationReport>[];
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_validationHistoryKey) ?? [];
      
      for (final reportString in history) {
        try {
          final reportJson = jsonDecode(reportString);
          final report = ValidationReport(
            timestamp: DateTime.parse(reportJson['timestamp']),
            subjectResults: (reportJson['subjectResults'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, (v as List).map((r) => ValidationResult.fromJson(r)).toList()),
            ),
            typeCoverage: Map<String, int>.from(reportJson['typeCoverage']),
            qualityScores: Map<String, double>.from(reportJson['qualityScores']),
            criticalIssues: List<String>.from(reportJson['criticalIssues']),
            recommendations: List<String>.from(reportJson['recommendations']),
            overallValid: reportJson['overallValid'] ?? false,
          );
          reports.add(report);
        } catch (e) {
          // Skip invalid reports
        }
      }
    } catch (e) {
      print('Error loading validation history: $e');
    }
    
    return reports;
  }
  
  /// Get skill IDs for a subject using the centralized SkillIdRegistry
  List<String> _getSkillIdsForSubject(SubjectType subject) {
    // Use the centralized SkillIdRegistry to ensure consistency
    return SkillIdRegistry.getSkillIdsForSubject(subject);
  }
}