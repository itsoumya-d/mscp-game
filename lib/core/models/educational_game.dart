import 'package:sp/core/models/subject.dart';
import 'package:sp/core/models/question.dart';

/// Represents a structured educational game with pre-defined content
class EducationalGame {
  final String id;
  final String title;
  final String description;
  final SubjectType subject;
  final int level;
  final String? skillId;  // Added skillId field
  final int xpReward;
  final List<GameQuestion> questions;
  final GameDifficulty difficulty;
  final List<String> learningObjectives;
  final Duration estimatedTime;
  final bool isUnlocked;

  const EducationalGame({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.level,
    this.skillId,  // Added skillId parameter
    required this.xpReward,
    required this.questions,
    required this.difficulty,
    required this.learningObjectives,
    required this.estimatedTime,
    this.isUnlocked = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'subject': subject.name,
        'level': level,
        'skillId': skillId,  // Added skillId to JSON
        'xpReward': xpReward,
        'questions': questions.map((q) => q.toJson()).toList(),
        'difficulty': difficulty.name,
        'learningObjectives': learningObjectives,
        'estimatedTime': estimatedTime.inMinutes,
        'isUnlocked': isUnlocked,
      };

  factory EducationalGame.fromJson(Map<String, dynamic> json) => EducationalGame(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        subject: SubjectType.values.firstWhere((e) => e.name == json['subject']),
        level: json['level'],
        skillId: json['skillId'],  // Added skillId from JSON
        xpReward: json['xpReward'],
        questions: (json['questions'] as List)
            .map((q) => GameQuestion.fromJson(q))
            .toList(),
        difficulty: GameDifficulty.values.firstWhere((e) => e.name == json['difficulty']),
        learningObjectives: List<String>.from(json['learningObjectives']),
        estimatedTime: Duration(minutes: json['estimatedTime']),
        isUnlocked: json['isUnlocked'] ?? false,
      );
}

/// Represents a question within an educational game
class GameQuestion {
  final String id;
  final QuestionType type;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String? hint;
  final Map<String, dynamic>? metadata;

  const GameQuestion({
    required this.id,
    required this.type,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.hint,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'questionText': questionText,
        'options': options,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
        'hint': hint,
        'metadata': metadata,
      };

  factory GameQuestion.fromJson(Map<String, dynamic> json) => GameQuestion(
        id: json['id'],
        type: QuestionType.values.firstWhere((e) => e.name == json['type']),
        questionText: json['questionText'],
        options: List<String>.from(json['options']),
        correctAnswer: json['correctAnswer'],
        explanation: json['explanation'],
        hint: json['hint'],
        metadata: json['metadata'],
      );

  /// Create GameQuestion from Question model
  factory GameQuestion.fromQuestion(Question question) => GameQuestion(
        id: question.id,
        type: question.type,
        questionText: question.questionText,
        options: question.options,
        correctAnswer: question.correctAnswer,
        explanation: question.explanation ?? '',
        hint: question.hint,
        metadata: null,
      );
}

/// Represents a lesson containing multiple educational games
class GameLesson {
  final String id;
  final String title;
  final String description;
  final SubjectType subject;
  final int level;
  final List<EducationalGame> games;
  final int totalXpReward;
  final List<String> prerequisites;
  final bool isUnlocked;
  final bool isCompleted;

  const GameLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.level,
    required this.games,
    required this.totalXpReward,
    required this.prerequisites,
    this.isUnlocked = false,
    this.isCompleted = false,
  });

  double get completionPercentage {
    if (games.isEmpty) return 0.0;
    final completedGames = games.where((g) => g.isUnlocked).length;
    return (completedGames / games.length) * 100;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'subject': subject.name,
        'level': level,
        'games': games.map((g) => g.toJson()).toList(),
        'totalXpReward': totalXpReward,
        'prerequisites': prerequisites,
        'isUnlocked': isUnlocked,
        'isCompleted': isCompleted,
      };

  factory GameLesson.fromJson(Map<String, dynamic> json) => GameLesson(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        subject: SubjectType.values.firstWhere((e) => e.name == json['subject']),
        level: json['level'],
        games: (json['games'] as List)
            .map((g) => EducationalGame.fromJson(g))
            .toList(),
        totalXpReward: json['totalXpReward'],
        prerequisites: List<String>.from(json['prerequisites']),
        isUnlocked: json['isUnlocked'] ?? false,
        isCompleted: json['isCompleted'] ?? false,
      );
}

/// Represents a chapter containing multiple lessons
class GameChapter {
  final String id;
  final String title;
  final String description;
  final SubjectType subject;
  final List<GameLesson> lessons;
  final int totalXpReward;
  final bool isUnlocked;
  final bool isCompleted;

  const GameChapter({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.lessons,
    required this.totalXpReward,
    this.isUnlocked = false,
    this.isCompleted = false,
  });

  double get completionPercentage {
    if (lessons.isEmpty) return 0.0;
    final totalCompletion = lessons.fold<double>(
      0.0,
      (sum, lesson) => sum + lesson.completionPercentage,
    );
    return totalCompletion / lessons.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'subject': subject.name,
        'lessons': lessons.map((l) => l.toJson()).toList(),
        'totalXpReward': totalXpReward,
        'isUnlocked': isUnlocked,
        'isCompleted': isCompleted,
      };

  factory GameChapter.fromJson(Map<String, dynamic> json) => GameChapter(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        subject: SubjectType.values.firstWhere((e) => e.name == json['subject']),
        lessons: (json['lessons'] as List)
            .map((l) => GameLesson.fromJson(l))
            .toList(),
        totalXpReward: json['totalXpReward'],
        isUnlocked: json['isUnlocked'] ?? false,
        isCompleted: json['isCompleted'] ?? false,
      );
}

/// Represents the complete syllabus for a subject
class GameSyllabus {
  final String id;
  final SubjectType subject;
  final String title;
  final String description;
  final List<GameChapter> chapters;
  final int totalXpReward;
  final DateTime createdAt;
  final DateTime? lastUpdated;

  const GameSyllabus({
    required this.id,
    required this.subject,
    required this.title,
    required this.description,
    required this.chapters,
    required this.totalXpReward,
    required this.createdAt,
    this.lastUpdated,
  });

  double get completionPercentage {
    if (chapters.isEmpty) return 0.0;
    final totalCompletion = chapters.fold<double>(
      0.0,
      (sum, chapter) => sum + chapter.completionPercentage,
    );
    return totalCompletion / chapters.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject.name,
        'title': title,
        'description': description,
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'totalXpReward': totalXpReward,
        'createdAt': createdAt.toIso8601String(),
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  factory GameSyllabus.fromJson(Map<String, dynamic> json) => GameSyllabus(
        id: json['id'],
        subject: SubjectType.values.firstWhere((e) => e.name == json['subject']),
        title: json['title'],
        description: json['description'],
        chapters: (json['chapters'] as List)
            .map((c) => GameChapter.fromJson(c))
            .toList(),
        totalXpReward: json['totalXpReward'],
        createdAt: DateTime.parse(json['createdAt']),
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'])
            : null,
      );
}

/// Difficulty levels for educational games
enum GameDifficulty {
  beginner,
  intermediate,
  advanced,
  expert,
}

/// Progress tracking for user's educational journey
class UserProgress {
  final String userId;
  final SubjectType subject;
  final int currentLevel;
  final int totalXp;
  final Map<String, bool> completedLessons;
  final Map<String, bool> completedChapters;
  final DateTime lastActivity;
  final Map<String, int> subjectXp;

  const UserProgress({
    required this.userId,
    required this.subject,
    required this.currentLevel,
    required this.totalXp,
    required this.completedLessons,
    required this.completedChapters,
    required this.lastActivity,
    required this.subjectXp,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'subject': subject.name,
        'currentLevel': currentLevel,
        'totalXp': totalXp,
        'completedLessons': completedLessons,
        'completedChapters': completedChapters,
        'lastActivity': lastActivity.toIso8601String(),
        'subjectXp': subjectXp,
      };

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
        userId: json['userId'],
        subject: SubjectType.values.firstWhere((e) => e.name == json['subject']),
        currentLevel: json['currentLevel'],
        totalXp: json['totalXp'],
        completedLessons: Map<String, bool>.from(json['completedLessons']),
        completedChapters: Map<String, bool>.from(json['completedChapters']),
        lastActivity: DateTime.parse(json['lastActivity']),
        subjectXp: Map<String, int>.from(json['subjectXp']),
      );
}