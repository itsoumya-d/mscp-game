import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/flashcard.dart';

class RatingButtons extends StatefulWidget {
  final Function(ReviewRating) onRatingSelected;
  final bool isEnabled;

  const RatingButtons({
    Key? key,
    required this.onRatingSelected,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  State<RatingButtons> createState() => _RatingButtonsState();
}

class _RatingButtonsState extends State<RatingButtons>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  ReviewRating? _selectedRating;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));
    
    // Start slide animation
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleRatingTap(ReviewRating rating) async {
    if (!widget.isEnabled || _isAnimating) return;
    
    setState(() {
      _selectedRating = rating;
      _isAnimating = true;
    });
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Pulse animation
    await _pulseController.forward();
    await _pulseController.reverse();
    
    // Delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 200));
    
    widget.onRatingSelected(rating);
    
    setState(() {
      _isAnimating = false;
      _selectedRating = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'How well did you know this?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Rating buttons
            Row(
              children: [
                Expanded(
                  child: _buildRatingButton(
                    rating: ReviewRating.again,
                    label: 'Again',
                    subtitle: '< 1m',
                    color: Colors.red,
                    icon: Icons.refresh,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRatingButton(
                    rating: ReviewRating.hard,
                    label: 'Hard',
                    subtitle: '< 6m',
                    color: Colors.orange,
                    icon: Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRatingButton(
                    rating: ReviewRating.good,
                    label: 'Good',
                    subtitle: '< 10m',
                    color: Colors.blue,
                    icon: Icons.thumb_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRatingButton(
                    rating: ReviewRating.easy,
                    label: 'Easy',
                    subtitle: '4d',
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Keyboard shortcuts hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Keyboard: 1 (Again) • 2 (Hard) • 3 (Good) • 4 (Easy)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingButton({
    required ReviewRating rating,
    required String label,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _selectedRating == rating;
    final isDisabled = !widget.isEnabled;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = isSelected ? _pulseAnimation.value : 1.0;
        
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: () => _handleRatingTap(rating),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? color.withOpacity(0.2)
                    : isDisabled 
                        ? Colors.grey[100]
                        : Colors.white,
                border: Border.all(
                  color: isSelected 
                      ? color
                      : isDisabled 
                          ? Colors.grey[300]!
                          : color.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? color
                          : isDisabled 
                              ? Colors.grey[400]
                              : color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected 
                          ? Colors.white
                          : isDisabled 
                              ? Colors.grey[600]
                              : color,
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Label
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? color
                          : isDisabled 
                              ? Colors.grey[600]
                              : Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Subtitle
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDisabled 
                          ? Colors.grey[500]
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class RatingButtonsKeyboardHandler extends StatefulWidget {
  final Widget child;
  final Function(ReviewRating) onRatingSelected;
  final bool isEnabled;

  const RatingButtonsKeyboardHandler({
    Key? key,
    required this.child,
    required this.onRatingSelected,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  State<RatingButtonsKeyboardHandler> createState() => 
      _RatingButtonsKeyboardHandlerState();
}

class _RatingButtonsKeyboardHandlerState 
    extends State<RatingButtonsKeyboardHandler> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus for keyboard input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (!widget.isEnabled) return;
    
    if (event is RawKeyDownEvent) {
      switch (event.logicalKey.keyLabel) {
        case '1':
          widget.onRatingSelected(ReviewRating.again);
          break;
        case '2':
          widget.onRatingSelected(ReviewRating.hard);
          break;
        case '3':
          widget.onRatingSelected(ReviewRating.good);
          break;
        case '4':
          widget.onRatingSelected(ReviewRating.easy);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyPress,
      child: widget.child,
    );
  }
}