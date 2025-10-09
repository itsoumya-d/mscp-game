import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';

/// Service for managing level progression and unlocking mechanics
class LevelProgressionService {
  static LevelProgressionService? _instance;
  static LevelProgressionService getInstance() {
    _instance ??= LevelProgressionService._internal();
    return _instance!;
  }

  LevelProgressionService._internal();

  static const String _progressKey = 'level_progression_data';
  static const String _unlockedLevelsKey = 'unlocked_levels';
  static const String _xpDataKey = 'xp_data';

  /// Performance thresholds for level unlocking
  static const double _minAccuracyForProgression = 0.7; // 70%
  static const int _minGamesForProgression = 3;
  static const double _excellentAccuracy = 0.9; // 90%
  static const double _goodAccuracy = 0.8; // 80%

  /// XP requirements for level progression
  static const Map<int, int> _xpRequirements = {
    1: 0,
    2: 100,
    3: 250,
    4: 450,
    5: 700,
    6: 1000,
    7: 1350,
    8: 1750,
    9: 2200,
    10: 2700,
  };

  /// Check if a level is unlocked for a specific subject and skill
  Future<bool> isLevelUnlocked({
    required SubjectType subject,
    required int level,
    String? skillId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedData = prefs.getString(_unlockedLevelsKey);
    
    if (unlockedData == null) {
      // First time - only level 1 is unlocked
      return level == 1;
    }

    final Map<String, dynamic> unlocked = json.decode(unlockedData);
    final key = _getLevelKey(subject, skillId, level);
    
    return unlocked[key] == true || level == 1; // Level 1 always unlocked
  }

  /// Get the highest unlocked level for a subject/skill
  Future<int> getHighestUnlockedLevel({
    required SubjectType subject,
    String? skillId,
  }) async {
    int highestLevel = 1;
    
    for (int level = 1; level <= 10; level++) {
      if (await isLevelUnlocked(
        subject: subject,
        level: level,
        skillId: skillId,
      )) {
        highestLevel = level;
      } else {
        break;
      }
    }
    
    return highestLevel;
  }

  /// Record game completion and check for level unlocks
  Future<Map<String, dynamic>> recordGameCompletion({
    required SubjectType subject,
    required int level,
    required double accuracy,
    required int score,
    required int totalTime,
    String? skillId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Update progress data
    await _updateProgressData(
      subject: subject,
      level: level,
      accuracy: accuracy,
      score: score,
      totalTime: totalTime,
      skillId: skillId,
    );

    // Award XP
    final xpAwarded = _calculateXPReward(level, accuracy, totalTime);
    await _awardXP(subject: subject, skillId: skillId, xp: xpAwarded);

    // Check for level unlocks
    final unlockedLevels = await _checkAndUnlockLevels(
      subject: subject,
      skillId: skillId,
    );

    // Get current XP and level info
    final currentXP = await getCurrentXP(subject: subject, skillId: skillId);
    final currentPlayerLevel = _getPlayerLevelFromXP(currentXP);
    final nextLevelXP = _getXPRequiredForLevel(currentPlayerLevel + 1);

    return {
      'xpAwarded': xpAwarded,
      'currentXP': currentXP,
      'currentPlayerLevel': currentPlayerLevel,
      'nextLevelXP': nextLevelXP,
      'unlockedLevels': unlockedLevels,
      'canProgress': accuracy >= _minAccuracyForProgression,
    };
  }

  /// Get current XP for a subject/skill
  Future<int> getCurrentXP({
    required SubjectType subject,
    String? skillId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final xpData = prefs.getString(_xpDataKey);
    
    if (xpData == null) return 0;

    final Map<String, dynamic> xp = json.decode(xpData);
    final key = _getXPKey(subject, skillId);
    
    return xp[key] ?? 0;
  }

  /// Get performance analytics for a subject/skill
  Future<Map<String, dynamic>> getPerformanceAnalytics({
    required SubjectType subject,
    String? skillId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = prefs.getString(_progressKey);
    
    if (progressData == null) {
      return {
        'gamesPlayed': 0,
        'averageAccuracy': 0.0,
        'averageScore': 0,
        'totalTime': 0,
        'bestAccuracy': 0.0,
        'bestScore': 0,
      };
    }

    final Map<String, dynamic> progress = json.decode(progressData);
    final key = _getProgressKey(subject, skillId);
    final subjectProgress = progress[key] as Map<String, dynamic>?;

    if (subjectProgress == null) {
      return {
        'gamesPlayed': 0,
        'averageAccuracy': 0.0,
        'averageScore': 0,
        'totalTime': 0,
        'bestAccuracy': 0.0,
        'bestScore': 0,
      };
    }

    final games = subjectProgress['games'] as List<dynamic>? ?? [];
    
    if (games.isEmpty) {
      return {
        'gamesPlayed': 0,
        'averageAccuracy': 0.0,
        'averageScore': 0,
        'totalTime': 0,
        'bestAccuracy': 0.0,
        'bestScore': 0,
      };
    }

    double totalAccuracy = 0;
    int totalScore = 0;
    int totalTime = 0;
    double bestAccuracy = 0;
    int bestScore = 0;

    for (final game in games) {
      final accuracy = (game['accuracy'] as num).toDouble();
      final score = game['score'] as int;
      final time = game['totalTime'] as int;

      totalAccuracy += accuracy;
      totalScore += score;
      totalTime += time;

      if (accuracy > bestAccuracy) bestAccuracy = accuracy;
      if (score > bestScore) bestScore = score;
    }

    return {
      'gamesPlayed': games.length,
      'averageAccuracy': totalAccuracy / games.length,
      'averageScore': totalScore ~/ games.length,
      'totalTime': totalTime,
      'bestAccuracy': bestAccuracy,
      'bestScore': bestScore,
    };
  }

  /// Get analytics for a specific level
  Future<Map<String, dynamic>> getLevelAnalytics({
    required SubjectType subject,
    required int level,
    String? skillId,
  }) async {
    // For now, return the same analytics as getPerformanceAnalytics
    // This can be enhanced later to track level-specific data
    return await getPerformanceAnalytics(
      subject: subject,
      skillId: skillId,
    );
  }

  /// Get recommended next level based on performance
  Future<Map<String, dynamic>> getRecommendedNextLevel({
    required SubjectType subject,
    String? skillId,
  }) async {
    final analytics = await getPerformanceAnalytics(
      subject: subject,
      skillId: skillId,
    );

    final currentLevel = await getHighestUnlockedLevel(
      subject: subject,
      skillId: skillId,
    );

    final accuracy = analytics['averageAccuracy'] as double;
    final gamesPlayed = analytics['gamesPlayed'] as int;

    String recommendation;
    int recommendedLevel;

    if (gamesPlayed < _minGamesForProgression) {
      recommendation = 'Play more games at current level to unlock progression';
      recommendedLevel = currentLevel;
    } else if (accuracy >= _excellentAccuracy) {
      recommendation = 'Excellent performance! Ready for advanced challenges';
      recommendedLevel = (currentLevel + 2).clamp(1, 10);
    } else if (accuracy >= _goodAccuracy) {
      recommendation = 'Good progress! Ready for next level';
      recommendedLevel = (currentLevel + 1).clamp(1, 10);
    } else if (accuracy >= _minAccuracyForProgression) {
      recommendation = 'Steady progress! Continue to next level';
      recommendedLevel = (currentLevel + 1).clamp(1, 10);
    } else {
      recommendation = 'Practice more at current level to improve accuracy';
      recommendedLevel = currentLevel;
    }

    return {
      'recommendedLevel': recommendedLevel,
      'recommendation': recommendation,
      'currentLevel': currentLevel,
      'canProgress': accuracy >= _minAccuracyForProgression && gamesPlayed >= _minGamesForProgression,
    };
  }

  /// Award XP for game completion and return amount awarded
  Future<int> awardXP({
    required SubjectType subject,
    required String skillId,
    required double accuracy,
    required int gamesPlayed,
  }) async {
    // Calculate XP based on accuracy and performance
    int baseXP = 10;
    
    if (accuracy >= _excellentAccuracy) {
      baseXP = 25; // Excellent performance
    } else if (accuracy >= _goodAccuracy) {
      baseXP = 20; // Good performance
    } else if (accuracy >= _minAccuracyForProgression) {
      baseXP = 15; // Acceptable performance
    }

    // Bonus XP for consistency (multiple games played)
    final bonusXP = (gamesPlayed > 1) ? (gamesPlayed * 2).clamp(0, 10) : 0;
    final totalXP = baseXP + bonusXP;

    await _awardXP(subject: subject, skillId: skillId, xp: totalXP);
    return totalXP;
  }

  /// Check for level unlocks and return newly unlocked levels
  Future<List<int>> checkLevelUnlocks({
    required SubjectType subject,
    required String skillId,
  }) async {
    return await _checkAndUnlockLevels(subject: subject, skillId: skillId);
  }

  /// Get next level recommendation with detailed info
  Future<Map<String, dynamic>> getNextLevelRecommendation({
    required SubjectType subject,
    required String skillId,
  }) async {
    return await getRecommendedNextLevel(subject: subject, skillId: skillId);
  }

  /// Private helper methods

  Future<void> _updateProgressData({
    required SubjectType subject,
    required int level,
    required double accuracy,
    required int score,
    required int totalTime,
    String? skillId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = prefs.getString(_progressKey);
    
    Map<String, dynamic> progress = {};
    if (progressData != null) {
      progress = json.decode(progressData);
    }

    final key = _getProgressKey(subject, skillId);
    final subjectProgress = progress[key] as Map<String, dynamic>? ?? {
      'games': <Map<String, dynamic>>[],
    };

    final games = List<Map<String, dynamic>>.from(subjectProgress['games'] ?? []);
    games.add({
      'level': level,
      'accuracy': accuracy,
      'score': score,
      'totalTime': totalTime,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 20 games for performance
    if (games.length > 20) {
      games.removeRange(0, games.length - 20);
    }

    subjectProgress['games'] = games;
    progress[key] = subjectProgress;

    await prefs.setString(_progressKey, json.encode(progress));
  }

  Future<void> _awardXP({
    required SubjectType subject,
    String? skillId,
    required int xp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final xpData = prefs.getString(_xpDataKey);
    
    Map<String, dynamic> xpMap = {};
    if (xpData != null) {
      xpMap = json.decode(xpData);
    }

    final key = _getXPKey(subject, skillId);
    final currentXP = xpMap[key] ?? 0;
    xpMap[key] = currentXP + xp;

    await prefs.setString(_xpDataKey, json.encode(xpMap));
  }

  Future<List<int>> _checkAndUnlockLevels({
    required SubjectType subject,
    String? skillId,
  }) async {
    final analytics = await getPerformanceAnalytics(
      subject: subject,
      skillId: skillId,
    );

    final accuracy = analytics['averageAccuracy'] as double;
    final gamesPlayed = analytics['gamesPlayed'] as int;
    final currentXP = await getCurrentXP(subject: subject, skillId: skillId);

    List<int> newlyUnlocked = [];

    if (gamesPlayed >= _minGamesForProgression && accuracy >= _minAccuracyForProgression) {
      final currentLevel = await getHighestUnlockedLevel(
        subject: subject,
        skillId: skillId,
      );

      // Check if we can unlock the next level
      final nextLevel = currentLevel + 1;
      if (nextLevel <= 10) {
        final requiredXP = _getXPRequiredForLevel(nextLevel);
        if (currentXP >= requiredXP) {
          await _unlockLevel(subject: subject, level: nextLevel, skillId: skillId);
          newlyUnlocked.add(nextLevel);
        }
      }
    }

    return newlyUnlocked;
  }

  Future<void> _unlockLevel({
    required SubjectType subject,
    required int level,
    String? skillId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedData = prefs.getString(_unlockedLevelsKey);
    
    Map<String, dynamic> unlocked = {};
    if (unlockedData != null) {
      unlocked = json.decode(unlockedData);
    }

    final key = _getLevelKey(subject, skillId, level);
    unlocked[key] = true;

    await prefs.setString(_unlockedLevelsKey, json.encode(unlocked));
  }

  int _calculateXPReward(int level, double accuracy, int totalTime) {
    int baseXP = 50;
    
    // Level multiplier
    double levelMultiplier = 1.0 + (level - 1) * 0.2;
    
    // Accuracy bonus
    double accuracyMultiplier = 1.0;
    if (accuracy >= 0.9) {
      accuracyMultiplier = 2.0;
    } else if (accuracy >= 0.8) {
      accuracyMultiplier = 1.5;
    } else if (accuracy >= 0.7) {
      accuracyMultiplier = 1.2;
    }

    // Time bonus (faster completion gets bonus)
    double timeMultiplier = 1.0;
    if (totalTime <= 60000) { // 1 minute
      timeMultiplier = 1.5;
    } else if (totalTime <= 120000) { // 2 minutes
      timeMultiplier = 1.2;
    }

    return (baseXP * levelMultiplier * accuracyMultiplier * timeMultiplier).round();
  }

  int _getPlayerLevelFromXP(int xp) {
    for (int level = 10; level >= 1; level--) {
      if (xp >= (_xpRequirements[level] ?? 0)) {
        return level;
      }
    }
    return 1;
  }

  int _getXPRequiredForLevel(int level) {
    return _xpRequirements[level] ?? _xpRequirements[10]!;
  }

  String _getLevelKey(SubjectType subject, String? skillId, int level) {
    return '${subject.name}_${skillId ?? 'general'}_level_$level';
  }

  String _getProgressKey(SubjectType subject, String? skillId) {
    return '${subject.name}_${skillId ?? 'general'}_progress';
  }

  String _getXPKey(SubjectType subject, String? skillId) {
    return '${subject.name}_${skillId ?? 'general'}_xp';
  }
}