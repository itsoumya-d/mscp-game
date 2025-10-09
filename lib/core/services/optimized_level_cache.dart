import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/question.dart';
import 'game_session_service.dart';
import 'unlimited_level_generator.dart';
import 'performance_analytics_service.dart';
import 'skill_id_registry.dart';

/// Optimized level cache service with intelligent prefetching and memory management
class OptimizedLevelCache {
  static OptimizedLevelCache? _instance;
  static OptimizedLevelCache get instance => _instance ??= OptimizedLevelCache._internal();
  
  OptimizedLevelCache._internal();

  // Cache configuration
  static const int _maxCacheSize = 50; // Maximum levels in memory
  static const int _prefetchDistance = 3; // Prefetch 3 levels ahead
  static const int _maxDiskCache = 200; // Maximum levels on disk
  static const Duration _cacheExpiry = Duration(hours: 24);
  
  // In-memory cache with LRU eviction
  final LinkedHashMap<String, CachedLevel> _memoryCache = LinkedHashMap();
  
  // Services
  final UnlimitedLevelGenerator _levelGenerator = UnlimitedLevelGenerator.getInstance();
  final PerformanceAnalyticsService _analytics = PerformanceAnalyticsService.instance;
  
  // Cache statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _prefetchCount = 0;
  
  /// Initialize the cache system
  Future<void> initialize() async {
    await _loadCacheFromDisk();
    await _cleanExpiredCache();
    debugPrint('[OptimizedLevelCache] Initialized with ${_memoryCache.length} cached levels');
  }

  /// Get a level with intelligent caching and prefetching
  Future<SevenQuestionGameSession?> getLevel({
    required SubjectType subject,
    required int level,
    String? skillId,
  }) async {
    final startTime = DateTime.now();
    final cacheKey = _generateCacheKey(subject, level, skillId);
    
    try {
      // Check memory cache first
      if (_memoryCache.containsKey(cacheKey)) {
        final cachedLevel = _memoryCache[cacheKey]!;
        
        // Move to end (most recently used)
        _memoryCache.remove(cacheKey);
        _memoryCache[cacheKey] = cachedLevel;
        
        _cacheHits++;
        
        // Record performance
        final loadTime = DateTime.now().difference(startTime);
        _analytics.recordLevelLoad(
          subject: subject,
          level: level,
          loadTime: loadTime,
          fromCache: true,
          success: true,
        );
        
        // Trigger prefetch for nearby levels
        _triggerPrefetch(subject, level, skillId);
        
        return cachedLevel.gameSession;
      }
      
      // Check disk cache
      final diskCached = await _loadFromDisk(cacheKey);
      if (diskCached != null && !diskCached.isExpired) {
        // Add to memory cache
        _addToMemoryCache(cacheKey, diskCached);
        _cacheHits++;
        
        // Record performance
        final loadTime = DateTime.now().difference(startTime);
        _analytics.recordLevelLoad(
          subject: subject,
          level: level,
          loadTime: loadTime,
          fromCache: true,
          success: true,
        );
        
        // Trigger prefetch
        _triggerPrefetch(subject, level, skillId);
        
        return diskCached.gameSession;
      }
      
      _cacheMisses++;
      
      // Generate new level
      final gameSession = await _generateLevel(subject, level, skillId);
      if (gameSession != null) {
        final cachedLevel = CachedLevel(
          gameSession: gameSession,
          createdAt: DateTime.now(),
          accessCount: 1,
        );
        
        // Cache in memory and disk
        _addToMemoryCache(cacheKey, cachedLevel);
        await _saveToDisk(cacheKey, cachedLevel);
        
        // Record performance
        final loadTime = DateTime.now().difference(startTime);
        _analytics.recordLevelLoad(
          subject: subject,
          level: level,
          loadTime: loadTime,
          fromCache: false,
          success: true,
        );
        
        // Trigger prefetch
        _triggerPrefetch(subject, level, skillId);
        
        return gameSession;
      }
      
      // Record failed load
      final loadTime = DateTime.now().difference(startTime);
      _analytics.recordLevelLoad(
        subject: subject,
        level: level,
        loadTime: loadTime,
        fromCache: false,
        success: false,
        errorMessage: 'Failed to generate level',
      );
      
      return null;
    } catch (e) {
      // Record error
      final loadTime = DateTime.now().difference(startTime);
      _analytics.recordLevelLoad(
        subject: subject,
        level: level,
        loadTime: loadTime,
        fromCache: false,
        success: false,
        errorMessage: e.toString(),
      );
      
      debugPrint('[OptimizedLevelCache] Error getting level: $e');
      return null;
    }
  }

  /// Prefetch levels around the current level
  void _triggerPrefetch(SubjectType subject, int currentLevel, String? skillId) {
    // Don't block the main thread
    Future.microtask(() async {
      final levelsToPreload = <int>[];
      
      // Prefetch next levels
      for (int i = 1; i <= _prefetchDistance; i++) {
        levelsToPreload.add(currentLevel + i);
      }
      
      // Prefetch previous levels if not at the beginning
      if (currentLevel > 1) {
        for (int i = 1; i <= _prefetchDistance && currentLevel - i > 0; i++) {
          levelsToPreload.add(currentLevel - i);
        }
      }
      
      for (final level in levelsToPreload) {
        final cacheKey = _generateCacheKey(subject, level, skillId);
        
        // Skip if already cached
        if (_memoryCache.containsKey(cacheKey)) continue;
        
        // Check if exists on disk
        final diskCached = await _loadFromDisk(cacheKey);
        if (diskCached != null && !diskCached.isExpired) {
          _addToMemoryCache(cacheKey, diskCached);
          continue;
        }
        
        // Generate and cache
        final gameSession = await _generateLevel(subject, level, skillId);
        if (gameSession != null) {
          final cachedLevel = CachedLevel(
            gameSession: gameSession,
            createdAt: DateTime.now(),
            accessCount: 0,
          );
          
          _addToMemoryCache(cacheKey, cachedLevel);
          await _saveToDisk(cacheKey, cachedLevel);
          _prefetchCount++;
        }
      }
    });
  }

  /// Add level to memory cache with LRU eviction
  void _addToMemoryCache(String key, CachedLevel level) {
    // Remove if already exists
    _memoryCache.remove(key);
    
    // Add to end (most recently used)
    _memoryCache[key] = level;
    
    // Evict oldest if cache is full
    while (_memoryCache.length > _maxCacheSize) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }
  }

  /// Generate a new level
  Future<SevenQuestionGameSession?> _generateLevel(
    SubjectType subject, 
    int level, 
    String? skillId
  ) async {
    try {
      final targetSkillId = skillId ?? _getDefaultSkillForSubject(subject);
      final skillName = await _getSkillName(subject, targetSkillId);
      
      final result = await _levelGenerator.generateUnlimitedLevels(
        subject: subject,
        skillId: targetSkillId,
        skillName: skillName,
        numberOfLevels: 1,
        startingLevel: level,
      );
      
      if (result['success'] == true && result['levels'] != null) {
        final levels = result['levels'] as List<Map<String, dynamic>>;
        if (levels.isNotEmpty) {
          return _convertLevelToGameSession(levels.first, subject, level, targetSkillId);
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('[OptimizedLevelCache] Error generating level: $e');
      return null;
    }
  }

  /// Convert level data to game session
  SevenQuestionGameSession? _convertLevelToGameSession(
    Map<String, dynamic> levelData,
    SubjectType subject,
    int level,
    String skillId,
  ) {
    try {
      final questions = levelData['questions'] as List<dynamic>?;
      if (questions == null || questions.isEmpty) return null;

      final questionObjects = questions.map((q) {
        return Question(
          id: q['id'] ?? 'q_${DateTime.now().millisecondsSinceEpoch}',
          type: QuestionType.values.firstWhere(
            (type) => type.name == q['type'],
            orElse: () => QuestionType.multipleChoice,
          ),
          questionText: q['questionText'] ?? '',
          options: List<String>.from(q['options'] ?? []),
          correctAnswer: q['correctAnswer'] ?? '',
          explanation: q['explanation'] ?? '',
          hint: q['hint'] ?? '',
          difficulty: q['difficulty'] ?? level,
          subject: subject,
        );
      }).toList();

      // Ensure exactly 7 questions
      while (questionObjects.length < 7) {
        questionObjects.add(_generateFallbackQuestion(subject, level, questionObjects.length + 1));
      }

      return SevenQuestionGameSession(
        id: levelData['id'] ?? 'cached_${DateTime.now().millisecondsSinceEpoch}',
        subject: subject,
        level: level,
        skillId: skillId,
        questions: questionObjects,
        userAnswers: List.filled(7, ''),
        answerCorrectness: List.filled(7, false),
        currentQuestionIndex: 0,
        startTime: DateTime.now(),
        score: 0,
        isCompleted: false,
      );
    } catch (e) {
      debugPrint('[OptimizedLevelCache] Error converting level: $e');
      return null;
    }
  }

  /// Generate fallback question
  Question _generateFallbackQuestion(SubjectType subject, int level, int questionNumber) {
    return Question(
      id: 'fallback_${subject.name}_${level}_$questionNumber',
      type: QuestionType.multipleChoice,
      questionText: 'Sample question $questionNumber for ${subject.name} level $level',
      options: ['Option A', 'Option B', 'Option C', 'Option D'],
      correctAnswer: 'Option A',
      explanation: 'This is a fallback question.',
      hint: 'Choose the first option.',
      difficulty: level,
      subject: subject,
    );
  }

  /// Save cached level to disk
  Future<void> _saveToDisk(String key, CachedLevel level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'gameSession': _gameSessionToJson(level.gameSession),
        'createdAt': level.createdAt.toIso8601String(),
        'accessCount': level.accessCount,
      };
      
      await prefs.setString('cache_$key', jsonEncode(data));
      
      // Manage disk cache size
      await _manageDiskCacheSize();
    } catch (e) {
      debugPrint('[OptimizedLevelCache] Error saving to disk: $e');
    }
  }

  /// Load cached level from disk
  Future<CachedLevel?> _loadFromDisk(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = prefs.getString('cache_$key');
      
      if (dataJson == null) return null;
      
      final data = jsonDecode(dataJson);
      final gameSession = _gameSessionFromJson(data['gameSession']);
      
      if (gameSession == null) return null;
      
      return CachedLevel(
        gameSession: gameSession,
        createdAt: DateTime.parse(data['createdAt']),
        accessCount: data['accessCount'] ?? 0,
      );
    } catch (e) {
      debugPrint('[OptimizedLevelCache] Error loading from disk: $e');
      return null;
    }
  }

  /// Load all cache from disk to memory
  Future<void> _loadCacheFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_')).toList();
      
      for (final key in keys) {
        final cacheKey = key.substring(6); // Remove 'cache_' prefix
        final cachedLevel = await _loadFromDisk(cacheKey);
        
        if (cachedLevel != null && !cachedLevel.isExpired) {
          _memoryCache[cacheKey] = cachedLevel;
        }
      }
    } catch (e) {
      debugPrint('[OptimizedLevelCache] Error loading cache from disk: $e');
    }
  }

  /// Clean expired cache entries
  Future<void> _cleanExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = <String>[];
      
      // Clean memory cache
      _memoryCache.removeWhere((key, level) => level.isExpired);
      
      // Clean disk cache
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_')).toList();
      
      for (final key in keys) {
        final cacheKey = key.substring(6);
        final cachedLevel = await _loadFromDisk(cacheKey);
        
        if (cachedLevel == null || cachedLevel.isExpired) {
          keysToRemove.add(key);
        }
      }
      
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
      
      debugPrint('[OptimizedLevelCache] Cleaned ${keysToRemove.length} expired entries');
    } catch (e) {
      debugPrint('[OptimizedLevelCache] Error cleaning expired cache: $e');
    }
  }

  /// Manage disk cache size by removing least recently used entries
  Future<void> _manageDiskCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_')).toList();
      
      if (keys.length <= _maxDiskCache) return;
      
      // Load all entries with access info
      final entries = <MapEntry<String, CachedLevel>>[];
      
      for (final key in keys) {
        final cacheKey = key.substring(6);
        final cachedLevel = await _loadFromDisk(cacheKey);
        
        if (cachedLevel != null) {
          entries.add(MapEntry(key, cachedLevel));
        }
      }
      
      // Sort by access count and creation time (LRU)
      entries.sort((a, b) {
        final accessCompare = a.value.accessCount.compareTo(b.value.accessCount);
        if (accessCompare != 0) return accessCompare;
        return a.value.createdAt.compareTo(b.value.createdAt);
      });
      
      // Remove oldest entries
      final toRemove = entries.length - _maxDiskCache;
      for (int i = 0; i < toRemove; i++) {
        await prefs.remove(entries[i].key);
      }
      
      debugPrint('[OptimizedLevelCache] Removed $toRemove old cache entries');
    } catch (e) {
      debugPrint('[OptimizedLevelCache] Error managing disk cache size: $e');
    }
  }

  /// Convert game session to JSON
  Map<String, dynamic> _gameSessionToJson(SevenQuestionGameSession session) {
    return {
      'id': session.id,
      'subject': session.subject.name,
      'level': session.level,
      'skillId': session.skillId,
      'questions': session.questions.map((q) => {
        'id': q.id,
        'type': q.type.name,
        'questionText': q.questionText,
        'options': q.options,
        'correctAnswer': q.correctAnswer,
        'explanation': q.explanation,
        'hint': q.hint,
        'difficulty': q.difficulty,
      }).toList(),
      'startTime': session.startTime.toIso8601String(),
    };
  }

  /// Convert JSON to game session
  SevenQuestionGameSession? _gameSessionFromJson(Map<String, dynamic> json) {
    try {
      final questions = (json['questions'] as List).map((q) {
        return Question(
          id: q['id'],
          type: QuestionType.values.firstWhere((type) => type.name == q['type']),
          questionText: q['questionText'],
          options: (q['options'] as List<dynamic>).cast<String>(),
          correctAnswer: q['correctAnswer'],
          explanation: q['explanation'],
          hint: q['hint'],
          difficulty: q['difficulty'],
          subject: SubjectType.values.firstWhere((s) => s.name == json['subject']),
        );
      }).toList();

      return SevenQuestionGameSession(
        id: json['id'],
        subject: SubjectType.values.firstWhere((s) => s.name == json['subject']),
        level: json['level'],
        skillId: json['skillId'],
        questions: questions,
        userAnswers: List.filled(7, ''),
        answerCorrectness: List.filled(7, false),
        currentQuestionIndex: 0,
        startTime: DateTime.parse(json['startTime']),
        score: 0,
        isCompleted: false,
      );
    } catch (e) {
      debugPrint('[OptimizedLevelCache] Error converting JSON to game session: $e');
      return null;
    }
  }

  /// Generate cache key
  String _generateCacheKey(SubjectType subject, int level, String? skillId) {
    final skill = skillId ?? _getDefaultSkillForSubject(subject);
    return '${subject.name}_${skill}_$level';
  }

  /// Get default skill for subject using the centralized SkillIdRegistry
  String _getDefaultSkillForSubject(SubjectType subject) {
    // Use the centralized SkillIdRegistry to ensure consistency
    return SkillIdRegistry.getDefaultSkillId(subject);
  }

  /// Get skill name using the centralized SkillIdRegistry
  Future<String> _getSkillName(SubjectType subject, String skillId) async {
    // Use the centralized SkillIdRegistry to ensure consistency
    return SkillIdRegistry.getSkillName(skillId);
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'memoryCache': _memoryCache.length,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'hitRate': _cacheHits + _cacheMisses > 0 
          ? (_cacheHits / (_cacheHits + _cacheMisses) * 100).toStringAsFixed(1)
          : '0.0',
      'prefetchCount': _prefetchCount,
    };
  }

  /// Clear all cache
  Future<void> clearCache() async {
    _memoryCache.clear();
    
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('cache_')).toList();
    
    for (final key in keys) {
      await prefs.remove(key);
    }
    
    debugPrint('[OptimizedLevelCache] Cache cleared');
  }

  /// Preload levels for a subject
  Future<void> preloadLevelsForSubject(SubjectType subject, {int count = 10}) async {
    for (int level = 1; level <= count; level++) {
      await getLevel(subject: subject, level: level);
    }
  }
}

/// Cached level data
class CachedLevel {
  final SevenQuestionGameSession gameSession;
  final DateTime createdAt;
  int accessCount;

  CachedLevel({
    required this.gameSession,
    required this.createdAt,
    required this.accessCount,
  });

  bool get isExpired => DateTime.now().difference(createdAt) > OptimizedLevelCache._cacheExpiry;
}