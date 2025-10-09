# Tutorial System Design Document
**Date**: 2025-10-02  
**Version**: 1.0  
**Purpose**: Design interactive tutorial system for kids ages 5-12

---

## Overview

The tutorial system will guide children through learning how to use the app and play each question type. It must be:
- **Kid-friendly**: Simple language, fun animations
- **Non-intrusive**: Easy to skip, can replay anytime
- **Contextual**: Shows tutorials when needed
- **Persistent**: Remembers which tutorials have been shown

---

## Architecture

### Components

1. **TutorialService** - Manages tutorial state
2. **TutorialOverlay** - UI widget for displaying tutorials
3. **TutorialContent** - Data models for tutorial steps
4. **TutorialTrigger** - Logic for when to show tutorials

### File Structure
```
lib/
├── core/
│   ├── services/
│   │   └── tutorial_service.dart          # State management
│   └── models/
│       └── tutorial_content.dart          # Data models
├── shared/
│   └── widgets/
│       ├── tutorial_overlay.dart          # Main overlay widget
│       ├── tutorial_pointer.dart          # Animated pointer
│       └── tutorial_bubble.dart           # Text bubble
└── features/
    └── practice/
        └── practice_mode_screen.dart      # Practice mode
```

---

## 1. TutorialService

### Responsibilities
- Track which tutorials have been shown
- Persist tutorial state to SharedPreferences
- Provide methods to check/mark tutorials as complete
- Reset tutorials if needed

### API
```dart
class TutorialService {
  // Check if tutorial has been shown
  Future<bool> hasShownTutorial(String tutorialId);
  
  // Mark tutorial as complete
  Future<void> markTutorialComplete(String tutorialId);
  
  // Reset all tutorials (for testing)
  Future<void> resetAllTutorials();
  
  // Get tutorial completion status
  Future<Map<String, bool>> getTutorialStatus();
}
```

### Tutorial IDs
```dart
static const String HOME_SCREEN = 'home_screen';
static const String SUBJECT_SELECTION = 'subject_selection';
static const String LEVEL_SELECTION = 'level_selection';
static const String MULTIPLE_CHOICE = 'question_type_multiple_choice';
static const String TRUE_FALSE = 'question_type_true_false';
static const String NUMERIC_INPUT = 'question_type_numeric_input';
static const String FILL_IN_BLANK = 'question_type_fill_in_blank';
static const String DRAG_DROP = 'question_type_drag_drop';
static const String CLICKABLE_ANSWER = 'question_type_clickable_answer';
static const String SHORT_ANSWER = 'question_type_short_answer';
```

### Storage
```dart
// SharedPreferences keys
static const String _TUTORIAL_PREFIX = 'tutorial_shown_';

// Example: 'tutorial_shown_home_screen' = true
```

---

## 2. TutorialContent

### Data Model
```dart
class TutorialStep {
  final String id;
  final String title;
  final String description;
  final String? targetWidgetKey;  // GlobalKey for highlighting
  final Offset? pointerOffset;     // Where to point
  final TutorialAnimation animation;
  final Duration duration;
  
  TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    this.targetWidgetKey,
    this.pointerOffset,
    this.animation = TutorialAnimation.fadeIn,
    this.duration = const Duration(seconds: 3),
  });
}

class Tutorial {
  final String id;
  final String name;
  final List<TutorialStep> steps;
  final bool canSkip;
  final bool canReplay;
  
  Tutorial({
    required this.id,
    required this.name,
    required this.steps,
    this.canSkip = true,
    this.canReplay = true,
  });
}

enum TutorialAnimation {
  fadeIn,
  slideUp,
  bounce,
  pulse,
}
```

### Tutorial Content Examples

#### Home Screen Tutorial
```dart
Tutorial(
  id: 'home_screen',
  name: 'Welcome to LearnoSphere!',
  steps: [
    TutorialStep(
      id: 'welcome',
      title: 'Welcome! 👋',
      description: 'Let\'s learn how to play!',
      animation: TutorialAnimation.fadeIn,
    ),
    TutorialStep(
      id: 'select_subject',
      title: 'Choose a Subject',
      description: 'Tap any subject to start learning!',
      targetWidgetKey: 'math_card',
      pointerOffset: Offset(0, -50),
      animation: TutorialAnimation.bounce,
    ),
  ],
);
```

#### Multiple Choice Tutorial
```dart
Tutorial(
  id: 'question_type_multiple_choice',
  name: 'Multiple Choice Questions',
  steps: [
    TutorialStep(
      id: 'read_question',
      title: 'Read the Question 📖',
      description: 'First, read the question carefully!',
    ),
    TutorialStep(
      id: 'tap_answer',
      title: 'Tap Your Answer 👆',
      description: 'Tap the answer you think is correct!',
      targetWidgetKey: 'answer_option_0',
      pointerOffset: Offset(0, -30),
      animation: TutorialAnimation.pulse,
    ),
    TutorialStep(
      id: 'submit',
      title: 'Submit Your Answer ✅',
      description: 'Tap the Submit button when you\'re ready!',
      targetWidgetKey: 'submit_button',
      pointerOffset: Offset(0, -30),
    ),
  ],
);
```

---

## 3. TutorialOverlay Widget

### Features
- Semi-transparent dark background (80% opacity)
- Highlighted target area (cutout with glow)
- Animated pointer/arrow
- Text bubble with instructions
- Next/Skip buttons
- Progress indicator (Step 1 of 3)

### UI Layout
```
┌─────────────────────────────────────┐
│  Dark Overlay (80% opacity)         │
│                                      │
│  ┌──────────────┐                   │
│  │              │ ← Highlighted     │
│  │  Target      │   area (cutout)   │
│  │  Widget      │                   │
│  └──────────────┘                   │
│         ↑                            │
│         │ Animated pointer           │
│    ┌────────────────┐                │
│    │  Text Bubble   │                │
│    │  "Tap here!"   │                │
│    │                │                │
│    │  [Skip] [Next] │                │
│    │  Step 1 of 3   │                │
│    └────────────────┘                │
│                                      │
└─────────────────────────────────────┘
```

### Implementation
```dart
class TutorialOverlay extends StatefulWidget {
  final Tutorial tutorial;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark background
        Container(
          color: Colors.black.withOpacity(0.8),
        ),
        
        // Highlighted area (if target specified)
        if (currentStep.targetWidgetKey != null)
          _buildHighlightedArea(),
        
        // Animated pointer
        if (currentStep.pointerOffset != null)
          _buildAnimatedPointer(),
        
        // Text bubble
        _buildTextBubble(),
        
        // Controls
        _buildControls(),
      ],
    );
  }
}
```

---

## 4. Tutorial Triggers

### When to Show Tutorials

#### First-Time User Flow
```
1. App Launch (first time)
   → Show home_screen tutorial
   
2. Select Subject (first time)
   → Show subject_selection tutorial
   
3. Select Level (first time)
   → Show level_selection tutorial
   
4. Start Game (first time)
   → Show question type tutorial (based on first question)
```

#### Question Type Triggers
```dart
// In game_session_screen.dart
@override
Widget build(BuildContext context) {
  final tutorialService = ref.read(tutorialServiceProvider);
  final currentQuestion = gameState.currentQuestion;
  
  // Check if we need to show tutorial for this question type
  final tutorialId = 'question_type_${currentQuestion.type.name}';
  final hasShown = await tutorialService.hasShownTutorial(tutorialId);
  
  if (!hasShown) {
    // Show tutorial overlay
    _showTutorialOverlay(tutorialId);
  }
  
  return ...;
}
```

### Help Button
```dart
// Add to all screens
FloatingActionButton(
  onPressed: () {
    // Show tutorial for current screen
    _showTutorial(context);
  },
  child: Icon(Icons.help_outline),
  tooltip: 'Help',
);
```

---

## 5. Practice Mode

### Purpose
Allow kids to practice each question type without pressure:
- No lives lost
- No score tracking
- Unlimited hints
- Can retry unlimited times
- Immediate feedback

### UI
```
┌─────────────────────────────────────┐
│  Practice Mode 🎯                   │
│  ─────────────────────────────────  │
│                                      │
│  Try each question type!             │
│                                      │
│  ✅ Multiple Choice                  │
│  ✅ True/False                       │
│  ⏳ Numeric Input (current)          │
│  ⬜ Fill in the Blank                │
│  ⬜ Drag & Drop                      │
│  ⬜ Clickable Answer                 │
│  ⬜ Short Answer                     │
│                                      │
│  [Try Next Type]  [I'm Ready!]      │
└─────────────────────────────────────┘
```

### Implementation
```dart
class PracticeModeScreen extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Practice Mode 🎯'),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          // Current question
          Expanded(
            child: _buildPracticeQuestion(),
          ),
          
          // Controls
          _buildControls(),
        ],
      ),
    );
  }
}
```

---

## 6. Animation Details

### Pointer Animation
```dart
class AnimatedPointer extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, sin(_controller.value * 2 * pi) * 10),
          child: Icon(
            Icons.arrow_downward,
            size: 48,
            color: Colors.yellow,
          ),
        );
      },
    );
  }
}
```

### Highlight Glow
```dart
BoxDecoration(
  border: Border.all(
    color: Colors.yellow,
    width: 3,
  ),
  borderRadius: BorderRadius.circular(12),
  boxShadow: [
    BoxShadow(
      color: Colors.yellow.withOpacity(0.5),
      blurRadius: 20,
      spreadRadius: 5,
    ),
  ],
);
```

---

## 7. Accessibility

### Screen Reader Support
```dart
Semantics(
  label: 'Tutorial: ${step.title}',
  hint: step.description,
  child: TutorialOverlay(...),
);
```

### Skip Option
- Always provide "Skip" button
- Keyboard shortcut: ESC key
- Voice command: "Skip tutorial"

---

## 8. Testing Strategy

### Unit Tests
- TutorialService state management
- Tutorial completion tracking
- Storage persistence

### Widget Tests
- TutorialOverlay rendering
- Button interactions
- Animation behavior

### Integration Tests
- Full tutorial flow
- First-time user experience
- Help button functionality

---

## 9. Implementation Checklist

- [ ] Create TutorialService
- [ ] Create TutorialContent models
- [ ] Implement TutorialOverlay widget
- [ ] Add tutorial triggers to screens
- [ ] Create practice mode screen
- [ ] Write tutorial content for all question types
- [ ] Add help buttons to all screens
- [ ] Test with kids (if possible)
- [ ] Add accessibility features
- [ ] Write unit tests

---

## 10. Future Enhancements

- **Video tutorials**: Short animated videos
- **Interactive demos**: Let kids try before playing
- **Gamified tutorials**: Earn badges for completing tutorials
- **Multilingual support**: Tutorials in multiple languages
- **Parent mode**: Tutorials for parents on how to help kids

---

**Status**: Design Complete - Ready for Implementation  
**Next Step**: Implement TutorialService and TutorialContent models

