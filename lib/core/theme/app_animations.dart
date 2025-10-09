import 'package:flutter/material.dart';

/// Unified animation system for the LearnoSphere educational app
/// Provides consistent animation durations, curves, and common animations
class AppAnimations {
  AppAnimations._(); // Private constructor to prevent instantiation

  // Standard Animation Durations
  static const Duration ultraFast = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Game-specific Durations
  static const Duration feedbackDuration = Duration(milliseconds: 1500);
  static const Duration questionTransition = Duration(milliseconds: 400);
  static const Duration answerReveal = Duration(milliseconds: 600);
  static const Duration levelUnlock = Duration(milliseconds: 800);
  static const Duration starAnimationDuration = Duration(milliseconds: 300);

  // Standard Animation Curves
  static const Curve standardCurve = Curves.easeInOut;
  static const Curve fastCurve = Curves.easeOut;
  static const Curve slowCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve slideCurve = Curves.easeOutCubic;
  static const Curve scaleCurve = Curves.easeOutBack;

  // Game-specific Curves
  static const Curve correctAnswerCurve = Curves.bounceOut;
  static const Curve incorrectAnswerCurve = Curves.easeInOut;
  static const Curve levelProgressCurve = Curves.easeInOutQuart;

  // Common Animation Builders

  /// Fade In Animation
  static Animation<double> fadeIn(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: standardCurve),
    );
  }

  /// Fade Out Animation
  static Animation<double> fadeOut(AnimationController controller) {
    return Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: standardCurve),
    );
  }

  /// Slide Up Animation
  static Animation<Offset> slideUp(AnimationController controller) {
    return Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: controller, curve: slideCurve),
    );
  }

  /// Slide Down Animation
  static Animation<Offset> slideDown(AnimationController controller) {
    return Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: controller, curve: slideCurve),
    );
  }

  /// Slide Left Animation
  static Animation<Offset> slideLeft(AnimationController controller) {
    return Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: controller, curve: slideCurve),
    );
  }

  /// Slide Right Animation
  static Animation<Offset> slideRight(AnimationController controller) {
    return Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: controller, curve: slideCurve),
    );
  }

  /// Scale Animation (for buttons and interactions)
  static Animation<double> scaleAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: scaleCurve),
    );
  }

  /// Bounce Scale Animation (for correct answers)
  static Animation<double> bounceScale(AnimationController controller) {
    return Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: bounceCurve),
    );
  }

  /// Shake Animation (for incorrect answers)
  static Animation<double> shakeAnimation(AnimationController controller) {
    return Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.elasticIn),
    );
  }

  /// Rotation Animation
  static Animation<double> rotationAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: standardCurve),
    );
  }

  /// Progress Animation (for progress bars)
  static Animation<double> progressAnimation(
    AnimationController controller,
    double from,
    double to,
  ) {
    return Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: controller, curve: levelProgressCurve),
    );
  }

  /// Color Animation
  static Animation<Color?> colorAnimation(
    AnimationController controller,
    Color from,
    Color to,
  ) {
    return ColorTween(begin: from, end: to).animate(
      CurvedAnimation(parent: controller, curve: standardCurve),
    );
  }

  // Pre-built Animation Widgets

  /// Animated Fade In Widget
  static Widget fadeInWidget({
    required Widget child,
    Duration duration = normal,
    Curve curve = standardCurve,
    double? delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: delay != null 
          ? Duration(milliseconds: duration.inMilliseconds + (delay * 1000).round())
          : duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: delay != null && value < delay ? 0.0 : (value - (delay ?? 0)) / (1 - (delay ?? 0)),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Animated Scale Widget
  static Widget scaleWidget({
    required Widget child,
    Duration duration = normal,
    Curve curve = scaleCurve,
    double? delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: delay != null 
          ? Duration(milliseconds: duration.inMilliseconds + (delay * 1000).round())
          : duration,
      curve: curve,
      builder: (context, value, child) {
        final scale = delay != null && value < delay ? 0.0 : (value - (delay ?? 0)) / (1 - (delay ?? 0));
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Animated Slide Widget
  static Widget slideWidget({
    required Widget child,
    required Offset begin,
    Offset end = Offset.zero,
    Duration duration = normal,
    Curve curve = slideCurve,
    double? delay,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: begin, end: end),
      duration: delay != null 
          ? Duration(milliseconds: duration.inMilliseconds + (delay * 1000).round())
          : duration,
      curve: curve,
      builder: (context, value, child) {
        final offset = delay != null && value == begin ? begin : value;
        return Transform.translate(
          offset: Offset(
            offset.dx * MediaQuery.of(context).size.width,
            offset.dy * MediaQuery.of(context).size.height,
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  // Game-Specific Animations

  /// Answer Button Animation (correct)
  static Widget correctAnswerAnimation({
    required Widget child,
    required bool trigger,
  }) {
    return AnimatedContainer(
      duration: answerReveal,
      curve: correctAnswerCurve,
      transform: trigger 
          ? (Matrix4.identity()..scale(1.1))
          : Matrix4.identity(),
      child: child,
    );
  }

  /// Answer Button Animation (incorrect)
  static Widget incorrectAnswerAnimation({
    required Widget child,
    required bool trigger,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: trigger ? 1.0 : 0.0),
      duration: answerReveal,
      curve: incorrectAnswerCurve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(10 * (0.5 - value).abs() * 2, 0),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Level Unlock Animation
  static Widget levelUnlockAnimation({
    required Widget child,
    required bool trigger,
  }) {
    return AnimatedContainer(
      duration: levelUnlock,
      curve: bounceCurve,
      transform: trigger 
          ? Matrix4.identity()
          : (Matrix4.identity()..scale(0.0)),
      child: child,
    );
  }

  /// Star Rating Animation
  static Widget starAnimation({
    required Widget child,
    required bool filled,
    double? delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: filled ? 1.0 : 0.0),
      duration: Duration(
        milliseconds: starAnimationDuration.inMilliseconds +
                     ((delay ?? 0) * 1000).round(),
      ),
      curve: bounceCurve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Progress Bar Animation
  static Widget progressBarAnimation({
    required double progress,
    required Widget child,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: slow,
      curve: levelProgressCurve,
      builder: (context, value, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Page Transition Animation
  static Widget pageTransition({
    required Widget child,
    required Animation<double> animation,
    SlideDirection direction = SlideDirection.right,
  }) {
    Offset begin;
    switch (direction) {
      case SlideDirection.up:
        begin = const Offset(0, 1);
        break;
      case SlideDirection.down:
        begin = const Offset(0, -1);
        break;
      case SlideDirection.left:
        begin = const Offset(-1, 0);
        break;
      case SlideDirection.right:
      default:
        begin = const Offset(1, 0);
        break;
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: slideCurve,
      )),
      child: child,
    );
  }

  // Helper Methods

  /// Create a staggered animation controller
  static AnimationController createStaggeredController({
    required TickerProvider vsync,
    required int itemCount,
    Duration duration = normal,
  }) {
    return AnimationController(
      duration: Duration(
        milliseconds: duration.inMilliseconds + (itemCount * 100),
      ),
      vsync: vsync,
    );
  }

  /// Get staggered animation for item at index
  static Animation<double> getStaggeredAnimation({
    required AnimationController controller,
    required int index,
    required int totalItems,
  }) {
    final start = index / totalItems;
    final end = (index + 1) / totalItems;
    
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: standardCurve),
      ),
    );
  }
}

/// Slide Direction Enum
enum SlideDirection {
  up,
  down,
  left,
  right,
}
