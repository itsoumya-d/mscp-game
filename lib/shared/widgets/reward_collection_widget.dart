import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:sp/core/services/sound_manager_service.dart';
import 'package:sp/theme.dart';
import 'dart:math' as math;

/// Reward collection widget with Flame-based animations
class RewardCollectionWidget extends StatefulWidget {
  final int coins;
  final int gems;
  final int xp;
  final VoidCallback? onAnimationComplete;

  const RewardCollectionWidget({
    super.key,
    this.coins = 0,
    this.gems = 0,
    this.xp = 0,
    this.onAnimationComplete,
  });

  @override
  State<RewardCollectionWidget> createState() => _RewardCollectionWidgetState();
}

class _RewardCollectionWidgetState extends State<RewardCollectionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onAnimationComplete?.call();
      });
    });

    // Play collection sounds
    if (widget.coins > 0) {
      SoundManagerService.instance.playCoinCollect();
    }
    if (widget.gems > 0) {
      Future.delayed(const Duration(milliseconds: 200), () {
        SoundManagerService.instance.playCoinCollect();
      });
    }
    if (widget.xp > 0) {
      Future.delayed(const Duration(milliseconds: 400), () {
        SoundManagerService.instance.playAchievementUnlock();
      });
    }
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
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.coins > 0)
                  _RewardItem(
                    icon: Icons.monetization_on,
                    color: LightModeColors.lightParticleGold,
                    value: '+${widget.coins}',
                    label: 'Coins',
                  ),
                if (widget.gems > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: InteractiveDesign.smallSpacing),
                    child: _RewardItem(
                      icon: Icons.diamond,
                      color: LightModeColors.lightInfo,
                      value: '+${widget.gems}',
                      label: 'Gems',
                    ),
                  ),
                if (widget.xp > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: InteractiveDesign.smallSpacing),
                    child: _RewardItem(
                      icon: Icons.star,
                      color: LightModeColors.lightWarning,
                      value: '+${widget.xp}',
                      label: 'XP',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RewardItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _RewardItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InteractiveDesign.mediumSpacing,
        vertical: InteractiveDesign.smallSpacing,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(InteractiveDesign.mediumRadius),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: InteractiveDesign.coinSize),
          const SizedBox(width: InteractiveDesign.smallSpacing),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: InteractiveDesign.tinySpacing),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Flame-based coin collection game
class CoinCollectionGame extends FlameGame {
  final Function(int) onCoinCollected;
  int _coinsCollected = 0;

  CoinCollectionGame({required this.onCoinCollected});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Spawn coins
    for (int i = 0; i < 10; i++) {
      final coin = CoinComponent(
        position: Vector2(
          math.Random().nextDouble() * size.x,
          math.Random().nextDouble() * size.y,
        ),
        onCollected: () {
          _coinsCollected++;
          onCoinCollected(_coinsCollected);
          SoundManagerService.instance.playCoinCollect();
        },
      );
      add(coin);
    }
  }
}

/// Coin component for collection
class CoinComponent extends PositionComponent with TapCallbacks {
  final VoidCallback onCollected;
  bool _collected = false;

  CoinComponent({
    required Vector2 position,
    required this.onCollected,
  }) : super(
          position: position,
          size: Vector2.all(InteractiveDesign.coinSize),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Add rotation animation
    add(
      RotateEffect.by(
        2 * math.pi,
        EffectController(
          duration: 2.0,
          infinite: true,
        ),
      ),
    );
    
    // Add floating animation
    add(
      MoveEffect.by(
        Vector2(0, -10),
        EffectController(
          duration: 1.0,
          infinite: true,
          alternate: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    if (!_collected) {
      final paint = Paint()
        ..color = LightModeColors.lightParticleGold
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x / 2,
        paint,
      );
      
      // Draw coin icon
      final iconPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x / 4,
        iconPaint,
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!_collected) {
      _collected = true;
      onCollected();
      
      // Add collection animation
      add(
        ScaleEffect.to(
          Vector2.zero(),
          EffectController(duration: 0.3),
          onComplete: () => removeFromParent(),
        ),
      );
    }
  }
}

/// Animated page transition widget
class AnimatedPageTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const AnimatedPageTransition({
    super.key,
    required this.child,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: child,
      ),
    );
  }
}

