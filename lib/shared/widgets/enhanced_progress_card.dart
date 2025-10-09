import 'package:flutter/material.dart';
import 'package:sp/core/models/user.dart';
import 'package:sp/shared/widgets/elevated_card.dart';
import 'package:sp/shared/widgets/progress_ring.dart';
import 'dart:math' as math;
import 'performance_optimized_widget.dart';

class EnhancedProgressCard extends StatefulWidget {
  final User user;
  final double levelProgress;
  final int xpInLevel;
  final int xpToNext;

  const EnhancedProgressCard({
    super.key,
    required this.user,
    required this.levelProgress,
    required this.xpInLevel,
    required this.xpToNext,
  });

  @override
  State<EnhancedProgressCard> createState() => _EnhancedProgressCardState();
}

class _EnhancedProgressCardState extends State<EnhancedProgressCard>
    with TickerProviderStateMixin, PerformanceOptimizedAnimationMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: getOptimizedDuration(const Duration(milliseconds: 1500)),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: getOptimizedDuration(const Duration(milliseconds: 2000)),
      vsync: this,
    );
    
    _sparkleController = AnimationController(
      duration: getOptimizedDuration(const Duration(milliseconds: 3000)),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.levelProgress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: getOptimizedCurve(Curves.easeOutCubic),
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: getOptimizedCurve(Curves.easeInOut),
    ));

    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: getOptimizedCurve(Curves.easeInOut),
    ));

    // Start animations
    _progressController.forward();
    if (!isLowPerformanceMode) {
      _pulseController.repeat(reverse: true);
      _sparkleController.repeat();
    }
  }

  @override
  void didUpdateWidget(EnhancedProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.levelProgress != widget.levelProgress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.levelProgress,
        end: widget.levelProgress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ));
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void onPerformanceModeChanged(bool isLowPerformance) {
    if (isLowPerformance) {
      _pulseController.stop();
      _sparkleController.stop();
    } else {
      _pulseController.repeat(reverse: true);
      _sparkleController.repeat();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _progressAnimation,
        _pulseAnimation,
        _sparkleAnimation,
      ]),
      builder: (context, child) {
        return ElevatedCard(
          child: Stack(
            children: [
              // Sparkle effects
              if (widget.levelProgress > 0.8)
                ...List.generate(5, (index) {
                  final angle = (index * 72) * math.pi / 180;
                  final distance = 40 + math.sin(_sparkleAnimation.value * 2 * math.pi + index) * 10;
                  return Positioned(
                    left: 80 + math.cos(angle) * distance,
                    top: 40 + math.sin(angle) * distance,
                    child: Transform.scale(
                      scale: 0.5 + math.sin(_sparkleAnimation.value * 4 * math.pi + index) * 0.3,
                      child: Icon(
                        Icons.star,
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.3 + math.sin(_sparkleAnimation.value * 3 * math.pi + index) * 0.2,
                        ),
                        size: 12,
                      ),
                    ),
                  );
                }),
              
              Column(
                children: [
                  Row(
                    children: [
                      Transform.scale(
                        scale: _pulseAnimation.value,
                        child: ProgressRing(
                          progress: _progressAnimation.value,
                          size: 60,
                          strokeWidth: 6,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${widget.user.level}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Level ${widget.user.level}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.levelProgress > 0.9)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Transform.rotate(
                                      angle: math.sin(_sparkleAnimation.value * 4 * math.pi) * 0.2,
                                      child: Icon(
                                        Icons.local_fire_department,
                                        color: Colors.orange,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.user.totalXP} XP total',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.xpInLevel} / ${widget.xpToNext} XP',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: theme.colorScheme.outline.withValues(alpha: 0.1),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Stack(
                                  children: [
                                    FractionallySizedBox(
                                      widthFactor: _progressAnimation.value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              theme.colorScheme.primary,
                                              theme.colorScheme.secondary,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_progressAnimation.value > 0)
                                      Positioned(
                                        right: 0,
                                        child: Container(
                                          width: 4,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.8),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _EnhancedStatItem(
                          icon: Icons.local_fire_department,
                          label: 'Streak',
                          value: '${widget.user.currentStreak}',
                          color: Colors.orange,
                          animationValue: _sparkleAnimation.value,
                        ),
                      ),
                      Expanded(
                        child: _EnhancedStatItem(
                          icon: Icons.diamond,
                          label: 'Gems',
                          value: '${widget.user.gems}',
                          color: Colors.blue,
                          animationValue: _sparkleAnimation.value,
                        ),
                      ),
                      Expanded(
                        child: _EnhancedStatItem(
                          icon: Icons.favorite,
                          label: 'Lives',
                          value: '${widget.user.lives}',
                          color: Colors.red,
                          animationValue: _sparkleAnimation.value,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EnhancedStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double animationValue;

  const _EnhancedStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.animationValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Transform.scale(
          scale: 1.0 + math.sin(animationValue * 2 * math.pi) * 0.05,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}