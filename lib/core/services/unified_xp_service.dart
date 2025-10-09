import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';

/// Unified XP service to replace conflicting XP services and resolve key conflicts
class UnifiedXPService {
  static UnifiedXPService? _instance;
  static UnifiedXPService getInstance() {
    _instance ??= UnifiedXPService._internal();
    return _instance!;
  }
  UnifiedXPService._internal();

  // Unified SharedPreferences keys - no conflicts
  static const String _unifiedXpDataKey = 'unified_xp_data';
  static const String _unifiedLevelDataKey = 'unified_level_data';
  static const String _unifiedProgressKey = 'unified_progress_data';
  static const String _unifiedUnlockedContentKey = 'unified_unlocked_content';

  /// Unified XP requirements for each level (exponential growth)
  static const Map<int, int> levelXPRequirements = {
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
    11: 3250,
    12: 3850,
    13: 4500,
    14: 5200,
    15: 5950,
  };

  /// Base XP rewards for different activities
  static const int baseQuestionXP = 10;
  static const int baseLessonXP = 50;
  static const int perfectScoreBonus = 25;
  static const int streakBonus = 5;
  static const int difficultyMultiplier = 2;

  /// Performance thresholds
  static const double minAccuracyForProgression = 0.7; // 70%
  static const double excellentAccuracy = 0.9; // 90%
  static const double goodAccuracy = 0.8; // 80%

  /// Get current XP for a subject (string version for compatibility)
  Future<int> getXP(String subject) async {
    final prefs = await SharedPreferences.getInstance();
    final xpData = prefs.getString(_unifiedXpDataKey);
    
    if (xpData == null) return 0;
    
    final Map<String, dynamic> data = jsonDecode(xpData);
    return data[subject] ?? 0;
  }

  /// Get current XP for a subject
  Future<int> getCurrentXP(SubjectType subject) async {
    final prefs = await SharedPreferences.getInstance();
    final xpData = prefs.getString(_unifiedXpDataKey);
    
    if (xpData == null) return 0;
    
    final Map<String, dynamic> data = jsonDecode(xpData);
    return data[subject.name] ?? 0;
  }

  /// Get total XP across all subjects
  Future<int> getTotalXP() async {
    final prefs = await SharedPreferences.getInstance();
    final xpData = prefs.getString(_unifiedXpDataKey);
    
    if (xpData == null) return 0;
    
    final Map<String, dynamic> data = jsonDecode(xpData);
    int total = 0;
    for (final value in data.values) {
      if (value is int) total += value;
    }
    return total;
  }

  /// Get current level for a subject based on XP
  Future<int> getCurrentLevel(SubjectType subject) async {
    final currentXP = await getCurrentXP(subject);
    
    for (int level = levelXPRequirements.length; level >= 1; level--) {
      if (currentXP >= (levelXPRequirements[level] ?? 0)) {
        return level;
      }
    }
    return 1;
  }

  /// Get overall player level based on total XP
  Future<int> getOverallLevel() async {
    final totalXP = await getTotalXP();
    
    for (int level = levelXPRequirements.length; level >= 1; level--) {
      if (totalXP >= (levelXPRequirements[level] ?? 0)) {
        return level;
      }
    }
    return 1;
  }

  /// Add XP to a specific subject (string version for compatibility)
  Future<Map<String, dynamic>> addXPString(String subject, int xpToAdd) async {
    final prefs = await SharedPreferences.getInstance();
    final currentXP = await getXP(subject);
    final currentLevel = getPlayerLevelFromXP(currentXP);
    
    final newXP = currentXP + xpToAdd;
    final newLevel = getPlayerLevelFromXP(newXP);
    
    // Save subject-specific XP
    final xpData = prefs.getString(_unifiedXpDataKey);
    final Map<String, dynamic> data = xpData != null ? jsonDecode(xpData) : {};
    data[subject] = newXP;
    await prefs.setString(_unifiedXpDataKey, jsonEncode(data));
    
    // Check for level up
    final leveledUp = newLevel > currentLevel;
    
    return {
      'previousXP': currentXP,
      'newXP': newXP,
      'xpGained': xpToAdd,
      'previousLevel': currentLevel,
      'newLevel': newLevel,
      'leveledUp': leveledUp,
      'subject': subject,
    };
  }

  /// Add XP to a specific subject
  Future<Map<String, dynamic>> addXP(SubjectType subject, int xpToAdd) async {
    final prefs = await SharedPreferences.getInstance();
    final currentXP = await getCurrentXP(subject);
    final currentLevel = await getCurrentLevel(subject);
    
    final newXP = currentXP + xpToAdd;
    final newLevel = await _calculateLevelFromXP(newXP);
    
    // Save subject-specific XP
    final xpData = prefs.getString(_unifiedXpDataKey);
    final Map<String, dynamic> data = xpData != null ? jsonDecode(xpData) : {};
    data[subject.name] = newXP;
    await prefs.setString(_unifiedXpDataKey, jsonEncode(data));
    
    // Check for level up
    final leveledUp = newLevel > currentLevel;
    
    return {
      'previousXP': currentXP,
      'newXP': newXP,
      'xpGained': xpToAdd,
      'previousLevel': currentLevel,
      'newLevel': newLevel,
      'leveledUp': leveledUp,
      'subject': subject.name,
    };
  }

  /// Calculate XP reward for lesson completion based on difficulty
  int calculateLessonXP(int difficulty) {
    // Standardized lesson XP calculation
    int baseXP = 20; // Base XP for completing a lesson
    
    // Difficulty multiplier
    switch (difficulty) {
      case 1:
        return (baseXP * 1.0).round(); // Easy: 20 XP
      case 2:
        return (baseXP * 1.5).round(); // Medium: 30 XP
      case 3:
        return (baseXP * 2.0).round(); // Hard: 40 XP
      default:
        return (baseXP * (1.0 + (difficulty - 1) * 0.5)).round();
    }
  }

  /// Calculate XP reward based on performance
  int calculateXPReward({
    required int correctAnswers,
    required int totalQuestions,
    required int timeSpent,
    required String difficulty,
    bool perfectScore = false,
    int streakCount = 0,
  }) {
    int baseXP = correctAnswers * baseQuestionXP;
    
    // Difficulty multiplier
    switch (difficulty.toLowerCase()) {
      case 'easy':
        baseXP = (baseXP * 1.0).round();
        break;
      case 'medium':
        baseXP = (baseXP * 1.5).round();
        break;
      case 'hard':
        baseXP = (baseXP * 2.0).round();
        break;
    }
    
    // Perfect score bonus
    if (perfectScore) {
      baseXP += perfectScoreBonus;
    }
    
    // Streak bonus
    baseXP += min(streakCount * streakBonus, 50); // Cap at 50 bonus XP
    
    // Time bonus (faster completion = more XP)
    final accuracy = correctAnswers / totalQuestions;
    if (accuracy >= excellentAccuracy && timeSpent < 60) {
      baseXP = (baseXP * 1.2).round();
    }
    
    return max(baseXP, 1); // Minimum 1 XP
  }

  /// Check if a level is unlocked for a specific subject
  Future<bool> isLevelUnlocked({
    required SubjectType subject,
    required int level,
    String? skillId,
  }) async {
    if (level == 1) return true; // First level always unlocked
    
    final prefs = await SharedPreferences.getInstance();
    final unlockedData = prefs.getString(_unifiedUnlockedContentKey);
    
    if (unlockedData == null) return false;
    
    final Map<String, dynamic> data = jsonDecode(unlockedData);
    final subjectData = data[subject.name] as Map<String, dynamic>?;
    
    if (subjectData == null) return false;
    
    final key = skillId != null ? '${subject.name}_${skillId}_$level' : '${subject.name}_$level';
    return subjectData[key] == true;
  }

  /// Unlock a level for a specific subject
  Future<void> unlockLevel({
    required SubjectType subject,
    required int level,
    String? skillId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedData = prefs.getString(_unifiedUnlockedContentKey);
    
    final Map<String, dynamic> data = unlockedData != null ? jsonDecode(unlockedData) : {};
    
    if (data[subject.name] == null) {
      data[subject.name] = <String, dynamic>{};
    }
    
    final subjectData = data[subject.name] as Map<String, dynamic>;
    final key = skillId != null ? '${subject.name}_${skillId}_$level' : '${subject.name}_$level';
    subjectData[key] = true;
    
    await prefs.setString(_unifiedUnlockedContentKey, jsonEncode(data));
  }

  /// Get XP needed for next level
  Future<int> getXPForNextLevel(SubjectType subject) async {
    final currentLevel = await getCurrentLevel(subject);
    final nextLevel = currentLevel + 1;
    
    if (nextLevel > levelXPRequirements.length) {
      return 0; // Max level reached
    }
    
    final currentXP = await getCurrentXP(subject);
    final requiredXP = levelXPRequirements[nextLevel] ?? 0;
    
    return max(0, requiredXP - currentXP);
  }

  /// Calculate level from XP
  Future<int> _calculateLevelFromXP(int xp) async {
    for (int level = levelXPRequirements.length; level >= 1; level--) {
      if (xp >= (levelXPRequirements[level] ?? 0)) {
        return level;
      }
    }
    return 1;
  }

  /// Get player level from XP (synchronous version for compatibility)
  int getPlayerLevelFromXP(int xp) {
    for (int level = levelXPRequirements.length; level >= 1; level--) {
      if (xp >= (levelXPRequirements[level] ?? 0)) {
        return level;
      }
    }
    return 1;
  }

  /// Get level analytics for compatibility with old services
  Future<Map<String, dynamic>> getLevelAnalytics({String? subject}) async {
    final xpData = await getXPData();
    final totalXP = xpData.values.fold<int>(0, (sum, xp) => sum + xp);
    final currentLevel = getPlayerLevelFromXP(totalXP);
    final nextLevel = currentLevel + 1;
    final currentLevelXP = levelXPRequirements[currentLevel] ?? 0;
    final nextLevelXP = levelXPRequirements[nextLevel] ?? levelXPRequirements[levelXPRequirements.length] ?? 0;
    final progressToNext = nextLevelXP > currentLevelXP ? 
        ((totalXP - currentLevelXP) / (nextLevelXP - currentLevelXP)).clamp(0.0, 1.0) : 1.0;

    return {
      'currentLevel': currentLevel,
      'totalXP': totalXP,
      'currentLevelXP': currentLevelXP,
      'nextLevelXP': nextLevelXP,
      'progressToNext': progressToNext,
      'xpToNextLevel': max(0, nextLevelXP - totalXP),
      'subjectXP': subject != null ? (xpData[subject] ?? 0) : null,
    };
  }

  /// Get XP data for all subjects
  Future<Map<String, int>> getXPData() async {
    final prefs = await SharedPreferences.getInstance();
    final xpDataString = prefs.getString(_unifiedXpDataKey);
    
    if (xpDataString == null) {
      return {};
    }
    
    final Map<String, dynamic> rawData = jsonDecode(xpDataString);
    return rawData.map((key, value) => MapEntry(key, value as int));
  }

  /// Get XP statistics for all subjects
  Future<Map<String, dynamic>> getAllXPStats() async {
    final xpData = await getXPData();
    final stats = <String, dynamic>{};
    
    for (final entry in xpData.entries) {
      final subject = entry.key;
      final xp = entry.value;
      final level = getPlayerLevelFromXP(xp);
      final nextLevel = level + 1;
      final currentLevelXP = levelXPRequirements[level] ?? 0;
      final nextLevelXP = levelXPRequirements[nextLevel] ?? levelXPRequirements[levelXPRequirements.length] ?? 0;
      final progressToNext = nextLevelXP > currentLevelXP ? 
          ((xp - currentLevelXP) / (nextLevelXP - currentLevelXP)).clamp(0.0, 1.0) : 1.0;
      
      stats[subject] = {
        'currentXP': xp,
        'currentLevel': level,
        'nextLevelXP': nextLevelXP,
        'progressToNextLevel': progressToNext,
        'xpToNextLevel': max(0, nextLevelXP - xp),
      };
    }
    
    return stats;
  }

  /// Check if user can upload progress (has completed enough content)
  Future<bool> canUploadProgress() async {
    final stats = await getAllXPStats();
    
    // Require at least level 3 in at least 2 subjects
    int subjectsAtLevel3OrHigher = 0;
    
    for (final subjectStats in stats.values) {
      final level = subjectStats['currentLevel'] as int;
      if (level >= 3) {
        subjectsAtLevel3OrHigher++;
      }
    }
    
    return subjectsAtLevel3OrHigher >= 2;
  }

  /// Get progress upload eligibility details
  Future<Map<String, dynamic>> getUploadEligibility() async {
    final canUpload = await canUploadProgress();
    final stats = await getAllXPStats();
    
    final eligibilityDetails = <String, dynamic>{};
    
    for (final entry in stats.entries) {
      final subject = entry.key;
      final subjectStats = entry.value;
      final level = subjectStats['currentLevel'] as int;
      
      eligibilityDetails[subject] = {
        'currentLevel': level,
        'meetsRequirement': level >= 3,
        'xpToNextLevel': level < 10 ? subjectStats['nextLevelXP'] - subjectStats['currentXP'] : 0,
      };
    }
    
    return {
      'canUpload': canUpload,
      'requirementMet': canUpload,
      'requirement': 'Reach level 3 in at least 2 subjects',
      'subjectDetails': eligibilityDetails,
    };
  }

  /// Get leaderboard data (top XP across all subjects)
  Future<List<Map<String, dynamic>>> getLeaderboardData() async {
    final stats = await getAllXPStats();
    final leaderboard = <Map<String, dynamic>>[];
    
    for (final entry in stats.entries) {
      final subject = entry.key;
      final subjectStats = entry.value;
      
      leaderboard.add({
        'subject': subject,
        'xp': subjectStats['currentXP'],
        'level': subjectStats['currentLevel'],
        'progressToNext': subjectStats['progressToNextLevel'],
      });
    }
    
    // Sort by XP descending
    leaderboard.sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));
    
    return leaderboard;
  }

  /// Migrate data from old services (call this once during app startup)
  Future<void> migrateFromOldServices() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if migration already done
    final migrationDone = prefs.getBool('xp_migration_completed') ?? false;
    if (migrationDone) return;
    
    // Migrate from old XP services
    final oldXpData = prefs.getString('user_xp_data');
    final oldProgressionData = prefs.getString('xp_progression_data');
    final oldLevelData = prefs.getString('xp_data');
    
    Map<String, dynamic> unifiedData = {};
    
    // Merge data from different sources, taking the highest values
    if (oldXpData != null) {
      final data = jsonDecode(oldXpData) as Map<String, dynamic>;
      for (final entry in data.entries) {
        final currentValue = unifiedData[entry.key] as int? ?? 0;
        unifiedData[entry.key] = max(currentValue, entry.value as int? ?? 0);
      }
    }
    
    if (oldProgressionData != null) {
      final data = jsonDecode(oldProgressionData) as Map<String, dynamic>;
      for (final entry in data.entries) {
        final currentValue = unifiedData[entry.key] as int? ?? 0;
        unifiedData[entry.key] = max(currentValue, entry.value as int? ?? 0);
      }
    }
    
    if (oldLevelData != null) {
      final data = jsonDecode(oldLevelData) as Map<String, dynamic>;
      for (final entry in data.entries) {
        final currentValue = unifiedData[entry.key] as int? ?? 0;
        unifiedData[entry.key] = max(currentValue, entry.value as int? ?? 0);
      }
    }
    
    // Save unified data
    if (unifiedData.isNotEmpty) {
      await prefs.setString(_unifiedXpDataKey, jsonEncode(unifiedData));
    }
    
    // Mark migration as completed
    await prefs.setBool('xp_migration_completed', true);
  }

  /// Clear all XP data (for testing/reset purposes)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_unifiedXpDataKey);
    await prefs.remove(_unifiedLevelDataKey);
    await prefs.remove(_unifiedProgressKey);
    await prefs.remove(_unifiedUnlockedContentKey);
    await prefs.remove('xp_migration_completed');
  }

  /// Get user progress data including level progress
  Future<UserProgressData> getUserProgress(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = prefs.getString(_unifiedProgressKey);
    
    Map<String, LevelProgressData> levelProgress = {};
    
    if (progressData != null) {
      final Map<String, dynamic> data = jsonDecode(progressData);
      final userProgressData = data[userId] as Map<String, dynamic>?;
      
      if (userProgressData != null) {
        final levelProgressMap = userProgressData['levelProgress'] as Map<String, dynamic>? ?? {};
        
        for (final entry in levelProgressMap.entries) {
          final levelId = entry.key;
          final levelData = entry.value as Map<String, dynamic>;
          
          levelProgress[levelId] = LevelProgressData(
            isCompleted: levelData['isCompleted'] ?? false,
            accuracy: (levelData['accuracy'] ?? 0.0).toDouble(),
            gamesPlayed: levelData['gamesPlayed'] ?? 0,
            bestScore: levelData['bestScore'] ?? 0,
            totalTime: levelData['totalTime'] ?? 0,
            lastPlayed: levelData['lastPlayed'] != null 
                ? DateTime.parse(levelData['lastPlayed']) 
                : null,
          );
        }
      }
    }
    
    return UserProgressData(
      userId: userId,
      levelProgress: levelProgress,
    );
  }

  /// Update level progress data
  Future<void> updateLevelProgress({
    required String userId,
    required String levelId,
    required bool isCompleted,
    required double accuracy,
    required int score,
    required int totalTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = prefs.getString(_unifiedProgressKey);
    
    Map<String, dynamic> data = {};
    if (progressData != null) {
      data = jsonDecode(progressData);
    }
    
    if (data[userId] == null) {
      data[userId] = {'levelProgress': <String, dynamic>{}};
    }
    
    final userProgressData = data[userId] as Map<String, dynamic>;
    final levelProgressMap = userProgressData['levelProgress'] as Map<String, dynamic>;
    
    final existingProgress = levelProgressMap[levelId] as Map<String, dynamic>? ?? {};
    final gamesPlayed = (existingProgress['gamesPlayed'] ?? 0) + 1;
    final bestScore = max((existingProgress['bestScore'] ?? 0) as int, score);
    
    levelProgressMap[levelId] = {
      'isCompleted': isCompleted,
      'accuracy': accuracy,
      'gamesPlayed': gamesPlayed,
      'bestScore': bestScore,
      'totalTime': (existingProgress['totalTime'] ?? 0) + totalTime,
      'lastPlayed': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_unifiedProgressKey, jsonEncode(data));
  }
}

/// Data class for user progress
class UserProgressData {
  final String userId;
  final Map<String, LevelProgressData> levelProgress;

  const UserProgressData({
    required this.userId,
    required this.levelProgress,
  });
}

/// Data class for individual level progress
class LevelProgressData {
  final bool isCompleted;
  final double accuracy;
  final int gamesPlayed;
  final int bestScore;
  final int totalTime;
  final DateTime? lastPlayed;

  const LevelProgressData({
    required this.isCompleted,
    required this.accuracy,
    required this.gamesPlayed,
    required this.bestScore,
    required this.totalTime,
    this.lastPlayed,
  });
}