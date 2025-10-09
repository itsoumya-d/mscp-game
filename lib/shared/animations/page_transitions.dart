import 'package:flutter/material.dart';

/// Page Transition Animations - Task C2
/// Custom transitions for navigation with shared elements, fade, slide, and scale

/// Fade transition
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  FadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

/// Slide transition from right
class SlideRightPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SlideRightPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

/// Slide transition from bottom
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SlideUpPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

/// Scale transition
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  ScalePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOut;

            var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            return ScaleTransition(
              scale: animation.drive(scaleTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// Rotation transition
class RotationPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  RotationPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOut;

            var rotationTween = Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            return RotationTransition(
              turns: animation.drive(rotationTween),
              child: ScaleTransition(
                scale: animation.drive(scaleTween),
                child: child,
              ),
            );
          },
        );
}

/// Fade + Slide transition
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Offset slideOffset;

  FadeSlidePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.slideOffset = const Offset(0.0, 0.1),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOut;

            var slideTween = Tween(begin: slideOffset, end: Offset.zero).chain(
              CurveTween(curve: curve),
            );

            var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// Shared element transition helper
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final SharedAxisTransitionType transitionType;

  SharedAxisPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.transitionType = SharedAxisTransitionType.horizontal,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: transitionType,
              child: child,
            );
          },
        );
}

enum SharedAxisTransitionType {
  horizontal,
  vertical,
  scaled,
}

class _SharedAxisTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final SharedAxisTransitionType transitionType;
  final Widget child;

  const _SharedAxisTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.transitionType,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Outgoing page
        SlideTransition(
          position: _getOutgoingSlide(),
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
              ),
            ),
            child: Container(),
          ),
        ),
        // Incoming page
        SlideTransition(
          position: _getIncomingSlide(),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
              ),
            ),
            child: child,
          ),
        ),
      ],
    );
  }

  Animation<Offset> _getOutgoingSlide() {
    Offset begin;
    switch (transitionType) {
      case SharedAxisTransitionType.horizontal:
        begin = const Offset(-0.3, 0.0);
        break;
      case SharedAxisTransitionType.vertical:
        begin = const Offset(0.0, -0.3);
        break;
      case SharedAxisTransitionType.scaled:
        begin = Offset.zero;
        break;
    }

    return Tween<Offset>(
      begin: Offset.zero,
      end: begin,
    ).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeIn,
      ),
    );
  }

  Animation<Offset> _getIncomingSlide() {
    Offset begin;
    switch (transitionType) {
      case SharedAxisTransitionType.horizontal:
        begin = const Offset(0.3, 0.0);
        break;
      case SharedAxisTransitionType.vertical:
        begin = const Offset(0.0, 0.3);
        break;
      case SharedAxisTransitionType.scaled:
        begin = Offset.zero;
        break;
    }

    return Tween<Offset>(
      begin: begin,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
    );
  }
}

/// Helper extension for easy navigation
extension PageTransitionExtension on BuildContext {
  Future<T?> pushWithFade<T>(Widget page) {
    return Navigator.of(this).push<T>(FadePageRoute(page: page));
  }

  Future<T?> pushWithSlideRight<T>(Widget page) {
    return Navigator.of(this).push<T>(SlideRightPageRoute(page: page));
  }

  Future<T?> pushWithSlideUp<T>(Widget page) {
    return Navigator.of(this).push<T>(SlideUpPageRoute(page: page));
  }

  Future<T?> pushWithScale<T>(Widget page) {
    return Navigator.of(this).push<T>(ScalePageRoute(page: page));
  }

  Future<T?> pushWithFadeSlide<T>(Widget page) {
    return Navigator.of(this).push<T>(FadeSlidePageRoute(page: page));
  }

  Future<T?> pushWithSharedAxis<T>(
    Widget page, {
    SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
  }) {
    return Navigator.of(this).push<T>(
      SharedAxisPageRoute(page: page, transitionType: type),
    );
  }
}

