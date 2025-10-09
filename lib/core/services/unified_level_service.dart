import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/educational_game.dart';
import 'firebase_service.dart';
import 'cloud_sync_service.dart';
import 'unified_xp_service.dart';
import 'optimized_level_cache.dart';
import 'game_session_service.dart';
import 'level_unlock_service.dart';
import 'unlock_animation_service.dart';

/// Unified service for managing all level progression, unlocking, and XP mechanics
/// Consolidates functionality from LevelProgressionService, LevelUnlockService, and XpProgressionService
class UnifiedLevelService {
  static UnifiedLevelService? _instance;
  static UnifiedLevelService getInstance() {
    _instance ??= UnifiedLevelService._internal();
    return _instance!;
  }
  UnifiedLevelService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final CloudSyncService _cloudSyncService = CloudSyncService();
  final OptimizedLevelCache _levelCache = OptimizedLevelCache.instance;
  final UnifiedXPService _xpService = UnifiedXPService.getInstance();
  final LevelUnlockService _levelUnlockService = LevelUnlockService();
  final UnlockAnimationService _unlockAnimationService = UnlockAnimationService.instance;

  // Storage keys
  static const String _levelProgressKey = 'unified_level_progress';
  static const String _unlockedLevelsKey = 'unified_unlocked_levels';
  static const String _playerStatsKey = 'unified_player_stats';
  static const String _migrationKey = 'unified_level_migration_v1';

  // Performance thresholds
  static const double _minAccuracyForProgression = 0.7; // 70%
  static const int _minGamesForProgression = 3;
  static const double _excellentAccuracy = 0.9; // 90%
  static const double _goodAccuracy = 0.8; // 80%

  // Level definitions with requirements
  static const Map<String, Map<String, dynamic>> _levelDefinitions = {
    // Mathematics levels
    'math_1': {
      'subject': 'mathematics',
      'displayName': 'Basic Numbers',
      'difficulty': 1,
      'xpRequired': 0,
      'prerequisites': <String>[],
      'minAccuracy': 0.0,
      'skillIds': ['counting', 'basic_addition'],
    },
    'math_2': {
      'subject': 'mathematics',
      'displayName': 'Addition & Subtraction',
      'difficulty': 2,
      'xpRequired': 100,
      'prerequisites': ['math_1'],
      'minAccuracy': 0.7,
      'skillIds': ['addition', 'subtraction'],
    },
    'math_3': {
      'subject': 'mathematics',
      'displayName': 'Multiplication',
      'difficulty': 3,
      'xpRequired': 250,
      'prerequisites': ['math_2'],
      'minAccuracy': 0.7,
      'skillIds': ['multiplication', 'times_tables'],
    },
    'math_4': {
      'subject': 'mathematics',
      'displayName': 'Division',
      'difficulty': 4,
      'xpRequired': 450,
      'prerequisites': ['math_3'],
      'minAccuracy': 0.75,
      'skillIds': ['division', 'remainders'],
    },
    'math_5': {
      'subject': 'mathematics',
      'displayName': 'Fractions',
      'difficulty': 5,
      'xpRequired': 700,
      'prerequisites': ['math_4'],
      'minAccuracy': 0.75,
      'skillIds': ['fractions', 'decimals'],
    },
    // Science levels
    'science_1': {
      'subject': 'science',
      'displayName': 'Living Things',
      'difficulty': 1,
      'xpRequired': 0,
      'prerequisites': <String>[],
      'minAccuracy': 0.0,
      'skillIds': ['animals', 'plants'],
    },
    'science_2': {
      'subject': 'science',
      'displayName': 'Human Body',
      'difficulty': 2,
      'xpRequired': 100,
      'prerequisites': ['science_1'],
      'minAccuracy': 0.7,
      'skillIds': ['body_parts', 'senses'],
    },
    // English levels
    'english_1': {
      'subject': 'english',
      'displayName': 'Letters & Sounds',
      'difficulty': 1,
      'xpRequired': 0,
      'prerequisites': <String>[],
      'minAccuracy': 0.0,
      'skillIds': ['alphabet', 'phonics'],
    },
    'english_2': {
      'subject': 'english',
      'displayName': 'Simple Words',
      'difficulty': 2,
      'xpRequired': 100,
      'prerequisites': ['english_1'],
      'minAccuracy': 0.7,
      'skillIds': ['sight_words', 'spelling'],
    },
  };

  /// Initialize the service and perform data migration if needed
  Future<void> initialize() async {
    await _levelCache.initialize();
    await _ensureMigrationCompleted();
    
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool(_migrationKey) ?? false;
    
    if (!migrated) {
      await _migrateExistingData();
      await prefs.setBool(_migrationKey, true);
    }
  }

  /// Check if a level is unlocked for a subject
  Future<bool> isLevelUnlocked({
    required SubjectType subject,
    required int level,
    String? skillId,
  }) async {
    final unlockedLevels = await getUnlockedLevels(subject: subject);
    return unlockedLevels.contains(level.toString());
  }

  /// Legacy method for backward compatibility
  Future<bool> isLevelUnlockedLegacy(String subject, int level) async {
    final unlockedLevels = await getUnlockedLevels(subject: SubjectType.values.firstWhere((s) => s.name == subject));
    return unlockedLevels.contains(level.toString());
  }

  /// Get the highest unlocked level for a subject
  Future<int> getHighestUnlockedLevel({
    required SubjectType subject,
    String? skillId,
  }) async {
    final unlockedLevels = await getUnlockedLevels(subject: subject);
    if (unlockedLevels.isEmpty) return 1;
    
    // Extract level numbers from level IDs and find the maximum
    final levelNumbers = unlockedLevels
        .map((levelId) => int.tryParse(levelId.split('_').last) ?? 1)
        .toList();
    return levelNumbers.reduce((a, b) => a > b ? a : b);
  }

  /// Legacy method for backward compatibility
  Future<int> getHighestUnlockedLevelLegacy(String subject) async {
    final unlockedLevels = await getUnlockedLevels(subject: SubjectType.values.firstWhere((s) => s.name == subject));
    if (unlockedLevels.isEmpty) return 1;
    
    // Extract level numbers from level IDs and find the maximum
    final levelNumbers = unlockedLevels
        .map((levelId) => int.tryParse(levelId.split('_').last) ?? 1)
        .toList();
    return levelNumbers.reduce((a, b) => a > b ? a : b);
  }

  /// Unlock a level and return true if it was newly unlocked
  Future<bool> unlockLevel(String subject, int level) async {
    final wasAlreadyUnlocked = await isLevelUnlockedLegacy(subject, level);
    if (wasAlreadyUnlocked) {
      return false; // Level was already unlocked
    }

    final unlockedLevels = await getUnlockedLevels(subject: SubjectType.values.firstWhere((s) => s.name == subject));
    unlockedLevels.add(level.toString());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${subject}_unlocked_levels', unlockedLevels);
    
    return true; // Level was newly unlocked
  }

  /// Get levels that should be unlocked based on XP progression
  Future<List<int>> getAvailableLevelsForUnlock(String subject) async {
    final currentXP = await _xpService.getXP(subject);
    final currentLevel = await getCurrentLevel(subject);
    final unlockedLevels = await getUnlockedLevels(subject: SubjectType.values.firstWhere((s) => s.name == subject));
    
    final availableLevels = <int>[];
    
    // Check if player has enough XP to unlock next levels
    for (int level = 1; level <= currentLevel; level++) {
      if (!unlockedLevels.contains(level)) {
        availableLevels.add(level);
      }
    }
    
    return availableLevels;
  }

  /// Process level completion and handle unlocking
  Future<Map<String, dynamic>> processLevelCompletion(
    String subject, 
    int completedLevel, 
    int earnedXP
  ) async {
    // Add XP
    await _xpService.addXPString(subject, earnedXP);
    
    // Mark level as completed
    await markLevelCompleted(subject, completedLevel);
    
    // Check for newly unlocked levels
    final newlyUnlockedLevels = <int>[];
    final availableLevels = await getAvailableLevelsForUnlock(subject);
    
    for (final level in availableLevels) {
      final wasNewlyUnlocked = await unlockLevel(subject, level);
      if (wasNewlyUnlocked) {
        newlyUnlockedLevels.add(level);
        
        // Trigger unlock animation for newly unlocked level
        await _triggerLevelUnlockAnimation(
          subject: subject,
          level: level,
          xpReward: earnedXP,
        );
      }
    }
    
    return {
      'completedLevel': completedLevel,
      'earnedXP': earnedXP,
      'newlyUnlockedLevels': newlyUnlockedLevels,
      'currentXP': await _xpService.getXP(subject),
      'currentLevel': await getCurrentLevel(subject),
    };
  }

  /// Get all unlocked levels for a subject
  Future<List<String>> getUnlockedLevels({SubjectType? subject}) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedData = prefs.getString(_unlockedLevelsKey);
    
    if (unlockedData == null) {
      await _unlockStartingLevels();
      return _getStartingLevels(subject);
    }
    
    final Map<String, dynamic> unlocked = jsonDecode(unlockedData);
    List<String> result = [];
    
    for (String levelId in unlocked.keys) {
      if (unlocked[levelId] == true) {
        if (subject == null || _levelDefinitions[levelId]?['subject'] == subject.name) {
          result.add(levelId);
        }
      }
    }
    
    return result;
  }

  /// Get level information
  Map<String, dynamic>? getLevelInfo(String levelId) {
    return _levelDefinitions[levelId];
  }

  /// Get all levels for a subject
  List<String> getLevelsForSubject(SubjectType subject) {
    return _levelDefinitions.keys
        .where((levelId) => _levelDefinitions[levelId]?['subject'] == subject.name)
        .toList()
        ..sort();
  }

  /// Mark a level as completed
  Future<void> markLevelCompleted(String subject, int level) async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = prefs.getString(_levelProgressKey);
    
    Map<String, dynamic> allProgress = {};
    if (progressData != null) {
      allProgress = jsonDecode(progressData);
    }
    
    final levelId = '${subject}_$level';
    if (allProgress[levelId] == null) {
      allProgress[levelId] = {};
    }
    
    allProgress[levelId]['completed'] = true;
    allProgress[levelId]['completedAt'] = DateTime.now().toIso8601String();
    
    await prefs.setString(_levelProgressKey, jsonEncode(allProgress));
  }

  /// Get current level for a subject
  Future<int> getCurrentLevel(String subject) async {
    final currentXP = await _xpService.getXP(subject);
    return _xpService.getPlayerLevelFromXP(currentXP);
  }

  /// Initialize cache for better performance
  Future<void> initializeCache() async {
    try {
      await _ensureMigrationCompleted();
      debugPrint('[UnifiedLevelService] Cache initialized');
    } catch (e) {
      debugPrint('[UnifiedLevelService] Cache initialization error: $e');
    }
  }

  /// Ensure migration is completed
  Future<void> _ensureMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final migrationCompleted = prefs.getBool(_migrationKey) ?? false;
    
    if (!migrationCompleted) {
      await _migrateExistingData();
      await prefs.setBool(_migrationKey, true);
    }
  }

  /// Preload levels for better performance
  Future<void> preloadLevelsForSubject(SubjectType subject, {int count = 10}) async {
    await _levelCache.preloadLevelsForSubject(subject, count: count);
  }

  /// Get cache performance statistics
  Map<String, dynamic> getCacheStats() {
    return _levelCache.getCacheStats();
  }

  /// Clear level cache
  Future<void> clearLevelCache() async {
    await _levelCache.clearCache();
  }

  /// Record game completion and check for unlocks
  Future<Map<String, dynamic>> recordGameCompletion({
    required String levelId,
    required double accuracy,
    required int score,
    required int totalTime,
    required int questionsAnswered,
  }) async {
    // Award XP using UnifiedXPService
    final levelInfo = getLevelInfo(levelId);
    final difficulty = levelInfo?['difficulty'] ?? 1;
    final xpAwarded = UnifiedXPService.getInstance().calculateLessonXP(difficulty);
    
    // Update progress data
    await _updateLevelProgress(
      levelId: levelId,
      accuracy: accuracy,
      score: score,
      totalTime: totalTime,
      questionsAnswered: questionsAnswered,
      xpAwarded: xpAwarded,
    );

    // Check for new unlocks
    final newUnlocks = await _checkAndUnlockLevels();
    
    // Get current player stats
    final stats = await getPlayerStats();
    
    return {
      'xpAwarded': xpAwarded,
      'currentXP': stats['totalXP'],
      'currentLevel': stats['playerLevel'],
      'newUnlocks': newUnlocks,
      'canProgress': accuracy >= _minAccuracyForProgression,
      'performance': _getPerformanceRating(accuracy),
    };
  }

  /// Get player statistics
  Future<Map<String, dynamic>> getPlayerStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsData = prefs.getString(_playerStatsKey);
    
    if (statsData == null) {
      return {
        'totalXP': 0,
        'playerLevel': 1,
        'gamesPlayed': 0,
        'averageAccuracy': 0.0,
        'totalTime': 0,
        'streakDays': 0,
      };
    }
    
    return jsonDecode(statsData);
  }

  /// Get level progress for a specific level
  Future<Map<String, dynamic>> getLevelProgress(String levelId) async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = prefs.getString(_levelProgressKey);
    
    if (progressData == null) return {};
    
    final Map<String, dynamic> allProgress = jsonDecode(progressData);
    return allProgress[levelId] ?? {};
  }

  /// Get next recommended level for a subject
  Future<String?> getNextRecommendedLevel(SubjectType subject) async {
    final unlockedLevels = await getUnlockedLevels(subject: subject);
    final allLevels = getLevelsForSubject(subject);
    
    // Find the first locked level that has prerequisites met
    for (String levelId in allLevels) {
      if (!unlockedLevels.contains(levelId)) {
        final levelInfo = getLevelInfo(levelId);
        final prerequisites = List<String>.from(levelInfo?['prerequisites'] ?? []);
        
        // Check if all prerequisites are unlocked
        bool prerequisitesMet = true;
        for (String prereq in prerequisites) {
          if (!unlockedLevels.contains(prereq)) {
            prerequisitesMet = false;
            break;
          }
        }
        
        if (prerequisitesMet) {
          return levelId;
        }
      }
    }
    
    return null; // All levels unlocked or no valid next level
  }

  /// Private helper methods
  
  bool _isStartingLevel(String levelId) {
    return levelId.endsWith('_1'); // All level 1s are starting levels
  }

  List<String> _getStartingLevels(SubjectType? subject) {
    if (subject == null) {
      return _levelDefinitions.keys.where(_isStartingLevel).toList();
    }
    return _levelDefinitions.keys
        .where((levelId) => 
            _isStartingLevel(levelId) && 
            _levelDefinitions[levelId]?['subject'] == subject.name)
        .toList();
  }

  Future<void> _unlockStartingLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> unlocked = {};
    
    for (String levelId in _levelDefinitions.keys) {
      if (_isStartingLevel(levelId)) {
        unlocked[levelId] = true;
      }
    }
    
    await prefs.setString(_unlockedLevelsKey, jsonEncode(unlocked));
  }

  Future<void> _updateLevelProgress({
    required String levelId,
    required double accuracy,
    required int score,
    required int totalTime,
    required int questionsAnswered,
    required int xpAwarded,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = prefs.getString(_levelProgressKey);
    
    Map<String, dynamic> allProgress = {};
    if (progressData != null) {
      allProgress = jsonDecode(progressData);
    }
    
    Map<String, dynamic> levelProgress = allProgress[levelId] ?? {
      'gamesPlayed': 0,
      'totalScore': 0,
      'totalTime': 0,
      'totalQuestions': 0,
      'totalXP': 0,
      'bestAccuracy': 0.0,
      'averageAccuracy': 0.0,
      'completionCount': 0,
    };
    
    // Update stats
    levelProgress['gamesPlayed']++;
    levelProgress['totalScore'] += score;
    levelProgress['totalTime'] += totalTime;
    levelProgress['totalQuestions'] += questionsAnswered;
    levelProgress['totalXP'] += xpAwarded;
    levelProgress['bestAccuracy'] = max(levelProgress['bestAccuracy'] as double, accuracy);
    
    // Calculate average accuracy
    final previousTotal = levelProgress['averageAccuracy'] * (levelProgress['gamesPlayed'] - 1);
    levelProgress['averageAccuracy'] = (previousTotal + accuracy) / levelProgress['gamesPlayed'];
    
    if (accuracy >= _minAccuracyForProgression) {
      levelProgress['completionCount']++;
    }
    
    allProgress[levelId] = levelProgress;
    await prefs.setString(_levelProgressKey, jsonEncode(allProgress));
    
    // Update player stats
    await _updatePlayerStats(xpAwarded, accuracy, totalTime);
  }

  Future<void> _updatePlayerStats(int xpAwarded, double accuracy, int totalTime) async {
    final prefs = await SharedPreferences.getInstance();
    final statsData = prefs.getString(_playerStatsKey);
    
    Map<String, dynamic> stats = {};
    if (statsData != null) {
      stats = jsonDecode(statsData);
    } else {
      stats = {
        'totalXP': 0,
        'playerLevel': 1,
        'gamesPlayed': 0,
        'averageAccuracy': 0.0,
        'totalTime': 0,
        'streakDays': 0,
      };
    }
    
    // Update stats
    stats['totalXP'] += xpAwarded;
    stats['gamesPlayed']++;
    stats['totalTime'] += totalTime;
    
    // Calculate average accuracy
    final previousTotal = stats['averageAccuracy'] * (stats['gamesPlayed'] - 1);
    stats['averageAccuracy'] = (previousTotal + accuracy) / stats['gamesPlayed'];
    
    // Calculate player level from total XP
    stats['playerLevel'] = UnifiedXPService.getInstance().getPlayerLevelFromXP(stats['totalXP']);
    
    await prefs.setString(_playerStatsKey, jsonEncode(stats));
  }

  Future<List<String>> _checkAndUnlockLevels() async {
    final List<String> newUnlocks = [];
    final stats = await getPlayerStats();
    final currentXP = stats['totalXP'];
    
    for (String levelId in _levelDefinitions.keys) {
      final isUnlocked = await _levelUnlockService.isLevelUnlocked(levelId);
      if (!isUnlocked) {
        final levelInfo = getLevelInfo(levelId)!;
        final xpRequired = levelInfo['xpRequired'];
        final prerequisites = List<String>.from(levelInfo['prerequisites']);
        
        // Check XP requirement
        if (currentXP >= xpRequired) {
          // Check prerequisites
          bool prerequisitesMet = true;
          for (String prereq in prerequisites) {
            final prereqUnlocked = await _levelUnlockService.isLevelUnlocked(prereq);
            if (!prereqUnlocked) {
              prerequisitesMet = false;
              break;
            }
          }
          
          if (prerequisitesMet) {
            await _unlockLevel(levelId);
            newUnlocks.add(levelId);
          }
        }
      }
    }
    
    return newUnlocks;
  }

  Future<void> _unlockLevel(String levelId) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedData = prefs.getString(_unlockedLevelsKey);
    
    Map<String, dynamic> unlocked = {};
    if (unlockedData != null) {
      unlocked = jsonDecode(unlockedData);
    }
    
    unlocked[levelId] = true;
    await prefs.setString(_unlockedLevelsKey, jsonEncode(unlocked));
    
    // Sync with cloud if available
    try {
      final levelInfo = getLevelInfo(levelId);
      if (levelInfo != null) {
        await _firebaseService.unlockLevel(levelInfo['subject'], levelId);
      }
    } catch (e) {
      print('Failed to sync level unlock to cloud: $e');
    }
  }

  String _getPerformanceRating(double accuracy) {
    if (accuracy >= _excellentAccuracy) return 'excellent';
    if (accuracy >= _goodAccuracy) return 'good';
    if (accuracy >= _minAccuracyForProgression) return 'satisfactory';
    return 'needs_improvement';
  }

  /// Migrate data from existing services
  Future<void> _migrateExistingData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Migrate from LevelProgressionService
    final oldProgressData = prefs.getString('level_progression_data');
    final oldUnlockedData = prefs.getString('unlocked_levels');
    final oldXpData = prefs.getString('xp_data');
    
    // Migrate from XpProgressionService
    final oldXpProgressData = prefs.getString('xp_progression_data');
    final oldLevelProgressData = prefs.getString('level_progress_data');
    
    Map<String, dynamic> migratedStats = {
      'totalXP': 0,
      'playerLevel': 1,
      'gamesPlayed': 0,
      'averageAccuracy': 0.0,
      'totalTime': 0,
      'streakDays': 0,
    };
    
    Map<String, dynamic> migratedUnlocked = {};
    
    // Process old XP data
    if (oldXpData != null) {
      try {
        final Map<String, dynamic> xpData = jsonDecode(oldXpData);
        int totalXP = 0;
        for (var value in xpData.values) {
          if (value is int) totalXP += value;
        }
        migratedStats['totalXP'] = totalXP;
        migratedStats['playerLevel'] = UnifiedXPService.getInstance().getPlayerLevelFromXP(totalXP);
      } catch (e) {
        print('Error migrating XP data: $e');
      }
    }
    
    // Process old unlocked levels
    if (oldUnlockedData != null) {
      try {
        final dynamic unlockedData = jsonDecode(oldUnlockedData);
        if (unlockedData is Map) {
          // Convert old format to new format
          for (var entry in unlockedData.entries) {
            if (entry.value == true) {
              // Try to map old level IDs to new format
              String newLevelId = _mapOldLevelId(entry.key);
              migratedUnlocked[newLevelId] = true;
            }
          }
        } else if (unlockedData is List) {
          // Handle list format
          for (var levelId in unlockedData) {
            String newLevelId = _mapOldLevelId(levelId.toString());
            migratedUnlocked[newLevelId] = true;
          }
        }
      } catch (e) {
        print('Error migrating unlocked levels: $e');
      }
    }
    
    // Ensure starting levels are unlocked
    for (String levelId in _levelDefinitions.keys) {
      if (_isStartingLevel(levelId)) {
        migratedUnlocked[levelId] = true;
      }
    }
    
    // Save migrated data
    await prefs.setString(_playerStatsKey, jsonEncode(migratedStats));
    await prefs.setString(_unlockedLevelsKey, jsonEncode(migratedUnlocked));
    
    print('Data migration completed. Migrated ${migratedUnlocked.length} unlocked levels and ${migratedStats['totalXP']} total XP.');
  }

  String _mapOldLevelId(String oldId) {
    // Map old level IDs to new format
    if (oldId.contains('math')) {
      if (oldId.contains('basic') || oldId.contains('arithmetic')) return 'math_1';
      if (oldId.contains('fraction')) return 'math_5';
      if (oldId.contains('decimal')) return 'math_5';
      if (oldId.contains('addition') || oldId.contains('subtraction')) return 'math_2';
      if (oldId.contains('multiplication')) return 'math_3';
      if (oldId.contains('division')) return 'math_4';
    }
    
    if (oldId.contains('science')) {
      if (oldId.contains('living') || oldId.contains('animal') || oldId.contains('plant')) return 'science_1';
      if (oldId.contains('body') || oldId.contains('human')) return 'science_2';
    }
    
    if (oldId.contains('english')) {
      if (oldId.contains('letter') || oldId.contains('alphabet')) return 'english_1';
      if (oldId.contains('word') || oldId.contains('spelling')) return 'english_2';
    }
    
    // Default mapping - try to extract subject and level number
    if (oldId.contains('_')) {
      final parts = oldId.split('_');
      if (parts.length >= 2) {
        final subject = parts[0];
        // Default to level 1 for unknown mappings
        return '${subject}_1';
      }
    }
    
    // Fallback
    return 'math_1';
  }

  /// Triggers unlock animation for a newly unlocked level
  Future<void> _triggerLevelUnlockAnimation({
    required String subject,
    required int level,
    required int xpReward,
  }) async {
    try {
      final levelId = '${subject.toLowerCase()}_$level';
      final levelInfo = getLevelInfo(levelId);
      
      final unlockEvent = _unlockAnimationService.createSingleLevelUnlockEvent(
        levelId: levelId,
        levelName: levelInfo?['displayName'] ?? 'Level $level',
        subjectName: _formatSubjectName(subject),
        xpReward: xpReward,
        gemReward: _calculateGemReward(level),
        metadata: {
          'subject': subject,
          'level': level,
          'unlockType': 'level_progression',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      _unlockAnimationService.queueUnlockEvent(unlockEvent);
    } catch (e) {
      // Log error but don't interrupt progression flow
      print('Error triggering unlock animation: $e');
    }
  }

  /// Formats subject name for display
  String _formatSubjectName(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return 'Mathematics';
      case 'science':
        return 'Science';
      case 'english':
        return 'English';
      default:
        return subject.substring(0, 1).toUpperCase() + subject.substring(1);
    }
  }

  /// Calculates gem reward based on level
  int _calculateGemReward(int level) {
    // Base gem reward with bonus for higher levels
    return 10 + (level ~/ 5) * 5;
  }
}