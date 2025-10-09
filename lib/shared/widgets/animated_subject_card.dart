import 'package:flutter/material.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/shared/widgets/progress_ring.dart';
import 'package:sp/core/services/asset_service.dart';
import 'dart:math' as math;
import 'performance_optimized_widget.dart';
import 'elevated_card.dart';

class AnimatedSubjectCard extends StatefulWidget {
  final Subject subject;
  final VoidCallback? onTap;
  final bool isUnlocked;

  const AnimatedSubjectCard({
    super.key,
    required this.subject,
    this.onTap,
    this.isUnlocked = true,
  });

  @override
  State<AnimatedSubjectCard> createState() => _AnimatedSubjectCardState();
}

class _AnimatedSubjectCardState extends State<AnimatedSubjectCard>
    with TickerProviderStateMixin, PerformanceOptimizedAnimationMixin {
  late AnimationController _hoverController;
  late AnimationController _progressController;
  late AnimationController _unlockController;
  late AnimationController _pulseController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _unlockAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    _hoverController = AnimationController(
      duration: getOptimizedDuration(const Duration(milliseconds: 200)),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: getOptimizedDuration(const Duration(milliseconds: 1000)),
      vsync: this,
    );
    
    _unlockController = AnimationController(
      duration: getOptimizedDuration(const Duration(milliseconds: 800)),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: getOptimizedDuration(const Duration(milliseconds: 1500)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: getOptimizedCurve(Curves.easeOutCubic),
    ));

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: getOptimizedCurve(Curves.easeOutCubic),
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.subject.progressPercentage / 100,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: getOptimizedCurve(Curves.easeOutCubic),
    ));

    _unlockAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _unlockController,
      curve: getOptimizedCurve(Curves.elasticOut),
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: getOptimizedCurve(Curves.easeInOut),
    ));

    // Start animations
    if (widget.isUnlocked) {
      _unlockController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _progressController.forward();
      });
    }
    if (!isLowPerformanceMode && widget.isUnlocked) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedSubjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subject.progressPercentage != widget.subject.progressPercentage) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.subject.progressPercentage / 100,
        end: widget.subject.progressPercentage / 100,
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
    } else if (widget.isUnlocked) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _progressController.dispose();
    _unlockController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _progressAnimation.value;
    final isLocked = !widget.isUnlocked;
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _elevationAnimation,
        _progressAnimation,
        _unlockAnimation,
        _pulseAnimation,
      ]),
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => _onHover(true),
          onExit: (_) => _onHover(false),
          child: Transform.scale(
            scale: _scaleAnimation.value * _unlockAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                  ),
                ],
              ),
              child: ElevatedCard(
                onTap: widget.isUnlocked ? widget.onTap : null,
                child: Stack(
                  children: [
                    // Locked overlay
                    if (isLocked)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Icon(
                                Icons.lock,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    
                    // Main content
                    Opacity(
                      opacity: isLocked ? 0.5 : 1.0,
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Progress ring with glow effect
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: progress > 0.5 ? [
                                        BoxShadow(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ] : null,
                                    ),
                                    child: ProgressRing(
                                      progress: progress,
                                      size: 60,
                                      strokeWidth: 4,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          width: 35,
                                          height: 35,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                theme.colorScheme.primary.withValues(alpha: 0.1),
                                                theme.colorScheme.secondary.withValues(alpha: 0.1),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(17.5),
                                          ),
                                          child: AssetService.getSubjectIcon(
                                            widget.subject.type,
                                            width: 20,
                                            height: 20,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // Completion sparkles
                                  if (progress >= 1.0)
                                    ...List.generate(6, (index) {
                                      final angle = (index * 60) * math.pi / 180;
                                      final distance = 35 + math.sin(_pulseAnimation.value * 2 * math.pi + index) * 5;
                                      return Positioned(
                                        left: 30 + math.cos(angle) * distance,
                                        top: 30 + math.sin(angle) * distance,
                                        child: Transform.scale(
                                          scale: 0.3 + math.sin(_pulseAnimation.value * 3 * math.pi + index) * 0.2,
                                          child: Icon(
                                            Icons.star,
                                            color: Colors.amber.withValues(
                                              alpha: 0.7 + math.sin(_pulseAnimation.value * 4 * math.pi + index) * 0.3,
                                            ),
                                            size: 8,
                                          ),
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              flex: 2,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.subject.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: _isHovered 
                                        ? theme.colorScheme.primary 
                                        : theme.colorScheme.onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Expanded(
                                    child: Text(
                                      widget.subject.description,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                        fontSize: 10,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary.withValues(alpha: 0.1),
                                          theme.colorScheme.secondary.withValues(alpha: 0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${widget.subject.completedSkills}/${widget.subject.totalSkills} skills',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


}