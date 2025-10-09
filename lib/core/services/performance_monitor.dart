import 'package:flutter/foundation.dart';
import 'dart:async';
import 'analytics_service.dart';

/// Performance Monitor for Phase E Task E5
/// Tracks load times, cache hit rates, and performance metrics
class PerformanceMonitor {
  static PerformanceMonitor? _instance;
  
  static PerformanceMonitor get instance {
    _instance ??= PerformanceMonitor._();
    return _instance!;
  }
  
  PerformanceMonitor._();

  final AnalyticsService _analyticsService = AnalyticsService();
  
  // Performance metrics
  final List<double> _loadTimes = [];
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _apiCalls = 0;
  int _totalNavigations = 0;
  
  // Slow operation tracking
  final List<SlowOperation> _slowOperations = [];
  
  // Performance targets
  static const double _targetAverageLoadTime = 1.0; // 1 second
  static const double _target95thPercentile = 2.0; // 2 seconds
  static const double _targetCacheHitRate = 0.90; // 90%
  static const double _targetApiCallRate = 0.05; // 5%
  static const double _slowOperationThreshold = 0.5; // 500ms

  /// Track a load operation
  Future<T> trackLoadOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      final duration = stopwatch.elapsedMilliseconds / 1000.0; // Convert to seconds
      _recordLoadTime(duration);
      
      // Track slow operations
      if (duration > _slowOperationThreshold) {
        _recordSlowOperation(operationName, duration, metadata);
      }
      
      if (kDebugMode) {
        debugPrint('[PerformanceMonitor] $operationName completed in ${duration.toStringAsFixed(3)}s');
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds / 1000.0;
      
      if (kDebugMode) {
        debugPrint('[PerformanceMonitor] $operationName failed after ${duration.toStringAsFixed(3)}s: $e');
      }
      
      rethrow;
    }
  }

  /// Record a load time
  void _recordLoadTime(double seconds) {
    _loadTimes.add(seconds);
    
    // Keep only last 100 measurements
    if (_loadTimes.length > 100) {
      _loadTimes.removeAt(0);
    }
  }

  /// Record a cache hit
  void recordCacheHit() {
    _cacheHits++;
    _totalNavigations++;
  }

  /// Record a cache miss
  void recordCacheMiss() {
    _cacheMisses++;
    _totalNavigations++;
  }

  /// Record an API call
  void recordApiCall() {
    _apiCalls++;
  }

  /// Record a slow operation
  void _recordSlowOperation(String operationName, double duration, Map<String, dynamic>? metadata) {
    final slowOp = SlowOperation(
      operationName: operationName,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    
    _slowOperations.add(slowOp);
    
    // Keep only last 50 slow operations
    if (_slowOperations.length > 50) {
      _slowOperations.removeAt(0);
    }
    
    if (kDebugMode) {
      debugPrint('[PerformanceMonitor] ⚠️ Slow operation: $operationName took ${duration.toStringAsFixed(3)}s');
      if (metadata != null) {
        debugPrint('[PerformanceMonitor] Metadata: $metadata');
      }
    }
    
    // Track in analytics
    _analyticsService.trackEvent('slow_operation', {
      'operation_name': operationName,
      'duration_seconds': duration,
      'timestamp': DateTime.now().toIso8601String(),
      ...?metadata,
    });
  }

  /// Get average load time
  double getAverageLoadTime() {
    if (_loadTimes.isEmpty) return 0.0;
    return _loadTimes.reduce((a, b) => a + b) / _loadTimes.length;
  }

  /// Get 95th percentile load time
  double get95thPercentileLoadTime() {
    if (_loadTimes.isEmpty) return 0.0;
    
    final sorted = List<double>.from(_loadTimes)..sort();
    final index = (sorted.length * 0.95).floor();
    return sorted[index.clamp(0, sorted.length - 1)];
  }

  /// Get cache hit rate
  double getCacheHitRate() {
    final total = _cacheHits + _cacheMisses;
    if (total == 0) return 0.0;
    return _cacheHits / total;
  }

  /// Get API call rate
  double getApiCallRate() {
    if (_totalNavigations == 0) return 0.0;
    return _apiCalls / _totalNavigations;
  }

  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    final avgLoadTime = getAverageLoadTime();
    final p95LoadTime = get95thPercentileLoadTime();
    final cacheHitRate = getCacheHitRate();
    final apiCallRate = getApiCallRate();
    
    return {
      'load_times': {
        'average': avgLoadTime,
        'average_ms': (avgLoadTime * 1000).round(),
        '95th_percentile': p95LoadTime,
        '95th_percentile_ms': (p95LoadTime * 1000).round(),
        'target_average': _targetAverageLoadTime,
        'target_95th': _target95thPercentile,
        'meets_average_target': avgLoadTime <= _targetAverageLoadTime,
        'meets_95th_target': p95LoadTime <= _target95thPercentile,
        'sample_count': _loadTimes.length,
      },
      'cache_performance': {
        'hit_rate': cacheHitRate,
        'hit_rate_percent': (cacheHitRate * 100).toStringAsFixed(1) + '%',
        'hits': _cacheHits,
        'misses': _cacheMisses,
        'total': _cacheHits + _cacheMisses,
        'target_hit_rate': _targetCacheHitRate,
        'meets_target': cacheHitRate >= _targetCacheHitRate,
      },
      'api_calls': {
        'count': _apiCalls,
        'rate': apiCallRate,
        'rate_percent': (apiCallRate * 100).toStringAsFixed(1) + '%',
        'total_navigations': _totalNavigations,
        'target_rate': _targetApiCallRate,
        'meets_target': apiCallRate <= _targetApiCallRate,
      },
      'slow_operations': {
        'count': _slowOperations.length,
        'threshold_seconds': _slowOperationThreshold,
        'recent': _slowOperations.take(10).map((op) => {
          'operation': op.operationName,
          'duration': op.duration,
          'duration_ms': (op.duration * 1000).round(),
          'timestamp': op.timestamp.toIso8601String(),
        }).toList(),
      },
      'overall_health': {
        'meets_all_targets': avgLoadTime <= _targetAverageLoadTime &&
            p95LoadTime <= _target95thPercentile &&
            cacheHitRate >= _targetCacheHitRate &&
            apiCallRate <= _targetApiCallRate,
        'health_score': _calculateHealthScore(avgLoadTime, p95LoadTime, cacheHitRate, apiCallRate),
      },
    };
  }

  /// Calculate overall health score (0-100)
  int _calculateHealthScore(double avgLoadTime, double p95LoadTime, double cacheHitRate, double apiCallRate) {
    int score = 100;
    
    // Average load time (max -30 points)
    if (avgLoadTime > _targetAverageLoadTime) {
      final penalty = ((avgLoadTime - _targetAverageLoadTime) / _targetAverageLoadTime * 30).round();
      score -= penalty.clamp(0, 30);
    }
    
    // 95th percentile (max -30 points)
    if (p95LoadTime > _target95thPercentile) {
      final penalty = ((p95LoadTime - _target95thPercentile) / _target95thPercentile * 30).round();
      score -= penalty.clamp(0, 30);
    }
    
    // Cache hit rate (max -25 points)
    if (cacheHitRate < _targetCacheHitRate) {
      final penalty = ((_targetCacheHitRate - cacheHitRate) / _targetCacheHitRate * 25).round();
      score -= penalty.clamp(0, 25);
    }
    
    // API call rate (max -15 points)
    if (apiCallRate > _targetApiCallRate) {
      final penalty = ((apiCallRate - _targetApiCallRate) / _targetApiCallRate * 15).round();
      score -= penalty.clamp(0, 15);
    }
    
    return score.clamp(0, 100);
  }

  /// Print performance report to console
  void printPerformanceReport() {
    if (!kDebugMode) return;
    
    final report = getPerformanceReport();
    
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('📊 PERFORMANCE REPORT');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('');
    
    // Load times
    final loadTimes = report['load_times'] as Map<String, dynamic>;
    debugPrint('⏱️  LOAD TIMES:');
    debugPrint('   Average: ${loadTimes['average_ms']}ms (target: ${(loadTimes['target_average'] * 1000).round()}ms) ${loadTimes['meets_average_target'] ? '✅' : '❌'}');
    debugPrint('   95th Percentile: ${loadTimes['95th_percentile_ms']}ms (target: ${(loadTimes['target_95th'] * 1000).round()}ms) ${loadTimes['meets_95th_target'] ? '✅' : '❌'}');
    debugPrint('   Sample Count: ${loadTimes['sample_count']}');
    debugPrint('');
    
    // Cache performance
    final cache = report['cache_performance'] as Map<String, dynamic>;
    debugPrint('💾 CACHE PERFORMANCE:');
    debugPrint('   Hit Rate: ${cache['hit_rate_percent']} (target: ${(cache['target_hit_rate'] * 100).toStringAsFixed(0)}%) ${cache['meets_target'] ? '✅' : '❌'}');
    debugPrint('   Hits: ${cache['hits']}');
    debugPrint('   Misses: ${cache['misses']}');
    debugPrint('');
    
    // API calls
    final api = report['api_calls'] as Map<String, dynamic>;
    debugPrint('🌐 API CALLS:');
    debugPrint('   Rate: ${api['rate_percent']} (target: <${(api['target_rate'] * 100).toStringAsFixed(0)}%) ${api['meets_target'] ? '✅' : '❌'}');
    debugPrint('   Count: ${api['count']} / ${api['total_navigations']} navigations');
    debugPrint('');
    
    // Slow operations
    final slow = report['slow_operations'] as Map<String, dynamic>;
    debugPrint('⚠️  SLOW OPERATIONS (>${(slow['threshold_seconds'] * 1000).round()}ms):');
    debugPrint('   Count: ${slow['count']}');
    if (slow['count'] > 0) {
      final recent = slow['recent'] as List;
      debugPrint('   Recent:');
      for (final op in recent.take(5)) {
        debugPrint('     - ${op['operation']}: ${op['duration_ms']}ms');
      }
    }
    debugPrint('');
    
    // Overall health
    final health = report['overall_health'] as Map<String, dynamic>;
    debugPrint('🏥 OVERALL HEALTH:');
    debugPrint('   Score: ${health['health_score']}/100');
    debugPrint('   Meets All Targets: ${health['meets_all_targets'] ? '✅ YES' : '❌ NO'}');
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('');
  }

  /// Send performance report to analytics
  void sendPerformanceReportToAnalytics() {
    final report = getPerformanceReport();
    _analyticsService.trackEvent('performance_report', report);
  }

  /// Reset all metrics
  void reset() {
    _loadTimes.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    _apiCalls = 0;
    _totalNavigations = 0;
    _slowOperations.clear();
    
    if (kDebugMode) {
      debugPrint('[PerformanceMonitor] Metrics reset');
    }
  }
}

/// Slow operation record
class SlowOperation {
  final String operationName;
  final double duration;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  SlowOperation({
    required this.operationName,
    required this.duration,
    required this.timestamp,
    this.metadata,
  });
}

