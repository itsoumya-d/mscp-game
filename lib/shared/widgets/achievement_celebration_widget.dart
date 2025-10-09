import 'package:flutter/material.dart';
import 'package:sp/core/services/sound_manager_service.dart';
import 'package:sp/theme.dart';
import 'dart:math' as math;

/// Achievement celebration widget with confetti and animations
class AchievementCelebrationWidget extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color? color;
  final VoidCallback? onDismiss;

  const AchievementCelebrationWidget({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.emoji_events,
    this.color,
    this.onDismiss,
  });

  @override
  State<AchievementCelebrationWidget> createState() => _AchievementCelebrationWidgetState();
}

class _AchievementCelebrationWidgetState extends State<AchievementCelebrationWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _confettiController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: InteractiveDesign.normalAnimation,
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: InteractiveDesign.celebrationAnimation,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeIn,
    ));

    // Play achievement sound
    SoundManagerService.instance.playAchievementUnlock();

    // Start animations
    _slideController.forward();
    _confettiController.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _slideController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? LightModeColors.lightWarning;

    return Stack(
      children: [
        // Confetti overlay
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    animation: _confettiController,
                  ),
                );
              },
            ),
          ),
        ),

        // Achievement card
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(InteractiveDesign.mediumSpacing),
                child: Material(
                  elevation: InteractiveDesign.highElevation,
                  borderRadius: BorderRadius.circular(InteractiveDesign.mediumRadius),
                  child: Container(
                    padding: const EdgeInsets.all(InteractiveDesign.mediumSpacing),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.9),
                          color.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(InteractiveDesign.mediumRadius),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(InteractiveDesign.smallSpacing),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon,
                            size: InteractiveDesign.achievementBadgeSize / 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: InteractiveDesign.mediumSpacing),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: InteractiveDesign.tinySpacing),
                              Text(
                                widget.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: _dismiss,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Confetti painter for celebration effects
class _ConfettiPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.animation})
      : particles = List.generate(50, (index) => _ConfettiParticle()),
        super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final progress = animation.value;
      final x = particle.startX * size.width;
      final y = particle.startY * size.height + (progress * size.height * particle.speed);
      
      if (y < size.height) {
        final paint = Paint()
          ..color = particle.color.withOpacity(1 - progress)
          ..style = PaintingStyle.fill;

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(progress * math.pi * 4 * particle.rotation);
        
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 2,
          ),
          paint,
        );
        
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}

/// Confetti particle data
class _ConfettiParticle {
  final double startX;
  final double startY;
  final double speed;
  final double rotation;
  final double size;
  final Color color;

  _ConfettiParticle()
      : startX = math.Random().nextDouble(),
        startY = math.Random().nextDouble() * 0.3,
        speed = 0.5 + math.Random().nextDouble() * 0.5,
        rotation = math.Random().nextDouble() * 2 - 1,
        size = 4 + math.Random().nextDouble() * 8,
        color = _randomColor();

  static Color _randomColor() {
    final colors = [
      LightModeColors.lightParticleGold,
      LightModeColors.lightParticleSilver,
      LightModeColors.lightSuccess,
      LightModeColors.lightWarning,
      LightModeColors.lightInfo,
      LightModeColors.lightGamePrimary,
      LightModeColors.lightGameSecondary,
    ];
    return colors[math.Random().nextInt(colors.length)];
  }
}

/// Level up celebration widget
class LevelUpCelebrationWidget extends StatefulWidget {
  final int newLevel;
  final VoidCallback? onDismiss;

  const LevelUpCelebrationWidget({
    super.key,
    required this.newLevel,
    this.onDismiss,
  });

  @override
  State<LevelUpCelebrationWidget> createState() => _LevelUpCelebrationWidgetState();
}

class _LevelUpCelebrationWidgetState extends State<LevelUpCelebrationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: InteractiveDesign.celebrationAnimation,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    SoundManagerService.instance.playLevelComplete();
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(InteractiveDesign.largeSpacing),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    LightModeColors.lightWarning,
                    LightModeColors.lightWarning.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: LightModeColors.lightWarning.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: InteractiveDesign.smallSpacing),
                  Text(
                    'LEVEL UP!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Level ${widget.newLevel}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

