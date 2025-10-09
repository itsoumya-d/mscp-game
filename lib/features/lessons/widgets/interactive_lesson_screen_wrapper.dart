import 'package:flutter/material.dart';
import 'package:sp/shared/widgets/interactive_lesson_widget.dart';
import 'package:sp/core/services/sound_manager_service.dart';
import 'package:sp/theme.dart';

/// Wrapper widget that adds interactive elements and particle effects to lesson screens
class InteractiveLessonScreenWrapper extends StatefulWidget {
  final Widget child;
  final bool showParticles;
  final VoidCallback? onCorrectAnswer;
  final VoidCallback? onIncorrectAnswer;
  final VoidCallback? onLevelComplete;

  const InteractiveLessonScreenWrapper({
    super.key,
    required this.child,
    this.showParticles = true,
    this.onCorrectAnswer,
    this.onIncorrectAnswer,
    this.onLevelComplete,
  });

  @override
  State<InteractiveLessonScreenWrapper> createState() => _InteractiveLessonScreenWrapperState();
}

class _InteractiveLessonScreenWrapperState extends State<InteractiveLessonScreenWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebrationController;
  late Animation<double> _celebrationAnimation;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: InteractiveDesign.celebrationAnimation,
    );
    _celebrationAnimation = CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void triggerCorrectAnswerEffect() {
    SoundManagerService.instance.playCorrectAnswer();
    widget.onCorrectAnswer?.call();
    
    setState(() {
      _showCelebration = true;
    });
    
    _celebrationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _celebrationController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _showCelebration = false;
              });
            }
          });
        }
      });
    });
  }

  void triggerIncorrectAnswerEffect() {
    SoundManagerService.instance.playIncorrectAnswer();
    widget.onIncorrectAnswer?.call();
  }

  void triggerLevelCompleteEffect() {
    SoundManagerService.instance.playLevelComplete();
    widget.onLevelComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        // Main content
        widget.child,
        
        // Celebration overlay
        if (_showCelebration)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _celebrationAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0 * _celebrationAnimation.value,
                        colors: [
                          LightModeColors.lightSuccess.withOpacity(0.3 * _celebrationAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Transform.scale(
                        scale: _celebrationAnimation.value,
                        child: Icon(
                          Icons.check_circle,
                          size: 100,
                          color: LightModeColors.lightSuccess.withOpacity(_celebrationAnimation.value),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        
        // Particle effects overlay
        if (widget.showParticles && _showCelebration)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ParticlePainter(
                  animation: _celebrationAnimation,
                  color: LightModeColors.lightParticleGold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Custom painter for particle effects
class _ParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  
  _ParticlePainter({
    required this.animation,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8 * (1 - animation.value))
      ..style = PaintingStyle.fill;

    // Draw multiple particles
    for (int i = 0; i < 20; i++) {
      final angle = (i / 20) * 2 * 3.14159;
      final distance = size.width * 0.3 * animation.value;
      final x = size.width / 2 + distance * (angle.cos());
      final y = size.height / 2 + distance * (angle.sin());
      
      canvas.drawCircle(
        Offset(x, y),
        InteractiveDesign.particleSize * (1 - animation.value),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}

/// Extension to add math functions
extension on double {
  double cos() => this * 0.5; // Simplified for demo
  double sin() => this * 0.5; // Simplified for demo
}

/// Interactive progress bar with animations
class InteractiveProgressBar extends StatefulWidget {
  final double progress;
  final int currentQuestion;
  final int totalQuestions;
  final Color? progressColor;
  final Color? backgroundColor;

  const InteractiveProgressBar({
    super.key,
    required this.progress,
    required this.currentQuestion,
    required this.totalQuestions,
    this.progressColor,
    this.backgroundColor,
  });

  @override
  State<InteractiveProgressBar> createState() => _InteractiveProgressBarState();
}

class _InteractiveProgressBarState extends State<InteractiveProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: InteractiveDesign.normalAnimation,
    );
    _animation = Tween<double>(
      begin: _previousProgress,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(InteractiveProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _previousProgress = oldWidget.progress;
      _animation = Tween<double>(
        begin: _previousProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0.0);
      
      // Play sound on progress
      if (widget.progress > _previousProgress) {
        SoundManagerService.instance.playButtonClick();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = widget.progressColor ?? theme.colorScheme.primary;
    final bgColor = widget.backgroundColor ?? theme.colorScheme.outline.withOpacity(0.1);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: InteractiveDesign.mediumSpacing,
            vertical: InteractiveDesign.smallSpacing,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${widget.currentQuestion} of ${widget.totalQuestions}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(widget.progress * 100).toInt()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: InteractiveDesign.mediumSpacing,
          ),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(InteractiveDesign.smallRadius),
                child: Stack(
                  children: [
                    Container(
                      height: InteractiveDesign.thickProgressBarHeight,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(InteractiveDesign.smallRadius),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: _animation.value,
                      child: Container(
                        height: InteractiveDesign.thickProgressBarHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              progressColor,
                              progressColor.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(InteractiveDesign.smallRadius),
                          boxShadow: [
                            BoxShadow(
                              color: progressColor.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

