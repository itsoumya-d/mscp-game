import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/unlock_event.dart';
import 'firebase_service.dart';
import 'cloud_sync_service.dart';
import 'unlock_animation_service.dart';

class LevelUnlockService {
  static final LevelUnlockService _instance = LevelUnlockService._internal();
  factory LevelUnlockService() => _instance;
  LevelUnlockService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final CloudSyncService _cloudSyncService = CloudSyncService();
  final UnlockAnimationService _animationService = UnlockAnimationService.instance;

  // Level unlock requirements
  static const Map<String, Map<String, dynamic>> _levelRequirements = {
    // Mathematics levels
    'math_basic_arithmetic': {
      'xpRequired': 0,
      'prerequisites': <String>[],
      'minAccuracy': 0.0,
    },
    'math_fractions': {
      'xpRequired': 100,
      'prerequisites': ['math_basic_arithmetic'],
      'minAccuracy': 0.7,
    },
    'math_decimals': {
      'xpRequired': 200,
      'prerequisites': ['math_fractions'],
      'minAccuracy': 0.75,
    },
    'math_percentages': {
      'xpRequired': 300,
      'prerequisites': ['math_decimals'],
      'minAccuracy': 0.75,
    },
    'math_algebra_basics': {
      'xpRequired': 500,
      'prerequisites': ['math_percentages'],
      'minAccuracy': 0.8,
    },
    'math_equations': {
      'xpRequired': 700,
      'prerequisites': ['math_algebra_basics'],
      'minAccuracy': 0.8,
    },
    'math_geometry_basics': {
      'xpRequired': 400,
      'prerequisites': ['math_basic_arithmetic'],
      'minAccuracy': 0.75,
    },
    'math_area_perimeter': {
      'xpRequired': 600,
      'prerequisites': ['math_geometry_basics'],
      'minAccuracy': 0.8,
    },

    // Science levels
    'science_scientific_method': {
      'xpRequired': 0,
      'prerequisites': <String>[],
      'minAccuracy': 0.0,
    },
    'science_matter_states': {
      'xpRequired': 150,
      'prerequisites': ['science_scientific_method'],
      'minAccuracy': 0.7,
    },
    'science_atoms_molecules': {
      'xpRequired': 300,
      'prerequisites': ['science_matter_states'],
      'minAccuracy': 0.75,
    },
    'science_chemical_reactions': {
      'xpRequired': 500,
      'prerequisites': ['science_atoms_molecules'],
      'minAccuracy': 0.8,
    },
    'science_forces_motion': {
      'xpRequired': 250,
      'prerequisites': ['science_scientific_method'],
      'minAccuracy': 0.7,
    },
    'science_energy_types': {
      'xpRequired': 400,
      'prerequisites': ['science_forces_motion'],
      'minAccuracy': 0.75,
    },
    'science_ecosystems': {
      'xpRequired': 350,
      'prerequisites': ['science_scientific_method'],
      'minAccuracy': 0.7,
    },
    'science_human_body': {
      'xpRequired': 450,
      'prerequisites': ['science_ecosystems'],
      'minAccuracy': 0.75,
    },

    // Programming levels
    'programming_variables': {
      'xpRequired': 0,
      'prerequisites': <String>[],
      'minAccuracy': 0.0,
    },
    'programming_conditionals': {
      'xpRequired': 100,
      'prerequisites': ['programming_variables'],
      'minAccuracy': 0.7,
    },
    'programming_loops': {
      'xpRequired': 200,
      'prerequisites': ['programming_conditionals'],
      'minAccuracy': 0.75,
    },
    'programming_functions': {
      'xpRequired': 350,
      'prerequisites': ['programming_loops'],
      'minAccuracy': 0.8,
    },
    'programming_arrays': {
      'xpRequired': 500,
      'prerequisites': ['programming_functions'],
      'minAccuracy': 0.8,
    },
    'programming_objects': {
      'xpRequired': 700,
      'prerequisites': ['programming_arrays'],
      'minAccuracy': 0.85,
    },

    // History levels
    'history_ancient_civilizations': {
      'xpRequired': 0,
      'prerequisites': <String>[],
      'minAccuracy': 0.0,
    },
    'history_medieval_period': {
      'xpRequired': 200,
      'prerequisites': ['history_ancient_civilizations'],
      'minAccuracy': 0.7,
    },
    'history_renaissance': {
      'xpRequired': 400,
      'prerequisites': ['history_medieval_period'],
      'minAccuracy': 0.75,
    },
    'history_industrial_revolution': {
      'xpRequired': 600,
      'prerequisites': ['history_renaissance'],
      'minAccuracy': 0.8,
    },
    'history_modern_era': {
      'xpRequired': 800,
      'prerequisites': ['history_industrial_revolution'],
      'minAccuracy': 0.8,
    },
  };

  // Check if a level is unlocked
  Future<bool> isLevelUnlocked(String levelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlockedLevelsJson = prefs.getString('unlocked_levels') ?? '[]';
      final List<dynamic> unlockedLevels = jsonDecode(unlockedLevelsJson);
      
      return unlockedLevels.contains(levelId);
    } catch (e) {
      print('Error checking level unlock status: $e');
      return false;
    }
  }

  // Get all unlocked levels
  Future<List<String>> getUnlockedLevels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlockedLevelsJson = prefs.getString('unlocked_levels') ?? '[]';
      final List<dynamic> unlockedLevels = jsonDecode(unlockedLevelsJson);
      
      return unlockedLevels.cast<String>();
    } catch (e) {
      print('Error getting unlocked levels: $e');
      return [];
    }
  }

  // Check and unlock levels based on current progress
  Future<List<String>> checkAndUnlockLevels() async {
    final newlyUnlocked = <String>[];
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentXP = prefs.getInt('total_xp') ?? 0;
      final unlockedLevels = await getUnlockedLevels();
      
      for (final entry in _levelRequirements.entries) {
        final levelId = entry.key;
        final requirements = entry.value;
        
        // Skip if already unlocked
        if (unlockedLevels.contains(levelId)) continue;
        
        // Check if requirements are met
        if (await _meetsRequirements(levelId, currentXP, requirements)) {
          await _unlockLevel(levelId);
          newlyUnlocked.add(levelId);
        }
      }
      
      return newlyUnlocked;
    } catch (e) {
      print('Error checking level unlocks: $e');
      return [];
    }
  }

  Future<bool> _meetsRequirements(String levelId, int currentXP, Map<String, dynamic> requirements) async {
    // Check XP requirement
    final xpRequired = requirements['xpRequired'] as int;
    if (currentXP < xpRequired) return false;
    
    // Check prerequisites
    final prerequisites = requirements['prerequisites'] as List<String>;
    final unlockedLevels = await getUnlockedLevels();
    
    for (final prerequisite in prerequisites) {
      if (!unlockedLevels.contains(prerequisite)) return false;
    }
    
    // Check minimum accuracy for prerequisite levels
    final minAccuracy = requirements['minAccuracy'] as double;
    if (minAccuracy > 0) {
      for (final prerequisite in prerequisites) {
        final accuracy = await _getLevelAccuracy(prerequisite);
        if (accuracy < minAccuracy) return false;
      }
    }
    
    return true;
  }

  Future<double> _getLevelAccuracy(String levelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accuracyKey = 'level_accuracy_$levelId';
      return prefs.getDouble(accuracyKey) ?? 0.0;
    } catch (e) {
      print('Error getting level accuracy: $e');
      return 0.0;
    }
  }

  Future<void> _unlockLevel(String levelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlockedLevelsJson = prefs.getString('unlocked_levels') ?? '[]';
      final List<dynamic> unlockedLevels = jsonDecode(unlockedLevelsJson);
      
      if (!unlockedLevels.contains(levelId)) {
        unlockedLevels.add(levelId);
        await prefs.setString('unlocked_levels', jsonEncode(unlockedLevels));
        
        // Sync to cloud
        if (_firebaseService.isLoggedIn) {
          final parts = levelId.split('_');
          if (parts.length >= 2) {
            final subjectId = parts[0];
            final skillId = parts.sublist(1).join('_');
            await _firebaseService.unlockLevel(subjectId, skillId);
          }
        }
        
        // Trigger unlock animation
        await _triggerUnlockAnimation(levelId);
        
        print('Level unlocked: $levelId');
      }
    } catch (e) {
      print('Error unlocking level: $e');
    }
  }

  // Update level performance after completing a game session
  Future<void> updateLevelPerformance(String levelId, double accuracy, int score, int timeSpent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Update accuracy (running average)
      final accuracyKey = 'level_accuracy_$levelId';
      final attemptsKey = 'level_attempts_$levelId';
      final bestScoreKey = 'level_best_score_$levelId';
      final bestTimeKey = 'level_best_time_$levelId';
      
      final currentAccuracy = prefs.getDouble(accuracyKey) ?? 0.0;
      final attempts = prefs.getInt(attemptsKey) ?? 0;
      final bestScore = prefs.getInt(bestScoreKey) ?? 0;
      final bestTime = prefs.getInt(bestTimeKey) ?? 0;
      
      // Calculate new running average accuracy
      final newAccuracy = (currentAccuracy * attempts + accuracy) / (attempts + 1);
      
      await prefs.setDouble(accuracyKey, newAccuracy);
      await prefs.setInt(attemptsKey, attempts + 1);
      
      // Update best score and time
      if (score > bestScore) {
        await prefs.setInt(bestScoreKey, score);
      }
      
      if (bestTime == 0 || timeSpent < bestTime) {
        await prefs.setInt(bestTimeKey, timeSpent);
      }
      
      // Check for new unlocks after performance update
      await checkAndUnlockLevels();
      
    } catch (e) {
      print('Error updating level performance: $e');
    }
  }

  // Get level progress information
  Future<Map<String, dynamic>> getLevelProgress(String levelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requirements = _levelRequirements[levelId];
      
      if (requirements == null) {
        return {'error': 'Level not found'};
      }
      
      final currentXP = prefs.getInt('total_xp') ?? 0;
      final isUnlocked = await isLevelUnlocked(levelId);
      final accuracy = await _getLevelAccuracy(levelId);
      final attempts = prefs.getInt('level_attempts_$levelId') ?? 0;
      final bestScore = prefs.getInt('level_best_score_$levelId') ?? 0;
      final bestTime = prefs.getInt('level_best_time_$levelId') ?? 0;
      
      final xpRequired = requirements['xpRequired'] as int;
      final prerequisites = requirements['prerequisites'] as List<String>;
      final minAccuracy = requirements['minAccuracy'] as double;
      
      // Check prerequisite status
      final unlockedLevels = await getUnlockedLevels();
      final prerequisitesMet = prerequisites.every((prereq) => unlockedLevels.contains(prereq));
      
      return {
        'levelId': levelId,
        'isUnlocked': isUnlocked,
        'xpRequired': xpRequired,
        'currentXP': currentXP,
        'xpProgress': currentXP >= xpRequired,
        'prerequisites': prerequisites,
        'prerequisitesMet': prerequisitesMet,
        'minAccuracy': minAccuracy,
        'currentAccuracy': accuracy,
        'accuracyMet': accuracy >= minAccuracy,
        'attempts': attempts,
        'bestScore': bestScore,
        'bestTime': bestTime,
        'canUnlock': currentXP >= xpRequired && prerequisitesMet,
      };
    } catch (e) {
      print('Error getting level progress: $e');
      return {'error': 'Failed to get level progress'};
    }
  }

  // Get next available levels to unlock
  Future<List<Map<String, dynamic>>> getNextAvailableLevels() async {
    final nextLevels = <Map<String, dynamic>>[];
    
    try {
      final currentXP = (await SharedPreferences.getInstance()).getInt('total_xp') ?? 0;
      final unlockedLevels = await getUnlockedLevels();
      
      for (final entry in _levelRequirements.entries) {
        final levelId = entry.key;
        final requirements = entry.value;
        
        // Skip if already unlocked
        if (unlockedLevels.contains(levelId)) continue;
        
        final xpRequired = requirements['xpRequired'] as int;
        final prerequisites = requirements['prerequisites'] as List<String>;
        
        // Check if prerequisites are met
        final prerequisitesMet = prerequisites.every((prereq) => unlockedLevels.contains(prereq));
        
        if (prerequisitesMet) {
          nextLevels.add({
            'levelId': levelId,
            'xpRequired': xpRequired,
            'xpNeeded': xpRequired - currentXP,
            'canUnlockNow': currentXP >= xpRequired,
          });
        }
      }
      
      // Sort by XP required
      nextLevels.sort((a, b) => (a['xpRequired'] as int).compareTo(b['xpRequired'] as int));
      
      return nextLevels.take(5).toList(); // Return top 5 next levels
    } catch (e) {
      print('Error getting next available levels: $e');
      return [];
    }
  }

  // Initialize with default unlocked levels
  Future<void> initializeDefaultLevels() async {
    try {
      final unlockedLevels = await getUnlockedLevels();
      
      if (unlockedLevels.isEmpty) {
        // Unlock starting levels for each subject
        final startingLevels = [
          'math_basic_arithmetic',
          'science_scientific_method',
          'programming_variables',
          'history_ancient_civilizations',
        ];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('unlocked_levels', jsonEncode(startingLevels));
        
        print('Initialized default levels: $startingLevels');
      }
    } catch (e) {
      print('Error initializing default levels: $e');
    }
  }

  // Sync unlocked levels with cloud
  Future<void> syncUnlockedLevels() async {
    if (!_firebaseService.isLoggedIn) return;
    
    try {
      final localUnlocked = await getUnlockedLevels();
      
      // Get cloud unlocked levels for each subject
      final subjects = ['math', 'science', 'programming', 'history'];
      final Set<String> cloudUnlocked = {};
      
      for (final subject in subjects) {
        final subjectLevels = await _firebaseService.getUnlockedLevels(subject);
        for (final level in subjectLevels) {
          cloudUnlocked.add('${subject}_$level');
        }
      }
      
      // Merge local and cloud
      final allUnlocked = {...localUnlocked, ...cloudUnlocked}.toList();
      
      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('unlocked_levels', jsonEncode(allUnlocked));
      
      // Update cloud with any local-only unlocks
      for (final levelId in localUnlocked) {
        if (!cloudUnlocked.contains(levelId)) {
          final parts = levelId.split('_');
          if (parts.length >= 2) {
            final subjectId = parts[0];
            final skillId = parts.sublist(1).join('_');
            await _firebaseService.unlockLevel(subjectId, skillId);
          }
        }
      }
      
    } catch (e) {
      print('Error syncing unlocked levels: $e');
    }
  }

  /// Trigger unlock animation for a newly unlocked level
  Future<void> _triggerUnlockAnimation(String levelId) async {
    try {
      // Parse level ID to extract subject and level info
      final parts = levelId.split('_');
      if (parts.length < 2) return;
      
      final subject = parts[0];
      final levelName = parts.sublist(1).join(' ').replaceAll('_', ' ');
      
      // Create unlock event
      final unlockEvent = _animationService.createLevelUnlockEvent(
        levelId: levelId,
        levelName: _formatLevelName(levelName),
        subject: _formatSubjectName(subject),
        description: 'You can now access ${_formatLevelName(levelName)} in ${_formatSubjectName(subject)}',
        xpReward: _calculateXpReward(levelId),
        gemReward: _calculateGemReward(levelId),
      );
      
      // Queue the unlock animation
      await _animationService.queueUnlockAnimation(unlockEvent);
      
    } catch (e) {
      print('Error triggering unlock animation: $e');
    }
  }

  /// Format level name for display
  String _formatLevelName(String levelName) {
    return levelName
        .split('_')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  /// Format subject name for display
  String _formatSubjectName(String subject) {
    switch (subject.toLowerCase()) {
      case 'math':
        return 'Mathematics';
      case 'science':
        return 'Science';
      case 'english':
        return 'English';
      case 'history':
        return 'History';
      case 'geography':
        return 'Geography';
      default:
        return subject[0].toUpperCase() + subject.substring(1);
    }
  }

  /// Calculate XP reward for unlocking a level
  int _calculateXpReward(String levelId) {
    // Base XP reward for unlocking a level
    int baseReward = 50;
    
    // Bonus XP for advanced levels
    if (levelId.contains('algebra') || levelId.contains('geometry')) {
      baseReward += 25;
    }
    if (levelId.contains('advanced') || levelId.contains('expert')) {
      baseReward += 50;
    }
    
    return baseReward;
  }

  /// Calculate gem reward for unlocking a level
  int _calculateGemReward(String levelId) {
    // Base gem reward for unlocking a level
    int baseReward = 2;
    
    // Bonus gems for milestone levels
    if (levelId.contains('algebra') || levelId.contains('geometry')) {
      baseReward += 3;
    }
    if (levelId.contains('advanced') || levelId.contains('expert')) {
      baseReward += 5;
    }
    
    return baseReward;
  }
}