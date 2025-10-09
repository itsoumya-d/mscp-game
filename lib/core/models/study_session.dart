import 'flashcard.dart';

/// Study session model for tracking learning sessions
class StudySession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int targetCards;
  final List<Flashcard> flashcards;
  final List<ReviewResult> results;
  final String? subjectId;
  final bool isCompleted;
  final Map<String, dynamic>? metadata;

  const StudySession({
    required this.id,
    required this.startTime,
    required this.targetCards,
    required this.flashcards,
    this.endTime,
    this.results = const [],
    this.subjectId,
    this.isCompleted = false,
    this.metadata,
  });

  /// Get session duration
  Duration get duration {
    if (endTime == null) return DateTime.now().difference(startTime);
    return endTime!.difference(startTime);
  }

  /// Get completion percentage
  double get completionPercentage {
    if (flashcards.isEmpty) return 0.0;
    return results.length / flashcards.length;
  }

  /// Get session accuracy
  double get accuracy {
    if (results.isEmpty) return 0.0;
    final correctAnswers = results.where((r) => 
      r.rating == ReviewRating.good || r.rating == ReviewRating.easy
    ).length;
    return correctAnswers / results.length;
  }

  /// Get total XP earned in session
  int get totalXpEarned => results.fold(0, (sum, result) => sum + result.xpEarned);

  /// Get average response time
  double get averageResponseTime {
    if (results.isEmpty) return 0.0;
    return results.fold(0.0, (sum, result) => sum + result.responseTime) / results.length;
  }

  /// Check if session is perfect (100% accuracy)
  bool get isPerfectSession => results.isNotEmpty && accuracy == 1.0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'targetCards': targetCards,
    'flashcards': flashcards.map((f) => f.toJson()).toList(),
    'results': results.map((r) => r.toJson()).toList(),
    'subjectId': subjectId,
    'isCompleted': isCompleted,
    'metadata': metadata,
  };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
    id: json['id'],
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    targetCards: json['targetCards'],
    flashcards: (json['flashcards'] as List).map((f) => Flashcard.fromJson(f)).toList(),
    results: (json['results'] as List).map((r) => ReviewResult.fromJson(r)).toList(),
    subjectId: json['subjectId'],
    isCompleted: json['isCompleted'] ?? false,
    metadata: json['metadata'],
  );

  StudySession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? targetCards,
    List<Flashcard>? flashcards,
    List<ReviewResult>? results,
    String? subjectId,
    bool? isCompleted,
    Map<String, dynamic>? metadata,
  }) => StudySession(
    id: id ?? this.id,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    targetCards: targetCards ?? this.targetCards,
    flashcards: flashcards ?? this.flashcards,
    results: results ?? this.results,
    subjectId: subjectId ?? this.subjectId,
    isCompleted: isCompleted ?? this.isCompleted,
    metadata: metadata ?? this.metadata,
  );
}

/// Session result with comprehensive statistics and rewards
class SessionResult {
  final StudySession session;
  final int totalXp;
  final double accuracy;
  final List<Achievement> achievements;
  final Duration studyTime;
  final Map<String, int> ratingDistribution;
  final double averageResponseTime;
  final int streakCount;

  const SessionResult({
    required this.session,
    required this.totalXp,
    required this.accuracy,
    required this.achievements,
    required this.studyTime,
    this.ratingDistribution = const {},
    this.averageResponseTime = 0.0,
    this.streakCount = 0,
  });

  /// Get performance level based on accuracy
  String get performanceLevel {
    if (accuracy >= 0.95) return 'Excellent';
    if (accuracy >= 0.85) return 'Great';
    if (accuracy >= 0.75) return 'Good';
    if (accuracy >= 0.65) return 'Fair';
    return 'Needs Improvement';
  }

  /// Get study efficiency (XP per minute)
  double get studyEfficiency {
    final minutes = studyTime.inMinutes;
    return minutes > 0 ? totalXp / minutes : 0.0;
  }

  /// Check if session qualifies for bonus rewards
  bool get qualifiesForBonus => accuracy >= 0.8 && session.results.length >= 10;

  Map<String, dynamic> toJson() => {
    'session': session.toJson(),
    'totalXp': totalXp,
    'accuracy': accuracy,
    'achievements': achievements.map((a) => a.toJson()).toList(),
    'studyTime': studyTime.inMilliseconds,
    'ratingDistribution': ratingDistribution,
    'averageResponseTime': averageResponseTime,
    'streakCount': streakCount,
  };

  factory SessionResult.fromJson(Map<String, dynamic> json) => SessionResult(
    session: StudySession.fromJson(json['session']),
    totalXp: json['totalXp'],
    accuracy: json['accuracy'],
    achievements: (json['achievements'] as List).map((a) => Achievement.fromJson(a)).toList(),
    studyTime: Duration(milliseconds: json['studyTime']),
    ratingDistribution: Map<String, int>.from(json['ratingDistribution'] ?? {}),
    averageResponseTime: json['averageResponseTime'] ?? 0.0,
    streakCount: json['streakCount'] ?? 0,
  );
}

/// Gamification data for user progress and achievements
class GamificationData {
  final int totalXp;
  final int level;
  final int totalCardsReviewed;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStudyDate;
  final List<String> unlockedBadges;
  final Map<String, int> subjectXp;
  final int dailyXp;
  final int dailyCardsReviewed;
  final Map<String, dynamic> statistics;

  const GamificationData({
    required this.totalXp,
    required this.level,
    required this.totalCardsReviewed,
    required this.currentStreak,
    required this.longestStreak,
    this.lastStudyDate,
    this.unlockedBadges = const [],
    this.subjectXp = const {},
    this.dailyXp = 0,
    this.dailyCardsReviewed = 0,
    this.statistics = const {},
  });

  /// Calculate level from total XP (exponential growth)
  static int calculateLevel(int totalXp) {
    if (totalXp < 100) return 1;
    return (totalXp / 100).floor() + 1;
  }

  /// Get XP needed for next level
  int get xpForNextLevel => (level * 100) - totalXp;

  /// Get progress to next level (0.0 to 1.0)
  double get levelProgress {
    final currentLevelXp = (level - 1) * 100;
    final nextLevelXp = level * 100;
    final progressXp = totalXp - currentLevelXp;
    return progressXp / (nextLevelXp - currentLevelXp);
  }

  /// Get user rank based on level
  String get rank {
    if (level >= 50) return 'Master';
    if (level >= 30) return 'Expert';
    if (level >= 20) return 'Advanced';
    if (level >= 10) return 'Intermediate';
    return 'Beginner';
  }

  /// Check if user studied today
  bool get studiedToday {
    if (lastStudyDate == null) return false;
    final today = DateTime.now();
    return lastStudyDate!.day == today.day &&
           lastStudyDate!.month == today.month &&
           lastStudyDate!.year == today.year;
  }

  /// Get study streak status
  String get streakStatus {
    if (currentStreak == 0) return 'Start your streak!';
    if (currentStreak == 1) return 'Great start!';
    if (currentStreak < 7) return 'Building momentum!';
    if (currentStreak < 30) return 'On fire! 🔥';
    return 'Unstoppable! 🚀';
  }

  /// Factory constructor for initial data
  factory GamificationData.initial() => const GamificationData(
    totalXp: 0,
    level: 1,
    totalCardsReviewed: 0,
    currentStreak: 0,
    longestStreak: 0,
  );

  Map<String, dynamic> toJson() => {
    'totalXp': totalXp,
    'level': level,
    'totalCardsReviewed': totalCardsReviewed,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastStudyDate': lastStudyDate?.toIso8601String(),
    'unlockedBadges': unlockedBadges,
    'subjectXp': subjectXp,
    'dailyXp': dailyXp,
    'dailyCardsReviewed': dailyCardsReviewed,
    'statistics': statistics,
  };

  factory GamificationData.fromJson(Map<String, dynamic> json) => GamificationData(
    totalXp: json['totalXp'],
    level: json['level'],
    totalCardsReviewed: json['totalCardsReviewed'],
    currentStreak: json['currentStreak'],
    longestStreak: json['longestStreak'],
    lastStudyDate: json['lastStudyDate'] != null ? DateTime.parse(json['lastStudyDate']) : null,
    unlockedBadges: List<String>.from(json['unlockedBadges'] ?? []),
    subjectXp: Map<String, int>.from(json['subjectXp'] ?? {}),
    dailyXp: json['dailyXp'] ?? 0,
    dailyCardsReviewed: json['dailyCardsReviewed'] ?? 0,
    statistics: Map<String, dynamic>.from(json['statistics'] ?? {}),
  );

  GamificationData copyWith({
    int? totalXp,
    int? level,
    int? totalCardsReviewed,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastStudyDate,
    List<String>? unlockedBadges,
    Map<String, int>? subjectXp,
    int? dailyXp,
    int? dailyCardsReviewed,
    Map<String, dynamic>? statistics,
  }) => GamificationData(
    totalXp: totalXp ?? this.totalXp,
    level: level ?? GamificationData.calculateLevel(totalXp ?? this.totalXp),
    totalCardsReviewed: totalCardsReviewed ?? this.totalCardsReviewed,
    currentStreak: currentStreak ?? this.currentStreak,
    longestStreak: longestStreak ?? this.longestStreak,
    lastStudyDate: lastStudyDate ?? this.lastStudyDate,
    unlockedBadges: unlockedBadges ?? this.unlockedBadges,
    subjectXp: subjectXp ?? this.subjectXp,
    dailyXp: dailyXp ?? this.dailyXp,
    dailyCardsReviewed: dailyCardsReviewed ?? this.dailyCardsReviewed,
    statistics: statistics ?? this.statistics,
  );
}

/// Weekly/Monthly progress summary
class ProgressSummary {
  final DateTime startDate;
  final DateTime endDate;
  final int totalXpEarned;
  final int totalCardsReviewed;
  final double averageAccuracy;
  final int studyDays;
  final Duration totalStudyTime;
  final Map<String, int> subjectProgress;
  final List<Achievement> achievementsUnlocked;

  const ProgressSummary({
    required this.startDate,
    required this.endDate,
    required this.totalXpEarned,
    required this.totalCardsReviewed,
    required this.averageAccuracy,
    required this.studyDays,
    required this.totalStudyTime,
    this.subjectProgress = const {},
    this.achievementsUnlocked = const [],
  });

  /// Get average XP per day
  double get averageXpPerDay {
    final days = endDate.difference(startDate).inDays + 1;
    return days > 0 ? totalXpEarned / days : 0.0;
  }

  /// Get average cards per day
  double get averageCardsPerDay {
    final days = endDate.difference(startDate).inDays + 1;
    return days > 0 ? totalCardsReviewed / days : 0.0;
  }

  /// Get study consistency (percentage of days studied)
  double get studyConsistency {
    final totalDays = endDate.difference(startDate).inDays + 1;
    return totalDays > 0 ? studyDays / totalDays : 0.0;
  }

  Map<String, dynamic> toJson() => {
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'totalXpEarned': totalXpEarned,
    'totalCardsReviewed': totalCardsReviewed,
    'averageAccuracy': averageAccuracy,
    'studyDays': studyDays,
    'totalStudyTime': totalStudyTime.inMilliseconds,
    'subjectProgress': subjectProgress,
    'achievementsUnlocked': achievementsUnlocked.map((a) => a.toJson()).toList(),
  };

  factory ProgressSummary.fromJson(Map<String, dynamic> json) => ProgressSummary(
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    totalXpEarned: json['totalXpEarned'],
    totalCardsReviewed: json['totalCardsReviewed'],
    averageAccuracy: json['averageAccuracy'],
    studyDays: json['studyDays'],
    totalStudyTime: Duration(milliseconds: json['totalStudyTime']),
    subjectProgress: Map<String, int>.from(json['subjectProgress'] ?? {}),
    achievementsUnlocked: (json['achievementsUnlocked'] as List).map((a) => Achievement.fromJson(a)).toList(),
  );
}