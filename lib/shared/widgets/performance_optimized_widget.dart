import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A widget that optimizes performance by controlling animation frame rates
/// and managing memory usage for smooth 60fps performance
class PerformanceOptimizedWidget extends StatefulWidget {
  final Widget child;
  final bool enablePerformanceMode;
  final int targetFPS;
  final bool enableMemoryOptimization;

  const PerformanceOptimizedWidget({
    super.key,
    required this.child,
    this.enablePerformanceMode = true,
    this.targetFPS = 60,
    this.enableMemoryOptimization = true,
  });

  @override
  State<PerformanceOptimizedWidget> createState() =>
      _PerformanceOptimizedWidgetState();
}

class _PerformanceOptimizedWidgetState extends State<PerformanceOptimizedWidget>
    with TickerProviderStateMixin {
  late PerformanceMonitor _performanceMonitor;
  bool _isLowPerformanceMode = false;

  @override
  void initState() {
    super.initState();
    _performanceMonitor = PerformanceMonitor(
      targetFPS: widget.targetFPS,
      onPerformanceChange: _handlePerformanceChange,
    );
    _performanceMonitor.start();
  }

  @override
  void dispose() {
    _performanceMonitor.dispose();
    super.dispose();
  }

  void _handlePerformanceChange(bool isLowPerformance) {
    if (mounted && _isLowPerformanceMode != isLowPerformance) {
      setState(() {
        _isLowPerformanceMode = isLowPerformance;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enablePerformanceMode) {
      return widget.child;
    }

    return RepaintBoundary(
      child: _isLowPerformanceMode
          ? _buildLowPerformanceVersion()
          : widget.child,
    );
  }

  Widget _buildLowPerformanceVersion() {
    // Simplified version for low performance devices
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: widget.child,
    );
  }
}

/// Monitors performance and provides callbacks when performance drops
class PerformanceMonitor {
  final int targetFPS;
  Function(bool isLowPerformance) onPerformanceChange;
  final List<Duration> _frameTimes = [];
  final int _sampleSize = 30;
  bool _isMonitoring = false;
  bool _isLowPerformance = false;

  PerformanceMonitor({
    required this.targetFPS,
    required this.onPerformanceChange,
  });

  void start() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _scheduleFrame();
  }

  void stop() {
    _isMonitoring = false;
  }

  void dispose() {
    stop();
  }

  void _scheduleFrame() {
    if (!_isMonitoring) return;

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _recordFrameTime(timeStamp);
      _scheduleFrame();
    });
  }

  void _recordFrameTime(Duration timeStamp) {
    _frameTimes.add(timeStamp);

    if (_frameTimes.length > _sampleSize) {
      _frameTimes.removeAt(0);
    }

    if (_frameTimes.length >= _sampleSize) {
      _analyzePerformance();
    }
  }

  void _analyzePerformance() {
    final durations = <Duration>[];
    for (int i = 1; i < _frameTimes.length; i++) {
      durations.add(_frameTimes[i] - _frameTimes[i - 1]);
    }

    if (durations.isEmpty) return;

    final averageFrameTime = durations
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a + b) / durations.length;

    final targetFrameTime = 1000000 / targetFPS; // microseconds
    final currentFPS = 1000000 / averageFrameTime;

    final isCurrentlyLowPerformance = currentFPS < (targetFPS * 0.8);

    if (isCurrentlyLowPerformance != _isLowPerformance) {
      _isLowPerformance = isCurrentlyLowPerformance;
      onPerformanceChange(_isLowPerformance);
    }
  }
}

/// A mixin that provides performance optimization utilities for animations
mixin PerformanceOptimizedAnimationMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  
  late PerformanceMonitor _performanceMonitor;
  bool _isLowPerformanceMode = false;

  @override
  void initState() {
    super.initState();
    _performanceMonitor = PerformanceMonitor(
      targetFPS: 60,
      onPerformanceChange: _handlePerformanceChange,
    );
    _performanceMonitor.start();
  }

  @override
  void dispose() {
    _performanceMonitor.dispose();
    super.dispose();
  }

  void _handlePerformanceChange(bool isLowPerformance) {
    if (mounted && _isLowPerformanceMode != isLowPerformance) {
      setState(() {
        _isLowPerformanceMode = isLowPerformance;
      });
      onPerformanceModeChanged(isLowPerformance);
    }
  }

  /// Override this method to handle performance mode changes
  void onPerformanceModeChanged(bool isLowPerformance) {}

  /// Get the appropriate animation duration based on performance mode
  Duration getOptimizedDuration(Duration normalDuration) {
    return _isLowPerformanceMode
        ? Duration(milliseconds: (normalDuration.inMilliseconds * 0.5).round())
        : normalDuration;
  }

  /// Get the appropriate curve based on performance mode
  Curve getOptimizedCurve(Curve normalCurve) {
    return _isLowPerformanceMode ? Curves.linear : normalCurve;
  }

  /// Check if currently in low performance mode
  bool get isLowPerformanceMode => _isLowPerformanceMode;
}

/// A widget that automatically reduces animation complexity based on performance
class AdaptiveAnimationWidget extends StatefulWidget {
  final Widget Function(BuildContext context, bool isLowPerformance) builder;
  final Duration monitoringDuration;

  const AdaptiveAnimationWidget({
    super.key,
    required this.builder,
    this.monitoringDuration = const Duration(seconds: 2),
  });

  @override
  State<AdaptiveAnimationWidget> createState() =>
      _AdaptiveAnimationWidgetState();
}

class _AdaptiveAnimationWidgetState extends State<AdaptiveAnimationWidget>
    with TickerProviderStateMixin, PerformanceOptimizedAnimationMixin {

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, isLowPerformanceMode);
  }
}

/// Memory-optimized list view for large datasets
class MemoryOptimizedListView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double itemExtent;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;

  const MemoryOptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.itemExtent,
    this.controller,
    this.padding,
  });

  @override
  State<MemoryOptimizedListView> createState() =>
      _MemoryOptimizedListViewState();
}

class _MemoryOptimizedListViewState extends State<MemoryOptimizedListView> {
  final Map<int, Widget> _cachedWidgets = {};
  final int _maxCacheSize = 50;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.controller,
      padding: widget.padding,
      itemCount: widget.itemCount,
      itemExtent: widget.itemExtent,
      itemBuilder: (context, index) {
        return _getCachedWidget(index);
      },
    );
  }

  Widget _getCachedWidget(int index) {
    if (_cachedWidgets.containsKey(index)) {
      return _cachedWidgets[index]!;
    }

    final widget = this.widget.itemBuilder(context, index);
    
    if (_cachedWidgets.length >= _maxCacheSize) {
      // Remove oldest cached widget
      final oldestKey = _cachedWidgets.keys.first;
      _cachedWidgets.remove(oldestKey);
    }

    _cachedWidgets[index] = widget;
    return widget;
  }
}

/// Optimized animation controller that adjusts based on performance
class OptimizedAnimationController extends AnimationController {
  final PerformanceMonitor _performanceMonitor;
  bool _isLowPerformanceMode = false;

  OptimizedAnimationController({
    required Duration duration,
    required TickerProvider vsync,
    double? value,
    String? debugLabel,
  }) : _performanceMonitor = PerformanceMonitor(
          targetFPS: 60,
          onPerformanceChange: (isLowPerformance) {},
        ),
        super(
          duration: duration,
          vsync: vsync,
          value: value,
          debugLabel: debugLabel,
        ) {
    _performanceMonitor.onPerformanceChange = _handlePerformanceChange;
    _performanceMonitor.start();
  }

  void _handlePerformanceChange(bool isLowPerformance) {
    _isLowPerformanceMode = isLowPerformance;
    
    // Adjust animation duration based on performance
    if (isLowPerformance) {
      duration = Duration(milliseconds: (duration!.inMilliseconds * 0.7).round());
    }
  }

  @override
  void dispose() {
    _performanceMonitor.dispose();
    super.dispose();
  }

  /// Get optimized tick period based on performance
  Duration get optimizedTickPeriod {
    return _isLowPerformanceMode
        ? const Duration(milliseconds: 32) // ~30fps
        : const Duration(milliseconds: 16); // ~60fps
  }
}

/// Utility class for performance-related constants and helpers
class PerformanceUtils {
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  static const Curve fastCurve = Curves.easeOut;
  static const Curve normalCurve = Curves.easeInOut;
  static const Curve slowCurve = Curves.easeInOutCubic;

  /// Get optimized animation duration based on device performance
  static Duration getOptimizedDuration(Duration baseDuration, bool isLowPerformance) {
    if (isLowPerformance) {
      return Duration(milliseconds: (baseDuration.inMilliseconds * 0.6).round());
    }
    return baseDuration;
  }

  /// Get optimized curve based on device performance
  static Curve getOptimizedCurve(Curve baseCurve, bool isLowPerformance) {
    return isLowPerformance ? Curves.linear : baseCurve;
  }

  /// Check if device is likely to have performance issues
  static bool isLowEndDevice() {
    // This is a simplified check - in a real app, you might want to
    // check device specs, memory, etc.
    return false; // Placeholder implementation
  }
}