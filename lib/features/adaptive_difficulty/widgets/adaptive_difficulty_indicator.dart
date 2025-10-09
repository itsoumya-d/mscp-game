import 'package:flutter/material.dart';
import '../../../core/models/difficulty_level.dart';

class AdaptiveDifficultyIndicator extends StatefulWidget {
  final DifficultyLevel currentDifficulty;
  final bool isAdaptive;
  final VoidCallback? onTap;

  const AdaptiveDifficultyIndicator({
    Key? key,
    required this.currentDifficulty,
    required this.isAdaptive,
    this.onTap,
  }) : super(key: key);

  @override
  State<AdaptiveDifficultyIndicator> createState() => _AdaptiveDifficultyIndicatorState();
}

class _AdaptiveDifficultyIndicatorState extends State<AdaptiveDifficultyIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: _getDifficultyColor(widget.currentDifficulty),
      end: _getDifficultyColor(widget.currentDifficulty).withOpacity(0.7),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isAdaptive) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AdaptiveDifficultyIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.currentDifficulty != widget.currentDifficulty) {
      // Trigger a brief animation when difficulty changes
      _animationController.reset();
      _animationController.forward().then((_) {
        if (widget.isAdaptive && mounted) {
          _animationController.repeat(reverse: true);
        }
      });
    }

    if (oldWidget.isAdaptive != widget.isAdaptive) {
      if (widget.isAdaptive) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return Colors.green;
      case DifficultyLevel.easy:
        return Colors.lightGreen;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
      case DifficultyLevel.expert:
        return Colors.purple;
    }
  }

  String _getDifficultyName(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 'Beginner';
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
      case DifficultyLevel.expert:
        return 'Expert';
    }
  }

  int _getDifficultyLevel(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 1;
      case DifficultyLevel.easy:
        return 3;
      case DifficultyLevel.medium:
        return 5;
      case DifficultyLevel.hard:
        return 7;
      case DifficultyLevel.expert:
        return 10;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isAdaptive ? _pulseAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.isAdaptive 
                    ? _colorAnimation.value 
                    : _getDifficultyColor(widget.currentDifficulty),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: widget.isAdaptive
                    ? [
                        BoxShadow(
                          color: _getDifficultyColor(widget.currentDifficulty).withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isAdaptive) ...[
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    widget.isAdaptive 
                        ? 'ADAPTIVE ${_getDifficultyLevel(widget.currentDifficulty)}'
                        : 'LV ${_getDifficultyLevel(widget.currentDifficulty)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}