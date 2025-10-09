import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'performance_optimized_widget.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? gradientColors;
  final bool showParticles;
  final int particleCount;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.gradientColors,
    this.showParticles = true,
    this.particleCount = 20,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin, PerformanceOptimizedAnimationMixin {
  late AnimationController _gradientController;
  late AnimationController _particleController;
  late Animation<double> _gradientAnimation;
  late Animation<double> _particleAnimation;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    
    _gradientController = AnimationController(
      duration: getOptimizedDuration(const Duration(seconds: 8)),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: getOptimizedDuration(const Duration(seconds: 20)),
      vsync: this,
    );

    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: getOptimizedCurve(Curves.easeInOut),
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: getOptimizedCurve(Curves.linear),
    ));

    _initializeParticles();
    
    if (!isLowPerformanceMode) {
      _gradientController.repeat(reverse: true);
      _particleController.repeat();
    }
  }

  @override
  void onPerformanceModeChanged(bool isLowPerformance) {
    if (isLowPerformance) {
      _gradientController.stop();
      _particleController.stop();
    } else {
      _gradientController.repeat(reverse: true);
      _particleController.repeat();
    }
  }

  void _initializeParticles() {
    _particles = List.generate(widget.particleCount, (index) {
      return Particle(
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: math.Random().nextDouble() * 4 + 1,
        speed: math.Random().nextDouble() * 0.5 + 0.1,
        opacity: math.Random().nextDouble() * 0.3 + 0.1,
      );
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColors = [
      theme.colorScheme.primary.withValues(alpha: 0.1),
      theme.colorScheme.secondary.withValues(alpha: 0.05),
      theme.colorScheme.tertiary.withValues(alpha: 0.08),
    ];

    return AnimatedBuilder(
      animation: Listenable.merge([_gradientController, _particleController]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradientColors ?? defaultColors,
              stops: [
                0.0,
                0.5 + math.sin(_gradientController.value * 2 * math.pi) * 0.2,
                1.0,
              ],
            ),
          ),
          child: Stack(
            children: [
              if (widget.showParticles)
                CustomPaint(
                  painter: ParticlePainter(
                    particles: _particles,
                    animationValue: _particleController.value,
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  size: Size.infinite,
                ),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      // Update particle position
      particle.y = (particle.y + particle.speed * 0.01) % 1.0;
      
      final x = particle.x * size.width;
      final y = particle.y * size.height;
      
      paint.color = color.withValues(alpha: particle.opacity);
      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}