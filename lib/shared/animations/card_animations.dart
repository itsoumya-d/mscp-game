import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Card Animations - Task C5
/// Flip, expand, stack animations for cards with swipe-to-dismiss and drag-to-reorder

/// Flip card animation
class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final Duration duration;
  final bool flipOnTap;

  const FlipCard({
    Key? key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 600),
    this.flipOnTap = true,
  }) : super(key: key);

  @override
  State<FlipCard> createState() => FlipCardState();
}

class FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void flip() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.flipOnTap ? flip : null,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: angle < math.pi / 2 ? widget.front : _buildBack(),
          );
        },
      ),
    );
  }

  Widget _buildBack() {
    return Transform(
      transform: Matrix4.identity()..rotateY(math.pi),
      alignment: Alignment.center,
      child: widget.back,
    );
  }
}

/// Expandable card
class ExpandableCard extends StatefulWidget {
  final Widget header;
  final Widget expandedContent;
  final Duration duration;
  final bool initiallyExpanded;

  const ExpandableCard({
    Key? key,
    required this.header,
    required this.expandedContent,
    this.duration = const Duration(milliseconds: 300),
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: _isExpanded ? 1.0 : 0.0,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggle() {
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
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: toggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: widget.header),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: widget.duration,
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _animation,
            child: widget.expandedContent,
          ),
        ],
      ),
    );
  }
}

/// Swipe to dismiss card
class SwipeToDismissCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onDismissed;
  final String dismissKey;
  final Color? backgroundColor;
  final IconData? dismissIcon;

  const SwipeToDismissCard({
    Key? key,
    required this.child,
    required this.onDismissed,
    required this.dismissKey,
    this.backgroundColor,
    this.dismissIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(dismissKey),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: backgroundColor ?? Colors.red,
        child: Icon(
          dismissIcon ?? Icons.delete,
          color: Colors.white,
          size: 32,
        ),
      ),
      child: child,
    );
  }
}

/// Draggable reorderable card
class DraggableCard extends StatelessWidget {
  final Widget child;
  final int index;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

  const DraggableCard({
    Key? key,
    required this.child,
    required this.index,
    this.onDragStarted,
    this.onDragEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<int>(
      data: index,
      feedback: Material(
        elevation: 8,
        child: Opacity(
          opacity: 0.8,
          child: child,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: child,
      ),
      onDragStarted: onDragStarted,
      onDragEnd: (details) => onDragEnd?.call(),
      child: child,
    );
  }
}

/// Stacked cards animation
class StackedCards extends StatefulWidget {
  final List<Widget> cards;
  final double cardOffset;
  final double scaleOffset;

  const StackedCards({
    Key? key,
    required this.cards,
    this.cardOffset = 20,
    this.scaleOffset = 0.05,
  }) : super(key: key);

  @override
  State<StackedCards> createState() => _StackedCardsState();
}

class _StackedCardsState extends State<StackedCards> {
  int _currentIndex = 0;

  void _nextCard() {
    if (_currentIndex < widget.cards.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          _nextCard();
        } else if (details.primaryVelocity! > 0) {
          _previousCard();
        }
      },
      child: Stack(
        children: List.generate(
          widget.cards.length,
          (index) {
            final offset = (index - _currentIndex) * widget.cardOffset;
            final scale = 1 - (index - _currentIndex).abs() * widget.scaleOffset;

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: offset.clamp(0, double.infinity),
              left: 0,
              right: 0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: scale.clamp(0.8, 1.0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: index >= _currentIndex ? 1.0 : 0.0,
                  child: widget.cards[index],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Tap to expand card
class TapToExpandCard extends StatefulWidget {
  final Widget collapsedChild;
  final Widget expandedChild;
  final Duration duration;

  const TapToExpandCard({
    Key? key,
    required this.collapsedChild,
    required this.expandedChild,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<TapToExpandCard> createState() => _TapToExpandCardState();
}

class _TapToExpandCardState extends State<TapToExpandCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeInOut,
        child: _isExpanded ? widget.expandedChild : widget.collapsedChild,
      ),
    );
  }
}

/// Hero card transition helper
class HeroCard extends StatelessWidget {
  final String tag;
  final Widget child;
  final VoidCallback? onTap;

  const HeroCard({
    Key? key,
    required this.tag,
    required this.child,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

/// Animated card list item
class AnimatedCardListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const AnimatedCardListItem({
    Key? key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  State<AnimatedCardListItem> createState() => _AnimatedCardListItemState();
}

class _AnimatedCardListItemState extends State<AnimatedCardListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

