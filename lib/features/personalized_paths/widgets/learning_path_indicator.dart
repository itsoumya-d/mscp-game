import 'package:flutter/material.dart';
import '../../../core/models/learning_path.dart';

class LearningPathIndicator extends StatefulWidget {
  final LearningPath? currentPath;
  final double progress;
  final String? nextRecommendation;
  final VoidCallback? onTap;

  const LearningPathIndicator({
    Key? key,
    this.currentPath,
    required this.progress,
    this.nextRecommendation,
    this.onTap,
  }) : super(key: key);

  @override
  State<LearningPathIndicator> createState() => _LearningPathIndicatorState();
}

class _LearningPathIndicatorState extends State<LearningPathIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Clamp progress values to valid range
    final clampedProgress = widget.progress.clamp(0.0, 1.0);
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: clampedProgress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void didUpdateWidget(LearningPathIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.progress != widget.progress) {
      // Clamp progress values to valid range
      final clampedOldProgress = oldWidget.progress.clamp(0.0, 1.0);
      final clampedNewProgress = widget.progress.clamp(0.0, 1.0);
      
      _progressAnimation = Tween<double>(
        begin: clampedOldProgress,
        end: clampedNewProgress,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getPathColor(LearningPathType? pathType) {
    if (pathType == null) return Colors.grey;
    
    switch (pathType) {
      case LearningPathType.adaptive:
        return Colors.purple;
      case LearningPathType.structured:
        return Colors.blue;
      case LearningPathType.exploratory:
        return Colors.green;
      case LearningPathType.remedial:
        return Colors.orange;
      case LearningPathType.accelerated:
        return Colors.red;
      case LearningPathType.collaborative:
        return Colors.teal;
      case LearningPathType.projectBased:
        return Colors.indigo;
      case LearningPathType.gamified:
        return Colors.pink;
    }
  }

  String _getPathName(LearningPathType? pathType) {
    if (pathType == null) return 'Standard';
    
    switch (pathType) {
      case LearningPathType.adaptive:
        return 'Adaptive';
      case LearningPathType.structured:
        return 'Structured';
      case LearningPathType.exploratory:
        return 'Exploratory';
      case LearningPathType.remedial:
        return 'Remedial';
      case LearningPathType.accelerated:
        return 'Accelerated';
      case LearningPathType.collaborative:
        return 'Collaborative';
      case LearningPathType.projectBased:
        return 'Project-Based';
      case LearningPathType.gamified:
        return 'Gamified';
    }
  }

  IconData _getPathIcon(LearningPathType? pathType) {
    if (pathType == null) return Icons.school;
    
    switch (pathType) {
      case LearningPathType.adaptive:
        return Icons.auto_awesome;
      case LearningPathType.structured:
        return Icons.list_alt;
      case LearningPathType.exploratory:
        return Icons.explore;
      case LearningPathType.remedial:
        return Icons.healing;
      case LearningPathType.accelerated:
        return Icons.speed;
      case LearningPathType.collaborative:
        return Icons.group;
      case LearningPathType.projectBased:
        return Icons.build;
      case LearningPathType.gamified:
        return Icons.games;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentPath == null) {
      return const SizedBox.shrink();
    }

    final pathColor = _getPathColor(widget.currentPath!.type);
    final pathName = _getPathName(widget.currentPath!.type);
    final pathIcon = _getPathIcon(widget.currentPath!.type);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: pathColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: pathColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with path type and icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: pathColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    pathIcon,
                    size: 16,
                    color: pathColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$pathName Learning Path',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: pathColor,
                    ),
                  ),
                ),
                Text(
                  '${(widget.progress.clamp(0.0, 1.0) * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Progress bar
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progressAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: pathColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Next recommendation
            if (widget.nextRecommendation != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: pathColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: pathColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 14,
                      color: pathColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Next: ${widget.nextRecommendation}',
                        style: TextStyle(
                          fontSize: 11,
                          color: pathColor.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}