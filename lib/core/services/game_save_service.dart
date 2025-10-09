import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/question.dart';
import '../models/question_pool.dart';

/// Service for managing game saves and session persistence
class GameSaveService {
  static const String _gameSessionKey = 'game_session_data';
  static const String _completedSetsKey = 'completed_question_sets';
  static const String _sessionStatsKey = 'session_statistics';
  static const String _achievementsKey = 'game_achievements';

  /// Save current game session
  Future<void> saveGameSession(GameSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(session.toJson());
    await prefs.setString(_gameSessionKey, jsonString);
  }

  /// Load current game session
  Future<GameSession?> loadGameSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_gameSessionKey);
    
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString);
        return GameSession.fromJson(json);
      } catch (e) {
        // If loading fails, return null
        return null;
      }
    }
    
    return null;
  }

  /// Save a completed question set
  Future<void> saveCompletedQuestionSet(CompletedQuestionSet set) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_completedSetsKey);
    
    List<CompletedQuestionSet> completedSets = [];
    if (jsonString != null) {
      try {
        final decoded = jsonDecode(jsonString) as List;
        completedSets = decoded
            .cast<Map<String, dynamic>>()
            .map((json) => CompletedQuestionSet.fromJson(json))
            .toList();
      } catch (e) {
        completedSets = [];
      }
    }
    
    completedSets.add(set);
    
    final updatedJsonString = jsonEncode(
      completedSets.map((set) => set.toJson()).toList(),
    );
    await prefs.setString(_completedSetsKey, updatedJsonString);
    
    // Update session statistics
    await _updateSessionStatistics(set);
    
    // Check and update achievements
    await _checkAndUpdateAchievements(set, completedSets);
  }

  /// Update session statistics based on a completed question set
  Future<void> _updateSessionStatistics(CompletedQuestionSet completedSet) async {
    final currentStats = await loadSessionStats();
    
    // Update subject counts
    final updatedSubjectCounts = Map<String, int>.from(currentStats.subjectCounts);
    updatedSubjectCounts[completedSet.subject.name] = 
        (updatedSubjectCounts[completedSet.subject.name] ?? 0) + 1;
    
    // Update category counts
    final updatedCategoryCounts = Map<String, int>.from(currentStats.categoryCounts);
    updatedCategoryCounts[completedSet.category.name] = 
        (updatedCategoryCounts[completedSet.category.name] ?? 0) + 1;
    
    // Create updated statistics
    final updatedStats = currentStats.copyWith(
      totalSessions: currentStats.totalSessions + 1,
      totalQuestionsAnswered: currentStats.totalQuestionsAnswered + completedSet.totalQuestions,
      totalCorrectAnswers: currentStats.totalCorrectAnswers + completedSet.correctAnswers,
      totalTimeSpent: currentStats.totalTimeSpent + completedSet.timeSpent,
      lastSessionDate: completedSet.completedAt,
      subjectCounts: updatedSubjectCounts,
      categoryCounts: updatedCategoryCounts,
    );
    
    // Save updated statistics
    await saveSessionStats(updatedStats);
  }

  /// Get completed question sets for a subject
  Future<List<CompletedQuestionSet>> getCompletedSets({
    SubjectType? subject,
    QuestionCategory? category,
    DateTime? since,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_completedSetsKey);
    
    if (jsonString == null) return [];
    
    try {
      final decoded = jsonDecode(jsonString) as List;
      final completedSets = decoded
          .cast<Map<String, dynamic>>()
          .map((json) => CompletedQuestionSet.fromJson(json))
          .toList();
      
      // Apply filters
      return completedSets.where((set) {
        if (subject != null && set.subject != subject) return false;
        if (category != null && set.category != category) return false;
        if (since != null && set.completedAt.isBefore(since)) return false;
        return true;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save session statistics
  Future<void> saveSessionStats(SessionStatistics stats) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(stats.toJson());
    await prefs.setString(_sessionStatsKey, jsonString);
  }

  /// Load session statistics
  Future<SessionStatistics> loadSessionStats() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_sessionStatsKey);
    
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString);
        return SessionStatistics.fromJson(json);
      } catch (e) {
        // If loading fails, return default stats
        return SessionStatistics.empty();
      }
    }
    
    return SessionStatistics.empty();
  }

  /// Clear game session (when completed or abandoned)
  Future<void> clearGameSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gameSessionKey);
  }

  /// Get achievement progress
  Future<Map<String, dynamic>> getAchievementProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_achievementsKey);
    
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return {};
      }
    }
    
    return {};
  }

  /// Update achievement progress
  Future<void> updateAchievementProgress(String achievementId, dynamic progress) async {
    final prefs = await SharedPreferences.getInstance();
    final currentProgress = await getAchievementProgress();
    
    currentProgress[achievementId] = progress;
    
    final jsonString = jsonEncode(currentProgress);
    await prefs.setString(_achievementsKey, jsonString);
  }

  /// Check and update achievements based on completed question set
  Future<void> _checkAndUpdateAchievements(CompletedQuestionSet completedSet, List<CompletedQuestionSet> allCompletedSets) async {
    // Perfect score achievement
    if (completedSet.score >= 100.0) {
      await updateAchievementProgress('perfect_score', true);
    }
    
    // Streak achievements - check last 5 sets
    if (allCompletedSets.length >= 5) {
      final recentSets = allCompletedSets.sublist(allCompletedSets.length - 5);
      if (recentSets.every((set) => set.score >= 100.0)) {
        await updateAchievementProgress('perfect_streak_5', true);
      }
    }
    
    // Subject mastery achievements
    final subjectSets = allCompletedSets
        .where((set) => set.subject == completedSet.subject)
        .toList();
    
    if (subjectSets.length >= 10) {
      await updateAchievementProgress('subject_mastery_${completedSet.subject.name}', true);
    }
    
    // Total sessions milestone
    if (allCompletedSets.length >= 50) {
      await updateAchievementProgress('sessions_milestone_50', true);
    }
  }

  /// Get performance analytics
  Future<Map<String, dynamic>> getPerformanceAnalytics() async {
    final completedSets = await getCompletedSets();
    
    final analytics = <String, dynamic>{};
    
    // Overall performance
    analytics['totalSetsCompleted'] = completedSets.length;
    analytics['averageScore'] = completedSets.isEmpty 
        ? 0.0 
        : completedSets.map((s) => s.score).reduce((a, b) => a + b) / completedSets.length;
    
    // Performance by subject
    final subjectPerformance = <String, Map<String, dynamic>>{};
    for (final subject in SubjectType.values) {
      final subjectSets = completedSets.where((s) => s.subject == subject).toList();
      subjectPerformance[subject.name] = {
        'completed': subjectSets.length,
        'averageScore': subjectSets.isEmpty 
            ? 0.0 
            : subjectSets.map((s) => s.score).reduce((a, b) => a + b) / subjectSets.length,
      };
    }
    analytics['subjectPerformance'] = subjectPerformance;
    
    // Performance by category
    final categoryPerformance = <String, Map<String, dynamic>>{};
    for (final category in QuestionCategory.values) {
      final categorySets = completedSets.where((s) => s.category == category).toList();
      categoryPerformance[category.name] = {
        'completed': categorySets.length,
        'averageScore': categorySets.isEmpty 
            ? 0.0 
            : categorySets.map((s) => s.score).reduce((a, b) => a + b) / categorySets.length,
      };
    }
    analytics['categoryPerformance'] = categoryPerformance;
    
    // Recent performance (last 7 days)
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentSets = completedSets.where((s) => s.completedAt.isAfter(weekAgo)).toList();
    analytics['recentPerformance'] = {
      'completed': recentSets.length,
      'averageScore': recentSets.isEmpty 
          ? 0.0 
          : recentSets.map((s) => s.score).reduce((a, b) => a + b) / recentSets.length,
    };
    
    return analytics;
  }
}

/// Represents a game session in progress
class GameSession {
  final String id;
  final SubjectType subject;
  final String skillId;
  final List<QuestionCategory> categories;
  final List<Question> questions;
  final List<String> userAnswers;
  final int currentQuestionIndex;
  final DateTime startTime;
  final int score;
  final int lives;

  const GameSession({
    required this.id,
    required this.subject,
    required this.skillId,
    required this.categories,
    required this.questions,
    required this.userAnswers,
    required this.currentQuestionIndex,
    required this.startTime,
    required this.score,
    required this.lives,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject.name,
    'skillId': skillId,
    'categories': categories.map((c) => c.name).toList(),
    'questions': questions.map((q) => (q as Question).toJson()).toList(),
    'userAnswers': userAnswers,
    'currentQuestionIndex': currentQuestionIndex,
    'startTime': startTime.toIso8601String(),
    'score': score,
    'lives': lives,
  };

  factory GameSession.fromJson(Map<String, dynamic> json) => GameSession(
    id: json['id'] as String,
    subject: SubjectType.values.firstWhere((s) => s.name == json['subject']),
    skillId: json['skillId'] as String,
    categories: (json['categories'] as List)
        .map((c) => QuestionCategory.values.firstWhere((cat) => cat.name == c))
        .toList(),
    questions: (json['questions'] as List)
        .map((q) => Question.fromJson(q as Map<String, dynamic>))
        .toList(),
    userAnswers: List<String>.from(json['userAnswers'] as List),
    currentQuestionIndex: json['currentQuestionIndex'] as int,
    startTime: DateTime.parse(json['startTime'] as String),
    score: json['score'] as int,
    lives: json['lives'] as int,
  );

  GameSession copyWith({
    String? id,
    SubjectType? subject,
    String? skillId,
    List<QuestionCategory>? categories,
    List<Question>? questions,
    List<String>? userAnswers,
    int? currentQuestionIndex,
    DateTime? startTime,
    int? score,
    int? lives,
  }) => GameSession(
    id: id ?? this.id,
    subject: subject ?? this.subject,
    skillId: skillId ?? this.skillId,
    categories: categories ?? this.categories,
    questions: questions ?? this.questions,
    userAnswers: userAnswers ?? this.userAnswers,
    currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    startTime: startTime ?? this.startTime,
    score: score ?? this.score,
    lives: lives ?? this.lives,
  );
}

/// Represents a completed question set
class CompletedQuestionSet {
  final String id;
  final SubjectType subject;
  final String skillId;
  final QuestionCategory category;
  final int totalQuestions;
  final int correctAnswers;
  final double score;
  final Duration timeSpent;
  final DateTime completedAt;
  final List<String> questionsAnswered;

  const CompletedQuestionSet({
    required this.id,
    required this.subject,
    required this.skillId,
    required this.category,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.score,
    required this.timeSpent,
    required this.completedAt,
    required this.questionsAnswered,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject.name,
    'skillId': skillId,
    'category': category.name,
    'totalQuestions': totalQuestions,
    'correctAnswers': correctAnswers,
    'score': score,
    'timeSpent': timeSpent.inMilliseconds,
    'completedAt': completedAt.toIso8601String(),
    'questionsAnswered': questionsAnswered,
  };

  factory CompletedQuestionSet.fromJson(Map<String, dynamic> json) => CompletedQuestionSet(
    id: json['id'] as String,
    subject: SubjectType.values.firstWhere((s) => s.name == json['subject']),
    skillId: json['skillId'] as String,
    category: QuestionCategory.values.firstWhere((c) => c.name == json['category']),
    totalQuestions: json['totalQuestions'] as int,
    correctAnswers: json['correctAnswers'] as int,
    score: (json['score'] as num).toDouble(),
    timeSpent: Duration(milliseconds: json['timeSpent'] as int),
    completedAt: DateTime.parse(json['completedAt'] as String),
    questionsAnswered: List<String>.from(json['questionsAnswered'] as List),
  );
}

/// Session statistics tracking
class SessionStatistics {
  final int totalSessions;
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;
  final Duration totalTimeSpent;
  final DateTime lastSessionDate;
  final Map<String, int> subjectCounts;
  final Map<String, int> categoryCounts;

  const SessionStatistics({
    required this.totalSessions,
    required this.totalQuestionsAnswered,
    required this.totalCorrectAnswers,
    required this.totalTimeSpent,
    required this.lastSessionDate,
    required this.subjectCounts,
    required this.categoryCounts,
  });

  factory SessionStatistics.empty() => SessionStatistics(
    totalSessions: 0,
    totalQuestionsAnswered: 0,
    totalCorrectAnswers: 0,
    totalTimeSpent: Duration.zero,
    lastSessionDate: DateTime.now(),
    subjectCounts: {},
    categoryCounts: {},
  );

  Map<String, dynamic> toJson() => {
    'totalSessions': totalSessions,
    'totalQuestionsAnswered': totalQuestionsAnswered,
    'totalCorrectAnswers': totalCorrectAnswers,
    'totalTimeSpent': totalTimeSpent.inMilliseconds,
    'lastSessionDate': lastSessionDate.toIso8601String(),
    'subjectCounts': subjectCounts,
    'categoryCounts': categoryCounts,
  };

  factory SessionStatistics.fromJson(Map<String, dynamic> json) => SessionStatistics(
    totalSessions: json['totalSessions'] as int,
    totalQuestionsAnswered: json['totalQuestionsAnswered'] as int,
    totalCorrectAnswers: json['totalCorrectAnswers'] as int,
    totalTimeSpent: Duration(milliseconds: json['totalTimeSpent'] as int),
    lastSessionDate: DateTime.parse(json['lastSessionDate'] as String),
    subjectCounts: Map<String, int>.from(json['subjectCounts'] as Map),
    categoryCounts: Map<String, int>.from(json['categoryCounts'] as Map),
  );

  SessionStatistics copyWith({
    int? totalSessions,
    int? totalQuestionsAnswered,
    int? totalCorrectAnswers,
    Duration? totalTimeSpent,
    DateTime? lastSessionDate,
    Map<String, int>? subjectCounts,
    Map<String, int>? categoryCounts,
  }) => SessionStatistics(
    totalSessions: totalSessions ?? this.totalSessions,
    totalQuestionsAnswered: totalQuestionsAnswered ?? this.totalQuestionsAnswered,
    totalCorrectAnswers: totalCorrectAnswers ?? this.totalCorrectAnswers,
    totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
    lastSessionDate: lastSessionDate ?? this.lastSessionDate,
    subjectCounts: subjectCounts ?? this.subjectCounts,
    categoryCounts: categoryCounts ?? this.categoryCounts,
  );
}