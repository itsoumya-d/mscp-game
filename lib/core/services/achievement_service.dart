import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';

enum AchievementType {
  gameplay,
  progress,
  streak,
  mastery,
  social,
  special,
}

enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final AchievementType type;
  final AchievementRarity rarity;
  final int xpReward;
  final Map<String, dynamic> requirements;
  final DateTime? unlockedAt;
  final double progress;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.type,
    required this.rarity,
    required this.xpReward,
    required this.requirements,
    this.unlockedAt,
    this.progress = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'iconPath': iconPath,
    'type': type.name,
    'rarity': rarity.name,
    'xpReward': xpReward,
    'requirements': requirements,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'progress': progress,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    iconPath: json['iconPath'],
    type: AchievementType.values.firstWhere((e) => e.name == json['type']),
    rarity: AchievementRarity.values.firstWhere((e) => e.name == json['rarity']),
    xpReward: json['xpReward'],
    requirements: json['requirements'],
    unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
    progress: json['progress'] ?? 0.0,
  );

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    AchievementType? type,
    AchievementRarity? rarity,
    int? xpReward,
    Map<String, dynamic>? requirements,
    DateTime? unlockedAt,
    double? progress,
  }) => Achievement(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    iconPath: iconPath ?? this.iconPath,
    type: type ?? this.type,
    rarity: rarity ?? this.rarity,
    xpReward: xpReward ?? this.xpReward,
    requirements: requirements ?? this.requirements,
    unlockedAt: unlockedAt ?? this.unlockedAt,
    progress: progress ?? this.progress,
  );

  bool get isUnlocked => unlockedAt != null;
}

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final FirebaseService _firebaseService = FirebaseService();

  // Predefined achievements
  static final Map<String, Achievement> _achievements = {
    // Gameplay Achievements
    'first_game': Achievement(
      id: 'first_game',
      title: 'First Steps',
      description: 'Complete your first game session',
      iconPath: 'assets/achievements/first_game.svg',
      type: AchievementType.gameplay,
      rarity: AchievementRarity.common,
      xpReward: 10,
      requirements: {'gamesPlayed': 1},
    ),
    'perfect_game': Achievement(
      id: 'perfect_game',
      title: 'Perfectionist',
      description: 'Score 100% accuracy in a game session',
      iconPath: 'assets/achievements/perfect_game.svg',
      type: AchievementType.gameplay,
      rarity: AchievementRarity.uncommon,
      xpReward: 25,
      requirements: {'perfectAccuracy': 1},
    ),
    'speed_demon': Achievement(
      id: 'speed_demon',
      title: 'Speed Demon',
      description: 'Complete a game in under 2 minutes',
      iconPath: 'assets/achievements/speed_demon.svg',
      type: AchievementType.gameplay,
      rarity: AchievementRarity.rare,
      xpReward: 30,
      requirements: {'fastCompletion': 120}, // seconds
    ),
    'marathon_player': Achievement(
      id: 'marathon_player',
      title: 'Marathon Player',
      description: 'Play 50 games in total',
      iconPath: 'assets/achievements/marathon_player.svg',
      type: AchievementType.gameplay,
      rarity: AchievementRarity.rare,
      xpReward: 50,
      requirements: {'gamesPlayed': 50},
    ),
    'century_club': Achievement(
      id: 'century_club',
      title: 'Century Club',
      description: 'Play 100 games in total',
      iconPath: 'assets/achievements/century_club.svg',
      type: AchievementType.gameplay,
      rarity: AchievementRarity.epic,
      xpReward: 100,
      requirements: {'gamesPlayed': 100},
    ),

    // Progress Achievements
    'level_up': Achievement(
      id: 'level_up',
      title: 'Level Up!',
      description: 'Reach level 5',
      iconPath: 'assets/achievements/level_up.svg',
      type: AchievementType.progress,
      rarity: AchievementRarity.common,
      xpReward: 20,
      requirements: {'level': 5},
    ),
    'xp_collector': Achievement(
      id: 'xp_collector',
      title: 'XP Collector',
      description: 'Earn 1000 total XP',
      iconPath: 'assets/achievements/xp_collector.svg',
      type: AchievementType.progress,
      rarity: AchievementRarity.uncommon,
      xpReward: 50,
      requirements: {'totalXP': 1000},
    ),
    'skill_master': Achievement(
      id: 'skill_master',
      title: 'Skill Master',
      description: 'Unlock 10 different skills',
      iconPath: 'assets/achievements/skill_master.svg',
      type: AchievementType.progress,
      rarity: AchievementRarity.rare,
      xpReward: 75,
      requirements: {'skillsUnlocked': 10},
    ),
    'subject_explorer': Achievement(
      id: 'subject_explorer',
      title: 'Subject Explorer',
      description: 'Play games in all 4 subjects',
      iconPath: 'assets/achievements/subject_explorer.svg',
      type: AchievementType.progress,
      rarity: AchievementRarity.uncommon,
      xpReward: 40,
      requirements: {'subjectsPlayed': 4},
    ),

    // Streak Achievements
    'daily_player': Achievement(
      id: 'daily_player',
      title: 'Daily Player',
      description: 'Play for 3 consecutive days',
      iconPath: 'assets/achievements/daily_player.svg',
      type: AchievementType.streak,
      rarity: AchievementRarity.common,
      xpReward: 15,
      requirements: {'dailyStreak': 3},
    ),
    'week_warrior': Achievement(
      id: 'week_warrior',
      title: 'Week Warrior',
      description: 'Play for 7 consecutive days',
      iconPath: 'assets/achievements/week_warrior.svg',
      type: AchievementType.streak,
      rarity: AchievementRarity.uncommon,
      xpReward: 35,
      requirements: {'dailyStreak': 7},
    ),
    'consistency_king': Achievement(
      id: 'consistency_king',
      title: 'Consistency King',
      description: 'Play for 30 consecutive days',
      iconPath: 'assets/achievements/consistency_king.svg',
      type: AchievementType.streak,
      rarity: AchievementRarity.legendary,
      xpReward: 200,
      requirements: {'dailyStreak': 30},
    ),
    'perfect_streak': Achievement(
      id: 'perfect_streak',
      title: 'Perfect Streak',
      description: 'Get perfect scores in 5 consecutive games',
      iconPath: 'assets/achievements/perfect_streak.svg',
      type: AchievementType.streak,
      rarity: AchievementRarity.epic,
      xpReward: 100,
      requirements: {'perfectStreak': 5},
    ),

    // Mastery Achievements
    'math_master': Achievement(
      id: 'math_master',
      title: 'Math Master',
      description: 'Achieve 90% average accuracy in Mathematics',
      iconPath: 'assets/achievements/math_master.svg',
      type: AchievementType.mastery,
      rarity: AchievementRarity.epic,
      xpReward: 80,
      requirements: {'subjectAccuracy': {'math': 0.9}},
    ),
    'science_scholar': Achievement(
      id: 'science_scholar',
      title: 'Science Scholar',
      description: 'Achieve 90% average accuracy in Science',
      iconPath: 'assets/achievements/science_scholar.svg',
      type: AchievementType.mastery,
      rarity: AchievementRarity.epic,
      xpReward: 80,
      requirements: {'subjectAccuracy': {'science': 0.9}},
    ),
    'code_ninja': Achievement(
      id: 'code_ninja',
      title: 'Code Ninja',
      description: 'Achieve 90% average accuracy in Programming',
      iconPath: 'assets/achievements/code_ninja.svg',
      type: AchievementType.mastery,
      rarity: AchievementRarity.epic,
      xpReward: 80,
      requirements: {'subjectAccuracy': {'programming': 0.9}},
    ),
    'history_buff': Achievement(
      id: 'history_buff',
      title: 'History Buff',
      description: 'Achieve 90% average accuracy in History',
      iconPath: 'assets/achievements/history_buff.svg',
      type: AchievementType.mastery,
      rarity: AchievementRarity.epic,
      xpReward: 80,
      requirements: {'subjectAccuracy': {'history': 0.9}},
    ),
    'all_rounder': Achievement(
      id: 'all_rounder',
      title: 'All-Rounder',
      description: 'Achieve 85% accuracy in all subjects',
      iconPath: 'assets/achievements/all_rounder.svg',
      type: AchievementType.mastery,
      rarity: AchievementRarity.legendary,
      xpReward: 150,
      requirements: {
        'subjectAccuracy': {
          'math': 0.85,
          'science': 0.85,
          'programming': 0.85,
          'history': 0.85,
        }
      },
    ),

    // Special Achievements
    'early_bird': Achievement(
      id: 'early_bird',
      title: 'Early Bird',
      description: 'Play a game before 8 AM',
      iconPath: 'assets/achievements/early_bird.svg',
      type: AchievementType.special,
      rarity: AchievementRarity.uncommon,
      xpReward: 25,
      requirements: {'earlyMorningPlay': 1},
    ),
    'night_owl': Achievement(
      id: 'night_owl',
      title: 'Night Owl',
      description: 'Play a game after 10 PM',
      iconPath: 'assets/achievements/night_owl.svg',
      type: AchievementType.special,
      rarity: AchievementRarity.uncommon,
      xpReward: 25,
      requirements: {'lateNightPlay': 1},
    ),
    'comeback_kid': Achievement(
      id: 'comeback_kid',
      title: 'Comeback Kid',
      description: 'Return to play after 7 days of inactivity',
      iconPath: 'assets/achievements/comeback_kid.svg',
      type: AchievementType.special,
      rarity: AchievementRarity.rare,
      xpReward: 40,
      requirements: {'comeback': 1},
    ),
  };

  // Get all achievements with current progress
  Future<List<Achievement>> getAllAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString('achievements_progress') ?? '{}';
      final Map<String, dynamic> progress = jsonDecode(achievementsJson);
      
      return _achievements.values.map((achievement) {
        final achievementProgress = progress[achievement.id];
        if (achievementProgress != null) {
          return Achievement.fromJson(achievementProgress);
        }
        return achievement;
      }).toList();
    } catch (e) {
      print('Error getting achievements: $e');
      return _achievements.values.toList();
    }
  }

  // Get unlocked achievements
  Future<List<Achievement>> getUnlockedAchievements() async {
    final achievements = await getAllAchievements();
    return achievements.where((achievement) => achievement.isUnlocked).toList();
  }

  // Get achievements by type
  Future<List<Achievement>> getAchievementsByType(AchievementType type) async {
    final achievements = await getAllAchievements();
    return achievements.where((achievement) => achievement.type == type).toList();
  }

  // Get achievements by rarity
  Future<List<Achievement>> getAchievementsByRarity(AchievementRarity rarity) async {
    final achievements = await getAllAchievements();
    return achievements.where((achievement) => achievement.rarity == rarity).toList();
  }

  // Check and unlock achievements based on current stats
  Future<List<Achievement>> checkAndUnlockAchievements() async {
    final newlyUnlocked = <Achievement>[];
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final stats = await _getCurrentStats();
      
      for (final achievement in _achievements.values) {
        if (await _isAchievementUnlocked(achievement.id)) continue;
        
        final progress = _calculateProgress(achievement, stats);
        await _updateAchievementProgress(achievement.id, progress);
        
        if (progress >= 1.0) {
          final unlockedAchievement = await _unlockAchievement(achievement.id);
          if (unlockedAchievement != null) {
            newlyUnlocked.add(unlockedAchievement);
            
            // Award XP
            final currentXP = prefs.getInt('total_xp') ?? 0;
            await prefs.setInt('total_xp', currentXP + achievement.xpReward);
          }
        }
      }
      
      return newlyUnlocked;
    } catch (e) {
      print('Error checking achievements: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _getCurrentStats() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'gamesPlayed': prefs.getInt('games_played') ?? 0,
      'totalXP': prefs.getInt('total_xp') ?? 0,
      'level': prefs.getInt('current_level') ?? 1,
      'dailyStreak': prefs.getInt('daily_streak') ?? 0,
      'perfectStreak': prefs.getInt('perfect_streak') ?? 0,
      'perfectAccuracy': prefs.getInt('perfect_games') ?? 0,
      'fastCompletion': prefs.getInt('fast_completions') ?? 0,
      'skillsUnlocked': (jsonDecode(prefs.getString('unlocked_levels') ?? '[]') as List).length,
      'subjectsPlayed': (jsonDecode(prefs.getString('subjects_played') ?? '[]') as List).length,
      'subjectAccuracy': {
        'math': prefs.getDouble('math_accuracy') ?? 0.0,
        'science': prefs.getDouble('science_accuracy') ?? 0.0,
        'programming': prefs.getDouble('programming_accuracy') ?? 0.0,
        'history': prefs.getDouble('history_accuracy') ?? 0.0,
      },
      'earlyMorningPlay': prefs.getInt('early_morning_plays') ?? 0,
      'lateNightPlay': prefs.getInt('late_night_plays') ?? 0,
      'comeback': prefs.getInt('comebacks') ?? 0,
    };
  }

  double _calculateProgress(Achievement achievement, Map<String, dynamic> stats) {
    final requirements = achievement.requirements;
    
    switch (achievement.type) {
      case AchievementType.gameplay:
        if (requirements.containsKey('gamesPlayed')) {
          return (stats['gamesPlayed'] as int) / (requirements['gamesPlayed'] as int);
        }
        if (requirements.containsKey('perfectAccuracy')) {
          return (stats['perfectAccuracy'] as int) >= (requirements['perfectAccuracy'] as int) ? 1.0 : 0.0;
        }
        if (requirements.containsKey('fastCompletion')) {
          return (stats['fastCompletion'] as int) >= 1 ? 1.0 : 0.0;
        }
        break;
        
      case AchievementType.progress:
        if (requirements.containsKey('level')) {
          return (stats['level'] as int) / (requirements['level'] as int);
        }
        if (requirements.containsKey('totalXP')) {
          return (stats['totalXP'] as int) / (requirements['totalXP'] as int);
        }
        if (requirements.containsKey('skillsUnlocked')) {
          return (stats['skillsUnlocked'] as int) / (requirements['skillsUnlocked'] as int);
        }
        if (requirements.containsKey('subjectsPlayed')) {
          return (stats['subjectsPlayed'] as int) / (requirements['subjectsPlayed'] as int);
        }
        break;
        
      case AchievementType.streak:
        if (requirements.containsKey('dailyStreak')) {
          return (stats['dailyStreak'] as int) / (requirements['dailyStreak'] as int);
        }
        if (requirements.containsKey('perfectStreak')) {
          return (stats['perfectStreak'] as int) / (requirements['perfectStreak'] as int);
        }
        break;
        
      case AchievementType.mastery:
        if (requirements.containsKey('subjectAccuracy')) {
          final reqAccuracy = requirements['subjectAccuracy'] as Map<String, dynamic>;
          final statsAccuracy = stats['subjectAccuracy'] as Map<String, dynamic>;
          
          if (reqAccuracy.length == 1) {
            // Single subject mastery
            final subject = reqAccuracy.keys.first;
            final required = reqAccuracy[subject] as double;
            final current = statsAccuracy[subject] as double;
            return current / required;
          } else {
            // All subjects mastery
            double totalProgress = 0.0;
            for (final entry in reqAccuracy.entries) {
              final required = entry.value as double;
              final current = statsAccuracy[entry.key] as double;
              totalProgress += (current / required).clamp(0.0, 1.0);
            }
            return totalProgress / reqAccuracy.length;
          }
        }
        break;
        
      case AchievementType.special:
        if (requirements.containsKey('earlyMorningPlay')) {
          return (stats['earlyMorningPlay'] as int) >= 1 ? 1.0 : 0.0;
        }
        if (requirements.containsKey('lateNightPlay')) {
          return (stats['lateNightPlay'] as int) >= 1 ? 1.0 : 0.0;
        }
        if (requirements.containsKey('comeback')) {
          return (stats['comeback'] as int) >= 1 ? 1.0 : 0.0;
        }
        break;
        
      case AchievementType.social:
        // Future implementation for social features
        break;
    }
    
    return 0.0;
  }

  Future<bool> _isAchievementUnlocked(String achievementId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString('achievements_progress') ?? '{}';
      final Map<String, dynamic> progress = jsonDecode(achievementsJson);
      
      final achievementData = progress[achievementId];
      return achievementData != null && achievementData['unlockedAt'] != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> _updateAchievementProgress(String achievementId, double progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString('achievements_progress') ?? '{}';
      final Map<String, dynamic> achievementsProgress = jsonDecode(achievementsJson);
      
      final achievement = _achievements[achievementId]!;
      achievementsProgress[achievementId] = achievement.copyWith(progress: progress.clamp(0.0, 1.0)).toJson();
      
      await prefs.setString('achievements_progress', jsonEncode(achievementsProgress));
    } catch (e) {
      print('Error updating achievement progress: $e');
    }
  }

  Future<Achievement?> _unlockAchievement(String achievementId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString('achievements_progress') ?? '{}';
      final Map<String, dynamic> achievementsProgress = jsonDecode(achievementsJson);
      
      final achievement = _achievements[achievementId]!;
      final unlockedAchievement = achievement.copyWith(
        unlockedAt: DateTime.now(),
        progress: 1.0,
      );
      
      achievementsProgress[achievementId] = unlockedAchievement.toJson();
      await prefs.setString('achievements_progress', jsonEncode(achievementsProgress));
      
      // Sync to cloud
      if (_firebaseService.isLoggedIn) {
        await _firebaseService.unlockAchievement(achievementId, {
          'unlockedAt': DateTime.now().toIso8601String(),
          'achievementId': achievementId,
        });
      }
      
      print('Achievement unlocked: ${achievement.title}');
      return unlockedAchievement;
    } catch (e) {
      print('Error unlocking achievement: $e');
      return null;
    }
  }

  // Update stats that affect achievements
  Future<void> updateGameStats({
    required double accuracy,
    required int timeSpent,
    required String subject,
    required int score,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Update games played
      final gamesPlayed = prefs.getInt('games_played') ?? 0;
      await prefs.setInt('games_played', gamesPlayed + 1);
      
      // Update perfect games
      if (accuracy >= 1.0) {
        final perfectGames = prefs.getInt('perfect_games') ?? 0;
        await prefs.setInt('perfect_games', perfectGames + 1);
        
        // Update perfect streak
        final perfectStreak = prefs.getInt('perfect_streak') ?? 0;
        await prefs.setInt('perfect_streak', perfectStreak + 1);
      } else {
        await prefs.setInt('perfect_streak', 0);
      }
      
      // Update fast completions (under 2 minutes)
      if (timeSpent < 120) {
        final fastCompletions = prefs.getInt('fast_completions') ?? 0;
        await prefs.setInt('fast_completions', fastCompletions + 1);
      }
      
      // Update subject accuracy
      final subjectKey = '${subject}_accuracy';
      final subjectGamesKey = '${subject}_games';
      final currentAccuracy = prefs.getDouble(subjectKey) ?? 0.0;
      final subjectGames = prefs.getInt(subjectGamesKey) ?? 0;
      
      final newAccuracy = (currentAccuracy * subjectGames + accuracy) / (subjectGames + 1);
      await prefs.setDouble(subjectKey, newAccuracy);
      await prefs.setInt(subjectGamesKey, subjectGames + 1);
      
      // Update subjects played
      final subjectsPlayedJson = prefs.getString('subjects_played') ?? '[]';
      final List<dynamic> subjectsPlayed = jsonDecode(subjectsPlayedJson);
      if (!subjectsPlayed.contains(subject)) {
        subjectsPlayed.add(subject);
        await prefs.setString('subjects_played', jsonEncode(subjectsPlayed));
      }
      
      // Update time-based achievements
      final now = DateTime.now();
      if (now.hour < 8) {
        final earlyPlays = prefs.getInt('early_morning_plays') ?? 0;
        await prefs.setInt('early_morning_plays', earlyPlays + 1);
      }
      if (now.hour >= 22) {
        final latePlays = prefs.getInt('late_night_plays') ?? 0;
        await prefs.setInt('late_night_plays', latePlays + 1);
      }
      
      // Check for achievements after updating stats
      await checkAndUnlockAchievements();
      
    } catch (e) {
      print('Error updating game stats: $e');
    }
  }

  // Update daily streak
  Future<void> updateDailyStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPlayDate = prefs.getString('last_play_date');
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      if (lastPlayDate == null) {
        // First time playing
        await prefs.setString('last_play_date', today);
        await prefs.setInt('daily_streak', 1);
      } else if (lastPlayDate != today) {
        final lastDate = DateTime.parse(lastPlayDate);
        final todayDate = DateTime.parse(today);
        final daysDifference = todayDate.difference(lastDate).inDays;
        
        if (daysDifference == 1) {
          // Consecutive day
          final currentStreak = prefs.getInt('daily_streak') ?? 0;
          await prefs.setInt('daily_streak', currentStreak + 1);
        } else if (daysDifference > 7) {
          // Comeback after 7+ days
          final comebacks = prefs.getInt('comebacks') ?? 0;
          await prefs.setInt('comebacks', comebacks + 1);
          await prefs.setInt('daily_streak', 1);
        } else {
          // Streak broken
          await prefs.setInt('daily_streak', 1);
        }
        
        await prefs.setString('last_play_date', today);
      }
      
      // Check for achievements after updating streak
      await checkAndUnlockAchievements();
      
    } catch (e) {
      print('Error updating daily streak: $e');
    }
  }

  // Get achievement statistics
  Future<Map<String, dynamic>> getAchievementStats() async {
    try {
      final achievements = await getAllAchievements();
      final unlocked = achievements.where((a) => a.isUnlocked).length;
      final total = achievements.length;
      
      final byType = <String, Map<String, int>>{};
      final byRarity = <String, Map<String, int>>{};
      
      for (final type in AchievementType.values) {
        final typeAchievements = achievements.where((a) => a.type == type);
        final typeUnlocked = typeAchievements.where((a) => a.isUnlocked).length;
        byType[type.name] = {
          'unlocked': typeUnlocked,
          'total': typeAchievements.length,
        };
      }
      
      for (final rarity in AchievementRarity.values) {
        final rarityAchievements = achievements.where((a) => a.rarity == rarity);
        final rarityUnlocked = rarityAchievements.where((a) => a.isUnlocked).length;
        byRarity[rarity.name] = {
          'unlocked': rarityUnlocked,
          'total': rarityAchievements.length,
        };
      }
      
      return {
        'totalUnlocked': unlocked,
        'totalAchievements': total,
        'completionPercentage': (unlocked / total * 100).round(),
        'byType': byType,
        'byRarity': byRarity,
      };
    } catch (e) {
      print('Error getting achievement stats: $e');
      return {
        'totalUnlocked': 0,
        'totalAchievements': 0,
        'completionPercentage': 0,
        'byType': {},
        'byRarity': {},
      };
    }
  }

  // Sync achievements with cloud
  Future<void> syncAchievements() async {
    if (!_firebaseService.isLoggedIn) return;
    
    try {
      // Implementation for syncing achievements with Firebase
      // This would involve comparing local and cloud achievements
      // and merging them appropriately
      print('Syncing achievements with cloud...');
    } catch (e) {
      print('Error syncing achievements: $e');
    }
  }
}