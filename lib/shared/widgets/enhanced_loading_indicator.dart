import 'package:flutter/material.dart';
import 'dart:async';

/// Enhanced loading indicator with progress tracking and estimated time
class EnhancedLoadingIndicator extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Color? color;
  final double? progress; // 0.0 to 1.0, null for indeterminate
  final int? totalItems;
  final int? completedItems;
  final Duration? estimatedTimeRemaining;
  final VoidCallback? onCancel;
  final bool showPercentage;
  final bool showItemCount;
  final bool showTimeRemaining;
  final List<String>? loadingMessages; // Rotating messages

  const EnhancedLoadingIndicator({
    Key? key,
    required this.title,
    this.subtitle,
    this.color,
    this.progress,
    this.totalItems,
    this.completedItems,
    this.estimatedTimeRemaining,
    this.onCancel,
    this.showPercentage = true,
    this.showItemCount = true,
    this.showTimeRemaining = true,
    this.loadingMessages,
  }) : super(key: key);

  @override
  State<EnhancedLoadingIndicator> createState() => _EnhancedLoadingIndicatorState();
}

class _EnhancedLoadingIndicatorState extends State<EnhancedLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotate loading messages every 3 seconds
    if (widget.loadingMessages != null && widget.loadingMessages!.isNotEmpty) {
      _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted) {
          setState(() {
            _currentMessageIndex = (_currentMessageIndex + 1) % widget.loadingMessages!.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated loading indicator
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: _buildProgressIndicator(color),
            ),

            const SizedBox(height: 24.0),

            // Title
            Text(
              widget.title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            if (widget.subtitle != null) ...[
              const SizedBox(height: 8.0),
              Text(
                widget.subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Progress percentage
            if (widget.showPercentage && widget.progress != null) ...[
              const SizedBox(height: 16.0),
              Text(
                '${(widget.progress! * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            // Item count
            if (widget.showItemCount &&
                widget.totalItems != null &&
                widget.completedItems != null) ...[
              const SizedBox(height: 8.0),
              Text(
                '${widget.completedItems} / ${widget.totalItems} items',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],

            // Estimated time remaining
            if (widget.showTimeRemaining && widget.estimatedTimeRemaining != null) ...[
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(widget.estimatedTimeRemaining!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],

            // Rotating loading messages
            if (widget.loadingMessages != null && widget.loadingMessages!.isNotEmpty) ...[
              const SizedBox(height: 16.0),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  key: ValueKey<int>(_currentMessageIndex),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.loadingMessages![_currentMessageIndex],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Cancel button
            if (widget.onCancel != null) ...[
              const SizedBox(height: 24.0),
              TextButton.icon(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(Color color) {
    if (widget.progress != null) {
      // Determinate progress indicator
      return SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: widget.progress,
                strokeWidth: 6,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Icon(
              Icons.hourglass_empty,
              color: color,
              size: 32,
            ),
          ],
        ),
      );
    } else {
      // Indeterminate progress indicator
      return SizedBox(
        width: 80,
        height: 80,
        child: CircularProgressIndicator(
          strokeWidth: 6,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m remaining';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s remaining';
    } else {
      return '${duration.inSeconds}s remaining';
    }
  }
}

/// Skeleton loading widget for content placeholders
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                theme.colorScheme.surfaceContainerHighest,
                theme.colorScheme.surfaceContainerHigh,
                theme.colorScheme.surfaceContainerHighest,
              ],
              stops: [
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

