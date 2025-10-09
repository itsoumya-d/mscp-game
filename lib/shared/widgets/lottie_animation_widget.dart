import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

enum AnimationType {
  loading,
  success,
  celebration,
  levelUp,
  achievement,
  error,
  thinking,
  sparkles,
}

class LottieAnimationWidget extends StatefulWidget {
  final AnimationType type;
  final double? width;
  final double? height;
  final bool repeat;
  final VoidCallback? onComplete;
  final Duration? duration;
  final bool autoPlay;

  const LottieAnimationWidget({
    super.key,
    required this.type,
    this.width,
    this.height,
    this.repeat = true,
    this.onComplete,
    this.duration,
    this.autoPlay = true,
  });

  @override
  State<LottieAnimationWidget> createState() => _LottieAnimationWidgetState();
}

class _LottieAnimationWidgetState extends State<LottieAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? const Duration(seconds: 2),
      vsync: this,
    );

    if (widget.autoPlay) {
      _playAnimation();
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
        if (widget.repeat) {
          _controller.repeat();
        }
      }
    });
  }

  void _playAnimation() {
    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getAnimationAsset() {
    switch (widget.type) {
      case AnimationType.loading:
        return 'assets/animations/loading.json';
      case AnimationType.success:
        return 'assets/animations/success.json';
      case AnimationType.celebration:
        return 'assets/animations/celebration.json';
      case AnimationType.levelUp:
        return 'assets/animations/level_up.json';
      case AnimationType.achievement:
        return 'assets/animations/achievement.json';
      case AnimationType.error:
        return 'assets/animations/error.json';
      case AnimationType.thinking:
        return 'assets/animations/thinking.json';
      case AnimationType.sparkles:
        return 'assets/animations/sparkles.json';
    }
  }

  Widget _buildFallbackAnimation() {
    // Fallback animations using built-in Flutter animations
    switch (widget.type) {
      case AnimationType.loading:
        return _buildLoadingFallback();
      case AnimationType.success:
        return _buildSuccessFallback();
      case AnimationType.celebration:
        return _buildCelebrationFallback();
      case AnimationType.levelUp:
        return _buildLevelUpFallback();
      case AnimationType.achievement:
        return _buildAchievementFallback();
      case AnimationType.error:
        return _buildErrorFallback();
      case AnimationType.thinking:
        return _buildThinkingFallback();
      case AnimationType.sparkles:
        return _buildSparklesFallback();
    }
  }

  Widget _buildLoadingFallback() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: const CircularProgressIndicator(),
        );
      },
    );
  }

  Widget _buildSuccessFallback() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.2),
          child: Icon(
            Icons.check_circle,
            color: Colors.green,
            size: widget.width ?? 50,
          ),
        );
      },
    );
  }

  Widget _buildCelebrationFallback() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + ((_controller.value * 2) % 1) * 0.3,
          child: const Icon(
            Icons.celebration,
            color: Colors.orange,
            size: 50,
          ),
        );
      },
    );
  }

  Widget _buildLevelUpFallback() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, -10 * _controller.value),
              child: const Icon(
                Icons.trending_up,
                color: Colors.blue,
                size: 40,
              ),
            ),
            Text(
              'LEVEL UP!',
              style: TextStyle(
                fontSize: 16 + (4 * _controller.value),
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAchievementFallback() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 0.1,
          child: const Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 50,
          ),
        );
      },
    );
  }

  Widget _buildErrorFallback() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.1),
          child: const Icon(
            Icons.error,
            color: Colors.red,
            size: 50,
          ),
        );
      },
    );
  }

  Widget _buildThinkingFallback() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final animValue = (_controller.value - delay).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, -5 * animValue),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSparklesFallback() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: List.generate(5, (index) {
            final angle = (index * 72) * (3.14159 / 180);
            final radius = 20 + (10 * _controller.value);
            return Transform.translate(
              offset: Offset(
                radius * cos(angle),
                radius * sin(angle),
              ),
              child: Transform.scale(
                scale: _controller.value,
                child: const Icon(
                  Icons.star,
                  color: Colors.yellow,
                  size: 12,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: FutureBuilder<bool>(
        future: _checkAssetExists(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            // Use Lottie animation if asset exists
            return Lottie.asset(
              _getAnimationAsset(),
              controller: _controller,
              width: widget.width,
              height: widget.height,
              repeat: widget.repeat,
              onLoaded: (composition) {
                _controller.duration = composition.duration;
                if (widget.autoPlay) {
                  _playAnimation();
                }
              },
            );
          } else {
            // Use fallback animation
            return Center(child: _buildFallbackAnimation());
          }
        },
      ),
    );
  }

  Future<bool> _checkAssetExists() async {
    try {
      await DefaultAssetBundle.of(context).load(_getAnimationAsset());
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Helper function for mathematical operations
double cos(double radians) => math.cos(radians);
double sin(double radians) => math.sin(radians);