import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/skill_node.dart';
import '../models/learning_path.dart';
import '../models/unlock_condition.dart';

/// Database migration service for progressive unlock system
/// Handles schema updates and data migration for 50,000 educational levels
class DatabaseMigrationService {
  static DatabaseMigrationService? _instance;
  static DatabaseMigrationService get instance => _instance ??= DatabaseMigrationService._();
  
  DatabaseMigrationService._();

  Database? _database;
  static const String _databaseName = 'progressive_unlock.db';
  static const int _currentVersion = 1;
  static const String _migrationKey = 'progressive_unlock_migration_v';

  /// Initialize the database with progressive unlock schema
  Future<void> initialize() async {
    // Initialize database factory for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    await _initializeDatabase();
    await _runMigrations();
  }

  /// Initialize the database with complete schema
  Future<void> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    _database = await openDatabase(
      path,
      version: _currentVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
      onOpen: (db) async {
        // Enable foreign keys
        await db.execute('PRAGMA foreign_keys = ON');
        print('[DatabaseMigration] Database opened with foreign keys enabled');
      },
    );

    print('[DatabaseMigration] Database initialized at: $path');
  }

  /// Create the complete database schema
  Future<void> _createDatabase(Database db, int version) async {
    print('[DatabaseMigration] Creating database schema v$version');

    // Skills and dependencies table
    await db.execute('''
      CREATE TABLE skills (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        subject TEXT NOT NULL,
        level_range_start INTEGER NOT NULL,
        level_range_end INTEGER NOT NULL,
        category TEXT NOT NULL,
        difficulty REAL NOT NULL,
        prerequisites TEXT, -- JSON array of skill IDs
        children TEXT, -- JSON array of skill IDs
        unlock_criteria TEXT, -- JSON object
        metadata TEXT, -- JSON object
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Unlock conditions table
    await db.execute('''
      CREATE TABLE unlock_conditions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        parameters TEXT NOT NULL, -- JSON object
        weight REAL NOT NULL DEFAULT 1.0,
        description TEXT NOT NULL,
        is_required INTEGER NOT NULL DEFAULT 0,
        valid_from INTEGER,
        valid_until INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Learning paths table
    await db.execute('''
      CREATE TABLE learning_paths (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        segments TEXT NOT NULL, -- JSON array
        metadata TEXT, -- JSON object
        progress TEXT, -- JSON object
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // User skill progress table
    await db.execute('''
      CREATE TABLE user_skill_progress (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        skill_id TEXT NOT NULL,
        mastery_level REAL NOT NULL DEFAULT 0.0,
        total_attempts INTEGER NOT NULL DEFAULT 0,
        successful_attempts INTEGER NOT NULL DEFAULT 0,
        average_accuracy REAL NOT NULL DEFAULT 0.0,
        time_spent_seconds INTEGER NOT NULL DEFAULT 0,
        last_practiced INTEGER,
        metadata TEXT, -- JSON object
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (skill_id) REFERENCES skills (id)
      )
    ''');

    // Level unlock tracking table
    await db.execute('''
      CREATE TABLE level_unlocks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        level_id INTEGER NOT NULL,
        unlock_method TEXT NOT NULL,
        unlock_conditions TEXT NOT NULL, -- JSON array
        unlock_score REAL NOT NULL,
        unlocked_at INTEGER NOT NULL,
        metadata TEXT, -- JSON object
        created_at INTEGER NOT NULL
      )
    ''');

    // User learning preferences table
    await db.execute('''
      CREATE TABLE user_learning_preferences (
        user_id TEXT PRIMARY KEY,
        learning_style TEXT NOT NULL DEFAULT 'adaptive',
        difficulty_preference TEXT NOT NULL DEFAULT 'adaptive',
        preferred_subjects TEXT, -- JSON array
        weak_areas TEXT, -- JSON array
        strong_areas TEXT, -- JSON array
        personalizations TEXT, -- JSON object
        last_updated INTEGER NOT NULL
      )
    ''');

    // Adaptive difficulty data table
    await db.execute('''
      CREATE TABLE adaptive_difficulty_data (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        level_id INTEGER NOT NULL,
        subject TEXT NOT NULL,
        performance_score REAL NOT NULL,
        completion_time INTEGER NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 1,
        difficulty_rating REAL NOT NULL,
        engagement_score REAL,
        timestamp INTEGER NOT NULL,
        metadata TEXT -- JSON object
      )
    ''');

    // Performance indexes for optimization
    await _createIndexes(db);

    print('[DatabaseMigration] Database schema created successfully');
  }

  /// Create performance indexes
  Future<void> _createIndexes(Database db) async {
    print('[DatabaseMigration] Creating performance indexes');

    // Skills indexes
    await db.execute('CREATE INDEX idx_skills_subject ON skills(subject)');
    await db.execute('CREATE INDEX idx_skills_category ON skills(category)');
    await db.execute('CREATE INDEX idx_skills_difficulty ON skills(difficulty)');
    await db.execute('CREATE INDEX idx_skills_level_range ON skills(level_range_start, level_range_end)');

    // User skill progress indexes
    await db.execute('CREATE INDEX idx_user_skill_progress_user ON user_skill_progress(user_id)');
    await db.execute('CREATE INDEX idx_user_skill_progress_skill ON user_skill_progress(skill_id)');
    await db.execute('CREATE INDEX idx_user_skill_progress_mastery ON user_skill_progress(mastery_level)');
    await db.execute('CREATE INDEX idx_user_skill_progress_last_practiced ON user_skill_progress(last_practiced)');

    // Level unlocks indexes
    await db.execute('CREATE INDEX idx_level_unlocks_user ON level_unlocks(user_id)');
    await db.execute('CREATE INDEX idx_level_unlocks_level ON level_unlocks(level_id)');
    await db.execute('CREATE INDEX idx_level_unlocks_method ON level_unlocks(unlock_method)');
    await db.execute('CREATE INDEX idx_level_unlocks_unlocked_at ON level_unlocks(unlocked_at)');

    // Learning paths indexes
    await db.execute('CREATE INDEX idx_learning_paths_user ON learning_paths(user_id)');
    await db.execute('CREATE INDEX idx_learning_paths_type ON learning_paths(type)');
    await db.execute('CREATE INDEX idx_learning_paths_active ON learning_paths(is_active)');

    // Adaptive difficulty indexes
    await db.execute('CREATE INDEX idx_adaptive_difficulty_user ON adaptive_difficulty_data(user_id)');
    await db.execute('CREATE INDEX idx_adaptive_difficulty_level ON adaptive_difficulty_data(level_id)');
    await db.execute('CREATE INDEX idx_adaptive_difficulty_subject ON adaptive_difficulty_data(subject)');
    await db.execute('CREATE INDEX idx_adaptive_difficulty_timestamp ON adaptive_difficulty_data(timestamp)');

    // Unlock conditions indexes
    await db.execute('CREATE INDEX idx_unlock_conditions_type ON unlock_conditions(type)');
    await db.execute('CREATE INDEX idx_unlock_conditions_required ON unlock_conditions(is_required)');

    print('[DatabaseMigration] Performance indexes created successfully');
  }

  /// Handle database upgrades
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    print('[DatabaseMigration] Upgrading database from v$oldVersion to v$newVersion');

    // Future version upgrades will be handled here
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      await _upgradeToVersion(db, version);
    }

    print('[DatabaseMigration] Database upgrade completed');
  }

  /// Upgrade to specific version
  Future<void> _upgradeToVersion(Database db, int version) async {
    switch (version) {
      case 1:
        // Initial version - no upgrade needed
        break;
      // Future versions will be added here
      default:
        print('[DatabaseMigration] Unknown version: $version');
    }
  }

  /// Run any pending migrations
  Future<void> _runMigrations() async {
    final prefs = await SharedPreferences.getInstance();
    final migrationKey = '$_migrationKey$_currentVersion';
    final migrationCompleted = prefs.getBool(migrationKey) ?? false;

    if (!migrationCompleted) {
      print('[DatabaseMigration] Running migrations for v$_currentVersion');
      
      await _migrateExistingUserData();
      await _initializeDefaultSkills();
      await _validateMigration();

      await prefs.setBool(migrationKey, true);
      print('[DatabaseMigration] Migration completed successfully');
    } else {
      print('[DatabaseMigration] Migration already completed for v$_currentVersion');
    }
  }

  /// Migrate existing user data from old system
  Future<void> _migrateExistingUserData() async {
    print('[DatabaseMigration] Migrating existing user data');

    try {
      // Get existing user progress from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => 
        key.startsWith('user_progress_') || 
        key.startsWith('xp_progression_') ||
        key.startsWith('level_unlock_')
      ).toList();

      int migratedUsers = 0;
      for (final key in keys) {
        try {
          await _migrateUserDataFromKey(key, prefs);
          migratedUsers++;
        } catch (e) {
          print('[DatabaseMigration] Error migrating key $key: $e');
        }
      }

      print('[DatabaseMigration] Migrated data for $migratedUsers user entries');
    } catch (e) {
      print('[DatabaseMigration] Error during user data migration: $e');
    }
  }

  /// Migrate user data from a specific SharedPreferences key
  Future<void> _migrateUserDataFromKey(String key, SharedPreferences prefs) async {
    final data = prefs.getString(key);
    if (data == null) return;

    try {
      final jsonData = json.decode(data);
      
      if (key.startsWith('user_progress_')) {
        await _migrateUserProgress(key, jsonData);
      } else if (key.startsWith('xp_progression_')) {
        await _migrateXPProgression(key, jsonData);
      } else if (key.startsWith('level_unlock_')) {
        await _migrateLevelUnlock(key, jsonData);
      }
    } catch (e) {
      print('[DatabaseMigration] Error parsing data for key $key: $e');
    }
  }

  /// Migrate user progress data
  Future<void> _migrateUserProgress(String key, Map<String, dynamic> data) async {
    final userId = key.replaceFirst('user_progress_', '');
    
    // Create default learning preferences
    await _database!.insert(
      'user_learning_preferences',
      {
        'user_id': userId,
        'learning_style': 'adaptive',
        'difficulty_preference': 'adaptive',
        'preferred_subjects': json.encode([]),
        'weak_areas': json.encode([]),
        'strong_areas': json.encode([]),
        'personalizations': json.encode({}),
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    // Migrate skill progress if available
    if (data.containsKey('skills')) {
      final skills = data['skills'] as Map<String, dynamic>? ?? {};
      for (final entry in skills.entries) {
        await _migrateSkillProgress(userId, entry.key, entry.value);
      }
    }
  }

  /// Migrate skill progress data
  Future<void> _migrateSkillProgress(String userId, String skillId, dynamic skillData) async {
    if (skillData is! Map<String, dynamic>) return;

    final progressId = '${userId}_$skillId';
    await _database!.insert(
      'user_skill_progress',
      {
        'id': progressId,
        'user_id': userId,
        'skill_id': skillId,
        'mastery_level': (skillData['mastery'] as num?)?.toDouble() ?? 0.0,
        'total_attempts': skillData['attempts'] ?? 0,
        'successful_attempts': skillData['successes'] ?? 0,
        'average_accuracy': (skillData['accuracy'] as num?)?.toDouble() ?? 0.0,
        'time_spent_seconds': skillData['timeSpent'] ?? 0,
        'last_practiced': skillData['lastPracticed'],
        'metadata': json.encode(skillData['metadata'] ?? {}),
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Migrate XP progression data
  Future<void> _migrateXPProgression(String key, Map<String, dynamic> data) async {
    final userId = key.replaceFirst('xp_progression_', '');
    
    // Convert XP data to adaptive difficulty data
    if (data.containsKey('levelPerformance')) {
      final levelPerformance = data['levelPerformance'] as Map<String, dynamic>? ?? {};
      for (final entry in levelPerformance.entries) {
        await _migrateLevelPerformance(userId, int.tryParse(entry.key) ?? 0, entry.value);
      }
    }
  }

  /// Migrate level performance data
  Future<void> _migrateLevelPerformance(String userId, int levelId, dynamic performanceData) async {
    if (performanceData is! Map<String, dynamic>) return;

    final adaptiveId = '${userId}_${levelId}_${DateTime.now().millisecondsSinceEpoch}';
    await _database!.insert(
      'adaptive_difficulty_data',
      {
        'id': adaptiveId,
        'user_id': userId,
        'level_id': levelId,
        'subject': performanceData['subject'] ?? 'unknown',
        'performance_score': (performanceData['score'] as num?)?.toDouble() ?? 0.0,
        'completion_time': performanceData['completionTime'] ?? 0,
        'attempts': performanceData['attempts'] ?? 1,
        'difficulty_rating': (performanceData['difficulty'] as num?)?.toDouble() ?? 0.5,
        'engagement_score': (performanceData['engagement'] as num?)?.toDouble(),
        'timestamp': performanceData['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
        'metadata': json.encode(performanceData['metadata'] ?? {}),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Migrate level unlock data
  Future<void> _migrateLevelUnlock(String key, Map<String, dynamic> data) async {
    final parts = key.replaceFirst('level_unlock_', '').split('_');
    if (parts.length < 2) return;

    final userId = parts[0];
    final levelId = int.tryParse(parts[1]) ?? 0;

    final unlockId = '${userId}_${levelId}_${DateTime.now().millisecondsSinceEpoch}';
    await _database!.insert(
      'level_unlocks',
      {
        'id': unlockId,
        'user_id': userId,
        'level_id': levelId,
        'unlock_method': data['method'] ?? 'sequential',
        'unlock_conditions': json.encode(data['conditions'] ?? []),
        'unlock_score': (data['score'] as num?)?.toDouble() ?? 1.0,
        'unlocked_at': data['unlockedAt'] ?? DateTime.now().millisecondsSinceEpoch,
        'metadata': json.encode(data['metadata'] ?? {}),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Initialize default skills in the database
  Future<void> _initializeDefaultSkills() async {
    print('[DatabaseMigration] Initializing default skills');

    // Check if skills already exist
    final existingSkills = await _database!.query('skills', limit: 1);
    if (existingSkills.isNotEmpty) {
      print('[DatabaseMigration] Skills already initialized');
      return;
    }

    // Create default skills for each subject
    final subjects = ['Mathematics', 'Science', 'Programming', 'Language', 'History'];
    int skillCount = 0;

    for (final subject in subjects) {
      final skills = _createDefaultSkillsForSubject(subject);
      for (final skill in skills) {
        await _insertSkill(skill);
        skillCount++;
      }
    }

    print('[DatabaseMigration] Initialized $skillCount default skills');
  }

  /// Create default skills for a subject
  List<SkillNode> _createDefaultSkillsForSubject(String subject) {
    final skills = <SkillNode>[];
    final categories = [
      SkillCategory.foundation,
      SkillCategory.core,
      SkillCategory.advanced,
      SkillCategory.application,
      SkillCategory.mastery,
    ];

    int skillIndex = 0;
    for (final category in categories) {
      for (int i = 0; i < 10; i++) { // 10 skills per category
        final skill = SkillNode(
          id: '${subject.toLowerCase()}_${category.name}_$i',
          name: '${subject} ${_getCategoryName(category)} Skill ${i + 1}',
          description: 'Essential ${category.name} skill for ${subject}',
          subject: subject,
          levelRange: [skillIndex * 100 + 1, (skillIndex + 1) * 100],
          category: category,
          difficulty: (0.1 + (skillIndex * 0.1) * 10).round().clamp(1, 10), // Increasing difficulty as int 1-10
          prerequisites: skillIndex > 0 ? ['${subject.toLowerCase()}_${categories[skillIndex ~/ 10]}_${(skillIndex - 1) % 10}'] : [],
          children: [],
          unlockCriteria: UnlockCriteria(
            minAccuracy: 0.7,
            minXP: 100 * (skillIndex + 1),
            requiredLevels: [skillIndex * 100 + 1, skillIndex * 100 + 5],
            minMasteryScore: 0.8,
          ),
          metadata: {
            'subject': subject,
            'tier': skillIndex ~/ 10,
            'position': skillIndex % 10,
          },
        );
        skills.add(skill);
        skillIndex++;
      }
    }

    return skills;
  }

  /// Insert a skill into the database
  Future<void> _insertSkill(SkillNode skill) async {
    await _database!.insert(
      'skills',
      {
        'id': skill.id,
        'name': skill.name,
        'description': skill.description,
        'subject': skill.subject,
        'level_range_start': skill.levelRange[0],
        'level_range_end': skill.levelRange[1],
        'category': skill.category.name,
        'difficulty': skill.difficulty,
        'prerequisites': json.encode(skill.prerequisites),
        'children': json.encode(skill.children),
        'unlock_criteria': json.encode(skill.unlockCriteria.toJson()),
        'metadata': json.encode(skill.metadata),
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get category display name
  String _getCategoryName(SkillCategory category) {
    switch (category) {
      case SkillCategory.foundation:
        return 'Foundation';
      case SkillCategory.core:
        return 'Core';
      case SkillCategory.advanced:
        return 'Advanced';
      case SkillCategory.application:
        return 'Application';
      case SkillCategory.mastery:
        return 'Mastery';
      case SkillCategory.crossSubject:
        return 'Cross-Subject';
      case SkillCategory.special:
        return 'Special';
    }
  }

  /// Validate migration success
  Future<void> _validateMigration() async {
    print('[DatabaseMigration] Validating migration');

    try {
      // Check skills table
      final skillCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM skills')
      ) ?? 0;
      print('[DatabaseMigration] Skills count: $skillCount');

      // Check user preferences table
      final preferencesCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM user_learning_preferences')
      ) ?? 0;
      print('[DatabaseMigration] User preferences count: $preferencesCount');

      // Check user skill progress table
      final progressCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM user_skill_progress')
      ) ?? 0;
      print('[DatabaseMigration] User skill progress count: $progressCount');

      // Check level unlocks table
      final unlocksCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM level_unlocks')
      ) ?? 0;
      print('[DatabaseMigration] Level unlocks count: $unlocksCount');

      // Validate indexes exist
      final indexes = await _database!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%'"
      );
      print('[DatabaseMigration] Created ${indexes.length} performance indexes');

      print('[DatabaseMigration] Migration validation completed successfully');
    } catch (e) {
      print('[DatabaseMigration] Validation error: $e');
      throw Exception('Migration validation failed: $e');
    }
  }

  /// Get database instance
  Database? get database => _database;

  /// Execute a raw query
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    if (_database == null) {
      throw Exception('Database not initialized');
    }
    return await _database!.rawQuery(sql, arguments);
  }

  /// Execute a raw insert/update/delete
  Future<int> rawExecute(String sql, [List<dynamic>? arguments]) async {
    if (_database == null) {
      throw Exception('Database not initialized');
    }
    return await _database!.rawUpdate(sql, arguments);
  }

  /// Get migration status
  Future<Map<String, dynamic>> getMigrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final migrationKey = '$_migrationKey$_currentVersion';
    final migrationCompleted = prefs.getBool(migrationKey) ?? false;

    final status = {
      'version': _currentVersion,
      'migrationCompleted': migrationCompleted,
      'databasePath': _database?.path ?? 'Not initialized',
    };

    if (_database != null) {
      try {
        final skillCount = Sqflite.firstIntValue(
          await _database!.rawQuery('SELECT COUNT(*) FROM skills')
        ) ?? 0;
        final userCount = Sqflite.firstIntValue(
          await _database!.rawQuery('SELECT COUNT(*) FROM user_learning_preferences')
        ) ?? 0;
        
        status['skillCount'] = skillCount;
        status['userCount'] = userCount;
      } catch (e) {
        status['error'] = e.toString();
      }
    }

    return status;
  }

  /// Reset migration (for testing purposes)
  Future<void> resetMigration() async {
    final prefs = await SharedPreferences.getInstance();
    final migrationKey = '$_migrationKey$_currentVersion';
    await prefs.remove(migrationKey);
    
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    
    // Delete database file
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    
    print('[DatabaseMigration] Migration reset completed');
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('[DatabaseMigration] Database connection closed');
    }
  }
}

/// Range class for skill level ranges
class Range {
  final int start;
  final int end;

  Range(this.start, this.end);

  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
  };

  factory Range.fromJson(Map<String, dynamic> json) => Range(
    json['start'],
    json['end'],
  );

  @override
  String toString() => 'Range($start-$end)';
}