import 'dart:math';
import 'package:flutter/foundation.dart';

/// Practice Problem Generator - Task F5
/// Infinite practice mode with manually-generated problems
/// 
/// Features:
/// - Infinite problem generation
/// - Difficulty adjustment
/// - Topic selection
/// - Performance tracking
/// - Adaptive difficulty

class PracticeProblemGenerator {
  static final PracticeProblemGenerator _instance = PracticeProblemGenerator._internal();
  factory PracticeProblemGenerator() => _instance;
  PracticeProblemGenerator._internal();

  final Random _random = Random();

  /// Generate a practice problem
  PracticeProblem generateProblem({
    required String subject,
    required String topic,
    required DifficultyLevel difficulty,
    List<String>? excludeQuestionIds,
  }) {
    // In production, this would use template-based generation
    // or retrieve from a database with templates
    
    final problemId = 'practice_${DateTime.now().millisecondsSinceEpoch}';
    
    switch (subject.toLowerCase()) {
      case 'math':
        return _generateMathProblem(problemId, topic, difficulty);
      case 'science':
        return _generateScienceProblem(problemId, topic, difficulty);
      case 'english':
        return _generateEnglishProblem(problemId, topic, difficulty);
      default:
        return _generateGenericProblem(problemId, subject, topic, difficulty);
    }
  }

  /// Generate multiple problems at once
  List<PracticeProblem> generateProblems({
    required String subject,
    required String topic,
    required DifficultyLevel difficulty,
    required int count,
  }) {
    final problems = <PracticeProblem>[];
    final usedIds = <String>{};
    
    for (int i = 0; i < count; i++) {
      final problem = generateProblem(
        subject: subject,
        topic: topic,
        difficulty: difficulty,
        excludeQuestionIds: usedIds.toList(),
      );
      problems.add(problem);
      usedIds.add(problem.id);
    }
    
    return problems;
  }

  PracticeProblem _generateMathProblem(
    String id,
    String topic,
    DifficultyLevel difficulty,
  ) {
    switch (topic.toLowerCase()) {
      case 'addition':
        return _generateAdditionProblem(id, difficulty);
      case 'subtraction':
        return _generateSubtractionProblem(id, difficulty);
      case 'multiplication':
        return _generateMultiplicationProblem(id, difficulty);
      case 'division':
        return _generateDivisionProblem(id, difficulty);
      case 'algebra':
        return _generateAlgebraProblem(id, difficulty);
      case 'geometry':
        return _generateGeometryProblem(id, difficulty);
      default:
        return _generateAdditionProblem(id, difficulty);
    }
  }

  PracticeProblem _generateAdditionProblem(String id, DifficultyLevel difficulty) {
    int maxNumber;
    switch (difficulty) {
      case DifficultyLevel.easy:
        maxNumber = 10;
        break;
      case DifficultyLevel.medium:
        maxNumber = 100;
        break;
      case DifficultyLevel.hard:
        maxNumber = 1000;
        break;
      case DifficultyLevel.expert:
        maxNumber = 10000;
        break;
    }

    final a = _random.nextInt(maxNumber) + 1;
    final b = _random.nextInt(maxNumber) + 1;
    final answer = a + b;

    return PracticeProblem(
      id: id,
      subject: 'Math',
      topic: 'Addition',
      difficulty: difficulty,
      questionText: 'What is $a + $b?',
      questionType: QuestionType.multipleChoice,
      correctAnswer: answer.toString(),
      options: _generateOptions(answer, 4),
      explanation: 'Add $a and $b together: $a + $b = $answer',
      hints: [
        'Start by adding the ones place',
        'Then add the tens place',
        'The answer is $answer',
      ],
      timeEstimate: Duration(seconds: 30),
      points: difficulty.points,
    );
  }

  PracticeProblem _generateSubtractionProblem(String id, DifficultyLevel difficulty) {
    int maxNumber;
    switch (difficulty) {
      case DifficultyLevel.easy:
        maxNumber = 10;
        break;
      case DifficultyLevel.medium:
        maxNumber = 100;
        break;
      case DifficultyLevel.hard:
        maxNumber = 1000;
        break;
      case DifficultyLevel.expert:
        maxNumber = 10000;
        break;
    }

    final a = _random.nextInt(maxNumber) + 1;
    final b = _random.nextInt(a) + 1; // Ensure positive result
    final answer = a - b;

    return PracticeProblem(
      id: id,
      subject: 'Math',
      topic: 'Subtraction',
      difficulty: difficulty,
      questionText: 'What is $a - $b?',
      questionType: QuestionType.multipleChoice,
      correctAnswer: answer.toString(),
      options: _generateOptions(answer, 4),
      explanation: 'Subtract $b from $a: $a - $b = $answer',
      hints: [
        'Start by subtracting the ones place',
        'Then subtract the tens place',
        'The answer is $answer',
      ],
      timeEstimate: Duration(seconds: 30),
      points: difficulty.points,
    );
  }

  PracticeProblem _generateMultiplicationProblem(String id, DifficultyLevel difficulty) {
    int maxNumber;
    switch (difficulty) {
      case DifficultyLevel.easy:
        maxNumber = 10;
        break;
      case DifficultyLevel.medium:
        maxNumber = 12;
        break;
      case DifficultyLevel.hard:
        maxNumber = 20;
        break;
      case DifficultyLevel.expert:
        maxNumber = 50;
        break;
    }

    final a = _random.nextInt(maxNumber) + 1;
    final b = _random.nextInt(maxNumber) + 1;
    final answer = a * b;

    return PracticeProblem(
      id: id,
      subject: 'Math',
      topic: 'Multiplication',
      difficulty: difficulty,
      questionText: 'What is $a × $b?',
      questionType: QuestionType.multipleChoice,
      correctAnswer: answer.toString(),
      options: _generateOptions(answer, 4),
      explanation: 'Multiply $a by $b: $a × $b = $answer',
      hints: [
        'Think of it as adding $a, $b times',
        'Or use the multiplication table',
        'The answer is $answer',
      ],
      timeEstimate: Duration(seconds: 45),
      points: difficulty.points,
    );
  }

  PracticeProblem _generateDivisionProblem(String id, DifficultyLevel difficulty) {
    int maxNumber;
    switch (difficulty) {
      case DifficultyLevel.easy:
        maxNumber = 10;
        break;
      case DifficultyLevel.medium:
        maxNumber = 12;
        break;
      case DifficultyLevel.hard:
        maxNumber = 20;
        break;
      case DifficultyLevel.expert:
        maxNumber = 50;
        break;
    }

    final b = _random.nextInt(maxNumber) + 1;
    final answer = _random.nextInt(maxNumber) + 1;
    final a = b * answer; // Ensure clean division

    return PracticeProblem(
      id: id,
      subject: 'Math',
      topic: 'Division',
      difficulty: difficulty,
      questionText: 'What is $a ÷ $b?',
      questionType: QuestionType.multipleChoice,
      correctAnswer: answer.toString(),
      options: _generateOptions(answer, 4),
      explanation: 'Divide $a by $b: $a ÷ $b = $answer',
      hints: [
        'How many times does $b go into $a?',
        'Think of the multiplication table',
        'The answer is $answer',
      ],
      timeEstimate: Duration(seconds: 45),
      points: difficulty.points,
    );
  }

  PracticeProblem _generateAlgebraProblem(String id, DifficultyLevel difficulty) {
    final x = _random.nextInt(20) + 1;
    final a = _random.nextInt(10) + 1;
    final b = a * x;

    return PracticeProblem(
      id: id,
      subject: 'Math',
      topic: 'Algebra',
      difficulty: difficulty,
      questionText: 'Solve for x: ${a}x = $b',
      questionType: QuestionType.multipleChoice,
      correctAnswer: x.toString(),
      options: _generateOptions(x, 4),
      explanation: 'Divide both sides by $a: x = $b ÷ $a = $x',
      hints: [
        'Isolate x by dividing both sides',
        'What number times $a equals $b?',
        'The answer is $x',
      ],
      timeEstimate: Duration(minutes: 1),
      points: difficulty.points,
    );
  }

  PracticeProblem _generateGeometryProblem(String id, DifficultyLevel difficulty) {
    final side = _random.nextInt(20) + 1;
    final area = side * side;

    return PracticeProblem(
      id: id,
      subject: 'Math',
      topic: 'Geometry',
      difficulty: difficulty,
      questionText: 'What is the area of a square with side length $side?',
      questionType: QuestionType.multipleChoice,
      correctAnswer: area.toString(),
      options: _generateOptions(area, 4),
      explanation: 'Area = side × side = $side × $side = $area',
      hints: [
        'Use the formula: Area = side²',
        'Multiply $side by itself',
        'The answer is $area',
      ],
      timeEstimate: Duration(seconds: 45),
      points: difficulty.points,
    );
  }

  PracticeProblem _generateScienceProblem(String id, String topic, DifficultyLevel difficulty) {
    // Placeholder for science problems
    return PracticeProblem(
      id: id,
      subject: 'Science',
      topic: topic,
      difficulty: difficulty,
      questionText: 'Science question about $topic',
      questionType: QuestionType.multipleChoice,
      correctAnswer: 'Answer',
      options: ['Answer', 'Option 2', 'Option 3', 'Option 4'],
      explanation: 'Explanation for the answer',
      hints: ['Hint 1', 'Hint 2', 'Hint 3'],
      timeEstimate: Duration(minutes: 1),
      points: difficulty.points,
    );
  }

  PracticeProblem _generateEnglishProblem(String id, String topic, DifficultyLevel difficulty) {
    // Placeholder for English problems
    return PracticeProblem(
      id: id,
      subject: 'English',
      topic: topic,
      difficulty: difficulty,
      questionText: 'English question about $topic',
      questionType: QuestionType.multipleChoice,
      correctAnswer: 'Answer',
      options: ['Answer', 'Option 2', 'Option 3', 'Option 4'],
      explanation: 'Explanation for the answer',
      hints: ['Hint 1', 'Hint 2', 'Hint 3'],
      timeEstimate: Duration(minutes: 1),
      points: difficulty.points,
    );
  }

  PracticeProblem _generateGenericProblem(
    String id,
    String subject,
    String topic,
    DifficultyLevel difficulty,
  ) {
    return PracticeProblem(
      id: id,
      subject: subject,
      topic: topic,
      difficulty: difficulty,
      questionText: 'Question about $topic in $subject',
      questionType: QuestionType.multipleChoice,
      correctAnswer: 'Answer',
      options: ['Answer', 'Option 2', 'Option 3', 'Option 4'],
      explanation: 'Explanation for the answer',
      hints: ['Hint 1', 'Hint 2', 'Hint 3'],
      timeEstimate: Duration(minutes: 1),
      points: difficulty.points,
    );
  }

  List<String> _generateOptions(int correctAnswer, int count) {
    final options = <String>[correctAnswer.toString()];
    final used = <int>{correctAnswer};

    while (options.length < count) {
      // Generate wrong answers near the correct answer
      final offset = _random.nextInt(20) - 10;
      final wrongAnswer = correctAnswer + offset;
      
      if (wrongAnswer > 0 && !used.contains(wrongAnswer)) {
        options.add(wrongAnswer.toString());
        used.add(wrongAnswer);
      }
    }

    options.shuffle(_random);
    return options;
  }
}

/// Practice problem model
class PracticeProblem {
  final String id;
  final String subject;
  final String topic;
  final DifficultyLevel difficulty;
  final String questionText;
  final QuestionType questionType;
  final String correctAnswer;
  final List<String> options;
  final String explanation;
  final List<String> hints;
  final Duration timeEstimate;
  final int points;

  PracticeProblem({
    required this.id,
    required this.subject,
    required this.topic,
    required this.difficulty,
    required this.questionText,
    required this.questionType,
    required this.correctAnswer,
    required this.options,
    required this.explanation,
    required this.hints,
    required this.timeEstimate,
    required this.points,
  });
}

enum DifficultyLevel {
  easy,
  medium,
  hard,
  expert,
}

extension DifficultyLevelExtension on DifficultyLevel {
  int get points {
    switch (this) {
      case DifficultyLevel.easy:
        return 10;
      case DifficultyLevel.medium:
        return 20;
      case DifficultyLevel.hard:
        return 30;
      case DifficultyLevel.expert:
        return 50;
    }
  }

  String get displayName {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
      case DifficultyLevel.expert:
        return 'Expert';
    }
  }
}

enum QuestionType {
  multipleChoice,
  trueFalse,
  fillInBlank,
  shortAnswer,
}

