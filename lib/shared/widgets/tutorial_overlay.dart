/// Tutorial overlay widget for displaying interactive tutorials
/// 
/// This widget shows a semi-transparent overlay with highlighted areas,
/// animated pointers, and instructional text bubbles.

import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/tutorial_content.dart';

/// Tutorial overlay widget
class TutorialOverlay extends StatefulWidget {
  final Tutorial tutorial;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;
  final Color overlayColor;
  final Color highlightColor;
  final Color bubbleColor;
  
  const TutorialOverlay({
    Key? key,
    required this.tutorial,
    required this.onComplete,
    this.onSkip,
    this.overlayColor = const Color(0xCC000000), // 80% black
    this.highlightColor = Colors.yellow,
    this.bubbleColor = Colors.white,
  }) : super(key: key);

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  TutorialStep get _currentStep => widget.tutorial.steps[_currentStepIndex];
  bool get _isLastStep => _currentStepIndex == widget.tutorial.steps.length - 1;

  void _nextStep() {
    if (_isLastStep) {
      widget.onComplete();
    } else {
      setState(() {
        _currentStepIndex++;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _skip() {
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark overlay
          Container(
            color: widget.overlayColor,
          ),
          
          // Tutorial content
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildTutorialContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialContent(BuildContext context) {
    return Stack(
      children: [
        // Animated pointer (if specified)
        if (_currentStep.pointerOffset != null)
          _buildAnimatedPointer(context),
        
        // Text bubble
        _buildTextBubble(context),
      ],
    );
  }

  Widget _buildAnimatedPointer(BuildContext context) {
    return Positioned(
      left: MediaQuery.of(context).size.width / 2 - 24,
      top: MediaQuery.of(context).size.height / 3,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1000),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, sin(value * 2 * pi) * 10),
            child: Icon(
              Icons.arrow_downward,
              size: 48,
              color: widget.highlightColor,
              shadows: [
                Shadow(
                  color: widget.highlightColor.withOpacity(0.5),
                  blurRadius: 20,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextBubble(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Positioned(
      left: screenWidth * 0.1,
      right: screenWidth * 0.1,
      bottom: screenHeight * 0.15,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.bubbleColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon and title
            Row(
              children: [
                if (_currentStep.icon != null) ...[
                  Text(
                    _currentStep.icon!,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    _currentStep.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              _currentStep.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.tutorial.steps.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentStepIndex
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Step counter
            Text(
              'Step ${_currentStepIndex + 1} of ${widget.tutorial.steps.length}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                // Skip button
                if (widget.tutorial.canSkip)
                  TextButton(
                    onPressed: _skip,
                    child: const Text('Skip'),
                  ),
                
                const Spacer(),
                
                // Previous button
                if (_currentStepIndex > 0)
                  TextButton(
                    onPressed: _previousStep,
                    child: const Text('Back'),
                  ),
                
                const SizedBox(width: 8),
                
                // Next/Done button
                ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text(_isLastStep ? 'Got it!' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show tutorial overlay
Future<void> showTutorialOverlay(
  BuildContext context,
  Tutorial tutorial, {
  VoidCallback? onComplete,
  VoidCallback? onSkip,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (context) => TutorialOverlay(
      tutorial: tutorial,
      onComplete: () {
        Navigator.of(context).pop();
        onComplete?.call();
      },
      onSkip: () {
        Navigator.of(context).pop();
        onSkip?.call();
      },
    ),
  );
}

