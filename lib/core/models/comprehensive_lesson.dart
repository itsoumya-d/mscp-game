import 'package:sp/core/models/subject.dart';
import 'package:sp/core/models/question.dart';

/// Comprehensive lesson model that ensures all 7 question types are included
class ComprehensiveLesson {
  final String id;
  final String title;
  final String description;
  final SubjectType subject;
  final String skillId;
  final String skillName;
  final int difficulty;
  final int xpReward;
  final bool isCompleted;
  final List<Question> questions;
  final DateTime createdAt;
  final DateTime? lastAccessed;
  final int accessCount;
  final Map<String, dynamic> metadata;

  const ComprehensiveLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.skillId,
    required this.skillName,
    required this.difficulty,
    required this.xpReward,
    required this.isCompleted,
    required this.questions,
    required this.createdAt,
    this.lastAccessed,
    this.accessCount = 0,
    this.metadata = const {},
  });

  /// Convert to regular Lesson for compatibility
  Lesson toLesson() {
    return Lesson(
      id: id,
      title: title,
      description: description,
      xpReward: xpReward,
      isCompleted: isCompleted,
      questions: questions,
    );
  }

  /// Create from regular Lesson
  factory ComprehensiveLesson.fromLesson(
    Lesson lesson, {
    required SubjectType subject,
    required String skillId,
    required String skillName,
    required int difficulty,
    DateTime? createdAt,
    DateTime? lastAccessed,
    int accessCount = 0,
    Map<String, dynamic> metadata = const {},
  }) {
    return ComprehensiveLesson(
      id: lesson.id,
      title: lesson.title,
      description: lesson.description,
      subject: subject,
      skillId: skillId,
      skillName: skillName,
      difficulty: difficulty,
      xpReward: lesson.xpReward,
      isCompleted: lesson.isCompleted,
      questions: lesson.questions,
      createdAt: createdAt ?? DateTime.now(),
      lastAccessed: lastAccessed,
      accessCount: accessCount,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'subject': subject.name,
        'skillId': skillId,
        'skillName': skillName,
        'difficulty': difficulty,
        'xpReward': xpReward,
        'isCompleted': isCompleted,
        'questions': questions.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'lastAccessed': lastAccessed?.toIso8601String(),
        'accessCount': accessCount,
        'metadata': metadata,
      };

  factory ComprehensiveLesson.fromJson(Map<String, dynamic> json) => ComprehensiveLesson(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        subject: SubjectType.values.firstWhere((e) => e.name == json['subject']),
        skillId: json['skillId'],
        skillName: json['skillName'],
        difficulty: json['difficulty'],
        xpReward: json['xpReward'],
        isCompleted: json['isCompleted'],
        questions: (json['questions'] as List).map((e) => Question.fromJson(e)).toList(),
        createdAt: DateTime.parse(json['createdAt']),
        lastAccessed: json['lastAccessed'] != null ? DateTime.parse(json['lastAccessed']) : null,
        accessCount: json['accessCount'] ?? 0,
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      );

  ComprehensiveLesson copyWith({
    String? id,
    String? title,
    String? description,
    SubjectType? subject,
    String? skillId,
    String? skillName,
    int? difficulty,
    int? xpReward,
    bool? isCompleted,
    List<Question>? questions,
    DateTime? createdAt,
    DateTime? lastAccessed,
    int? accessCount,
    Map<String, dynamic>? metadata,
  }) {
    return ComprehensiveLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      skillId: skillId ?? this.skillId,
      skillName: skillName ?? this.skillName,
      difficulty: difficulty ?? this.difficulty,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      accessCount: accessCount ?? this.accessCount,
      metadata: metadata ?? this.metadata,
    );
  }
}