import 'question.dart';

enum SubjectType { 
  math, 
  physics, 
  chemistry, 
  biology, 
  computerScience, 
  geography, 
  history,
  science,
  english,
  art,
  music,
  physicalEducation
}

class Subject {
  final String id;
  final String name;
  final SubjectType type;
  final String description;
  final String iconUrl;
  final List<Unit> units;
  final int totalSkills;
  final int completedSkills;

  const Subject({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.iconUrl,
    required this.units,
    required this.totalSkills,
    required this.completedSkills,
  });

  double get progressPercentage => 
      totalSkills > 0 ? (completedSkills / totalSkills * 100) : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'description': description,
        'iconUrl': iconUrl,
        'units': units.map((e) => e.toJson()).toList(),
        'totalSkills': totalSkills,
        'completedSkills': completedSkills,
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'],
        name: json['name'],
        type: SubjectType.values.firstWhere((e) => e.name == json['type']),
        description: json['description'],
        iconUrl: json['iconUrl'],
        units: (json['units'] as List).map((e) => Unit.fromJson(e)).toList(),
        totalSkills: json['totalSkills'],
        completedSkills: json['completedSkills'],
      );
}

class Unit {
  final String id;
  final String name;
  final String description;
  final List<Skill> skills;
  final bool isUnlocked;

  const Unit({
    required this.id,
    required this.name,
    required this.description,
    required this.skills,
    required this.isUnlocked,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'skills': skills.map((e) => e.toJson()).toList(),
        'isUnlocked': isUnlocked,
      };

  factory Unit.fromJson(Map<String, dynamic> json) => Unit(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        skills: (json['skills'] as List).map((e) => Skill.fromJson(e)).toList(),
        isUnlocked: json['isUnlocked'],
      );
}

class Skill {
  final String id;
  final String name;
  final String description;
  final int crowns;
  final int maxCrowns;
  final bool isUnlocked;
  final List<Lesson> lessons;

  const Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.crowns,
    required this.maxCrowns,
    required this.isUnlocked,
    required this.lessons,
  });

  bool get isCompleted => crowns >= maxCrowns;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'crowns': crowns,
        'maxCrowns': maxCrowns,
        'isUnlocked': isUnlocked,
        'lessons': lessons.map((e) => e.toJson()).toList(),
      };

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        crowns: json['crowns'],
        maxCrowns: json['maxCrowns'],
        isUnlocked: json['isUnlocked'],
        lessons: (json['lessons'] as List).map((e) => Lesson.fromJson(e)).toList(),
      );
}

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
        'questions': questions.map((e) => (e as Question).toJson()).toList(),
      };

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        xpReward: json['xpReward'],
        isCompleted: json['isCompleted'],
        questions: (json['questions'] as List).map((e) => Question.fromJson(e)).toList(),
      );
}
