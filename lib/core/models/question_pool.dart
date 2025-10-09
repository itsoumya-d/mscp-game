import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/models/question.dart';

/// Represents a question category with specific characteristics
enum QuestionCategory {
  conceptual,     // Understanding concepts and definitions
  computational,  // Calculations and problem-solving
  analytical,     // Analysis and reasoning
  factual,        // Facts and memorization
  practical,      // Real-world applications
  comparative,    // Comparing and contrasting
  creative        // Open-ended and creative thinking
}

/// Manages question pools and prevents repetition
class QuestionPool {
  final String id;
  final SubjectType subject;
  final String skillId;
  final QuestionCategory category;
  final List<QuestionTemplate> templates;
  final Set<String> usedQuestionIds;
  final DateTime lastUsed;
  final int maxRepetitions;

  const QuestionPool({
    required this.id,
    required this.subject,
    required this.skillId,
    required this.category,
    required this.templates,
    required this.usedQuestionIds,
    required this.lastUsed,
    this.maxRepetitions = 3,
  });

  /// Check if a question can be generated from this pool
  bool canGenerateQuestion() {
    final availableTemplates = templates.where((template) => 
      !usedQuestionIds.contains(template.id) || 
      template.repetitionCount < maxRepetitions
    ).toList();
    
    return availableTemplates.isNotEmpty;
  }

  /// Get the next available question template
  QuestionTemplate? getNextTemplate(Random rng) {
    final availableTemplates = templates.where((template) => 
      !usedQuestionIds.contains(template.id) || 
      template.repetitionCount < maxRepetitions
    ).toList();
    
    if (availableTemplates.isEmpty) return null;
    
    // Prioritize unused templates
    final unusedTemplates = availableTemplates.where((template) => 
      !usedQuestionIds.contains(template.id)
    ).toList();
    
    if (unusedTemplates.isNotEmpty) {
      return unusedTemplates[rng.nextInt(unusedTemplates.length)];
    }
    
    // If all templates have been used, pick the least used one
    availableTemplates.sort((a, b) => a.repetitionCount.compareTo(b.repetitionCount));
    return availableTemplates.first;
  }

  /// Mark a question as used
  QuestionPool markQuestionUsed(String questionId) {
    final newUsedIds = Set<String>.from(usedQuestionIds)..add(questionId);
    
    // Update repetition count for the template
    final updatedTemplates = templates.map((template) {
      if (template.id == questionId) {
        return template.copyWith(repetitionCount: template.repetitionCount + 1);
      }
      return template;
    }).toList();
    
    return copyWith(
      usedQuestionIds: newUsedIds,
      templates: updatedTemplates,
      lastUsed: DateTime.now(),
    );
  }

  /// Reset usage tracking (for new learning sessions)
  QuestionPool resetUsage() {
    final resetTemplates = templates.map((template) => 
      template.copyWith(repetitionCount: 0)
    ).toList();
    
    return copyWith(
      usedQuestionIds: <String>{},
      templates: resetTemplates,
      lastUsed: DateTime.now(),
    );
  }

  QuestionPool copyWith({
    String? id,
    SubjectType? subject,
    String? skillId,
    QuestionCategory? category,
    List<QuestionTemplate>? templates,
    Set<String>? usedQuestionIds,
    DateTime? lastUsed,
    int? maxRepetitions,
  }) {
    return QuestionPool(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      skillId: skillId ?? this.skillId,
      category: category ?? this.category,
      templates: templates ?? this.templates,
      usedQuestionIds: usedQuestionIds ?? this.usedQuestionIds,
      lastUsed: lastUsed ?? this.lastUsed,
      maxRepetitions: maxRepetitions ?? this.maxRepetitions,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject.name,
    'skillId': skillId,
    'category': category.name,
    'templates': templates.map((e) => e.toJson()).toList(),
    'usedQuestionIds': usedQuestionIds.toList(),
    'lastUsed': lastUsed.millisecondsSinceEpoch,
    'maxRepetitions': maxRepetitions,
  };

  factory QuestionPool.fromJson(Map<String, dynamic> json) => QuestionPool(
    id: json['id'],
    subject: SubjectType.values.firstWhere((e) => e.name == json['subject']),
    skillId: json['skillId'],
    category: QuestionCategory.values.firstWhere((e) => e.name == json['category']),
    templates: (json['templates'] as List).map((e) => QuestionTemplate.fromJson(e)).toList(),
    usedQuestionIds: Set<String>.from(json['usedQuestionIds']),
    lastUsed: DateTime.fromMillisecondsSinceEpoch(json['lastUsed']),
    maxRepetitions: json['maxRepetitions'] ?? 3,
  );
}

/// Template for generating questions with variations
class QuestionTemplate {
  final String id;
  final QuestionType type;
  final QuestionCategory category;
  final String questionPattern;
  final List<String> optionPatterns;
  final String correctAnswerPattern;
  final String explanationPattern;
  final String? hintPattern;
  final int baseDifficulty;
  final Map<String, List<dynamic>> variables;
  final int repetitionCount;
  final Set<String> tags;

  const QuestionTemplate({
    required this.id,
    required this.type,
    required this.category,
    required this.questionPattern,
    required this.optionPatterns,
    required this.correctAnswerPattern,
    required this.explanationPattern,
    this.hintPattern,
    required this.baseDifficulty,
    required this.variables,
    this.repetitionCount = 0,
    required this.tags,
  });

  /// Generate a question from this template
  Question generateQuestion(SubjectType subject, Random rng) {
    final variableValues = <String, dynamic>{};
    
    // Generate random values for each variable
    for (final entry in variables.entries) {
      final values = entry.value;
      if (values.isNotEmpty) {
        variableValues[entry.key] = values[rng.nextInt(values.length)];
      } else {
        // Use a default value if the variable list is empty
        variableValues[entry.key] = '';
      }
    }
    
    // Replace variables in patterns
    String questionText = questionPattern;
    List<String> options = List.from(optionPatterns);
    String correctAnswer = correctAnswerPattern;
    String explanation = explanationPattern;
    String? hint = hintPattern;
    
    for (final entry in variableValues.entries) {
      final placeholder = '{${entry.key}}';
      final value = entry.value.toString();
      
      questionText = questionText.replaceAll(placeholder, value);
      options = options.map((option) => option.replaceAll(placeholder, value)).toList();
      correctAnswer = correctAnswer.replaceAll(placeholder, value);
      explanation = explanation.replaceAll(placeholder, value);
      hint = hint?.replaceAll(placeholder, value);
    }
    
    return Question(
      id: const Uuid().v4(),
      type: type,
      questionText: questionText,
      options: options,
      correctAnswer: correctAnswer,
      explanation: explanation,
      hint: hint,
      difficulty: baseDifficulty,
      subject: subject,
    );
  }

  QuestionTemplate copyWith({
    String? id,
    QuestionType? type,
    QuestionCategory? category,
    String? questionPattern,
    List<String>? optionPatterns,
    String? correctAnswerPattern,
    String? explanationPattern,
    String? hintPattern,
    int? baseDifficulty,
    Map<String, List<dynamic>>? variables,
    int? repetitionCount,
    Set<String>? tags,
  }) {
    return QuestionTemplate(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      questionPattern: questionPattern ?? this.questionPattern,
      optionPatterns: optionPatterns ?? this.optionPatterns,
      correctAnswerPattern: correctAnswerPattern ?? this.correctAnswerPattern,
      explanationPattern: explanationPattern ?? this.explanationPattern,
      hintPattern: hintPattern ?? this.hintPattern,
      baseDifficulty: baseDifficulty ?? this.baseDifficulty,
      variables: variables ?? this.variables,
      repetitionCount: repetitionCount ?? this.repetitionCount,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'category': category.name,
    'questionPattern': questionPattern,
    'optionPatterns': optionPatterns,
    'correctAnswerPattern': correctAnswerPattern,
    'explanationPattern': explanationPattern,
    'hintPattern': hintPattern,
    'baseDifficulty': baseDifficulty,
    'variables': variables,
    'repetitionCount': repetitionCount,
    'tags': tags.toList(),
  };

  factory QuestionTemplate.fromJson(Map<String, dynamic> json) => QuestionTemplate(
    id: json['id'],
    type: QuestionType.values.firstWhere((e) => e.name == json['type']),
    category: QuestionCategory.values.firstWhere((e) => e.name == json['category']),
    questionPattern: json['questionPattern'],
    optionPatterns: List<String>.from(json['optionPatterns']),
    correctAnswerPattern: json['correctAnswerPattern'],
    explanationPattern: json['explanationPattern'],
    hintPattern: json['hintPattern'],
    baseDifficulty: json['baseDifficulty'],
    variables: Map<String, List<dynamic>>.from(json['variables']),
    repetitionCount: json['repetitionCount'] ?? 0,
    tags: Set<String>.from(json['tags']),
  );
}

/// Manages the overall question pool system
class QuestionPoolManager {
  final Map<String, QuestionPool> pools;
  final Map<String, DateTime> lastResetTimes;

  const QuestionPoolManager({
    required this.pools,
    required this.lastResetTimes,
  });

  /// Get a question pool for a specific subject, skill, and category
  QuestionPool? getPool(SubjectType subject, String skillId, QuestionCategory category) {
    final key = '${subject.name}_${skillId}_${category.name}';
    return pools[key];
  }

  /// Add or update a question pool
  QuestionPoolManager updatePool(QuestionPool pool) {
    final key = '${pool.subject.name}_${pool.skillId}_${pool.category.name}';
    final updatedPools = Map<String, QuestionPool>.from(pools);
    updatedPools[key] = pool;
    
    return copyWith(pools: updatedPools);
  }

  /// Reset all pools for a subject (for new learning sessions)
  QuestionPoolManager resetSubjectPools(SubjectType subject) {
    final updatedPools = Map<String, QuestionPool>.from(pools);
    final resetTime = DateTime.now();
    final updatedResetTimes = Map<String, DateTime>.from(lastResetTimes);
    
    for (final entry in pools.entries) {
      if (entry.value.subject == subject) {
        updatedPools[entry.key] = entry.value.resetUsage();
        updatedResetTimes[entry.key] = resetTime;
      }
    }
    
    return copyWith(
      pools: updatedPools,
      lastResetTimes: updatedResetTimes,
    );
  }

  /// Check if pools need to be reset (daily reset)
  bool shouldResetPools(String poolKey) {
    final lastReset = lastResetTimes[poolKey];
    if (lastReset == null) return true;
    
    final now = DateTime.now();
    final daysSinceReset = now.difference(lastReset).inDays;
    return daysSinceReset >= 1;
  }

  QuestionPoolManager copyWith({
    Map<String, QuestionPool>? pools,
    Map<String, DateTime>? lastResetTimes,
  }) {
    return QuestionPoolManager(
      pools: pools ?? this.pools,
      lastResetTimes: lastResetTimes ?? this.lastResetTimes,
    );
  }

  Map<String, dynamic> toJson() => {
    'pools': pools.map((key, pool) => MapEntry(key, pool.toJson())),
    'lastResetTimes': lastResetTimes.map((key, time) => 
      MapEntry(key, time.millisecondsSinceEpoch)),
  };

  factory QuestionPoolManager.fromJson(Map<String, dynamic> json) {
    final poolsMap = <String, QuestionPool>{};
    final resetTimesMap = <String, DateTime>{};
    
    if (json['pools'] != null) {
      for (final entry in (json['pools'] as Map<String, dynamic>).entries) {
        poolsMap[entry.key] = QuestionPool.fromJson(entry.value);
      }
    }
    
    if (json['lastResetTimes'] != null) {
      for (final entry in (json['lastResetTimes'] as Map<String, dynamic>).entries) {
        resetTimesMap[entry.key] = DateTime.fromMillisecondsSinceEpoch(entry.value);
      }
    }
    
    return QuestionPoolManager(
      pools: poolsMap,
      lastResetTimes: resetTimesMap,
    );
  }
}