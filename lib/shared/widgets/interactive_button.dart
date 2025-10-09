import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sp/core/services/sound_manager_service.dart';
import 'package:sp/theme.dart';

/// Interactive button with sound effects and animations
class InteractiveButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final bool enableSoundEffects;
  final bool enableHapticFeedback;
  final InteractiveButtonStyle style;
  final bool isLoading;
  final Widget? loadingWidget;

  const InteractiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.enableSoundEffects = true,
    this.enableHapticFeedback = true,
    this.style = InteractiveButtonStyle.primary,
    this.isLoading = false,
    this.loadingWidget,
  });

  @override
  State<InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<InteractiveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: InteractiveDesign.fastAnimation,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
      _handlePress();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _handlePress() {
    if (widget.onPressed != null && !widget.isLoading) {
      if (widget.enableSoundEffects) {
        SoundManagerService.instance.playButtonClick();
      }
      
      if (widget.enableHapticFeedback) {
        HapticFeedback.lightImpact();
      }
      
      widget.onPressed!();
    }
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (widget.backgroundColor != null) {
      return widget.backgroundColor!;
    }
    
    switch (widget.style) {
      case InteractiveButtonStyle.primary:
        return theme.colorScheme.primary;
      case InteractiveButtonStyle.secondary:
        return theme.colorScheme.secondary;
      case InteractiveButtonStyle.success:
        return LightModeColors.lightSuccess;
      case InteractiveButtonStyle.warning:
        return LightModeColors.lightWarning;
      case InteractiveButtonStyle.error:
        return theme.colorScheme.error;
      case InteractiveButtonStyle.outline:
        return Colors.transparent;
      case InteractiveButtonStyle.ghost:
        return Colors.transparent;
    }
  }

  Color _getTextColor(ThemeData theme) {
    if (widget.textColor != null) {
      return widget.textColor!;
    }
    
    switch (widget.style) {
      case InteractiveButtonStyle.primary:
        return theme.colorScheme.onPrimary;
      case InteractiveButtonStyle.secondary:
        return theme.colorScheme.onSecondary;
      case InteractiveButtonStyle.success:
        return Colors.white;
      case InteractiveButtonStyle.warning:
        return Colors.white;
      case InteractiveButtonStyle.error:
        return theme.colorScheme.onError;
      case InteractiveButtonStyle.outline:
        return theme.colorScheme.primary;
      case InteractiveButtonStyle.ghost:
        return theme.colorScheme.primary;
    }
  }

  BorderSide? _getBorder(ThemeData theme) {
    switch (widget.style) {
      case InteractiveButtonStyle.outline:
        return BorderSide(
          color: theme.colorScheme.primary,
          width: 2.0,
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = _getBackgroundColor(theme);
    final textColor = _getTextColor(theme);
    final border = _getBorder(theme);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              width: widget.width,
              height: widget.height ?? InteractiveDesign.buttonHeight,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(InteractiveDesign.mediumRadius),
                border: border != null ? Border.fromBorderSide(border) : null,
                boxShadow: [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.3 * _glowAnimation.value),
                    blurRadius: 10 * _glowAnimation.value,
                    spreadRadius: 2 * _glowAnimation.value,
                    offset: Offset(0, 4 * _glowAnimation.value),
                  ),
                ],
                gradient: widget.style == InteractiveButtonStyle.primary
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          backgroundColor,
                          backgroundColor.withOpacity(0.8),
                        ],
                      )
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(InteractiveDesign.mediumRadius),
                  onTap: widget.onPressed != null && !widget.isLoading ? _handlePress : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: InteractiveDesign.mediumSpacing,
                      vertical: InteractiveDesign.smallSpacing,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isLoading)
                          widget.loadingWidget ??
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                                ),
                              )
                        else ...[
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: textColor,
                              size: 20,
                            ),
                            const SizedBox(width: InteractiveDesign.smallSpacing),
                          ],
                          Text(
                            widget.text,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Button style variants
enum InteractiveButtonStyle {
  primary,
  secondary,
  success,
  warning,
  error,
  outline,
  ghost,
}

/// Specialized button for correct answers
class CorrectAnswerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSelected;

  const CorrectAnswerButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveButton(
      text: text,
      onPressed: onPressed,
      style: isSelected ? InteractiveButtonStyle.success : InteractiveButtonStyle.outline,
      backgroundColor: isSelected ? LightModeColors.lightSuccess : null,
      icon: isSelected ? Icons.check_circle : null,
    );
  }
}

/// Specialized button for incorrect answers
class IncorrectAnswerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSelected;

  const IncorrectAnswerButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveButton(
      text: text,
      onPressed: onPressed,
      style: isSelected ? InteractiveButtonStyle.error : InteractiveButtonStyle.outline,
      backgroundColor: isSelected ? Theme.of(context).colorScheme.error : null,
      icon: isSelected ? Icons.cancel : null,
    );
  }
}

/// Floating action button with game-like effects
class GameFloatingActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;

  const GameFloatingActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
  });

  @override
  State<GameFloatingActionButton> createState() => _GameFloatingActionButtonState();
}

class _GameFloatingActionButtonState extends State<GameFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: FloatingActionButton(
            onPressed: widget.onPressed != null
                ? () {
                    SoundManagerService.instance.playButtonClick();
                    HapticFeedback.mediumImpact();
                    widget.onPressed!();
                  }
                : null,
            backgroundColor: widget.backgroundColor ?? theme.colorScheme.primary,
            tooltip: widget.tooltip,
            elevation: InteractiveDesign.floatingElevation,
            child: Icon(
              widget.icon,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        );
      },
    );
  }
}
