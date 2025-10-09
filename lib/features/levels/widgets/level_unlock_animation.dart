import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A widget that displays an animated level unlock sequence
class LevelUnlockAnimation extends StatefulWidget {
  final int level;
  final VoidCallback? onComplete;
  final Color primaryColor;
  final bool autoStart;

  const LevelUnlockAnimation({
    Key? key,
    required this.level,
    this.onComplete,
    this.primaryColor = Colors.blue,
    this.autoStart = true,
  }) : super(key: key);

  @override
  State<LevelUnlockAnimation> createState() => _LevelUnlockAnimationState();
}

class _LevelUnlockAnimationState extends State<LevelUnlockAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _particleController;
  late AnimationController _textController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation for the main unlock effect
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Rotation animation for the lock icon
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    // Particle animation for sparkle effects
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
    );

    // Text animation for level number reveal
    _textController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.bounceOut),
    );

    if (widget.autoStart) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _startAnimation() async {
    // Start scale and rotation animations
    _scaleController.forward();
    _rotationController.forward();
    
    // Start particle animation after a short delay
    await Future.delayed(const Duration(milliseconds: 200));
    _particleController.forward();
    
    // Start text animation after lock opens
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();
    
    // Call completion callback
    await Future.delayed(const Duration(milliseconds: 800));
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Particle effects
            AnimatedBuilder(
              animation: _particleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(200, 200),
                  painter: ParticleEffectPainter(
                    progress: _particleAnimation.value,
                    primaryColor: widget.primaryColor,
                  ),
                );
              },
            ),
            
            // Main unlock circle
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Lock icon that transforms to unlock
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                final isUnlocked = _rotationAnimation.value > 0.5;
                return Transform.rotate(
                  angle: _rotationAnimation.value * math.pi * 0.2,
                  child: Icon(
                    isUnlocked ? Icons.lock_open : Icons.lock,
                    size: 48,
                    color: Colors.white,
                  ),
                );
              },
            ),
            
            // Level number reveal
            AnimatedBuilder(
              animation: _textAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _textAnimation.value,
                  child: Opacity(
                    opacity: _textAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 80),
                        Text(
                          'LEVEL ${widget.level}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'UNLOCKED!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for particle effects
class ParticleEffectPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final List<Particle> particles;

  ParticleEffectPainter({
    required this.progress,
    required this.primaryColor,
  }) : particles = _generateParticles();

  static List<Particle> _generateParticles() {
    final random = math.Random();
    return List.generate(20, (index) {
      return Particle(
        angle: random.nextDouble() * 2 * math.pi,
        distance: 50 + random.nextDouble() * 50,
        size: 2 + random.nextDouble() * 4,
        speed: 0.5 + random.nextDouble() * 0.5,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      final particleProgress = (progress * particle.speed).clamp(0.0, 1.0);
      final currentDistance = particle.distance * particleProgress;
      final opacity = (1.0 - particleProgress).clamp(0.0, 1.0);
      
      final x = center.dx + math.cos(particle.angle) * currentDistance;
      final y = center.dy + math.sin(particle.angle) * currentDistance;
      
      paint.color = primaryColor.withOpacity(opacity * 0.8);
      canvas.drawCircle(
        Offset(x, y),
        particle.size * (1.0 - particleProgress * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticleEffectPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Data class for particle information
class Particle {
  final double angle;
  final double distance;
  final double size;
  final double speed;

  Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.speed,
  });
}

/// A simple unlock notification widget
class UnlockNotification extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Duration duration;
  final VoidCallback? onDismiss;

  const UnlockNotification({
    Key? key,
    required this.message,
    this.backgroundColor = Colors.green,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  }) : super(key: key);

  @override
  State<UnlockNotification> createState() => _UnlockNotificationState();
}

class _UnlockNotificationState extends State<UnlockNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    _controller.forward();
    
    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_open,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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