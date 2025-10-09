import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated Progress Bar - Task C4
/// Progress bars with smooth fills, milestone markers, and glow effects

/// Animated linear progress bar with glow
class AnimatedProgressBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool showGlow;
  final Duration animationDuration;
  final List<double>? milestones; // e.g., [0.25, 0.5, 0.75, 1.0]

  const AnimatedProgressBar({
    Key? key,
    required this.progress,
    this.height = 12,
    this.color,
    this.backgroundColor,
    this.borderRadius,
    this.showGlow = true,
    this.animationDuration = const Duration(milliseconds: 800),
    this.milestones,
  }) : super(key: key);

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = Tween<double>(
      begin: _previousProgress,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _previousProgress = oldWidget.progress;
      _animation = Tween<double>(
        begin: _previousProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final bgColor = widget.backgroundColor ??
        Theme.of(context).colorScheme.surfaceVariant;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            // Background
            Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius:
                    widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
              ),
            ),
            // Progress with glow
            if (widget.showGlow)
              Container(
                height: widget.height,
                width: MediaQuery.of(context).size.width * _animation.value,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            // Progress fill
            Container(
              height: widget.height,
              width: MediaQuery.of(context).size.width * _animation.value,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withOpacity(0.8),
                  ],
                ),
                borderRadius:
                    widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
              ),
            ),
            // Milestone markers
            if (widget.milestones != null)
              ...widget.milestones!.map((milestone) {
                return Positioned(
                  left: MediaQuery.of(context).size.width * milestone - 2,
                  child: Container(
                    width: 4,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: _animation.value >= milestone
                          ? Colors.white
                          : Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }).toList(),
          ],
        );
      },
    );
  }
}

/// Circular progress indicator with animation
class AnimatedCircularProgress extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;
  final bool showPercentage;
  final Duration animationDuration;

  const AnimatedCircularProgress({
    Key? key,
    required this.progress,
    this.size = 100,
    this.strokeWidth = 8,
    this.color,
    this.backgroundColor,
    this.showPercentage = true,
    this.animationDuration = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  State<AnimatedCircularProgress> createState() =>
      _AnimatedCircularProgressState();
}

class _AnimatedCircularProgressState extends State<AnimatedCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final bgColor = widget.backgroundColor ??
        Theme.of(context).colorScheme.surfaceVariant;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CircleProgressPainter(
                  progress: 1.0,
                  color: bgColor,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              // Progress circle
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CircleProgressPainter(
                  progress: _animation.value,
                  color: color,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              // Percentage text
              if (widget.showPercentage)
                Text(
                  '${(_animation.value * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: widget.size * 0.2,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircleProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Segmented progress bar (like skill levels)
class SegmentedProgressBar extends StatelessWidget {
  final int totalSegments;
  final int filledSegments;
  final double height;
  final double spacing;
  final Color? filledColor;
  final Color? unfilledColor;

  const SegmentedProgressBar({
    Key? key,
    required this.totalSegments,
    required this.filledSegments,
    this.height = 8,
    this.spacing = 4,
    this.filledColor,
    this.unfilledColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filled = filledColor ?? Theme.of(context).colorScheme.primary;
    final unfilled = unfilledColor ?? Theme.of(context).colorScheme.surfaceVariant;

    return Row(
      children: List.generate(totalSegments, (index) {
        return Expanded(
          child: Container(
            height: height,
            margin: EdgeInsets.only(
              right: index < totalSegments - 1 ? spacing : 0,
            ),
            decoration: BoxDecoration(
              color: index < filledSegments ? filled : unfilled,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        );
      }),
    );
  }
}

/// Wave progress indicator
class WaveProgressIndicator extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final Color? color;

  const WaveProgressIndicator({
    Key? key,
    required this.progress,
    this.size = 100,
    this.color,
  }) : super(key: key);

  @override
  State<WaveProgressIndicator> createState() => _WaveProgressIndicatorState();
}

class _WaveProgressIndicatorState extends State<WaveProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipOval(
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _WavePainter(
                progress: widget.progress,
                wavePhase: _controller.value,
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color color;

  _WavePainter({
    required this.progress,
    required this.wavePhase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = size.height * 0.05;
    final waterLevel = size.height * (1 - progress);

    path.moveTo(0, waterLevel);

    for (double x = 0; x <= size.width; x++) {
      final y = waterLevel +
          waveHeight * math.sin((x / size.width * 2 * math.pi) + (wavePhase * 2 * math.pi));
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.wavePhase != wavePhase;
  }
}

