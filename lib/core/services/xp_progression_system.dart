import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/services/sound_manager_service.dart';
import 'package:sp/core/services/enhanced_firebase_sync.dart';

/// Comprehensive XP and level progression system
class XPProgressionSystem {
  static final XPProgressionSystem instance = XPProgressionSystem._();
  XPProgressionSystem._();

  // XP calculation constants
  static const int baseXPPerQuestion = 10;
  static const int perfectAnswerBonus = 5;
  static const int streakBonusMultiplier = 2;
  static const int firstTryBonus = 10;
  static const int speedBonusThreshold = 10; // seconds
  static const int speedBonus = 5;

  // Level progression constants
  static const int baseXPForLevel = 100;
  static const double levelMultiplier = 1.5;
  static const int maxLevel = 100;

  // Reward constants
  static const int coinsPerLevel = 50;
  static const int gemsPerMilestone = 10; // Every 5 levels
  static const int livesPerMilestone = 1; // Every 10 levels

  /// Calculate XP earned for answering a question
  int calculateQuestionXP({
    required bool isCorrect,
    required int difficulty,
    required int currentStreak,
    required bool isFirstTry,
    required Duration timeSpent,
  }) {
    if (!isCorrect) return 0;

    int xp = baseXPPerQuestion;

    // Difficulty multiplier
    xp *= difficulty;

    // First try bonus
    if (isFirstTry) {
      xp += firstTryBonus;
    }

    // Streak bonus
    if (currentStreak > 0) {
      xp += (currentStreak * streakBonusMultiplier);
    }

    // Speed bonus
    if (timeSpent.inSeconds <= speedBonusThreshold) {
      xp += speedBonus;
    }

    return xp;
  }

  /// Calculate XP for completing a lesson
  int calculateLessonXP({
    required int correctAnswers,
    required int totalAnswers,
    required int difficulty,
    required Duration totalTime,
  }) {
    int xp = 0;

    // Base XP for each correct answer
    xp += correctAnswers * baseXPPerQuestion * difficulty;

    // Perfect score bonus
    if (correctAnswers == totalAnswers) {
      xp += perfectAnswerBonus * totalAnswers;
    }

    // Completion bonus
    final completionRate = correctAnswers / totalAnswers;
    if (completionRate >= 0.8) {
      xp += 50; // Good performance bonus
    }

    return xp;
  }

  /// Calculate XP required for a specific level
  int calculateXPForLevel(int level) {
    if (level <= 1) return 0;
    
    // Exponential growth: XP = base * (multiplier ^ (level - 1))
    return (baseXPForLevel * (levelMultiplier * (level - 1))).round();
  }

  /// Calculate total XP required to reach a level
  int calculateTotalXPForLevel(int level) {
    int totalXP = 0;
    for (int i = 2; i <= level; i++) {
      totalXP += calculateXPForLevel(i);
    }
    return totalXP;
  }

  /// Calculate current level from total XP
  int calculateLevelFromXP(int totalXP) {
    int level = 1;
    int xpForNextLevel = calculateXPForLevel(2);
    int accumulatedXP = 0;

    while (accumulatedXP + xpForNextLevel <= totalXP && level < maxLevel) {
      accumulatedXP += xpForNextLevel;
      level++;
      xpForNextLevel = calculateXPForLevel(level + 1);
    }

    return level;
  }

  /// Calculate XP progress within current level
  Map<String, int> calculateLevelProgress(int totalXP) {
    final currentLevel = calculateLevelFromXP(totalXP);
    final xpForCurrentLevel = calculateTotalXPForLevel(currentLevel);
    final xpForNextLevel = calculateTotalXPForLevel(currentLevel + 1);
    
    final xpInLevel = totalXP - xpForCurrentLevel;
    final xpNeededForNext = xpForNextLevel - xpForCurrentLevel;

    return {
      'currentLevel': currentLevel,
      'xpInLevel': xpInLevel,
      'xpNeededForNext': xpNeededForNext,
      'totalXP': totalXP,
    };
  }

  /// Award XP and check for level up
  Future<LevelUpResult> awardXP({
    required int currentXP,
    required int xpToAdd,
    required Function(int newLevel) onLevelUp,
  }) async {
    final oldLevel = calculateLevelFromXP(currentXP);
    final newTotalXP = currentXP + xpToAdd;
    final newLevel = calculateLevelFromXP(newTotalXP);

    final leveledUp = newLevel > oldLevel;
    final levelsGained = newLevel - oldLevel;

    if (leveledUp) {
      // Play level up sound
      SoundManagerService.instance.playLevelComplete();
      
      // Trigger level up callback
      onLevelUp(newLevel);

      // Calculate rewards
      final rewards = _calculateLevelUpRewards(oldLevel, newLevel);

      return LevelUpResult(
        leveledUp: true,
        oldLevel: oldLevel,
        newLevel: newLevel,
        levelsGained: levelsGained,
        newTotalXP: newTotalXP,
        rewards: rewards,
      );
    }

    return LevelUpResult(
      leveledUp: false,
      oldLevel: oldLevel,
      newLevel: newLevel,
      levelsGained: 0,
      newTotalXP: newTotalXP,
      rewards: LevelUpRewards.empty(),
    );
  }

  /// Calculate rewards for leveling up
  LevelUpRewards _calculateLevelUpRewards(int oldLevel, int newLevel) {
    int coins = 0;
    int gems = 0;
    int lives = 0;
    final achievements = <String>[];

    for (int level = oldLevel + 1; level <= newLevel; level++) {
      // Coins for every level
      coins += coinsPerLevel;

      // Gems for milestone levels (every 5 levels)
      if (level % 5 == 0) {
        gems += gemsPerMilestone;
        achievements.add('Reached Level $level!');
      }

      // Lives for major milestones (every 10 levels)
      if (level % 10 == 0) {
        lives += livesPerMilestone;
        achievements.add('Level $level Milestone!');
      }

      // Special achievements
      if (level == 25) {
        achievements.add('Quarter Century!');
        gems += 25;
      }
      if (level == 50) {
        achievements.add('Halfway to Mastery!');
        gems += 50;
      }
      if (level == 100) {
        achievements.add('Master Level Achieved!');
        gems += 100;
        lives += 5;
      }
    }

    return LevelUpRewards(
      coins: coins,
      gems: gems,
      lives: lives,
      achievements: achievements,
    );
  }

  /// Calculate difficulty progression based on level
  int calculateDifficultyForLevel(int level) {
    if (level < 10) return 1; // Easy
    if (level < 30) return 2; // Medium
    if (level < 60) return 3; // Hard
    return 4; // Expert
  }

  /// Get recommended content difficulty
  int getRecommendedDifficulty(int level, double recentPerformance) {
    int baseDifficulty = calculateDifficultyForLevel(level);

    // Adjust based on recent performance
    if (recentPerformance >= 0.9) {
      baseDifficulty = (baseDifficulty + 1).clamp(1, 4);
    } else if (recentPerformance < 0.6) {
      baseDifficulty = (baseDifficulty - 1).clamp(1, 4);
    }

    return baseDifficulty;
  }

  /// Calculate streak bonus
  int calculateStreakBonus(int streakDays) {
    if (streakDays < 3) return 0;
    if (streakDays < 7) return 10;
    if (streakDays < 30) return 25;
    if (streakDays < 100) return 50;
    return 100;
  }

  /// Get XP statistics
  Map<String, dynamic> getXPStatistics(int totalXP) {
    final progress = calculateLevelProgress(totalXP);
    final currentLevel = progress['currentLevel']!;
    final xpInLevel = progress['xpInLevel']!;
    final xpNeededForNext = progress['xpNeededForNext']!;

    return {
      'totalXP': totalXP,
      'currentLevel': currentLevel,
      'xpInLevel': xpInLevel,
      'xpNeededForNext': xpNeededForNext,
      'progressPercentage': (xpInLevel / xpNeededForNext * 100).round(),
      'nextMilestone': _getNextMilestone(currentLevel),
      'recommendedDifficulty': calculateDifficultyForLevel(currentLevel),
    };
  }

  /// Get next milestone level
  int _getNextMilestone(int currentLevel) {
    if (currentLevel < 5) return 5;
    if (currentLevel < 10) return 10;
    if (currentLevel < 25) return 25;
    if (currentLevel < 50) return 50;
    if (currentLevel < 100) return 100;
    return 100;
  }
}

/// Result of awarding XP
class LevelUpResult {
  final bool leveledUp;
  final int oldLevel;
  final int newLevel;
  final int levelsGained;
  final int newTotalXP;
  final LevelUpRewards rewards;

  LevelUpResult({
    required this.leveledUp,
    required this.oldLevel,
    required this.newLevel,
    required this.levelsGained,
    required this.newTotalXP,
    required this.rewards,
  });
}

/// Rewards for leveling up
class LevelUpRewards {
  final int coins;
  final int gems;
  final int lives;
  final List<String> achievements;

  LevelUpRewards({
    required this.coins,
    required this.gems,
    required this.lives,
    required this.achievements,
  });

  factory LevelUpRewards.empty() {
    return LevelUpRewards(
      coins: 0,
      gems: 0,
      lives: 0,
      achievements: [],
    );
  }

  bool get hasRewards => coins > 0 || gems > 0 || lives > 0 || achievements.isNotEmpty;
}

/// XP event for tracking
class XPEvent {
  final String type;
  final int xpEarned;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  XPEvent({
    required this.type,
    required this.xpEarned,
    required this.timestamp,
    required this.metadata,
  });
}

/// XP tracker for analytics
class XPTracker {
  final List<XPEvent> _events = [];

  void trackXPGain({
    required String type,
    required int xpEarned,
    Map<String, dynamic>? metadata,
  }) {
    _events.add(XPEvent(
      type: type,
      xpEarned: xpEarned,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    ));

    // Keep only last 100 events
    if (_events.length > 100) {
      _events.removeAt(0);
    }
  }

  int getTotalXPEarned() {
    return _events.fold(0, (sum, event) => sum + event.xpEarned);
  }

  Map<String, int> getXPByType() {
    final byType = <String, int>{};
    for (final event in _events) {
      byType[event.type] = (byType[event.type] ?? 0) + event.xpEarned;
    }
    return byType;
  }
}

