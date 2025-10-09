import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/educational_game.dart';
import '../models/question.dart';

/// Service for managing predefined educational games and content
class PredefinedGamesService {
  static const String _gamesKey = 'predefined_games';
  static const String _syllabusKey = 'subject_syllabus';
  static const String _progressKey = 'user_progress';

  /// Get all games for a specific subject
  Future<List<EducationalGame>> getGamesForSubject(SubjectType subject) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gamesJson = prefs.getString('${_gamesKey}_${subject.name}');

      if (gamesJson != null) {
        final List<dynamic> gamesList = json.decode(gamesJson);
        return gamesList.map((json) => EducationalGame.fromJson(json)).toList();
      }

      // Return default games if none cached
      return _getDefaultGamesForSubject(subject);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[PredefinedGamesService] Error loading games for ${subject.name}: $e');
      }
      return _getDefaultGamesForSubject(subject);
    }
  }

  /// Save games for a specific subject
  Future<void> saveGamesForSubject(
      SubjectType subject, List<EducationalGame> games) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gamesJson =
          json.encode(games.map((game) => game.toJson()).toList());
      await prefs.setString('${_gamesKey}_${subject.name}', gamesJson);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[PredefinedGamesService] Error saving games for ${subject.name}: $e');
      }
    }
  }

  /// Get syllabus for a specific subject
  Future<GameSyllabus> getSyllabusForSubject(SubjectType subject) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syllabusJson = prefs.getString('${_syllabusKey}_${subject.name}');

      if (syllabusJson != null) {
        return GameSyllabus.fromJson(json.decode(syllabusJson));
      }

      // Return default syllabus if none cached
      return _getDefaultSyllabusForSubject(subject);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[PredefinedGamesService] Error loading syllabus for ${subject.name}: $e');
      }
      return _getDefaultSyllabusForSubject(subject);
    }
  }

  /// Save syllabus for a specific subject
  Future<void> saveSyllabusForSubject(
      SubjectType subject, GameSyllabus syllabus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          '${_syllabusKey}_${subject.name}', json.encode(syllabus.toJson()));
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[PredefinedGamesService] Error saving syllabus for ${subject.name}: $e');
      }
    }
  }

  /// Get user progress for all subjects
  Future<Map<SubjectType, UserProgress>> getUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_progressKey);

      if (progressJson != null) {
        final Map<String, dynamic> progressMap = json.decode(progressJson);
        return progressMap.map((key, value) => MapEntry(
              SubjectType.values.firstWhere((s) => s.name == key),
              UserProgress.fromJson(value),
            ));
      }

      // Return default progress for all subjects
      return _getDefaultUserProgress();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PredefinedGamesService] Error loading user progress: $e');
      }
      return _getDefaultUserProgress();
    }
  }

  /// Save user progress
  Future<void> saveUserProgress(Map<SubjectType, UserProgress> progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressMap =
          progress.map((key, value) => MapEntry(key.name, value.toJson()));
      await prefs.setString(_progressKey, json.encode(progressMap));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PredefinedGamesService] Error saving user progress: $e');
      }
    }
  }

  /// Get default games for a subject (fallback content)
  List<EducationalGame> _getDefaultGamesForSubject(SubjectType subject) {
    switch (subject) {
      case SubjectType.math:
        return _getMathGames();
      case SubjectType.science:
        return _getScienceGames();
      case SubjectType.english:
        return _getEnglishGames();
      case SubjectType.history:
        return _getHistoryGames();
      case SubjectType.geography:
        return _getGeographyGames();
      case SubjectType.physicalEducation:
        return _getPhysicalEducationGames();
      default:
        return [];
    }
  }

  /// Get default syllabus for a subject
  GameSyllabus _getDefaultSyllabusForSubject(SubjectType subject) {
    final games = _getDefaultGamesForSubject(subject);
    final chapters = _organizeGamesIntoChapters(games, subject);
    
    return GameSyllabus(
      id: '${subject.name}_syllabus',
      subject: subject,
      title: _getSubjectDisplayName(subject),
      description: 'Complete syllabus for ${_getSubjectDisplayName(subject)}',
      chapters: chapters,
      totalXpReward: chapters.fold(0, (sum, chapter) => sum + chapter.totalXpReward),
      createdAt: DateTime.now(),
    );
  }

  /// Get default user progress for all subjects
  Map<SubjectType, UserProgress> _getDefaultUserProgress() {
    return Map.fromEntries(
      SubjectType.values.map((subject) => MapEntry(
            subject,
            UserProgress(
              userId: 'default_user',
              subject: subject,
              currentLevel: 1,
              totalXp: 0,
              completedLessons: <String, bool>{},
              completedChapters: <String, bool>{},
              lastActivity: DateTime.now(),
              subjectXp: <String, int>{},
            ),
          )),
    );
  }

  /// Organize games into chapters and lessons
  List<GameChapter> _organizeGamesIntoChapters(
      List<EducationalGame> games, SubjectType subject) {
    final Map<int, List<EducationalGame>> gamesByLevel = {};

    for (final game in games) {
      gamesByLevel.putIfAbsent(game.level, () => []).add(game);
    }

    return gamesByLevel.entries.map((entry) {
      final level = entry.key;
      final levelGames = entry.value;
      final lessons = _organizeGamesIntoLessons(levelGames);

      return GameChapter(
        id: '${subject.name}_chapter_$level',
        title: 'Level $level',
        description:
            'Level $level content for ${_getSubjectDisplayName(subject)}',
        subject: subject,
        lessons: lessons,
        totalXpReward:
            lessons.fold(0, (sum, lesson) => sum + lesson.totalXpReward),
        isUnlocked: level == 1,
      );
    }).toList();
  }

  /// Organize games into lessons
  List<GameLesson> _organizeGamesIntoLessons(List<EducationalGame> games) {
    const gamesPerLesson = 3;
    final lessons = <GameLesson>[];

    for (int i = 0; i < games.length; i += gamesPerLesson) {
      final lessonGames = games.skip(i).take(gamesPerLesson).toList();
      final lessonNumber = (i ~/ gamesPerLesson) + 1;
      
      // Get subject from the first game in the lesson
      final subject = lessonGames.isNotEmpty ? lessonGames.first.subject : SubjectType.math;

      lessons.add(GameLesson(
        id: 'lesson_$lessonNumber',
        title: 'Lesson $lessonNumber',
        description: 'Practice lesson $lessonNumber',
        subject: subject,
        level: lessonGames.isNotEmpty ? lessonGames.first.level : 1,
        games: lessonGames,
        totalXpReward: lessonGames.fold(0, (sum, game) => sum + game.xpReward),
        prerequisites: [],
        isUnlocked: lessonNumber == 1,
      ));
    }

    return lessons;
  }

  /// Get subject display name
  String _getSubjectDisplayName(SubjectType subject) {
    switch (subject) {
      case SubjectType.math:
        return 'Mathematics';
      case SubjectType.science:
        return 'Science';
      case SubjectType.english:
        return 'English';
      case SubjectType.history:
        return 'History';
      case SubjectType.geography:
        return 'Geography';
      case SubjectType.physicalEducation:
        return 'Physical Education';
      default:
        return subject.name;
    }
  }

  /// Get mathematics games
  List<EducationalGame> _getMathGames() {
    return [
      EducationalGame(
        id: 'math_basic_arithmetic_1',
        title: 'Basic Arithmetic',
        description: 'Learn addition and subtraction',
        subject: SubjectType.math,
        level: 1,
        xpReward: 10,
        difficulty: GameDifficulty.beginner,
        learningObjectives: ['Basic addition', 'Basic subtraction'],
        estimatedTime: Duration(minutes: 5),
        questions: _generateBasicArithmeticQuestions(),
      ),
      EducationalGame(
        id: 'math_multiplication_1',
        title: 'Multiplication Basics',
        description: 'Learn multiplication tables',
        subject: SubjectType.math,
        level: 2,
        xpReward: 15,
        difficulty: GameDifficulty.beginner,
        learningObjectives: ['Multiplication tables', 'Times tables'],
        estimatedTime: Duration(minutes: 7),
        questions: _generateMultiplicationQuestions(),
      ),
    ];
  }

  /// Get science games
  List<EducationalGame> _getScienceGames() {
    return [
      EducationalGame(
        id: 'science_basic_biology_1',
        title: 'Basic Biology',
        description: 'Learn about living organisms',
        subject: SubjectType.science,
        level: 1,
        xpReward: 10,
        difficulty: GameDifficulty.beginner,
        learningObjectives: ['Cell structure', 'Living vs non-living'],
        estimatedTime: Duration(minutes: 5),
        questions: _generateBasicBiologyQuestions(),
      ),
    ];
  }

  /// Get English games
  List<EducationalGame> _getEnglishGames() {
    return [
      EducationalGame(
        id: 'english_vocabulary_1',
        title: 'Basic Vocabulary',
        description: 'Learn common English words',
        subject: SubjectType.english,
        level: 1,
        xpReward: 10,
        difficulty: GameDifficulty.beginner,
        learningObjectives: ['Common words', 'Word meanings'],
        estimatedTime: Duration(minutes: 5),
        questions: _generateVocabularyQuestions(),
      ),
    ];
  }

  /// Get history games
  List<EducationalGame> _getHistoryGames() {
    return [
      EducationalGame(
        id: 'history_ancient_civilizations_1',
        title: 'Ancient Civilizations',
        description: 'Learn about ancient cultures',
        subject: SubjectType.history,
        level: 1,
        xpReward: 10,
        difficulty: GameDifficulty.beginner,
        learningObjectives: ['Ancient Egypt', 'Ancient Greece'],
        estimatedTime: Duration(minutes: 5),
        questions: _generateAncientCivilizationsQuestions(),
      ),
    ];
  }

  /// Get geography games
  List<EducationalGame> _getGeographyGames() {
    return [
      EducationalGame(
        id: 'geography_world_capitals_1',
        title: 'World Capitals',
        description: 'Learn capital cities of countries',
        subject: SubjectType.geography,
        level: 1,
        xpReward: 10,
        difficulty: GameDifficulty.beginner,
        learningObjectives: ['Capital cities', 'Country locations'],
        estimatedTime: Duration(minutes: 5),
        questions: _generateWorldCapitalsQuestions(),
      ),
    ];
  }

  /// Get physical education games
  List<EducationalGame> _getPhysicalEducationGames() {
    return [
      EducationalGame(
        id: 'pe_fitness_basics_1',
        title: 'Fitness Basics',
        description: 'Learn about health and fitness',
        subject: SubjectType.physicalEducation,
        level: 1,
        xpReward: 10,
        difficulty: GameDifficulty.beginner,
        learningObjectives: ['Exercise benefits', 'Healthy habits'],
        estimatedTime: Duration(minutes: 5),
        questions: _generateFitnessBasicsQuestions(),
      ),
    ];
  }

  // Question generation methods
  List<GameQuestion> _generateBasicArithmeticQuestions() {
    return [
      GameQuestion(
        id: 'math_add_1',
        type: QuestionType.multipleChoice,
        questionText: 'What is 2 + 3?',
        options: ['4', '5', '6', '7'],
        correctAnswer: '5',
        explanation: '2 + 3 equals 5',
      ),
      GameQuestion(
        id: 'math_sub_1',
        type: QuestionType.multipleChoice,
        questionText: 'What is 10 - 4?',
        options: ['5', '6', '7', '8'],
        correctAnswer: '6',
        explanation: '10 - 4 equals 6',
      ),
    ];
  }

  List<GameQuestion> _generateMultiplicationQuestions() {
    return [
      GameQuestion(
        id: 'math_mult_1',
        type: QuestionType.multipleChoice,
        questionText: 'What is 3 × 4?',
        options: ['10', '11', '12', '13'],
        correctAnswer: '12',
        explanation: '3 × 4 equals 12',
      ),
    ];
  }

  List<GameQuestion> _generateBasicBiologyQuestions() {
    return [
      GameQuestion(
        id: 'bio_cell_1',
        type: QuestionType.multipleChoice,
        questionText: 'What is the basic unit of life?',
        options: ['Atom', 'Cell', 'Molecule', 'Organ'],
        correctAnswer: 'Cell',
        explanation: 'The cell is the basic unit of life',
      ),
    ];
  }

  List<GameQuestion> _generateVocabularyQuestions() {
    return [
      GameQuestion(
        id: 'eng_vocab_1',
        type: QuestionType.multipleChoice,
        questionText: 'What does "happy" mean?',
        options: ['Sad', 'Joyful', 'Angry', 'Tired'],
        correctAnswer: 'Joyful',
        explanation: 'Happy means feeling joyful or pleased',
      ),
    ];
  }

  List<GameQuestion> _generateAncientCivilizationsQuestions() {
    return [
      GameQuestion(
        id: 'hist_egypt_1',
        type: QuestionType.multipleChoice,
        questionText: 'Which river was important to ancient Egypt?',
        options: ['Amazon', 'Nile', 'Mississippi', 'Thames'],
        correctAnswer: 'Nile',
        explanation: 'The Nile River was crucial to ancient Egyptian civilization',
      ),
    ];
  }

  List<GameQuestion> _generateWorldCapitalsQuestions() {
    return [
      GameQuestion(
        id: 'geo_capital_1',
        type: QuestionType.multipleChoice,
        questionText: 'What is the capital of France?',
        options: ['London', 'Berlin', 'Paris', 'Rome'],
        correctAnswer: 'Paris',
        explanation: 'Paris is the capital city of France',
      ),
    ];
  }

  List<GameQuestion> _generateFitnessBasicsQuestions() {
    return [
      GameQuestion(
        id: 'pe_fitness_1',
        type: QuestionType.multipleChoice,
        questionText: 'How many minutes of exercise per day is recommended?',
        options: ['10', '20', '30', '60'],
        correctAnswer: '30',
        explanation: '30 minutes of daily exercise is recommended for good health',
      ),
    ];
  }
}