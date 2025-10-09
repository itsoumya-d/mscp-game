import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/question.dart';
import 'progressive_difficulty_enhanced_service.dart';

/// Question Diversity Manager
/// Ensures varied and engaging question sets in 7-question game sessions
/// Category E Task E6: Question Diversity Management
class QuestionDiversityManager {
  static QuestionDiversityManager? _instance;
  static QuestionDiversityManager get instance => _instance ??= QuestionDiversityManager._();
  
  QuestionDiversityManager._();

  // Storage keys
  static const String _recentQuestionsKey = 'recent_questions_v1';
  static const String _topicRotationKey = 'topic_rotation_v1';

  // Diversity constraints
  static const int _maxSameTypePerGame = 3;
  static const int _recentQuestionsWindow = 20;
  static const int _repetitionPreventionWindow = 10;
  static const int _questionsPerGame = 7;

  // Recent questions tracking (per subject)
  final Map<SubjectType, List<QuestionFingerprint>> _recentQuestions = {};
  
  // Topic rotation state (per subject/skill)
  final Map<String, TopicRotationState> _topicRotation = {};

  /// Initialize the service
  Future<void> initialize() async {
    await _loadRecentQuestions();
    await _loadTopicRotation();
    
    if (kDebugMode) {
      debugPrint('[DiversityManager] ✅ Service initialized');
    }
  }

  /// Diversify a set of questions for a 7-question game
  /// Task E6: Main diversification method
  Future<List<Question>> diversifyQuestions({
    required List<Question> candidateQuestions,
    required SubjectType subject,
    required String skillId,
    required int userPerformanceLevel, // 1-10 from ProgressiveDifficultyEnhancedService
  }) async {
    if (candidateQuestions.length < _questionsPerGame) {
      if (kDebugMode) {
        debugPrint('[DiversityManager] ⚠️ Not enough candidate questions: ${candidateQuestions.length}');
      }
      return candidateQuestions;
    }

    if (kDebugMode) {
      debugPrint('[DiversityManager] 🎯 Diversifying ${candidateQuestions.length} questions for ${subject.name}/$skillId');
    }

    // Step 1: Remove recent duplicates
    final nonDuplicates = _filterRecentDuplicates(candidateQuestions, subject);
    
    if (nonDuplicates.length < _questionsPerGame) {
      if (kDebugMode) {
        debugPrint('[DiversityManager] ⚠️ Not enough non-duplicate questions: ${nonDuplicates.length}');
      }
      return candidateQuestions.take(_questionsPerGame).toList();
    }

    // Step 2: Ensure type distribution
    final typeBalanced = _balanceQuestionTypes(nonDuplicates);

    // Step 3: Balance difficulty distribution
    final difficultyBalanced = _balanceDifficulty(typeBalanced, userPerformanceLevel);

    // Step 4: Vary topics within skill
    final topicVaried = _varyTopics(difficultyBalanced, subject, skillId);

    // Step 5: Arrange questions (easy → medium → hard → medium)
    final arranged = _arrangeQuestions(topicVaried);

    // Step 6: Take exactly 7 questions
    final finalQuestions = arranged.take(_questionsPerGame).toList();

    // Step 7: Track these questions
    await _trackQuestions(finalQuestions, subject);

    if (kDebugMode) {
      _logDiversityStats(finalQuestions);
    }

    return finalQuestions;
  }

  /// Filter out questions that were recently shown
  /// Task E6: Repetition prevention
  List<Question> _filterRecentDuplicates(List<Question> questions, SubjectType subject) {
    final recentFingerprints = _recentQuestions[subject] ?? [];
    
    if (recentFingerprints.isEmpty) {
      return questions;
    }

    // Get fingerprints from last 10 questions
    final recentWindow = recentFingerprints.take(_repetitionPreventionWindow).toList();
    final recentHashes = recentWindow.map((f) => f.hash).toSet();

    // Filter out duplicates
    final filtered = questions.where((q) {
      final hash = _generateFingerprint(q);
      return !recentHashes.contains(hash);
    }).toList();

    if (kDebugMode && filtered.length < questions.length) {
      debugPrint('[DiversityManager] 🗑️ Filtered ${questions.length - filtered.length} duplicate questions');
    }

    return filtered;
  }

  /// Balance question types (max 3 of same type)
  /// Task E6: Type distribution
  List<Question> _balanceQuestionTypes(List<Question> questions) {
    final balanced = <Question>[];
    final typeCounts = <QuestionType, int>{};

    // Shuffle to avoid predictable patterns
    final shuffled = List<Question>.from(questions)..shuffle();

    for (final question in shuffled) {
      final count = typeCounts[question.type] ?? 0;
      
      if (count < _maxSameTypePerGame) {
        balanced.add(question);
        typeCounts[question.type] = count + 1;
      }

      if (balanced.length >= _questionsPerGame * 2) break; // Get extra for next steps
    }

    // Ensure minimum 1 of each major type
    final majorTypes = [
      QuestionType.multipleChoice,
      QuestionType.numericInput,
      QuestionType.dragDrop,
    ];

    for (final type in majorTypes) {
      if (!balanced.any((q) => q.type == type)) {
        final typeQuestion = questions.firstWhere(
          (q) => q.type == type,
          orElse: () => questions.first,
        );
        if (!balanced.contains(typeQuestion)) {
          balanced.add(typeQuestion);
        }
      }
    }

    return balanced;
  }

  /// Balance difficulty distribution based on user performance
  /// Task E6: Difficulty balancing
  List<Question> _balanceDifficulty(List<Question> questions, int userLevel) {
    // Categorize questions by difficulty
    final easy = <Question>[];
    final medium = <Question>[];
    final hard = <Question>[];

    for (final q in questions) {
      if (q.difficulty <= userLevel - 2) {
        easy.add(q);
      } else if (q.difficulty >= userLevel + 2) {
        hard.add(q);
      } else {
        medium.add(q);
      }
    }

    // Determine mix based on user level
    int easyCount, mediumCount, hardCount;
    
    if (userLevel <= 3) {
      // Beginner: More easy questions
      easyCount = 3;
      mediumCount = 3;
      hardCount = 1;
    } else if (userLevel <= 7) {
      // Intermediate: Balanced
      easyCount = 2;
      mediumCount = 3;
      hardCount = 2;
    } else {
      // Advanced: More challenging
      easyCount = 2;
      mediumCount = 2;
      hardCount = 3;
    }

    // Build balanced set
    final balanced = <Question>[];
    
    balanced.addAll(easy.take(easyCount));
    balanced.addAll(medium.take(mediumCount));
    balanced.addAll(hard.take(hardCount));

    // Fill remaining with medium if needed
    while (balanced.length < _questionsPerGame && medium.length > balanced.where((q) => medium.contains(q)).length) {
      final remaining = medium.where((q) => !balanced.contains(q)).toList();
      if (remaining.isNotEmpty) {
        balanced.add(remaining.first);
      } else {
        break;
      }
    }

    if (kDebugMode) {
      debugPrint('[DiversityManager] 📊 Difficulty mix: ${easyCount}E, ${mediumCount}M, ${hardCount}H');
    }

    return balanced;
  }

  /// Vary topics within skill
  /// Task E6: Topic variation
  List<Question> _varyTopics(List<Question> questions, SubjectType subject, String skillId) {
    // Group questions by topic/concept
    final topicGroups = <String, List<Question>>{};
    
    for (final q in questions) {
      // Extract topic from question (simplified - could be enhanced)
      final topic = _extractTopic(q);
      topicGroups.putIfAbsent(topic, () => []).add(q);
    }

    // Get rotation state
    final rotationKey = '${subject.name}_$skillId';
    final rotation = _topicRotation[rotationKey] ?? TopicRotationState(topics: topicGroups.keys.toList());

    // Select questions rotating through topics
    final varied = <Question>[];
    final usedTopics = <String>{};

    for (final q in questions) {
      final topic = _extractTopic(q);
      
      // Avoid clustering same topics
      if (usedTopics.length < 2 || !usedTopics.contains(topic)) {
        varied.add(q);
        usedTopics.add(topic);
        
        if (usedTopics.length > 2) {
          usedTopics.remove(usedTopics.first);
        }
      }

      if (varied.length >= _questionsPerGame * 2) break;
    }

    // Update rotation state
    rotation.lastUsedIndex = (rotation.lastUsedIndex + 1) % rotation.topics.length;
    _topicRotation[rotationKey] = rotation;

    return varied.isEmpty ? questions : varied;
  }

  /// Arrange questions for optimal flow
  /// Task E6: Question arrangement (easy → medium → hard → medium)
  List<Question> _arrangeQuestions(List<Question> questions) {
    // Sort by difficulty
    final sorted = List<Question>.from(questions)
      ..sort((a, b) => a.difficulty.compareTo(b.difficulty));

    if (sorted.length < _questionsPerGame) {
      return sorted;
    }

    // Arrange: easy start, gradually increase, medium end
    final arranged = <Question>[];
    
    // Start with easiest (confidence boost)
    arranged.add(sorted.first);
    
    // Gradually increase difficulty
    final middle = sorted.sublist(1, min(sorted.length - 1, _questionsPerGame - 1));
    arranged.addAll(middle);
    
    // End with medium difficulty (accomplished feeling)
    if (sorted.length > 2) {
      final mediumIndex = sorted.length ~/ 2;
      if (mediumIndex < sorted.length && !arranged.contains(sorted[mediumIndex])) {
        arranged.add(sorted[mediumIndex]);
      }
    }

    return arranged;
  }

  /// Generate question fingerprint for duplicate detection
  /// Task E6: Question fingerprinting
  String _generateFingerprint(Question question) {
    final content = StringBuffer();
    content.write(question.questionText.toLowerCase().trim());
    content.write('|');
    content.write(question.correctAnswer.toLowerCase().trim());
    
    if (question.options != null) {
      final sortedOptions = List<String>.from(question.options!)..sort();
      content.write('|');
      content.write(sortedOptions.join(','));
    }

    final bytes = utf8.encode(content.toString());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Extract topic/concept from question
  String _extractTopic(Question question) {
    // Simplified topic extraction
    // In production, this could use NLP or predefined topic tags
    final text = question.questionText.toLowerCase();
    
    // Math topics
    if (text.contains('equation')) return 'equations';
    if (text.contains('inequality')) return 'inequalities';
    if (text.contains('function')) return 'functions';
    if (text.contains('fraction')) return 'fractions';
    if (text.contains('decimal')) return 'decimals';
    if (text.contains('percent')) return 'percentages';
    
    // Physics topics
    if (text.contains('force')) return 'forces';
    if (text.contains('energy')) return 'energy';
    if (text.contains('motion')) return 'motion';
    if (text.contains('velocity')) return 'velocity';
    
    // Chemistry topics
    if (text.contains('atom')) return 'atoms';
    if (text.contains('molecule')) return 'molecules';
    if (text.contains('reaction')) return 'reactions';
    if (text.contains('bond')) return 'bonding';
    
    // Biology topics
    if (text.contains('cell')) return 'cells';
    if (text.contains('gene')) return 'genetics';
    if (text.contains('evolution')) return 'evolution';
    
    return 'general';
  }

  /// Track questions shown to user
  /// Task E6: Recent questions tracking
  Future<void> _trackQuestions(List<Question> questions, SubjectType subject) async {
    final fingerprints = _recentQuestions[subject] ?? [];
    
    for (final q in questions) {
      final hash = _generateFingerprint(q);
      fingerprints.insert(0, QuestionFingerprint(
        hash: hash,
        questionId: q.id,
        timestamp: DateTime.now(),
      ));
    }

    // Keep only last 20
    if (fingerprints.length > _recentQuestionsWindow) {
      fingerprints.removeRange(_recentQuestionsWindow, fingerprints.length);
    }

    _recentQuestions[subject] = fingerprints;
    await _saveRecentQuestions();
  }

  /// Log diversity statistics
  void _logDiversityStats(List<Question> questions) {
    final typeCounts = <QuestionType, int>{};
    final difficultyCounts = <String, int>{'easy': 0, 'medium': 0, 'hard': 0};
    
    for (final q in questions) {
      typeCounts[q.type] = (typeCounts[q.type] ?? 0) + 1;
      
      if (q.difficulty <= 3) {
        difficultyCounts['easy'] = difficultyCounts['easy']! + 1;
      } else if (q.difficulty <= 7) {
        difficultyCounts['medium'] = difficultyCounts['medium']! + 1;
      } else {
        difficultyCounts['hard'] = difficultyCounts['hard']! + 1;
      }
    }

    debugPrint('[DiversityManager] 📊 Type distribution:');
    typeCounts.forEach((type, count) {
      debugPrint('   ${type.name}: $count');
    });
    
    debugPrint('[DiversityManager] 📊 Difficulty distribution:');
    debugPrint('   Easy: ${difficultyCounts['easy']}, Medium: ${difficultyCounts['medium']}, Hard: ${difficultyCounts['hard']}');
  }

  /// Load recent questions from storage
  Future<void> _loadRecentQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_recentQuestionsKey);
    
    if (json != null) {
      try {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          final subject = SubjectType.values.firstWhere((s) => s.name == key);
          final fingerprints = (value as List)
              .map((item) => QuestionFingerprint.fromJson(item as Map<String, dynamic>))
              .toList();
          _recentQuestions[subject] = fingerprints;
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[DiversityManager] Error loading recent questions: $e');
        }
      }
    }
  }

  /// Save recent questions to storage
  Future<void> _saveRecentQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _recentQuestions.map((k, v) => MapEntry(k.name, v.map((f) => f.toJson()).toList()));
    await prefs.setString(_recentQuestionsKey, jsonEncode(map));
  }

  /// Load topic rotation state
  Future<void> _loadTopicRotation() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_topicRotationKey);
    
    if (json != null) {
      try {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          _topicRotation[key] = TopicRotationState.fromJson(value as Map<String, dynamic>);
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[DiversityManager] Error loading topic rotation: $e');
        }
      }
    }
  }

  /// Save topic rotation state
  Future<void> _saveTopicRotation() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _topicRotation.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_topicRotationKey, jsonEncode(map));
  }

  /// Clear recent questions for a subject
  Future<void> clearRecentQuestions(SubjectType subject) async {
    _recentQuestions[subject] = [];
    await _saveRecentQuestions();
    
    if (kDebugMode) {
      debugPrint('[DiversityManager] 🗑️ Cleared recent questions for ${subject.name}');
    }
  }
}

/// Question fingerprint for duplicate detection
class QuestionFingerprint {
  final String hash;
  final String questionId;
  final DateTime timestamp;

  QuestionFingerprint({
    required this.hash,
    required this.questionId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'hash': hash,
    'questionId': questionId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory QuestionFingerprint.fromJson(Map<String, dynamic> json) => QuestionFingerprint(
    hash: json['hash'] as String,
    questionId: json['questionId'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

/// Topic rotation state for systematic coverage
class TopicRotationState {
  final List<String> topics;
  int lastUsedIndex;

  TopicRotationState({
    required this.topics,
    this.lastUsedIndex = 0,
  });

  Map<String, dynamic> toJson() => {
    'topics': topics,
    'lastUsedIndex': lastUsedIndex,
  };

  factory TopicRotationState.fromJson(Map<String, dynamic> json) => TopicRotationState(
    topics: List<String>.from(json['topics'] as List),
    lastUsedIndex: json['lastUsedIndex'] as int,
  );
}

