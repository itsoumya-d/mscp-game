import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/educational_game.dart';

/// Service to manage XP progression across subjects and levels
class XPProgressionService {
  static XPProgressionService? _instance;
  static XPProgressionService getInstance() {
    _instance ??= XPProgressionService._internal();
    return _instance!;
  }
  XPProgressionService._internal();

  static const String _xpDataKey = 'xp_progression_data';
  static const String _levelProgressKey = 'level_progress_data';
  static const String _unlockedContentKey = 'unlocked_content_data';

  /// XP requirements for each level (exponential growth)
  static const Map<int, int> levelXPRequirements = {
    1: 0,    // Changed from 100 to 0 to match UnifiedXPService
    2: 100,  // Changed from 250 to 100
    3: 250,  // Changed from 450 to 250
    4: 450,  // Changed from 700 to 450
    5: 700,  // Changed from 1000 to 700
    6: 1000, // Changed from 1350 to 1000
    7: 1350, // Changed from 1750 to 1350
    8: 1750, // Changed from 2200 to 1750
    9: 2200, // Changed from 2700 to 2200
    10: 2700, // Changed from 3250 to 2700
  };

  /// Get current XP for a subject
  Future<int> getCurrentXP(SubjectType subject) async {
    final prefs = await SharedPreferences.getInstance();
    final xpData = prefs.getString(_xpDataKey);
    
    if (xpData == null) return 0;
    
    final Map<String, dynamic> data = jsonDecode(xpData);
    return data[subject.name] ?? 0;
  }

  /// Get current level for a subject based on XP
  Future<int> getCurrentLevel(SubjectType subject) async {
    final currentXP = await getCurrentXP(subject);
    
    for (int level = 10; level >= 1; level--) {
      if (currentXP >= levelXPRequirements[level]!) {
        return level;
      }
    }
    
    return 1; // Minimum level
  }

  /// Add XP to a subject and return new level if leveled up
  Future<Map<String, dynamic>> addXP(SubjectType subject, int xpToAdd) async {
    final prefs = await SharedPreferences.getInstance();
    final currentXP = await getCurrentXP(subject);
    final currentLevel = await getCurrentLevel(subject);
    
    final newXP = currentXP + xpToAdd;
    final newLevel = _calculateLevelFromXP(newXP);
    
    // Save new XP
    final xpData = prefs.getString(_xpDataKey);
    Map<String, dynamic> data = xpData != null ? jsonDecode(xpData) : {};
    data[subject.name] = newXP;
    await prefs.setString(_xpDataKey, jsonEncode(data));
    
    // Check if leveled up
    final leveledUp = newLevel > currentLevel;
    
    if (leveledUp) {
      await _unlockContentForLevel(subject, newLevel);
    }
    
    return {
      'previousXP': currentXP,
      'newXP': newXP,
      'xpGained': xpToAdd,
      'previousLevel': currentLevel,
      'newLevel': newLevel,
      'leveledUp': leveledUp,
      'nextLevelXP': _getNextLevelXP(newLevel),
      'progressToNextLevel': _getProgressToNextLevel(newXP, newLevel),
    };
  }

  /// Calculate level from total XP
  int _calculateLevelFromXP(int totalXP) {
    for (int level = 10; level >= 1; level--) {
      if (totalXP >= levelXPRequirements[level]!) {
        return level;
      }
    }
    return 1;
  }

  /// Get XP required for next level
  int _getNextLevelXP(int currentLevel) {
    if (currentLevel >= 10) return levelXPRequirements[10]!;
    return levelXPRequirements[currentLevel + 1]!;
  }

  /// Get progress percentage to next level (0.0 to 1.0)
  double _getProgressToNextLevel(int currentXP, int currentLevel) {
    if (currentLevel >= 10) return 1.0;
    
    final currentLevelXP = levelXPRequirements[currentLevel]!;
    final nextLevelXP = levelXPRequirements[currentLevel + 1]!;
    final xpInCurrentLevel = currentXP - currentLevelXP;
    final xpNeededForNextLevel = nextLevelXP - currentLevelXP;
    
    return (xpInCurrentLevel / xpNeededForNextLevel).clamp(0.0, 1.0);
  }

  /// Unlock content for a new level
  Future<void> _unlockContentForLevel(SubjectType subject, int level) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedData = prefs.getString(_unlockedContentKey);
    
    Map<String, dynamic> data = unlockedData != null ? jsonDecode(unlockedData) : {};
    
    if (data[subject.name] == null) {
      data[subject.name] = <int>[];
    }
    
    final List<int> unlockedLevels = List<int>.from(data[subject.name]);
    if (!unlockedLevels.contains(level)) {
      unlockedLevels.add(level);
      unlockedLevels.sort();
      data[subject.name] = unlockedLevels;
      
      await prefs.setString(_unlockedContentKey, jsonEncode(data));
    }
  }

  /// Check if a level is unlocked for a subject
  Future<bool> isLevelUnlocked(SubjectType subject, int level) async {
    final currentLevel = await getCurrentLevel(subject);
    return level <= currentLevel;
  }

  /// Get all unlocked levels for a subject
  Future<List<int>> getUnlockedLevels(SubjectType subject) async {
    final currentLevel = await getCurrentLevel(subject);
    return List.generate(currentLevel, (index) => index + 1);
  }

  /// Get XP statistics for all subjects
  Future<Map<String, dynamic>> getAllXPStats() async {
    final stats = <String, dynamic>{};
    
    for (final subject in SubjectType.values) {
      final xp = await getCurrentXP(subject);
      final level = await getCurrentLevel(subject);
      final nextLevelXP = _getNextLevelXP(level);
      final progress = _getProgressToNextLevel(xp, level);
      
      stats[subject.name] = {
        'currentXP': xp,
        'currentLevel': level,
        'nextLevelXP': nextLevelXP,
        'progressToNextLevel': progress,
        'unlockedLevels': await getUnlockedLevels(subject),
      };
    }
    
    return stats;
  }

  /// Calculate XP reward based on game performance
  int calculateXPReward({
    required int correctAnswers,
    required int totalQuestions,
    required int level,
    required Duration timeSpent,
    int? streakBonus,
  }) {
    // Base XP calculation
    final accuracy = correctAnswers / totalQuestions;
    final baseXP = (accuracy * 100).round();
    
    // Level multiplier (higher levels give more XP)
    final levelMultiplier = 1.0 + (level * 0.1);
    
    // Time bonus (faster completion gives bonus, but not too much penalty for slower)
    final timeInSeconds = timeSpent.inSeconds;
    final optimalTime = totalQuestions * 30; // 30 seconds per question
    final timeBonus = timeInSeconds <= optimalTime ? 1.2 : 1.0;
    
    // Streak bonus
    final streakMultiplier = 1.0 + ((streakBonus ?? 0) * 0.05);
    
    // Perfect score bonus
    final perfectBonus = accuracy == 1.0 ? 1.5 : 1.0;
    
    final finalXP = (baseXP * levelMultiplier * timeBonus * streakMultiplier * perfectBonus).round();
    
    return max(10, finalXP); // Minimum 10 XP
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

  /// Reset all XP data (for testing or fresh start)
  Future<void> resetAllXP() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_xpDataKey);
    await prefs.remove(_levelProgressKey);
    await prefs.remove(_unlockedContentKey);
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
      });
    }
    
    // Sort by XP descending
    leaderboard.sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));
    
    return leaderboard;
  }
}