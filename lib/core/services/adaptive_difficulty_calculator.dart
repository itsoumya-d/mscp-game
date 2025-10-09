import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Calculates adaptive difficulty levels based on user performance and learning patterns
/// Provides intelligent difficulty adjustment for 50,000 educational levels
class AdaptiveDifficultyCalculator {
  static AdaptiveDifficultyCalculator? _instance;
  static AdaptiveDifficultyCalculator get instance => _instance ??= AdaptiveDifficultyCalculator._();
  
  AdaptiveDifficultyCalculator._();

  // Difficulty calculation parameters
  static const double _baselineDifficulty = 0.5;
  static const double _maxDifficultyChange = 0.3;
  static const double _performanceWeight = 0.4;
  static const double _consistencyWeight = 0.3;
  static const double _velocityWeight = 0.2;
  static const double _engagementWeight = 0.1;
  
  // Performance thresholds
  static const double _excellentThreshold = 0.9;
  static const double _goodThreshold = 0.75;
  static const double _strugglingThreshold = 0.5;
  
  // Cache for user performance data
  final Map<String, UserPerformanceProfile> _performanceCache = {};
  
  /// Initializes the adaptive difficulty calculator
  Future<void> initialize() async {
    await _loadPerformanceProfiles();
  }

  /// Calculates the optimal difficulty for a user at a specific level
  Future<DifficultyRecommendation> calculateOptimalDifficulty(
    String userId, 
    int levelId, 
    String subject,
    {double? currentDifficulty}
  ) async {
    final profile = await _getUserPerformanceProfile(userId);
    final subjectProfile = profile.getSubjectProfile(subject);
    
    // Calculate base difficulty from user's overall performance
    final baseDifficulty = _calculateBaseDifficulty(subjectProfile);
    
    // Apply contextual adjustments
    final contextualDifficulty = _applyContextualAdjustments(
      baseDifficulty, 
      subjectProfile, 
      levelId
    );
    
    // Apply learning curve adjustments
    final adaptedDifficulty = _applyLearningCurveAdjustments(
      contextualDifficulty, 
      subjectProfile, 
      currentDifficulty
    );
    
    // Ensure difficulty is within reasonable bounds
    final finalDifficulty = _clampDifficulty(adaptedDifficulty);
    
    // Calculate confidence in this recommendation
    final confidence = _calculateRecommendationConfidence(subjectProfile);
    
    return DifficultyRecommendation(
      userId: userId,
      levelId: levelId,
      subject: subject,
      recommendedDifficulty: finalDifficulty,
      currentDifficulty: currentDifficulty ?? _baselineDifficulty,
      confidence: confidence,
      reasoning: _generateReasoning(subjectProfile, finalDifficulty, currentDifficulty),
      adjustmentFactors: _getAdjustmentFactors(subjectProfile),
      calculatedAt: DateTime.now(),
    );
  }

  /// Calculates base difficulty from user's performance profile
  double _calculateBaseDifficulty(SubjectPerformanceProfile profile) {
    final performance = profile.averageAccuracy * _performanceWeight;
    final consistency = profile.consistencyScore * _consistencyWeight;
    final velocity = profile.learningVelocity * _velocityWeight;
    final engagement = profile.engagementScore * _engagementWeight;
    
    final weightedScore = performance + consistency + velocity + engagement;
    
    // Convert weighted score to difficulty level (0.1 to 1.0)
    return 0.1 + (weightedScore * 0.9);
  }

  /// Applies contextual adjustments based on recent performance and patterns
  double _applyContextualAdjustments(
    double baseDifficulty, 
    SubjectPerformanceProfile profile, 
    int levelId
  ) {
    double adjustedDifficulty = baseDifficulty;
    
    // Recent performance trend adjustment
    if (profile.recentTrend > 0.1) {
      // Improving performance - can handle slightly higher difficulty
      adjustedDifficulty += 0.05;
    } else if (profile.recentTrend < -0.1) {
      // Declining performance - reduce difficulty
      adjustedDifficulty -= 0.1;
    }
    
    // Streak adjustment
    if (profile.currentStreak >= 5) {
      // Good streak - can handle higher difficulty
      adjustedDifficulty += min(0.1, profile.currentStreak * 0.01);
    } else if (profile.currentStreak <= -3) {
      // Struggling streak - reduce difficulty
      adjustedDifficulty -= min(0.15, profile.currentStreak.abs() * 0.02);
    }
    
    // Time of day adjustment (if user performs better at certain times)
    final timeAdjustment = _calculateTimeOfDayAdjustment(profile);
    adjustedDifficulty += timeAdjustment;
    
    // Fatigue adjustment based on session length
    final fatigueAdjustment = _calculateFatigueAdjustment(profile);
    adjustedDifficulty += fatigueAdjustment;
    
    return adjustedDifficulty;
  }

  /// Applies learning curve adjustments for smooth progression
  double _applyLearningCurveAdjustments(
    double contextualDifficulty, 
    SubjectPerformanceProfile profile, 
    double? currentDifficulty
  ) {
    if (currentDifficulty == null) {
      return contextualDifficulty;
    }
    
    final difficultyChange = contextualDifficulty - currentDifficulty;
    
    // Limit sudden difficulty changes
    final maxChange = _calculateMaxAllowedChange(profile);
    final clampedChange = difficultyChange.clamp(-maxChange, maxChange);
    
    return currentDifficulty + clampedChange;
  }

  /// Calculates maximum allowed difficulty change based on user stability
  double _calculateMaxAllowedChange(SubjectPerformanceProfile profile) {
    // More stable users can handle larger changes
    final stabilityFactor = profile.consistencyScore;
    return _maxDifficultyChange * stabilityFactor;
  }

  /// Calculates time of day performance adjustment
  double _calculateTimeOfDayAdjustment(SubjectPerformanceProfile profile) {
    final currentHour = DateTime.now().hour;
    final timePerformance = profile.timeOfDayPerformance;
    
    if (timePerformance.isEmpty) return 0.0;
    
    final currentPerformance = timePerformance[currentHour] ?? profile.averageAccuracy;
    final performanceDiff = currentPerformance - profile.averageAccuracy;
    
    // Convert performance difference to difficulty adjustment
    return performanceDiff * 0.2; // Scale factor
  }

  /// Calculates fatigue adjustment based on session activity
  double _calculateFatigueAdjustment(SubjectPerformanceProfile profile) {
    final sessionMinutes = profile.currentSessionMinutes;
    
    if (sessionMinutes < 15) {
      return 0.0; // No adjustment for short sessions
    } else if (sessionMinutes < 45) {
      return 0.02; // Slight boost for warmed-up state
    } else if (sessionMinutes < 90) {
      return 0.0; // Neutral for normal sessions
    } else {
      // Reduce difficulty for long sessions due to fatigue
      return -min(0.1, (sessionMinutes - 90) * 0.001);
    }
  }

  /// Clamps difficulty to reasonable bounds
  double _clampDifficulty(double difficulty) {
    return difficulty.clamp(0.1, 1.0);
  }

  /// Calculates confidence in the difficulty recommendation
  double _calculateRecommendationConfidence(SubjectPerformanceProfile profile) {
    // Confidence based on data quality and consistency
    final dataQuality = min(1.0, profile.totalAttempts / 20.0); // More data = higher confidence
    final consistency = profile.consistencyScore;
    final recency = _calculateDataRecency(profile);
    
    return (dataQuality * 0.4 + consistency * 0.4 + recency * 0.2).clamp(0.0, 1.0);
  }

  /// Calculates how recent the performance data is
  double _calculateDataRecency(SubjectPerformanceProfile profile) {
    final daysSinceLastActivity = DateTime.now().difference(profile.lastActivity).inDays;
    
    if (daysSinceLastActivity <= 1) return 1.0;
    if (daysSinceLastActivity <= 3) return 0.8;
    if (daysSinceLastActivity <= 7) return 0.6;
    if (daysSinceLastActivity <= 14) return 0.4;
    return 0.2;
  }

  /// Generates human-readable reasoning for the difficulty recommendation
  String _generateReasoning(
    SubjectPerformanceProfile profile, 
    double recommendedDifficulty, 
    double? currentDifficulty
  ) {
    final reasons = <String>[];
    
    // Performance-based reasoning
    if (profile.averageAccuracy >= _excellentThreshold) {
      reasons.add('Excellent performance (${(profile.averageAccuracy * 100).toInt()}% accuracy)');
    } else if (profile.averageAccuracy >= _goodThreshold) {
      reasons.add('Good performance (${(profile.averageAccuracy * 100).toInt()}% accuracy)');
    } else if (profile.averageAccuracy >= _strugglingThreshold) {
      reasons.add('Moderate performance (${(profile.averageAccuracy * 100).toInt()}% accuracy)');
    } else {
      reasons.add('Needs support (${(profile.averageAccuracy * 100).toInt()}% accuracy)');
    }
    
    // Trend-based reasoning
    if (profile.recentTrend > 0.1) {
      reasons.add('improving trend');
    } else if (profile.recentTrend < -0.1) {
      reasons.add('declining trend');
    }
    
    // Streak-based reasoning
    if (profile.currentStreak >= 5) {
      reasons.add('${profile.currentStreak}-level success streak');
    } else if (profile.currentStreak <= -3) {
      reasons.add('${profile.currentStreak.abs()}-level struggle streak');
    }
    
    // Consistency reasoning
    if (profile.consistencyScore >= 0.8) {
      reasons.add('high consistency');
    } else if (profile.consistencyScore <= 0.5) {
      reasons.add('variable performance');
    }
    
    final change = currentDifficulty != null ? 
        recommendedDifficulty - currentDifficulty : 0.0;
    
    String changeDescription = '';
    if (change.abs() > 0.05) {
      if (change > 0) {
        changeDescription = ' → Increasing difficulty by ${(change * 100).toInt()}%';
      } else {
        changeDescription = ' → Decreasing difficulty by ${(change.abs() * 100).toInt()}%';
      }
    } else {
      changeDescription = ' → Maintaining current difficulty level';
    }
    
    return '${reasons.join(', ')}$changeDescription';
  }

  /// Gets adjustment factors that influenced the difficulty calculation
  Map<String, double> _getAdjustmentFactors(SubjectPerformanceProfile profile) {
    return {
      'performance': profile.averageAccuracy * _performanceWeight,
      'consistency': profile.consistencyScore * _consistencyWeight,
      'velocity': profile.learningVelocity * _velocityWeight,
      'engagement': profile.engagementScore * _engagementWeight,
      'trend': profile.recentTrend,
      'streak': profile.currentStreak.toDouble(),
    };
  }

  /// Updates user performance data after completing a level
  Future<void> updatePerformanceData(
    String userId, 
    String subject, 
    LevelPerformanceData performance
  ) async {
    final profile = await _getUserPerformanceProfile(userId);
    final subjectProfile = profile.getSubjectProfile(subject);
    
    // Update subject-specific performance
    subjectProfile.addPerformanceData(performance);
    
    // Update overall profile
    profile.updateOverallStats();
    
    // Cache the updated profile
    _performanceCache[userId] = profile;
    
    // Save to persistent storage
    await _savePerformanceProfile(userId, profile);
  }

  /// Gets user performance profile from cache or storage
  Future<UserPerformanceProfile> _getUserPerformanceProfile(String userId) async {
    if (_performanceCache.containsKey(userId)) {
      return _performanceCache[userId]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('performance_profile_$userId');
    
    UserPerformanceProfile profile;
    if (profileJson != null) {
      try {
        profile = UserPerformanceProfile.fromJson(json.decode(profileJson));
      } catch (e) {
        print('Error loading performance profile: $e');
        profile = UserPerformanceProfile(userId: userId);
      }
    } else {
      profile = UserPerformanceProfile(userId: userId);
    }

    _performanceCache[userId] = profile;
    return profile;
  }

  /// Saves performance profile to persistent storage
  Future<void> _savePerformanceProfile(String userId, UserPerformanceProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('performance_profile_$userId', json.encode(profile.toJson()));
  }

  /// Loads performance profiles from storage
  Future<void> _loadPerformanceProfiles() async {
    // Implementation would load frequently accessed profiles
    // For now, profiles are loaded on-demand
  }

  /// Gets difficulty statistics for a user
  Future<Map<String, dynamic>> getDifficultyStats(String userId) async {
    final profile = await _getUserPerformanceProfile(userId);
    
    return {
      'overallAccuracy': profile.overallAccuracy,
      'subjectCount': profile.subjectProfiles.length,
      'totalAttempts': profile.totalAttempts,
      'averageDifficulty': profile.averageDifficulty,
      'consistencyScore': profile.consistencyScore,
      'learningVelocity': profile.learningVelocity,
      'lastActivity': profile.lastActivity.toIso8601String(),
      'subjectBreakdown': profile.subjectProfiles.map(
        (subject, subjectProfile) => MapEntry(subject, {
          'accuracy': subjectProfile.averageAccuracy,
          'attempts': subjectProfile.totalAttempts,
          'trend': subjectProfile.recentTrend,
          'streak': subjectProfile.currentStreak,
        })
      ),
    };
  }

  /// Clears all cached performance data
  void clearCache() {
    _performanceCache.clear();
  }
}

/// Represents a difficulty recommendation for a specific level
class DifficultyRecommendation {
  final String userId;
  final int levelId;
  final String subject;
  final double recommendedDifficulty;
  final double currentDifficulty;
  final double confidence;
  final String reasoning;
  final Map<String, double> adjustmentFactors;
  final DateTime calculatedAt;

  DifficultyRecommendation({
    required this.userId,
    required this.levelId,
    required this.subject,
    required this.recommendedDifficulty,
    required this.currentDifficulty,
    required this.confidence,
    required this.reasoning,
    required this.adjustmentFactors,
    required this.calculatedAt,
  });

  double get difficultyChange => recommendedDifficulty - currentDifficulty;
  
  bool get shouldIncreaseDifficulty => difficultyChange > 0.05;
  bool get shouldDecreaseDifficulty => difficultyChange < -0.05;
  bool get shouldMaintainDifficulty => difficultyChange.abs() <= 0.05;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'levelId': levelId,
    'subject': subject,
    'recommendedDifficulty': recommendedDifficulty,
    'currentDifficulty': currentDifficulty,
    'confidence': confidence,
    'reasoning': reasoning,
    'adjustmentFactors': adjustmentFactors,
    'calculatedAt': calculatedAt.toIso8601String(),
  };

  factory DifficultyRecommendation.fromJson(Map<String, dynamic> json) => DifficultyRecommendation(
    userId: json['userId'],
    levelId: json['levelId'],
    subject: json['subject'],
    recommendedDifficulty: json['recommendedDifficulty'],
    currentDifficulty: json['currentDifficulty'],
    confidence: json['confidence'],
    reasoning: json['reasoning'],
    adjustmentFactors: Map<String, double>.from(json['adjustmentFactors']),
    calculatedAt: DateTime.parse(json['calculatedAt']),
  );
}

/// Represents performance data for a single level attempt
class LevelPerformanceData {
  final int levelId;
  final String subject;
  final double accuracy;
  final int timeSpentSeconds;
  final int attempts;
  final double difficulty;
  final DateTime completedAt;
  final Map<String, dynamic> metadata;

  LevelPerformanceData({
    required this.levelId,
    required this.subject,
    required this.accuracy,
    required this.timeSpentSeconds,
    required this.attempts,
    required this.difficulty,
    required this.completedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'levelId': levelId,
    'subject': subject,
    'accuracy': accuracy,
    'timeSpentSeconds': timeSpentSeconds,
    'attempts': attempts,
    'difficulty': difficulty,
    'completedAt': completedAt.toIso8601String(),
    'metadata': metadata,
  };

  factory LevelPerformanceData.fromJson(Map<String, dynamic> json) => LevelPerformanceData(
    levelId: json['levelId'],
    subject: json['subject'],
    accuracy: json['accuracy'],
    timeSpentSeconds: json['timeSpentSeconds'],
    attempts: json['attempts'],
    difficulty: json['difficulty'],
    completedAt: DateTime.parse(json['completedAt']),
    metadata: json['metadata'] ?? {},
  );
}

/// Represents a user's overall performance profile
class UserPerformanceProfile {
  final String userId;
  final Map<String, SubjectPerformanceProfile> subjectProfiles;
  double overallAccuracy;
  int totalAttempts;
  double averageDifficulty;
  double consistencyScore;
  double learningVelocity;
  DateTime lastActivity;

  UserPerformanceProfile({
    required this.userId,
    Map<String, SubjectPerformanceProfile>? subjectProfiles,
    this.overallAccuracy = 0.0,
    this.totalAttempts = 0,
    this.averageDifficulty = 0.5,
    this.consistencyScore = 0.0,
    this.learningVelocity = 0.0,
    DateTime? lastActivity,
  }) : subjectProfiles = subjectProfiles ?? {},
       lastActivity = lastActivity ?? DateTime.now();

  SubjectPerformanceProfile getSubjectProfile(String subject) {
    return subjectProfiles.putIfAbsent(
      subject, 
      () => SubjectPerformanceProfile(subject: subject)
    );
  }

  void updateOverallStats() {
    if (subjectProfiles.isEmpty) return;

    final profiles = subjectProfiles.values.toList();
    overallAccuracy = profiles.map((p) => p.averageAccuracy).reduce((a, b) => a + b) / profiles.length;
    totalAttempts = profiles.map((p) => p.totalAttempts).reduce((a, b) => a + b);
    averageDifficulty = profiles.map((p) => p.averageDifficulty).reduce((a, b) => a + b) / profiles.length;
    consistencyScore = profiles.map((p) => p.consistencyScore).reduce((a, b) => a + b) / profiles.length;
    learningVelocity = profiles.map((p) => p.learningVelocity).reduce((a, b) => a + b) / profiles.length;
    lastActivity = profiles.map((p) => p.lastActivity).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'subjectProfiles': subjectProfiles.map((k, v) => MapEntry(k, v.toJson())),
    'overallAccuracy': overallAccuracy,
    'totalAttempts': totalAttempts,
    'averageDifficulty': averageDifficulty,
    'consistencyScore': consistencyScore,
    'learningVelocity': learningVelocity,
    'lastActivity': lastActivity.toIso8601String(),
  };

  factory UserPerformanceProfile.fromJson(Map<String, dynamic> json) => UserPerformanceProfile(
    userId: json['userId'],
    subjectProfiles: (json['subjectProfiles'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, SubjectPerformanceProfile.fromJson(v))
    ),
    overallAccuracy: json['overallAccuracy'] ?? 0.0,
    totalAttempts: json['totalAttempts'] ?? 0,
    averageDifficulty: json['averageDifficulty'] ?? 0.5,
    consistencyScore: json['consistencyScore'] ?? 0.0,
    learningVelocity: json['learningVelocity'] ?? 0.0,
    lastActivity: DateTime.parse(json['lastActivity']),
  );
}

/// Represents performance profile for a specific subject
class SubjectPerformanceProfile {
  final String subject;
  final List<LevelPerformanceData> recentPerformances;
  double averageAccuracy;
  int totalAttempts;
  double averageDifficulty;
  double consistencyScore;
  double learningVelocity;
  double recentTrend;
  int currentStreak;
  double engagementScore;
  int currentSessionMinutes;
  Map<int, double> timeOfDayPerformance;
  DateTime lastActivity;

  SubjectPerformanceProfile({
    required this.subject,
    List<LevelPerformanceData>? recentPerformances,
    this.averageAccuracy = 0.0,
    this.totalAttempts = 0,
    this.averageDifficulty = 0.5,
    this.consistencyScore = 0.0,
    this.learningVelocity = 0.0,
    this.recentTrend = 0.0,
    this.currentStreak = 0,
    this.engagementScore = 0.0,
    this.currentSessionMinutes = 0,
    Map<int, double>? timeOfDayPerformance,
    DateTime? lastActivity,
  }) : recentPerformances = recentPerformances ?? [],
       timeOfDayPerformance = timeOfDayPerformance ?? {},
       lastActivity = lastActivity ?? DateTime.now();

  void addPerformanceData(LevelPerformanceData performance) {
    recentPerformances.add(performance);
    
    // Keep only last 50 performances
    if (recentPerformances.length > 50) {
      recentPerformances.removeAt(0);
    }
    
    _recalculateStats();
    lastActivity = performance.completedAt;
  }

  void _recalculateStats() {
    if (recentPerformances.isEmpty) return;

    // Calculate average accuracy
    averageAccuracy = recentPerformances
        .map((p) => p.accuracy)
        .reduce((a, b) => a + b) / recentPerformances.length;

    // Calculate total attempts
    totalAttempts = recentPerformances.length;

    // Calculate average difficulty
    averageDifficulty = recentPerformances
        .map((p) => p.difficulty)
        .reduce((a, b) => a + b) / recentPerformances.length;

    // Calculate consistency (inverse of standard deviation)
    final accuracies = recentPerformances.map((p) => p.accuracy).toList();
    final variance = _calculateVariance(accuracies);
    consistencyScore = 1.0 / (1.0 + variance);

    // Calculate learning velocity (improvement over time)
    learningVelocity = _calculateLearningVelocity();

    // Calculate recent trend
    recentTrend = _calculateRecentTrend();

    // Calculate current streak
    currentStreak = _calculateCurrentStreak();

    // Calculate engagement score
    engagementScore = _calculateEngagementScore();

    // Update time of day performance
    _updateTimeOfDayPerformance();
  }

  double _calculateVariance(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2)).toList();
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  double _calculateLearningVelocity() {
    if (recentPerformances.length < 5) return 0.0;
    
    final recent = recentPerformances.skip(max(0, recentPerformances.length - 5)).map((p) => p.accuracy).toList();
    final older = recentPerformances.length >= 10 
        ? recentPerformances.skip(recentPerformances.length - 10).take(5).map((p) => p.accuracy).toList()
        : recentPerformances.take(5).map((p) => p.accuracy).toList();
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    
    return recentAvg - olderAvg;
  }

  double _calculateRecentTrend() {
    if (recentPerformances.length < 3) return 0.0;
    
    final recent = recentPerformances.skip(max(0, recentPerformances.length - min(10, recentPerformances.length))).toList();
    final accuracies = recent.map((p) => p.accuracy).toList();
    
    // Simple linear regression slope
    final n = accuracies.length;
    final sumX = n * (n - 1) / 2;
    final sumY = accuracies.reduce((a, b) => a + b);
    final sumXY = accuracies.asMap().entries.fold(0.0, (sum, entry) => sum + entry.key * entry.value);
    final sumX2 = n * (n - 1) * (2 * n - 1) / 6;
    
    return (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
  }

  int _calculateCurrentStreak() {
    if (recentPerformances.isEmpty) return 0;
    
    int streak = 0;
    final threshold = 0.7; // 70% accuracy threshold for success
    
    for (int i = recentPerformances.length - 1; i >= 0; i--) {
      if (recentPerformances[i].accuracy >= threshold) {
        streak++;
      } else {
        break;
      }
    }
    
    // Check for negative streak (failures)
    if (streak == 0) {
      for (int i = recentPerformances.length - 1; i >= 0; i--) {
        if (recentPerformances[i].accuracy < threshold) {
          streak--;
        } else {
          break;
        }
      }
    }
    
    return streak;
  }

  double _calculateEngagementScore() {
    if (recentPerformances.isEmpty) return 0.0;
    
    // Engagement based on session frequency and duration
    final now = DateTime.now();
    final recentSessions = recentPerformances
        .where((p) => now.difference(p.completedAt).inDays <= 7)
        .length;
    
    final averageTimePerLevel = recentPerformances
        .map((p) => p.timeSpentSeconds)
        .reduce((a, b) => a + b) / recentPerformances.length;
    
    // Normalize to 0-1 scale
    final frequencyScore = min(1.0, recentSessions / 10.0); // 10 sessions per week = max
    final timeScore = min(1.0, averageTimePerLevel / 300.0); // 5 minutes = optimal
    
    return (frequencyScore + timeScore) / 2;
  }

  void _updateTimeOfDayPerformance() {
    final hourlyPerformance = <int, List<double>>{};
    
    for (final performance in recentPerformances) {
      final hour = performance.completedAt.hour;
      hourlyPerformance.putIfAbsent(hour, () => []).add(performance.accuracy);
    }
    
    timeOfDayPerformance = hourlyPerformance.map(
      (hour, accuracies) => MapEntry(
        hour, 
        accuracies.reduce((a, b) => a + b) / accuracies.length
      )
    );
  }

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'recentPerformances': recentPerformances.map((p) => p.toJson()).toList(),
    'averageAccuracy': averageAccuracy,
    'totalAttempts': totalAttempts,
    'averageDifficulty': averageDifficulty,
    'consistencyScore': consistencyScore,
    'learningVelocity': learningVelocity,
    'recentTrend': recentTrend,
    'currentStreak': currentStreak,
    'engagementScore': engagementScore,
    'currentSessionMinutes': currentSessionMinutes,
    'timeOfDayPerformance': timeOfDayPerformance,
    'lastActivity': lastActivity.toIso8601String(),
  };

  factory SubjectPerformanceProfile.fromJson(Map<String, dynamic> json) => SubjectPerformanceProfile(
    subject: json['subject'],
    recentPerformances: (json['recentPerformances'] as List)
        .map((p) => LevelPerformanceData.fromJson(p))
        .toList(),
    averageAccuracy: json['averageAccuracy'] ?? 0.0,
    totalAttempts: json['totalAttempts'] ?? 0,
    averageDifficulty: json['averageDifficulty'] ?? 0.5,
    consistencyScore: json['consistencyScore'] ?? 0.0,
    learningVelocity: json['learningVelocity'] ?? 0.0,
    recentTrend: json['recentTrend'] ?? 0.0,
    currentStreak: json['currentStreak'] ?? 0,
    engagementScore: json['engagementScore'] ?? 0.0,
    currentSessionMinutes: json['currentSessionMinutes'] ?? 0,
    timeOfDayPerformance: Map<int, double>.from(json['timeOfDayPerformance'] ?? {}),
    lastActivity: DateTime.parse(json['lastActivity']),
  );
}