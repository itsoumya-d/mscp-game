import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../models/subject.dart';
import '../models/question_pool.dart';
import '../models/lesson.dart';
import '../utils/question_validator.dart';
import 'game_save_service.dart';
import 'skill_id_registry.dart';

import 'fallback_content_preloader.dart';
import 'progressive_difficulty_service.dart';
import 'predefined_games_manager.dart';
import 'unified_lesson_service.dart';
import 'lesson_validation_service.dart';
import 'level_preloader_service.dart';
import 'smart_cache_service.dart';
import 'analytics_service.dart';

/// Service for managing 7-question game sessions with dynamic generation
class GameSessionService {
  static const String _currentGameKey = 'current_seven_question_game';
  static const String _gameHistoryKey = 'seven_question_game_history';
  static const String _comprehensiveSessionsKey = 'comprehensive_game_sessions';
  
  // Default constructor
  GameSessionService();
  
  final GameSaveService _gameSaveService = GameSaveService();
  final ProgressiveDifficultyService _progressiveDifficultyService = ProgressiveDifficultyService.getInstance();
  final PredefinedGamesManager _predefinedGamesManager = PredefinedGamesManager.getInstance();
  final UnifiedLessonService _comprehensiveGenerator = UnifiedLessonService.instance;
  final LessonValidationService _validationService = LessonValidationService();
  final LevelPreloaderService _preloaderService = LevelPreloaderService.getInstance();
  final FallbackContentPreloader _fallbackPreloader = FallbackContentPreloader.getInstance();
  final SmartCacheService _smartCache = SmartCacheService.getInstance();
  final AnalyticsService _analyticsService = AnalyticsService();

  /// Create a new 7-question game session with comprehensive lesson generation
  Future<SevenQuestionGameSession> createGameSession({
    required SubjectType subject,
    required int level,
    String? skillId,
    bool useComprehensiveGeneration = true,
  }) async {
    try {
      // Check smart cache first
      final cacheKey = '${subject.name}_${skillId ?? _getDefaultSkillForSubject(subject)}_$level';
      final cachedSession = _smartCache.getSession(cacheKey);
      if (cachedSession != null) {
        debugPrint('[GameSessionService] Using cached session for ${subject.name} Level $level');
        await _saveCurrentSession(cachedSession);
        return cachedSession;
      }

      // PRIORITY 1: Try fallback content preloader FIRST (instant, no API calls)
      final fallbackSession = await _fallbackPreloader.getPreloadedContent(
        subject: subject,
        skillId: skillId ?? _getDefaultSkillForSubject(subject),
        level: level,
      );

      if (fallbackSession != null) {
        debugPrint('[GameSessionService] Using fallback preloaded content for ${subject.name} Level $level');
        _smartCache.cacheSession(cacheKey, fallbackSession); // Cache it
        await _saveCurrentSession(fallbackSession);
        return fallbackSession;
      }

      // PRIORITY 2: Try to get cached levels from preloader service
      final preloaderSession = await _preloaderService.getCachedGameSession(subject, level);
      if (preloaderSession != null) {
        debugPrint('[GameSessionService] Using preloader cached session for ${subject.name} Level $level');
        await _saveCurrentSession(preloaderSession);
        // Trigger background preloading for next levels
        _preloaderService.preloadLevelsInBackground(subject, level + 1);
        return preloaderSession;
      }

      // PRIORITY 3: Try comprehensive lesson generation if enabled (requires API)
      if (useComprehensiveGeneration) {
        final comprehensiveSession = await _createComprehensiveSession(subject, level, skillId);
        if (comprehensiveSession != null) {
          debugPrint('[GameSessionService] Using comprehensive session for ${subject.name} Level $level');
          await _saveCurrentSession(comprehensiveSession);
          // Cache this session for future use
          await _preloaderService.cacheGameSession(subject, level, comprehensiveSession);
          return comprehensiveSession;
        }
      }

      // PRIORITY 4: Use predefined games manager to get structured educational content
      final session = await _predefinedGamesManager.getPredefinedGameSession(
        subject: subject,
        level: level,
        skillId: skillId,
      );

      debugPrint('[GameSessionService] Using predefined game session for ${subject.name} Level $level');
      await _saveCurrentSession(session);
      // Cache this session for future use
      await _preloaderService.cacheGameSession(subject, level, session);
      return session;
    } catch (e) {
      debugPrint('[GameSessionService] Error creating game session: $e');

      // Fallback to original adaptive generation if all methods fail
      return _createFallbackSession(subject, level, skillId);
    }
  }

  /// Get default skill for a subject using the centralized SkillIdRegistry
  String _getDefaultSkillForSubject(SubjectType subject) {
    // Use the centralized SkillIdRegistry to ensure consistency
    return SkillIdRegistry.getDefaultSkillId(subject);
  }

  /// Create a comprehensive game session with all 7 question types
  Future<SevenQuestionGameSession?> _createComprehensiveSession(
    SubjectType subject,
    int level,
    String? skillId,
  ) async {
    try {
      // Generate comprehensive lesson with all 7 question types
      final lessons = await _comprehensiveGenerator.getLessonsForSkill(
        skillId: skillId ?? 'game_session_${DateTime.now().millisecondsSinceEpoch}',
        skillName: '${_getSubjectDisplayName(subject)} Game Session Level $level',
        subject: subject,
        difficulty: level,
        lessonCount: 1,
      );

      if (lessons.isEmpty) {
        return null;
      }

      final lesson = lessons.first;

      // Validate the lesson
      final validation = await _validationService.validateLesson(
        questions: lesson.questions,
        subject: subject,
        skillId: skillId ?? 'game_session',
        difficulty: level,
      );

      if (!validation.isValid) {
        debugPrint('Comprehensive lesson validation failed: ${validation.recommendations.join(', ')}');
        return null;
      }

      // Convert lesson to game session
      final session = SevenQuestionGameSession(
        id: lesson.id,
        subject: subject,
        level: level,
        skillId: skillId ?? 'comprehensive_game',
        questions: lesson.questions,
        userAnswers: List.filled(7, ''),
        answerCorrectness: List.filled(7, false),
        currentQuestionIndex: 0,
        startTime: DateTime.now(),
        score: 0,
        isCompleted: false,
        endTime: null,
      );

      // Store comprehensive session for analytics
      await _storeComprehensiveSession(session, validation);

      debugPrint('Created comprehensive game session with validation score: ${validation.overallScore}');
      return session;

    } catch (e) {
      debugPrint('Error creating comprehensive session: $e');
      return null;
    }
  }

  /// Store comprehensive session data for analytics and tracking
  Future<void> _storeComprehensiveSession(
    SevenQuestionGameSession session,
    LessonValidationResult validation,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingSessions = prefs.getStringList(_comprehensiveSessionsKey) ?? [];
      
      final sessionData = {
        'id': session.id,
        'subject': session.subject.name,
        'level': session.level,
        'createdAt': session.startTime.toIso8601String(),
        'validationScore': validation.overallScore,
        'questionTypes': session.questions.map((q) => (q as Question).type.name).toList(),
        'isValid': validation.isValid,
      };

      existingSessions.add(jsonEncode(sessionData));
      
      // Keep only last 50 sessions to prevent storage bloat
      if (existingSessions.length > 50) {
        existingSessions.removeRange(0, existingSessions.length - 50);
      }

      await prefs.setStringList(_comprehensiveSessionsKey, existingSessions);
    } catch (e) {
      debugPrint('Error storing comprehensive session: $e');
    }
  }

  /// Get subject display name for UI
  String _getSubjectDisplayName(SubjectType subject) {
    switch (subject) {
      case SubjectType.math:
        return 'Mathematics';
      case SubjectType.physics:
        return 'Physics';
      case SubjectType.chemistry:
        return 'Chemistry';
      case SubjectType.biology:
        return 'Biology';
      case SubjectType.science:
        return 'Science';
      case SubjectType.english:
        return 'English';
      case SubjectType.history:
        return 'History';
      case SubjectType.geography:
        return 'Geography';
      case SubjectType.art:
        return 'Art';
      case SubjectType.music:
        return 'Music';
      case SubjectType.physicalEducation:
        return 'Physical Education';
      case SubjectType.computerScience:
        return 'Computer Science';
    }
  }

  /// Fallback method to create session using original adaptive generation
  Future<SevenQuestionGameSession> _createFallbackSession(
    SubjectType subject, 
    int level, 
    String? skillId
  ) async {
    // Generate exactly 7 questions with adaptive difficulty and focus areas
    final questions = await _generateAdaptiveSevenQuestions(subject, level, skillId);
    
    final session = SevenQuestionGameSession(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      subject: subject,
      level: level,
      skillId: skillId ?? 'general',
      questions: questions,
      userAnswers: List.filled(7, ''),
      answerCorrectness: List.filled(7, false),
      currentQuestionIndex: 0,
      startTime: DateTime.now(),
      score: 0,
      isCompleted: false,
      endTime: null,
    );

    await _saveCurrentSession(session);
    return session;
  }

  /// Generate exactly 7 questions with adaptive difficulty and focus on weak areas
  Future<List<Question>> _generateAdaptiveSevenQuestions(SubjectType subject, int level, String? skillId) async {
    try {
      // Get adaptive recommendations to identify weak areas
      final recommendations = await _progressiveDifficultyService.getAdaptiveRecommendations(subject);

      final focusAreas = recommendations['focusAreas'] as List<String>? ?? [];
      final adaptiveDifficulty = recommendations['recommendedDifficulty'] as int? ?? level;

      // Calculate difficulty based on adaptive level
      final difficulty = _calculateDifficulty(adaptiveDifficulty);

      // Generate adaptive questions using manual template-based generation
      final validatedQuestions = <Question>[];
      
      // Generate 7 questions using fallback method (now primary method)
      for (int i = 0; i < 7; i++) {
        final fallbackQuestion = _generateAdaptiveFallbackQuestion(
          subject,
          difficulty,
          focusAreas,
          i + 1
        );

        // Validate the question
        final validationResult = QuestionValidator.validateQuestion(fallbackQuestion);
        if (validationResult.isValid) {
          validatedQuestions.add(fallbackQuestion);
        } else {
          final fixed = QuestionValidator.fixQuestion(fallbackQuestion);
          if (QuestionValidator.isQuestionValid(fixed)) {
            validatedQuestions.add(fixed);
          }
        }
      }

      return validatedQuestions;
    } catch (e) {
      debugPrint('Error generating adaptive questions via API: $e');
    }

    // Fallback: generate 7 questions locally with adaptive focus
    final fallbackQuestions = await _generateAdaptiveFallbackQuestions(subject, level, skillId);
    return QuestionValidator.validateAndFixQuestions(fallbackQuestions);
  }

  /// Generate exactly 7 questions for the session
  Future<List<Question>> _generateSevenQuestions(SubjectType subject, int level) async {
    try {
      // Calculate difficulty based on level (1-100)
      final difficulty = _calculateDifficulty(level);

      // Generate 7 questions using manual template-based approach
      final validatedQuestions = <Question>[];
      
      for (int i = 0; i < 7; i++) {
        final fallbackQuestion = _generateFallbackQuestion(
          subject,
          difficulty,
          i + 1
        );

        // Validate the question
        final validationResult = QuestionValidator.validateQuestion(fallbackQuestion);
        if (validationResult.isValid) {
          validatedQuestions.add(fallbackQuestion);
        } else {
          final fixed = QuestionValidator.fixQuestion(fallbackQuestion);
          if (QuestionValidator.isQuestionValid(fixed)) {
            validatedQuestions.add(fixed);
          } else {
            // If fixing fails, create a basic valid question
            validatedQuestions.add(_generateBasicQuestion(subject, difficulty, i + 1));
          }
        }
      }

      return validatedQuestions;
    } catch (e) {
      debugPrint('Error generating questions via API: $e');
    }

    // Fallback: generate 7 questions locally
    final fallbackQuestions = _generateFallbackQuestions(subject, level);
    return QuestionValidator.validateAndFixQuestions(fallbackQuestions);
  }

  /// Calculate difficulty based on level (1-100)
  int _calculateDifficulty(int level) {
    if (level <= 20) return 1; // Beginner
    if (level <= 40) return 2; // Easy
    if (level <= 60) return 3; // Medium
    if (level <= 80) return 4; // Hard
    return 5; // Expert
  }

  /// Convert API response to Question object
  Question _convertToQuestion(dynamic questionData, SubjectType subject, int difficulty) {
    final Map<String, dynamic> qMap = questionData is Map<String, dynamic> 
        ? questionData 
        : {'question': questionData.toString()};

    return Question(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      type: _determineQuestionType(qMap),
      questionText: qMap['question'] ?? qMap['questionText'] ?? 'Sample question',
      options: _extractOptions(qMap),
      correctAnswer: qMap['correctAnswer'] ?? qMap['answer'] ?? '1',
      explanation: qMap['explanation'] ?? 'Explanation not provided',
      hint: qMap['hint'] ?? 'Think carefully about the problem',
      difficulty: difficulty,
      subject: subject,
    );
  }

  /// Determine question type from question data
  QuestionType _determineQuestionType(Map<String, dynamic> qMap) {
    final questionText = (qMap['question'] ?? qMap['questionText'] ?? '').toString().toLowerCase();
    
    if (qMap['options'] != null && qMap['options'] is List) {
      return QuestionType.multipleChoice;
    }
    if (questionText.contains('true') && questionText.contains('false')) {
      return QuestionType.trueFalse;
    }
    if (questionText.contains('fill') || questionText.contains('blank')) {
      return QuestionType.fillInTheBlank;
    }
    if (questionText.contains('number') || questionText.contains('calculate')) {
      return QuestionType.numericInput;
    }
    
    return QuestionType.multipleChoice; // Default
  }

  /// Extract options from question data
  List<String> _extractOptions(Map<String, dynamic> qMap) {
    if (qMap['options'] != null && qMap['options'] is List) {
      return List<String>.from(qMap['options']);
    }
    
    // Generate default options for multiple choice
    return ['Option A', 'Option B', 'Option C', 'Option D'];
  }

  /// Generate fallback questions when API fails
  List<Question> _generateFallbackQuestions(SubjectType subject, int level) {
    final questions = <Question>[];
    final difficulty = _calculateDifficulty(level);
    
    for (int i = 0; i < 7; i++) {
      questions.add(_generateFallbackQuestion(subject, difficulty, i + 1));
    }
    
    return questions;
  }

  /// Generate a single fallback question
  Question _generateFallbackQuestion(SubjectType subject, int difficulty, int questionNumber) {
    final questionTemplates = _getQuestionTemplates(subject, difficulty);
    final template = questionTemplates[questionNumber % questionTemplates.length];
    
    return Question(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}_$questionNumber',
      type: template['type'],
      questionText: template['question'],
      options: template['options'],
      correctAnswer: template['correctAnswer'],
      explanation: template['explanation'],
      hint: template['hint'],
      difficulty: difficulty,
      subject: subject,
    );
  }

  /// Generate a basic valid question as a last resort
  Question _generateBasicQuestion(SubjectType subject, int difficulty, int questionNumber) {
    // Create a simple, guaranteed valid question based on subject
    switch (subject) {
      case SubjectType.math:
        return Question(
          id: 'basic_math_${DateTime.now().millisecondsSinceEpoch}_$questionNumber',
          type: QuestionType.multipleChoice,
          questionText: 'What is 1 + 1?',
          options: ['1', '2', '3', '4'],
          correctAnswer: '2',
          explanation: '1 + 1 equals 2',
          hint: 'Add the two numbers together',
          difficulty: difficulty,
          subject: subject,
        );
      case SubjectType.physics:
        return Question(
          id: 'basic_physics_${DateTime.now().millisecondsSinceEpoch}_$questionNumber',
          type: QuestionType.trueFalse,
          questionText: 'Gravity pulls objects downward.',
          options: ['True', 'False'],
          correctAnswer: 'True',
          explanation: 'Gravity is a force that pulls objects toward Earth.',
          hint: 'Think about what happens when you drop something.',
          difficulty: difficulty,
          subject: subject,
        );
      case SubjectType.chemistry:
        return Question(
          id: 'basic_chemistry_${DateTime.now().millisecondsSinceEpoch}_$questionNumber',
          type: QuestionType.multipleChoice,
          questionText: 'What is the chemical symbol for water?',
          options: ['H2O', 'CO2', 'NaCl', 'O2'],
          correctAnswer: 'H2O',
          explanation: 'Water is composed of two hydrogen atoms and one oxygen atom.',
          hint: 'Think about hydrogen and oxygen.',
          difficulty: difficulty,
          subject: subject,
        );
      case SubjectType.biology:
        return Question(
          id: 'basic_biology_${DateTime.now().millisecondsSinceEpoch}_$questionNumber',
          type: QuestionType.trueFalse,
          questionText: 'Plants need sunlight to grow.',
          options: ['True', 'False'],
          correctAnswer: 'True',
          explanation: 'Plants use sunlight for photosynthesis to make their food.',
          hint: 'Think about what plants need for photosynthesis.',
          difficulty: difficulty,
          subject: subject,
        );
      default:
        return Question(
          id: 'basic_general_${DateTime.now().millisecondsSinceEpoch}_$questionNumber',
          type: QuestionType.multipleChoice,
          questionText: 'What color do you get when you mix red and blue?',
          options: ['Green', 'Purple', 'Yellow', 'Orange'],
          correctAnswer: 'Purple',
          explanation: 'Red and blue combine to make purple.',
          hint: 'Think about primary color mixing.',
          difficulty: difficulty,
          subject: subject,
        );
    }
  }

  /// Get question templates for fallback generation
  List<Map<String, dynamic>> _getQuestionTemplates(SubjectType subject, int difficulty) {
    switch (subject) {
      case SubjectType.math:
        return _getMathTemplates(difficulty);
      case SubjectType.physics:
        return _getPhysicsTemplates(difficulty);
      case SubjectType.chemistry:
        return _getChemistryTemplates(difficulty);
      case SubjectType.biology:
        return _getBiologyTemplates(difficulty);
      case SubjectType.science:
        return _getScienceTemplates(difficulty);
      case SubjectType.english:
        return _getEnglishTemplates(difficulty);
      case SubjectType.history:
        return _getHistoryTemplates(difficulty);
      case SubjectType.geography:
        return _getGeographyTemplates(difficulty);
      case SubjectType.art:
        return _getArtTemplates(difficulty);
      case SubjectType.music:
        return _getMusicTemplates(difficulty);
      case SubjectType.physicalEducation:
        return _getPhysicalEducationTemplates(difficulty);
      case SubjectType.computerScience:
        return _getComputerScienceTemplates(difficulty);
    }
  }

  /// Math question templates
  List<Map<String, dynamic>> _getMathTemplates(int difficulty) {
    return [
      {
        'type': QuestionType.multipleChoice,
        'question': 'What is 2 + 2?',
        'options': ['3', '4', '5', '6'],
        'correctAnswer': '4',
        'explanation': '2 + 2 equals 4',
        'hint': 'Add the two numbers together',
      },
      {
        'type': QuestionType.numericInput,
        'question': 'Calculate: 5 × 3',
        'options': [],
        'correctAnswer': '15',
        'explanation': '5 multiplied by 3 equals 15',
        'hint': 'Multiply the two numbers',
      },
      // Add more math templates...
    ];
  }

  /// Computer Science question templates
  List<Map<String, dynamic>> _getComputerScienceTemplates(int difficulty) {
    return [
      {
        'type': QuestionType.multipleChoice,
        'question': 'What is a variable in programming?',
        'options': ['A storage location', 'A function', 'A loop', 'A condition'],
        'correctAnswer': 'A storage location',
        'explanation': 'A variable is a storage location with an associated name that contains data.',
        'difficulty': difficulty,
        'subject': 'Computer Science',
      },
    ];
  }

  /// Geography question templates
  List<Map<String, dynamic>> _getGeographyTemplates(int difficulty) {
    return [
      {
        'type': QuestionType.multipleChoice,
        'question': 'What is the capital of France?',
        'options': ['London', 'Berlin', 'Paris', 'Madrid'],
        'correctAnswer': 'Paris',
        'explanation': 'Paris is the capital and largest city of France.',
        'difficulty': difficulty,
        'subject': 'Geography',
      },
    ];
  }

  /// History question templates
  List<Map<String, dynamic>> _getHistoryTemplates(int difficulty) {
    return [
      {
        'type': QuestionType.multipleChoice,
        'question': 'In which year did World War II end?',
        'options': ['1944', '1945', '1946', '1947'],
        'correctAnswer': '1945',
        'explanation': 'World War II ended in 1945 with the surrender of Japan.',
        'difficulty': difficulty,
        'subject': 'History',
      },
    ];
  }

  /// General question templates (fallback)
  List<Map<String, dynamic>> _getGeneralTemplates(int difficulty) {
    return [
      {
        'type': QuestionType.multipleChoice,
        'question': 'What is 1 + 1?',
        'options': ['1', '2', '3', '4'],
        'correctAnswer': '2',
        'explanation': 'Basic addition: 1 + 1 = 2',
        'difficulty': difficulty,
        'subject': 'General',
      },
    ];
  }

  /// Physics question templates
  List<Map<String, dynamic>> _getPhysicsTemplates(int difficulty) {
    return [
      {
        'type': QuestionType.multipleChoice,
        'question': 'What is the unit of force?',
        'options': ['Newton', 'Joule', 'Watt', 'Pascal'],
        'correctAnswer': 'Newton',
        'explanation': 'Newton is the SI unit of force',
        'hint': 'Think about Newton\'s laws',
      },
      // Add more physics templates...
    ];
  }

  /// Chemistry question templates
  List<Map<String, dynamic>> _getChemistryTemplates(int difficulty) {
    return [
      {
        'type': QuestionType.multipleChoice,
        'question': 'What is the chemical symbol for water?',
        'options': ['H2O', 'CO2', 'NaCl', 'O2'],
        'correctAnswer': 'H2O',
        'explanation': 'Water is composed of two hydrogen atoms and one oxygen atom',
        'hint': 'Think about hydrogen and oxygen',
      },
      // Add more chemistry templates...
    ];
  }

  /// Biology question templates
  List<Map<String, dynamic>> _getBiologyTemplates(int difficulty) {
    return [
      {
        'type': QuestionType.multipleChoice,
        'question': 'What is the powerhouse of the cell?',
        'options': ['Nucleus', 'Mitochondria', 'Ribosome', 'Golgi apparatus'],
        'correctAnswer': 'Mitochondria',
        'explanation': 'Mitochondria produce ATP, the energy currency of cells',
        'hint': 'Think about cellular energy production',
      },
      // Add more biology templates...
    ];
  }

  /// Submit answer for current question
  Future<AnswerResult> submitAnswer(String answer) async {
    final session = await getCurrentSession();
    if (session == null || session.isCompleted) {
      throw Exception('No active game session');
    }

    final currentQuestion = session.questions[session.currentQuestionIndex];
    final isCorrect = _checkAnswer(currentQuestion, answer);
    
    // Update session with answer
    final updatedAnswers = List<String>.from(session.userAnswers);
    updatedAnswers[session.currentQuestionIndex] = answer;
    
    final updatedCorrectness = List<bool>.from(session.answerCorrectness);
    updatedCorrectness[session.currentQuestionIndex] = isCorrect;
    
    final newScore = isCorrect ? session.score + 1 : session.score;
    
    final updatedSession = session.copyWith(
      userAnswers: updatedAnswers,
      answerCorrectness: updatedCorrectness,
      score: newScore,
    );

    await _saveCurrentSession(updatedSession);

    return AnswerResult(
      isCorrect: isCorrect,
      correctAnswer: currentQuestion.correctAnswer,
      explanation: currentQuestion.explanation,
      currentScore: newScore,
      totalQuestions: 7,
    );
  }

  /// Move to next question
  Future<bool> nextQuestion() async {
    final session = await getCurrentSession();
    if (session == null) return false;

    if (session.currentQuestionIndex < 6) {
      final updatedSession = session.copyWith(
        currentQuestionIndex: session.currentQuestionIndex + 1,
      );
      await _saveCurrentSession(updatedSession);
      return true;
    }
    
    return false;
  }

  /// Complete the game session
  Future<GameResult> completeSession() async {
    final session = await getCurrentSession();
    if (session == null) {
      throw Exception('No active game session');
    }

    final completedSession = session.copyWith(
      isCompleted: true,
      endTime: DateTime.now(),
    );

    // Save to history
    await _saveToHistory(completedSession);
    
    // Clear current session
    await _clearCurrentSession();

    // Calculate final results
    final result = GameResult(
      sessionId: completedSession.id,
      subject: completedSession.subject,
      level: completedSession.level,
      totalQuestions: 7,
      correctAnswers: completedSession.score,
      finalScore: (completedSession.score / 7 * 100).round(),
      timeSpent: completedSession.endTime!.difference(completedSession.startTime),
      questionsAndAnswers: List.generate(7, (index) => QuestionAnswer(
        question: completedSession.questions[index],
        userAnswer: completedSession.userAnswers[index],
        isCorrect: completedSession.answerCorrectness[index],
      )),
    );

    return result;
  }

  /// Check if answer is correct
  bool _checkAnswer(Question question, String answer) {
    return answer.trim().toLowerCase() == 
           question.correctAnswer.trim().toLowerCase();
  }

  /// Get current active session
  Future<SevenQuestionGameSession?> getCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_currentGameKey);
    
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString);
        return SevenQuestionGameSession.fromJson(json);
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }

  /// Save current session
  Future<void> _saveCurrentSession(SevenQuestionGameSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentGameKey, jsonEncode(session.toJson()));
  }

  /// Clear current session
  Future<void> _clearCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentGameKey);
  }

  /// Save completed session to history
  Future<void> _saveToHistory(SevenQuestionGameSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_gameHistoryKey);
    
    List<Map<String, dynamic>> history = [];
    if (historyJson != null) {
      try {
        history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
      } catch (e) {
        history = [];
      }
    }
    
    history.insert(0, session.toJson());
    
    // Keep only last 50 sessions
    if (history.length > 50) {
      history = history.take(50).toList();
    }
    
    await prefs.setString(_gameHistoryKey, jsonEncode(history));
  }

  /// Get game history
  Future<List<SevenQuestionGameSession>> getGameHistory({int limit = 20}) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_gameHistoryKey);

    if (historyJson != null) {
      try {
        final history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
        return history
            .take(limit)
            .map((json) => SevenQuestionGameSession.fromJson(json))
            .toList();
      } catch (e) {
        return [];
      }
    }

    return [];
  }

  /// Clear all AI-generated questions and cached content
  /// This is part of Phase B: Delete Existing Bad Questions
  Future<Map<String, dynamic>> clearAllGeneratedQuestions({
    bool clearHistory = false,
    bool clearCurrentSession = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      int clearedCount = 0;
      final clearedKeys = <String>[];

      // Patterns to match for AI-generated content
      final patternsToDelete = [
        'ai_pool_',                          // AI question pools
        'cached_session_',                   // Cached game sessions
        'preloaded_',                        // Preloaded content
        'comprehensive_lessons_cache_',      // Comprehensive lessons
        'enhanced_daily_generation',         // Daily generation tracking
        'enhanced_generation_stats',         // Generation statistics
        'level_preload_',                    // Level preloader cache
        'unlimited_levels_',                 // Unlimited level generator cache
      ];

      // Clear keys matching patterns
      for (final key in allKeys) {
        bool shouldDelete = false;

        // Check if key matches any deletion pattern
        for (final pattern in patternsToDelete) {
          if (key.startsWith(pattern)) {
            shouldDelete = true;
            break;
          }
        }

        // Also clear comprehensive sessions
        if (key == _comprehensiveSessionsKey) {
          shouldDelete = true;
        }

        // Optionally clear history
        if (clearHistory && key == _gameHistoryKey) {
          shouldDelete = true;
        }

        // Optionally clear current session
        if (clearCurrentSession && key == _currentGameKey) {
          shouldDelete = true;
        }

        if (shouldDelete) {
          await prefs.remove(key);
          clearedKeys.add(key);
          clearedCount++;
        }
      }

      // Clear in-memory caches
      _smartCache.clearAll();
      _fallbackPreloader.clearCache();

      // Log results
      if (kDebugMode) {
        debugPrint('🗑️ [Cache Clearing] Cleared $clearedCount cache entries');
        debugPrint('🗑️ [Cache Clearing] Patterns cleared: ${patternsToDelete.join(', ')}');
        if (clearedKeys.length <= 20) {
          debugPrint('🗑️ [Cache Clearing] Keys cleared: ${clearedKeys.join(', ')}');
        } else {
          debugPrint('🗑️ [Cache Clearing] Sample keys: ${clearedKeys.take(20).join(', ')}...');
        }
      }

      // Track in analytics
      _analyticsService.trackEvent('cache_cleared', {
        'cleared_count': clearedCount,
        'cleared_history': clearHistory,
        'cleared_current_session': clearCurrentSession,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'cleared_count': clearedCount,
        'cleared_keys': clearedKeys,
        'message': 'Successfully cleared $clearedCount AI-generated question cache entries',
      };
    } catch (e) {
      debugPrint('❌ [Cache Clearing] Error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to clear cache: $e',
      };
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      int aiPoolCount = 0;
      int cachedSessionCount = 0;
      int preloadedCount = 0;
      int comprehensiveLessonCount = 0;
      int otherCacheCount = 0;

      for (final key in allKeys) {
        if (key.startsWith('ai_pool_')) {
          aiPoolCount++;
        } else if (key.startsWith('cached_session_')) {
          cachedSessionCount++;
        } else if (key.startsWith('preloaded_')) {
          preloadedCount++;
        } else if (key.startsWith('comprehensive_lessons_cache_')) {
          comprehensiveLessonCount++;
        } else if (key.startsWith('level_preload_') ||
                   key.startsWith('unlimited_levels_') ||
                   key == _comprehensiveSessionsKey) {
          otherCacheCount++;
        }
      }

      final smartCacheStats = _smartCache.getCacheStats();
      final fallbackCacheStats = _fallbackPreloader.getCacheStats();

      return {
        'shared_preferences': {
          'ai_pool_count': aiPoolCount,
          'cached_session_count': cachedSessionCount,
          'preloaded_count': preloadedCount,
          'comprehensive_lesson_count': comprehensiveLessonCount,
          'other_cache_count': otherCacheCount,
          'total_cache_keys': aiPoolCount + cachedSessionCount + preloadedCount +
                              comprehensiveLessonCount + otherCacheCount,
        },
        'smart_cache': smartCacheStats,
        'fallback_cache': fallbackCacheStats,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// Generate adaptive fallback questions when API fails
  Future<List<Question>> _generateAdaptiveFallbackQuestions(SubjectType subject, int level, String? skillId) async {
    try {
      // Get adaptive recommendations to identify weak areas
      final recommendations = await _progressiveDifficultyService.getAdaptiveRecommendations(subject);

      final focusAreas = recommendations['focusAreas'] as List<String>? ?? [];
      final adaptiveDifficulty = recommendations['recommendedDifficulty'] as int? ?? level;

      final questions = <Question>[];
      final difficulty = _calculateDifficulty(adaptiveDifficulty);

      for (int i = 0; i < 7; i++) {
        questions.add(_generateAdaptiveFallbackQuestion(subject, difficulty, focusAreas, i + 1));
      }

      return questions;
    } catch (e) {
      debugPrint('Error generating adaptive fallback questions: $e');
      // Fall back to regular question generation
      return _generateFallbackQuestions(subject, level);
    }
  }

  /// Generate a single adaptive fallback question with focus areas
  Question _generateAdaptiveFallbackQuestion(SubjectType subject, int difficulty, List<String> focusAreas, int questionNumber) {
    final questionTemplates = _getAdaptiveQuestionTemplates(subject, difficulty, focusAreas);
    final template = questionTemplates[questionNumber % questionTemplates.length];

    return Question(
      id: 'adaptive_fallback_${DateTime.now().millisecondsSinceEpoch}_$questionNumber',
      type: template['type'],
      questionText: template['question'],
      options: template['options'],
      correctAnswer: template['correctAnswer'],
      explanation: template['explanation'],
      hint: template['hint'],
      difficulty: difficulty,
      subject: subject,
    );
  }

  /// Get adaptive question templates based on focus areas
  List<Map<String, dynamic>> _getAdaptiveQuestionTemplates(SubjectType subject, int difficulty, List<String> focusAreas) {
    final baseTemplates = _getQuestionTemplates(subject, difficulty);

    if (focusAreas.isEmpty) {
      return baseTemplates;
    }

    // Filter templates based on focus areas or enhance them
    final adaptiveTemplates = <Map<String, dynamic>>[];

    for (final template in baseTemplates) {
      // Check if template matches any focus area
      final questionText = template['question'].toString().toLowerCase();
      final hasMatchingFocus = focusAreas.any((area) => 
        questionText.contains(area.toLowerCase()) ||
        _isRelatedToFocusArea(subject, area, questionText)
      );

      if (hasMatchingFocus || adaptiveTemplates.length < 7) {
        // Enhance the template with adaptive hints
        final enhancedTemplate = Map<String, dynamic>.from(template);
        enhancedTemplate['hint'] = _generateAdaptiveHint(template['hint'], focusAreas);
        enhancedTemplate['explanation'] = _enhanceExplanationWithFocus(template['explanation'], focusAreas);
        adaptiveTemplates.add(enhancedTemplate);
      }
    }

    // Ensure we have at least 7 templates
    while (adaptiveTemplates.length < 7 && baseTemplates.isNotEmpty) {
      adaptiveTemplates.add(baseTemplates[adaptiveTemplates.length % baseTemplates.length]);
    }

    return adaptiveTemplates;
  }

  /// Check if a question is related to a focus area
  bool _isRelatedToFocusArea(SubjectType subject, String focusArea, String questionText) {
    // Simple keyword matching - can be enhanced with more sophisticated logic
    final keywords = _getFocusAreaKeywords(subject, focusArea);
    return keywords.any((keyword) => questionText.contains(keyword.toLowerCase()));
  }

  /// Get keywords associated with a focus area for a subject
  List<String> _getFocusAreaKeywords(SubjectType subject, String focusArea) {
    // This can be expanded with more comprehensive keyword mappings
    switch (subject) {
      case SubjectType.math:
        switch (focusArea.toLowerCase()) {
          case 'algebra':
            return ['equation', 'variable', 'solve', 'x', 'y'];
          case 'geometry':
            return ['triangle', 'circle', 'area', 'perimeter', 'angle'];
          case 'calculus':
            return ['derivative', 'integral', 'limit', 'function'];
          default:
            return [focusArea.toLowerCase()];
        }
      case SubjectType.physics:
        switch (focusArea.toLowerCase()) {
          case 'mechanics':
            return ['force', 'motion', 'velocity', 'acceleration'];
          case 'thermodynamics':
            return ['heat', 'temperature', 'energy', 'entropy'];
          default:
            return [focusArea.toLowerCase()];
        }
      case SubjectType.chemistry:
        switch (focusArea.toLowerCase()) {
          case 'organic':
            return ['carbon', 'molecule', 'bond', 'reaction'];
          case 'inorganic':
            return ['element', 'compound', 'ion', 'crystal'];
          default:
            return [focusArea.toLowerCase()];
        }
      case SubjectType.biology:
        switch (focusArea.toLowerCase()) {
          case 'genetics':
            return ['dna', 'gene', 'chromosome', 'heredity'];
          case 'ecology':
            return ['ecosystem', 'environment', 'species', 'habitat'];
          default:
            return [focusArea.toLowerCase()];
        }
      case SubjectType.science:
        switch (focusArea.toLowerCase()) {
          case 'scientific method':
            return ['hypothesis', 'experiment', 'observation', 'theory'];
          case 'measurement':
            return ['unit', 'scale', 'precision', 'accuracy'];
          default:
            return [focusArea.toLowerCase()];
        }
      case SubjectType.english:
        switch (focusArea.toLowerCase()) {
          case 'grammar':
            return ['noun', 'verb', 'adjective', 'sentence'];
          case 'literature':
            return ['story', 'character', 'plot', 'theme'];
          default:
            return [focusArea.toLowerCase()];
        }
      case SubjectType.history:
        switch (focusArea.toLowerCase()) {
          case 'ancient':
            return ['civilization', 'empire', 'culture', 'artifact'];
          case 'modern':
            return ['revolution', 'war', 'democracy', 'technology'];
          default:
            return [focusArea.toLowerCase()];
        }
      case SubjectType.geography:
        switch (focusArea.toLowerCase()) {
          case 'physical':
            return ['mountain', 'river', 'climate', 'landform'];
          case 'human':
            return ['population', 'city', 'culture', 'economy'];
          default:
            return [focusArea.toLowerCase()];
        }
      case SubjectType.art:
        switch (focusArea.toLowerCase()) {
          case 'painting':
            return ['color', 'brush', 'canvas', 'technique'];
          case 'sculpture':
            return ['form', 'material', 'texture', 'dimension'];
          default:
            return [focusArea.toLowerCase()];
        }
      case SubjectType.music:
        switch (focusArea.toLowerCase()) {
          case 'theory':
            return ['note', 'scale', 'chord', 'rhythm'];
          case 'history':
            return ['composer', 'period', 'style', 'instrument'];
          default:
            return [focusArea.toLowerCase()];
        }
      case SubjectType.physicalEducation:
        switch (focusArea.toLowerCase()) {
          case 'fitness':
            return ['exercise', 'strength', 'endurance', 'flexibility'];
          case 'sports':
            return ['game', 'rule', 'strategy', 'teamwork'];
          default:
            return [focusArea.toLowerCase()];
        }
      case SubjectType.computerScience:
        switch (focusArea.toLowerCase()) {
          case 'programming':
            return ['code', 'algorithm', 'function', 'variable'];
          case 'data structures':
            return ['array', 'list', 'tree', 'graph'];
          default:
            return [focusArea.toLowerCase()];
        }
    }
  }

  /// Generate adaptive hint based on focus areas
  String _generateAdaptiveHint(String baseHint, List<String> focusAreas) {
    if (focusAreas.isEmpty) return baseHint;
    
    final focusContext = focusAreas.join(', ');
    return '$baseHint\n\nFocus on: $focusContext';
  }

  /// Enhance explanation with focus area context
  String _enhanceExplanationWithFocus(String baseExplanation, List<String> focusAreas) {
    if (focusAreas.isEmpty) return baseExplanation;
    
    final focusContext = focusAreas.join(', ');
    return '$baseExplanation\n\nThis question focuses on: $focusContext. Understanding these concepts will help improve your performance in these areas.';
  }

  /// Science question templates
  List<Map<String, dynamic>> _getScienceTemplates(int difficulty) {
    return [
      {
        'type': QuestionType.multipleChoice,
        'question': 'What is the first step in the scientific method?',
        'options': ['Hypothesis', 'Observation', 'Experiment', 'Conclusion'],
        'correctAnswer': 'Observation',
        'explanation': 'The scientific method begins with observation of phenomena.',
        'hint': 'Think about what scientists do first when studying something new.',
      },
      {
        'type': QuestionType.trueFalse,
        'question': 'A hypothesis must be testable.',
        'options': ['True', 'False'],
        'correctAnswer': 'True',
        'explanation': 'A hypothesis must be testable through experiments or observations.',
        'hint': 'Consider what makes a good scientific hypothesis.',
      },
    ];
  }

  /// English question templates
  List<Map<String, dynamic>> _getEnglishTemplates(int difficulty) {
    return [
      {
        'type': QuestionType.multipleChoice,
        'question': 'What is a noun?',
        'options': ['Action word', 'Describing word', 'Person, place, or thing', 'Connecting word'],
        'correctAnswer': 'Person, place, or thing',
        'explanation': 'A noun is a word that names a person, place, thing, or idea.',
        'hint': 'Think about words that name things.',
      },
      {
        'type': QuestionType.fillInTheBlank,
        'question': 'The cat ___ on the mat.',
        'options': ['sat', 'sit', 'sitting', 'sits'],
        'correctAnswer': 'sat',
        'explanation': 'Past tense verbs describe actions that already happened.',
        'hint': 'This sentence describes something that already happened.',
      },
    ];
  }

  /// Art question templates
  List<Map<String, dynamic>> _getArtTemplates(int difficulty) {
    return [
      {
        'type': QuestionType.multipleChoice,
        'question': 'What are the primary colors?',
        'options': ['Red, Blue, Yellow', 'Red, Green, Blue', 'Blue, Yellow, Orange', 'Red, Blue, Green'],
        'correctAnswer': 'Red, Blue, Yellow',
        'explanation': 'Primary colors cannot be created by mixing other colors.',
        'hint': 'These colors cannot be made by mixing other colors.',
      },
      {
        'type': QuestionType.trueFalse,
        'question': 'Warm colors include red, orange, and yellow.',
        'options': ['True', 'False'],
        'correctAnswer': 'True',
        'explanation': 'Warm colors are associated with fire and sun.',
        'hint': 'Think about colors that remind you of fire or sunshine.',
      },
    ];
  }

  /// Music question templates
  List<Map<String, dynamic>> _getMusicTemplates(int difficulty) {
    return [
      {
        'type': QuestionType.multipleChoice,
        'question': 'How many lines are in a musical staff?',
        'options': ['4', '5', '6', '7'],
        'correctAnswer': '5',
        'explanation': 'A musical staff has five horizontal lines.',
        'hint': 'Count the lines where musical notes are placed.',
      },
      {
        'type': QuestionType.trueFalse,
        'question': 'A whole note lasts longer than a half note.',
        'options': ['True', 'False'],
        'correctAnswer': 'True',
        'explanation': 'A whole note lasts four beats, while a half note lasts two beats.',
        'hint': 'Think about which note value represents a longer duration.',
      },
    ];
  }

  /// Physical Education question templates
  List<Map<String, dynamic>> _getPhysicalEducationTemplates(int difficulty) {
    return [
      {
        'type': QuestionType.multipleChoice,
        'question': 'What is the recommended amount of daily exercise for children?',
        'options': ['30 minutes', '60 minutes', '90 minutes', '120 minutes'],
        'correctAnswer': '60 minutes',
        'explanation': 'Children should get at least 60 minutes of physical activity daily.',
        'hint': 'Think about health recommendations for daily activity.',
      },
      {
        'type': QuestionType.trueFalse,
        'question': 'Stretching helps prevent injuries.',
        'options': ['True', 'False'],
        'correctAnswer': 'True',
        'explanation': 'Stretching improves flexibility and helps prevent muscle injuries.',
        'hint': 'Consider what happens to muscles when they are more flexible.',
      },
    ];
  }
}

/// Enhanced game session model for 7-question games
class SevenQuestionGameSession extends GameSession {
  final int level;
  final List<bool> answerCorrectness;
  final bool isCompleted;
  final DateTime? endTime;

  const SevenQuestionGameSession({
    required String id,
    required SubjectType subject,
    required this.level,
    required String skillId,
    List<QuestionCategory> categories = const [],
    required List<Question> questions,
    required List<String> userAnswers,
    required this.answerCorrectness,
    required int currentQuestionIndex,
    required DateTime startTime,
    required int score,
    required this.isCompleted,
    this.endTime,
  }) : super(
    id: id,
    subject: subject,
    skillId: skillId,
    categories: categories,
    questions: questions,
    userAnswers: userAnswers,
    currentQuestionIndex: currentQuestionIndex,
    startTime: startTime,
    score: score,
    lives: 1, // Default value for lives
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject.name,
    'level': level,
    'skillId': skillId,
    'questions': questions.map((q) => (q as Question).toJson()).toList(),
    'userAnswers': userAnswers,
    'answerCorrectness': answerCorrectness,
    'currentQuestionIndex': currentQuestionIndex,
    'startTime': startTime.toIso8601String(),
    'score': score,
    'isCompleted': isCompleted,
    'endTime': endTime?.toIso8601String(),
  };

  factory SevenQuestionGameSession.fromJson(Map<String, dynamic> json) => 
      SevenQuestionGameSession(
        id: json['id'] as String,
        subject: SubjectType.values.firstWhere((s) => s.name == json['subject']),
        level: json['level'] as int,
        skillId: json['skillId'] as String,
        questions: (json['questions'] as List)
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .toList(),
        userAnswers: List<String>.from(json['userAnswers'] as List),
        answerCorrectness: List<bool>.from(json['answerCorrectness'] as List),
        currentQuestionIndex: json['currentQuestionIndex'] as int,
        startTime: DateTime.parse(json['startTime'] as String),
        score: json['score'] as int,
        isCompleted: json['isCompleted'] as bool,
        endTime: json['endTime'] != null 
            ? DateTime.parse(json['endTime'] as String) 
            : null,
      );

  SevenQuestionGameSession copyWith({
    String? id,
    SubjectType? subject,
    int? level,
    String? skillId,
    List<QuestionCategory>? categories,
    List<Question>? questions,
    List<String>? userAnswers,
    List<bool>? answerCorrectness,
    int? currentQuestionIndex,
    DateTime? startTime,
    int? score,
    int? lives,
    bool? isCompleted,
    DateTime? endTime,
  }) => SevenQuestionGameSession(
    id: id ?? this.id,
    subject: subject ?? this.subject,
    level: level ?? this.level,
    skillId: skillId ?? this.skillId,
    categories: categories ?? const [],
    questions: questions ?? this.questions,
    userAnswers: userAnswers ?? this.userAnswers,
    answerCorrectness: answerCorrectness ?? this.answerCorrectness,
    currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    startTime: startTime ?? this.startTime,
    score: score ?? this.score,
    isCompleted: isCompleted ?? this.isCompleted,
    endTime: endTime ?? this.endTime,
  );
}

/// Result of answering a question
class AnswerResult {
  final bool isCorrect;
  final String correctAnswer;
  final String explanation;
  final int currentScore;
  final int totalQuestions;

  const AnswerResult({
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
    required this.currentScore,
    required this.totalQuestions,
  });
}

/// Final game result
class GameResult {
  final String sessionId;
  final SubjectType subject;
  final int level;
  final int totalQuestions;
  final int correctAnswers;
  final int finalScore;
  final Duration timeSpent;
  final List<QuestionAnswer> questionsAndAnswers;

  const GameResult({
    required this.sessionId,
    required this.subject,
    required this.level,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.finalScore,
    required this.timeSpent,
    required this.questionsAndAnswers,
  });
}

/// Question and answer pair for results
class QuestionAnswer {
  final Question question;
  final String userAnswer;
  final bool isCorrect;

  const QuestionAnswer({
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
  });
}