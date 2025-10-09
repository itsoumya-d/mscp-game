import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/question.dart';
import 'game_session_service.dart';

/// Smart caching service with LRU eviction and predictive preloading
class SmartCacheService {
  static SmartCacheService? _instance;
  
  static SmartCacheService getInstance() {
    return _instance ??= SmartCacheService._();
  }
  
  SmartCacheService._();
  
  // LRU Cache for game sessions
  final _sessionCache = LRUCache<String, SevenQuestionGameSession>(maxSize: 50);
  
  // LRU Cache for individual questions
  final _questionCache = LRUCache<String, Question>(maxSize: 200);
  
  // Access pattern tracking
  final Map<String, AccessPattern> _accessPatterns = {};
  
  // Preloading queue
  final Set<String> _preloadingQueue = {};
  
  bool _isInitialized = false;
  
  /// Initialize the smart cache service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[SmartCache] Already initialized');
      return;
    }
    
    debugPrint('[SmartCache] Initializing smart cache service...');
    _isInitialized = true;
    
    // Start background preloading based on patterns
    _startPredictivePreloading();
    
    debugPrint('[SmartCache] Smart cache service initialized');
  }
  
  /// Cache a game session
  void cacheSession(String key, SevenQuestionGameSession session) {
    _sessionCache.put(key, session);
    _trackAccess(key, CacheType.session);
    debugPrint('[SmartCache] Cached session: $key');
  }
  
  /// Get a cached game session
  SevenQuestionGameSession? getSession(String key) {
    final session = _sessionCache.get(key);
    if (session != null) {
      _trackAccess(key, CacheType.session);
      debugPrint('[SmartCache] Cache hit for session: $key');
    } else {
      debugPrint('[SmartCache] Cache miss for session: $key');
    }
    return session;
  }
  
  /// Cache a question
  void cacheQuestion(String key, Question question) {
    _questionCache.put(key, question);
    _trackAccess(key, CacheType.question);
  }
  
  /// Get a cached question
  Question? getQuestion(String key) {
    final question = _questionCache.get(key);
    if (question != null) {
      _trackAccess(key, CacheType.question);
    }
    return question;
  }
  
  /// Track access patterns for predictive preloading
  void _trackAccess(String key, CacheType type) {
    final pattern = _accessPatterns.putIfAbsent(
      key,
      () => AccessPattern(key: key, type: type),
    );
    pattern.recordAccess();
  }
  
  /// Get cache statistics
  Map<String, dynamic> getStatistics() {
    return {
      'session_cache_size': _sessionCache.size,
      'session_cache_max': _sessionCache.maxSize,
      'session_cache_hit_rate': _sessionCache.hitRate,
      'question_cache_size': _questionCache.size,
      'question_cache_max': _questionCache.maxSize,
      'question_cache_hit_rate': _questionCache.hitRate,
      'tracked_patterns': _accessPatterns.length,
      'preloading_queue': _preloadingQueue.length,
    };
  }
  
  /// Start predictive preloading based on access patterns
  void _startPredictivePreloading() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }
      
      _preloadFrequentlyAccessedContent();
    });
  }
  
  /// Preload frequently accessed content
  Future<void> _preloadFrequentlyAccessedContent() async {
    // Get top 10 most frequently accessed items
    final topPatterns = _accessPatterns.values
        .where((p) => p.accessCount > 2)
        .toList()
      ..sort((a, b) => b.accessCount.compareTo(a.accessCount));
    
    final toPreload = topPatterns.take(10).where((p) {
      return !_preloadingQueue.contains(p.key) &&
             (p.type == CacheType.session ? !_sessionCache.contains(p.key) : !_questionCache.contains(p.key));
    }).toList();
    
    if (toPreload.isEmpty) return;
    
    debugPrint('[SmartCache] Preloading ${toPreload.length} frequently accessed items');
    
    for (final pattern in toPreload) {
      _preloadingQueue.add(pattern.key);
      // Preloading logic would go here
      // For now, just remove from queue after a delay
      Future.delayed(const Duration(seconds: 5), () {
        _preloadingQueue.remove(pattern.key);
      });
    }
  }
  
  /// Clear all caches
  void clearAll() {
    _sessionCache.clear();
    _questionCache.clear();
    _accessPatterns.clear();
    _preloadingQueue.clear();
    debugPrint('[SmartCache] All caches cleared');
  }
  
  /// Clear session cache only
  void clearSessions() {
    _sessionCache.clear();
    debugPrint('[SmartCache] Session cache cleared');
  }
  
  /// Clear question cache only
  void clearQuestions() {
    _questionCache.clear();
    debugPrint('[SmartCache] Question cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'session_cache': {
        'size': _sessionCache.size,
        'max_size': _sessionCache.maxSize,
        'hits': _sessionCache.hits,
        'misses': _sessionCache.misses,
        'hit_rate': _sessionCache.hits + _sessionCache.misses > 0
            ? (_sessionCache.hits / (_sessionCache.hits + _sessionCache.misses) * 100).toStringAsFixed(2) + '%'
            : '0%',
      },
      'question_cache': {
        'size': _questionCache.size,
        'max_size': _questionCache.maxSize,
        'hits': _questionCache.hits,
        'misses': _questionCache.misses,
        'hit_rate': _questionCache.hits + _questionCache.misses > 0
            ? (_questionCache.hits / (_questionCache.hits + _questionCache.misses) * 100).toStringAsFixed(2) + '%'
            : '0%',
      },
      'access_patterns': _accessPatterns.length,
      'preloading_queue': _preloadingQueue.length,
      'is_initialized': _isInitialized,
    };
  }
}

/// LRU (Least Recently Used) Cache implementation
class LRUCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap();
  int _hits = 0;
  int _misses = 0;
  
  LRUCache({required this.maxSize});
  
  /// Put an item in the cache
  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      // Move to end (most recently used)
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      // Remove least recently used (first item)
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }
  
  /// Get an item from the cache
  V? get(K key) {
    if (_cache.containsKey(key)) {
      // Move to end (most recently used)
      final value = _cache.remove(key)!;
      _cache[key] = value;
      _hits++;
      return value;
    }
    _misses++;
    return null;
  }
  
  /// Check if cache contains key
  bool contains(K key) => _cache.containsKey(key);

  /// Get cache size
  int get size => _cache.length;

  /// Get hit count
  int get hits => _hits;

  /// Get miss count
  int get misses => _misses;
  
  /// Get hit rate
  double get hitRate {
    final total = _hits + _misses;
    return total > 0 ? _hits / total : 0.0;
  }
  
  /// Clear the cache
  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }
  
  /// Get all keys
  Iterable<K> get keys => _cache.keys;
  
  /// Get all values
  Iterable<V> get values => _cache.values;
}

/// Access pattern tracking
class AccessPattern {
  final String key;
  final CacheType type;
  int accessCount = 0;
  DateTime lastAccessed = DateTime.now();
  DateTime firstAccessed = DateTime.now();
  
  AccessPattern({
    required this.key,
    required this.type,
  });
  
  void recordAccess() {
    accessCount++;
    lastAccessed = DateTime.now();
  }
  
  /// Get access frequency (accesses per hour)
  double get frequency {
    final duration = DateTime.now().difference(firstAccessed);
    if (duration.inHours == 0) return accessCount.toDouble();
    return accessCount / duration.inHours;
  }
  
  /// Check if recently accessed (within last 5 minutes)
  bool get isRecentlyAccessed {
    return DateTime.now().difference(lastAccessed).inMinutes < 5;
  }
}

/// Cache type enum
enum CacheType {
  session,
  question,
}

