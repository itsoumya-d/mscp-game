import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/features/levels/models/enhanced_level_data.dart';
import 'package:sp/features/levels/widgets/level_node.dart';

/// Service for managing progressive unlock system across all subjects
class ProgressiveUnlockService {
  static final ProgressiveUnlockService _instance = ProgressiveUnlockService._internal();
  factory ProgressiveUnlockService() => _instance;
  ProgressiveUnlockService._internal();

  static const String _unlockDataKey = 'progressive_unlock_data';
  static const String _completionDataKey = 'level_completion_data';
  
  // Unlock requirements
  static const int STARS_TO_UNLOCK_NEXT_SKILL = 3;
  static const int SKILLS_TO_UNLOCK_NEXT_UNIT = 5;
  static const double MIN_ACCURACY_FOR_UNLOCK = 0.7;
  static const int MIN_ATTEMPTS_FOR_MASTERY = 2;

  Map<String, Map<String, dynamic>> _unlockData = {};
  Map<String, Map<String, dynamic>> _completionData = {};

  /// Initialize the unlock service
  Future<void> initialize() async {
    await _loadUnlockData();
    await _loadCompletionData();
  }

  /// Check if a specific level/lesson is unlocked
  bool isLevelUnlocked(String subjectId, int unitIndex, int skillIndex, int lessonIndex) {
    final levelId = _getLevelId(subjectId, unitIndex, skillIndex, lessonIndex);
    
    // First level is always unlocked
    if (unitIndex == 0 && skillIndex == 0 && lessonIndex == 0) {
      return true;
    }
    
    // Check if previous level requirements are met
    return _checkUnlockRequirements(subjectId, unitIndex, skillIndex, lessonIndex);
  }

  /// Check if a skill is unlocked
  bool isSkillUnlocked(String subjectId, int unitIndex, int skillIndex) {
    // First skill is always unlocked
    if (unitIndex == 0 && skillIndex == 0) {
      return true;
    }
    
    // Check if previous skill has enough stars
    if (skillIndex > 0) {
      final previousSkillStars = getSkillStars(subjectId, unitIndex, skillIndex - 1);
      return previousSkillStars >= STARS_TO_UNLOCK_NEXT_SKILL;
    }
    
    // Check if previous unit has enough completed skills
    if (unitIndex > 0) {
      final previousUnitCompletedSkills = getUnitCompletedSkills(subjectId, unitIndex - 1);
      return previousUnitCompletedSkills >= SKILLS_TO_UNLOCK_NEXT_UNIT;
    }
    
    return false;
  }

  /// Check if a unit is unlocked
  bool isUnitUnlocked(String subjectId, int unitIndex) {
    // First unit is always unlocked
    if (unitIndex == 0) {
      return true;
    }
    
    // Check if previous unit has enough completed skills
    final previousUnitCompletedSkills = getUnitCompletedSkills(subjectId, unitIndex - 1);
    return previousUnitCompletedSkills >= SKILLS_TO_UNLOCK_NEXT_UNIT;
  }

  /// Record level completion
  Future<void> recordLevelCompletion({
    required String subjectId,
    required int unitIndex,
    required int skillIndex,
    required int lessonIndex,
    required int score,
    required double accuracy,
    required int timeSpent,
  }) async {
    final levelId = _getLevelId(subjectId, unitIndex, skillIndex, lessonIndex);
    
    if (!_completionData.containsKey(subjectId)) {
      _completionData[subjectId] = {};
    }
    
    final currentData = _completionData[subjectId]![levelId] ?? {
      'attempts': 0,
      'bestScore': 0,
      'bestAccuracy': 0.0,
      'totalTimeSpent': 0,
      'stars': 0,
      'completed': false,
    };
    
    // Update completion data
    currentData['attempts'] = (currentData['attempts'] as int) + 1;
    currentData['bestScore'] = math.max(currentData['bestScore'] as int, score);
    currentData['bestAccuracy'] = math.max(currentData['bestAccuracy'] as double, accuracy);
    currentData['totalTimeSpent'] = (currentData['totalTimeSpent'] as int) + timeSpent;
    
    // Calculate stars based on performance
    final stars = _calculateStars(score, accuracy, currentData['attempts'] as int);
    currentData['stars'] = math.max(currentData['stars'] as int, stars);
    currentData['completed'] = stars > 0;
    
    _completionData[subjectId]![levelId] = currentData;
    
    // Update skill progress
    await _updateSkillProgress(subjectId, unitIndex, skillIndex);
    
    // Save data
    await _saveCompletionData();
    await _checkAndUnlockNewContent(subjectId, unitIndex, skillIndex, lessonIndex);
  }

  /// Get enhanced level data for display
  EnhancedLevelData getEnhancedLevelData({
    required String subjectId,
    required int unitIndex,
    required int skillIndex,
    required int lessonIndex,
  }) {
    final levelId = _getLevelId(subjectId, unitIndex, skillIndex, lessonIndex);
    final isUnlocked = isLevelUnlocked(subjectId, unitIndex, skillIndex, lessonIndex);
    
    final completionData = _completionData[subjectId]?[levelId] ?? {
      'attempts': 0,
      'bestScore': 0,
      'bestAccuracy': 0.0,
      'stars': 0,
      'completed': false,
    };
    
    // Determine level state
    LevelNodeState state;
    if (!isUnlocked) {
      state = LevelNodeState.locked;
    } else if (completionData['completed'] as bool) {
      state = LevelNodeState.completed;
    } else {
      state = LevelNodeState.unlocked;
    }
    
    // Calculate difficulty and color
    final difficulty = _calculateLevelDifficulty(unitIndex, skillIndex, lessonIndex);
    final difficultyColor = _getDifficultyColor(difficulty);
    
    // Generate unlock reason
    final unlockReason = _getUnlockReason(subjectId, unitIndex, skillIndex, lessonIndex, isUnlocked);
    
    return EnhancedLevelData(
      level: _getLevelNumber(unitIndex, skillIndex, lessonIndex),
      state: state,
      stars: completionData['stars'] as int,
      bestScore: completionData['bestScore'] as int,
      accuracy: completionData['bestAccuracy'] as double,
      difficultyColor: difficultyColor,
      difficulty: difficulty,
      unlockReason: unlockReason,
      skillProgress: getSkillProgress(subjectId, unitIndex, skillIndex),
      isRecommended: _isRecommendedLevel(subjectId, unitIndex, skillIndex, lessonIndex),
      isUnlocked: isUnlocked,
      attempts: completionData['attempts'] as int,
      bestAccuracy: completionData['bestAccuracy'] as double,
    );
  }

  /// Get skill progress (0.0 to 1.0)
  double getSkillProgress(String subjectId, int unitIndex, int skillIndex) {
    final skillId = _getSkillId(subjectId, unitIndex, skillIndex);
    return _unlockData[subjectId]?[skillId]?['progress'] ?? 0.0;
  }

  /// Get number of stars for a skill
  int getSkillStars(String subjectId, int unitIndex, int skillIndex) {
    final skillId = _getSkillId(subjectId, unitIndex, skillIndex);
    return _unlockData[subjectId]?[skillId]?['stars'] ?? 0;
  }

  /// Get number of completed skills in a unit
  int getUnitCompletedSkills(String subjectId, int unitIndex) {
    int completedSkills = 0;
    for (int skillIndex = 0; skillIndex < 25; skillIndex++) { // 25 skills per unit
      final skillStars = getSkillStars(subjectId, unitIndex, skillIndex);
      if (skillStars >= STARS_TO_UNLOCK_NEXT_SKILL) {
        completedSkills++;
      }
    }
    return completedSkills;
  }

  /// Get recommended next level for a subject
  Map<String, int>? getRecommendedNextLevel(String subjectId) {
    // Find the first incomplete level
    for (int unitIndex = 0; unitIndex < 20; unitIndex++) {
      if (!isUnitUnlocked(subjectId, unitIndex)) break;
      
      for (int skillIndex = 0; skillIndex < 25; skillIndex++) {
        if (!isSkillUnlocked(subjectId, unitIndex, skillIndex)) break;
        
        for (int lessonIndex = 0; lessonIndex < 20; lessonIndex++) {
          if (!isLevelUnlocked(subjectId, unitIndex, skillIndex, lessonIndex)) {
            return {
              'unitIndex': unitIndex,
              'skillIndex': skillIndex,
              'lessonIndex': lessonIndex,
            };
          }
          
          final levelId = _getLevelId(subjectId, unitIndex, skillIndex, lessonIndex);
          final completionData = _completionData[subjectId]?[levelId];
          if (completionData == null || !(completionData['completed'] as bool)) {
            return {
              'unitIndex': unitIndex,
              'skillIndex': skillIndex,
              'lessonIndex': lessonIndex,
            };
          }
        }
      }
    }
    
    return null; // All levels completed
  }

  /// Get overall progress for a subject (0.0 to 1.0)
  double getSubjectProgress(String subjectId) {
    int totalLevels = 0;
    int completedLevels = 0;
    
    for (int unitIndex = 0; unitIndex < 20; unitIndex++) {
      for (int skillIndex = 0; skillIndex < 25; skillIndex++) {
        for (int lessonIndex = 0; lessonIndex < 20; lessonIndex++) {
          totalLevels++;
          
          final levelId = _getLevelId(subjectId, unitIndex, skillIndex, lessonIndex);
          final completionData = _completionData[subjectId]?[levelId];
          if (completionData != null && (completionData['completed'] as bool)) {
            completedLevels++;
          }
        }
      }
    }
    
    return totalLevels > 0 ? completedLevels / totalLevels : 0.0;
  }

  // Private helper methods

  bool _checkUnlockRequirements(String subjectId, int unitIndex, int skillIndex, int lessonIndex) {
    // Check if previous lesson is completed
    if (lessonIndex > 0) {
      final prevLevelId = _getLevelId(subjectId, unitIndex, skillIndex, lessonIndex - 1);
      final prevCompletion = _completionData[subjectId]?[prevLevelId];
      return prevCompletion != null && (prevCompletion['completed'] as bool);
    }
    
    // Check if skill is unlocked
    return isSkillUnlocked(subjectId, unitIndex, skillIndex);
  }

  int _calculateStars(int score, double accuracy, int attempts) {
    if (accuracy >= 0.95 && attempts <= 2) return 3; // Perfect performance
    if (accuracy >= 0.85 && score >= 80) return 2;   // Good performance
    if (accuracy >= MIN_ACCURACY_FOR_UNLOCK) return 1; // Minimum passing
    return 0; // Failed
  }

  double _calculateLevelDifficulty(int unitIndex, int skillIndex, int lessonIndex) {
    // Progressive difficulty from 1.0 to 10.0
    final totalProgress = (unitIndex * 25 * 20) + (skillIndex * 20) + lessonIndex;
    final maxProgress = 20 * 25 * 20; // Total levels per subject
    return 1.0 + (9.0 * totalProgress / maxProgress);
  }

  Color _getDifficultyColor(double difficulty) {
    if (difficulty <= 2.0) return Colors.green;
    if (difficulty <= 4.0) return Colors.lightGreen;
    if (difficulty <= 6.0) return Colors.yellow;
    if (difficulty <= 8.0) return Colors.orange;
    return Colors.red;
  }

  String _getUnlockReason(String subjectId, int unitIndex, int skillIndex, int lessonIndex, bool isUnlocked) {
    if (isUnlocked) return '';
    
    if (lessonIndex > 0) {
      return 'Complete the previous lesson to unlock';
    }
    
    if (skillIndex > 0) {
      final requiredStars = STARS_TO_UNLOCK_NEXT_SKILL;
      final currentStars = getSkillStars(subjectId, unitIndex, skillIndex - 1);
      return 'Earn $requiredStars stars in the previous skill (currently $currentStars)';
    }
    
    if (unitIndex > 0) {
      final requiredSkills = SKILLS_TO_UNLOCK_NEXT_UNIT;
      final completedSkills = getUnitCompletedSkills(subjectId, unitIndex - 1);
      return 'Complete $requiredSkills skills in the previous unit (currently $completedSkills)';
    }
    
    return 'Requirements not met';
  }

  bool _isRecommendedLevel(String subjectId, int unitIndex, int skillIndex, int lessonIndex) {
    final recommended = getRecommendedNextLevel(subjectId);
    if (recommended == null) return false;
    
    return recommended['unitIndex'] == unitIndex &&
           recommended['skillIndex'] == skillIndex &&
           recommended['lessonIndex'] == lessonIndex;
  }

  Future<void> _updateSkillProgress(String subjectId, int unitIndex, int skillIndex) async {
    final skillId = _getSkillId(subjectId, unitIndex, skillIndex);
    
    if (!_unlockData.containsKey(subjectId)) {
      _unlockData[subjectId] = {};
    }
    
    // Calculate skill progress based on completed lessons
    int completedLessons = 0;
    int totalStars = 0;
    
    for (int lessonIndex = 0; lessonIndex < 20; lessonIndex++) {
      final levelId = _getLevelId(subjectId, unitIndex, skillIndex, lessonIndex);
      final completionData = _completionData[subjectId]?[levelId];
      
      if (completionData != null && (completionData['completed'] as bool)) {
        completedLessons++;
        totalStars += completionData['stars'] as int;
      }
    }
    
    final progress = completedLessons / 20.0;
    final skillStars = (totalStars / 20).round().clamp(0, 5);
    
    _unlockData[subjectId]![skillId] = {
      'progress': progress,
      'stars': skillStars,
      'completedLessons': completedLessons,
    };
    
    await _saveUnlockData();
  }

  Future<void> _checkAndUnlockNewContent(String subjectId, int unitIndex, int skillIndex, int lessonIndex) async {
    // This method can trigger unlock animations and notifications
    // For now, it just ensures data consistency
    await _saveUnlockData();
  }

  /// Unlock next content based on current progress
  Future<void> unlockNextContent(String subjectId, int unitIndex, int skillIndex, int lessonIndex) async {
    // Mark current level as completed
    await recordLevelCompletion(
      subjectId: subjectId, 
      unitIndex: unitIndex, 
      skillIndex: skillIndex, 
      lessonIndex: lessonIndex,
      score: 100,
      accuracy: 1.0, 
      timeSpent: 60
    );
    
    // Check and unlock new content based on completion
    await _checkAndUnlockNewContent(subjectId, unitIndex, skillIndex, lessonIndex);
    
    // Update skill progress
    await _updateSkillProgress(subjectId, unitIndex, skillIndex);
  }

  String _getLevelId(String subjectId, int unitIndex, int skillIndex, int lessonIndex) {
    return '${subjectId}_u${unitIndex}_s${skillIndex}_l$lessonIndex';
  }

  String _getSkillId(String subjectId, int unitIndex, int skillIndex) {
    return '${subjectId}_u${unitIndex}_s$skillIndex';
  }

  int _getLevelNumber(int unitIndex, int skillIndex, int lessonIndex) {
    return (unitIndex * 25 * 20) + (skillIndex * 20) + lessonIndex + 1;
  }

  Future<void> _loadUnlockData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString(_unlockDataKey);
      if (dataString != null) {
        final Map<String, dynamic> rawData = json.decode(dataString);
        _unlockData = rawData.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
      }
    } catch (e) {
      print('Error loading unlock data: $e');
      _unlockData = {};
    }
  }

  Future<void> _saveUnlockData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = json.encode(_unlockData);
      await prefs.setString(_unlockDataKey, dataString);
    } catch (e) {
      print('Error saving unlock data: $e');
    }
  }

  Future<void> _loadCompletionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString(_completionDataKey);
      if (dataString != null) {
        final Map<String, dynamic> rawData = json.decode(dataString);
        _completionData = rawData.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
      }
    } catch (e) {
      print('Error loading completion data: $e');
      _completionData = {};
    }
  }

  Future<void> _saveCompletionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = json.encode(_completionData);
      await prefs.setString(_completionDataKey, dataString);
    } catch (e) {
      print('Error saving completion data: $e');
    }
  }

  /// Reset all progress (for testing purposes)
  Future<void> resetAllProgress() async {
    _unlockData.clear();
    _completionData.clear();
    await _saveUnlockData();
    await _saveCompletionData();
  }
}