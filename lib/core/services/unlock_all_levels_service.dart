import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';

/// Utility service to unlock all levels for testing and development purposes
class UnlockAllLevelsService {
  static final UnlockAllLevelsService _instance = UnlockAllLevelsService._internal();
  factory UnlockAllLevelsService() => _instance;
  UnlockAllLevelsService._internal();

  /// Unlock all levels across all subjects and services
  Future<void> unlockAllLevels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all available level definitions from UnifiedLevelService
      final allLevelIds = _getAllLevelIds();
      
      // 1. Update LevelUnlockService storage (uses 'unlocked_levels' key with JSON array)
      await prefs.setString('unlocked_levels', jsonEncode(allLevelIds));
      
      // 2. Update UnifiedLevelService storage (uses 'unified_unlocked_levels' key with JSON object)
      final unifiedUnlocked = <String, bool>{};
      for (String levelId in allLevelIds) {
        unifiedUnlocked[levelId] = true;
      }
      await prefs.setString('unified_unlocked_levels', jsonEncode(unifiedUnlocked));
      
      // 3. Update LevelProgressionService storage (uses subject-specific keys)
      await _unlockLevelProgressionLevels(prefs);
      
      // 4. Set high XP to ensure all requirements are met
      await prefs.setInt('total_xp', 10000);
      
      // 5. Update player stats to reflect unlocked state
      final playerStats = {
        'totalXP': 10000,
        'playerLevel': 10,
        'gamesPlayed': 100,
        'averageAccuracy': 0.95,
        'totalTime': 0,
        'streakDays': 7,
      };
      await prefs.setString('unified_player_stats', jsonEncode(playerStats));
      
      print('✅ Successfully unlocked all ${allLevelIds.length} levels!');
      print('📊 Set player XP to 10,000 and level to 10');
      print('🎮 All games should now be accessible');
      
    } catch (e) {
      print('❌ Error unlocking all levels: $e');
      rethrow;
    }
  }

  /// Get all available level IDs from the app
  List<String> _getAllLevelIds() {
    final allLevels = <String>[];
    
    // Mathematics levels (from UnifiedLevelService definitions)
    allLevels.addAll([
      'math_1', 'math_2', 'math_3', 'math_4', 'math_5',
      'math_6', 'math_7', 'math_8', 'math_9', 'math_10'
    ]);
    
    // Science levels
    allLevels.addAll([
      'science_1', 'science_2', 'science_3', 'science_4', 'science_5',
      'science_6', 'science_7', 'science_8', 'science_9', 'science_10'
    ]);
    
    // English levels
    allLevels.addAll([
      'english_1', 'english_2', 'english_3', 'english_4', 'english_5',
      'english_6', 'english_7', 'english_8', 'english_9', 'english_10'
    ]);
    
    // Programming levels
    allLevels.addAll([
      'programming_1', 'programming_2', 'programming_3', 'programming_4', 'programming_5',
      'programming_6', 'programming_7', 'programming_8', 'programming_9', 'programming_10'
    ]);
    
    // History levels
    allLevels.addAll([
      'history_1', 'history_2', 'history_3', 'history_4', 'history_5',
      'history_6', 'history_7', 'history_8', 'history_9', 'history_10'
    ]);
    
    // Legacy level IDs from LevelUnlockService
    allLevels.addAll([
      'math_basic_arithmetic', 'math_fractions', 'math_decimals', 'math_percentages',
      'math_algebra_basics', 'math_equations', 'math_geometry_basics', 'math_area_perimeter',
      'science_scientific_method', 'science_matter_states', 'science_atoms_molecules',
      'science_chemical_reactions', 'science_forces_motion', 'science_energy_types',
      'science_ecosystems', 'science_human_body',
      'programming_variables', 'programming_conditionals', 'programming_loops',
      'programming_functions', 'programming_arrays', 'programming_objects',
      'history_ancient_civilizations', 'history_medieval_period', 'history_renaissance',
      'history_industrial_revolution', 'history_modern_era'
    ]);
    
    return allLevels;
  }

  /// Unlock levels for LevelProgressionService (uses different storage format)
  Future<void> _unlockLevelProgressionLevels(SharedPreferences prefs) async {
    final subjects = [
      SubjectType.math,
      SubjectType.science,
      SubjectType.english,
      SubjectType.computerScience,
      SubjectType.history
    ];
    
    final unlockedData = <String, bool>{};
    
    // Unlock all levels (1-10) for each subject
    for (final subject in subjects) {
      for (int level = 1; level <= 10; level++) {
        final key = '${subject.name.toLowerCase()}_$level';
        unlockedData[key] = true;
        
        // Also add skill-specific keys if they exist
        final skillKey = '${subject.name.toLowerCase()}_skill_$level';
        unlockedData[skillKey] = true;
      }
    }
    
    // Store in the format expected by LevelProgressionService
    await prefs.setString('unlocked_levels_progression', jsonEncode(unlockedData));
  }

  /// Check current unlock status
  Future<Map<String, dynamic>> getUnlockStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final levelUnlockData = prefs.getString('unlocked_levels');
      final unifiedUnlockData = prefs.getString('unified_unlocked_levels');
      final totalXP = prefs.getInt('total_xp') ?? 0;
      
      final levelUnlockCount = levelUnlockData != null 
          ? (jsonDecode(levelUnlockData) as List).length 
          : 0;
      
      final unifiedUnlockCount = unifiedUnlockData != null
          ? (jsonDecode(unifiedUnlockData) as Map).length
          : 0;
      
      return {
        'levelUnlockService_count': levelUnlockCount,
        'unifiedLevelService_count': unifiedUnlockCount,
        'totalXP': totalXP,
        'allLevelsUnlocked': levelUnlockCount > 50 && unifiedUnlockCount > 50,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'allLevelsUnlocked': false,
      };
    }
  }
}