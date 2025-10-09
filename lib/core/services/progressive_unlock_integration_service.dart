import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/skill_node.dart';
import '../models/learning_path.dart';
import '../models/unlock_condition.dart';
import 'skill_dependency_manager.dart';
import 'progressive_unlock_engine.dart';
import 'adaptive_difficulty_calculator.dart';
import 'personalized_path_generator.dart';
import 'database_migration_service.dart';

/// Integration service that connects the progressive unlock system
/// with existing UnifiedLevelService and XPProgressionService
class ProgressiveUnlockIntegrationService {
  static ProgressiveUnlockIntegrationService? _instance;
  static ProgressiveUnlockIntegrationService get instance => 
      _instance ??= ProgressiveUnlockIntegrationService._();
  
  ProgressiveUnlockIntegrationService._();

  // Core services
  late SkillDependencyManager _skillManager;
  late ProgressiveUnlockEngine _unlockEngine;
  late AdaptiveDifficultyCalculator _difficultyCalculator;
  late PersonalizedPathGenerator _pathGenerator;
  late DatabaseMigrationService _databaseService;

  // Integration state
  bool _isInitialized = false;
  Map<String, dynamic> _integrationCache = {};
  
  static const String _cacheKey = 'progressive_unlock_integration_cache';
  static const String _legacyMigrationKey = 'legacy_system_migration_completed';

  /// Initialize the integration service
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('[ProgressiveIntegration] Initializing integration service...');

    try {
      // Initialize database migration service first
      _databaseService = DatabaseMigrationService.instance;
      await _databaseService.initialize();

      // Initialize core services
      _skillManager = SkillDependencyManager.instance;
      await _skillManager.initialize();

      _unlockEngine = ProgressiveUnlockEngine.instance;
      await _unlockEngine.initialize();

      _difficultyCalculator = AdaptiveDifficultyCalculator.instance;
      await _difficultyCalculator.initialize();

      _pathGenerator = PersonalizedPathGenerator.instance;
      await _pathGenerator.initialize();

      // Load integration cache
      await _loadIntegrationCache();

      // Perform legacy system migration if needed
      await _migrateLegacySystem();

      _isInitialized = true;
      print('[ProgressiveIntegration] Integration service initialized successfully');
    } catch (e) {
      print('[ProgressiveIntegration] Initialization error: $e');
      throw Exception('Failed to initialize progressive unlock integration: $e');
    }
  }

  /// Migrate data from legacy UnifiedLevelService and XPProgressionService
  Future<void> _migrateLegacySystem() async {
    final prefs = await SharedPreferences.getInstance();
    final migrationCompleted = prefs.getBool(_legacyMigrationKey) ?? false;

    if (migrationCompleted) {
      print('[ProgressiveIntegration] Legacy system migration already completed');
      return;
    }

    print('[ProgressiveIntegration] Starting legacy system migration...');

    try {
      // Migrate user level progress
      await _migrateUserLevelProgress();
      
      // Migrate XP progression data
      await _migrateXPProgressionData();
      
      // Migrate unlock history
      await _migrateUnlockHistory();
      
      // Create initial learning paths for existing users
      await _createInitialLearningPaths();

      // Mark migration as completed
      await prefs.setBool(_legacyMigrationKey, true);
      print('[ProgressiveIntegration] Legacy system migration completed successfully');
    } catch (e) {
      print('[ProgressiveIntegration] Legacy migration error: $e');
      throw Exception('Legacy system migration failed: $e');
    }
  }

  /// Migrate user level progress from UnifiedLevelService
  Future<void> _migrateUserLevelProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => 
      key.startsWith('unified_level_') || 
      key.startsWith('user_level_progress_')
    ).toList();

    int migratedEntries = 0;
    for (final key in keys) {
      try {
        final data = prefs.getString(key);
        if (data != null) {
          final jsonData = json.decode(data);
          await _processLevelProgressData(key, jsonData);
          migratedEntries++;
        }
      } catch (e) {
        print('[ProgressiveIntegration] Error migrating level progress key $key: $e');
      }
    }

    print('[ProgressiveIntegration] Migrated $migratedEntries level progress entries');
  }

  /// Process individual level progress data
  Future<void> _processLevelProgressData(String key, Map<String, dynamic> data) async {
    final userId = _extractUserIdFromKey(key);
    if (userId == null) return;

    // Extract level completion data
    final completedLevels = data['completedLevels'] as List<dynamic>? ?? [];
    final levelScores = data['levelScores'] as Map<String, dynamic>? ?? {};
    final levelTimes = data['levelTimes'] as Map<String, dynamic>? ?? {};

    for (final levelData in completedLevels) {
      if (levelData is Map<String, dynamic>) {
        final levelId = levelData['levelId'] ?? levelData['id'];
        if (levelId != null) {
          await _createUnlockRecord(
            userId,
            levelId,
            levelScores[levelId.toString()]?.toDouble() ?? 1.0,
            levelTimes[levelId.toString()] ?? DateTime.now().millisecondsSinceEpoch,
            'legacy_migration',
          );
        }
      }
    }

    // Update skill progress based on completed levels
    await _updateSkillProgressFromLevels(userId, completedLevels);
  }

  /// Migrate XP progression data
  Future<void> _migrateXPProgressionData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => 
      key.startsWith('xp_progression_') || 
      key.startsWith('user_xp_')
    ).toList();

    int migratedEntries = 0;
    for (final key in keys) {
      try {
        final data = prefs.getString(key);
        if (data != null) {
          final jsonData = json.decode(data);
          await _processXPProgressionData(key, jsonData);
          migratedEntries++;
        }
      } catch (e) {
        print('[ProgressiveIntegration] Error migrating XP data key $key: $e');
      }
    }

    print('[ProgressiveIntegration] Migrated $migratedEntries XP progression entries');
  }

  /// Process XP progression data
  Future<void> _processXPProgressionData(String key, Map<String, dynamic> data) async {
    final userId = _extractUserIdFromKey(key);
    if (userId == null) return;

    // Extract performance data for adaptive difficulty
    final subjectXP = data['subjectXP'] as Map<String, dynamic>? ?? {};
    final levelPerformance = data['levelPerformance'] as Map<String, dynamic>? ?? {};
    final streaks = data['streaks'] as Map<String, dynamic>? ?? {};

    // Create adaptive difficulty records
    for (final entry in levelPerformance.entries) {
      final levelId = int.tryParse(entry.key);
      if (levelId != null && entry.value is Map<String, dynamic>) {
        await _createAdaptiveDifficultyRecord(userId, levelId, entry.value);
      }
    }

    // Update user learning preferences based on XP data
    await _updateLearningPreferences(userId, subjectXP, streaks);
  }

  /// Migrate unlock history
  Future<void> _migrateUnlockHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => 
      key.startsWith('level_unlock_') || 
      key.startsWith('unlock_history_')
    ).toList();

    int migratedEntries = 0;
    for (final key in keys) {
      try {
        final data = prefs.getString(key);
        if (data != null) {
          final jsonData = json.decode(data);
          await _processUnlockHistoryData(key, jsonData);
          migratedEntries++;
        }
      } catch (e) {
        print('[ProgressiveIntegration] Error migrating unlock history key $key: $e');
      }
    }

    print('[ProgressiveIntegration] Migrated $migratedEntries unlock history entries');
  }

  /// Process unlock history data
  Future<void> _processUnlockHistoryData(String key, Map<String, dynamic> data) async {
    final parts = key.split('_');
    if (parts.length < 3) return;

    final userId = parts[2];
    final levelId = int.tryParse(parts[3] ?? '0') ?? 0;

    await _createUnlockRecord(
      userId,
      levelId,
      data['score']?.toDouble() ?? 1.0,
      data['unlockedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      data['method'] ?? 'legacy_unlock',
    );
  }

  /// Create initial learning paths for existing users
  Future<void> _createInitialLearningPaths() async {
    final db = _databaseService.database;
    if (db == null) return;

    // Get all users with learning preferences
    final users = await db.query('user_learning_preferences');
    
    int pathsCreated = 0;
    for (final user in users) {
      try {
        final userId = user['user_id'] as String;
        await _createDefaultLearningPath(userId);
        pathsCreated++;
      } catch (e) {
        print('[ProgressiveIntegration] Error creating learning path for user: $e');
      }
    }

    print('[ProgressiveIntegration] Created $pathsCreated initial learning paths');
  }

  /// Create a default learning path for a user
  Future<void> _createDefaultLearningPath(String userId) async {
    // Get user's completed levels to determine current progress
    final completedLevels = await _getUserCompletedLevels(userId);
    final userPreferences = await _getUserLearningPreferences(userId);

    // Generate adaptive learning path
    final learningPath = await _pathGenerator.generatePersonalizedPath(
        userId,
        'math', // Default subject - should be determined from user preferences
      );

    // Save the learning path
    final db = _databaseService.database;
    if (db != null) {
      await db.insert(
        'learning_paths',
        {
          'id': learningPath.id,
          'user_id': learningPath.userId,
          'name': learningPath.name,
          'description': learningPath.description,
          'type': learningPath.type.name,
          'segments': json.encode(learningPath.segments.map((s) => s.toJson()).toList()),
          'metadata': json.encode(learningPath.metadata.toJson()),
          'progress': json.encode(learningPath.progress.toJson()),
          'is_active': learningPath.isActive ? 1 : 0,
          'created_at': learningPath.createdAt.millisecondsSinceEpoch,
          'updated_at': learningPath.updatedAt.millisecondsSinceEpoch,
        },
      );
    }
  }

  /// Get user's completed levels
  Future<List<int>> _getUserCompletedLevels(String userId) async {
    final db = _databaseService.database;
    if (db == null) return [];

    final results = await db.query(
      'level_unlocks',
      columns: ['level_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return results.map((r) => r['level_id'] as int).toList();
  }

  /// Get user learning preferences
  Future<Map<String, dynamic>> _getUserLearningPreferences(String userId) async {
    final db = _databaseService.database;
    if (db == null) return {};

    final results = await db.query(
      'user_learning_preferences',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (results.isEmpty) return {};

    final prefs = results.first;
    return {
      'learningStyle': prefs['learning_style'],
      'difficultyPreference': prefs['difficulty_preference'],
      'preferredSubjects': json.decode(prefs['preferred_subjects'] as String? ?? '[]'),
      'weakAreas': json.decode(prefs['weak_areas'] as String? ?? '[]'),
      'strongAreas': json.decode(prefs['strong_areas'] as String? ?? '[]'),
      'personalizations': json.decode(prefs['personalizations'] as String? ?? '{}'),
    };
  }

  /// Create unlock record in database
  Future<void> _createUnlockRecord(
    String userId,
    int levelId,
    double score,
    int timestamp,
    String method,
  ) async {
    final db = _databaseService.database;
    if (db == null) return;

    final unlockId = '${userId}_${levelId}_$timestamp';
    await db.insert(
      'level_unlocks',
      {
        'id': unlockId,
        'user_id': userId,
        'level_id': levelId,
        'unlock_method': method,
        'unlock_conditions': json.encode([]),
        'unlock_score': score,
        'unlocked_at': timestamp,
        'metadata': json.encode({'migrated': true}),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Update skill progress from completed levels
  Future<void> _updateSkillProgressFromLevels(String userId, List<dynamic> completedLevels) async {
    for (final levelData in completedLevels) {
      if (levelData is Map<String, dynamic>) {
        final levelId = levelData['levelId'] ?? levelData['id'];
        if (levelId != null) {
          final skills = await _skillManager.getSkillsForLevel(levelId);
          for (final skill in skills) {
            await _updateUserSkillProgress(
              userId,
              skill.id,
              levelData['score']?.toDouble() ?? 0.8,
              levelData['attempts'] ?? 1,
              levelData['timeSpent'] ?? 0,
            );
          }
        }
      }
    }
  }

  /// Update user skill progress
  Future<void> _updateUserSkillProgress(
    String userId,
    String skillId,
    double accuracy,
    int attempts,
    int timeSpent,
  ) async {
    final db = _databaseService.database;
    if (db == null) return;

    final progressId = '${userId}_$skillId';
    
    // Check if record exists
    final existing = await db.query(
      'user_skill_progress',
      where: 'id = ?',
      whereArgs: [progressId],
      limit: 1,
    );

    if (existing.isEmpty) {
      // Create new record
      await db.insert(
        'user_skill_progress',
        {
          'id': progressId,
          'user_id': userId,
          'skill_id': skillId,
          'mastery_level': min(accuracy, 1.0),
          'total_attempts': attempts,
          'successful_attempts': (attempts * accuracy).round(),
          'average_accuracy': accuracy,
          'time_spent_seconds': timeSpent,
          'last_practiced': DateTime.now().millisecondsSinceEpoch,
          'metadata': json.encode({'migrated': true}),
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } else {
      // Update existing record
      final current = existing.first;
      final currentAttempts = current['total_attempts'] as int;
      final currentSuccesses = current['successful_attempts'] as int;
      final currentTimeSpent = current['time_spent_seconds'] as int;

      final newAttempts = currentAttempts + attempts;
      final newSuccesses = currentSuccesses + (attempts * accuracy).round();
      final newAccuracy = newSuccesses / newAttempts;
      final newMastery = min(newAccuracy * 1.2, 1.0); // Slight mastery boost

      await db.update(
        'user_skill_progress',
        {
          'mastery_level': newMastery,
          'total_attempts': newAttempts,
          'successful_attempts': newSuccesses,
          'average_accuracy': newAccuracy,
          'time_spent_seconds': currentTimeSpent + timeSpent,
          'last_practiced': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [progressId],
      );
    }
  }

  /// Create adaptive difficulty record
  Future<void> _createAdaptiveDifficultyRecord(
    String userId,
    int levelId,
    Map<String, dynamic> performanceData,
  ) async {
    final db = _databaseService.database;
    if (db == null) return;

    final recordId = '${userId}_${levelId}_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert(
      'adaptive_difficulty_data',
      {
        'id': recordId,
        'user_id': userId,
        'level_id': levelId,
        'subject': performanceData['subject'] ?? 'unknown',
        'performance_score': performanceData['score']?.toDouble() ?? 0.0,
        'completion_time': performanceData['completionTime'] ?? 0,
        'attempts': performanceData['attempts'] ?? 1,
        'difficulty_rating': performanceData['difficulty']?.toDouble() ?? 0.5,
        'engagement_score': performanceData['engagement']?.toDouble(),
        'timestamp': performanceData['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
        'metadata': json.encode({'migrated': true}),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Update learning preferences
  Future<void> _updateLearningPreferences(
    String userId,
    Map<String, dynamic> subjectXP,
    Map<String, dynamic> streaks,
  ) async {
    final db = _databaseService.database;
    if (db == null) return;

    // Analyze subject preferences
    final sortedSubjects = subjectXP.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    final preferredSubjects = sortedSubjects.take(3).map((e) => e.key).toList();
    final weakAreas = sortedSubjects.reversed.take(2).map((e) => e.key).toList();

    // Determine learning style based on performance patterns
    String learningStyle = 'adaptive';
    if (streaks.isNotEmpty) {
      final avgStreak = streaks.values.map((v) => v as num).reduce((a, b) => a + b) / streaks.length;
      if (avgStreak > 10) {
        learningStyle = 'consistent';
      } else if (avgStreak < 3) {
        learningStyle = 'exploratory';
      }
    }

    await db.insert(
      'user_learning_preferences',
      {
        'user_id': userId,
        'learning_style': learningStyle,
        'difficulty_preference': 'adaptive',
        'preferred_subjects': json.encode(preferredSubjects),
        'weak_areas': json.encode(weakAreas),
        'strong_areas': json.encode(preferredSubjects.take(2).toList()),
        'personalizations': json.encode({'migrated': true}),
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Extract user ID from SharedPreferences key
  String? _extractUserIdFromKey(String key) {
    final patterns = [
      RegExp(r'unified_level_(.+)'),
      RegExp(r'user_level_progress_(.+)'),
      RegExp(r'xp_progression_(.+)'),
      RegExp(r'user_xp_(.+)'),
      RegExp(r'level_unlock_(.+?)_'),
      RegExp(r'unlock_history_(.+?)_'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(key);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  /// Load integration cache
  Future<void> _loadIntegrationCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_cacheKey);
      if (cacheData != null) {
        _integrationCache = json.decode(cacheData);
      }
    } catch (e) {
      print('[ProgressiveIntegration] Error loading cache: $e');
      _integrationCache = {};
    }
  }

  /// Save integration cache
  Future<void> _saveIntegrationCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(_integrationCache));
    } catch (e) {
      print('[ProgressiveIntegration] Error saving cache: $e');
    }
  }

  /// Check if a level should be unlocked for a user
  Future<bool> shouldUnlockLevel(String userId, int levelId) async {
    if (!_isInitialized) await initialize();

    try {
      final decision = await _unlockEngine.evaluateUnlock(levelId, userId);
      return decision.shouldUnlock;
    } catch (e) {
      print('[ProgressiveIntegration] Error checking unlock for level $levelId: $e');
      return false;
    }
  }

  /// Get recommended difficulty for a level
  Future<double> getRecommendedDifficulty(String userId, int levelId, String subject) async {
    if (!_isInitialized) await initialize();

    try {
      final recommendation = await _difficultyCalculator.calculateOptimalDifficulty(
        userId,
        levelId,
        subject,
      );
      return recommendation.recommendedDifficulty;
    } catch (e) {
      print('[ProgressiveIntegration] Error getting difficulty for level $levelId: $e');
      return 0.5; // Default medium difficulty
    }
  }

  /// Get personalized learning path for a user
  Future<LearningPath?> getPersonalizedPath(String userId) async {
    if (!_isInitialized) await initialize();

    try {
      final preferences = await _getUserLearningPreferences(userId);
      final completedLevels = await _getUserCompletedLevels(userId);
      
      return await _pathGenerator.generatePersonalizedPath(
        userId,
        'general', // Default subject
        pathType: LearningPathType.adaptive,
      );
    } catch (e) {
      print('[ProgressiveIntegration] Error getting personalized path: $e');
      return null;
    }
  }

  /// Update user progress after level completion
  Future<void> updateUserProgress(
    String userId,
    int levelId,
    double score,
    int completionTime,
    int attempts,
  ) async {
    if (!_isInitialized) await initialize();

    try {
      // Update skill progress
      final skills = await _skillManager.getSkillsForLevel(levelId);
      for (final skill in skills) {
        await _updateUserSkillProgress(userId, skill.id, score, attempts, completionTime);
      }

      // Create unlock record
      await _createUnlockRecord(
        userId,
        levelId,
        score,
        DateTime.now().millisecondsSinceEpoch,
        'completion',
      );

      // Update adaptive difficulty data
      await _createAdaptiveDifficultyRecord(userId, levelId, {
        'score': score,
        'completionTime': completionTime,
        'attempts': attempts,
        'difficulty': await getRecommendedDifficulty(userId, levelId, 'unknown'),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      print('[ProgressiveIntegration] Updated progress for user $userId, level $levelId');
    } catch (e) {
      print('[ProgressiveIntegration] Error updating user progress: $e');
    }
  }

  /// Check if a level is unlocked for a user
  Future<bool> isLevelUnlocked(String userId, String levelId) async {
    if (!_isInitialized) await initialize();

    try {
      final db = _databaseService.database;
      if (db == null) return false;

      // Check if level is unlocked in database
      final results = await db.query(
        'level_unlocks',
        where: 'user_id = ? AND level_id = ?',
        whereArgs: [userId, levelId],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return true;
      }

      // Fallback to progressive unlock service logic
      // Parse levelId to extract subject, unit, skill, and lesson indices
      final parts = levelId.split('_');
      if (parts.length >= 2) {
        final subjectId = parts[0];
        final level = int.tryParse(parts[1]) ?? 1;
        
        // Simple unlock logic: level 1 is always unlocked, others require previous completion
        if (level == 1) return true;
        
        // Check if previous level is completed
        final previousLevelId = '${subjectId}_${level - 1}';
        final previousResults = await db.query(
          'level_unlocks',
          where: 'user_id = ? AND level_id = ?',
          whereArgs: [userId, previousLevelId],
          limit: 1,
        );
        
        return previousResults.isNotEmpty;
      }

      return false;
    } catch (e) {
      print('[ProgressiveIntegration] Error checking level unlock: $e');
      return false;
    }
  }

  /// Get integration status
  Future<Map<String, dynamic>> getIntegrationStatus() async {
    final migrationStatus = await _databaseService.getMigrationStatus();
    final prefs = await SharedPreferences.getInstance();
    final legacyMigrationCompleted = prefs.getBool(_legacyMigrationKey) ?? false;

    return {
      'initialized': _isInitialized,
      'databaseMigration': migrationStatus,
      'legacyMigrationCompleted': legacyMigrationCompleted,
      'cacheSize': _integrationCache.length,
      'services': {
        'skillManager': _isInitialized,
        'unlockEngine': _isInitialized,
        'difficultyCalculator': _isInitialized,
        'pathGenerator': _isInitialized,
      },
    };
  }

  /// Reset integration (for testing)
  Future<void> resetIntegration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyMigrationKey);
    await prefs.remove(_cacheKey);
    
    await _databaseService.resetMigration();
    
    _isInitialized = false;
    _integrationCache.clear();
    
    print('[ProgressiveIntegration] Integration reset completed');
  }
}