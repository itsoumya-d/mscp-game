import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/models/unlock_event.dart';

/// A comprehensive widget for displaying unlock celebrations
/// Supports different types of unlock events with customizable animations
class UnlockCelebrationWidget extends StatefulWidget {
  final UnlockEvent unlockEvent;
  final VoidCallback? onComplete;
  final bool autoStart;

  const UnlockCelebrationWidget({
    Key? key,
    required this.unlockEvent,
    this.onComplete,
    this.autoStart = true,
  }) : super(key: key);

  @override
  State<UnlockCelebrationWidget> createState() => _UnlockCelebrationWidgetState();
}

class _UnlockCelebrationWidgetState extends State<UnlockCelebrationWidget>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _particleController;
  late AnimationController _textController;
  late AnimationController _rewardController;

  late Animation<double> _backgroundAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _rewardAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    if (widget.autoStart) {
      _startCelebration();
    }
  }

  void _initializeAnimations() {
    final duration = Duration(milliseconds: widget.unlockEvent.animationDuration);
    
    // Background fade-in animation
    _backgroundController = AnimationController(
      duration: Duration(milliseconds: (duration.inMilliseconds * 0.2).round()),
      vsync: this,
    );
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeIn),
    );

    // Main scale animation for the unlock effect
    _scaleController = AnimationController(
      duration: Duration(milliseconds: (duration.inMilliseconds * 0.4).round()),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Rotation animation for the icon
    _rotationController = AnimationController(
      duration: Duration(milliseconds: (duration.inMilliseconds * 0.3).round()),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    // Particle animation for sparkle effects
    _particleController = AnimationController(
      duration: Duration(milliseconds: (duration.inMilliseconds * 0.6).round()),
      vsync: this,
    );
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
    );

    // Text animation for title and subtitle reveal
    _textController = AnimationController(
      duration: Duration(milliseconds: (duration.inMilliseconds * 0.3).round()),
      vsync: this,
    );
    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.bounceOut),
    );

    // Reward animation for XP and gems
    _rewardController = AnimationController(
      duration: Duration(milliseconds: (duration.inMilliseconds * 0.4).round()),
      vsync: this,
    );
    _rewardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rewardController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    _textController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  Future<void> _startCelebration() async {
    // Start background fade-in
    _backgroundController.forward();
    
    // Start main animations with staggered timing
    await Future.delayed(const Duration(milliseconds: 100));
    _scaleController.forward();
    _rotationController.forward();
    
    // Start particle animation
    await Future.delayed(const Duration(milliseconds: 200));
    _particleController.forward();
    
    // Start text animation
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();
    
    // Start reward animation
    await Future.delayed(const Duration(milliseconds: 600));
    _rewardController.forward();
    
    // Call completion callback after full animation
    await Future.delayed(Duration(milliseconds: widget.unlockEvent.animationDuration - 1000));
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            color: Colors.black.withValues(alpha: 0.85 * _backgroundAnimation.value),
            child: Center(
              child: SizedBox(
                width: 300,
                height: 400,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Particle effects background
                    _buildParticleEffects(),
                    
                    // Main celebration content
                    _buildMainContent(),
                    
                    // Reward display
                    _buildRewardDisplay(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticleEffects() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(300, 400),
          painter: CelebrationParticlePainter(
            progress: _particleAnimation.value,
            primaryColor: widget.unlockEvent.primaryColor,
            secondaryColor: widget.unlockEvent.secondaryColor,
            unlockType: widget.unlockEvent.type,
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Main icon with scale and rotation
        AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation, _rotationAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * math.pi * 0.1,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.unlockEvent.primaryColor,
                        widget.unlockEvent.primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.unlockEvent.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.unlockEvent.iconData,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 40),
        
        // Title and subtitle with text animation
        AnimatedBuilder(
          animation: _textAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _textAnimation.value,
              child: Opacity(
                opacity: _textAnimation.value,
                child: Column(
                  children: [
                    Text(
                      widget.unlockEvent.title,
                      style: const TextStyle(
                        fontSize: 28,
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
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.unlockEvent.subtitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: widget.unlockEvent.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.unlockEvent.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.unlockEvent.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRewardDisplay() {
    if (widget.unlockEvent.rewards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _rewardAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _rewardAnimation.value,
            child: Opacity(
              opacity: _rewardAnimation.value,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.unlockEvent.rewards.entries.map((entry) {
                  final rewardType = entry.key;
                  final amount = entry.value;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getRewardIcon(rewardType),
                          color: _getRewardColor(rewardType),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '+$amount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getRewardIcon(String rewardType) {
    switch (rewardType.toLowerCase()) {
      case 'xp':
        return Icons.star;
      case 'gems':
        return Icons.diamond;
      case 'coins':
        return Icons.monetization_on;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _getRewardColor(String rewardType) {
    switch (rewardType.toLowerCase()) {
      case 'xp':
        return Colors.amber;
      case 'gems':
        return Colors.cyan;
      case 'coins':
        return Colors.yellow;
      default:
        return Colors.white;
    }
  }
}

/// Custom painter for celebration particle effects
class CelebrationParticlePainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final UnlockType unlockType;

  CelebrationParticlePainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.unlockType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    
    // Generate particles based on unlock type
    final particleCount = _getParticleCount();
    
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final distance = progress * (60 + (i % 3) * 20);
      final particleSize = (3 + (i % 3)) * progress;
      
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;
      
      paint.color = i % 2 == 0 ? primaryColor : secondaryColor;
      paint.color = paint.color.withValues(alpha: 1.0 - progress * 0.7);
      
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
    
    // Add sparkle effects
    _drawSparkles(canvas, size, center);
  }

  void _drawSparkles(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: progress * 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi + progress * math.pi;
      final distance = 80 + math.sin(progress * math.pi * 2) * 10;
      
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;
      
      final sparkleSize = 8 * progress;
      
      // Draw cross-shaped sparkle
      canvas.drawLine(
        Offset(x - sparkleSize, y),
        Offset(x + sparkleSize, y),
        paint,
      );
      canvas.drawLine(
        Offset(x, y - sparkleSize),
        Offset(x, y + sparkleSize),
        paint,
      );
    }
  }

  int _getParticleCount() {
    switch (unlockType) {
      case UnlockType.level:
        return 12;
      case UnlockType.chapter:
        return 18;
      case UnlockType.achievement:
        return 15;
      case UnlockType.multipleLevels:
        return 24;
      case UnlockType.skillMastery:
        return 16;
      case UnlockType.bonus:
        return 10;
      case UnlockType.milestone:
        return 20;
    }
  }

  @override
  bool shouldRepaint(CelebrationParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}