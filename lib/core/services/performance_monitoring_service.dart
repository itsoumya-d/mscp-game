import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// Performance metric types
enum PerformanceMetricType {
  frameTime,
  memoryUsage,
  cpuUsage,
  networkLatency,
  diskIO,
  batteryUsage,
  renderTime,
  loadTime,
  responseTime,
  errorRate,
}

/// Performance severity levels
enum PerformanceSeverity {
  low,
  medium,
  high,
  critical,
}

/// Performance alert types
enum PerformanceAlertType {
  highMemoryUsage,
  slowFrameRate,
  highCpuUsage,
  networkTimeout,
  diskSpaceWarning,
  batteryDrain,
  memoryLeak,
  anrWarning, // Application Not Responding
}

/// Individual performance metric
class PerformanceMetric {
  final PerformanceMetricType type;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.type,
    required this.value,
    required this.unit,
    DateTime? timestamp,
    this.metadata = const {},
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) {
    return PerformanceMetric(
      type: PerformanceMetricType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => PerformanceMetricType.frameTime,
      ),
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }
}

/// Performance alert
class PerformanceAlert {
  final PerformanceAlertType type;
  final PerformanceSeverity severity;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  final bool isResolved;

  PerformanceAlert({
    required this.type,
    required this.severity,
    required this.message,
    DateTime? timestamp,
    this.context = const {},
    this.isResolved = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'severity': severity.toString(),
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'is_resolved': isResolved,
    };
  }

  factory PerformanceAlert.fromJson(Map<String, dynamic> json) {
    return PerformanceAlert(
      type: PerformanceAlertType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => PerformanceAlertType.highMemoryUsage,
      ),
      severity: PerformanceSeverity.values.firstWhere(
        (e) => e.toString() == json['severity'],
        orElse: () => PerformanceSeverity.medium,
      ),
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      context: Map<String, dynamic>.from(json['context'] as Map? ?? {}),
      isResolved: json['is_resolved'] as bool? ?? false,
    );
  }

  PerformanceAlert copyWith({
    PerformanceAlertType? type,
    PerformanceSeverity? severity,
    String? message,
    DateTime? timestamp,
    Map<String, dynamic>? context,
    bool? isResolved,
  }) {
    return PerformanceAlert(
      type: type ?? this.type,
      severity: severity ?? this.severity,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      context: context ?? this.context,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}

/// Performance session data
class PerformanceSession {
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<PerformanceMetric> metrics;
  final List<PerformanceAlert> alerts;
  final Map<String, dynamic> sessionInfo;

  PerformanceSession({
    required this.sessionId,
    DateTime? startTime,
    this.endTime,
    List<PerformanceMetric>? metrics,
    List<PerformanceAlert>? alerts,
    this.sessionInfo = const {},
  }) : startTime = startTime ?? DateTime.now(),
       metrics = metrics ?? [],
       alerts = alerts ?? [];

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'metrics': metrics.map((m) => m.toJson()).toList(),
      'alerts': alerts.map((a) => a.toJson()).toList(),
      'session_info': sessionInfo,
    };
  }

  factory PerformanceSession.fromJson(Map<String, dynamic> json) {
    return PerformanceSession(
      sessionId: json['session_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time'] as String) 
          : null,
      metrics: (json['metrics'] as List? ?? [])
          .map((m) => PerformanceMetric.fromJson(m))
          .toList(),
      alerts: (json['alerts'] as List? ?? [])
          .map((a) => PerformanceAlert.fromJson(a))
          .toList(),
      sessionInfo: Map<String, dynamic>.from(json['session_info'] as Map? ?? {}),
    );
  }
}

/// Performance statistics
class PerformanceStatistics {
  final Map<PerformanceMetricType, double> averageValues;
  final Map<PerformanceMetricType, double> maxValues;
  final Map<PerformanceMetricType, double> minValues;
  final Map<PerformanceAlertType, int> alertCounts;
  final int totalSessions;
  final Duration totalDuration;
  final DateTime periodStart;
  final DateTime periodEnd;

  PerformanceStatistics({
    required this.averageValues,
    required this.maxValues,
    required this.minValues,
    required this.alertCounts,
    required this.totalSessions,
    required this.totalDuration,
    required this.periodStart,
    required this.periodEnd,
  });

  Map<String, dynamic> toJson() {
    return {
      'average_values': averageValues.map((k, v) => MapEntry(k.toString(), v)),
      'max_values': maxValues.map((k, v) => MapEntry(k.toString(), v)),
      'min_values': minValues.map((k, v) => MapEntry(k.toString(), v)),
      'alert_counts': alertCounts.map((k, v) => MapEntry(k.toString(), v)),
      'total_sessions': totalSessions,
      'total_duration_ms': totalDuration.inMilliseconds,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
    };
  }
}

/// Performance monitoring service
class PerformanceMonitoringService {
  static const String _sessionsKey = 'performance_sessions';
  static const String _alertsKey = 'performance_alerts';
  static const String _configKey = 'performance_config';
  static const int _maxStoredSessions = 50;
  static const int _maxStoredAlerts = 200;

  late SharedPreferences _prefs;
  final List<PerformanceSession> _sessions = [];
  final List<PerformanceAlert> _alerts = [];
  PerformanceSession? _currentSession;
  
  Timer? _monitoringTimer;
  Timer? _alertCheckTimer;
  Timer? _cleanupTimer;
  
  final StreamController<PerformanceMetric> _metricController = 
      StreamController<PerformanceMetric>.broadcast();
  final StreamController<PerformanceAlert> _alertController = 
      StreamController<PerformanceAlert>.broadcast();

  // Configuration
  bool _isMonitoringEnabled = true;
  Duration _monitoringInterval = const Duration(seconds: 5);
  Map<PerformanceMetricType, double> _alertThresholds = {};
  Map<PerformanceAlertType, bool> _alertsEnabled = {};
  
  // Session counter for unique IDs
  int _sessionCounter = 0;

  /// Stream of performance metrics
  Stream<PerformanceMetric> get metrics => _metricController.stream;

  /// Stream of performance alerts
  Stream<PerformanceAlert> get alerts => _alertController.stream;

  /// Initialize the performance monitoring service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadConfiguration();
    await _loadSessions();
    await _loadAlerts();
    _setupDefaultThresholds();
    _startMonitoring();
  }

  /// Load configuration
  Future<void> _loadConfiguration() async {
    try {
      final configJson = _prefs.getString(_configKey);
      if (configJson != null) {
        final config = jsonDecode(configJson) as Map<String, dynamic>;
        _isMonitoringEnabled = config['monitoring_enabled'] as bool? ?? true;
        _monitoringInterval = Duration(
          milliseconds: config['monitoring_interval_ms'] as int? ?? 5000,
        );
        
        // Load thresholds
        final thresholds = config['alert_thresholds'] as Map<String, dynamic>? ?? {};
        _alertThresholds.clear();
        thresholds.forEach((key, value) {
          try {
            final metricType = PerformanceMetricType.values.firstWhere(
              (e) => e.toString() == key,
            );
            _alertThresholds[metricType] = (value as num).toDouble();
          } catch (e) {
            // Skip invalid threshold
          }
        });

        // Load alert settings
        final alertSettings = config['alerts_enabled'] as Map<String, dynamic>? ?? {};
        _alertsEnabled.clear();
        alertSettings.forEach((key, value) {
          try {
            final alertType = PerformanceAlertType.values.firstWhere(
              (e) => e.toString() == key,
            );
            _alertsEnabled[alertType] = value as bool;
          } catch (e) {
            // Skip invalid alert type
          }
        });
      }
    } catch (e) {
      print('Error loading performance configuration: $e');
    }
  }

  /// Save configuration
  Future<void> _saveConfiguration() async {
    try {
      final config = {
        'monitoring_enabled': _isMonitoringEnabled,
        'monitoring_interval_ms': _monitoringInterval.inMilliseconds,
        'alert_thresholds': _alertThresholds.map((k, v) => MapEntry(k.toString(), v)),
        'alerts_enabled': _alertsEnabled.map((k, v) => MapEntry(k.toString(), v)),
      };
      await _prefs.setString(_configKey, jsonEncode(config));
    } catch (e) {
      print('Error saving performance configuration: $e');
    }
  }

  /// Load stored sessions
  Future<void> _loadSessions() async {
    try {
      final sessionsJson = _prefs.getStringList(_sessionsKey) ?? [];
      _sessions.clear();
      for (final sessionJson in sessionsJson) {
        try {
          final session = PerformanceSession.fromJson(jsonDecode(sessionJson));
          _sessions.add(session);
        } catch (e) {
          print('Error parsing session: $e');
        }
      }
    } catch (e) {
      print('Error loading performance sessions: $e');
    }
  }

  /// Save sessions
  Future<void> _saveSessions() async {
    try {
      final sessionsJson = _sessions
          .take(_maxStoredSessions)
          .map((s) => jsonEncode(s.toJson()))
          .toList();
      await _prefs.setStringList(_sessionsKey, sessionsJson);
    } catch (e) {
      print('Error saving performance sessions: $e');
    }
  }

  /// Load stored alerts
  Future<void> _loadAlerts() async {
    try {
      final alertsJson = _prefs.getStringList(_alertsKey) ?? [];
      _alerts.clear();
      for (final alertJson in alertsJson) {
        try {
          final alert = PerformanceAlert.fromJson(jsonDecode(alertJson));
          _alerts.add(alert);
        } catch (e) {
          print('Error parsing alert: $e');
        }
      }
    } catch (e) {
      print('Error loading performance alerts: $e');
    }
  }

  /// Save alerts
  Future<void> _saveAlerts() async {
    try {
      final alertsJson = _alerts
          .take(_maxStoredAlerts)
          .map((a) => jsonEncode(a.toJson()))
          .toList();
      await _prefs.setStringList(_alertsKey, alertsJson);
    } catch (e) {
      print('Error saving performance alerts: $e');
    }
  }

  /// Setup default alert thresholds
  void _setupDefaultThresholds() {
    if (_alertThresholds.isEmpty) {
      _alertThresholds = {
        PerformanceMetricType.frameTime: 16.67, // 60 FPS threshold
        PerformanceMetricType.memoryUsage: 512.0, // 512 MB
        PerformanceMetricType.cpuUsage: 80.0, // 80%
        PerformanceMetricType.networkLatency: 1000.0, // 1 second
        PerformanceMetricType.renderTime: 100.0, // 100ms
        PerformanceMetricType.loadTime: 3000.0, // 3 seconds
        PerformanceMetricType.responseTime: 500.0, // 500ms
        PerformanceMetricType.errorRate: 5.0, // 5%
      };
    }

    if (_alertsEnabled.isEmpty) {
      for (final alertType in PerformanceAlertType.values) {
        _alertsEnabled[alertType] = true;
      }
    }
  }

  /// Start performance monitoring
  void _startMonitoring() {
    if (!_isMonitoringEnabled) return;

    _monitoringTimer?.cancel();
    _alertCheckTimer?.cancel();
    _cleanupTimer?.cancel();

    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      _collectMetrics();
    });

    _alertCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkAlerts(),
    );

    _cleanupTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _performCleanup(),
    );
  }

  /// Stop performance monitoring
  void _stopMonitoring() {
    _monitoringTimer?.cancel();
    _alertCheckTimer?.cancel();
    _cleanupTimer?.cancel();
  }

  /// Start a new performance session
  Future<String> startSession({Map<String, dynamic>? sessionInfo}) async {
    await endCurrentSession();

    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}_${++_sessionCounter}';
    _currentSession = PerformanceSession(
      sessionId: sessionId,
      sessionInfo: sessionInfo ?? {},
    );

    return sessionId;
  }

  /// End the current performance session
  Future<void> endCurrentSession() async {
    if (_currentSession != null) {
      final endedSession = PerformanceSession(
        sessionId: _currentSession!.sessionId,
        startTime: _currentSession!.startTime,
        endTime: DateTime.now(),
        metrics: List.from(_currentSession!.metrics),
        alerts: List.from(_currentSession!.alerts),
        sessionInfo: _currentSession!.sessionInfo,
      );

      _sessions.insert(0, endedSession);
      if (_sessions.length > _maxStoredSessions) {
        _sessions.removeRange(_maxStoredSessions, _sessions.length);
      }

      await _saveSessions();
      _currentSession = null;
    }
  }

  /// Collect performance metrics
  void _collectMetrics() {
    if (_currentSession == null) return;

    try {
      // Collect frame time metric (simulated)
      final frameTime = _measureFrameTime();
      _recordMetric(PerformanceMetric(
        type: PerformanceMetricType.frameTime,
        value: frameTime,
        unit: 'ms',
        metadata: {'fps': 1000 / frameTime},
      ));

      // Collect memory usage
      final memoryUsage = _measureMemoryUsage();
      _recordMetric(PerformanceMetric(
        type: PerformanceMetricType.memoryUsage,
        value: memoryUsage,
        unit: 'MB',
      ));

      // Collect CPU usage (simulated)
      final cpuUsage = _measureCpuUsage();
      _recordMetric(PerformanceMetric(
        type: PerformanceMetricType.cpuUsage,
        value: cpuUsage,
        unit: '%',
      ));

      // Collect network latency (if applicable)
      _measureNetworkLatency().then((latency) {
        if (latency != null) {
          _recordMetric(PerformanceMetric(
            type: PerformanceMetricType.networkLatency,
            value: latency,
            unit: 'ms',
          ));
        }
      });

    } catch (e) {
      print('Error collecting performance metrics: $e');
    }
  }

  /// Measure frame time (simulated)
  double _measureFrameTime() {
    // In a real implementation, this would measure actual frame rendering time
    // For now, we'll simulate with some variation
    final baseTime = 16.67; // 60 FPS baseline
    final variation = (DateTime.now().millisecond % 10) - 5;
    return baseTime + variation;
  }

  /// Measure memory usage
  double _measureMemoryUsage() {
    try {
      // This is a simplified approach - in production you'd use platform-specific APIs
      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile platforms, you'd use platform channels to get actual memory usage
        // For now, simulate memory usage
        return 128.0 + (DateTime.now().millisecond % 100);
      } else {
        // On desktop/web, you might have different approaches
        return 256.0 + (DateTime.now().millisecond % 200);
      }
    } catch (e) {
      return 0.0;
    }
  }

  /// Measure CPU usage (simulated)
  double _measureCpuUsage() {
    // In a real implementation, this would measure actual CPU usage
    // For now, simulate with some variation
    final baseCpu = 25.0;
    final variation = (DateTime.now().millisecond % 30) - 15;
    return (baseCpu + variation).clamp(0.0, 100.0);
  }

  /// Measure network latency
  Future<double?> _measureNetworkLatency() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Simple ping test (in production, you'd ping your actual servers)
      final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 2));
      await socket.close();
      
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds.toDouble();
    } catch (e) {
      return null;
    }
  }

  /// Record a performance metric
  void _recordMetric(PerformanceMetric metric) {
    if (_currentSession != null) {
      _currentSession!.metrics.add(metric);
      _metricController.add(metric);
    }
  }

  /// Record a custom metric
  void recordCustomMetric({
    required PerformanceMetricType type,
    required double value,
    required String unit,
    Map<String, dynamic>? metadata,
  }) {
    final metric = PerformanceMetric(
      type: type,
      value: value,
      unit: unit,
      metadata: metadata ?? {},
    );
    _recordMetric(metric);
  }

  /// Record render time
  void recordRenderTime(Duration duration, {String? componentName}) {
    recordCustomMetric(
      type: PerformanceMetricType.renderTime,
      value: duration.inMilliseconds.toDouble(),
      unit: 'ms',
      metadata: {
        if (componentName != null) 'component': componentName,
      },
    );
  }

  /// Record load time
  void recordLoadTime(Duration duration, {String? resourceName}) {
    recordCustomMetric(
      type: PerformanceMetricType.loadTime,
      value: duration.inMilliseconds.toDouble(),
      unit: 'ms',
      metadata: {
        if (resourceName != null) 'resource': resourceName,
      },
    );
  }

  /// Record response time
  void recordResponseTime(Duration duration, {String? endpoint}) {
    recordCustomMetric(
      type: PerformanceMetricType.responseTime,
      value: duration.inMilliseconds.toDouble(),
      unit: 'ms',
      metadata: {
        if (endpoint != null) 'endpoint': endpoint,
      },
    );
  }

  /// Check for performance alerts
  void _checkAlerts() {
    if (_currentSession == null || _currentSession!.metrics.isEmpty) return;

    final recentMetrics = _currentSession!.metrics
        .where((m) => DateTime.now().difference(m.timestamp).inMinutes < 5)
        .toList();

    for (final metricType in PerformanceMetricType.values) {
      final metrics = recentMetrics.where((m) => m.type == metricType).toList();
      if (metrics.isEmpty) continue;

      final threshold = _alertThresholds[metricType];
      if (threshold == null) continue;

      final averageValue = metrics.map((m) => m.value).reduce((a, b) => a + b) / metrics.length;
      
      if (averageValue > threshold) {
        _createAlert(metricType, averageValue, threshold);
      }
    }

    // Check for specific alert conditions
    _checkMemoryLeaks();
    _checkFrameDrops();
    _checkNetworkTimeouts();
  }

  /// Create a performance alert
  void _createAlert(PerformanceMetricType metricType, double currentValue, double threshold) {
    final alertType = _getAlertTypeForMetric(metricType);
    if (alertType == null || !(_alertsEnabled[alertType] ?? false)) return;

    // Check if we already have a recent alert of this type
    final recentAlerts = _alerts
        .where((a) => a.type == alertType && 
                     DateTime.now().difference(a.timestamp).inMinutes < 10)
        .toList();
    
    if (recentAlerts.isNotEmpty) return;

    final severity = _getSeverityForValue(currentValue, threshold);
    final alert = PerformanceAlert(
      type: alertType,
      severity: severity,
      message: _getAlertMessage(alertType, currentValue, threshold),
      context: {
        'metric_type': metricType.toString(),
        'current_value': currentValue,
        'threshold': threshold,
        'session_id': _currentSession?.sessionId,
      },
    );

    _alerts.insert(0, alert);
    if (_currentSession != null) {
      _currentSession!.alerts.add(alert);
    }

    _alertController.add(alert);
    _saveAlerts();
  }

  /// Get alert type for metric type
  PerformanceAlertType? _getAlertTypeForMetric(PerformanceMetricType metricType) {
    switch (metricType) {
      case PerformanceMetricType.memoryUsage:
        return PerformanceAlertType.highMemoryUsage;
      case PerformanceMetricType.frameTime:
        return PerformanceAlertType.slowFrameRate;
      case PerformanceMetricType.cpuUsage:
        return PerformanceAlertType.highCpuUsage;
      case PerformanceMetricType.networkLatency:
        return PerformanceAlertType.networkTimeout;
      default:
        return null;
    }
  }

  /// Get severity for value
  PerformanceSeverity _getSeverityForValue(double currentValue, double threshold) {
    final ratio = currentValue / threshold;
    if (ratio >= 2.0) return PerformanceSeverity.critical;
    if (ratio >= 1.5) return PerformanceSeverity.high;
    if (ratio >= 1.2) return PerformanceSeverity.medium;
    return PerformanceSeverity.low;
  }

  /// Get alert message
  String _getAlertMessage(PerformanceAlertType alertType, double currentValue, double threshold) {
    switch (alertType) {
      case PerformanceAlertType.highMemoryUsage:
        return 'High memory usage detected: ${currentValue.toStringAsFixed(1)} MB (threshold: ${threshold.toStringAsFixed(1)} MB)';
      case PerformanceAlertType.slowFrameRate:
        return 'Slow frame rate detected: ${currentValue.toStringAsFixed(1)} ms per frame (threshold: ${threshold.toStringAsFixed(1)} ms)';
      case PerformanceAlertType.highCpuUsage:
        return 'High CPU usage detected: ${currentValue.toStringAsFixed(1)}% (threshold: ${threshold.toStringAsFixed(1)}%)';
      case PerformanceAlertType.networkTimeout:
        return 'High network latency detected: ${currentValue.toStringAsFixed(0)} ms (threshold: ${threshold.toStringAsFixed(0)} ms)';
      default:
        return 'Performance issue detected: ${currentValue.toStringAsFixed(1)} (threshold: ${threshold.toStringAsFixed(1)})';
    }
  }

  /// Check for memory leaks
  void _checkMemoryLeaks() {
    if (_currentSession == null) return;

    final memoryMetrics = _currentSession!.metrics
        .where((m) => m.type == PerformanceMetricType.memoryUsage)
        .toList();

    if (memoryMetrics.length < 10) return;

    // Check if memory usage is consistently increasing
    final recentMetrics = memoryMetrics.takeLast(10).toList();
    bool isIncreasing = true;
    
    for (int i = 1; i < recentMetrics.length; i++) {
      if (recentMetrics[i].value <= recentMetrics[i - 1].value) {
        isIncreasing = false;
        break;
      }
    }

    if (isIncreasing && _alertsEnabled[PerformanceAlertType.memoryLeak] == true) {
      final alert = PerformanceAlert(
        type: PerformanceAlertType.memoryLeak,
        severity: PerformanceSeverity.high,
        message: 'Potential memory leak detected: Memory usage consistently increasing',
        context: {
          'start_memory': recentMetrics.first.value,
          'end_memory': recentMetrics.last.value,
          'increase': recentMetrics.last.value - recentMetrics.first.value,
        },
      );

      _alerts.insert(0, alert);
      if (_currentSession != null) {
        _currentSession!.alerts.add(alert);
      }
      _alertController.add(alert);
    }
  }

  /// Check for frame drops
  void _checkFrameDrops() {
    if (_currentSession == null) return;

    final frameMetrics = _currentSession!.metrics
        .where((m) => m.type == PerformanceMetricType.frameTime)
        .toList();

    if (frameMetrics.length < 5) return;

    final recentFrames = frameMetrics.takeLast(30).toList();
    final droppedFrames = recentFrames.where((m) => m.value > 33.33).length; // Frames slower than 30 FPS

    if (droppedFrames > recentFrames.length * 0.2 && 
        _alertsEnabled[PerformanceAlertType.slowFrameRate] == true) {
      final alert = PerformanceAlert(
        type: PerformanceAlertType.slowFrameRate,
        severity: PerformanceSeverity.medium,
        message: 'Frequent frame drops detected: ${droppedFrames}/${recentFrames.length} frames dropped',
        context: {
          'dropped_frames': droppedFrames,
          'total_frames': recentFrames.length,
          'drop_rate': droppedFrames / recentFrames.length,
        },
      );

      _alerts.insert(0, alert);
      if (_currentSession != null) {
        _currentSession!.alerts.add(alert);
      }
      _alertController.add(alert);
    }
  }

  /// Check for network timeouts
  void _checkNetworkTimeouts() {
    if (_currentSession == null) return;

    final networkMetrics = _currentSession!.metrics
        .where((m) => m.type == PerformanceMetricType.networkLatency)
        .toList();

    if (networkMetrics.isEmpty) return;

    final recentMetrics = networkMetrics
        .where((m) => DateTime.now().difference(m.timestamp).inMinutes < 5)
        .toList();

    final timeouts = recentMetrics.where((m) => m.value > 5000).length; // > 5 seconds

    if (timeouts > 0 && _alertsEnabled[PerformanceAlertType.networkTimeout] == true) {
      final alert = PerformanceAlert(
        type: PerformanceAlertType.networkTimeout,
        severity: PerformanceSeverity.high,
        message: 'Network timeouts detected: $timeouts timeout(s) in the last 5 minutes',
        context: {
          'timeout_count': timeouts,
          'total_requests': recentMetrics.length,
        },
      );

      _alerts.insert(0, alert);
      if (_currentSession != null) {
        _currentSession!.alerts.add(alert);
      }
      _alertController.add(alert);
    }
  }

  /// Perform cleanup of old data
  void _performCleanup() {
    // Remove old sessions
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    _sessions.removeWhere((session) => session.startTime.isBefore(cutoffDate));

    // Remove old alerts
    _alerts.removeWhere((alert) => alert.timestamp.isBefore(cutoffDate));

    // Save cleaned data
    _saveSessions();
    _saveAlerts();
  }

  /// Get performance statistics
  PerformanceStatistics getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
    final end = endDate ?? DateTime.now();

    final relevantSessions = _sessions
        .where((s) => s.startTime.isAfter(start) && s.startTime.isBefore(end))
        .toList();

    final allMetrics = relevantSessions
        .expand((s) => s.metrics)
        .where((m) => m.timestamp.isAfter(start) && m.timestamp.isBefore(end))
        .toList();

    final allAlerts = _alerts
        .where((a) => a.timestamp.isAfter(start) && a.timestamp.isBefore(end))
        .toList();

    // Calculate statistics
    final averageValues = <PerformanceMetricType, double>{};
    final maxValues = <PerformanceMetricType, double>{};
    final minValues = <PerformanceMetricType, double>{};

    for (final metricType in PerformanceMetricType.values) {
      final metrics = allMetrics.where((m) => m.type == metricType).toList();
      if (metrics.isNotEmpty) {
        final values = metrics.map((m) => m.value).toList();
        averageValues[metricType] = values.reduce((a, b) => a + b) / values.length;
        maxValues[metricType] = values.reduce((a, b) => a > b ? a : b);
        minValues[metricType] = values.reduce((a, b) => a < b ? a : b);
      }
    }

    final alertCounts = <PerformanceAlertType, int>{};
    for (final alertType in PerformanceAlertType.values) {
      alertCounts[alertType] = allAlerts.where((a) => a.type == alertType).length;
    }

    final totalDuration = relevantSessions.fold<Duration>(
      Duration.zero,
      (sum, session) => sum + session.duration,
    );

    return PerformanceStatistics(
      averageValues: averageValues,
      maxValues: maxValues,
      minValues: minValues,
      alertCounts: alertCounts,
      totalSessions: relevantSessions.length,
      totalDuration: totalDuration,
      periodStart: start,
      periodEnd: end,
    );
  }

  /// Get recent sessions
  List<PerformanceSession> getRecentSessions({int limit = 10}) {
    return _sessions.take(limit).toList();
  }

  /// Get recent alerts
  List<PerformanceAlert> getRecentAlerts({int limit = 20}) {
    return _alerts.take(limit).toList();
  }

  /// Get unresolved alerts
  List<PerformanceAlert> getUnresolvedAlerts() {
    return _alerts.where((a) => !a.isResolved).toList();
  }

  /// Resolve an alert
  Future<void> resolveAlert(PerformanceAlert alert) async {
    final index = _alerts.indexWhere((a) => 
        a.type == alert.type && 
        a.timestamp == alert.timestamp);
    
    if (index != -1) {
      _alerts[index] = alert.copyWith(isResolved: true);
      await _saveAlerts();
    }
  }

  /// Update monitoring configuration
  Future<void> updateConfiguration({
    bool? isEnabled,
    Duration? monitoringInterval,
    Map<PerformanceMetricType, double>? alertThresholds,
    Map<PerformanceAlertType, bool>? alertsEnabled,
  }) async {
    if (isEnabled != null) {
      _isMonitoringEnabled = isEnabled;
      if (isEnabled) {
        _startMonitoring();
      } else {
        _stopMonitoring();
      }
    }

    if (monitoringInterval != null) {
      _monitoringInterval = monitoringInterval;
      if (_isMonitoringEnabled) {
        _startMonitoring(); // Restart with new interval
      }
    }

    if (alertThresholds != null) {
      _alertThresholds.addAll(alertThresholds);
    }

    if (alertsEnabled != null) {
      _alertsEnabled.addAll(alertsEnabled);
    }

    await _saveConfiguration();
  }

  /// Get current configuration
  Map<String, dynamic> getConfiguration() {
    return {
      'monitoring_enabled': _isMonitoringEnabled,
      'monitoring_interval': _monitoringInterval,
      'alert_thresholds': Map<String, double>.from(
        _alertThresholds.map((k, v) => MapEntry(k.toString(), v)),
      ),
      'alerts_enabled': Map<String, bool>.from(
        _alertsEnabled.map((k, v) => MapEntry(k.toString(), v)),
      ),
    };
  }

  /// Clear all performance data
  Future<void> clearAllData() async {
    await endCurrentSession();
    _sessions.clear();
    _alerts.clear();
    
    await _prefs.remove(_sessionsKey);
    await _prefs.remove(_alertsKey);
  }

  /// Export performance data
  Map<String, dynamic> exportData() {
    return {
      'sessions': _sessions.map((s) => s.toJson()).toList(),
      'alerts': _alerts.map((a) => a.toJson()).toList(),
      'configuration': getConfiguration(),
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Dispose of resources
  void dispose() {
    _stopMonitoring();
    _metricController.close();
    _alertController.close();
  }
}

/// Extension for List to get last N elements
extension ListExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return sublist(length - count);
  }
}