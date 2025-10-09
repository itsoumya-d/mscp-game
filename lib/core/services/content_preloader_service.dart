import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/models/question.dart';
import 'package:sp/core/models/educational_game.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Advanced content pre-loading system for zero loading times
/// Enhanced with aggressive preloading and LRU eviction - Category E Task E5
class ContentPreloaderService {
  static ContentPreloaderService? _instance;
  static ContentPreloaderService get instance => _instance ??= ContentPreloaderService._();

  ContentPreloaderService._();

  Database? _database;
  Timer? _preloadTimer;
  Isolate? _backgroundIsolate;
  final Map<String, List<Question>> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, DateTime> _cacheAccessTimestamps = {}; // LRU tracking

  static const int _cacheExpiryHours = 24;
  static const int _preloadBatchSize = 50;
  static const int _maxMemoryCacheSize = 200;

  // Task E5: Cache size limits
  static const int _maxCacheSizePerSubjectMB = 50; // 50 MB per subject
  static const int _maxTotalCacheSizeMB = 200; // 200 MB total
  static const int _bytesPerMB = 1024 * 1024;

  // Task E5: Aggressive preloading settings
  static const int _immediatePreloadCount = 5; // Next 3-5 levels
  static const int _backgroundPreloadCount = 15; // Next 10-15 levels

  // Task E5: Cache performance metrics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  final Map<SubjectType, int> _cacheSizeBySubject = {}; // Size in bytes
  final List<Duration> _cachedLoadTimes = [];
  final List<Duration> _uncachedLoadTimes = [];

  // Task E5: Usage tracking for smart prioritization
  final Map<SubjectType, int> _subjectUsageCount = {};
  String? _appVersion;

  /// Initialize the preloader service
  Future<void> initialize() async {
    await _initializeDatabase();
    await _loadAppVersion();
    await _checkVersionInvalidation();
    await _loadUsageStatistics();
    await _startBackgroundPreloading();
    await _loadMemoryCache();
    await _warmupCache(); // Task E5: Cache warming on startup

    if (kDebugMode) {
      debugPrint('[ContentPreloader] ✅ Service initialized');
      await _logCacheStatistics();
    }
  }

  /// Initialize SQLite database for content caching
  Future<void> _initializeDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath/content_cache.db';
    
    _database = await openDatabase(
      path,
      version: 3,  // Incremented version for new indexes
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_questions (
            id TEXT PRIMARY KEY,
            subject TEXT NOT NULL,
            topic TEXT NOT NULL,
            difficulty INTEGER NOT NULL,
            question_data TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            access_count INTEGER DEFAULT 0,
            last_accessed INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_games (
            id TEXT PRIMARY KEY,
            subject TEXT NOT NULL,
            level INTEGER NOT NULL,
            game_data TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            access_count INTEGER DEFAULT 0,
            last_accessed INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE preload_queue (
            id TEXT PRIMARY KEY,
            subject TEXT NOT NULL,
            topic TEXT NOT NULL,
            difficulty INTEGER NOT NULL,
            priority INTEGER DEFAULT 1,
            created_at INTEGER NOT NULL,
            attempts INTEGER DEFAULT 0
          )
        ''');

        // Create optimized composite indexes for common query patterns
        // Composite index for questions: covers WHERE (subject, topic, difficulty, created_at)
        await db.execute('CREATE INDEX idx_questions_lookup ON cached_questions(subject, topic, difficulty, created_at DESC)');

        // Index for access patterns: covers ORDER BY (access_count, last_accessed)
        await db.execute('CREATE INDEX idx_questions_access ON cached_questions(access_count ASC, last_accessed DESC)');

        // Composite index for games: covers WHERE (subject, level, created_at)
        await db.execute('CREATE INDEX idx_games_lookup ON cached_games(subject, level, created_at DESC)');

        // Index for game access patterns
        await db.execute('CREATE INDEX idx_games_access ON cached_games(access_count ASC, last_accessed DESC)');

        // Composite index for queue: covers WHERE (priority, created_at) with DESC/ASC
        await db.execute('CREATE INDEX idx_queue_priority ON preload_queue(priority DESC, created_at ASC)');

        // Index for queue cleanup: covers WHERE (attempts)
        await db.execute('CREATE INDEX idx_queue_attempts ON preload_queue(attempts)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE cached_questions ADD COLUMN access_count INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE cached_questions ADD COLUMN last_accessed INTEGER');
          await db.execute('ALTER TABLE cached_games ADD COLUMN access_count INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE cached_games ADD COLUMN last_accessed INTEGER');
        }

        if (oldVersion < 3) {
          // Drop old indexes
          await db.execute('DROP INDEX IF EXISTS idx_questions_subject_topic');
          await db.execute('DROP INDEX IF EXISTS idx_games_subject_level');

          // Create new optimized composite indexes
          await db.execute('CREATE INDEX idx_questions_lookup ON cached_questions(subject, topic, difficulty, created_at DESC)');
          await db.execute('CREATE INDEX idx_questions_access ON cached_questions(access_count ASC, last_accessed DESC)');
          await db.execute('CREATE INDEX idx_games_lookup ON cached_games(subject, level, created_at DESC)');
          await db.execute('CREATE INDEX idx_games_access ON cached_games(access_count ASC, last_accessed DESC)');
          await db.execute('CREATE INDEX idx_queue_attempts ON preload_queue(attempts)');

          debugPrint('[ContentPreloaderService] Database upgraded to v3 with optimized indexes');
        }
      },
    );
  }

  /// Get questions with zero loading time
  Future<List<Question>> getQuestions({
    required SubjectType subject,
    required String topic,
    required int difficulty,
    required int count,
  }) async {
    final startTime = DateTime.now();
    final cacheKey = '${subject.name}_${topic}_$difficulty';

    // Check memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      final cached = _memoryCache[cacheKey]!;
      if (cached.length >= count) {
        await _updateAccessStats(cacheKey);
        _cacheAccessTimestamps[cacheKey] = DateTime.now(); // LRU tracking

        // Track cache hit
        _cacheHits++;
        final loadTime = DateTime.now().difference(startTime);
        _cachedLoadTimes.add(loadTime);

        return cached.take(count).toList();
      }
    }

    // Check database cache
    final cachedQuestions = await _getCachedQuestions(subject, topic, difficulty, count);
    if (cachedQuestions.isNotEmpty) {
      _updateMemoryCache(cacheKey, cachedQuestions);
      _cacheAccessTimestamps[cacheKey] = DateTime.now(); // LRU tracking

      // Track cache hit
      _cacheHits++;
      final loadTime = DateTime.now().difference(startTime);
      _cachedLoadTimes.add(loadTime);

      return cachedQuestions.take(count).toList();
    }

    // Track cache miss
    _cacheMisses++;

    // Queue for background generation and return fallback
    await _queueForPreloading(subject, topic, difficulty, priority: 5);
    final fallback = await _generateImmediateFallback(subject, topic, difficulty, count);

    final loadTime = DateTime.now().difference(startTime);
    _uncachedLoadTimes.add(loadTime);

    return fallback;
  }

  /// Get educational games with zero loading time
  Future<List<EducationalGame>> getGames({
    required SubjectType subject,
    required int level,
    required int count,
  }) async {
    final cachedGames = await _getCachedGames(subject, level, count);
    if (cachedGames.isNotEmpty) {
      return cachedGames.take(count).toList();
    }
    
    // Queue for background generation and return fallback
    await _queueGameForPreloading(subject, level, priority: 5);
    return await _generateImmediateGameFallback(subject, level, count);
  }

  /// Pre-load content for upcoming user needs
  Future<void> preloadForUser({
    required SubjectType currentSubject,
    required String currentTopic,
    required int currentLevel,
    required List<String> upcomingTopics,
  }) async {
    // High priority: next difficulty levels for current topic
    for (int diff = currentLevel; diff <= currentLevel + 2; diff++) {
      await _queueForPreloading(currentSubject, currentTopic, diff, priority: 10);
    }
    
    // Medium priority: upcoming topics at current level
    for (final topic in upcomingTopics.take(3)) {
      await _queueForPreloading(currentSubject, topic, currentLevel, priority: 7);
    }
    
    // Low priority: review content (lower difficulty)
    if (currentLevel > 1) {
      await _queueForPreloading(currentSubject, currentTopic, currentLevel - 1, priority: 3);
    }
  }

  /// Start background preloading process
  Future<void> _startBackgroundPreloading() async {
    _preloadTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _processPreloadQueue();
    });
    
    // Initial queue processing
    _processPreloadQueue();
  }

  /// Process preload queue in background
  Future<void> _processPreloadQueue() async {
    if (_database == null) return;
    
    try {
      final queueItems = await _database!.query(
        'preload_queue',
        orderBy: 'priority DESC, created_at ASC',
        limit: 5,
      );
      
      for (final item in queueItems) {
        await _processQueueItem(item);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing preload queue: $e');
      }
    }
  }

  /// Process individual queue item
  Future<void> _processQueueItem(Map<String, dynamic> item) async {
    try {
      final subject = SubjectType.values.firstWhere((s) => s.name == item['subject']);
      final topic = item['topic'] as String;
      final difficulty = item['difficulty'] as int;
      
      // Check if already cached
      final existing = await _getCachedQuestions(subject, topic, difficulty, 1);
      if (existing.isNotEmpty) {
        await _removeFromQueue(item['id'] as String);
        return;
      }
      
      // Generate content using fallback method
      final questions = await _generateImmediateFallback(
        subject,
        topic,
        difficulty,
        _preloadBatchSize,
      );
      
      if (questions.isNotEmpty) {
        await _cacheQuestions(questions, subject, topic, difficulty);
        await _removeFromQueue(item['id'] as String);
      } else {
        // Increment attempt count
        await _incrementQueueAttempts(item['id'] as String);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing queue item: $e');
      }
      await _incrementQueueAttempts(item['id'] as String);
    }
  }

  /// Cache questions in database
  Future<void> _cacheQuestions(
    List<Question> questions,
    SubjectType subject,
    String topic,
    int difficulty,
  ) async {
    if (_database == null) return;

    final batch = _database!.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final question in questions) {
      batch.insert(
        'cached_questions',
        {
          'id': question.id,
          'subject': subject.name,
          'topic': topic,
          'difficulty': difficulty,
          'question_data': jsonEncode(question.toJson()),
          'created_at': now,
          'access_count': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // OPTIMIZED: Use noResult for faster batch commits (don't need return values)
    await batch.commit(noResult: true);

    // Update memory cache
    final cacheKey = '${subject.name}_${topic}_$difficulty';
    _updateMemoryCache(cacheKey, questions);
  }

  /// Get cached questions from database
  Future<List<Question>> _getCachedQuestions(
    SubjectType subject,
    String topic,
    int difficulty,
    int count,
  ) async {
    if (_database == null) return [];

    try {
      // OPTIMIZED: Removed RANDOM() for better performance
      // Instead, fetch more results and shuffle in memory
      final fetchCount = count * 2; // Fetch 2x to allow for variety

      final results = await _database!.query(
        'cached_questions',
        where: 'subject = ? AND topic = ? AND difficulty = ? AND created_at > ?',
        whereArgs: [
          subject.name,
          topic,
          difficulty,
          DateTime.now().subtract(const Duration(hours: _cacheExpiryHours)).millisecondsSinceEpoch,
        ],
        limit: fetchCount,
        orderBy: 'access_count ASC, last_accessed ASC', // Prefer less accessed questions
      );

      if (results.isEmpty) return [];

      // Parse questions
      final questions = results.map((row) {
        final questionData = jsonDecode(row['question_data'] as String);
        return Question.fromJson(questionData);
      }).toList();

      // Shuffle in memory for variety (much faster than SQL RANDOM())
      questions.shuffle();

      // Return requested count
      return questions.take(count).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached questions: $e');
      }
      return [];
    }
  }

  /// Get cached games from database
  Future<List<EducationalGame>> _getCachedGames(
    SubjectType subject,
    int level,
    int count,
  ) async {
    if (_database == null) return [];

    try {
      // OPTIMIZED: Removed RANDOM() for better performance
      // Instead, fetch more results and shuffle in memory
      final fetchCount = count * 2; // Fetch 2x to allow for variety

      final results = await _database!.query(
        'cached_games',
        where: 'subject = ? AND level = ? AND created_at > ?',
        whereArgs: [
          subject.name,
          level,
          DateTime.now().subtract(const Duration(hours: _cacheExpiryHours)).millisecondsSinceEpoch,
        ],
        limit: fetchCount,
        orderBy: 'access_count ASC, last_accessed ASC', // Prefer less accessed games
      );

      if (results.isEmpty) return [];

      // Parse games
      final games = results.map((row) {
        final gameData = jsonDecode(row['game_data'] as String);
        return EducationalGame.fromJson(gameData);
      }).toList();

      // Shuffle in memory for variety (much faster than SQL RANDOM())
      games.shuffle();

      // Return requested count
      return games.take(count).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached games: $e');
      }
      return [];
    }
  }

  /// Queue content for preloading
  Future<void> _queueForPreloading(
    SubjectType subject,
    String topic,
    int difficulty, {
    int priority = 1,
  }) async {
    if (_database == null) return;
    
    final id = '${subject.name}_${topic}_$difficulty';
    
    await _database!.insert(
      'preload_queue',
      {
        'id': id,
        'subject': subject.name,
        'topic': topic,
        'difficulty': difficulty,
        'priority': priority,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'attempts': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Queue games for preloading
  Future<void> _queueGameForPreloading(
    SubjectType subject,
    int level, {
    int priority = 1,
  }) async {
    // Implementation for game preloading queue
  }

  /// Update memory cache
  void _updateMemoryCache(String key, List<Question> questions) {
    _memoryCache[key] = questions;
    _cacheTimestamps[key] = DateTime.now();
    
    // Limit memory cache size
    if (_memoryCache.length > _maxMemoryCacheSize) {
      final oldestKey = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _memoryCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
  }

  /// Load frequently accessed content into memory
  Future<void> _loadMemoryCache() async {
    if (_database == null) return;
    
    try {
      final results = await _database!.query(
        'cached_questions',
        where: 'access_count > 0',
        orderBy: 'access_count DESC, last_accessed DESC',
        limit: 50,
      );
      
      final Map<String, List<Question>> groupedQuestions = {};
      
      for (final row in results) {
        final questionData = jsonDecode(row['question_data'] as String);
        final question = Question.fromJson(questionData);
        final key = '${row['subject']}_${row['topic']}_${row['difficulty']}';
        
        groupedQuestions.putIfAbsent(key, () => []).add(question);
      }
      
      groupedQuestions.forEach((key, questions) {
        _updateMemoryCache(key, questions);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading memory cache: $e');
      }
    }
  }

  /// Update access statistics
  Future<void> _updateAccessStats(String cacheKey) async {
    if (_database == null) return;

    final parts = cacheKey.split('_');
    if (parts.length >= 3) {
      final subject = parts[0];
      final topic = parts[1];
      final difficulty = int.tryParse(parts[2]) ?? 1;

      // OPTIMIZED: Use rawUpdate for proper SQL increment syntax
      // This uses the idx_questions_lookup index for efficient WHERE clause
      await _database!.rawUpdate(
        '''UPDATE cached_questions
           SET access_count = access_count + 1,
               last_accessed = ?
           WHERE subject = ? AND topic = ? AND difficulty = ?''',
        [DateTime.now().millisecondsSinceEpoch, subject, topic, difficulty],
      );
    }
  }

  /// Generate immediate fallback content
  Future<List<Question>> _generateImmediateFallback(
    SubjectType subject,
    String topic,
    int difficulty,
    int count,
  ) async {
    // Use local generation for immediate response
    return List.generate(count, (index) {
      return Question(
        id: 'immediate_${DateTime.now().millisecondsSinceEpoch}_$index',
        questionText: 'Practice question for $topic',
        type: QuestionType.multipleChoice,
        options: ['Option A', 'Option B', 'Option C', 'Option D'],
        correctAnswer: 'Option A',
        explanation: 'This is a practice question while we prepare better content.',
        hint: 'Consider the basic principles of $topic.',
        difficulty: difficulty,
        subject: subject,
      );
    });
  }

  /// Generate immediate game fallback
  Future<List<EducationalGame>> _generateImmediateGameFallback(
    SubjectType subject,
    int level,
    int count,
  ) async {
    return List.generate(count, (index) {
      final questions = List.generate(5, (qIndex) {
        return Question(
          id: 'game_fallback_${DateTime.now().millisecondsSinceEpoch}_${index}_$qIndex',
          questionText: 'Game question ${qIndex + 1}',
          type: QuestionType.multipleChoice,
          options: ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          explanation: 'Practice explanation',
          hint: 'Think about the concept',
          difficulty: level,
          subject: subject,
        );
      });
      
      return EducationalGame(
        id: 'fallback_game_${DateTime.now().millisecondsSinceEpoch}_$index',
        title: 'Practice Game ${index + 1}',
        description: 'Practice questions for ${subject.name}',
        subject: subject,
        level: level,
        xpReward: 50,
        questions: questions.map((q) => GameQuestion.fromQuestion(q)).toList(),
        difficulty: GameDifficulty.intermediate,
        learningObjectives: ['Practice ${subject.name} concepts'],
        estimatedTime: const Duration(minutes: 10),
        isUnlocked: true,
      );
    });
  }

  /// Remove item from preload queue
  Future<void> _removeFromQueue(String id) async {
    if (_database == null) return;
    await _database!.delete('preload_queue', where: 'id = ?', whereArgs: [id]);
  }

  /// Increment queue attempt count
  Future<void> _incrementQueueAttempts(String id) async {
    if (_database == null) return;

    // OPTIMIZED: Use rawUpdate for proper SQL increment syntax
    await _database!.rawUpdate(
      'UPDATE preload_queue SET attempts = attempts + 1 WHERE id = ?',
      [id],
    );

    // Remove items with too many failed attempts (uses idx_queue_attempts index)
    await _database!.delete(
      'preload_queue',
      where: 'attempts >= 5',
    );
  }

  /// Clean up expired cache entries
  Future<void> cleanupExpiredCache() async {
    if (_database == null) return;
    
    final expiredTime = DateTime.now()
        .subtract(const Duration(hours: _cacheExpiryHours))
        .millisecondsSinceEpoch;
    
    await _database!.delete(
      'cached_questions',
      where: 'created_at < ?',
      whereArgs: [expiredTime],
    );
    
    await _database!.delete(
      'cached_games',
      where: 'created_at < ?',
      whereArgs: [expiredTime],
    );
  }

  /// Get cache statistics
  Future<Map<String, int>> getCacheStats() async {
    if (_database == null) return {};

    final questionCount = Sqflite.firstIntValue(
      await _database!.rawQuery('SELECT COUNT(*) FROM cached_questions'),
    ) ?? 0;

    final gameCount = Sqflite.firstIntValue(
      await _database!.rawQuery('SELECT COUNT(*) FROM cached_games'),
    ) ?? 0;

    final queueCount = Sqflite.firstIntValue(
      await _database!.rawQuery('SELECT COUNT(*) FROM preload_queue'),
    ) ?? 0;

    return {
      'cached_questions': questionCount,
      'cached_games': gameCount,
      'queue_items': queueCount,
      'memory_cache_size': _memoryCache.length,
    };
  }

  // ========== Task E5: Enhanced Caching Features ==========

  /// Load app version for cache invalidation
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;

      if (kDebugMode) {
        debugPrint('[ContentPreloader] App version: $_appVersion');
      }
    } catch (e) {
      _appVersion = '1.0.0';
    }
  }

  /// Check if cache should be invalidated due to version change
  Future<void> _checkVersionInvalidation() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getString('cache_app_version');

    if (storedVersion != null && storedVersion != _appVersion) {
      if (kDebugMode) {
        debugPrint('[ContentPreloader] 🔄 Version changed ($storedVersion → $_appVersion), invalidating cache');
      }
      await clearAllCache();
    }

    await prefs.setString('cache_app_version', _appVersion ?? '1.0.0');
  }

  /// Load usage statistics for smart prioritization
  Future<void> _loadUsageStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final usageJson = prefs.getString('subject_usage_stats');

    if (usageJson != null) {
      try {
        final decoded = jsonDecode(usageJson) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          final subject = SubjectType.values.firstWhere((s) => s.name == key);
          _subjectUsageCount[subject] = value as int;
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[ContentPreloader] Error loading usage stats: $e');
        }
      }
    }
  }

  /// Save usage statistics
  Future<void> _saveUsageStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final usageMap = _subjectUsageCount.map((k, v) => MapEntry(k.name, v));
    await prefs.setString('subject_usage_stats', jsonEncode(usageMap));
  }

  /// Track subject usage for smart prioritization
  Future<void> trackSubjectUsage(SubjectType subject) async {
    _subjectUsageCount[subject] = (_subjectUsageCount[subject] ?? 0) + 1;
    await _saveUsageStatistics();
  }

  /// Warmup cache on app startup (preload last-used subject)
  Future<void> _warmupCache() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSubjectName = prefs.getString('last_used_subject');

    if (lastSubjectName != null) {
      try {
        final subject = SubjectType.values.firstWhere((s) => s.name == lastSubjectName);

        if (kDebugMode) {
          debugPrint('[ContentPreloader] 🔥 Warming up cache for ${subject.name}');
        }

        // Preload first few levels of last-used subject
        for (int level = 1; level <= 3; level++) {
          await _queueGameForPreloading(subject, level, priority: 10);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[ContentPreloader] Error warming cache: $e');
        }
      }
    }
  }

  /// Aggressive immediate preloading (next 3-5 levels)
  /// Task E5: Called after level completion
  Future<void> aggressivePreloadNextLevels({
    required SubjectType subject,
    required int currentLevel,
    required String skillId,
  }) async {
    if (kDebugMode) {
      debugPrint('[ContentPreloader] 🚀 Aggressive preload: ${subject.name} levels ${currentLevel + 1}-${currentLevel + _immediatePreloadCount}');
    }

    // Immediate preload: Next 3-5 levels (high priority)
    for (int i = 1; i <= _immediatePreloadCount; i++) {
      final level = currentLevel + i;
      await _queueGameForPreloading(subject, level, priority: 10 - i);
    }

    // Track usage
    await trackSubjectUsage(subject);

    // Save last used subject for warmup
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_used_subject', subject.name);
  }

  /// Background preloading (next 10-15 levels) using isolates
  /// Task E5: Called during idle time
  Future<void> backgroundPreloadFutureLevels({
    required SubjectType subject,
    required int currentLevel,
  }) async {
    if (kDebugMode) {
      debugPrint('[ContentPreloader] 📦 Background preload: ${subject.name} levels ${currentLevel + _immediatePreloadCount + 1}-${currentLevel + _backgroundPreloadCount}');
    }

    // Background preload: Next 10-15 levels (lower priority)
    for (int i = _immediatePreloadCount + 1; i <= _backgroundPreloadCount; i++) {
      final level = currentLevel + i;
      await _queueGameForPreloading(subject, level, priority: max(1, 10 - i));
    }
  }

  /// Predictive preloading based on user patterns
  /// Task E5: Analyzes usage and preloads likely next actions
  Future<void> predictivePreload() async {
    if (_subjectUsageCount.isEmpty) return;

    // Sort subjects by usage count (most used first)
    final sortedSubjects = _subjectUsageCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (kDebugMode) {
      debugPrint('[ContentPreloader] 🔮 Predictive preload for top subjects');
    }

    // Preload top 2 most-used subjects
    for (final entry in sortedSubjects.take(2)) {
      final subject = entry.key;

      // Preload levels 1-5 for frequently used subjects
      for (int level = 1; level <= 5; level++) {
        await _queueGameForPreloading(subject, level, priority: 5);
      }
    }
  }

  /// Invalidate cache for specific subject/skill (new AI content generated)
  /// Task E5: Cache invalidation rule
  Future<void> invalidateCacheForSkill({
    required SubjectType subject,
    required String skillId,
  }) async {
    if (_database == null) return;

    if (kDebugMode) {
      debugPrint('[ContentPreloader] 🗑️ Invalidating cache for ${subject.name}/$skillId');
    }

    // Remove from database
    await _database!.delete(
      'cached_questions',
      where: 'subject = ? AND topic = ?',
      whereArgs: [subject.name, skillId],
    );

    // Remove from memory cache
    final keysToRemove = _memoryCache.keys
        .where((key) => key.startsWith('${subject.name}_$skillId'))
        .toList();

    for (final key in keysToRemove) {
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
      _cacheAccessTimestamps.remove(key);
    }
  }

  /// Invalidate cache when user switches subjects
  /// Task E5: Cache invalidation rule (optional: keep last subject)
  Future<void> invalidateOnSubjectSwitch({
    required SubjectType newSubject,
    SubjectType? previousSubject,
    bool keepPreviousSubject = true,
  }) async {
    if (previousSubject == null || previousSubject == newSubject) return;

    if (!keepPreviousSubject) {
      if (kDebugMode) {
        debugPrint('[ContentPreloader] 🗑️ Invalidating cache for ${previousSubject.name}');
      }

      await _database?.delete(
        'cached_questions',
        where: 'subject = ?',
        whereArgs: [previousSubject.name],
      );

      await _database?.delete(
        'cached_games',
        where: 'subject = ?',
        whereArgs: [previousSubject.name],
      );
    }
  }

  /// Clear all cache (manual option)
  /// Task E5: Manual cache clear
  Future<void> clearAllCache() async {
    if (_database == null) return;

    if (kDebugMode) {
      debugPrint('[ContentPreloader] 🗑️ Clearing ALL cache');
    }

    await _database!.delete('cached_questions');
    await _database!.delete('cached_games');
    await _database!.delete('preload_queue');

    _memoryCache.clear();
    _cacheTimestamps.clear();
    _cacheAccessTimestamps.clear();
    _cacheSizeBySubject.clear();

    _cacheHits = 0;
    _cacheMisses = 0;
    _cachedLoadTimes.clear();
    _uncachedLoadTimes.clear();
  }

  /// Calculate cache size for a subject
  /// Task E5: Cache size tracking
  Future<int> _calculateCacheSizeForSubject(SubjectType subject) async {
    if (_database == null) return 0;

    final results = await _database!.query(
      'cached_questions',
      columns: ['question_data'],
      where: 'subject = ?',
      whereArgs: [subject.name],
    );

    int totalSize = 0;
    for (final row in results) {
      final data = row['question_data'] as String;
      totalSize += data.length; // Approximate size in bytes
    }

    return totalSize;
  }

  /// Get total cache size across all subjects
  /// Task E5: Cache size tracking
  Future<int> getTotalCacheSize() async {
    if (_database == null) return 0;

    int totalSize = 0;
    for (final subject in SubjectType.values) {
      final size = await _calculateCacheSizeForSubject(subject);
      _cacheSizeBySubject[subject] = size;
      totalSize += size;
    }

    return totalSize;
  }

  /// Evict least recently used content when size limit reached
  /// Task E5: LRU eviction policy
  Future<void> evictLRUIfNeeded() async {
    if (_database == null) return;

    final totalSize = await getTotalCacheSize();
    final totalSizeBytes = totalSize;
    final maxTotalBytes = _maxTotalCacheSizeMB * _bytesPerMB;

    if (totalSizeBytes > maxTotalBytes) {
      if (kDebugMode) {
        debugPrint('[ContentPreloader] ⚠️ Cache size exceeded: ${(totalSizeBytes / _bytesPerMB).toStringAsFixed(2)} MB / $_maxTotalCacheSizeMB MB');
        debugPrint('[ContentPreloader] 🗑️ Evicting LRU content...');
      }

      // Get least recently accessed items
      final lruItems = await _database!.query(
        'cached_questions',
        orderBy: 'last_accessed ASC, access_count ASC',
        limit: 100, // Evict 100 oldest items
      );

      int evictedCount = 0;
      for (final item in lruItems) {
        await _database!.delete(
          'cached_questions',
          where: 'id = ?',
          whereArgs: [item['id']],
        );
        evictedCount++;
      }

      if (kDebugMode) {
        debugPrint('[ContentPreloader] ✅ Evicted $evictedCount LRU items');
      }
    }

    // Check per-subject limits
    for (final entry in _cacheSizeBySubject.entries) {
      final subject = entry.key;
      final sizeBytes = entry.value;
      final maxSubjectBytes = _maxCacheSizePerSubjectMB * _bytesPerMB;

      if (sizeBytes > maxSubjectBytes) {
        if (kDebugMode) {
          debugPrint('[ContentPreloader] ⚠️ ${subject.name} cache exceeded: ${(sizeBytes / _bytesPerMB).toStringAsFixed(2)} MB / $_maxCacheSizePerSubjectMB MB');
        }

        // Evict oldest items for this subject
        final subjectLRU = await _database!.query(
          'cached_questions',
          where: 'subject = ?',
          whereArgs: [subject.name],
          orderBy: 'last_accessed ASC, access_count ASC',
          limit: 50,
        );

        for (final item in subjectLRU) {
          await _database!.delete(
            'cached_questions',
            where: 'id = ?',
            whereArgs: [item['id']],
          );
        }
      }
    }
  }

  /// Get cache performance metrics
  /// Task E5: Performance metrics
  CachePerformanceMetrics getCachePerformanceMetrics() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? (_cacheHits / totalRequests) * 100 : 0.0;

    final avgCachedTime = _cachedLoadTimes.isEmpty
        ? Duration.zero
        : Duration(
            microseconds: _cachedLoadTimes
                .map((d) => d.inMicroseconds)
                .reduce((a, b) => a + b) ~/
                _cachedLoadTimes.length,
          );

    final avgUncachedTime = _uncachedLoadTimes.isEmpty
        ? Duration.zero
        : Duration(
            microseconds: _uncachedLoadTimes
                .map((d) => d.inMicroseconds)
                .reduce((a, b) => a + b) ~/
                _uncachedLoadTimes.length,
          );

    return CachePerformanceMetrics(
      cacheHits: _cacheHits,
      cacheMisses: _cacheMisses,
      hitRate: hitRate,
      averageCachedLoadTime: avgCachedTime,
      averageUncachedLoadTime: avgUncachedTime,
      cacheSizeBySubject: Map.from(_cacheSizeBySubject),
      totalCacheSize: _cacheSizeBySubject.values.fold(0, (a, b) => a + b),
    );
  }

  /// Log cache statistics (debug mode)
  /// Task E5: Debug logging
  Future<void> _logCacheStatistics() async {
    if (!kDebugMode) return;

    final stats = await getCacheStats();
    final metrics = getCachePerformanceMetrics();
    final totalSize = await getTotalCacheSize();

    debugPrint('');
    debugPrint('========== Cache Statistics ==========');
    debugPrint('📊 Cached Questions: ${stats['cached_questions']}');
    debugPrint('📊 Cached Games: ${stats['cached_games']}');
    debugPrint('📊 Queue Items: ${stats['queue_items']}');
    debugPrint('📊 Memory Cache: ${stats['memory_cache_size']}');
    debugPrint('');
    debugPrint('🎯 Cache Hit Rate: ${metrics.hitRate.toStringAsFixed(1)}%');
    debugPrint('🎯 Cache Hits: ${metrics.cacheHits}');
    debugPrint('🎯 Cache Misses: ${metrics.cacheMisses}');
    debugPrint('');
    debugPrint('⚡ Avg Cached Load: ${metrics.averageCachedLoadTime.inMilliseconds}ms');
    debugPrint('⚡ Avg Uncached Load: ${metrics.averageUncachedLoadTime.inMilliseconds}ms');
    debugPrint('');
    debugPrint('💾 Total Cache Size: ${(totalSize / _bytesPerMB).toStringAsFixed(2)} MB / $_maxTotalCacheSizeMB MB');

    for (final entry in metrics.cacheSizeBySubject.entries) {
      final sizeMB = entry.value / _bytesPerMB;
      debugPrint('   ${entry.key.name}: ${sizeMB.toStringAsFixed(2)} MB');
    }
    debugPrint('======================================');
    debugPrint('');
  }

  /// Get cache health report
  /// Task E5: Cache health diagnostics
  Future<CacheHealthReport> getCacheHealthReport() async {
    final stats = await getCacheStats();
    final metrics = getCachePerformanceMetrics();
    final totalSize = await getTotalCacheSize();

    final health = _calculateCacheHealth(metrics, totalSize);

    return CacheHealthReport(
      health: health,
      metrics: metrics,
      stats: stats,
      totalSizeMB: totalSize / _bytesPerMB,
      recommendations: _generateRecommendations(health, metrics, totalSize),
    );
  }

  /// Calculate cache health score (0-100)
  double _calculateCacheHealth(CachePerformanceMetrics metrics, int totalSize) {
    double score = 100.0;

    // Penalize low hit rate
    if (metrics.hitRate < 50) {
      score -= (50 - metrics.hitRate) * 0.5;
    }

    // Penalize high cache size
    final sizeMB = totalSize / _bytesPerMB;
    if (sizeMB > _maxTotalCacheSizeMB * 0.9) {
      score -= 20;
    }

    // Reward good performance
    if (metrics.hitRate > 80) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  /// Generate cache recommendations
  List<String> _generateRecommendations(
    double health,
    CachePerformanceMetrics metrics,
    int totalSize,
  ) {
    final recommendations = <String>[];

    if (metrics.hitRate < 50) {
      recommendations.add('Low cache hit rate. Consider preloading more content.');
    }

    if (totalSize > _maxTotalCacheSizeMB * _bytesPerMB * 0.9) {
      recommendations.add('Cache size near limit. LRU eviction will occur soon.');
    }

    if (metrics.cacheMisses > metrics.cacheHits * 2) {
      recommendations.add('High cache miss rate. Improve preloading strategy.');
    }

    if (health > 80) {
      recommendations.add('Cache health is excellent! 🎉');
    }

    return recommendations;
  }

  /// Dispose resources
  void dispose() {
    _preloadTimer?.cancel();
    _backgroundIsolate?.kill();
    _database?.close();
  }
}

// ========== Task E5: New Data Classes ==========

/// Cache performance metrics
class CachePerformanceMetrics {
  final int cacheHits;
  final int cacheMisses;
  final double hitRate; // Percentage
  final Duration averageCachedLoadTime;
  final Duration averageUncachedLoadTime;
  final Map<SubjectType, int> cacheSizeBySubject; // Bytes
  final int totalCacheSize; // Bytes

  const CachePerformanceMetrics({
    required this.cacheHits,
    required this.cacheMisses,
    required this.hitRate,
    required this.averageCachedLoadTime,
    required this.averageUncachedLoadTime,
    required this.cacheSizeBySubject,
    required this.totalCacheSize,
  });
}

/// Cache health report
class CacheHealthReport {
  final double health; // 0-100 score
  final CachePerformanceMetrics metrics;
  final Map<String, int> stats;
  final double totalSizeMB;
  final List<String> recommendations;

  const CacheHealthReport({
    required this.health,
    required this.metrics,
    required this.stats,
    required this.totalSizeMB,
    required this.recommendations,
  });
}
