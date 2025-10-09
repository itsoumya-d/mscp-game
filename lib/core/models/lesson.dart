import 'package:sp/core/models/subject.dart';
import 'package:sp/core/models/question.dart';

/// Basic lesson model for compatibility with existing code
class Lesson {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final bool isCompleted;
  final List<Question> questions;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.isCompleted,
    required this.questions,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'xpReward': xpReward,
        'isCompleted': isCompleted,
        'questions': questions.map((e) => e.toJson()).toList(),
      };

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        xpReward: json['xpReward'],
        isCompleted: json['isCompleted'],
        questions: (json['questions'] as List).map((e) => Question.fromJson(e)).toList(),
      );

  Lesson copyWith({
    String? id,
    String? title,
    String? description,
    int? xpReward,
    bool? isCompleted,
    List<Question>? questions,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      questions: questions ?? this.questions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lesson &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          xpReward == other.xpReward &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      xpReward.hashCode ^
      isCompleted.hashCode;

  @override
  String toString() {
    return 'Lesson{id: $id, title: $title, description: $description, xpReward: $xpReward, isCompleted: $isCompleted, questions: ${questions.length}}';
  }
}