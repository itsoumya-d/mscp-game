import 'package:flutter/material.dart';
import 'level_unlock_animation.dart';
import 'difficulty_indicator.dart';
import 'level_progress_indicator.dart';

/// Overlay that appears when a level is completed
class LevelCompletionOverlay extends StatefulWidget {
  final Map<String, dynamic> completionData;
  final VoidCallback onContinue;
  final VoidCallback? onReplay;
  final VoidCallback? onHome;

  const LevelCompletionOverlay({
    Key? key,
    required this.completionData,
    required this.onContinue,
    this.onReplay,
    this.onHome,
  }) : super(key: key);

  @override
  State<LevelCompletionOverlay> createState() => _LevelCompletionOverlayState();
}

class _LevelCompletionOverlayState extends State<LevelCompletionOverlay>
    with TickerProviderStateMixin {
  late AnimationController _overlayController;
  late AnimationController _contentController;
  late Animation<double> _overlayAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _showUnlockAnimations = false;
  int _currentUnlockIndex = 0;

  @override
  void initState() {
    super.initState();
    
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _overlayAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _overlayController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.elasticOut,
    ));

    _startAnimations();
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _startAnimations() async {
    await _overlayController.forward();
    await _contentController.forward();
    
    // Check if there are newly unlocked levels
    final newlyUnlocked = widget.completionData['newlyUnlockedLevels'] as List<int>? ?? [];
    if (newlyUnlocked.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _showUnlockAnimations = true;
      });
    }
  }

  void _onUnlockAnimationComplete() {
    final newlyUnlocked = widget.completionData['newlyUnlockedLevels'] as List<int>? ?? [];
    if (_currentUnlockIndex < newlyUnlocked.length - 1) {
      setState(() {
        _currentUnlockIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _overlayAnimation,
        builder: (context, child) {
          return Container(
            color: Colors.black.withOpacity(0.8 * _overlayAnimation.value),
            child: Stack(
              children: [
                // Main completion content
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildCompletionContent(),
                ),
                
                // Unlock animations overlay
                if (_showUnlockAnimations)
                  _buildUnlockAnimations(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompletionContent() {
    final completedLevel = widget.completionData['completedLevel'] as int;
    final earnedXP = widget.completionData['earnedXP'] as int;
    final currentXP = widget.completionData['currentXP'] as int;
    final currentLevel = widget.completionData['currentLevel'] as int;
    final newlyUnlocked = widget.completionData['newlyUnlockedLevels'] as List<int>? ?? [];

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon and title
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              'Level $completedLevel Complete!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            // XP gained
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '+$earnedXP XP',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Current progress
            LevelProgressIndicator(
              currentLevel: currentLevel,
              totalLevels: 50,
              progress: currentXP / 1000.0, // Assuming 1000 XP per level
            ),
            const SizedBox(height: 16),
            
            // Newly unlocked levels notification
            if (newlyUnlocked.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_open, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'New Levels Unlocked!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: newlyUnlocked.map((level) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Level $level',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (widget.onHome != null)
                  _buildActionButton(
                    icon: Icons.home,
                    label: 'Home',
                    onPressed: widget.onHome!,
                    color: Colors.grey,
                  ),
                
                if (widget.onReplay != null)
                  _buildActionButton(
                    icon: Icons.replay,
                    label: 'Replay',
                    onPressed: widget.onReplay!,
                    color: Colors.orange,
                  ),
                
                _buildActionButton(
                  icon: Icons.arrow_forward,
                  label: 'Continue',
                  onPressed: widget.onContinue,
                  color: Colors.blue,
                  isPrimary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool isPrimary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : Colors.white,
        foregroundColor: isPrimary ? Colors.white : color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildUnlockAnimations() {
    final newlyUnlocked = widget.completionData['newlyUnlockedLevels'] as List<int>? ?? [];
    
    if (_currentUnlockIndex >= newlyUnlocked.length) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withOpacity(0.9),
      child: LevelUnlockAnimation(
        level: newlyUnlocked[_currentUnlockIndex],
        onComplete: _onUnlockAnimationComplete,
        primaryColor: Colors.blue,
      ),
    );
  }
}

/// A simpler notification widget for quick level unlock feedback
class QuickUnlockNotification extends StatelessWidget {
  final List<int> unlockedLevels;
  final VoidCallback? onDismiss;

  const QuickUnlockNotification({
    Key? key,
    required this.unlockedLevels,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (unlockedLevels.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: UnlockNotification(
        message: unlockedLevels.length == 1
            ? 'Level ${unlockedLevels.first} Unlocked!'
            : '${unlockedLevels.length} New Levels Unlocked!',
        onDismiss: onDismiss,
      ),
    );
  }
}