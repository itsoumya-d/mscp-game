import 'dart:math';
import 'package:flutter/material.dart';

/// Confetti & Celebration Effects - Task C3
/// Particle-based confetti animation for achievements
class ConfettiAnimation extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback? onComplete;
  final int particleCount;
  final Duration duration;

  const ConfettiAnimation({
    Key? key,
    required this.isPlaying,
    this.onComplete,
    this.particleCount = 50,
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _particles = List.generate(
      widget.particleCount,
      (index) => ConfettiParticle(),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.isPlaying) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ConfettiAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

/// Confetti particle
class ConfettiParticle {
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double rotationSpeed;
  final Color color;
  final double size;

  ConfettiParticle()
      : startX = Random().nextDouble(),
        startY = -0.1,
        velocityX = (Random().nextDouble() - 0.5) * 2,
        velocityY = Random().nextDouble() * 2 + 1,
        rotation = Random().nextDouble() * 2 * pi,
        rotationSpeed = (Random().nextDouble() - 0.5) * 10,
        color = _randomColor(),
        size = Random().nextDouble() * 8 + 4;

  static Color _randomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];
    return colors[Random().nextInt(colors.length)];
  }
}

/// Confetti painter
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final x = particle.startX * size.width + particle.velocityX * progress * 100;
      final y = particle.startY * size.height + particle.velocityY * progress * size.height;

      // Don't draw particles that are off screen
      if (y > size.height) continue;

      final paint = Paint()
        ..color = particle.color.withOpacity(1 - progress)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + particle.rotationSpeed * progress);

      // Draw confetti piece (rectangle)
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

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Success celebration widget
class SuccessCelebration extends StatefulWidget {
  final Widget child;
  final bool trigger;

  const SuccessCelebration({
    Key? key,
    required this.child,
    required this.trigger,
  }) : super(key: key);

  @override
  State<SuccessCelebration> createState() => _SuccessCelebrationState();
}

class _SuccessCelebrationState extends State<SuccessCelebration>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.bounceOut),
    );
  }

  @override
  void didUpdateWidget(SuccessCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _celebrate();
    }
  }

  void _celebrate() {
    setState(() => _showConfetti = true);
    _scaleController.forward(from: 0);
    _bounceController.forward(from: 0);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showConfetti = false);
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti layer
        if (_showConfetti)
          Positioned.fill(
            child: ConfettiAnimation(
              isPlaying: _showConfetti,
              onComplete: () {
                setState(() => _showConfetti = false);
              },
            ),
          ),
        
        // Child with animations
        AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation, _bounceAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: widget.trigger ? _scaleAnimation.value : 1.0,
              child: Transform.translate(
                offset: Offset(0, -20 * _bounceAnimation.value),
                child: widget.child,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Star burst animation
class StarBurstAnimation extends StatefulWidget {
  final bool isPlaying;
  final Color color;

  const StarBurstAnimation({
    Key? key,
    required this.isPlaying,
    this.color = Colors.amber,
  }) : super(key: key);

  @override
  State<StarBurstAnimation> createState() => _StarBurstAnimationState();
}

class _StarBurstAnimationState extends State<StarBurstAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    if (widget.isPlaying) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(StarBurstAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: StarBurstPainter(
            progress: _controller.value,
            color: widget.color,
          ),
          child: Container(),
        );
      },
    );
  }
}

/// Star burst painter
class StarBurstPainter extends CustomPainter {
  final double progress;
  final Color color;

  StarBurstPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) + (progress * pi / 8);
      final radius = maxRadius * progress;
      final opacity = 1 - progress;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      final start = center;
      final end = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(StarBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

