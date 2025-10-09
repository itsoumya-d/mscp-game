import 'subject.dart';

enum QuestionType { 
  multipleChoice, 
  numericInput, 
  dragDrop, 
  trueFalse, 
  fillInTheBlank, 
  clickableAnswer,
  shortAnswer 
}

class Question {
  final String id;
  final QuestionType type;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String? hint;
  final int difficulty;
  final SubjectType subject;

  const Question({
    required this.id,
    required this.type,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.hint,
    this.difficulty = 1,
    required this.subject,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'questionText': questionText,
        'options': options,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
        'hint': hint,
        'difficulty': difficulty,
        'subject': subject.name,
      };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'],
        type: QuestionType.values.firstWhere((e) => e.name == json['type']),
        questionText: json['questionText'],
        options: List<String>.from(json['options']),
        correctAnswer: json['correctAnswer'],
        explanation: json['explanation'],
        hint: json['hint'],
        difficulty: json['difficulty'] ?? 1,
        subject: SubjectType.values.firstWhere((e) => e.name == json['subject']),
      );

  Question copyWith({
    String? id,
    QuestionType? type,
    String? questionText,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    String? hint,
    int? difficulty,
    SubjectType? subject,
  }) {
    return Question(
      id: id ?? this.id,
      type: type ?? this.type,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      hint: hint ?? this.hint,
      difficulty: difficulty ?? this.difficulty,
      subject: subject ?? this.subject,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Question &&
        other.id == id &&
        other.type == type &&
        other.questionText == questionText &&
        other.options.toString() == options.toString() &&
        other.correctAnswer == correctAnswer &&
        other.explanation == explanation &&
        other.hint == hint &&
        other.difficulty == difficulty &&
        other.subject == subject;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      type,
      questionText,
      options,
      correctAnswer,
      explanation,
      hint,
      difficulty,
      subject,
    );
  }

  @override
  String toString() {
    return 'Question(id: $id, type: $type, questionText: $questionText, '
           'options: $options, correctAnswer: $correctAnswer, '
           'explanation: $explanation, hint: $hint, difficulty: $difficulty, '
           'subject: $subject)';
  }
}