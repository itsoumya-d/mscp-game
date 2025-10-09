import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/subject.dart';
import '../models/question.dart';
import '../services/game_session_service.dart';
import '../services/game_save_service.dart';
import '../services/analytics_service.dart';
import '../services/progressive_difficulty_service.dart';
import '../services/unified_xp_service.dart';
import '../services/unified_level_service.dart';
import '../services/level_preloader_service.dart';
import '../services/unlock_animation_service.dart';

/// Controller for managing 7-question game sessions
class GameController extends ChangeNotifier {
  final GameSessionService _gameSessionService;
  final GameSaveService _gameSaveService;
  final AnalyticsService _analyticsService;
  final ProgressiveDifficultyService _progressiveDifficultyService;
  final UnifiedXPService _unifiedXPService;
  final UnifiedLevelService _levelService;
  final LevelPreloaderService _levelPreloaderService;
  final UnlockAnimationService _unlockAnimationService;

  SevenQuestionGameSession? _currentSession;
  int _currentQuestionIndex = 0;
  List<String> _userAnswers = [];
  int _score = 0;
  bool _isLoading = false;
  String? _error;
  Timer? _questionTimer;
  DateTime? _questionStartTime;
  List<int> _questionTimes = [];

  // Game state
  bool _isGameActive = false;
  bool _isGameCompleted = false;
  String? _currentFeedback;
  bool? _lastAnswerCorrect;
  String? _currentAnswer; // Temporarily store selected answer

  GameController({
    required GameSessionService gameSessionService,
    required GameSaveService gameSaveService,
    required AnalyticsService analyticsService,
    required ProgressiveDifficultyService progressiveDifficultyService,
    required UnifiedXPService unifiedXPService,
    required UnifiedLevelService levelService,
    required LevelPreloaderService levelPreloaderService,
    required UnlockAnimationService unlockAnimationService,
  })  : _gameSessionService = gameSessionService,
        _gameSaveService = gameSaveService,
        _analyticsService = analyticsService,
        _progressiveDifficultyService = progressiveDifficultyService,
        _unifiedXPService = unifiedXPService,
        _levelService = levelService,
        _levelPreloaderService = levelPreloaderService,
        _unlockAnimationService = unlockAnimationService;

  // Getters
  SevenQuestionGameSession? get currentSession => _currentSession;
  int get currentQuestionIndex => _currentQuestionIndex;
  List<String> get userAnswers => List.unmodifiable(_userAnswers);
  int get score => _score;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isGameActive => _isGameActive;
  bool get isGameCompleted => _isGameCompleted;
  String? get currentFeedback => _currentFeedback;
  bool? get lastAnswerCorrect => _lastAnswerCorrect;
  List<int> get questionTimes => List.unmodifiable(_questionTimes);
  String? get currentAnswer => _currentAnswer;

  // Current question getter
  Question? get currentQuestion {
    if (_currentSession == null || 
        _currentQuestionIndex >= _currentSession!.questions.length) {
      return null;
    }
    return _currentSession!.questions[_currentQuestionIndex];
  }

  // Progress getter (0.0 to 1.0)
  double get progress {
    if (_currentSession == null || _currentSession!.questions.isEmpty) {
      return 0.0;
    }
    return _currentQuestionIndex / _currentSession!.questions.length;
  }

  // Questions remaining
  int get questionsRemaining {
    if (_currentSession == null) return 0;
    return max(0, _currentSession!.questions.length - _currentQuestionIndex);
  }

  /// Start a new game session
  Future<void> startNewGame({
    required SubjectType subject,
    required int level,
    String? skillId,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _resetGameState();

      // Preload levels for better performance
      await _levelService.preloadLevelsForSubject(subject);

      // Get adaptive difficulty based on user performance
      final adaptiveDifficulty = await _progressiveDifficultyService.getAdaptiveDifficulty(subject);

      // Use adaptive difficulty if available, otherwise use provided level
      final effectiveLevel = adaptiveDifficulty ?? level;

      // Try to get cached level session first for better performance
      var session = await _levelPreloaderService.getCachedGameSession(subject, effectiveLevel);
      
      // If no cached session, create new one
      if (session == null) {
        session = await _gameSessionService.createGameSession(
          subject: subject,
          level: effectiveLevel,
          skillId: skillId,
        );
      }

      _currentSession = session;
      _isGameActive = true;
      _startQuestionTimer();

      // Save session
      await _gameSaveService.saveGameSession(session);

      // Track analytics with adaptive difficulty info
      _analyticsService.trackEvent('game_start', {
        'subject': subject.name,
        'requested_level': level,
        'adaptive_level': effectiveLevel,
        'skill_id': skillId ?? 'general',
        'adaptive_reasoning': adaptiveDifficulty != null ? 'Adaptive level: $adaptiveDifficulty' : 'No adaptive data',
        'timestamp': DateTime.now().toIso8601String(),
        'cache_hit': session != null ? 'true' : 'false',
      });

      notifyListeners();
    } catch (e) {
      _setError('Failed to start game: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Set the current answer temporarily (before submission)
  void setCurrentAnswer(String answer) {
    _currentAnswer = answer;
    notifyListeners();
  }

  /// Submit answer for current question
  Future<void> submitAnswer([String? answer]) async {
    if (_currentSession == null || 
        _currentQuestionIndex >= _currentSession!.questions.length ||
        !_isGameActive) {
      return;
    }

    // Use provided answer or current stored answer
    final answerToSubmit = answer ?? _currentAnswer ?? '';
    if (answerToSubmit.isEmpty) {
      _setError('No answer selected');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final currentQ = _currentSession!.questions[_currentQuestionIndex];
      final isCorrect = _checkAnswer(currentQ, answerToSubmit);

      // Record answer and time
      _userAnswers.add(answerToSubmit);
      _recordQuestionTime();

      // Update score
      if (isCorrect) {
        _score += _calculateQuestionScore(currentQ, _getLastQuestionTime());
      }

      // Set feedback
      _currentFeedback = isCorrect ? 'Correct!' : 'Incorrect';
      _lastAnswerCorrect = isCorrect;

      // Update session
      _currentSession = _currentSession!.copyWith(
        userAnswers: _userAnswers,
        currentQuestionIndex: _currentQuestionIndex,
        score: _score,
      );

      // Save progress
      await _gameSaveService.saveGameSession(_currentSession!);

      // Track analytics
      _analyticsService.trackEvent('question_answer', {
        'subject': _currentSession!.subject.name,
        'question_number': _currentQuestionIndex + 1,
        'is_correct': isCorrect,
        'response_time': _getLastQuestionTime(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      notifyListeners();

      // REMOVED AUTO-ADVANCE: User must manually proceed to next question
      // This prevents the auto-skip bug where questions advance without user interaction
      // The UI should provide a "Next Question" or "Continue" button instead

    } catch (e) {
      _setError('Failed to submit answer: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Move to next question or complete game (PRIVATE - called internally)
  Future<void> _nextQuestion() async {
    if (_currentSession == null) return;

    _currentQuestionIndex++;
    _currentFeedback = null;
    _lastAnswerCorrect = null;
    _currentAnswer = null; // Clear current answer for next question

    if (_currentQuestionIndex >= _currentSession!.questions.length) {
      // Game completed
      await _completeGame();
    } else {
      // Start next question
      _startQuestionTimer();

      // Update session
      _currentSession = _currentSession!.copyWith(
        currentQuestionIndex: _currentQuestionIndex,
      );

      await _gameSaveService.saveGameSession(_currentSession!);
    }

    notifyListeners();
  }

  /// PUBLIC method to manually advance to next question (called by UI)
  /// This prevents auto-skip bug by requiring explicit user action
  Future<void> nextQuestion() async {
    await _nextQuestion();
  }

  /// Complete the current game
  Future<void> _completeGame() async {
    if (_currentSession == null) return;

    try {
      _isGameActive = false;
      _isGameCompleted = true;
      _stopQuestionTimer();

      // Calculate final score and statistics
      final finalScore = _calculateFinalScore();
      final accuracy = _userAnswers.length > 0 
          ? (_score > 0 ? _score / (_userAnswers.length * 100) : 0.0)
          : 0.0;
      
      final totalTime = _questionTimes.fold<int>(0, (sum, time) => sum + time);
      final avgTime = _questionTimes.isNotEmpty 
          ? totalTime / _questionTimes.length 
          : 0.0;

      // Record performance for progressive difficulty
      await _progressiveDifficultyService.recordPerformance(
        subject: _currentSession!.subject,
        skillId: _currentSession!.skillId ?? 'general',
        difficulty: _currentSession!.questions.isNotEmpty 
            ? _currentSession!.questions.first.difficulty 
            : 50,
        isCorrect: accuracy > 0.7, // Consider >70% as correct performance
        timeSpentSeconds: avgTime.round(),
        questionType: 'game_session',
      );

      // Update session with final data
      _currentSession = _currentSession!.copyWith(
        score: finalScore,
        userAnswers: _userAnswers,
        currentQuestionIndex: _currentQuestionIndex,
      );

      // Save completed session
      await _gameSaveService.saveGameSession(_currentSession!);

      // Track completion analytics
      _analyticsService.trackEvent('game_complete', {
        'subject': _currentSession!.subject.name,
        'skill_id': _currentSession!.skillId ?? 'general',
        'final_score': finalScore,
        'accuracy': accuracy,
        'total_time': totalTime,
        'avg_response_time': avgTime,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Update progress and unlock levels based on performance
      if (accuracy >= 0.7) { // 70% accuracy threshold for progression
        // Calculate XP reward using the new XP progression system
        final correctAnswers = _userAnswers.where((answer) => 
          _currentSession!.questions[_userAnswers.indexOf(answer)].correctAnswer == answer
        ).length;
        
        final xpReward = _unifiedXPService.calculateXPReward(
          correctAnswers: correctAnswers,
          totalQuestions: _currentSession!.questions.length,
          timeSpent: totalTime,
          difficulty: 'medium', // Default difficulty since SevenQuestionGameSession doesn't have difficulty property
          perfectScore: correctAnswers == _currentSession!.questions.length,
        );
        
        // Add XP to the subject
        final xpResult = await _unifiedXPService.addXP(
          _currentSession!.subject,
          xpReward,
        );
        
        // Record level completion
        final currentGameLevel = _currentSession!.level;
        final levelId = '${_currentSession!.skillId ?? 'general'}_$currentGameLevel';

        await _unifiedXPService.updateLevelProgress(
          userId: 'default', // Use default user ID since SevenQuestionGameSession doesn't have userId
          levelId: levelId,
          isCompleted: true,
          accuracy: accuracy,
          score: finalScore,
          totalTime: totalTime,
        );

        // Check if next level should be unlocked (sequential unlock)
        final nextLevel = currentGameLevel + 1;
        final isNextLevelAlreadyUnlocked = await _unifiedXPService.isLevelUnlocked(
          subject: _currentSession!.subject,
          level: nextLevel,
          skillId: _currentSession!.skillId,
        );

        if (!isNextLevelAlreadyUnlocked && nextLevel <= 10) {
          // Unlock the next level
          await _unifiedXPService.unlockLevel(
            subject: _currentSession!.subject,
            level: nextLevel,
            skillId: _currentSession!.skillId,
          );

          // Trigger unlock animation for the next level
          await _triggerLevelUnlockAnimation(
            subject: _currentSession!.subject.name,
            level: nextLevel,
            xpReward: xpReward,
          );
        }

        // Get updated XP and level information
        final currentXP = await _unifiedXPService.getCurrentXP(_currentSession!.subject);
        final currentLevel = await _unifiedXPService.getCurrentLevel(_currentSession!.subject);
        final totalXP = await _unifiedXPService.getTotalXP();
        final overallLevel = await _unifiedXPService.getOverallLevel();
        
        // Track level progression with unified XP system data
        _analyticsService.trackEvent('level_progression', {
          'subject': _currentSession!.subject.name,
          'skill_id': _currentSession!.skillId ?? 'general',
          'completed_level': currentGameLevel,
          'accuracy': accuracy,
          'xp_awarded': xpReward,
          'current_xp': currentXP,
          'current_level': currentLevel,
          'total_xp': totalXP,
          'overall_level': overallLevel,
          'next_level_unlocked': !isNextLevelAlreadyUnlocked && nextLevel <= 10,
          'next_level': nextLevel,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

    } catch (e) {
      _setError('Failed to complete game: $e');
    }
  }

  /// Restart current game
  Future<void> restartGame() async {
    if (_currentSession == null) return;

    await startNewGame(
      subject: _currentSession!.subject,
      level: _currentSession!.skillId != null 
          ? int.tryParse(_currentSession!.skillId!) ?? 1 
          : 1,
      skillId: _currentSession!.skillId,
    );
  }

  /// Pause current game
  void pauseGame() {
    if (_isGameActive) {
      _stopQuestionTimer();
      _isGameActive = false;
      notifyListeners();
    }
  }

  /// Resume paused game
  void resumeGame() {
    if (!_isGameActive && !_isGameCompleted && _currentSession != null) {
      _isGameActive = true;
      _startQuestionTimer();
      notifyListeners();
    }
  }

  /// Load saved game session
  Future<void> loadSavedGame(String sessionId) async {
    try {
      _setLoading(true);
      _clearError();

      final session = await _gameSaveService.loadGameSession();
      if (session != null) {
        // Cast to SevenQuestionGameSession if it's the correct type
        if (session is SevenQuestionGameSession) {
          _currentSession = session;
        } else {
          // Handle case where loaded session is not the expected type
          _setError('Invalid session type loaded');
          return;
        }
        _currentQuestionIndex = session.currentQuestionIndex;
        _userAnswers = List.from(session.userAnswers);
        _score = session.score;
        
        if (_currentQuestionIndex < session.questions.length) {
          _isGameActive = true;
          _startQuestionTimer();
        } else {
          _isGameCompleted = true;
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to load saved game: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Check if answer is correct
  bool _checkAnswer(Question question, String userAnswer) {
    final correctAnswer = question.correctAnswer.toLowerCase().trim();
    final userAnswerNormalized = userAnswer.toLowerCase().trim();

    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
      case QuestionType.clickableAnswer:
        return correctAnswer == userAnswerNormalized;
      
      case QuestionType.numericInput:
        // Handle numeric answers with tolerance
        final correctNum = double.tryParse(correctAnswer);
        final userNum = double.tryParse(userAnswerNormalized);
        if (correctNum != null && userNum != null) {
          return (correctNum - userNum).abs() < 0.01;
        }
        return correctAnswer == userAnswerNormalized;
      
      case QuestionType.fillInTheBlank:
      case QuestionType.shortAnswer:
        // More flexible matching for text answers
        return correctAnswer.contains(userAnswerNormalized) ||
               userAnswerNormalized.contains(correctAnswer);
      
      case QuestionType.dragDrop:
        // For drag-drop, expect exact match
        return correctAnswer == userAnswerNormalized;
      
      default:
        return correctAnswer == userAnswerNormalized;
    }
  }

  /// Calculate score for a question based on difficulty and time
  int _calculateQuestionScore(Question question, int timeSpent) {
    // Base score per question to achieve 50-60 points per lesson (7 questions)
    // Target: 50-60 points / 7 questions = 7-8.5 points per question
    int baseScore = 8;
    
    // Difficulty multiplier (1-5 maps to 0.8-1.2)
    double difficultyMultiplier = 0.8 + (question.difficulty / 5.0) * 0.4;
    
    // Time bonus (faster answers get bonus, max 30 seconds)
    double timeMultiplier = 1.0;
    if (timeSpent <= 10000) { // 10 seconds
      timeMultiplier = 1.3;
    } else if (timeSpent <= 20000) { // 20 seconds
      timeMultiplier = 1.1;
    } else if (timeSpent <= 30000) { // 30 seconds
      timeMultiplier = 1.0;
    } else {
      timeMultiplier = 0.9;
    }
    
    return (baseScore * difficultyMultiplier * timeMultiplier).round();
  }

  /// Calculate final score
  int _calculateFinalScore() {
    return _score;
  }

  /// Timer management
  void _startQuestionTimer() {
    _questionStartTime = DateTime.now();
  }

  void _stopQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimer = null;
  }

  void _recordQuestionTime() {
    if (_questionStartTime != null) {
      final timeSpent = DateTime.now().difference(_questionStartTime!).inMilliseconds;
      _questionTimes.add(timeSpent);
    }
  }

  int _getLastQuestionTime() {
    return _questionTimes.isNotEmpty ? _questionTimes.last : 0;
  }

  /// State management helpers
  void _resetGameState() {
    _currentSession = null;
    _currentQuestionIndex = 0;
    _userAnswers.clear();
    _score = 0;
    _isGameActive = false;
    _isGameCompleted = false;
    _currentFeedback = null;
    _lastAnswerCorrect = null;
    _currentAnswer = null; // Clear current answer
    _questionTimes.clear();
    _stopQuestionTimer();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Triggers unlock animation for a newly unlocked level
  Future<void> _triggerLevelUnlockAnimation({
    required String subject,
    required int level,
    required int xpReward,
  }) async {
    try {
      final unlockEvent = _unlockAnimationService.createSingleLevelUnlockEvent(
        levelId: '${subject.toLowerCase()}_level_$level',
        levelName: 'Level $level',
        subjectName: subject,
        xpReward: xpReward,
        gemReward: _calculateGemReward(level),
        metadata: {
          'subject': subject,
          'level': level,
          'unlockType': 'level_completion',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      _unlockAnimationService.queueUnlockEvent(unlockEvent);
    } catch (e) {
      // Log error but don't interrupt game flow
      print('Error triggering unlock animation: $e');
    }
  }

  /// Calculates gem reward based on level
  int _calculateGemReward(int level) {
    // Base gem reward with bonus for higher levels
    return 10 + (level ~/ 5) * 5;
  }

  @override
  void dispose() {
    _stopQuestionTimer();
    super.dispose();
  }
}