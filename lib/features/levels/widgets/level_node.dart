import 'package:flutter/material.dart';
import 'package:sp/core/services/sound_manager_service.dart';
import 'difficulty_indicator.dart';

/// Enum for level node states
enum LevelNodeState {
  locked,      // Gray/dimmed, lock icon, not accessible
  unlocked,    // Colored, pulsing glow, not attempted
  current,     // Highlighted, animated indicator, ready to play
  completed,   // Full color, stars displayed, checkmark badge
}

/// Data class for level node information
class LevelNodeData {
  final int level;
  final LevelNodeState state;
  final int stars;
  final int bestScore;
  final double accuracy;
  final Color difficultyColor;
  final int difficulty; // Add difficulty level (1-10)

  LevelNodeData({
    required this.level,
    required this.state,
    this.stars = 0,
    this.bestScore = 0,
    this.accuracy = 0.0,
    required this.difficultyColor,
    required this.difficulty,
  });
}

/// Interactive level node widget with 4 distinct states
class LevelNode extends StatefulWidget {
  final LevelNodeData data;
  final Offset position;
  final VoidCallback? onTap;
  final bool playUnlockAnimation;
  final bool isRecommended;

  const LevelNode({
    super.key,
    required this.data,
    required this.position,
    this.onTap,
    this.playUnlockAnimation = false,
    this.isRecommended = false,
  });

  @override
  State<LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<LevelNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  bool _isShaking = false;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // Start animations based on state
    if (widget.data.state == LevelNodeState.unlocked ||
        widget.data.state == LevelNodeState.current) {
      _animationController.repeat(reverse: true);
    }

    // Play unlock animation if requested
    if (widget.playUnlockAnimation) {
      _playUnlockAnimation();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _playUnlockAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _animationController.forward();
      SoundManagerService.instance.playLevelComplete();
    }
  }

  void _playShakeAnimation() {
    setState(() => _isShaking = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _isShaking = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        if (widget.data.state == LevelNodeState.locked) {
          _playShakeAnimation();
          SoundManagerService.instance.playIncorrectAnswer();
          _showLockedTooltip(context);
        } else if (widget.onTap != null) {
          SoundManagerService.instance.playButtonClick();
          widget.onTap!();
        }
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _getScale(),
            child: Transform.translate(
              offset: _isShaking ? Offset(_getShakeOffset(), 0) : Offset.zero,
              child: _buildNodeContent(theme),
            ),
          );
        },
      ),
    );
  }

  double _getScale() {
    switch (widget.data.state) {
      case LevelNodeState.locked:
        return 1.0;
      case LevelNodeState.unlocked:
        return _pulseAnimation.value;
      case LevelNodeState.current:
        return 1.1 * _pulseAnimation.value;
      case LevelNodeState.completed:
        return widget.playUnlockAnimation ? _scaleAnimation.value : 1.0;
    }
  }

  double _getShakeOffset() {
    final time = DateTime.now().millisecondsSinceEpoch;
    return (time % 100 < 50) ? -5.0 : 5.0;
  }

  Widget _buildNodeContent(ThemeData theme) {
    final size = widget.data.state == LevelNodeState.current ? 90.0 : 80.0;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getBackgroundColor(),
        boxShadow: _getBoxShadow(),
        border: _getBorder(),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Recommended level glow effect
          if (widget.isRecommended)
            Container(
              width: size + 10,
              height: size + 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.amber.withOpacity(0.8),
                  width: 3,
                ),
              ),
            ),
          
          // Level number or lock icon
          _buildCenterContent(theme),
          
          // Difficulty badge for unlocked levels
          if (widget.data.state != LevelNodeState.locked)
            Positioned(
              top: -5,
              left: -5,
              child: DifficultyBadge(
                difficulty: widget.data.difficulty,
                size: 20,
              ),
            ),
          
          // Stars for completed levels
          if (widget.data.state == LevelNodeState.completed && widget.data.stars > 0)
            Positioned(
              bottom: 5,
              child: _buildStars(),
            ),
          
          // Checkmark badge for completed levels
          if (widget.data.state == LevelNodeState.completed)
            Positioned(
              top: 0,
              right: 0,
              child: _buildCheckmarkBadge(),
            ),
          
          // "PLAY" badge for current level
          if (widget.data.state == LevelNodeState.current)
            Positioned(
              top: 0,
              child: _buildPlayBadge(),
            ),
          
          // Recommended badge
          if (widget.isRecommended && widget.data.state != LevelNodeState.completed)
            Positioned(
              bottom: -5,
              child: _buildRecommendedBadge(),
            ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (widget.data.state) {
      case LevelNodeState.locked:
        return Colors.grey.withOpacity(0.3);
      case LevelNodeState.unlocked:
      case LevelNodeState.current:
      case LevelNodeState.completed:
        return widget.data.difficultyColor;
    }
  }

  List<BoxShadow> _getBoxShadow() {
    switch (widget.data.state) {
      case LevelNodeState.locked:
        return [];
      case LevelNodeState.unlocked:
        return [
          BoxShadow(
            color: widget.data.difficultyColor.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ];
      case LevelNodeState.current:
        return [
          BoxShadow(
            color: widget.data.difficultyColor.withOpacity(0.6),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ];
      case LevelNodeState.completed:
        return [
          BoxShadow(
            color: widget.data.difficultyColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ];
    }
  }

  Border? _getBorder() {
    if (widget.data.state == LevelNodeState.current) {
      return Border.all(
        color: Colors.white,
        width: 3,
      );
    }
    return null;
  }

  Widget _buildCenterContent(ThemeData theme) {
    if (widget.data.state == LevelNodeState.locked) {
      return Icon(
        Icons.lock,
        color: Colors.grey[600],
        size: 32,
      );
    }
    
    return Text(
      '${widget.data.level}',
      style: theme.textTheme.headlineMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildStars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        widget.data.stars,
        (index) => Icon(
          Icons.star,
          color: Colors.amber,
          size: 16,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckmarkBadge() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(
        Icons.check,
        color: Colors.white,
        size: 14,
      ),
    );
  }

  Widget _buildPlayBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Text(
        'PLAY',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRecommendedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: const Text(
        'REC',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showLockedTooltip(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Complete Level ${widget.data.level - 1} to unlock this level'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

