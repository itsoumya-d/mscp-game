# Phase 3: Level Progression & Unlock System - Implementation Guide

**Duration**: 4 weeks  
**Priority**: HIGH  
**Status**: Ready for Implementation

---

## Overview

This phase implements an engaging level progression system with visual unlock mechanics, progress tracking, and celebration animations. Users will see clear paths forward and feel rewarded for their progress.

---

## Task 1: Design Unlock Conditions Logic (Week 1)

### Objective
Define when and how levels/chapters unlock based on user performance.

### Implementation

#### 1.1 Create UnlockCondition Model

```dart
// lib/core/models/unlock_condition.dart
enum UnlockType {
  sequential,    // Complete previous level
  xpBased,       // Earn X amount of XP
  accuracyBased, // Achieve X% accuracy
  achievementBased, // Complete specific achievement
  timeBased,     // Available after certain date
}

class UnlockCondition {
  final UnlockType type;
  final int? requiredLevel;
  final int? requiredXP;
  final double? requiredAccuracy;
  final String? requiredAchievement;
  final DateTime? availableAfter;

  const UnlockCondition({
    required this.type,
    this.requiredLevel,
    this.requiredXP,
    this.requiredAccuracy,
    this.requiredAchievement,
    this.availableAfter,
  });

  bool isMet(UserProgress progress) {
    switch (type) {
      case UnlockType.sequential:
        return progress.completedLevels.contains(requiredLevel);
      case UnlockType.xpBased:
        return progress.totalXP >= (requiredXP ?? 0);
      case UnlockType.accuracyBased:
        return progress.overallAccuracy >= (requiredAccuracy ?? 0.0);
      case UnlockType.achievementBased:
        return progress.achievements.contains(requiredAchievement);
      case UnlockType.timeBased:
        return DateTime.now().isAfter(availableAfter ?? DateTime.now());
    }
  }
}
```

#### 1.2 Update Level Model

```dart
// Add to lib/core/models/level.dart
class Level {
  // ... existing fields ...
  final UnlockCondition? unlockCondition;
  final bool isLocked;
  
  bool canUnlock(UserProgress progress) {
    if (unlockCondition == null) return true;
    return unlockCondition!.isMet(progress);
  }
}
```

#### 1.3 Create UnlockService

```dart
// lib/core/services/unlock_service.dart
class UnlockService {
  Future<List<Level>> checkForNewUnlocks(UserProgress progress) async {
    final newlyUnlocked = <Level>[];
    final allLevels = await _getAllLevels();
    
    for (final level in allLevels) {
      if (level.isLocked && level.canUnlock(progress)) {
        await _unlockLevel(level.id);
        newlyUnlocked.add(level);
      }
    }
    
    return newlyUnlocked;
  }
  
  Future<void> _unlockLevel(String levelId) async {
    // Update database
    // Trigger unlock animation
    // Award unlock bonus (gems, XP)
  }
}
```

### Testing Checklist
- [ ] Sequential unlocking works correctly
- [ ] XP-based unlocking triggers at right threshold
- [ ] Accuracy requirements calculated correctly
- [ ] Multiple unlock conditions can be combined

---

## Task 2: Create Locked/Unlocked UI States (Week 1-2)

### Objective
Design distinct visual states for locked, unlocked, in-progress, and completed levels.

### Implementation

#### 2.1 Create LevelStateWidget

```dart
// lib/shared/widgets/level_state_widget.dart
enum LevelState {
  locked,
  unlocked,
  inProgress,
  completed,
}

class LevelStateWidget extends StatelessWidget {
  final LevelState state;
  final Level level;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: state != LevelState.locked ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: _getDecoration(state),
        child: Stack(
          children: [
            _buildContent(state),
            if (state == LevelState.locked) _buildLockOverlay(),
            if (state == LevelState.completed) _buildCompletionBadge(),
          ],
        ),
      ),
    );
  }

  BoxDecoration _getDecoration(LevelState state) {
    switch (state) {
      case LevelState.locked:
        return BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade400, width: 2),
        );
      case LevelState.unlocked:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case LevelState.inProgress:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.orange.shade600],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case LevelState.completed:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
    }
  }

  Widget _buildLockOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(
          Icons.lock,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCompletionBadge() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.amber,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
```

### Design Specifications
- **Locked**: Gray, desaturated, lock icon overlay
- **Unlocked**: Vibrant gradient, glowing shadow, pulsing animation
- **In Progress**: Orange gradient, progress bar visible
- **Completed**: Green gradient, checkmark badge, star rating

---

## Task 3: Implement Unlock Animations (Week 2)

### Objective
Create satisfying lock-breaking animation with particles and confetti.

### Implementation

#### 3.1 Create UnlockAnimationWidget

```dart
// lib/shared/widgets/unlock_animation_widget.dart
class UnlockAnimationWidget extends StatefulWidget {
  final Level level;
  final VoidCallback onComplete;

  @override
  State<UnlockAnimationWidget> createState() => _UnlockAnimationWidgetState();
}

class _UnlockAnimationWidgetState extends State<UnlockAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _breakController;
  late AnimationController _revealController;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _playUnlockSequence();
  }

  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _breakController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _playUnlockSequence() async {
    // 1. Shake the lock
    await _shakeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    
    // 2. Break the lock
    await _breakController.forward();
    
    // 3. Reveal the level with confetti
    _confettiController.play();
    await _revealController.forward();
    
    // 4. Complete
    await Future.delayed(const Duration(milliseconds: 500));
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            colors: const [Colors.blue, Colors.green, Colors.orange, Colors.purple],
          ),
        ),
        
        // Animation sequence
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock breaking animation
              AnimatedBuilder(
                animation: _breakController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_breakController.value * 0.5),
                    child: Opacity(
                      opacity: 1.0 - _breakController.value,
                      child: const Icon(
                        Icons.lock_open,
                        size: 100,
                        color: Colors.amber,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Level reveal
              FadeTransition(
                opacity: _revealController,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _revealController,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Level ${widget.level.number} Unlocked!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.level.title,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

### Animation Sequence
1. **Shake** (0.5s): Lock shakes vigorously
2. **Break** (0.3s): Lock explodes into particles
3. **Reveal** (0.6s): Level card scales up with elastic bounce
4. **Confetti** (3s): Celebration particles fall

---

## Task 4-6: Progress Tracking, Level Map, Skill Tree (Week 3-4)

### Quick Implementation Notes

**Progress Tracking UI**:
- Circular progress indicators for each subject
- XP bar with milestone markers
- Achievement progress cards
- Daily/weekly goal trackers

**Level Map Visualization**:
- Vertical scrolling path (Candy Crush style)
- Nodes connected by animated paths
- Current position highlighted
- Upcoming levels visible but grayed

**Skill Tree Layout**:
- Branching paths for different topics
- Prerequisites shown with connecting lines
- Multiple paths to same destination
- Visual indication of recommended path

---

## Integration Points

### With Existing Code
- Update `level_selection_screen.dart` to use new state widgets
- Integrate unlock checks in `game_controller.dart`
- Add unlock animations to level completion flow
- Update progress tracking in `user_progress_service.dart`

### Database Changes
```sql
ALTER TABLE levels ADD COLUMN unlock_condition TEXT;
ALTER TABLE levels ADD COLUMN is_locked BOOLEAN DEFAULT TRUE;
ALTER TABLE user_progress ADD COLUMN unlocked_levels TEXT; -- JSON array
```

---

## Testing Strategy

1. **Unit Tests**: Unlock condition logic
2. **Widget Tests**: UI state transitions
3. **Integration Tests**: Full unlock flow
4. **User Testing**: Satisfaction with animations

---

## Success Metrics

- [ ] All unlock conditions work correctly
- [ ] Animations play smoothly (60 FPS)
- [ ] Users understand progression path
- [ ] Unlock celebrations feel rewarding
- [ ] No performance issues with animations

---

**Next**: Phase 4 - Interactive Elements & Gamification

