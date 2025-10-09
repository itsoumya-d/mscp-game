import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../core/models/study_session.dart';
import '../../../core/models/flashcard.dart';

class AchievementPopup extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;

  const AchievementPopup({
    Key? key,
    required this.achievement,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<AchievementPopup> createState() => _AchievementPopupState();
}

class _AchievementPopupState extends State<AchievementPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late AnimationController _shimmerController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _confettiAnimation;
  late Animation<double> _shimmerAnimation;
  
  final List<ConfettiParticle> _confettiParticles = [];

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    _initializeConfetti();
    _startAnimations();
  }

  void _initializeConfetti() {
    final random = math.Random();
    for (int i = 0; i < 30; i++) {
      _confettiParticles.add(ConfettiParticle(
        x: random.nextDouble(),
        y: random.nextDouble() * 0.3,
        vx: (random.nextDouble() - 0.5) * 2,
        vy: random.nextDouble() * 2 + 1,
        color: _getRandomColor(random),
        size: random.nextDouble() * 6 + 2,
        rotation: random.nextDouble() * 2 * math.pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.2,
      ));
    }
  }

  Color _getRandomColor(math.Random random) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[random.nextInt(colors.length)];
  }

  void _startAnimations() async {
    // Haptic feedback
    HapticFeedback.heavyImpact();
    
    // Start scale animation
    _scaleController.forward();
    
    // Start confetti after a short delay
    await Future.delayed(const Duration(milliseconds: 200));
    _confettiController.forward();
    
    // Start shimmer effect
    _shimmerController.repeat();
    
    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _scaleController.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: GestureDetector(
        onTap: _dismiss,
        child: Stack(
          children: [
            // Confetti layer
            AnimatedBuilder(
              animation: _confettiAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ConfettiPainter(
                    particles: _confettiParticles,
                    progress: _confettiAnimation.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
            
            // Achievement card
            Center(
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: _buildAchievementCard(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard() {
    return Container(
      margin: const EdgeInsets.all(40),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Achievement badge with shimmer effect
          AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Shimmer background
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        transform: GradientRotation(
                          _shimmerAnimation.value * 2 * math.pi,
                        ),
                      ),
                    ),
                  ),
                  
                  // Badge
                  _buildBadge(),
                ],
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Achievement unlocked text
          const Text(
            'Achievement Unlocked!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4ECDC4),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Achievement name
          Text(
            widget.achievement.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Achievement description
          Text(
            widget.achievement.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // XP reward
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '+${widget.achievement.xpReward} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Dismiss hint
          Text(
            'Tap anywhere to continue',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _getBadgeGradient(),
        boxShadow: [
          BoxShadow(
            color: _getBadgeColor().withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        _getBadgeIcon(),
        color: Colors.white,
        size: 50,
      ),
    );
  }

  LinearGradient _getBadgeGradient() {
    // Use achievement ID to determine type-based styling
    final id = widget.achievement.id.toLowerCase();
    if (id.contains('streak') || id.contains('daily') || id.contains('consecutive')) {
      return const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
      );
    } else if (id.contains('accuracy') || id.contains('perfect') || id.contains('score')) {
      return const LinearGradient(
        colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
      );
    } else if (id.contains('speed') || id.contains('fast') || id.contains('quick')) {
      return const LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
      );
    } else if (id.contains('milestone') || id.contains('level') || id.contains('master')) {
      return const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
      );
    }
  }

  Color _getBadgeColor() {
    // Use achievement ID to determine type-based styling
    final id = widget.achievement.id.toLowerCase();
    if (id.contains('streak') || id.contains('daily') || id.contains('consecutive')) {
      return const Color(0xFFFF6B6B);
    } else if (id.contains('accuracy') || id.contains('perfect') || id.contains('score')) {
      return const Color(0xFF4ECDC4);
    } else if (id.contains('speed') || id.contains('fast') || id.contains('quick')) {
      return const Color(0xFF667eea);
    } else if (id.contains('milestone') || id.contains('level') || id.contains('master')) {
      return const Color(0xFFFFD700);
    } else {
      return const Color(0xFF4ECDC4);
    }
  }

  IconData _getBadgeIcon() {
    // Use achievement ID to determine type-based styling
    final id = widget.achievement.id.toLowerCase();
    if (id.contains('streak') || id.contains('daily') || id.contains('consecutive')) {
      return Icons.local_fire_department;
    } else if (id.contains('accuracy') || id.contains('perfect') || id.contains('score')) {
      return Icons.center_focus_strong;
    } else if (id.contains('speed') || id.contains('fast') || id.contains('quick')) {
      return Icons.flash_on;
    } else if (id.contains('milestone') || id.contains('level') || id.contains('master')) {
      return Icons.emoji_events;
    } else {
      return Icons.star;
    }
  }
}

class ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  final Color color;
  final double size;
  double rotation;
  final double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 0.5 * dt; // Gravity
    rotation += rotationSpeed * dt;
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Update particle position based on progress
      final updatedParticle = ConfettiParticle(
        x: particle.x + particle.vx * progress,
        y: particle.y + particle.vy * progress + 0.5 * progress * progress,
        vx: particle.vx,
        vy: particle.vy,
        color: particle.color,
        size: particle.size,
        rotation: particle.rotation + particle.rotationSpeed * progress,
        rotationSpeed: particle.rotationSpeed,
      );

      final paint = Paint()
        ..color = particle.color.withOpacity(1.0 - progress * 0.7);

      canvas.save();
      canvas.translate(
        updatedParticle.x * size.width,
        updatedParticle.y * size.height,
      );
      canvas.rotate(updatedParticle.rotation);
      
      // Draw confetti piece (rectangle)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          const Radius.circular(1),
        ),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is ConfettiPainter && oldDelegate.progress != progress;
  }
}

// Quick achievement popup for smaller rewards
class QuickAchievementToast extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;
  final Duration duration;

  const QuickAchievementToast({
    Key? key,
    required this.message,
    this.icon = Icons.star,
    this.color = const Color(0xFF4ECDC4),
    this.duration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<QuickAchievementToast> createState() => _QuickAchievementToastState();
}

class _QuickAchievementToastState extends State<QuickAchievementToast>
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
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _controller.forward();
    
    // Auto-dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse();
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
                color: widget.color,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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