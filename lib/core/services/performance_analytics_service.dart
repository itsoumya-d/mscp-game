import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';

/// Service for monitoring and analyzing performance metrics
class PerformanceAnalyticsService {
  static PerformanceAnalyticsService? _instance;
  static PerformanceAnalyticsService get instance => _instance ??= PerformanceAnalyticsService._internal();
  
  PerformanceAnalyticsService._internal();

  // Performance tracking
  final Map<String, List<PerformanceMetric>> _metrics = {};
  final Map<String, Timer> _activeTimers = {};
  
  // Configuration
  static const int _maxMetricsPerType = 100;
  static const Duration _metricRetentionPeriod = Duration(days: 7);
  
  /// Start timing an operation
  void startTiming(String operationId, String operationType) {
    final startTime = DateTime.now();
    _activeTimers[operationId] = Timer(Duration.zero, () {});
    
    // Store start time in a temporary metric
    final metric = PerformanceMetric(
      id: operationId,
      type: operationType,
      startTime: startTime,
      duration: Duration.zero,
      success: false,
      metadata: {},
    );
    
    _addMetric(metric);
  }

  /// End timing an operation
  void endTiming(String operationId, {
    bool success = true,
    Map<String, dynamic>? metadata,
    String? errorMessage,
  }) {
    final endTime = DateTime.now();
    
    // Find the corresponding start metric
    final typeMetrics = _metrics.values.expand((list) => list).toList();
    final startMetric = typeMetrics.firstWhere(
      (m) => m.id == operationId,
      orElse: () => PerformanceMetric(
        id: operationId,
        type: 'unknown',
        startTime: endTime,
        duration: Duration.zero,
        success: false,
        metadata: {},
      ),
    );
    
    final duration = endTime.difference(startMetric.startTime);
    
    final completedMetric = PerformanceMetric(
      id: operationId,
      type: startMetric.type,
      startTime: startMetric.startTime,
      endTime: endTime,
      duration: duration,
      success: success,
      metadata: {
        ...startMetric.metadata,
        ...?metadata,
        if (errorMessage != null) 'error': errorMessage,
      },
    );
    
    _addMetric(completedMetric);
    _activeTimers.remove(operationId);
  }

  /// Record a level loading event
  void recordLevelLoad({
    required SubjectType subject,
    required int level,
    required Duration loadTime,
    required bool fromCache,
    required bool success,
    String? errorMessage,
  }) {
    final metric = PerformanceMetric(
      id: 'level_load_${subject.name}_$level',
      type: 'level_load',
      startTime: DateTime.now().subtract(loadTime),
      endTime: DateTime.now(),
      duration: loadTime,
      success: success,
      metadata: {
        'subject': subject.name,
        'level': level,
        'fromCache': fromCache,
        if (errorMessage != null) 'error': errorMessage,
      },
    );
    
    _addMetric(metric);
  }

  /// Record cache performance
  void recordCachePerformance({
    required String operation,
    required Duration duration,
    required bool hit,
    required int cacheSize,
    Map<String, dynamic>? additionalData,
  }) {
    final metric = PerformanceMetric(
      id: 'cache_${operation}_${DateTime.now().millisecondsSinceEpoch}',
      type: 'cache_operation',
      startTime: DateTime.now().subtract(duration),
      endTime: DateTime.now(),
      duration: duration,
      success: true,
      metadata: {
        'operation': operation,
        'hit': hit,
        'cacheSize': cacheSize,
        ...?additionalData,
      },
    );
    
    _addMetric(metric);
  }

  /// Record UI performance
  void recordUIPerformance({
    required String screen,
    required String operation,
    required Duration duration,
    required bool success,
    Map<String, dynamic>? metadata,
  }) {
    final metric = PerformanceMetric(
      id: 'ui_${screen}_${operation}_${DateTime.now().millisecondsSinceEpoch}',
      type: 'ui_performance',
      startTime: DateTime.now().subtract(duration),
      endTime: DateTime.now(),
      duration: duration,
      success: success,
      metadata: {
        'screen': screen,
        'operation': operation,
        ...?metadata,
      },
    );
    
    _addMetric(metric);
  }

  /// Get performance analytics for a specific type
  PerformanceAnalytics getAnalytics(String type) {
    final metrics = _metrics[type] ?? [];
    
    if (metrics.isEmpty) {
      return PerformanceAnalytics(
        type: type,
        totalOperations: 0,
        successRate: 0.0,
        averageDuration: Duration.zero,
        medianDuration: Duration.zero,
        p95Duration: Duration.zero,
        fastestDuration: Duration.zero,
        slowestDuration: Duration.zero,
        recentTrend: 'stable',
        recommendations: [],
      );
    }

    final successfulMetrics = metrics.where((m) => m.success).toList();
    final durations = metrics.map((m) => m.duration).toList()..sort();
    
    final averageDuration = Duration(
      microseconds: (durations.map((d) => d.inMicroseconds).reduce((a, b) => a + b) / durations.length).round(),
    );
    
    final medianDuration = durations[durations.length ~/ 2];
    final p95Index = ((durations.length - 1) * 0.95).round();
    final p95Duration = durations[p95Index];
    
    final recentTrend = _calculateTrend(metrics);
    final recommendations = _generateRecommendations(type, metrics);

    return PerformanceAnalytics(
      type: type,
      totalOperations: metrics.length,
      successRate: successfulMetrics.length / metrics.length,
      averageDuration: averageDuration,
      medianDuration: medianDuration,
      p95Duration: p95Duration,
      fastestDuration: durations.first,
      slowestDuration: durations.last,
      recentTrend: recentTrend,
      recommendations: recommendations,
    );
  }

  /// Get overall system performance summary
  Map<String, dynamic> getSystemPerformanceSummary() {
    final summary = <String, dynamic>{};
    
    for (final type in _metrics.keys) {
      final analytics = getAnalytics(type);
      summary[type] = {
        'totalOperations': analytics.totalOperations,
        'successRate': '${(analytics.successRate * 100).toStringAsFixed(1)}%',
        'averageDuration': '${analytics.averageDuration.inMilliseconds}ms',
        'p95Duration': '${analytics.p95Duration.inMilliseconds}ms',
        'trend': analytics.recentTrend,
        'recommendations': analytics.recommendations.length,
      };
    }
    
    return summary;
  }

  /// Get cache hit rate analytics
  Map<String, dynamic> getCacheAnalytics() {
    final cacheMetrics = _metrics['cache_operation'] ?? [];
    
    if (cacheMetrics.isEmpty) {
      return {
        'hitRate': '0.0%',
        'totalOperations': 0,
        'averageResponseTime': '0ms',
        'recommendations': ['No cache data available'],
      };
    }
    
    final hits = cacheMetrics.where((m) => m.metadata['hit'] == true).length;
    final hitRate = hits / cacheMetrics.length;
    
    final avgDuration = cacheMetrics.map((m) => m.duration.inMilliseconds).reduce((a, b) => a + b) / cacheMetrics.length;
    
    final recommendations = <String>[];
    if (hitRate < 0.7) {
      recommendations.add('Cache hit rate is low (${(hitRate * 100).toStringAsFixed(1)}%). Consider increasing cache size or improving prefetching.');
    }
    if (avgDuration > 100) {
      recommendations.add('Cache operations are slow (${avgDuration.toStringAsFixed(1)}ms average). Consider optimizing cache implementation.');
    }
    
    return {
      'hitRate': '${(hitRate * 100).toStringAsFixed(1)}%',
      'totalOperations': cacheMetrics.length,
      'averageResponseTime': '${avgDuration.toStringAsFixed(1)}ms',
      'recommendations': recommendations,
    };
  }

  /// Add a metric to the collection
  void _addMetric(PerformanceMetric metric) {
    final typeMetrics = _metrics[metric.type] ??= <PerformanceMetric>[];
    
    // Remove old metric with same ID if exists
    typeMetrics.removeWhere((m) => m.id == metric.id);
    
    // Add new metric
    typeMetrics.add(metric);
    
    // Maintain size limit
    if (typeMetrics.length > _maxMetricsPerType) {
      typeMetrics.removeAt(0);
    }
    
    // Clean old metrics
    _cleanOldMetrics();
  }

  /// Clean metrics older than retention period
  void _cleanOldMetrics() {
    final cutoffTime = DateTime.now().subtract(_metricRetentionPeriod);
    
    for (final typeMetrics in _metrics.values) {
      typeMetrics.removeWhere((metric) => metric.startTime.isBefore(cutoffTime));
    }
  }

  /// Calculate performance trend
  String _calculateTrend(List<PerformanceMetric> metrics) {
    if (metrics.length < 10) return 'insufficient_data';
    
    final recent = metrics.skip(metrics.length - 10).toList();
    final older = metrics.take(metrics.length - 10).toList();
    
    if (older.isEmpty) return 'stable';
    
    final recentAvg = recent.map((m) => m.duration.inMilliseconds).reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.map((m) => m.duration.inMilliseconds).reduce((a, b) => a + b) / older.length;
    
    final change = (recentAvg - olderAvg) / olderAvg;
    
    if (change > 0.2) return 'degrading';
    if (change < -0.2) return 'improving';
    return 'stable';
  }

  /// Generate performance recommendations
  List<String> _generateRecommendations(String type, List<PerformanceMetric> metrics) {
    final recommendations = <String>[];
    
    if (metrics.isEmpty) return recommendations;
    
    final successRate = metrics.where((m) => m.success).length / metrics.length;
    final avgDuration = metrics.map((m) => m.duration.inMilliseconds).reduce((a, b) => a + b) / metrics.length;
    
    switch (type) {
      case 'level_load':
        if (successRate < 0.95) {
          recommendations.add('Level loading success rate is low (${(successRate * 100).toStringAsFixed(1)}%). Check network connectivity and error handling.');
        }
        if (avgDuration > 2000) {
          recommendations.add('Level loading is slow (${avgDuration.toStringAsFixed(0)}ms average). Consider implementing better caching or prefetching.');
        }
        
        final cacheHits = metrics.where((m) => m.metadata['fromCache'] == true).length;
        final cacheHitRate = cacheHits / metrics.length;
        if (cacheHitRate < 0.5) {
          recommendations.add('Cache hit rate for level loading is low (${(cacheHitRate * 100).toStringAsFixed(1)}%). Improve prefetching strategy.');
        }
        break;
        
      case 'ui_performance':
        if (avgDuration > 16) { // 60 FPS = 16.67ms per frame
          recommendations.add('UI operations are slow (${avgDuration.toStringAsFixed(1)}ms average). Consider optimizing widgets and reducing rebuilds.');
        }
        break;
        
      case 'cache_operation':
        if (avgDuration > 50) {
          recommendations.add('Cache operations are slow (${avgDuration.toStringAsFixed(1)}ms average). Consider optimizing cache implementation.');
        }
        break;
    }
    
    return recommendations;
  }

  /// Export performance data for analysis
  Future<String> exportPerformanceData() async {
    final data = {
      'exportTime': DateTime.now().toIso8601String(),
      'metrics': _metrics.map((type, metrics) => MapEntry(
        type,
        metrics.map((m) => m.toJson()).toList(),
      )),
      'summary': getSystemPerformanceSummary(),
    };
    
    return jsonEncode(data);
  }

  /// Clear all performance data
  void clearData() {
    _metrics.clear();
    _activeTimers.clear();
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String id;
  final String type;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final bool success;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.id,
    required this.type,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.success,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration.inMilliseconds,
      'success': success,
      'metadata': metadata,
    };
  }
}

/// Performance analytics result
class PerformanceAnalytics {
  final String type;
  final int totalOperations;
  final double successRate;
  final Duration averageDuration;
  final Duration medianDuration;
  final Duration p95Duration;
  final Duration fastestDuration;
  final Duration slowestDuration;
  final String recentTrend;
  final List<String> recommendations;

  PerformanceAnalytics({
    required this.type,
    required this.totalOperations,
    required this.successRate,
    required this.averageDuration,
    required this.medianDuration,
    required this.p95Duration,
    required this.fastestDuration,
    required this.slowestDuration,
    required this.recentTrend,
    required this.recommendations,
  });
}