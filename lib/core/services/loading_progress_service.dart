import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service to track loading progress across the app
class LoadingProgressService {
  static LoadingProgressService? _instance;
  
  static LoadingProgressService getInstance() {
    return _instance ??= LoadingProgressService._();
  }
  
  LoadingProgressService._();
  
  final Map<String, LoadingProgress> _activeOperations = {};
  final StreamController<Map<String, LoadingProgress>> _progressController =
      StreamController<Map<String, LoadingProgress>>.broadcast();
  
  /// Stream of all active loading operations
  Stream<Map<String, LoadingProgress>> get progressStream => _progressController.stream;
  
  /// Start tracking a new loading operation
  String startOperation({
    required String operationId,
    required String title,
    String? subtitle,
    int? totalItems,
  }) {
    final progress = LoadingProgress(
      operationId: operationId,
      title: title,
      subtitle: subtitle,
      totalItems: totalItems,
      startTime: DateTime.now(),
    );
    
    _activeOperations[operationId] = progress;
    _notifyListeners();
    
    debugPrint('[LoadingProgress] Started: $operationId - $title');
    return operationId;
  }
  
  /// Update progress for an operation
  void updateProgress({
    required String operationId,
    int? completedItems,
    double? progress,
    String? currentMessage,
  }) {
    final operation = _activeOperations[operationId];
    if (operation == null) return;
    
    _activeOperations[operationId] = operation.copyWith(
      completedItems: completedItems,
      progress: progress,
      currentMessage: currentMessage,
    );
    
    _notifyListeners();
  }
  
  /// Complete an operation
  void completeOperation(String operationId) {
    final operation = _activeOperations[operationId];
    if (operation != null) {
      final duration = DateTime.now().difference(operation.startTime);
      debugPrint('[LoadingProgress] Completed: $operationId in ${duration.inMilliseconds}ms');
    }
    
    _activeOperations.remove(operationId);
    _notifyListeners();
  }
  
  /// Cancel an operation
  void cancelOperation(String operationId) {
    debugPrint('[LoadingProgress] Cancelled: $operationId');
    _activeOperations.remove(operationId);
    _notifyListeners();
  }
  
  /// Get current progress for an operation
  LoadingProgress? getProgress(String operationId) {
    return _activeOperations[operationId];
  }
  
  /// Check if an operation is active
  bool isOperationActive(String operationId) {
    return _activeOperations.containsKey(operationId);
  }
  
  /// Get all active operations
  Map<String, LoadingProgress> getAllOperations() {
    return Map.unmodifiable(_activeOperations);
  }
  
  void _notifyListeners() {
    if (!_progressController.isClosed) {
      _progressController.add(Map.unmodifiable(_activeOperations));
    }
  }
  
  /// Dispose resources
  void dispose() {
    _progressController.close();
    _activeOperations.clear();
  }
}

/// Model representing loading progress
class LoadingProgress {
  final String operationId;
  final String title;
  final String? subtitle;
  final int? totalItems;
  final int? completedItems;
  final double? progress; // 0.0 to 1.0
  final String? currentMessage;
  final DateTime startTime;
  
  const LoadingProgress({
    required this.operationId,
    required this.title,
    this.subtitle,
    this.totalItems,
    this.completedItems,
    this.progress,
    this.currentMessage,
    required this.startTime,
  });
  
  /// Calculate progress percentage
  double get progressPercentage {
    if (progress != null) return progress!;
    if (totalItems != null && completedItems != null && totalItems! > 0) {
      return completedItems! / totalItems!;
    }
    return 0.0;
  }
  
  /// Estimate time remaining based on current progress
  Duration? get estimatedTimeRemaining {
    if (progressPercentage <= 0) return null;
    
    final elapsed = DateTime.now().difference(startTime);
    final totalEstimated = elapsed.inMilliseconds / progressPercentage;
    final remaining = totalEstimated - elapsed.inMilliseconds;
    
    return Duration(milliseconds: remaining.round());
  }
  
  /// Check if operation is complete
  bool get isComplete {
    if (progress != null) return progress! >= 1.0;
    if (totalItems != null && completedItems != null) {
      return completedItems! >= totalItems!;
    }
    return false;
  }
  
  LoadingProgress copyWith({
    String? operationId,
    String? title,
    String? subtitle,
    int? totalItems,
    int? completedItems,
    double? progress,
    String? currentMessage,
    DateTime? startTime,
  }) {
    return LoadingProgress(
      operationId: operationId ?? this.operationId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      totalItems: totalItems ?? this.totalItems,
      completedItems: completedItems ?? this.completedItems,
      progress: progress ?? this.progress,
      currentMessage: currentMessage ?? this.currentMessage,
      startTime: startTime ?? this.startTime,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'operationId': operationId,
    'title': title,
    'subtitle': subtitle,
    'totalItems': totalItems,
    'completedItems': completedItems,
    'progress': progress,
    'currentMessage': currentMessage,
    'startTime': startTime.toIso8601String(),
  };
  
  @override
  String toString() {
    return 'LoadingProgress(id: $operationId, title: $title, progress: ${(progressPercentage * 100).toStringAsFixed(1)}%)';
  }
}

/// Extension to add progress tracking to Future operations
extension FutureProgressTracking<T> on Future<T> {
  /// Execute a future with progress tracking
  Future<T> withProgress({
    required LoadingProgressService progressService,
    required String operationId,
    required String title,
    String? subtitle,
    int? totalItems,
  }) async {
    progressService.startOperation(
      operationId: operationId,
      title: title,
      subtitle: subtitle,
      totalItems: totalItems,
    );
    
    try {
      final result = await this;
      progressService.completeOperation(operationId);
      return result;
    } catch (e) {
      progressService.cancelOperation(operationId);
      rethrow;
    }
  }
}

/// Helper class for batch operations with progress tracking
class BatchProgressTracker {
  final LoadingProgressService _progressService;
  final String _operationId;
  final int _totalItems;
  int _completedItems = 0;
  
  BatchProgressTracker({
    required LoadingProgressService progressService,
    required String operationId,
    required String title,
    required int totalItems,
    String? subtitle,
  })  : _progressService = progressService,
        _operationId = operationId,
        _totalItems = totalItems {
    _progressService.startOperation(
      operationId: operationId,
      title: title,
      subtitle: subtitle,
      totalItems: totalItems,
    );
  }
  
  /// Mark one item as complete
  void incrementProgress({String? message}) {
    _completedItems++;
    _progressService.updateProgress(
      operationId: _operationId,
      completedItems: _completedItems,
      currentMessage: message,
    );
  }
  
  /// Update progress with specific count
  void updateProgress(int completedItems, {String? message}) {
    _completedItems = completedItems;
    _progressService.updateProgress(
      operationId: _operationId,
      completedItems: _completedItems,
      currentMessage: message,
    );
  }
  
  /// Complete the batch operation
  void complete() {
    _progressService.completeOperation(_operationId);
  }
  
  /// Cancel the batch operation
  void cancel() {
    _progressService.cancelOperation(_operationId);
  }
  
  /// Get current progress percentage
  double get progress => _completedItems / _totalItems;
  
  /// Check if complete
  bool get isComplete => _completedItems >= _totalItems;
}

