import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flame/events.dart';
import 'package:sp/core/services/sound_manager_service.dart';
import 'package:sp/theme.dart';

/// Interactive lesson widget with Flame engine integration
class InteractiveLessonWidget extends StatefulWidget {
  final Widget child;
  final bool showParticles;
  final bool enableSoundEffects;
  final VoidCallback? onTap;
  final VoidCallback? onCorrectAnswer;
  final VoidCallback? onIncorrectAnswer;

  const InteractiveLessonWidget({
    super.key,
    required this.child,
    this.showParticles = false,
    this.enableSoundEffects = true,
    this.onTap,
    this.onCorrectAnswer,
    this.onIncorrectAnswer,
  });

  @override
  State<InteractiveLessonWidget> createState() => _InteractiveLessonWidgetState();
}

class _InteractiveLessonWidgetState extends State<InteractiveLessonWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
  LessonParticleGame? _particleGame;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: InteractiveDesign.fastAnimation,
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: InteractiveDesign.normalAnimation,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    if (widget.showParticles) {
      _particleGame = LessonParticleGame();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.enableSoundEffects) {
      SoundManagerService.instance.playButtonClick();
    }
    
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    
    widget.onTap?.call();
  }

  void _triggerCorrectAnswer() {
    if (widget.enableSoundEffects) {
      SoundManagerService.instance.playCorrectAnswer();
    }
    
    _glowController.forward().then((_) {
      _glowController.reverse();
    });
    
    _particleGame?.triggerSuccessParticles();
    widget.onCorrectAnswer?.call();
  }

  void _triggerIncorrectAnswer() {
    if (widget.enableSoundEffects) {
      SoundManagerService.instance.playIncorrectAnswer();
    }
    
    // Gentle shake animation for incorrect answers
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    
    widget.onIncorrectAnswer?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _glowAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(InteractiveDesign.mediumRadius),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(_glowAnimation.value * 0.3),
                    blurRadius: 20 * _glowAnimation.value,
                    spreadRadius: 5 * _glowAnimation.value,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  widget.child,
                  if (widget.showParticles && _particleGame != null)
                    Positioned.fill(
                      child: GameWidget<LessonParticleGame>.controlled(
                        gameFactory: () => _particleGame!,
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

/// Flame game for lesson particle effects
class LessonParticleGame extends FlameGame with TapCallbacks {
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Initialize particle systems
  }

  void triggerSuccessParticles() {
    final particleComponent = ParticleSystemComponent(
      particle: Particle.generate(
        count: 20,
        lifespan: 2.0,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2(0, 100),
          speed: Vector2.random() * 100,
          position: Vector2(size.x / 2, size.y / 2),
          child: CircleParticle(
            radius: 3.0,
            paint: Paint()..color = const Color(0xFFFFD700),
          ),
        ),
      ),
    );
    
    add(particleComponent);
  }

  void triggerCoinCollection(Vector2 position) {
    final coinParticle = ParticleSystemComponent(
      particle: Particle.generate(
        count: 10,
        lifespan: 1.5,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2(0, -200),
          speed: Vector2.random() * 50,
          position: position,
          child: CircleParticle(
            radius: 4.0,
            paint: Paint()..color = const Color(0xFFFFD700),
          ),
        ),
      ),
    );
    
    add(coinParticle);
  }
}

/// Interactive progress bar with Flame effects
class InteractiveProgressBar extends StatefulWidget {
  final double progress;
  final double height;
  final Color? backgroundColor;
  final Color? progressColor;
  final bool showParticles;
  final VoidCallback? onComplete;

  const InteractiveProgressBar({
    super.key,
    required this.progress,
    this.height = InteractiveDesign.progressBarHeight,
    this.backgroundColor,
    this.progressColor,
    this.showParticles = true,
    this.onComplete,
  });

  @override
  State<InteractiveProgressBar> createState() => _InteractiveProgressBarState();
}

class _InteractiveProgressBarState extends State<InteractiveProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: InteractiveDesign.normalAnimation,
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _progressController.forward();
  }

  @override
  void didUpdateWidget(InteractiveProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.progress != widget.progress) {
      _previousProgress = oldWidget.progress;
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ));
      
      _progressController.reset();
      _progressController.forward();
      
      if (widget.progress >= 1.0 && _previousProgress < 1.0) {
        widget.onComplete?.call();
        if (widget.showParticles) {
          SoundManagerService.instance.playLevelComplete();
        }
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.height / 2),
            color: widget.backgroundColor ?? theme.colorScheme.surfaceVariant,
          ),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  color: widget.backgroundColor ?? theme.colorScheme.surfaceVariant,
                ),
              ),
              FractionallySizedBox(
                widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                child: Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    gradient: LinearGradient(
                      colors: [
                        widget.progressColor ?? theme.colorScheme.primary,
                        (widget.progressColor ?? theme.colorScheme.primary).withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.progressColor ?? theme.colorScheme.primary).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.showParticles && _progressAnimation.value > 0.8)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          (widget.progressColor ?? theme.colorScheme.primary).withOpacity(0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
