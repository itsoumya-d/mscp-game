/// Tutorial content models for the tutorial system
/// 
/// This file defines the data structures for tutorials, tutorial steps,
/// and tutorial animations used throughout the app.

import 'package:flutter/material.dart';

/// Animation types for tutorial steps
enum TutorialAnimation {
  fadeIn,
  slideUp,
  bounce,
  pulse,
  none,
}

/// A single step in a tutorial
class TutorialStep {
  /// Unique identifier for this step
  final String id;
  
  /// Title shown in the tutorial bubble
  final String title;
  
  /// Description/instructions for this step
  final String description;
  
  /// Optional key of the widget to highlight
  final String? targetWidgetKey;
  
  /// Offset for the pointer arrow relative to target
  final Offset? pointerOffset;
  
  /// Animation to use for this step
  final TutorialAnimation animation;
  
  /// Duration to show this step (if auto-advancing)
  final Duration duration;
  
  /// Icon to show in the bubble (emoji or icon data)
  final String? icon;

  const TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    this.targetWidgetKey,
    this.pointerOffset,
    this.animation = TutorialAnimation.fadeIn,
    this.duration = const Duration(seconds: 3),
    this.icon,
  });
}

/// A complete tutorial with multiple steps
class Tutorial {
  /// Unique identifier for this tutorial
  final String id;
  
  /// Display name of the tutorial
  final String name;
  
  /// List of steps in this tutorial
  final List<TutorialStep> steps;
  
  /// Whether the user can skip this tutorial
  final bool canSkip;
  
  /// Whether the user can replay this tutorial
  final bool canReplay;
  
  /// Whether to auto-advance through steps
  final bool autoAdvance;

  const Tutorial({
    required this.id,
    required this.name,
    required this.steps,
    this.canSkip = true,
    this.canReplay = true,
    this.autoAdvance = false,
  });
  
  /// Get the number of steps in this tutorial
  int get stepCount => steps.length;
}

/// Tutorial IDs used throughout the app
class TutorialIds {
  // Screen tutorials
  static const String homeScreen = 'home_screen';
  static const String subjectSelection = 'subject_selection';
  static const String levelSelection = 'level_selection';
  static const String gameSession = 'game_session';
  
  // Question type tutorials
  static const String multipleChoice = 'question_type_multiple_choice';
  static const String trueFalse = 'question_type_true_false';
  static const String numericInput = 'question_type_numeric_input';
  static const String fillInBlank = 'question_type_fill_in_blank';
  static const String dragDrop = 'question_type_drag_drop';
  static const String clickableAnswer = 'question_type_clickable_answer';
  static const String shortAnswer = 'question_type_short_answer';
  
  // Feature tutorials
  static const String hints = 'feature_hints';
  static const String lives = 'feature_lives';
  static const String xpSystem = 'feature_xp_system';
  static const String levelUnlocking = 'feature_level_unlocking';
}

/// Pre-defined tutorials for the app
class TutorialLibrary {
  /// Home screen tutorial
  static const Tutorial homeScreen = Tutorial(
    id: TutorialIds.homeScreen,
    name: 'Welcome to LearnoSphere!',
    steps: [
      TutorialStep(
        id: 'welcome',
        title: 'Welcome! 👋',
        description: 'Let\'s learn how to play and have fun!',
        animation: TutorialAnimation.fadeIn,
        icon: '👋',
      ),
      TutorialStep(
        id: 'select_subject',
        title: 'Choose a Subject',
        description: 'Tap any subject card to start learning! Try Math first!',
        targetWidgetKey: 'math_card',
        pointerOffset: Offset(0, -50),
        animation: TutorialAnimation.bounce,
        icon: '📚',
      ),
      TutorialStep(
        id: 'have_fun',
        title: 'Have Fun! 🎉',
        description: 'Answer questions, earn XP, and unlock new levels!',
        animation: TutorialAnimation.fadeIn,
        icon: '🎉',
      ),
    ],
  );
  
  /// Multiple choice question tutorial
  static const Tutorial multipleChoice = Tutorial(
    id: TutorialIds.multipleChoice,
    name: 'Multiple Choice Questions',
    steps: [
      TutorialStep(
        id: 'read_question',
        title: 'Read the Question 📖',
        description: 'First, read the question carefully at the top!',
        animation: TutorialAnimation.fadeIn,
        icon: '📖',
      ),
      TutorialStep(
        id: 'look_at_options',
        title: 'Look at the Options 👀',
        description: 'You\'ll see several answer choices. Only one is correct!',
        animation: TutorialAnimation.fadeIn,
        icon: '👀',
      ),
      TutorialStep(
        id: 'tap_answer',
        title: 'Tap Your Answer 👆',
        description: 'Tap the answer you think is correct. It will highlight!',
        targetWidgetKey: 'answer_option_0',
        pointerOffset: Offset(0, -30),
        animation: TutorialAnimation.pulse,
        icon: '👆',
      ),
      TutorialStep(
        id: 'submit',
        title: 'Submit Your Answer ✅',
        description: 'Tap the Submit button when you\'re ready!',
        targetWidgetKey: 'submit_button',
        pointerOffset: Offset(0, -30),
        animation: TutorialAnimation.bounce,
        icon: '✅',
      ),
    ],
  );
  
  /// True/False question tutorial
  static const Tutorial trueFalse = Tutorial(
    id: TutorialIds.trueFalse,
    name: 'True or False Questions',
    steps: [
      TutorialStep(
        id: 'read_statement',
        title: 'Read the Statement 📖',
        description: 'Read the statement carefully!',
        animation: TutorialAnimation.fadeIn,
        icon: '📖',
      ),
      TutorialStep(
        id: 'decide',
        title: 'Is it True or False? 🤔',
        description: 'Think about whether the statement is true or false.',
        animation: TutorialAnimation.fadeIn,
        icon: '🤔',
      ),
      TutorialStep(
        id: 'tap_choice',
        title: 'Tap Your Choice 👆',
        description: 'Tap True or False, then submit!',
        animation: TutorialAnimation.pulse,
        icon: '👆',
      ),
    ],
  );
  
  /// Numeric input question tutorial
  static const Tutorial numericInput = Tutorial(
    id: TutorialIds.numericInput,
    name: 'Number Answer Questions',
    steps: [
      TutorialStep(
        id: 'read_question',
        title: 'Read the Question 📖',
        description: 'This question needs a number as the answer!',
        animation: TutorialAnimation.fadeIn,
        icon: '📖',
      ),
      TutorialStep(
        id: 'type_number',
        title: 'Type the Number ⌨️',
        description: 'Tap the box and type your answer using the keyboard.',
        targetWidgetKey: 'numeric_input_field',
        pointerOffset: Offset(0, -30),
        animation: TutorialAnimation.pulse,
        icon: '⌨️',
      ),
      TutorialStep(
        id: 'submit',
        title: 'Submit Your Answer ✅',
        description: 'Tap Submit when you\'re done!',
        animation: TutorialAnimation.bounce,
        icon: '✅',
      ),
    ],
  );
  
  /// Fill in the blank question tutorial
  static const Tutorial fillInBlank = Tutorial(
    id: TutorialIds.fillInBlank,
    name: 'Fill in the Blank Questions',
    steps: [
      TutorialStep(
        id: 'read_sentence',
        title: 'Read the Sentence 📖',
        description: 'There\'s a blank space that needs a word!',
        animation: TutorialAnimation.fadeIn,
        icon: '📖',
      ),
      TutorialStep(
        id: 'type_word',
        title: 'Type the Missing Word ⌨️',
        description: 'Tap the box and type the word that fits best.',
        targetWidgetKey: 'fill_blank_input',
        pointerOffset: Offset(0, -30),
        animation: TutorialAnimation.pulse,
        icon: '⌨️',
      ),
      TutorialStep(
        id: 'submit',
        title: 'Submit Your Answer ✅',
        description: 'Tap Submit to check if you\'re right!',
        animation: TutorialAnimation.bounce,
        icon: '✅',
      ),
    ],
  );
  
  /// Drag and drop question tutorial
  static const Tutorial dragDrop = Tutorial(
    id: TutorialIds.dragDrop,
    name: 'Drag and Drop Questions',
    steps: [
      TutorialStep(
        id: 'understand_task',
        title: 'Match the Items 🔗',
        description: 'You need to match items from the left to the right!',
        animation: TutorialAnimation.fadeIn,
        icon: '🔗',
      ),
      TutorialStep(
        id: 'drag_item',
        title: 'Drag an Item 👆',
        description: 'Press and hold an item, then drag it to its match!',
        animation: TutorialAnimation.pulse,
        icon: '👆',
      ),
      TutorialStep(
        id: 'drop_item',
        title: 'Drop on the Match 🎯',
        description: 'Release your finger when you\'re over the correct match!',
        animation: TutorialAnimation.bounce,
        icon: '🎯',
      ),
      TutorialStep(
        id: 'match_all',
        title: 'Match All Items ✅',
        description: 'Match all items, then submit your answer!',
        animation: TutorialAnimation.fadeIn,
        icon: '✅',
      ),
    ],
  );
  
  /// Clickable answer question tutorial
  static const Tutorial clickableAnswer = Tutorial(
    id: TutorialIds.clickableAnswer,
    name: 'Select All That Apply',
    steps: [
      TutorialStep(
        id: 'multiple_correct',
        title: 'Multiple Correct Answers! 🎯',
        description: 'This question can have MORE THAN ONE correct answer!',
        animation: TutorialAnimation.fadeIn,
        icon: '🎯',
      ),
      TutorialStep(
        id: 'tap_all',
        title: 'Tap All Correct Answers 👆',
        description: 'Tap each answer you think is correct. You can tap multiple!',
        animation: TutorialAnimation.pulse,
        icon: '👆',
      ),
      TutorialStep(
        id: 'deselect',
        title: 'Change Your Mind? 🔄',
        description: 'Tap an answer again to deselect it!',
        animation: TutorialAnimation.fadeIn,
        icon: '🔄',
      ),
      TutorialStep(
        id: 'submit',
        title: 'Submit When Ready ✅',
        description: 'When you\'ve selected all correct answers, tap Submit!',
        animation: TutorialAnimation.bounce,
        icon: '✅',
      ),
    ],
  );
  
  /// Short answer question tutorial
  static const Tutorial shortAnswer = Tutorial(
    id: TutorialIds.shortAnswer,
    name: 'Short Answer Questions',
    steps: [
      TutorialStep(
        id: 'read_question',
        title: 'Read the Question 📖',
        description: 'This question needs a written answer!',
        animation: TutorialAnimation.fadeIn,
        icon: '📖',
      ),
      TutorialStep(
        id: 'write_answer',
        title: 'Write Your Answer ✍️',
        description: 'Type your answer in your own words. A few sentences is perfect!',
        targetWidgetKey: 'short_answer_field',
        pointerOffset: Offset(0, -30),
        animation: TutorialAnimation.pulse,
        icon: '✍️',
      ),
      TutorialStep(
        id: 'submit',
        title: 'Submit Your Answer ✅',
        description: 'Tap Submit when you\'re done writing!',
        animation: TutorialAnimation.bounce,
        icon: '✅',
      ),
    ],
  );
  
  /// Get tutorial by ID
  static Tutorial? getTutorial(String id) {
    switch (id) {
      case TutorialIds.homeScreen:
        return homeScreen;
      case TutorialIds.multipleChoice:
        return multipleChoice;
      case TutorialIds.trueFalse:
        return trueFalse;
      case TutorialIds.numericInput:
        return numericInput;
      case TutorialIds.fillInBlank:
        return fillInBlank;
      case TutorialIds.dragDrop:
        return dragDrop;
      case TutorialIds.clickableAnswer:
        return clickableAnswer;
      case TutorialIds.shortAnswer:
        return shortAnswer;
      default:
        return null;
    }
  }
  
  /// Get all available tutorials
  static List<Tutorial> getAllTutorials() {
    return [
      homeScreen,
      multipleChoice,
      trueFalse,
      numericInput,
      fillInBlank,
      dragDrop,
      clickableAnswer,
      shortAnswer,
    ];
  }
}

