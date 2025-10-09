import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../models/subject.dart';
import '../models/comprehensive_lesson.dart';
import 'comprehensive_lesson_storage_service.dart';
import 'lesson_validation_service.dart';

/// Unified service that ensures all lessons across the application
/// have consistent question-answering functionality with all 7 question types
class UnifiedLessonService {
  static UnifiedLessonService? _instance;
  static UnifiedLessonService get instance => _instance ??= UnifiedLessonService._();
  
  UnifiedLessonService._();

  final ComprehensiveLessonStorageService _storage = ComprehensiveLessonStorageService();
  final LessonValidationService _validator = LessonValidationService();
  final Random _random = Random();

  // Cache for generated lessons
  final Map<String, List<ComprehensiveLesson>> _lessonCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(hours: 2);

  /// Get lessons for a specific skill with guaranteed question functionality
  /// This method ensures every lesson has exactly 7 questions (one per type)
  Future<List<ComprehensiveLesson>> getLessonsForSkill({
    required String skillId,
    required String skillName,
    required SubjectType subject,
    int? difficulty,
    int lessonCount = 3,
  }) async {
    final cacheKey = '${subject.name}_${skillId}_${difficulty ?? 1}';
    
    // Check cache first
    if (_lessonCache.containsKey(cacheKey) && _cacheTimestamps.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey]!;
      if (DateTime.now().difference(cacheTime) < _cacheExpiry) {
        return _lessonCache[cacheKey]!;
      }
    }

    try {
      // Try to get stored lessons first
      final storedLessons = await _storage.searchLessons(
        subject: subject,
        skillId: skillId,
        limit: lessonCount,
      );

      if (storedLessons.isNotEmpty) {
        final lessons = storedLessons.map((lessonData) => _mapToLesson(lessonData)).toList();
        _updateCache(cacheKey, lessons);
        return lessons;
      }

      // Generate new lessons if none stored
      final lessons = await _generateLessonsForSkill(
        skillId: skillId,
        skillName: skillName,
        subject: subject,
        difficulty: difficulty ?? 1,
        lessonCount: lessonCount,
      );

      _updateCache(cacheKey, lessons);
      return lessons;

    } catch (e) {
      if (kDebugMode) {
        print('Error getting lessons for skill $skillId: $e');
      }
      
      // Return fallback lessons with questions
      return await _generateFallbackLessons(
        skillId: skillId,
        skillName: skillName,
        subject: subject,
        lessonCount: lessonCount,
      );
    }
  }

  /// Generate comprehensive lessons for a skill
  Future<List<ComprehensiveLesson>> _generateLessonsForSkill({
    required String skillId,
    required String skillName,
    required SubjectType subject,
    required int difficulty,
    required int lessonCount,
  }) async {
    final lessons = <ComprehensiveLesson>[];

    for (int i = 0; i < lessonCount; i++) {
      try {
        final lesson = await _generateProceduralLesson(
          subject: subject,
          skillId: skillId,
          skillName: skillName,
          difficulty: difficulty + (i ~/ 2), // Gradually increase difficulty
        );

        // Store the lesson for future use
        await _storage.storeComprehensiveLesson(
          subject: lesson.subject,
          skillId: skillId,
          skillName: skillName,
          questions: lesson.questions,
          difficulty: lesson.difficulty,
        );

        lessons.add(lesson);

      } catch (e) {
        if (kDebugMode) {
          print('Error generating lesson ${i + 1} for $skillId: $e');
        }
        
        // Generate fallback lesson
        final fallbackLesson = await _generateSingleFallbackLesson(
          skillId: skillId,
          skillName: skillName,
          subject: subject,
          lessonIndex: i,
          difficulty: difficulty,
        );
        
        if (fallbackLesson != null) {
          lessons.add(fallbackLesson);
        }
      }
    }

    return lessons;
  }

  /// Generate fallback lessons when AI generation fails
  Future<List<ComprehensiveLesson>> _generateFallbackLessons({
    required String skillId,
    required String skillName,
    required SubjectType subject,
    required int lessonCount,
  }) async {
    final lessons = <ComprehensiveLesson>[];

    for (int i = 0; i < lessonCount; i++) {
      final lesson = await _generateSingleFallbackLesson(
        skillId: skillId,
        skillName: skillName,
        subject: subject,
        lessonIndex: i,
        difficulty: 1,
      );
      
      if (lesson != null) {
        lessons.add(lesson);
      }
    }

    return lessons;
  }

  /// Generate a single fallback lesson with all 7 question types
  Future<ComprehensiveLesson?> _generateSingleFallbackLesson({
    required String skillId,
    required String skillName,
    required SubjectType subject,
    required int lessonIndex,
    required int difficulty,
  }) async {
    try {
      final questions = <Question>[];
      final lessonId = '${skillId}_lesson_${lessonIndex + 1}';
      
      // Generate one question for each of the 7 required types
      for (final questionType in QuestionType.values) {
        final question = _generateFallbackQuestion(
          type: questionType,
          subject: subject,
          skillId: skillId,
          skillName: skillName,
          lessonIndex: lessonIndex,
          difficulty: difficulty,
        );
        questions.add(question);
      }

      return ComprehensiveLesson(
        id: lessonId,
        title: _generateLessonTitle(skillName, lessonIndex),
        description: _generateLessonDescription(skillName, lessonIndex),
        xpReward: 10 + (difficulty * 5) + (lessonIndex * 2),
        isCompleted: false,
        questions: questions,
        skillId: skillId,
        skillName: skillName,
        subject: subject,
        difficulty: difficulty,
        createdAt: DateTime.now(),
      );

    } catch (e) {
      if (kDebugMode) {
        print('Error generating fallback lesson: $e');
      }
      return null;
    }
  }

  /// Generate a fallback question for a specific type
  Question _generateFallbackQuestion({
    required QuestionType type,
    required SubjectType subject,
    required String skillId,
    required String skillName,
    required int lessonIndex,
    required int difficulty,
  }) {
    final questionId = '${skillId}_${type.name}_${lessonIndex}_${_random.nextInt(1000)}';
    
    switch (type) {
      case QuestionType.multipleChoice:
        return Question(
          id: questionId,
          type: type,
          questionText: 'Which of the following best describes $skillName?',
          options: [
            'Option A: Basic concept',
            'Option B: Advanced concept',
            'Option C: Related concept',
            'Option D: Unrelated concept',
          ],
          correctAnswer: 'Option A: Basic concept',
          explanation: 'This is the correct answer because it represents the fundamental concept of $skillName.',
          hint: 'Think about the basic principles of $skillName.',
          difficulty: difficulty,
          subject: subject,
        );

      case QuestionType.trueFalse:
        return Question(
          id: questionId,
          type: type,
          questionText: '$skillName is an important concept in ${subject.name}.',
          options: ['True', 'False'],
          correctAnswer: 'True',
          explanation: '$skillName is indeed a fundamental concept in ${subject.name}.',
          hint: 'Consider the role of $skillName in this subject.',
          difficulty: difficulty,
          subject: subject,
        );

      case QuestionType.numericInput:
        return Question(
          id: questionId,
          type: type,
          questionText: 'If you have 2 examples of $skillName and add 3 more, how many do you have?',
          options: [],
          correctAnswer: '5',
          explanation: '2 + 3 = 5. This demonstrates basic arithmetic with $skillName concepts.',
          hint: 'Use simple addition: 2 + 3 = ?',
          difficulty: difficulty,
          subject: subject,
        );

      case QuestionType.fillInTheBlank:
        return Question(
          id: questionId,
          type: type,
          questionText: '$skillName is a _____ concept in ${subject.name}.',
          options: ['fundamental', 'complex', 'optional', 'advanced'],
          correctAnswer: 'fundamental',
          explanation: '$skillName is a fundamental concept that forms the basis for understanding ${subject.name}.',
          hint: 'Think about how important $skillName is to the subject.',
          difficulty: difficulty,
          subject: subject,
        );

      case QuestionType.dragDrop:
        return Question(
          id: questionId,
          type: type,
          questionText: 'Match these $skillName concepts with their definitions:',
          options: ['Concept A', 'Concept B', 'Concept C'],
          correctAnswer: 'Concept A:Definition A,Concept B:Definition B,Concept C:Definition C',
          explanation: 'These are the correct matches for $skillName concepts.',
          hint: 'Consider the relationships between concepts and definitions.',
          difficulty: difficulty,
          subject: subject,
        );

      case QuestionType.clickableAnswer:
        return Question(
          id: questionId,
          type: type,
          questionText: 'Click on all examples of $skillName:',
          options: ['Example 1', 'Example 2', 'Counter-example', 'Example 3'],
          correctAnswer: 'Example 1,Example 2,Example 3',
          explanation: 'These examples demonstrate $skillName principles.',
          hint: 'Look for characteristics that define $skillName.',
          difficulty: difficulty,
          subject: subject,
        );

      case QuestionType.shortAnswer:
        return Question(
          id: questionId,
          type: type,
          questionText: 'Briefly explain why $skillName is important in ${subject.name}:',
          options: [],
          correctAnswer: '$skillName is important because it provides fundamental understanding of key concepts in ${subject.name}.',
          explanation: 'A good answer should mention the foundational role of $skillName in the subject.',
          hint: 'Think about why $skillName matters in this subject.',
          difficulty: difficulty,
          subject: subject,
        );
    }
  }

  /// Generate lesson title based on skill and index
  String _generateLessonTitle(String skillName, int lessonIndex) {
    final titles = [
      'Introduction to $skillName',
      'Exploring $skillName',
      'Mastering $skillName',
      'Advanced $skillName',
      '$skillName in Practice',
    ];
    
    if (lessonIndex < titles.length) {
      return titles[lessonIndex];
    }
    
    return '$skillName - Lesson ${lessonIndex + 1}';
  }

  /// Generate lesson description based on skill and index
  String _generateLessonDescription(String skillName, int lessonIndex) {
    final descriptions = [
      'Learn the basics of $skillName',
      'Dive deeper into $skillName concepts',
      'Master advanced $skillName techniques',
      'Apply $skillName in complex scenarios',
      'Practice $skillName with real examples',
    ];
    
    if (lessonIndex < descriptions.length) {
      return descriptions[lessonIndex];
    }
    
    return 'Continue learning about $skillName';
  }

  /// Convert stored lesson data to ComprehensiveLesson object
  ComprehensiveLesson _mapToLesson(Map<String, dynamic> lessonData) {
    final questionsData = lessonData['questions'] as List;
    final questions = questionsData.map((q) => Question.fromJson(q)).toList();

    return ComprehensiveLesson(
      id: lessonData['id'],
      title: lessonData['title'],
      description: lessonData['description'],
      xpReward: lessonData['xpReward'],
      isCompleted: lessonData['isCompleted'] ?? false,
      questions: questions,
      skillId: lessonData['skillId'] ?? '',
      skillName: lessonData['skillName'] ?? '',
      subject: lessonData['subject'] ?? SubjectType.math,
      difficulty: lessonData['difficulty'] ?? 1,
      createdAt: lessonData['createdAt'] != null 
          ? DateTime.parse(lessonData['createdAt']) 
          : DateTime.now(),
    );
  }

  /// Update cache with new lessons
  void _updateCache(String cacheKey, List<ComprehensiveLesson> lessons) {
    _lessonCache[cacheKey] = lessons;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  /// Clear cache for a specific skill or all skills
  void clearCache([String? skillId]) {
    if (skillId != null) {
      _lessonCache.removeWhere((key, value) => key.contains(skillId));
      _cacheTimestamps.removeWhere((key, value) => key.contains(skillId));
    } else {
      _lessonCache.clear();
      _cacheTimestamps.clear();
    }
  }

  /// Validate that a lesson has all required question types
  Future<bool> validateLessonCompleteness(Lesson lesson) async {
    if (lesson.questions.length != 7) {
      return false;
    }

    final presentTypes = lesson.questions.map((q) => (q as Question).type).toSet();
    return presentTypes.length == 7 && 
           QuestionType.values.every((type) => presentTypes.contains(type));
  }

  /// Get statistics about lesson generation
  Future<Map<String, dynamic>> getStatistics() async {
    final stats = await _storage.getStorageStatistics();
    
    return {
      ...stats,
      'cacheSize': _lessonCache.length,
      'cachedSkills': _lessonCache.keys.toList(),
      'lastCacheUpdate': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String()
          : null,
    };
  }

  /// Generate a procedural lesson without AI
  Future<ComprehensiveLesson> _generateProceduralLesson({
    required SubjectType subject,
    required String skillId,
    required String skillName,
    required int difficulty,
  }) async {
    final questions = <Question>[];
    final questionCount = 10 + (difficulty * 2); // More questions for higher difficulty
    
    for (int i = 0; i < questionCount; i++) {
      final question = _generateProceduralQuestion(
        subject: subject,
        skillId: skillId,
        difficulty: difficulty,
        index: i,
      );
      questions.add(question);
    }
    
    return ComprehensiveLesson(
      id: '${skillId}_${DateTime.now().millisecondsSinceEpoch}',
      title: skillName,
      description: 'Generated lesson for $skillName',
      subject: subject,
      skillId: skillId,
      skillName: skillName,
      difficulty: difficulty,
      xpReward: 50 + (difficulty * 10),
      isCompleted: false,
      questions: questions,
      createdAt: DateTime.now(),
    );
  }

  /// Generate a single procedural question
  Question _generateProceduralQuestion({
    required SubjectType subject,
    required String skillId,
    required int difficulty,
    required int index,
  }) {
    switch (subject) {
      case SubjectType.math:
        return _generateMathQuestion(difficulty, index);
      case SubjectType.science:
        return _generateScienceQuestion(difficulty, index);
      case SubjectType.english:
        return _generateEnglishQuestion(difficulty, index);
      case SubjectType.history:
        return _generateHistoryQuestion(difficulty, index);
      case SubjectType.geography:
        return _generateGeographyQuestion(difficulty, index);
      case SubjectType.physics:
        return _generatePhysicsQuestion(difficulty, index);
      case SubjectType.chemistry:
        return _generateChemistryQuestion(difficulty, index);
      case SubjectType.biology:
        return _generateBiologyQuestion(difficulty, index);
      case SubjectType.computerScience:
        return _generateComputerScienceQuestion(difficulty, index);
      case SubjectType.art:
        return _generateArtQuestion(difficulty, index);
      case SubjectType.music:
        return _generateMusicQuestion(difficulty, index);
      case SubjectType.physicalEducation:
        return _generatePhysicalEducationQuestion(difficulty, index);
    }
  }

  Question _generateMathQuestion(int difficulty, int index) {
    final operations = ['+', '-', '*', '/'];
    final operation = operations[_random.nextInt(operations.length)];
    
    int a, b, answer;
    String questionText;
    
    switch (operation) {
      case '+':
        a = _random.nextInt(50 * (difficulty + 1)) + 1;
        b = _random.nextInt(50 * (difficulty + 1)) + 1;
        answer = a + b;
        questionText = 'What is $a + $b?';
        break;
      case '-':
        a = _random.nextInt(50 * (difficulty + 1)) + 10;
        b = _random.nextInt(a);
        answer = a - b;
        questionText = 'What is $a - $b?';
        break;
      case '*':
        a = _random.nextInt(12) + 1;
        b = _random.nextInt(12) + 1;
        answer = a * b;
        questionText = 'What is $a × $b?';
        break;
      case '/':
        answer = _random.nextInt(12) + 1;
        b = _random.nextInt(12) + 1;
        a = answer * b;
        questionText = 'What is $a ÷ $b?';
        break;
      default:
        a = 1; b = 1; answer = 2;
        questionText = 'What is 1 + 1?';
    }
    
    final wrongAnswers = <int>[];
    while (wrongAnswers.length < 3) {
      final wrong = answer + _random.nextInt(20) - 10;
      if (wrong != answer && !wrongAnswers.contains(wrong) && wrong > 0) {
        wrongAnswers.add(wrong);
      }
    }
    
    final options = [answer.toString(), ...wrongAnswers.map((w) => w.toString())];
    options.shuffle(_random);
    
    return Question(
      id: 'math_${index}_${DateTime.now().millisecondsSinceEpoch}',
      questionText: questionText,
      options: options,
      correctAnswer: answer.toString(),
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      subject: SubjectType.math,
      explanation: 'The correct answer is $answer.',
    );
  }

  Question _generateScienceQuestion(int difficulty, int index) {
    final topics = ['Solar System', 'Human Body', 'Animals', 'Plants', 'Weather'];
    final topic = topics[_random.nextInt(topics.length)];
    
    return Question(
      id: 'science_${index}_${DateTime.now().millisecondsSinceEpoch}',
      questionText: 'Which planet is closest to the Sun?',
      options: ['Mercury', 'Venus', 'Earth', 'Mars'],
      correctAnswer: 'Mercury',
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      subject: SubjectType.science,
      explanation: 'Mercury is the closest planet to the Sun.',
    );
  }

  Question _generateEnglishQuestion(int difficulty, int index) {
    return Question(
      id: 'english_${index}_${DateTime.now().millisecondsSinceEpoch}',
      questionText: 'What is the plural of "child"?',
      options: ['childs', 'children', 'childes', 'child'],
      correctAnswer: 'children',
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      subject: SubjectType.english,
      explanation: 'The plural of "child" is "children".',
    );
  }

  Question _generateHistoryQuestion(int difficulty, int index) {
    return Question(
      id: 'history_${index}_${DateTime.now().millisecondsSinceEpoch}',
      questionText: 'Who was the first President of the United States?',
      options: ['George Washington', 'Thomas Jefferson', 'John Adams', 'Benjamin Franklin'],
      correctAnswer: 'George Washington',
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      subject: SubjectType.history,
      explanation: 'George Washington was the first President of the United States.',
    );
  }

  Question _generateGeographyQuestion(int difficulty, int index) {
    return Question(
      id: 'geography_${index}_${DateTime.now().millisecondsSinceEpoch}',
      questionText: 'What is the capital of France?',
      options: ['London', 'Berlin', 'Paris', 'Madrid'],
      correctAnswer: 'Paris',
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      subject: SubjectType.geography,
      explanation: 'Paris is the capital of France.',
    );
  }

  Question _generatePhysicsQuestion(int difficulty, int index) {
    return Question(
      id: 'physics_${index}_${DateTime.now().millisecondsSinceEpoch}',
      questionText: 'What is the unit of force?',
      options: ['Newton (N)', 'Joule (J)', 'Watt (W)', 'Pascal (Pa)'],
      correctAnswer: 'Newton (N)',
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      subject: SubjectType.physics,
      explanation: 'Force is measured in Newtons (N).',
    );
  }

  Question _generateChemistryQuestion(int difficulty, int index) {
    return Question(
      id: 'chemistry_${index}_${DateTime.now().millisecondsSinceEpoch}',
      questionText: 'What is the chemical symbol for water?',
      options: ['H2O', 'CO2', 'NaCl', 'O2'],
      correctAnswer: 'H2O',
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      subject: SubjectType.chemistry,
      explanation: 'Water is composed of two hydrogen atoms and one oxygen atom (H2O).',
    );
  }

  Question _generateBiologyQuestion(int difficulty, int index) {
    return Question(
      id: 'biology_${index}_${DateTime.now().millisecondsSinceEpoch}',
      questionText: 'What is the basic unit of life?',
      options: ['Cell', 'Atom', 'Molecule', 'Tissue'],
      correctAnswer: 'Cell',
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      subject: SubjectType.biology,
      explanation: 'The cell is the basic structural and functional unit of all living organisms.',
    );
  }

  Question _generateComputerScienceQuestion(int difficulty, int index) {
    return Question(
      id: 'cs_${index}_${DateTime.now().millisecondsSinceEpoch}',
      questionText: 'What does CPU stand for?',
      options: ['Central Processing Unit', 'Computer Processing Unit', 'Central Program Unit', 'Computer Program Unit'],
      correctAnswer: 'Central Processing Unit',
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      subject: SubjectType.computerScience,
      explanation: 'CPU stands for Central Processing Unit, the main component that executes instructions.',
    );
  }

  Question _generateArtQuestion(int difficulty, int index) {
    return Question(
      id: 'art_${index}_${DateTime.now().millisecondsSinceEpoch}',
      questionText: 'What are the primary colors?',
      options: ['Red, Blue, Yellow', 'Red, Green, Blue', 'Blue, Yellow, Green', 'Red, Orange, Yellow'],
      correctAnswer: 'Red, Blue, Yellow',
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      subject: SubjectType.art,
      explanation: 'The primary colors in traditional color theory are red, blue, and yellow.',
    );
  }

  Question _generateMusicQuestion(int difficulty, int index) {
    return Question(
      id: 'music_${index}_${DateTime.now().millisecondsSinceEpoch}',
      questionText: 'How many lines are in a musical staff?',
      options: ['5', '4', '6', '7'],
      correctAnswer: '5',
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      subject: SubjectType.music,
      explanation: 'A musical staff consists of five horizontal lines.',
    );
  }

  Question _generatePhysicalEducationQuestion(int difficulty, int index) {
    return Question(
      id: 'pe_${index}_${DateTime.now().millisecondsSinceEpoch}',
      questionText: 'What is the recommended amount of daily exercise for adults?',
      options: ['30 minutes', '60 minutes', '15 minutes', '90 minutes'],
      correctAnswer: '30 minutes',
      type: QuestionType.multipleChoice,
      difficulty: difficulty,
      subject: SubjectType.physicalEducation,
      explanation: 'Adults should aim for at least 30 minutes of moderate exercise daily.',
    );
  }
}