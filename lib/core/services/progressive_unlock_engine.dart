import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/skill_node.dart';
import '../models/unlock_condition.dart';
import '../models/learning_path.dart';
import 'skill_dependency_manager.dart';

/// Core engine for evaluating unlock conditions and making unlock decisions
/// Handles progressive unlocking for 50,000 educational levels with intelligent evaluation
class ProgressiveUnlockEngine {
  static ProgressiveUnlockEngine? _instance;
  static ProgressiveUnlockEngine get instance => _instance ??= ProgressiveUnlockEngine._();
  
  ProgressiveUnlockEngine._();

  final SkillDependencyManager _skillManager = SkillDependencyManager.instance;
  
  // Cache for user data and evaluations
  final Map<String, Map<String, dynamic>> _userDataCache = {};
  final Map<String, List<UnlockEvaluation>> _evaluationCache = {};
  
  // Storage keys
  static const String _userProgressKey = 'user_progress_data';
  static const String _unlockHistoryKey = 'unlock_history';
  static const String _evaluationCacheKey = 'evaluation_cache';

  /// Initializes the progressive unlock engine
  Future<void> initialize() async {
    await _skillManager.initialize();
    await _loadUserDataCache();
  }

  /// Evaluates whether a level should be unlocked for a user
  Future<UnlockDecision> evaluateUnlock(int levelId, String userId) async {
    // Get all skills that cover this level
    final relevantSkills = _skillManager.getSkillsForLevel(levelId);
    
    if (relevantSkills.isEmpty) {
      // No skills defined for this level, use basic sequential unlock
      return await _evaluateBasicUnlock(levelId, userId);
    }

    // Evaluate unlock conditions for each relevant skill
    final allEvaluations = <UnlockEvaluation>[];
    final allConditions = <UnlockCondition>[];

    for (final skill in relevantSkills) {
      final conditions = await _getUnlockConditionsForSkill(skill, levelId);
      final evaluations = await _evaluateConditions(conditions, userId, levelId);
      
      allConditions.addAll(conditions);
      allEvaluations.addAll(evaluations);
    }

    // Create unlock decision from evaluations
    final decision = UnlockDecision.fromEvaluations(
      levelId: levelId,
      evaluations: allEvaluations,
      conditions: allConditions,
    );

    // Cache the decision and update unlock history
    await _cacheUnlockDecision(userId, decision);
    
    return decision;
  }

  /// Evaluates basic sequential unlock for levels without specific skills
  Future<UnlockDecision> _evaluateBasicUnlock(int levelId, String userId) async {
    final userData = await _getUserData(userId);
    final completedLevels = userData['completedLevels'] as List<int>? ?? [];
    final previousLevel = levelId - 1;
    
    final condition = UnlockCondition(
      id: 'sequential_$levelId',
      type: UnlockConditionType.sequential,
      parameters: {'previousLevel': previousLevel},
      weight: 1.0,
      description: 'Complete the previous level',
    );

    final evaluation = UnlockEvaluation(
      conditionId: condition.id,
      isSatisfied: previousLevel <= 0 || completedLevels.contains(previousLevel),
      score: previousLevel <= 0 || completedLevels.contains(previousLevel) ? 1.0 : 0.0,
      feedback: previousLevel <= 0 
          ? 'First level is always available'
          : completedLevels.contains(previousLevel)
              ? 'Previous level completed'
              : 'Complete level $previousLevel first',
      evaluatedAt: DateTime.now(),
    );

    return UnlockDecision.fromEvaluations(
      levelId: levelId,
      evaluations: [evaluation],
      conditions: [condition],
    );
  }

  /// Gets unlock conditions for a specific skill and level
  Future<List<UnlockCondition>> _getUnlockConditionsForSkill(SkillNode skill, int levelId) async {
    final conditions = <UnlockCondition>[];
    final criteria = skill.unlockCriteria;

    // Sequential condition (prerequisite levels)
    if (criteria.requiredLevels.isNotEmpty) {
      conditions.add(UnlockCondition(
        id: '${skill.id}_sequential',
        type: UnlockConditionType.sequential,
        parameters: {'requiredLevels': criteria.requiredLevels},
        weight: 0.8,
        description: 'Complete required prerequisite levels',
        isRequired: true,
      ));
    }

    // XP-based condition
    if (criteria.minXP > 0) {
      conditions.add(UnlockCondition(
        id: '${skill.id}_xp',
        type: UnlockConditionType.xpBased,
        parameters: {'minXP': criteria.minXP},
        weight: 0.6,
        description: 'Earn ${criteria.minXP} XP points',
        isRequired: false,
      ));
    }

    // Accuracy-based condition
    if (criteria.minAccuracy > 0) {
      conditions.add(UnlockCondition(
        id: '${skill.id}_accuracy',
        type: UnlockConditionType.accuracyBased,
        parameters: {'minAccuracy': criteria.minAccuracy},
        weight: 0.7,
        description: 'Achieve ${(criteria.minAccuracy * 100).toInt()}% accuracy',
        isRequired: true,
      ));
    }

    // Skill mastery condition
    if (criteria.minMasteryScore > 0) {
      conditions.add(UnlockCondition(
        id: '${skill.id}_mastery',
        type: UnlockConditionType.skillMastery,
        parameters: {'minMasteryScore': criteria.minMasteryScore, 'skillId': skill.id},
        weight: 0.9,
        description: 'Achieve ${(criteria.minMasteryScore * 100).toInt()}% mastery in ${skill.name}',
        isRequired: skill.category == SkillCategory.mastery,
      ));
    }

    // Prerequisite skills condition
    if (skill.prerequisites.isNotEmpty) {
      conditions.add(UnlockCondition(
        id: '${skill.id}_prerequisites',
        type: UnlockConditionType.prerequisiteCompletion,
        parameters: {'prerequisites': skill.prerequisites},
        weight: 1.0,
        description: 'Complete prerequisite skills',
        isRequired: true,
      ));
    }

    // Time-based condition
    if (criteria.timeRequirement != null) {
      conditions.add(UnlockCondition(
        id: '${skill.id}_time',
        type: UnlockConditionType.timeBased,
        parameters: {'requiredMinutes': criteria.timeRequirement!.inMinutes},
        weight: 0.4,
        description: 'Spend ${criteria.timeRequirement!.inHours} hours learning',
        isRequired: false,
      ));
    }

    // Achievement-based condition
    if (criteria.requiredAchievements.isNotEmpty) {
      conditions.add(UnlockCondition(
        id: '${skill.id}_achievements',
        type: UnlockConditionType.achievementUnlock,
        parameters: {'achievements': criteria.requiredAchievements},
        weight: 0.5,
        description: 'Earn required achievements',
        isRequired: false,
      ));
    }

    // Adaptive difficulty condition for advanced skills
    if (skill.category == SkillCategory.advanced || skill.category == SkillCategory.mastery) {
      conditions.add(UnlockCondition(
        id: '${skill.id}_adaptive',
        type: UnlockConditionType.difficultyOptimal,
        parameters: {'targetDifficulty': skill.difficulty, 'skillId': skill.id},
        weight: 0.6,
        description: 'Demonstrate readiness for difficulty level ${skill.difficulty.toStringAsFixed(1)}',
        isRequired: false,
      ));
    }

    return conditions;
  }

  /// Evaluates a list of unlock conditions
  Future<List<UnlockEvaluation>> _evaluateConditions(
    List<UnlockCondition> conditions, 
    String userId, 
    int levelId
  ) async {
    final evaluations = <UnlockEvaluation>[];
    final userData = await _getUserData(userId);

    for (final condition in conditions) {
      if (!condition.isCurrentlyValid) {
        // Skip time-invalid conditions
        continue;
      }

      final evaluation = await _evaluateCondition(condition, userData, levelId);
      evaluations.add(evaluation);
    }

    return evaluations;
  }

  /// Evaluates a single unlock condition
  Future<UnlockEvaluation> _evaluateCondition(
    UnlockCondition condition, 
    Map<String, dynamic> userData, 
    int levelId
  ) async {
    switch (condition.type) {
      case UnlockConditionType.sequential:
        return _evaluateSequentialCondition(condition, userData);
      
      case UnlockConditionType.xpBased:
        return _evaluateXPCondition(condition, userData);
      
      case UnlockConditionType.accuracyBased:
        return _evaluateAccuracyCondition(condition, userData);
      
      case UnlockConditionType.skillMastery:
        return _evaluateSkillMasteryCondition(condition, userData);
      
      case UnlockConditionType.prerequisiteCompletion:
        return _evaluatePrerequisiteCondition(condition, userData);
      
      case UnlockConditionType.timeBased:
        return _evaluateTimeCondition(condition, userData);
      
      case UnlockConditionType.achievementUnlock:
        return _evaluateAchievementCondition(condition, userData);
      
      case UnlockConditionType.difficultyOptimal:
        return _evaluateDifficultyCondition(condition, userData);
      
      case UnlockConditionType.performanceTrend:
        return _evaluatePerformanceTrendCondition(condition, userData);
      
      case UnlockConditionType.learningVelocity:
        return _evaluateLearningVelocityCondition(condition, userData);
      
      default:
        return UnlockEvaluation(
          conditionId: condition.id,
          isSatisfied: false,
          score: 0.0,
          feedback: 'Condition type not implemented: ${condition.type}',
          evaluatedAt: DateTime.now(),
        );
    }
  }

  /// Evaluates sequential unlock condition
  UnlockEvaluation _evaluateSequentialCondition(
    UnlockCondition condition, 
    Map<String, dynamic> userData
  ) {
    final requiredLevels = condition.parameters['requiredLevels'] as List<int>? ?? [];
    final completedLevels = (userData['completedLevels'] as List?)?.cast<int>() ?? <int>[];
    
    final missingLevels = requiredLevels.where((level) => !completedLevels.contains(level)).toList();
    final isSatisfied = missingLevels.isEmpty;
    final score = requiredLevels.isEmpty ? 1.0 : 
        (requiredLevels.length - missingLevels.length) / requiredLevels.length;

    return UnlockEvaluation(
      conditionId: condition.id,
      isSatisfied: isSatisfied,
      score: score,
      feedback: isSatisfied 
          ? 'All prerequisite levels completed'
          : 'Complete levels: ${missingLevels.join(', ')}',
      details: {'missingLevels': missingLevels, 'completedCount': requiredLevels.length - missingLevels.length},
      evaluatedAt: DateTime.now(),
    );
  }

  /// Evaluates XP-based unlock condition
  UnlockEvaluation _evaluateXPCondition(
    UnlockCondition condition, 
    Map<String, dynamic> userData
  ) {
    final requiredXP = condition.parameters['minXP'] as int;
    final currentXP = userData['totalXP'] as int? ?? 0;
    
    final isSatisfied = currentXP >= requiredXP;
    final score = requiredXP > 0 ? min(currentXP / requiredXP, 1.0) : 1.0;

    return UnlockEvaluation(
      conditionId: condition.id,
      isSatisfied: isSatisfied,
      score: score,
      feedback: isSatisfied 
          ? 'XP requirement met ($currentXP/$requiredXP)'
          : 'Need ${requiredXP - currentXP} more XP',
      details: {'currentXP': currentXP, 'requiredXP': requiredXP},
      evaluatedAt: DateTime.now(),
    );
  }

  /// Evaluates accuracy-based unlock condition
  UnlockEvaluation _evaluateAccuracyCondition(
    UnlockCondition condition, 
    Map<String, dynamic> userData
  ) {
    final requiredAccuracy = condition.parameters['minAccuracy'] as double;
    final recentScores = (userData['recentScores'] as List?)?.cast<double>() ?? <double>[];
    
    final currentAccuracy = recentScores.isEmpty ? 0.0 : 
        recentScores.reduce((a, b) => a + b) / recentScores.length;
    
    final isSatisfied = currentAccuracy >= requiredAccuracy;
    final score = requiredAccuracy > 0 ? min(currentAccuracy / requiredAccuracy, 1.0) : 1.0;

    return UnlockEvaluation(
      conditionId: condition.id,
      isSatisfied: isSatisfied,
      score: score,
      feedback: isSatisfied 
          ? 'Accuracy requirement met (${(currentAccuracy * 100).toInt()}%)'
          : 'Need ${((requiredAccuracy - currentAccuracy) * 100).toInt()}% more accuracy',
      details: {'currentAccuracy': currentAccuracy, 'requiredAccuracy': requiredAccuracy, 'sampleSize': recentScores.length},
      evaluatedAt: DateTime.now(),
    );
  }

  /// Evaluates skill mastery condition
  UnlockEvaluation _evaluateSkillMasteryCondition(
    UnlockCondition condition, 
    Map<String, dynamic> userData
  ) {
    final requiredMastery = condition.parameters['minMasteryScore'] as double;
    final skillId = condition.parameters['skillId'] as String;
    final skillProgress = userData['skillProgress'] as Map<String, dynamic>? ?? {};
    final currentMastery = skillProgress[skillId]?['masteryScore'] as double? ?? 0.0;
    
    final isSatisfied = currentMastery >= requiredMastery;
    final score = requiredMastery > 0 ? min(currentMastery / requiredMastery, 1.0) : 1.0;

    return UnlockEvaluation(
      conditionId: condition.id,
      isSatisfied: isSatisfied,
      score: score,
      feedback: isSatisfied 
          ? 'Skill mastery achieved (${(currentMastery * 100).toInt()}%)'
          : 'Need ${((requiredMastery - currentMastery) * 100).toInt()}% more mastery',
      details: {'currentMastery': currentMastery, 'requiredMastery': requiredMastery, 'skillId': skillId},
      evaluatedAt: DateTime.now(),
    );
  }

  /// Evaluates prerequisite completion condition
  UnlockEvaluation _evaluatePrerequisiteCondition(
    UnlockCondition condition, 
    Map<String, dynamic> userData
  ) {
    final prerequisites = (condition.parameters['prerequisites'] as List).cast<String>();
    final skillProgress = userData['skillProgress'] as Map<String, dynamic>? ?? {};
    
    final completedPrereqs = prerequisites.where((prereq) => 
        skillProgress[prereq]?['completed'] == true).toList();
    
    final isSatisfied = completedPrereqs.length == prerequisites.length;
    final score = prerequisites.isEmpty ? 1.0 : completedPrereqs.length / prerequisites.length;

    return UnlockEvaluation(
      conditionId: condition.id,
      isSatisfied: isSatisfied,
      score: score,
      feedback: isSatisfied 
          ? 'All prerequisite skills completed'
          : 'Complete ${prerequisites.length - completedPrereqs.length} more prerequisite skills',
      details: {'completedPrereqs': completedPrereqs, 'totalPrereqs': prerequisites.length},
      evaluatedAt: DateTime.now(),
    );
  }

  /// Evaluates time-based condition
  UnlockEvaluation _evaluateTimeCondition(
    UnlockCondition condition, 
    Map<String, dynamic> userData
  ) {
    final requiredMinutes = condition.parameters['requiredMinutes'] as int;
    final totalTimeSpent = userData['totalTimeSpentMinutes'] as int? ?? 0;
    
    final isSatisfied = totalTimeSpent >= requiredMinutes;
    final score = requiredMinutes > 0 ? min(totalTimeSpent / requiredMinutes, 1.0) : 1.0;

    return UnlockEvaluation(
      conditionId: condition.id,
      isSatisfied: isSatisfied,
      score: score,
      feedback: isSatisfied 
          ? 'Time requirement met (${(totalTimeSpent / 60).toStringAsFixed(1)} hours)'
          : 'Need ${((requiredMinutes - totalTimeSpent) / 60).toStringAsFixed(1)} more hours',
      details: {'currentMinutes': totalTimeSpent, 'requiredMinutes': requiredMinutes},
      evaluatedAt: DateTime.now(),
    );
  }

  /// Evaluates achievement-based condition
  UnlockEvaluation _evaluateAchievementCondition(
    UnlockCondition condition, 
    Map<String, dynamic> userData
  ) {
    final requiredAchievements = (condition.parameters['achievements'] as List).cast<String>();
    final userAchievements = (userData['achievements'] as List?)?.cast<String>() ?? <String>[];
    
    final earnedRequired = requiredAchievements.where((achievement) => 
        userAchievements.contains(achievement)).toList();
    
    final isSatisfied = earnedRequired.length == requiredAchievements.length;
    final score = requiredAchievements.isEmpty ? 1.0 : earnedRequired.length / requiredAchievements.length;

    return UnlockEvaluation(
      conditionId: condition.id,
      isSatisfied: isSatisfied,
      score: score,
      feedback: isSatisfied 
          ? 'All required achievements earned'
          : 'Earn ${requiredAchievements.length - earnedRequired.length} more achievements',
      details: {'earnedRequired': earnedRequired, 'totalRequired': requiredAchievements.length},
      evaluatedAt: DateTime.now(),
    );
  }

  /// Evaluates difficulty optimization condition
  UnlockEvaluation _evaluateDifficultyCondition(
    UnlockCondition condition, 
    Map<String, dynamic> userData
  ) {
    final targetDifficulty = condition.parameters['targetDifficulty'] as double;
    final recentPerformance = userData['recentPerformance'] as Map<String, dynamic>? ?? {};
    final averageScore = recentPerformance['averageScore'] as double? ?? 0.0;
    final consistency = recentPerformance['consistency'] as double? ?? 0.0;
    
    // Calculate readiness based on performance and consistency
    final performanceReadiness = averageScore >= 0.75 ? 1.0 : averageScore / 0.75;
    final consistencyReadiness = consistency >= 0.8 ? 1.0 : consistency / 0.8;
    final overallReadiness = (performanceReadiness + consistencyReadiness) / 2;
    
    final isSatisfied = overallReadiness >= 0.8;
    final score = overallReadiness;

    return UnlockEvaluation(
      conditionId: condition.id,
      isSatisfied: isSatisfied,
      score: score,
      feedback: isSatisfied 
          ? 'Ready for difficulty level ${targetDifficulty.toStringAsFixed(1)}'
          : 'Need more consistent performance for this difficulty',
      details: {
        'targetDifficulty': targetDifficulty,
        'performanceReadiness': performanceReadiness,
        'consistencyReadiness': consistencyReadiness,
        'overallReadiness': overallReadiness,
      },
      evaluatedAt: DateTime.now(),
    );
  }

  /// Evaluates performance trend condition
  UnlockEvaluation _evaluatePerformanceTrendCondition(
    UnlockCondition condition, 
    Map<String, dynamic> userData
  ) {
    final recentScores = (userData['recentScores'] as List?)?.cast<double>() ?? <double>[];
    
    if (recentScores.length < 3) {
      return UnlockEvaluation(
        conditionId: condition.id,
        isSatisfied: false,
        score: 0.0,
        feedback: 'Need more performance data to evaluate trend',
        evaluatedAt: DateTime.now(),
      );
    }

    // Calculate trend (positive = improving, negative = declining)
    final trend = _calculatePerformanceTrend(recentScores);
    final isSatisfied = trend >= 0.0; // Non-declining performance
    final score = max(0.0, min(1.0, (trend + 1.0) / 2.0)); // Normalize to 0-1

    return UnlockEvaluation(
      conditionId: condition.id,
      isSatisfied: isSatisfied,
      score: score,
      feedback: trend >= 0.1 
          ? 'Performance is improving'
          : trend >= 0.0 
              ? 'Performance is stable'
              : 'Performance is declining - practice more',
      details: {'trend': trend, 'sampleSize': recentScores.length},
      evaluatedAt: DateTime.now(),
    );
  }

  /// Evaluates learning velocity condition
  UnlockEvaluation _evaluateLearningVelocityCondition(
    UnlockCondition condition, 
    Map<String, dynamic> userData
  ) {
    final completionTimes = (userData['recentCompletionTimes'] as List?)?.cast<int>() ?? <int>[];
    
    if (completionTimes.length < 3) {
      return UnlockEvaluation(
        conditionId: condition.id,
        isSatisfied: false,
        score: 0.0,
        feedback: 'Need more completion data to evaluate learning velocity',
        evaluatedAt: DateTime.now(),
      );
    }

    final averageTime = completionTimes.reduce((a, b) => a + b) / completionTimes.length;
    final expectedTime = 300; // 5 minutes expected per level
    
    // Faster completion = higher velocity
    final velocity = expectedTime / averageTime;
    final isSatisfied = velocity >= 0.8; // At least 80% of expected velocity
    final score = min(1.0, velocity);

    return UnlockEvaluation(
      conditionId: condition.id,
      isSatisfied: isSatisfied,
      score: score,
      feedback: velocity >= 1.2 
          ? 'Excellent learning velocity'
          : velocity >= 0.8 
              ? 'Good learning velocity'
              : 'Take time to understand concepts better',
      details: {'velocity': velocity, 'averageTime': averageTime, 'expectedTime': expectedTime},
      evaluatedAt: DateTime.now(),
    );
  }

  /// Calculates performance trend from recent scores
  double _calculatePerformanceTrend(List<double> scores) {
    if (scores.length < 2) return 0.0;
    
    // Simple linear regression slope
    final n = scores.length;
    final sumX = n * (n - 1) / 2; // Sum of indices 0, 1, 2, ...
    final sumY = scores.reduce((a, b) => a + b);
    final sumXY = scores.asMap().entries.fold(0.0, (sum, entry) => sum + entry.key * entry.value);
    final sumX2 = n * (n - 1) * (2 * n - 1) / 6; // Sum of squares of indices
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    return slope;
  }

  /// Gets user data from cache or storage
  Future<Map<String, dynamic>> _getUserData(String userId) async {
    if (_userDataCache.containsKey(userId)) {
      return _userDataCache[userId]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final userDataJson = prefs.getString('${_userProgressKey}_$userId');
    
    Map<String, dynamic> userData = {};
    if (userDataJson != null) {
      try {
        userData = json.decode(userDataJson);
      } catch (e) {
        print('Error loading user data: $e');
      }
    }

    // Initialize default values if missing
    userData.putIfAbsent('completedLevels', () => <int>[]);
    userData.putIfAbsent('totalXP', () => 0);
    userData.putIfAbsent('recentScores', () => <double>[]);
    userData.putIfAbsent('skillProgress', () => <String, dynamic>{});
    userData.putIfAbsent('achievements', () => <String>[]);
    userData.putIfAbsent('totalTimeSpentMinutes', () => 0);
    userData.putIfAbsent('recentPerformance', () => <String, dynamic>{});
    userData.putIfAbsent('recentCompletionTimes', () => <int>[]);

    _userDataCache[userId] = userData;
    return userData;
  }

  /// Loads user data cache from storage
  Future<void> _loadUserDataCache() async {
    // Implementation would load frequently accessed user data
    // For now, data is loaded on-demand
  }

  /// Caches an unlock decision
  Future<void> _cacheUnlockDecision(String userId, UnlockDecision decision) async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = '${_unlockHistoryKey}_$userId';
    final historyJson = prefs.getString(historyKey);
    
    List<Map<String, dynamic>> history = [];
    if (historyJson != null) {
      try {
        history = (json.decode(historyJson) as List).cast<Map<String, dynamic>>();
      } catch (e) {
        print('Error loading unlock history: $e');
      }
    }

    history.add(decision.toJson());
    
    // Keep only last 100 decisions
    if (history.length > 100) {
      history = history.sublist(history.length - 100);
    }

    await prefs.setString(historyKey, json.encode(history));
  }

  /// Updates user progress data
  Future<void> updateUserProgress(String userId, Map<String, dynamic> updates) async {
    final userData = await _getUserData(userId);
    userData.addAll(updates);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_userProgressKey}_$userId', json.encode(userData));
    
    // Update cache
    _userDataCache[userId] = userData;
  }

  /// Gets unlock history for a user
  Future<List<UnlockDecision>> getUnlockHistory(String userId, {int limit = 50}) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('${_unlockHistoryKey}_$userId');
    
    if (historyJson == null) return [];

    try {
      final historyData = (json.decode(historyJson) as List).cast<Map<String, dynamic>>();
      final decisions = historyData
          .map((data) => UnlockDecision.fromJson(data))
          .toList()
        ..sort((a, b) => b.decidedAt.compareTo(a.decidedAt));
      
      return decisions.take(limit).toList();
    } catch (e) {
      print('Error loading unlock history: $e');
      return [];
    }
  }

  /// Gets unlock statistics for a user
  Future<Map<String, dynamic>> getUnlockStats(String userId) async {
    final history = await getUnlockHistory(userId, limit: 1000);
    
    final stats = <String, dynamic>{};
    stats['totalEvaluations'] = history.length;
    stats['successfulUnlocks'] = history.where((d) => d.shouldUnlock).length;
    stats['averageConfidence'] = history.isEmpty ? 0.0 : 
        history.map((d) => d.confidenceScore).reduce((a, b) => a + b) / history.length;
    
    // Decision type distribution
    final decisionTypes = <String, int>{};
    for (final decision in history) {
      decisionTypes[decision.decisionType.name] = 
          (decisionTypes[decision.decisionType.name] ?? 0) + 1;
    }
    stats['decisionTypeDistribution'] = decisionTypes;
    
    return stats;
  }

  /// Clears all cached data
  void clearCache() {
    _userDataCache.clear();
    _evaluationCache.clear();
  }
}