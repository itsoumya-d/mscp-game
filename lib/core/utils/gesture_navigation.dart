import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gesture Navigation - Task B15
/// Add swipe gestures for navigation
/// 
/// Features:
/// - Swipe back
/// - Swipe between questions
/// - Pull to refresh
/// - Gesture indicators
/// - Haptic feedback

class GestureNavigation {
  /// Enable swipe back gesture
  static Widget swipeBack({
    required Widget child,
    required VoidCallback onSwipeBack,
    bool enabled = true,
  }) {
    if (!enabled) return child;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Swipe from left to right
        if (details.primaryVelocity! > 500) {
          HapticFeedback.mediumImpact();
          onSwipeBack();
        }
      },
      child: child,
    );
  }

  /// Enable swipe between items
  static Widget swipeBetween({
    required Widget child,
    VoidCallback? onSwipeLeft,
    VoidCallback? onSwipeRight,
    bool showIndicators = true,
  }) {
    return SwipeBetweenWidget(
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
      showIndicators: showIndicators,
      child: child,
    );
  }

  /// Enable pull to refresh
  static Widget pullToRefresh({
    required Widget child,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  }
}

/// Swipe between widget
class SwipeBetweenWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final bool showIndicators;

  const SwipeBetweenWidget({
    Key? key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.showIndicators = true,
  }) : super(key: key);

  @override
  State<SwipeBetweenWidget> createState() => _SwipeBetweenWidgetState();
}

class _SwipeBetweenWidgetState extends State<SwipeBetweenWidget>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (_) {
        setState(() {
          _isDragging = true;
        });
      },
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dx;
          _dragOffset = _dragOffset.clamp(-100.0, 100.0);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragOffset < -50 && widget.onSwipeLeft != null) {
          HapticFeedback.mediumImpact();
          widget.onSwipeLeft!();
        } else if (_dragOffset > 50 && widget.onSwipeRight != null) {
          HapticFeedback.mediumImpact();
          widget.onSwipeRight!();
        }

        setState(() {
          _dragOffset = 0;
          _isDragging = false;
        });
      },
      child: Stack(
        children: [
          // Main content
          Transform.translate(
            offset: Offset(_dragOffset * 0.3, 0),
            child: widget.child,
          ),

          // Left indicator
          if (widget.showIndicators && _isDragging && _dragOffset > 20)
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

          // Right indicator
          if (widget.showIndicators && _isDragging && _dragOffset < -20)
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Swipeable page route
class SwipeablePageRoute<T> extends MaterialPageRoute<T> {
  SwipeablePageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Slide transition
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: child,
    );
  }
}

/// Dismissible card with swipe gestures
class SwipeDismissibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onDismissLeft;
  final VoidCallback? onDismissRight;
  final Color leftColor;
  final Color rightColor;
  final IconData leftIcon;
  final IconData rightIcon;

  const SwipeDismissibleCard({
    Key? key,
    required this.child,
    this.onDismissLeft,
    this.onDismissRight,
    this.leftColor = Colors.red,
    this.rightColor = Colors.green,
    this.leftIcon = Icons.delete,
    this.rightIcon = Icons.check,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      background: Container(
        color: leftColor,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(leftIcon, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        color: rightColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(rightIcon, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();

        if (direction == DismissDirection.startToEnd && onDismissLeft != null) {
          onDismissLeft!();
          return true;
        } else if (direction == DismissDirection.endToStart &&
            onDismissRight != null) {
          onDismissRight!();
          return true;
        }

        return false;
      },
      child: child,
    );
  }
}

/// Swipe detector
class SwipeDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final double sensitivity;

  const SwipeDetector({
    Key? key,
    required this.child,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.sensitivity = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < -sensitivity && onSwipeUp != null) {
          HapticFeedback.lightImpact();
          onSwipeUp!();
        } else if (details.primaryVelocity! > sensitivity &&
            onSwipeDown != null) {
          HapticFeedback.lightImpact();
          onSwipeDown!();
        }
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < -sensitivity && onSwipeLeft != null) {
          HapticFeedback.lightImpact();
          onSwipeLeft!();
        } else if (details.primaryVelocity! > sensitivity &&
            onSwipeRight != null) {
          HapticFeedback.lightImpact();
          onSwipeRight!();
        }
      },
      child: child,
    );
  }
}

/// Long press gesture
class LongPressGesture extends StatelessWidget {
  final Widget child;
  final VoidCallback onLongPress;
  final Duration duration;

  const LongPressGesture({
    Key? key,
    required this.child,
    required this.onLongPress,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.heavyImpact();
        onLongPress();
      },
      child: child,
    );
  }
}

/// Usage Examples:
/// 
/// ```dart
/// // Swipe back
/// GestureNavigation.swipeBack(
///   child: MyScreen(),
///   onSwipeBack: () => Navigator.pop(context),
/// )
/// 
/// // Swipe between questions
/// GestureNavigation.swipeBetween(
///   child: QuestionCard(),
///   onSwipeLeft: () => nextQuestion(),
///   onSwipeRight: () => previousQuestion(),
/// )
/// 
/// // Pull to refresh
/// GestureNavigation.pullToRefresh(
///   child: ListView(...),
///   onRefresh: () async {
///     await refreshData();
///   },
/// )
/// 
/// // Swipeable page route
/// Navigator.push(
///   context,
///   SwipeablePageRoute(
///     builder: (context) => NextScreen(),
///   ),
/// )
/// 
/// // Dismissible card
/// SwipeDismissibleCard(
///   child: ListTile(...),
///   onDismissLeft: () => deleteItem(),
///   onDismissRight: () => completeItem(),
/// )
/// 
/// // Swipe detector
/// SwipeDetector(
///   child: MyWidget(),
///   onSwipeUp: () => print('Swiped up'),
///   onSwipeDown: () => print('Swiped down'),
///   onSwipeLeft: () => print('Swiped left'),
///   onSwipeRight: () => print('Swiped right'),
/// )
/// ```

