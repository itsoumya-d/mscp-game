import 'package:flutter/material.dart';

/// Widget that draws the connecting path between level nodes
/// Uses CustomPaint to create smooth curved lines in a Candy Crush style
class LevelPath extends StatelessWidget {
  final List<Offset> nodePositions;
  final int highestUnlockedLevel;
  final Color unlockedColor;
  final Color lockedColor;
  final double strokeWidth;
  final double animationProgress;

  const LevelPath({
    Key? key,
    required this.nodePositions,
    required this.highestUnlockedLevel,
    required this.unlockedColor,
    required this.lockedColor,
    this.strokeWidth = 5.0,
    this.animationProgress = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LevelPathPainter(
        nodePositions: nodePositions,
        highestUnlockedLevel: highestUnlockedLevel,
        unlockedColor: unlockedColor,
        lockedColor: lockedColor,
        strokeWidth: strokeWidth,
        animationProgress: animationProgress,
      ),
      child: Container(),
    );
  }
}

/// Custom painter for drawing the level path
class _LevelPathPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final int highestUnlockedLevel;
  final Color unlockedColor;
  final Color lockedColor;
  final double strokeWidth;
  final double animationProgress;

  _LevelPathPainter({
    required this.nodePositions,
    required this.highestUnlockedLevel,
    required this.unlockedColor,
    required this.lockedColor,
    required this.strokeWidth,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) return;

    // Draw paths between consecutive nodes
    for (int i = 0; i < nodePositions.length - 1; i++) {
      final startPos = nodePositions[i];
      final endPos = nodePositions[i + 1];
      
      // Determine if this segment is unlocked
      final isUnlocked = i < highestUnlockedLevel;
      
      // Create paint for this segment
      final paint = Paint()
        ..color = isUnlocked ? unlockedColor : lockedColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Add dashed effect for locked segments
      if (!isUnlocked) {
        paint.strokeWidth = strokeWidth * 0.8;
      }

      // Create curved path between nodes
      final path = Path();
      path.moveTo(startPos.dx, startPos.dy);

      // Calculate control point for smooth curve
      final controlPoint = _calculateControlPoint(startPos, endPos);
      
      // Draw quadratic bezier curve
      path.quadraticBezierTo(
        controlPoint.dx,
        controlPoint.dy,
        endPos.dx,
        endPos.dy,
      );

      // Apply animation progress for path reveal effect
      if (i == highestUnlockedLevel - 1 && animationProgress < 1.0) {
        // Animate the path being drawn
        final pathMetrics = path.computeMetrics();
        final metric = pathMetrics.first;
        final extractPath = metric.extractPath(
          0.0,
          metric.length * animationProgress,
        );
        canvas.drawPath(extractPath, paint);
      } else if (!isUnlocked) {
        // Draw dashed line for locked segments
        _drawDashedPath(canvas, path, paint);
      } else {
        // Draw solid line for unlocked segments
        canvas.drawPath(path, paint);
      }

      // Add glow effect for unlocked paths
      if (isUnlocked) {
        final glowPaint = Paint()
          ..color = unlockedColor.withOpacity(0.3)
          ..strokeWidth = strokeWidth * 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(path, glowPaint);
      }
    }
  }

  /// Calculate control point for smooth curve between two points
  Offset _calculateControlPoint(Offset start, Offset end) {
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;
    
    // Add horizontal offset for more pronounced curve
    final horizontalOffset = (end.dx - start.dx) * 0.3;
    
    return Offset(midX + horizontalOffset, midY);
  }

  /// Draw dashed path for locked segments
  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      
      while (distance < metric.length) {
        final nextDistance = distance + (draw ? dashWidth : dashSpace);
        final extractPath = metric.extractPath(
          distance,
          nextDistance.clamp(0.0, metric.length),
        );
        
        if (draw) {
          canvas.drawPath(extractPath, paint);
        }
        
        distance = nextDistance;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LevelPathPainter oldDelegate) {
    return oldDelegate.highestUnlockedLevel != highestUnlockedLevel ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.nodePositions != nodePositions;
  }
}

