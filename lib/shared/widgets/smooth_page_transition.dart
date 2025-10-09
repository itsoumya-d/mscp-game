import 'package:flutter/material.dart';

enum TransitionType {
  slide,
  fade,
  scale,
  rotation,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  fadeScale,
  hero,
}

class SmoothPageTransition<T> extends PageRouteBuilder<T> {
  final Widget child;
  final TransitionType type;
  final Duration duration;
  final Curve curve;
  final String? heroTag;

  SmoothPageTransition({
    required this.child,
    this.type = TransitionType.slide,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.heroTag,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(
              context,
              animation,
              secondaryAnimation,
              child,
              type,
              curve,
            );
          },
        );

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    TransitionType type,
    Curve curve,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
    );

    switch (type) {
      case TransitionType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.fade:
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );

      case TransitionType.scale:
        return ScaleTransition(
          scale: curvedAnimation,
          child: child,
        );

      case TransitionType.rotation:
        return RotationTransition(
          turns: curvedAnimation,
          child: child,
        );

      case TransitionType.fadeScale:
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        );

      case TransitionType.hero:
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );
    }
  }
}

class SmoothNavigator {
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget page, {
    TransitionType type = TransitionType.slide,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    String? heroTag,
  }) {
    return Navigator.of(context).push<T>(
      SmoothPageTransition(
        child: page,
        type: type,
        duration: duration,
        curve: curve,
        heroTag: heroTag,
      ),
    );
  }

  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page, {
    TransitionType type = TransitionType.slide,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    TO? result,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      SmoothPageTransition(
        child: page,
        type: type,
        duration: duration,
        curve: curve,
      ),
      result: result,
    );
  }

  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    Widget page,
    RoutePredicate predicate, {
    TransitionType type = TransitionType.slide,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      SmoothPageTransition(
        child: page,
        type: type,
        duration: duration,
        curve: curve,
      ),
      predicate,
    );
  }
}

class HeroTransitionWidget extends StatelessWidget {
  final String tag;
  final Widget child;
  final VoidCallback? onTap;

  const HeroTransitionWidget({
    super.key,
    required this.tag,
    required this.child,
    this.onTap,
  });

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

class AnimatedPageWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const AnimatedPageWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  State<AnimatedPageWrapper> createState() => _AnimatedPageWrapperState();
}

class _AnimatedPageWrapperState extends State<AnimatedPageWrapper>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _controller.forward();
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
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

class StaggeredAnimationWrapper extends StatefulWidget {
  final List<Widget> children;
  final Duration duration;
  final Duration staggerDelay;
  final Curve curve;

  const StaggeredAnimationWrapper({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.curve = Curves.easeInOut,
  });

  @override
  State<StaggeredAnimationWrapper> createState() =>
      _StaggeredAnimationWrapperState();
}

class _StaggeredAnimationWrapperState extends State<StaggeredAnimationWrapper>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );

    _animations = _controllers
        .map((controller) => Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: widget.curve,
            )))
        .toList();

    _startStaggeredAnimation();
  }

  void _startStaggeredAnimation() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(widget.staggerDelay);
      if (mounted) {
        _controllers[i].forward();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        widget.children.length,
        (index) => AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return FadeTransition(
              opacity: _animations[index],
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.3),
                  end: Offset.zero,
                ).animate(_animations[index]),
                child: widget.children[index],
              ),
            );
          },
        ),
      ),
    );
  }
}