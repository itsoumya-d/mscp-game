import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/question_pool.dart';
import 'question_pool_service.dart';

/// Enhanced progressive difficulty service with AI-driven scaling
/// Enhanced with dynamic difficulty adjustment - Category E Task E4
class ProgressiveDifficultyEnhancedService {
  static const String _difficultyProfileKey = 'difficulty_profile_v2';
  static const String _performanceHistoryKey = 'performance_history_v2';
  static const String _recentPerformanceKey = 'recent_performance_window_v1';
  static const String _challengeModeKey = 'challenge_mode_v1';

  DifficultyProfile? _difficultyProfile;

  /// Recent performance window (last 10-20 questions)
  final List<QuestionPerformance> _recentPerformanceWindow = [];
  static const int _performanceWindowSize = 20;

  /// Difficulty adjustment settings
  static const double _increaseThreshold = 0.85; // 85% accuracy
  static const int _increaseConsecutive = 5; // 5 consecutive correct
  static const double _decreaseThreshold = 0.50; // 50% accuracy
  static const int _decreaseConsecutive = 3; // 3 consecutive incorrect
  static const int _maxDifficultyChangePerSession = 2; // ±2 levels max
  static const int _cooldownQuestions = 5; // 5 questions between changes

  /// Difficulty adjustment state
  int _questionsSinceLastAdjustment = 0;
  int _sessionDifficultyChanges = 0;
  int _consecutiveCorrect = 0;
  int _consecutiveIncorrect = 0;

  /// Challenge mode state
  bool _challengeModeEnabled = false;
  int _userBaseLevel = 1;

  ProgressiveDifficultyEnhancedService();

  /// Initialize the service
  Future<void> initialize() async {
    await _loadDifficultyProfile();
    await _initializeDefaultProfile();
    await _loadRecentPerformanceWindow();
    await _loadChallengeMode();
  }

  /// Load difficulty profile from storage
  Future<void> _loadDifficultyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_difficultyProfileKey);
    
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString);
        _difficultyProfile = DifficultyProfile.fromJson(json);
      } catch (e) {
        _difficultyProfile = DifficultyProfile.createDefault();
      }
    } else {
      _difficultyProfile = DifficultyProfile.createDefault();
    }
  }

  /// Save difficulty profile to storage
  Future<void> _saveDifficultyProfile() async {
    if (_difficultyProfile == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_difficultyProfile!.toJson());
    await prefs.setString(_difficultyProfileKey, jsonString);
  }

  /// Initialize default difficulty profile
  Future<void> _initializeDefaultProfile() async {
    if (_difficultyProfile == null) {
      _difficultyProfile = DifficultyProfile.createDefault();
      await _saveDifficultyProfile();
    }
  }

  /// Load recent performance window from storage
  Future<void> _loadRecentPerformanceWindow() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_recentPerformanceKey);

    if (jsonString != null) {
      try {
        final decoded = jsonDecode(jsonString) as List;
        _recentPerformanceWindow.clear();
        _recentPerformanceWindow.addAll(
          decoded.map((item) => QuestionPerformance.fromJson(item as Map<String, dynamic>))
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[DifficultyService] Error loading performance window: $e');
        }
      }
    }
  }

  /// Save recent performance window to storage
  Future<void> _saveRecentPerformanceWindow() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(
      _recentPerformanceWindow.map((p) => p.toJson()).toList()
    );
    await prefs.setString(_recentPerformanceKey, jsonString);
  }

  /// Load challenge mode state
  Future<void> _loadChallengeMode() async {
    final prefs = await SharedPreferences.getInstance();
    _challengeModeEnabled = prefs.getBool(_challengeModeKey) ?? false;

    if (kDebugMode && _challengeModeEnabled) {
      debugPrint('[DifficultyService] Challenge mode enabled');
    }
  }

  /// Save challenge mode state
  Future<void> _saveChallengeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_challengeModeKey, _challengeModeEnabled);
  }

  /// Record question performance and adjust difficulty dynamically
  /// Category E Task E4: Dynamic Difficulty Adjustment
  Future<DifficultyAdjustment> recordQuestionPerformance({
    required SubjectType subject,
    required String skillId,
    required bool isCorrect,
    required Duration responseTime,
    required int currentDifficulty,
    required String questionType,
  }) async {
    // Create performance record
    final performance = QuestionPerformance(
      subject: subject,
      skillId: skillId,
      isCorrect: isCorrect,
      responseTime: responseTime,
      difficulty: currentDifficulty,
      questionType: questionType,
      timestamp: DateTime.now(),
    );

    // Add to rolling window
    _recentPerformanceWindow.add(performance);
    if (_recentPerformanceWindow.length > _performanceWindowSize) {
      _recentPerformanceWindow.removeAt(0);
    }

    // Save window
    await _saveRecentPerformanceWindow();

    // Update consecutive counters
    if (isCorrect) {
      _consecutiveCorrect++;
      _consecutiveIncorrect = 0;
    } else {
      _consecutiveIncorrect++;
      _consecutiveCorrect = 0;
    }

    _questionsSinceLastAdjustment++;

    // Check if we should adjust difficulty
    final adjustment = _calculateDifficultyAdjustment(
      subject: subject,
      skillId: skillId,
      currentDifficulty: currentDifficulty,
    );

    if (adjustment.shouldAdjust) {
      _questionsSinceLastAdjustment = 0;
      _sessionDifficultyChanges += adjustment.change.abs();

      if (kDebugMode) {
        debugPrint('[DifficultyService] 🎯 Difficulty adjusted: ${adjustment.change > 0 ? '+' : ''}${adjustment.change}');
        debugPrint('[DifficultyService] Reason: ${adjustment.reason}');
        debugPrint('[DifficultyService] New difficulty: ${adjustment.newDifficulty}');
      }
    }

    return adjustment;
  }

  /// Calculate difficulty adjustment based on recent performance
  DifficultyAdjustment _calculateDifficultyAdjustment({
    required SubjectType subject,
    required String skillId,
    required int currentDifficulty,
  }) {
    // Check cooldown period
    if (_questionsSinceLastAdjustment < _cooldownQuestions) {
      return DifficultyAdjustment(
        shouldAdjust: false,
        change: 0,
        newDifficulty: currentDifficulty,
        reason: 'Cooldown period (${_cooldownQuestions - _questionsSinceLastAdjustment} questions remaining)',
      );
    }

    // Check session change limit
    if (_sessionDifficultyChanges >= _maxDifficultyChangePerSession) {
      return DifficultyAdjustment(
        shouldAdjust: false,
        change: 0,
        newDifficulty: currentDifficulty,
        reason: 'Session change limit reached (±$_maxDifficultyChangePerSession max)',
      );
    }

    // Get recent performance metrics
    final recentQuestions = _recentPerformanceWindow
        .where((p) => p.subject == subject && p.skillId == skillId)
        .toList();

    if (recentQuestions.length < 5) {
      return DifficultyAdjustment(
        shouldAdjust: false,
        change: 0,
        newDifficulty: currentDifficulty,
        reason: 'Insufficient data (${recentQuestions.length}/5 questions)',
      );
    }

    // Calculate recent accuracy
    final recentAccuracy = recentQuestions
        .where((p) => p.isCorrect)
        .length / recentQuestions.length;

    // Calculate average response time
    final avgResponseTime = recentQuestions
        .map((p) => p.responseTime.inSeconds)
        .reduce((a, b) => a + b) / recentQuestions.length;

    // Expected time based on difficulty (10 seconds base + 5 seconds per difficulty level)
    final expectedTime = 10 + (currentDifficulty * 5);

    // Check for difficulty increase
    if (_consecutiveCorrect >= _increaseConsecutive &&
        recentAccuracy > _increaseThreshold &&
        avgResponseTime < expectedTime) {

      final newDifficulty = (currentDifficulty + 1).clamp(_userBaseLevel, 10);

      if (newDifficulty == currentDifficulty) {
        return DifficultyAdjustment(
          shouldAdjust: false,
          change: 0,
          newDifficulty: currentDifficulty,
          reason: 'Already at maximum difficulty',
        );
      }

      return DifficultyAdjustment(
        shouldAdjust: true,
        change: 1,
        newDifficulty: newDifficulty,
        reason: 'High accuracy (${(recentAccuracy * 100).toStringAsFixed(1)}%) and fast responses (${avgResponseTime.toStringAsFixed(1)}s < ${expectedTime}s)',
      );
    }

    // Check for difficulty decrease (not in challenge mode)
    if (!_challengeModeEnabled) {
      if (_consecutiveIncorrect >= _decreaseConsecutive ||
          (recentAccuracy < _decreaseThreshold && recentQuestions.length >= 5)) {

        final newDifficulty = (currentDifficulty - 1).clamp(_userBaseLevel, 10);

        if (newDifficulty == currentDifficulty) {
          return DifficultyAdjustment(
            shouldAdjust: false,
            change: 0,
            newDifficulty: currentDifficulty,
            reason: 'Already at minimum difficulty (user base level: $_userBaseLevel)',
          );
        }

        return DifficultyAdjustment(
          shouldAdjust: true,
          change: -1,
          newDifficulty: newDifficulty,
          reason: 'Low accuracy (${(recentAccuracy * 100).toStringAsFixed(1)}%) or slow responses',
        );
      }
    }

    // No adjustment needed
    return DifficultyAdjustment(
      shouldAdjust: false,
      change: 0,
      newDifficulty: currentDifficulty,
      reason: 'Performance stable (accuracy: ${(recentAccuracy * 100).toStringAsFixed(1)}%)',
    );
  }

  /// Get recent performance statistics
  PerformanceStatistics getRecentPerformanceStats({
    SubjectType? subject,
    String? skillId,
  }) {
    var questions = _recentPerformanceWindow.toList();

    if (subject != null) {
      questions = questions.where((p) => p.subject == subject).toList();
    }
    if (skillId != null) {
      questions = questions.where((p) => p.skillId == skillId).toList();
    }

    if (questions.isEmpty) {
      return PerformanceStatistics.empty();
    }

    final correctCount = questions.where((p) => p.isCorrect).length;
    final accuracy = correctCount / questions.length;

    final avgResponseTime = Duration(
      seconds: (questions.map((p) => p.responseTime.inSeconds).reduce((a, b) => a + b) / questions.length).round()
    );

    final avgDifficulty = questions.map((p) => p.difficulty).reduce((a, b) => a + b) / questions.length;

    // Analyze question types
    final typePerformance = <String, double>{};
    final typeGroups = <String, List<QuestionPerformance>>{};

    for (final q in questions) {
      typeGroups.putIfAbsent(q.questionType, () => []).add(q);
    }

    for (final entry in typeGroups.entries) {
      final typeCorrect = entry.value.where((p) => p.isCorrect).length;
      typePerformance[entry.key] = typeCorrect / entry.value.length;
    }

    return PerformanceStatistics(
      totalQuestions: questions.length,
      correctAnswers: correctCount,
      accuracy: accuracy,
      averageResponseTime: avgResponseTime,
      averageDifficulty: avgDifficulty,
      consecutiveCorrect: _consecutiveCorrect,
      consecutiveIncorrect: _consecutiveIncorrect,
      questionTypePerformance: typePerformance,
    );
  }

  /// Enable challenge mode
  Future<void> enableChallengeMode({required int userBaseLevel}) async {
    _challengeModeEnabled = true;
    _userBaseLevel = userBaseLevel;
    await _saveChallengeMode();

    if (kDebugMode) {
      debugPrint('[DifficultyService] 🔥 Challenge mode enabled! Base level: $userBaseLevel');
    }
  }

  /// Disable challenge mode
  Future<void> disableChallengeMode() async {
    _challengeModeEnabled = false;
    await _saveChallengeMode();

    if (kDebugMode) {
      debugPrint('[DifficultyService] Challenge mode disabled');
    }
  }

  /// Get challenge mode starting difficulty
  int getChallengeModeStartDifficulty(int userLevel) {
    return (userLevel + 2).clamp(1, 10);
  }

  /// Reset session state (call at start of new game session)
  void resetSessionState() {
    _sessionDifficultyChanges = 0;
    _questionsSinceLastAdjustment = 0;

    if (kDebugMode) {
      debugPrint('[DifficultyService] Session state reset');
    }
  }

  /// Clear recent performance window
  Future<void> clearPerformanceWindow() async {
    _recentPerformanceWindow.clear();
    _consecutiveCorrect = 0;
    _consecutiveIncorrect = 0;
    await _saveRecentPerformanceWindow();

    if (kDebugMode) {
      debugPrint('[DifficultyService] Performance window cleared');
    }
  }

  /// Calculate optimal difficulty for a subject and skill
  Future<DifficultyRecommendation> calculateOptimalDifficulty(
    SubjectType subject,
    String skillId,
    {QuestionCategory? preferredCategory}
  ) async {
    final profile = _difficultyProfile!;
    final subjectProfile = profile.subjectProfiles[subject] ?? SubjectDifficultyProfile.createDefault();
    final skillProfile = subjectProfile.skillProfiles[skillId] ?? SkillDifficultyProfile.createDefault();
    
    // Analyze recent performance
    final recentPerformance = await _analyzeRecentPerformance(subject, skillId, preferredCategory);
    
    // Calculate base difficulty using multiple factors
    double baseDifficulty = _calculateBaseDifficulty(skillProfile, recentPerformance);
    
    // Apply adaptive adjustments
    baseDifficulty = _applyAdaptiveAdjustments(baseDifficulty, recentPerformance, skillProfile);
    
    // Determine question categories based on difficulty and performance
    final recommendedCategories = _recommendQuestionCategories(
      baseDifficulty, 
      recentPerformance, 
      preferredCategory
    );
    
    // Calculate confidence level
    final confidence = _calculateConfidenceLevel(skillProfile, recentPerformance);
    
    return DifficultyRecommendation(
      difficulty: baseDifficulty.clamp(1.0, 5.0),
      categories: recommendedCategories,
      confidence: confidence,
      reasoning: _generateReasoningExplanation(baseDifficulty, recentPerformance, skillProfile),
      adaptiveFactors: _getAdaptiveFactors(recentPerformance, skillProfile),
    );
  }

  /// Analyze recent performance for a subject/skill combination
  Future<PerformanceAnalysis> _analyzeRecentPerformance(
    SubjectType subject,
    String skillId,
    QuestionCategory? category
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_performanceHistoryKey);
    
    List<PerformanceRecord> records = [];
    if (historyJson != null) {
      try {
        final decoded = jsonDecode(historyJson) as List;
        records = decoded
            .map((r) => PerformanceRecord.fromJson(r as Map<String, dynamic>))
            .where((r) => r.subject == subject && r.skillId == skillId)
            .toList();
      } catch (e) {
        records = [];
      }
    }
    
    // Filter recent records (last 20 attempts or 7 days)
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    final recentRecords = records
        .where((r) => r.timestamp.isAfter(cutoffDate))
        .take(20)
        .toList();
    
    if (recentRecords.isEmpty) {
      return PerformanceAnalysis.empty();
    }
    
    // Calculate performance metrics
    final accuracyScores = recentRecords.map((r) => r.accuracy).toList();
    final responseTimes = recentRecords.map((r) => r.averageResponseTime.inMilliseconds).toList();
    final difficulties = recentRecords.map((r) => r.difficulty).toList();
    
    final averageAccuracy = accuracyScores.reduce((a, b) => a + b) / accuracyScores.length;
    final averageResponseTime = Duration(
      milliseconds: (responseTimes.reduce((a, b) => a + b) / responseTimes.length).round()
    );
    final averageDifficulty = difficulties.reduce((a, b) => a + b) / difficulties.length;
    
    // Calculate trends
    final accuracyTrend = _calculateTrend(accuracyScores);
    final difficultyTrend = _calculateTrend(difficulties);
    
    // Analyze consistency
    final accuracyVariance = _calculateVariance(accuracyScores);
    final consistencyScore = 1.0 - (accuracyVariance / 0.25).clamp(0.0, 1.0);
    
    return PerformanceAnalysis(
      averageAccuracy: averageAccuracy,
      averageResponseTime: averageResponseTime,
      averageDifficulty: averageDifficulty,
      accuracyTrend: accuracyTrend,
      difficultyTrend: difficultyTrend,
      consistencyScore: consistencyScore,
      totalAttempts: recentRecords.length,
      categoryPerformance: _analyzeCategoryPerformance(recentRecords),
    );
  }

  /// Calculate base difficulty using multiple factors
  double _calculateBaseDifficulty(SkillDifficultyProfile skillProfile, PerformanceAnalysis performance) {
    double baseDifficulty = skillProfile.currentDifficulty;
    
    // Adjust based on recent accuracy
    if (performance.averageAccuracy > 0.85) {
      baseDifficulty += 0.3; // Increase difficulty if performing well
    } else if (performance.averageAccuracy < 0.6) {
      baseDifficulty -= 0.4; // Decrease difficulty if struggling
    }
    
    // Adjust based on consistency
    if (performance.consistencyScore > 0.8) {
      baseDifficulty += 0.2; // Increase if consistent
    } else if (performance.consistencyScore < 0.5) {
      baseDifficulty -= 0.2; // Decrease if inconsistent
    }
    
    // Adjust based on trends
    if (performance.accuracyTrend > 0.1) {
      baseDifficulty += 0.2; // Increase if improving
    } else if (performance.accuracyTrend < -0.1) {
      baseDifficulty -= 0.3; // Decrease if declining
    }
    
    return baseDifficulty;
  }

  /// Apply adaptive adjustments based on learning patterns
  double _applyAdaptiveAdjustments(
    double baseDifficulty, 
    PerformanceAnalysis performance, 
    SkillDifficultyProfile skillProfile
  ) {
    double adjustedDifficulty = baseDifficulty;
    
    // Time-based adjustments
    final avgResponseTime = performance.averageResponseTime.inSeconds;
    if (avgResponseTime < 10) {
      adjustedDifficulty += 0.1; // Quick responses suggest readiness for harder questions
    } else if (avgResponseTime > 30) {
      adjustedDifficulty -= 0.1; // Slow responses suggest need for easier questions
    }
    
    // Mastery level adjustments
    final masteryLevel = skillProfile.masteryLevel;
    if (masteryLevel > 0.9) {
      adjustedDifficulty += 0.2; // High mastery allows for harder questions
    } else if (masteryLevel < 0.3) {
      adjustedDifficulty -= 0.2; // Low mastery requires easier questions
    }
    
    // Confidence adjustments
    final confidenceLevel = skillProfile.confidenceLevel;
    if (confidenceLevel > 0.8 && performance.consistencyScore > 0.7) {
      adjustedDifficulty += 0.15; // High confidence + consistency = ready for challenge
    }
    
    return adjustedDifficulty;
  }

  /// Recommend question categories based on difficulty and performance
  List<QuestionCategory> _recommendQuestionCategories(
    double difficulty,
    PerformanceAnalysis performance,
    QuestionCategory? preferredCategory
  ) {
    final categories = <QuestionCategory>[];
    
    if (preferredCategory != null) {
      categories.add(preferredCategory);
    }
    
    // Base categories on difficulty level
    if (difficulty <= 2.0) {
      categories.addAll([
        QuestionCategory.factual,
        QuestionCategory.conceptual,
      ]);
    } else if (difficulty <= 3.0) {
      categories.addAll([
        QuestionCategory.computational,
        QuestionCategory.analytical,
      ]);
    } else if (difficulty <= 4.0) {
      categories.addAll([
        QuestionCategory.practical,
        QuestionCategory.comparative,
      ]);
    } else {
      categories.addAll([
        QuestionCategory.creative,
        QuestionCategory.analytical,
      ]);
    }
    
    // Adjust based on category performance
    final categoryPerformance = performance.categoryPerformance;
    final weakCategories = categoryPerformance.entries
        .where((e) => e.value < 0.6)
        .map((e) => QuestionCategory.values.firstWhere((c) => c.name == e.key))
        .toList();
    
    // Include weak categories for improvement
    if (weakCategories.isNotEmpty && categories.length < 4) {
      categories.addAll(weakCategories.take(4 - categories.length));
    }
    
    return categories.toSet().toList(); // Remove duplicates
  }

  /// Calculate confidence level for the recommendation
  double _calculateConfidenceLevel(SkillDifficultyProfile skillProfile, PerformanceAnalysis performance) {
    double confidence = 0.5; // Base confidence
    
    // Increase confidence with more data
    if (performance.totalAttempts >= 10) {
      confidence += 0.2;
    } else if (performance.totalAttempts >= 5) {
      confidence += 0.1;
    }
    
    // Increase confidence with consistency
    confidence += performance.consistencyScore * 0.3;
    
    // Increase confidence with stable mastery level
    if (skillProfile.masteryLevel > 0.5) {
      confidence += 0.2;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Generate reasoning explanation for the difficulty recommendation
  String _generateReasoningExplanation(
    double difficulty,
    PerformanceAnalysis performance,
    SkillDifficultyProfile skillProfile
  ) {
    final reasons = <String>[];
    
    if (performance.averageAccuracy > 0.85) {
      reasons.add('High accuracy (${(performance.averageAccuracy * 100).toStringAsFixed(1)}%) suggests readiness for increased difficulty');
    } else if (performance.averageAccuracy < 0.6) {
      reasons.add('Lower accuracy (${(performance.averageAccuracy * 100).toStringAsFixed(1)}%) indicates need for easier questions');
    }
    
    if (performance.consistencyScore > 0.8) {
      reasons.add('Consistent performance allows for stable difficulty progression');
    } else if (performance.consistencyScore < 0.5) {
      reasons.add('Inconsistent performance suggests need for difficulty stabilization');
    }
    
    if (performance.accuracyTrend > 0.1) {
      reasons.add('Improving trend supports difficulty increase');
    } else if (performance.accuracyTrend < -0.1) {
      reasons.add('Declining trend requires difficulty reduction');
    }
    
    if (reasons.isEmpty) {
      reasons.add('Maintaining current difficulty level based on stable performance');
    }
    
    return reasons.join('. ');
  }

  /// Get adaptive factors that influenced the recommendation
  Map<String, double> _getAdaptiveFactors(PerformanceAnalysis performance, SkillDifficultyProfile skillProfile) {
    return {
      'accuracy_factor': performance.averageAccuracy,
      'consistency_factor': performance.consistencyScore,
      'trend_factor': performance.accuracyTrend,
      'mastery_factor': skillProfile.masteryLevel,
      'confidence_factor': skillProfile.confidenceLevel,
      'response_time_factor': performance.averageResponseTime.inSeconds / 30.0, // Normalized to 30 seconds
    };
  }

  /// Record performance for future analysis
  Future<void> recordPerformance(PerformanceRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_performanceHistoryKey);
    
    List<Map<String, dynamic>> records = [];
    if (historyJson != null) {
      try {
        final decoded = jsonDecode(historyJson) as List;
        records = decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        records = [];
      }
    }
    
    records.add(record.toJson());
    
    // Keep only last 1000 records to prevent storage bloat
    if (records.length > 1000) {
      records = records.sublist(records.length - 1000);
    }
    
    final jsonString = jsonEncode(records);
    await prefs.setString(_performanceHistoryKey, jsonString);
    
    // Update difficulty profile
    await _updateDifficultyProfile(record);
  }

  /// Update difficulty profile based on performance
  Future<void> _updateDifficultyProfile(PerformanceRecord record) async {
    if (_difficultyProfile == null) return;
    
    final subjectProfile = _difficultyProfile!.subjectProfiles[record.subject] ?? 
        SubjectDifficultyProfile.createDefault();
    
    final skillProfile = subjectProfile.skillProfiles[record.skillId] ?? 
        SkillDifficultyProfile.createDefault();
    
    // Update skill profile
    final updatedSkillProfile = skillProfile.updateWithPerformance(record);
    final updatedSubjectProfile = subjectProfile.updateSkillProfile(record.skillId, updatedSkillProfile);
    
    _difficultyProfile = _difficultyProfile!.updateSubjectProfile(record.subject, updatedSubjectProfile);
    
    await _saveDifficultyProfile();
  }

  /// Calculate trend from a list of values
  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final firstHalf = values.take(values.length ~/ 2).toList();
    final secondHalf = values.skip(values.length ~/ 2).toList();
    
    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    
    return secondAvg - firstAvg;
  }

  /// Calculate variance of values
  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2)).toList();
    
    return squaredDiffs.reduce((a, b) => a + b) / squaredDiffs.length;
  }

  /// Analyze performance by category
  Map<String, double> _analyzeCategoryPerformance(List<PerformanceRecord> records) {
    final categoryPerformance = <String, List<double>>{};
    
    for (final record in records) {
      if (record.category != null) {
        final categoryName = record.category!.name;
        categoryPerformance.putIfAbsent(categoryName, () => []).add(record.accuracy);
      }
    }
    
    final result = <String, double>{};
    for (final entry in categoryPerformance.entries) {
      result[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
    }
    
    return result;
  }

  /// Get current difficulty profile
  DifficultyProfile? get difficultyProfile => _difficultyProfile;
}

/// Represents a difficulty recommendation
class DifficultyRecommendation {
  final double difficulty;
  final List<QuestionCategory> categories;
  final double confidence;
  final String reasoning;
  final Map<String, double> adaptiveFactors;

  const DifficultyRecommendation({
    required this.difficulty,
    required this.categories,
    required this.confidence,
    required this.reasoning,
    required this.adaptiveFactors,
  });
}

/// Represents performance analysis
class PerformanceAnalysis {
  final double averageAccuracy;
  final Duration averageResponseTime;
  final double averageDifficulty;
  final double accuracyTrend;
  final double difficultyTrend;
  final double consistencyScore;
  final int totalAttempts;
  final Map<String, double> categoryPerformance;

  const PerformanceAnalysis({
    required this.averageAccuracy,
    required this.averageResponseTime,
    required this.averageDifficulty,
    required this.accuracyTrend,
    required this.difficultyTrend,
    required this.consistencyScore,
    required this.totalAttempts,
    required this.categoryPerformance,
  });

  factory PerformanceAnalysis.empty() => const PerformanceAnalysis(
    averageAccuracy: 0.0,
    averageResponseTime: Duration.zero,
    averageDifficulty: 1.0,
    accuracyTrend: 0.0,
    difficultyTrend: 0.0,
    consistencyScore: 0.0,
    totalAttempts: 0,
    categoryPerformance: {},
  );
}

/// Represents a performance record
class PerformanceRecord {
  final SubjectType subject;
  final String skillId;
  final QuestionCategory? category;
  final double accuracy;
  final double difficulty;
  final Duration averageResponseTime;
  final DateTime timestamp;
  final int questionsAnswered;
  final int correctAnswers;

  const PerformanceRecord({
    required this.subject,
    required this.skillId,
    this.category,
    required this.accuracy,
    required this.difficulty,
    required this.averageResponseTime,
    required this.timestamp,
    required this.questionsAnswered,
    required this.correctAnswers,
  });

  Map<String, dynamic> toJson() => {
    'subject': subject.name,
    'skillId': skillId,
    'category': category?.name,
    'accuracy': accuracy,
    'difficulty': difficulty,
    'averageResponseTime': averageResponseTime.inMilliseconds,
    'timestamp': timestamp.toIso8601String(),
    'questionsAnswered': questionsAnswered,
    'correctAnswers': correctAnswers,
  };

  factory PerformanceRecord.fromJson(Map<String, dynamic> json) => PerformanceRecord(
    subject: SubjectType.values.firstWhere((s) => s.name == json['subject']),
    skillId: json['skillId'] as String,
    category: json['category'] != null 
        ? QuestionCategory.values.firstWhere((c) => c.name == json['category'])
        : null,
    accuracy: (json['accuracy'] as num).toDouble(),
    difficulty: (json['difficulty'] as num).toDouble(),
    averageResponseTime: Duration(milliseconds: json['averageResponseTime'] as int),
    timestamp: DateTime.parse(json['timestamp'] as String),
    questionsAnswered: json['questionsAnswered'] as int,
    correctAnswers: json['correctAnswers'] as int,
  );
}

/// Represents overall difficulty profile
class DifficultyProfile {
  final Map<SubjectType, SubjectDifficultyProfile> subjectProfiles;
  final DateTime lastUpdated;

  const DifficultyProfile({
    required this.subjectProfiles,
    required this.lastUpdated,
  });

  factory DifficultyProfile.createDefault() => DifficultyProfile(
    subjectProfiles: {},
    lastUpdated: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'subjectProfiles': subjectProfiles.map(
      (k, v) => MapEntry(k.name, v.toJson())
    ),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory DifficultyProfile.fromJson(Map<String, dynamic> json) => DifficultyProfile(
    subjectProfiles: (json['subjectProfiles'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(
        SubjectType.values.firstWhere((s) => s.name == k),
        SubjectDifficultyProfile.fromJson(v as Map<String, dynamic>)
      )
    ),
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  );

  DifficultyProfile updateSubjectProfile(SubjectType subject, SubjectDifficultyProfile profile) {
    final updatedProfiles = Map<SubjectType, SubjectDifficultyProfile>.from(subjectProfiles);
    updatedProfiles[subject] = profile;
    
    return DifficultyProfile(
      subjectProfiles: updatedProfiles,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Represents difficulty profile for a subject
class SubjectDifficultyProfile {
  final Map<String, SkillDifficultyProfile> skillProfiles;
  final double overallMastery;
  final DateTime lastUpdated;

  const SubjectDifficultyProfile({
    required this.skillProfiles,
    required this.overallMastery,
    required this.lastUpdated,
  });

  factory SubjectDifficultyProfile.createDefault() => SubjectDifficultyProfile(
    skillProfiles: {},
    overallMastery: 0.0,
    lastUpdated: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'skillProfiles': skillProfiles.map((k, v) => MapEntry(k, v.toJson())),
    'overallMastery': overallMastery,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory SubjectDifficultyProfile.fromJson(Map<String, dynamic> json) => SubjectDifficultyProfile(
    skillProfiles: (json['skillProfiles'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, SkillDifficultyProfile.fromJson(v as Map<String, dynamic>))
    ),
    overallMastery: (json['overallMastery'] as num).toDouble(),
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  );

  SubjectDifficultyProfile updateSkillProfile(String skillId, SkillDifficultyProfile profile) {
    final updatedProfiles = Map<String, SkillDifficultyProfile>.from(skillProfiles);
    updatedProfiles[skillId] = profile;
    
    // Recalculate overall mastery
    final masteryValues = updatedProfiles.values.map((p) => p.masteryLevel).toList();
    final newOverallMastery = masteryValues.isEmpty 
        ? 0.0 
        : masteryValues.reduce((a, b) => a + b) / masteryValues.length;
    
    return SubjectDifficultyProfile(
      skillProfiles: updatedProfiles,
      overallMastery: newOverallMastery,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Represents difficulty profile for a skill
class SkillDifficultyProfile {
  final double currentDifficulty;
  final double masteryLevel;
  final double confidenceLevel;
  final int totalAttempts;
  final DateTime lastUpdated;

  const SkillDifficultyProfile({
    required this.currentDifficulty,
    required this.masteryLevel,
    required this.confidenceLevel,
    required this.totalAttempts,
    required this.lastUpdated,
  });

  factory SkillDifficultyProfile.createDefault() => SkillDifficultyProfile(
    currentDifficulty: 1.0,
    masteryLevel: 0.0,
    confidenceLevel: 0.0,
    totalAttempts: 0,
    lastUpdated: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'currentDifficulty': currentDifficulty,
    'masteryLevel': masteryLevel,
    'confidenceLevel': confidenceLevel,
    'totalAttempts': totalAttempts,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory SkillDifficultyProfile.fromJson(Map<String, dynamic> json) => SkillDifficultyProfile(
    currentDifficulty: (json['currentDifficulty'] as num).toDouble(),
    masteryLevel: (json['masteryLevel'] as num).toDouble(),
    confidenceLevel: (json['confidenceLevel'] as num).toDouble(),
    totalAttempts: json['totalAttempts'] as int,
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  );

  SkillDifficultyProfile updateWithPerformance(PerformanceRecord record) {
    final newTotalAttempts = totalAttempts + 1;

    // Update mastery level (weighted average with more weight on recent performance)
    final masteryWeight = 0.3;
    final newMasteryLevel = (masteryLevel * (1 - masteryWeight)) + (record.accuracy * masteryWeight);

    // Update confidence level based on consistency
    final confidenceWeight = 0.2;
    final performanceConfidence = record.accuracy > 0.7 ? record.accuracy : record.accuracy * 0.5;
    final newConfidenceLevel = (confidenceLevel * (1 - confidenceWeight)) + (performanceConfidence * confidenceWeight);

    // Update difficulty based on performance
    double newDifficulty = currentDifficulty;
    if (record.accuracy > 0.85) {
      newDifficulty += 0.1;
    } else if (record.accuracy < 0.6) {
      newDifficulty -= 0.15;
    }
    newDifficulty = newDifficulty.clamp(1.0, 5.0);

    return SkillDifficultyProfile(
      currentDifficulty: newDifficulty,
      masteryLevel: newMasteryLevel.clamp(0.0, 1.0),
      confidenceLevel: newConfidenceLevel.clamp(0.0, 1.0),
      totalAttempts: newTotalAttempts,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Question performance record for rolling window
/// Category E Task E4: Dynamic Difficulty Adjustment
class QuestionPerformance {
  final SubjectType subject;
  final String skillId;
  final bool isCorrect;
  final Duration responseTime;
  final int difficulty;
  final String questionType;
  final DateTime timestamp;

  const QuestionPerformance({
    required this.subject,
    required this.skillId,
    required this.isCorrect,
    required this.responseTime,
    required this.difficulty,
    required this.questionType,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'subject': subject.name,
    'skillId': skillId,
    'isCorrect': isCorrect,
    'responseTime': responseTime.inMilliseconds,
    'difficulty': difficulty,
    'questionType': questionType,
    'timestamp': timestamp.toIso8601String(),
  };

  factory QuestionPerformance.fromJson(Map<String, dynamic> json) => QuestionPerformance(
    subject: SubjectType.values.firstWhere((s) => s.name == json['subject']),
    skillId: json['skillId'] as String,
    isCorrect: json['isCorrect'] as bool,
    responseTime: Duration(milliseconds: json['responseTime'] as int),
    difficulty: json['difficulty'] as int,
    questionType: json['questionType'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

/// Difficulty adjustment result
class DifficultyAdjustment {
  final bool shouldAdjust;
  final int change; // -1, 0, or +1
  final int newDifficulty;
  final String reason;

  const DifficultyAdjustment({
    required this.shouldAdjust,
    required this.change,
    required this.newDifficulty,
    required this.reason,
  });
}

/// Performance statistics for recent window
class PerformanceStatistics {
  final int totalQuestions;
  final int correctAnswers;
  final double accuracy;
  final Duration averageResponseTime;
  final double averageDifficulty;
  final int consecutiveCorrect;
  final int consecutiveIncorrect;
  final Map<String, double> questionTypePerformance;

  const PerformanceStatistics({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracy,
    required this.averageResponseTime,
    required this.averageDifficulty,
    required this.consecutiveCorrect,
    required this.consecutiveIncorrect,
    required this.questionTypePerformance,
  });

  factory PerformanceStatistics.empty() => const PerformanceStatistics(
    totalQuestions: 0,
    correctAnswers: 0,
    accuracy: 0.0,
    averageResponseTime: Duration.zero,
    averageDifficulty: 1.0,
    consecutiveCorrect: 0,
    consecutiveIncorrect: 0,
    questionTypePerformance: {},
  );
}