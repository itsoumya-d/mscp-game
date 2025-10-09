import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Quick Actions Menu - Task B12
/// Expandable FAB with quick actions (practice, review, daily challenge, ask AI)
class QuickActionsMenu extends StatefulWidget {
  final VoidCallback? onStartPractice;
  final VoidCallback? onReview;
  final VoidCallback? onDailyChallenge;
  final VoidCallback? onAskAI;

  const QuickActionsMenu({
    Key? key,
    this.onStartPractice,
    this.onReview,
    this.onDailyChallenge,
    this.onAskAI,
  }) : super(key: key);

  @override
  State<QuickActionsMenu> createState() => _QuickActionsMenuState();
}

class _QuickActionsMenuState extends State<QuickActionsMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  bool _isExpanded = false;

  final List<QuickAction> _actions = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize actions
    if (widget.onStartPractice != null) {
      _actions.add(QuickAction(
        icon: Icons.play_circle_filled,
        label: 'Practice',
        color: Colors.blue,
        onTap: widget.onStartPractice!,
      ));
    }
    if (widget.onReview != null) {
      _actions.add(QuickAction(
        icon: Icons.refresh,
        label: 'Review',
        color: Colors.green,
        onTap: widget.onReview!,
      ));
    }
    if (widget.onDailyChallenge != null) {
      _actions.add(QuickAction(
        icon: Icons.emoji_events,
        label: 'Daily Challenge',
        color: Colors.amber,
        onTap: widget.onDailyChallenge!,
      ));
    }
    if (widget.onAskAI != null) {
      _actions.add(QuickAction(
        icon: Icons.psychology,
        label: 'Ask AI',
        color: Colors.purple,
        onTap: widget.onAskAI!,
      ));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 0.75,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop
        if (_isExpanded)
          GestureDetector(
            onTap: _toggle,
            child: AnimatedOpacity(
              opacity: _isExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),

        // Action buttons
        ..._buildActionButtons(),

        // Main FAB
        Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value * 2 * math.pi,
                child: FloatingActionButton(
                  onPressed: _toggle,
                  child: Icon(_isExpanded ? Icons.close : Icons.add),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons() {
    return List.generate(_actions.length, (index) {
      final action = _actions[index];
      final angle = (math.pi / 2) / (_actions.length + 1) * (index + 1);

      return AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          final distance = _expandAnimation.value * 80.0 * (index + 1);
          final x = math.cos(angle) * distance;
          final y = math.sin(angle) * distance;

          return Positioned(
            right: 16 + x,
            bottom: 16 + y,
            child: Transform.scale(
              scale: _expandAnimation.value,
              child: Opacity(
                opacity: _expandAnimation.value,
                child: _buildActionButton(action),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildActionButton(QuickAction action) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            action.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: action.label,
          onPressed: () {
            _toggle();
            action.onTap();
          },
          backgroundColor: action.color,
          child: Icon(action.icon),
        ),
      ],
    );
  }
}

/// Speed dial FAB (alternative implementation)
class SpeedDialFAB extends StatefulWidget {
  final List<SpeedDialAction> actions;
  final IconData icon;
  final IconData? openIcon;
  final Color? backgroundColor;

  const SpeedDialFAB({
    Key? key,
    required this.actions,
    this.icon = Icons.add,
    this.openIcon,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<SpeedDialFAB> createState() => _SpeedDialFABState();
}

class _SpeedDialFABState extends State<SpeedDialFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...List.generate(widget.actions.length, (index) {
          return ScaleTransition(
            scale: CurvedAnimation(
              parent: _controller,
              curve: Interval(
                0.0,
                1.0 - index / widget.actions.length / 2.0,
                curve: Curves.easeOut,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.actions[index].label,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton(
                    heroTag: 'speed_dial_${widget.actions[index].label}',
                    mini: true,
                    onPressed: () {
                      _toggle();
                      widget.actions[index].onTap();
                    },
                    backgroundColor: widget.actions[index].backgroundColor,
                    child: Icon(widget.actions[index].icon),
                  ),
                ],
              ),
            ),
          );
        }).reversed,
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: widget.backgroundColor,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 250),
            child: Icon(_isOpen ? (widget.openIcon ?? Icons.close) : widget.icon),
          ),
        ),
      ],
    );
  }
}

/// Quick action data model
class QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// Speed dial action data model
class SpeedDialAction {
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final VoidCallback onTap;

  SpeedDialAction({
    required this.icon,
    required this.label,
    this.backgroundColor,
    required this.onTap,
  });
}

/// Expandable FAB with custom animation
class ExpandableFAB extends StatefulWidget {
  final List<Widget> children;
  final double distance;
  final IconData icon;

  const ExpandableFAB({
    Key? key,
    required this.children,
    this.distance = 100,
    this.icon = Icons.menu,
  }) : super(key: key);

  @override
  State<ExpandableFAB> createState() => _ExpandableFABState();
}

class _ExpandableFABState extends State<ExpandableFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = 90.0 / (count - 1);
    for (var i = 0, angleInDegrees = 0.0;
        i < count;
        i++, angleInDegrees += step) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _isExpanded,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _isExpanded ? 0.7 : 1.0,
          _isExpanded ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _isExpanded ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            onPressed: _toggle,
            child: Icon(widget.icon),
          ),
        ),
      ),
    );
  }
}

class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * math.pi / 2,
            child: child!,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}

