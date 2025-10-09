import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/question.dart';
import 'content_quality_validator.dart';

/// Content Quality Metrics Service
/// Tracks and analyzes AI-generated question quality over time
/// Category E Task E8: Content Quality Metrics
class ContentQualityMetrics {
  static ContentQualityMetrics? _instance;
  static ContentQualityMetrics get instance => _instance ??= ContentQualityMetrics._();
  
  ContentQualityMetrics._();

  // Storage keys
  static const String _qualityScoresKey = 'quality_scores_v1';
  static const String _userFeedbackKey = 'user_feedback_v1';
  static const String _flaggedQuestionsKey = 'flagged_questions_v1';
  static const String _questionStatsKey = 'question_stats_v1';

  // Thresholds
  static const double _minQualityScore = 0.5; // 50%
  static const double _minAccuracyRate = 0.3; // 30%
  static const double _maxSkipRate = 0.5; // 50%

  // In-memory cache
  final Map<String, QualityScoreEntry> _qualityScores = {};
  final Map<String, List<UserFeedbackEntry>> _userFeedback = {};
  final Map<String, FlaggedQuestion> _flaggedQuestions = {};
  final Map<String, QuestionStats> _questionStats = {};

  /// Initialize the service
  Future<void> initialize() async {
    await _loadQualityScores();
    await _loadUserFeedback();
    await _loadFlaggedQuestions();
    await _loadQuestionStats();
    
    if (kDebugMode) {
      debugPrint('[QualityMetrics] ✅ Service initialized');
      debugPrint('[QualityMetrics] 📊 Loaded ${_qualityScores.length} quality scores');
      debugPrint('[QualityMetrics] 📊 Loaded ${_flaggedQuestions.length} flagged questions');
    }
  }

  /// Track quality score for a question
  /// Task E8: Store quality score with metadata
  Future<void> trackQualityScore({
    required String questionId,
    required double qualityScore,
    required SubjectType subject,
    required String skillId,
  }) async {
    final entry = QualityScoreEntry(
      questionId: questionId,
      qualityScore: qualityScore,
      subject: subject,
      skillId: skillId,
      timestamp: DateTime.now(),
    );

    _qualityScores[questionId] = entry;
    await _saveQualityScores();

    // Check if question should be flagged
    if (qualityScore < _minQualityScore) {
      await _flagQuestion(
        questionId: questionId,
        reason: 'Low quality score: ${(qualityScore * 100).toStringAsFixed(1)}%',
        metrics: {'quality_score': qualityScore},
      );
    }

    if (kDebugMode) {
      debugPrint('[QualityMetrics] 📊 Tracked quality score for $questionId: ${(qualityScore * 100).toStringAsFixed(1)}%');
    }
  }

  /// Track question interaction (answer, skip, time)
  /// Task E8: Collect user feedback
  Future<void> trackQuestionInteraction({
    required String questionId,
    required SubjectType subject,
    required String skillId,
    required bool wasSkipped,
    required bool wasCorrect,
    required Duration responseTime,
  }) async {
    // Update question stats
    final stats = _questionStats[questionId] ?? QuestionStats(
      questionId: questionId,
      subject: subject,
      skillId: skillId,
      timesShown: 0,
      timesSkipped: 0,
      timesAnswered: 0,
      timesCorrect: 0,
      totalResponseTime: Duration.zero,
    );

    stats.timesShown++;
    if (wasSkipped) {
      stats.timesSkipped++;
    } else {
      stats.timesAnswered++;
      if (wasCorrect) {
        stats.timesCorrect++;
      }
      stats.totalResponseTime += responseTime;
    }

    _questionStats[questionId] = stats;
    await _saveQuestionStats();

    // Check for problematic patterns
    await _checkForProblematicPatterns(questionId, stats);

    if (kDebugMode) {
      debugPrint('[QualityMetrics] 📊 Tracked interaction for $questionId: skip=$wasSkipped, correct=$wasCorrect');
    }
  }

  /// Track user report for a question
  /// Task E8: User feedback collection
  Future<void> trackUserReport({
    required String questionId,
    required String reason,
    String? userComment,
  }) async {
    final feedback = UserFeedbackEntry(
      questionId: questionId,
      feedbackType: FeedbackType.report,
      reason: reason,
      userComment: userComment,
      timestamp: DateTime.now(),
    );

    _userFeedback.putIfAbsent(questionId, () => []).add(feedback);
    await _saveUserFeedback();

    // Flag question with user report
    await _flagQuestion(
      questionId: questionId,
      reason: 'User report: $reason',
      metrics: {'report_count': _userFeedback[questionId]!.length},
    );

    if (kDebugMode) {
      debugPrint('[QualityMetrics] 🚩 User reported question $questionId: $reason');
    }
  }

  /// Check for problematic patterns
  /// Task E8: Identify problematic questions
  Future<void> _checkForProblematicPatterns(String questionId, QuestionStats stats) async {
    // Check skip rate
    if (stats.timesShown >= 10) {
      final skipRate = stats.timesSkipped / stats.timesShown;
      if (skipRate > _maxSkipRate) {
        await _flagQuestion(
          questionId: questionId,
          reason: 'High skip rate: ${(skipRate * 100).toStringAsFixed(1)}%',
          metrics: {
            'skip_rate': skipRate,
            'times_shown': stats.timesShown,
            'times_skipped': stats.timesSkipped,
          },
        );
      }
    }

    // Check accuracy rate
    if (stats.timesAnswered >= 10) {
      final accuracyRate = stats.timesCorrect / stats.timesAnswered;
      if (accuracyRate < _minAccuracyRate) {
        await _flagQuestion(
          questionId: questionId,
          reason: 'Low accuracy rate: ${(accuracyRate * 100).toStringAsFixed(1)}%',
          metrics: {
            'accuracy_rate': accuracyRate,
            'times_answered': stats.timesAnswered,
            'times_correct': stats.timesCorrect,
          },
        );
      }
    }
  }

  /// Flag a question for review
  Future<void> _flagQuestion({
    required String questionId,
    required String reason,
    required Map<String, dynamic> metrics,
  }) async {
    final flagged = _flaggedQuestions[questionId] ?? FlaggedQuestion(
      questionId: questionId,
      reasons: [],
      metrics: {},
      flaggedAt: DateTime.now(),
    );

    if (!flagged.reasons.contains(reason)) {
      flagged.reasons.add(reason);
    }
    flagged.metrics.addAll(metrics);
    flagged.lastUpdated = DateTime.now();

    _flaggedQuestions[questionId] = flagged;
    await _saveFlaggedQuestions();

    if (kDebugMode) {
      debugPrint('[QualityMetrics] 🚩 Flagged question $questionId: $reason');
    }
  }

  /// Get average quality score for subject/skill
  /// Task E8: Rolling average calculation
  double getAverageQualityScore({
    SubjectType? subject,
    String? skillId,
  }) {
    final filtered = _qualityScores.values.where((entry) {
      if (subject != null && entry.subject != subject) return false;
      if (skillId != null && entry.skillId != skillId) return false;
      return true;
    }).toList();

    if (filtered.isEmpty) return 0.0;

    final sum = filtered.fold<double>(0.0, (sum, entry) => sum + entry.qualityScore);
    return sum / filtered.length;
  }

  /// Get quality report
  /// Task E8: Generate comprehensive quality report
  Future<QualityReport> getQualityReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
    final end = endDate ?? DateTime.now();

    // Filter scores by date range
    final scoresInRange = _qualityScores.values.where((entry) {
      return entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end);
    }).toList();

    // Calculate overall average
    final overallAverage = scoresInRange.isEmpty
        ? 0.0
        : scoresInRange.fold<double>(0.0, (sum, e) => sum + e.qualityScore) / scoresInRange.length;

    // Calculate per-subject averages
    final subjectAverages = <SubjectType, double>{};
    for (final subject in SubjectType.values) {
      final subjectScores = scoresInRange.where((e) => e.subject == subject).toList();
      if (subjectScores.isNotEmpty) {
        subjectAverages[subject] = subjectScores.fold<double>(0.0, (sum, e) => sum + e.qualityScore) / subjectScores.length;
      }
    }

    // Calculate trend (compare with previous period)
    final previousStart = start.subtract(end.difference(start));
    final previousScores = _qualityScores.values.where((entry) {
      return entry.timestamp.isAfter(previousStart) && entry.timestamp.isBefore(start);
    }).toList();

    final previousAverage = previousScores.isEmpty
        ? 0.0
        : previousScores.fold<double>(0.0, (sum, e) => sum + e.qualityScore) / previousScores.length;

    final trend = previousAverage > 0
        ? ((overallAverage - previousAverage) / previousAverage) * 100
        : 0.0;

    // Generate recommendations
    final recommendations = _generateRecommendations(subjectAverages, _flaggedQuestions.values.toList());

    return QualityReport(
      startDate: start,
      endDate: end,
      overallAverageScore: overallAverage,
      subjectAverages: subjectAverages,
      totalQuestionsTracked: scoresInRange.length,
      flaggedQuestions: _flaggedQuestions.values.toList(),
      trend: trend,
      recommendations: recommendations,
    );
  }

  /// Generate recommendations for content improvement
  /// Task E8: Actionable recommendations
  List<String> _generateRecommendations(
    Map<SubjectType, double> subjectAverages,
    List<FlaggedQuestion> flaggedQuestions,
  ) {
    final recommendations = <String>[];

    // Check subject quality
    subjectAverages.forEach((subject, average) {
      if (average < 0.6) {
        recommendations.add('⚠️ Focus on improving ${subject.name} content quality (current: ${(average * 100).toStringAsFixed(1)}%)');
      } else if (average > 0.85) {
        recommendations.add('✅ ${subject.name} content quality is excellent (${(average * 100).toStringAsFixed(1)}%)');
      }
    });

    // Check flagged questions
    if (flaggedQuestions.length > 10) {
      recommendations.add('🚩 ${flaggedQuestions.length} questions flagged for review - prioritize fixing these');
    }

    // Check for high skip rates
    final highSkipQuestions = flaggedQuestions.where((q) {
      return q.reasons.any((r) => r.contains('skip rate'));
    }).length;
    if (highSkipQuestions > 5) {
      recommendations.add('⏭️ $highSkipQuestions questions have high skip rates - review question clarity');
    }

    // Check for low accuracy
    final lowAccuracyQuestions = flaggedQuestions.where((q) {
      return q.reasons.any((r) => r.contains('accuracy rate'));
    }).length;
    if (lowAccuracyQuestions > 5) {
      recommendations.add('🎯 $lowAccuracyQuestions questions have low accuracy - review difficulty and correctness');
    }

    if (recommendations.isEmpty) {
      recommendations.add('🎉 Content quality is good! Keep up the great work.');
    }

    return recommendations;
  }

  /// Get flagged questions for review
  List<FlaggedQuestion> getFlaggedQuestions({
    SubjectType? subject,
    String? skillId,
  }) {
    return _flaggedQuestions.values.where((flagged) {
      final stats = _questionStats[flagged.questionId];
      if (stats == null) return true;
      if (subject != null && stats.subject != subject) return false;
      if (skillId != null && stats.skillId != skillId) return false;
      return true;
    }).toList();
  }

  /// Clear flagged status for a question (after review)
  Future<void> clearFlaggedQuestion(String questionId) async {
    _flaggedQuestions.remove(questionId);
    await _saveFlaggedQuestions();
    
    if (kDebugMode) {
      debugPrint('[QualityMetrics] ✅ Cleared flagged status for $questionId');
    }
  }

  /// Storage methods
  Future<void> _loadQualityScores() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_qualityScoresKey);
    if (json != null) {
      try {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          _qualityScores[key] = QualityScoreEntry.fromJson(value as Map<String, dynamic>);
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[QualityMetrics] Error loading quality scores: $e');
        }
      }
    }
  }

  Future<void> _saveQualityScores() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _qualityScores.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_qualityScoresKey, jsonEncode(map));
  }

  Future<void> _loadUserFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_userFeedbackKey);
    if (json != null) {
      try {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          _userFeedback[key] = (value as List)
              .map((item) => UserFeedbackEntry.fromJson(item as Map<String, dynamic>))
              .toList();
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[QualityMetrics] Error loading user feedback: $e');
        }
      }
    }
  }

  Future<void> _saveUserFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _userFeedback.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()));
    await prefs.setString(_userFeedbackKey, jsonEncode(map));
  }

  Future<void> _loadFlaggedQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_flaggedQuestionsKey);
    if (json != null) {
      try {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          _flaggedQuestions[key] = FlaggedQuestion.fromJson(value as Map<String, dynamic>);
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[QualityMetrics] Error loading flagged questions: $e');
        }
      }
    }
  }

  Future<void> _saveFlaggedQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _flaggedQuestions.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_flaggedQuestionsKey, jsonEncode(map));
  }

  Future<void> _loadQuestionStats() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_questionStatsKey);
    if (json != null) {
      try {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          _questionStats[key] = QuestionStats.fromJson(value as Map<String, dynamic>);
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[QualityMetrics] Error loading question stats: $e');
        }
      }
    }
  }

  Future<void> _saveQuestionStats() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _questionStats.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_questionStatsKey, jsonEncode(map));
  }
}

/// Quality score entry
class QualityScoreEntry {
  final String questionId;
  final double qualityScore;
  final SubjectType subject;
  final String skillId;
  final DateTime timestamp;

  QualityScoreEntry({
    required this.questionId,
    required this.qualityScore,
    required this.subject,
    required this.skillId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'qualityScore': qualityScore,
    'subject': subject.name,
    'skillId': skillId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory QualityScoreEntry.fromJson(Map<String, dynamic> json) => QualityScoreEntry(
    questionId: json['questionId'] as String,
    qualityScore: json['qualityScore'] as double,
    subject: SubjectType.values.firstWhere((s) => s.name == json['subject']),
    skillId: json['skillId'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

/// User feedback entry
enum FeedbackType { report, skip, lowAccuracy }

class UserFeedbackEntry {
  final String questionId;
  final FeedbackType feedbackType;
  final String reason;
  final String? userComment;
  final DateTime timestamp;

  UserFeedbackEntry({
    required this.questionId,
    required this.feedbackType,
    required this.reason,
    this.userComment,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'feedbackType': feedbackType.name,
    'reason': reason,
    'userComment': userComment,
    'timestamp': timestamp.toIso8601String(),
  };

  factory UserFeedbackEntry.fromJson(Map<String, dynamic> json) => UserFeedbackEntry(
    questionId: json['questionId'] as String,
    feedbackType: FeedbackType.values.firstWhere((t) => t.name == json['feedbackType']),
    reason: json['reason'] as String,
    userComment: json['userComment'] as String?,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

/// Flagged question
class FlaggedQuestion {
  final String questionId;
  final List<String> reasons;
  final Map<String, dynamic> metrics;
  final DateTime flaggedAt;
  DateTime lastUpdated;

  FlaggedQuestion({
    required this.questionId,
    required this.reasons,
    required this.metrics,
    required this.flaggedAt,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? flaggedAt;

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'reasons': reasons,
    'metrics': metrics,
    'flaggedAt': flaggedAt.toIso8601String(),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory FlaggedQuestion.fromJson(Map<String, dynamic> json) => FlaggedQuestion(
    questionId: json['questionId'] as String,
    reasons: List<String>.from(json['reasons'] as List),
    metrics: Map<String, dynamic>.from(json['metrics'] as Map),
    flaggedAt: DateTime.parse(json['flaggedAt'] as String),
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  );
}

/// Question statistics
class QuestionStats {
  final String questionId;
  final SubjectType subject;
  final String skillId;
  int timesShown;
  int timesSkipped;
  int timesAnswered;
  int timesCorrect;
  Duration totalResponseTime;

  QuestionStats({
    required this.questionId,
    required this.subject,
    required this.skillId,
    required this.timesShown,
    required this.timesSkipped,
    required this.timesAnswered,
    required this.timesCorrect,
    required this.totalResponseTime,
  });

  double get skipRate => timesShown > 0 ? timesSkipped / timesShown : 0.0;
  double get accuracyRate => timesAnswered > 0 ? timesCorrect / timesAnswered : 0.0;
  Duration get averageResponseTime => timesAnswered > 0 
      ? Duration(milliseconds: totalResponseTime.inMilliseconds ~/ timesAnswered)
      : Duration.zero;

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'subject': subject.name,
    'skillId': skillId,
    'timesShown': timesShown,
    'timesSkipped': timesSkipped,
    'timesAnswered': timesAnswered,
    'timesCorrect': timesCorrect,
    'totalResponseTime': totalResponseTime.inMilliseconds,
  };

  factory QuestionStats.fromJson(Map<String, dynamic> json) => QuestionStats(
    questionId: json['questionId'] as String,
    subject: SubjectType.values.firstWhere((s) => s.name == json['subject']),
    skillId: json['skillId'] as String,
    timesShown: json['timesShown'] as int,
    timesSkipped: json['timesSkipped'] as int,
    timesAnswered: json['timesAnswered'] as int,
    timesCorrect: json['timesCorrect'] as int,
    totalResponseTime: Duration(milliseconds: json['totalResponseTime'] as int),
  );
}

/// Quality report
class QualityReport {
  final DateTime startDate;
  final DateTime endDate;
  final double overallAverageScore;
  final Map<SubjectType, double> subjectAverages;
  final int totalQuestionsTracked;
  final List<FlaggedQuestion> flaggedQuestions;
  final double trend; // Percentage change from previous period
  final List<String> recommendations;

  QualityReport({
    required this.startDate,
    required this.endDate,
    required this.overallAverageScore,
    required this.subjectAverages,
    required this.totalQuestionsTracked,
    required this.flaggedQuestions,
    required this.trend,
    required this.recommendations,
  });

  String toFormattedString() {
    final buffer = StringBuffer();
    buffer.writeln('========== Quality Report ==========');
    buffer.writeln('Period: ${startDate.toLocal()} to ${endDate.toLocal()}');
    buffer.writeln('');
    buffer.writeln('📊 Overall Average Score: ${(overallAverageScore * 100).toStringAsFixed(1)}%');
    buffer.writeln('📈 Trend: ${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(1)}%');
    buffer.writeln('📝 Total Questions Tracked: $totalQuestionsTracked');
    buffer.writeln('🚩 Flagged Questions: ${flaggedQuestions.length}');
    buffer.writeln('');
    buffer.writeln('📚 Subject Averages:');
    subjectAverages.forEach((subject, average) {
      buffer.writeln('   ${subject.name}: ${(average * 100).toStringAsFixed(1)}%');
    });
    buffer.writeln('');
    buffer.writeln('💡 Recommendations:');
    for (final rec in recommendations) {
      buffer.writeln('   $rec');
    }
    buffer.writeln('====================================');
    return buffer.toString();
  }
}

