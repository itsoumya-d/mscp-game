# Content Quality Improvements Guide
**Date**: 2025-10-02  
**Version**: 1.0  
**Purpose**: Guide for improving question quality and content diversity

---

## Overview

This document outlines improvements needed for question quality, validation, difficulty scaling, and cultural diversity in LearnoSphere.

---

## 1. Fix Drag & Drop Validation Issues

### Current Problem
- **Rejection Rate**: 14.3% of dragDrop questions are rejected
- **Root Cause**: Incorrect format expectations

### Issue Details

**Expected Format**:
```dart
options: ['LEFT:a|b|c', 'RIGHT:x|y|z']
correctAnswer: 'a:x,b:y,c:z'
```

**Common Errors**:
1. Single value instead of JSON array
2. Correct answer not in options
3. Mismatched left/right items

### Fix Implementation

**File**: `lib/core/services/comprehensive_lesson_generator.dart`

```dart
// BEFORE (Incorrect validation)
if (question.type == QuestionType.dragDrop) {
  if (question.correctAnswer is! Map) {
    return false;  // ← Too strict
  }
}

// AFTER (Correct validation)
if (question.type == QuestionType.dragDrop) {
  // Parse options
  if (question.options == null || question.options!.length != 2) {
    return false;
  }
  
  final leftItems = question.options![0].split(':')[1].split('|');
  final rightItems = question.options![1].split(':')[1].split('|');
  
  // Parse correct answer
  final pairs = question.correctAnswer.split(',');
  
  // Validate each pair
  for (final pair in pairs) {
    final parts = pair.split(':');
    if (parts.length != 2) return false;
    
    final left = parts[0];
    final right = parts[1];
    
    // Check if items exist in options
    if (!leftItems.contains(left) || !rightItems.contains(right)) {
      return false;
    }
  }
  
  return true;
}
```

**File**: `lib/core/services/ai_content_generator.dart`

```dart
// Add validation before returning dragDrop questions
Question _generateDragDropQuestion(String subject, int level) {
  // ... generation logic ...
  
  // Validate format
  if (!_validateDragDropFormat(question)) {
    // Regenerate or use fallback
    return _getFallbackDragDropQuestion(subject, level);
  }
  
  return question;
}

bool _validateDragDropFormat(Question question) {
  try {
    final leftItems = question.options![0].split(':')[1].split('|');
    final rightItems = question.options![1].split(':')[1].split('|');
    final pairs = question.correctAnswer.split(',');
    
    // Must have same number of pairs as left items
    if (pairs.length != leftItems.length) return false;
    
    // Each pair must be valid
    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length != 2) return false;
      if (!leftItems.contains(parts[0])) return false;
      if (!rightItems.contains(parts[1])) return false;
    }
    
    return true;
  } catch (e) {
    return false;
  }
}
```

---

## 2. Increase Difficulty for Levels 7-10

### Current Problem
- Levels 7-10 questions are too easy
- No significant difficulty increase
- Kids get bored

### Difficulty Scaling Strategy

**File**: `lib/core/services/game_session_service.dart`

```dart
// BEFORE
int _calculateDifficulty(int level) {
  return level;  // ← Too simple
}

// AFTER
int _calculateDifficulty(int level) {
  // Exponential difficulty scaling
  if (level <= 3) {
    return level;  // Easy: 1-3
  } else if (level <= 6) {
    return 3 + (level - 3) * 2;  // Medium: 4-9
  } else {
    return 9 + (level - 6) * 3;  // Hard: 10-18
  }
}
```

### Level-Specific Improvements

**Level 1-3 (Easy)**:
- Small numbers (1-10)
- Simple operations
- Obvious distractors
- Clear explanations

**Level 4-6 (Medium)**:
- Medium numbers (10-50)
- Two-step problems
- Plausible distractors
- Detailed explanations

**Level 7-10 (Hard)**:
- Large numbers (50-100+)
- Multi-step reasoning
- Tricky distractors
- Comprehensive explanations

### Example: Math Addition

```dart
Question _generateAdditionQuestion(int level) {
  if (level <= 3) {
    // Easy: Single digit
    final a = Random().nextInt(9) + 1;  // 1-9
    final b = Random().nextInt(9) + 1;
    final answer = a + b;
    
    return Question(
      text: 'What is $a + $b?',
      options: [
        '${answer - 1}',
        '$answer',
        '${answer + 1}',
        '${answer + 2}',
      ]..shuffle(),
      correctAnswer: '$answer',
    );
  } else if (level <= 6) {
    // Medium: Two digits
    final a = Random().nextInt(40) + 10;  // 10-49
    final b = Random().nextInt(40) + 10;
    final answer = a + b;
    
    return Question(
      text: 'What is $a + $b?',
      options: [
        '${answer - 5}',
        '${answer - 2}',
        '$answer',
        '${answer + 3}',
      ]..shuffle(),
      correctAnswer: '$answer',
    );
  } else {
    // Hard: Three digits or word problems
    final a = Random().nextInt(400) + 100;  // 100-499
    final b = Random().nextInt(400) + 100;
    final answer = a + b;
    
    return Question(
      text: 'Sarah has $a marbles. She gets $b more marbles from her friend. How many marbles does she have now?',
      options: [
        '${answer - 10}',
        '${answer - 5}',
        '$answer',
        '${answer + 5}',
      ]..shuffle(),
      correctAnswer: '$answer',
      explanation: 'Add the two numbers: $a + $b = $answer',
    );
  }
}
```

---

## 3. Add Diverse Names and Cultural Scenarios

### Current Problem
- Limited name pool
- Not culturally diverse
- Kids may not relate to names

### Solution: Diverse Name Lists

**File**: `lib/core/services/ai_content_generator.dart`

```dart
class DiverseNamePool {
  // American names
  static const americanNames = [
    'Emma', 'Liam', 'Olivia', 'Noah', 'Ava', 'Ethan',
    'Sophia', 'Mason', 'Isabella', 'William',
  ];
  
  // Asian names
  static const asianNames = [
    'Li', 'Yuki', 'Priya', 'Raj', 'Mei', 'Kenji',
    'Aisha', 'Arjun', 'Sakura', 'Wei',
  ];
  
  // African names
  static const africanNames = [
    'Amara', 'Kofi', 'Zuri', 'Kwame', 'Nia', 'Jabari',
    'Imani', 'Malik', 'Aaliyah', 'Tariq',
  ];
  
  // Hispanic names
  static const hispanicNames = [
    'Sofia', 'Diego', 'Isabella', 'Miguel', 'Valentina', 'Carlos',
    'Camila', 'Mateo', 'Luna', 'Santiago',
  ];
  
  // Middle Eastern names
  static const middleEasternNames = [
    'Fatima', 'Omar', 'Layla', 'Hassan', 'Zara', 'Ali',
    'Noor', 'Yusuf', 'Amina', 'Karim',
  ];
  
  // European names
  static const europeanNames = [
    'Emma', 'Lucas', 'Mia', 'Felix', 'Anna', 'Max',
    'Sophie', 'Leo', 'Clara', 'Oscar',
  ];
  
  // Get random name from all cultures
  static String getRandomName() {
    final allNames = [
      ...americanNames,
      ...asianNames,
      ...africanNames,
      ...hispanicNames,
      ...middleEasternNames,
      ...europeanNames,
    ];
    return allNames[Random().nextInt(allNames.length)];
  }
  
  // Get name from specific culture
  static String getNameFromCulture(String culture) {
    switch (culture) {
      case 'american':
        return americanNames[Random().nextInt(americanNames.length)];
      case 'asian':
        return asianNames[Random().nextInt(asianNames.length)];
      case 'african':
        return africanNames[Random().nextInt(africanNames.length)];
      case 'hispanic':
        return hispanicNames[Random().nextInt(hispanicNames.length)];
      case 'middle_eastern':
        return middleEasternNames[Random().nextInt(middleEasternNames.length)];
      case 'european':
        return europeanNames[Random().nextInt(europeanNames.length)];
      default:
        return getRandomName();
    }
  }
}
```

### Usage in Questions

```dart
Question _generateWordProblem() {
  final name1 = DiverseNamePool.getRandomName();
  final name2 = DiverseNamePool.getRandomName();
  
  return Question(
    text: '$name1 has 5 apples. $name2 gives $name1 3 more apples. How many apples does $name1 have now?',
    // ...
  );
}
```

### Cultural Scenarios

```dart
class CulturalScenarios {
  static const scenarios = {
    'food': [
      'pizza', 'sushi', 'tacos', 'curry', 'pasta',
      'dumplings', 'falafel', 'paella', 'pho', 'biryani',
    ],
    'sports': [
      'soccer', 'basketball', 'cricket', 'baseball', 'tennis',
      'badminton', 'volleyball', 'rugby', 'hockey', 'swimming',
    ],
    'celebrations': [
      'birthday', 'Diwali', 'Eid', 'Christmas', 'Hanukkah',
      'Lunar New Year', 'Thanksgiving', 'Ramadan', 'Kwanzaa',
    ],
    'places': [
      'park', 'school', 'library', 'market', 'temple',
      'mosque', 'church', 'community center', 'playground',
    ],
  };
  
  static String getRandomScenario(String category) {
    final items = scenarios[category] ?? [];
    return items[Random().nextInt(items.length)];
  }
}
```

---

## 4. Unit Tests for Critical Fixes

### Test File Structure

```
test/
├── widget_test.dart
├── services/
│   ├── predefined_games_manager_test.dart
│   ├── level_progression_service_test.dart
│   ├── tutorial_service_test.dart
│   └── ai_content_generator_test.dart
└── widgets/
    ├── question_widget_test.dart
    └── tutorial_overlay_test.dart
```

### Example: Question Widget Tests

**File**: `test/widgets/question_widget_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sp/features/lessons/widgets/question_widget.dart';

void main() {
  group('QuestionWidget Tests', () {
    testWidgets('handles 4 options correctly', (tester) async {
      final question = Question(
        id: 'test',
        text: 'Test question',
        type: QuestionType.multipleChoice,
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'A',
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionWidget(
              question: question,
              onAnswerSelected: (_) {},
              onSubmit: () {},
            ),
          ),
        ),
      );
      
      // Verify all 4 options are displayed
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
    });
    
    testWidgets('handles 6 options correctly', (tester) async {
      final question = Question(
        id: 'test',
        text: 'Test question',
        type: QuestionType.multipleChoice,
        options: ['A', 'B', 'C', 'D', 'E', 'F'],
        correctAnswer: 'A',
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionWidget(
              question: question,
              onAnswerSelected: (_) {},
              onSubmit: () {},
            ),
          ),
        ),
      );
      
      // Verify all 6 options are displayed
      expect(find.text('A'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });
    
    testWidgets('limits to 6 options when 8 provided', (tester) async {
      final question = Question(
        id: 'test',
        text: 'Test question',
        type: QuestionType.multipleChoice,
        options: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'],
        correctAnswer: 'A',
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionWidget(
              question: question,
              onAnswerSelected: (_) {},
              onSubmit: () {},
            ),
          ),
        ),
      );
      
      // Verify only first 6 options are displayed
      expect(find.text('A'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
      expect(find.text('G'), findsNothing);
      expect(find.text('H'), findsNothing);
    });
  });
}
```

---

## 5. Integration Tests

**File**: `test/integration/navigation_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Navigation Flow Tests', () {
    testWidgets('Complete Math Addition flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Tap Math card
      await tester.tap(find.text('Math'));
      await tester.pumpAndSettle();
      
      // Tap Addition skill
      await tester.tap(find.text('Addition & Subtraction'));
      await tester.pumpAndSettle();
      
      // Tap Level 1
      await tester.tap(find.text('Level 1'));
      await tester.pumpAndSettle();
      
      // Verify game session started
      expect(find.text('Question 1 of 7'), findsOneWidget);
    });
  });
}
```

---

## Implementation Checklist

- [ ] Fix dragDrop validation in comprehensive_lesson_generator.dart
- [ ] Fix dragDrop validation in ai_content_generator.dart
- [ ] Update difficulty calculation in game_session_service.dart
- [ ] Add diverse name pool to ai_content_generator.dart
- [ ] Add cultural scenarios to question templates
- [ ] Write unit tests for question_widget.dart
- [ ] Write unit tests for predefined_games_manager.dart
- [ ] Write integration tests for navigation flows
- [ ] Test all changes thoroughly

---

**Status**: Design Complete - Ready for Implementation  
**Next Step**: Implement fixes and run tests

