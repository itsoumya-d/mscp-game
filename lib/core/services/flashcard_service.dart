import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard.dart';
import '../models/study_session.dart';

/// Comprehensive flashcard service with spaced repetition and gamification
/// Based on FSRS algorithm and educational gamification best practices
class FlashcardService {
  static FlashcardService? _instance;
  static FlashcardService getInstance() => _instance ??= FlashcardService._();
  FlashcardService._();

  final Random _random = Random();
  
  // FSRS Algorithm Parameters (research-backed optimal values)
  static const double _defaultEaseFactor = 2.5;
  static const double _minEaseFactor = 1.3;
  static const double _maxEaseFactor = 4.0;
  static const int _graduatingInterval = 1; // days
  static const int _easyInterval = 4; // days
  static const List<int> _learningSteps = [1, 10]; // minutes
  
  // Gamification Constants
  static const int _baseXpPerCard = 10;
  static const int _streakBonusMultiplier = 2;
  static const int _perfectSessionBonus = 50;
  static const int _dailyGoalXp = 200;

  /// Generate flashcards for a specific subject and skill level
  Future<List<Flashcard>> generateFlashcardsForSkill({
    required String subjectId,
    required String skillId,
    required int difficultyLevel,
    int count = 20,
  }) async {
    final flashcards = <Flashcard>[];
    
    for (int i = 0; i < count; i++) {
      final flashcard = _generateFlashcard(
        subjectId: subjectId,
        skillId: skillId,
        difficultyLevel: difficultyLevel,
        index: i,
      );
      flashcards.add(flashcard);
    }
    
    await _saveFlashcards(flashcards);
    return flashcards;
  }

  /// Generate a single flashcard based on subject and difficulty
  Flashcard _generateFlashcard({
    required String subjectId,
    required String skillId,
    required int difficultyLevel,
    required int index,
  }) {
    final cardData = _getSubjectSpecificContent(subjectId, difficultyLevel, index);
    
    return Flashcard(
      id: '${subjectId}_${skillId}_${difficultyLevel}_$index',
      subjectId: subjectId,
      skillId: skillId,
      front: cardData['front']!,
      back: cardData['back']!,
      type: cardData['type'] as FlashcardType,
      difficulty: difficultyLevel,
      easeFactor: _defaultEaseFactor,
      interval: 0,
      repetitions: 0,
      nextReviewDate: DateTime.now(),
      createdAt: DateTime.now(),
      tags: cardData['tags'] as List<String>,
      multimedia: cardData['multimedia'] as MultimediaContent?,
    );
  }

  /// Get subject-specific flashcard content with multimedia support
  Map<String, dynamic> _getSubjectSpecificContent(String subjectId, int difficulty, int index) {
    switch (subjectId) {
      case 'math':
        return _generateMathFlashcard(difficulty, index);
      case 'physics':
        return _generatePhysicsFlashcard(difficulty, index);
      case 'chemistry':
        return _generateChemistryFlashcard(difficulty, index);
      case 'biology':
        return _generateBiologyFlashcard(difficulty, index);
      case 'computer_science':
        return _generateComputerScienceFlashcard(difficulty, index);
      default:
        return _generateGenericFlashcard(difficulty, index);
    }
  }

  /// Generate math flashcards with visual elements
  Map<String, dynamic> _generateMathFlashcard(int difficulty, int index) {
    final problems = [
      // Basic arithmetic (difficulty 1-2)
      if (difficulty <= 2) ...[
        {
          'front': 'What is ${5 + index} × ${3 + (index % 4)}?',
          'back': '${(5 + index) * (3 + (index % 4))}',
          'type': FlashcardType.basic,
          'tags': ['arithmetic', 'multiplication'],
        },
        {
          'front': 'Solve: ${10 + index} ÷ ${2 + (index % 3)} = ?',
          'back': '${(10 + index) / (2 + (index % 3))}',
          'type': FlashcardType.basic,
          'tags': ['arithmetic', 'division'],
        },
      ],
      // Algebra (difficulty 3-5)
      if (difficulty >= 3 && difficulty <= 5) ...[
        {
          'front': 'Solve for x: ${2 + (index % 3)}x + ${5 + index} = ${15 + index}',
          'back': 'x = ${(15 + index - 5 - index) / (2 + (index % 3))}',
          'type': FlashcardType.problem_solving,
          'tags': ['algebra', 'linear_equations'],
        },
        {
          'front': 'What is the slope of the line passing through (${index}, ${index + 2}) and (${index + 3}, ${index + 8})?',
          'back': 'Slope = ${(index + 8 - index - 2) / (index + 3 - index)} = 2',
          'type': FlashcardType.problem_solving,
          'tags': ['algebra', 'slope'],
        },
      ],
      // Advanced topics (difficulty 6+)
      if (difficulty >= 6) ...[
        {
          'front': 'Find the derivative of f(x) = x² + ${3 + index}x + ${index}',
          'back': "f'(x) = 2x + ${3 + index}",
          'type': FlashcardType.problem_solving,
          'tags': ['calculus', 'derivatives'],
        },
      ],
    ];

    final selectedProblem = problems[index % problems.length];
    return {
      ...selectedProblem,
      'multimedia': difficulty >= 4 ? MultimediaContent(
        id: 'math_diagram_${difficulty}_${index}',
        type: MultimediaType.image,
        url: 'math_diagram_${difficulty}_${index}.svg',
        description: 'Visual representation of the problem',
      ) : null,
    };
  }

  /// Generate physics flashcards with formulas and diagrams
  Map<String, dynamic> _generatePhysicsFlashcard(int difficulty, int index) {
    final concepts = [
      {
        'front': 'What is Newton\'s Second Law of Motion?',
        'back': 'F = ma (Force equals mass times acceleration)',
        'type': FlashcardType.definition,
        'tags': ['mechanics', 'newton_laws'],
      },
      {
        'front': 'Calculate the kinetic energy of a ${5 + index}kg object moving at ${10 + index}m/s',
        'back': 'KE = ½mv² = ½ × ${5 + index} × ${10 + index}² = ${0.5 * (5 + index) * (10 + index) * (10 + index)}J',
        'type': FlashcardType.problem_solving,
        'tags': ['energy', 'kinetic_energy'],
      },
      {
        'front': 'What is the unit of electric current?',
        'back': 'Ampere (A)',
        'type': FlashcardType.basic,
        'tags': ['electricity', 'units'],
      },
    ];

    final selectedConcept = concepts[index % concepts.length];
    return {
      ...selectedConcept,
      'multimedia': difficulty >= 3 ? MultimediaContent(
        id: 'physics_diagram_${difficulty}_${index}',
        type: MultimediaType.image,
        url: 'physics_diagram_${difficulty}_${index}.svg',
        description: 'Physics concept visualization',
      ) : null,
    };
  }

  /// Generate chemistry flashcards with molecular structures
  Map<String, dynamic> _generateChemistryFlashcard(int difficulty, int index) {
    final concepts = [
      {
        'front': 'What is the chemical formula for water?',
        'back': 'H₂O',
        'type': FlashcardType.basic,
        'tags': ['formulas', 'basic_compounds'],
      },
      {
        'front': 'How many electrons can the second electron shell hold?',
        'back': '8 electrons',
        'type': FlashcardType.basic,
        'tags': ['atomic_structure', 'electron_shells'],
      },
      {
        'front': 'Balance this equation: C₂H₆ + O₂ → CO₂ + H₂O',
        'back': '2C₂H₆ + 7O₂ → 4CO₂ + 6H₂O',
        'type': FlashcardType.problem_solving,
        'tags': ['chemical_equations', 'balancing'],
      },
    ];

    final selectedConcept = concepts[index % concepts.length];
    return {
      ...selectedConcept,
      'multimedia': difficulty >= 4 ? MultimediaContent(
        id: 'chemistry_molecule_${difficulty}_${index}',
        type: MultimediaType.image,
        url: 'chemistry_molecule_${difficulty}_${index}.svg',
        description: 'Molecular structure diagram',
      ) : null,
    };
  }

  /// Generate biology flashcards with anatomical diagrams
  Map<String, dynamic> _generateBiologyFlashcard(int difficulty, int index) {
    final concepts = [
      {
        'front': 'What is the powerhouse of the cell?',
        'back': 'Mitochondria',
        'type': FlashcardType.basic,
        'tags': ['cell_biology', 'organelles'],
      },
      {
        'front': 'What process do plants use to make food from sunlight?',
        'back': 'Photosynthesis',
        'type': FlashcardType.definition,
        'tags': ['plant_biology', 'photosynthesis'],
      },
      {
        'front': 'How many chambers does a human heart have?',
        'back': '4 chambers (2 atria and 2 ventricles)',
        'type': FlashcardType.basic,
        'tags': ['anatomy', 'cardiovascular_system'],
      },
    ];

    final selectedConcept = concepts[index % concepts.length];
    return {
      ...selectedConcept,
      'multimedia': difficulty >= 3 ? MultimediaContent(
        id: 'biology_diagram_${difficulty}_${index}',
        type: MultimediaType.image,
        url: 'biology_diagram_${difficulty}_${index}.svg',
        description: 'Biological structure diagram',
      ) : null,
    };
  }

  /// Generate computer science flashcards with code examples
  Map<String, dynamic> _generateComputerScienceFlashcard(int difficulty, int index) {
    final concepts = [
      {
        'front': 'What is the time complexity of binary search?',
        'back': 'O(log n)',
        'type': FlashcardType.basic,
        'tags': ['algorithms', 'time_complexity'],
      },
      {
        'front': 'What data structure uses LIFO (Last In, First Out)?',
        'back': 'Stack',
        'type': FlashcardType.definition,
        'tags': ['data_structures', 'stack'],
      },
      {
        'front': 'Write a function to reverse a string in Python',
        'back': 'def reverse_string(s):\n    return s[::-1]',
        'type': FlashcardType.code,
        'tags': ['programming', 'python', 'strings'],
      },
    ];

    final selectedConcept = concepts[index % concepts.length];
    return {
      ...selectedConcept,
      'multimedia': difficulty >= 5 ? MultimediaContent(
        id: 'code_example_${difficulty}_${index}',
        type: MultimediaType.code,
        url: 'code_example_${difficulty}_${index}.py',
        description: 'Code implementation example',
      ) : null,
    };
  }

  /// Generate generic flashcards for unknown subjects
  Map<String, dynamic> _generateGenericFlashcard(int difficulty, int index) {
    return {
      'front': 'Generic question ${index + 1} (Difficulty: $difficulty)',
      'back': 'Generic answer ${index + 1}',
      'type': FlashcardType.basic,
      'tags': ['general'],
      'multimedia': null,
    };
  }

  /// Get flashcards due for review using FSRS algorithm
  Future<List<Flashcard>> getDueFlashcards({int limit = 20}) async {
    final allFlashcards = await _loadFlashcards();
    final now = DateTime.now();
    
    final dueCards = allFlashcards
        .where((card) => card.nextReviewDate.isBefore(now) || card.nextReviewDate.isAtSameMomentAs(now))
        .toList();
    
    // Sort by priority: new cards first, then by due date
    dueCards.sort((a, b) {
      if (a.repetitions == 0 && b.repetitions > 0) return -1;
      if (a.repetitions > 0 && b.repetitions == 0) return 1;
      return a.nextReviewDate.compareTo(b.nextReviewDate);
    });
    
    return dueCards.take(limit).toList();
  }

  /// Process flashcard review with FSRS-inspired algorithm
  Future<StudyResult> reviewFlashcard({
    required String flashcardId,
    required ReviewRating rating,
  }) async {
    final flashcards = await _loadFlashcards();
    final cardIndex = flashcards.indexWhere((card) => card.id == flashcardId);
    
    if (cardIndex == -1) {
      throw Exception('Flashcard not found: $flashcardId');
    }
    
    final card = flashcards[cardIndex];
    final updatedCard = _updateCardWithFSRS(card, rating);
    flashcards[cardIndex] = updatedCard;
    
    await _saveFlashcards(flashcards);
    
    // Calculate XP and gamification rewards
    final xpEarned = _calculateXpEarned(rating, updatedCard);
    final achievements = await _checkAchievements(rating, updatedCard);
    
    return StudyResult(
      flashcard: updatedCard,
      xpEarned: xpEarned,
      achievements: achievements,
      nextReviewDate: updatedCard.nextReviewDate,
    );
  }

  /// Update flashcard using FSRS-inspired algorithm
  Flashcard _updateCardWithFSRS(Flashcard card, ReviewRating rating) {
    final now = DateTime.now();
    
    // Handle new cards (in learning phase)
    if (card.repetitions == 0) {
      return _handleNewCard(card, rating, now);
    }
    
    // Handle review cards
    return _handleReviewCard(card, rating, now);
  }

  /// Handle new cards in learning phase
  Flashcard _handleNewCard(Flashcard card, ReviewRating rating, DateTime now) {
    switch (rating) {
      case ReviewRating.again:
        return card.copyWith(
          interval: _learningSteps[0],
          nextReviewDate: now.add(Duration(minutes: _learningSteps[0])),
          lastReviewDate: now,
        );
      
      case ReviewRating.hard:
        return card.copyWith(
          interval: _learningSteps.length > 1 ? _learningSteps[1] : _learningSteps[0],
          nextReviewDate: now.add(Duration(minutes: _learningSteps.length > 1 ? _learningSteps[1] : _learningSteps[0])),
          lastReviewDate: now,
        );
      
      case ReviewRating.good:
        return card.copyWith(
          interval: _graduatingInterval,
          repetitions: 1,
          nextReviewDate: now.add(Duration(days: _graduatingInterval)),
          lastReviewDate: now,
        );
      
      case ReviewRating.easy:
        return card.copyWith(
          interval: _easyInterval,
          repetitions: 1,
          easeFactor: card.easeFactor + 0.15,
          nextReviewDate: now.add(Duration(days: _easyInterval)),
          lastReviewDate: now,
        );
    }
  }

  /// Handle review cards (graduated cards)
  Flashcard _handleReviewCard(Flashcard card, ReviewRating rating, DateTime now) {
    double newEaseFactor = card.easeFactor;
    int newInterval;
    
    switch (rating) {
      case ReviewRating.again:
        newEaseFactor = max(_minEaseFactor, card.easeFactor - 0.2);
        newInterval = max(1, (card.interval * 0.25).round());
        break;
      
      case ReviewRating.hard:
        newEaseFactor = max(_minEaseFactor, card.easeFactor - 0.15);
        newInterval = max(1, (card.interval * 1.2).round());
        break;
      
      case ReviewRating.good:
        newInterval = (card.interval * card.easeFactor).round();
        break;
      
      case ReviewRating.easy:
        newEaseFactor = min(_maxEaseFactor, card.easeFactor + 0.15);
        newInterval = (card.interval * card.easeFactor * 1.3).round();
        break;
    }
    
    return card.copyWith(
      interval: newInterval,
      repetitions: card.repetitions + 1,
      easeFactor: newEaseFactor,
      nextReviewDate: now.add(Duration(days: newInterval)),
      lastReviewDate: now,
    );
  }

  /// Calculate XP earned based on performance and streaks
  int _calculateXpEarned(ReviewRating rating, Flashcard card) {
    int baseXp = _baseXpPerCard;
    
    // Bonus for difficulty
    baseXp += (card.difficulty * 2);
    
    // Rating multiplier
    switch (rating) {
      case ReviewRating.again:
        baseXp = (baseXp * 0.5).round();
        break;
      case ReviewRating.hard:
        baseXp = (baseXp * 0.8).round();
        break;
      case ReviewRating.good:
        // No change
        break;
      case ReviewRating.easy:
        baseXp = (baseXp * 1.5).round();
        break;
    }
    
    return baseXp;
  }

  /// Check for achievements and badges
  Future<List<Achievement>> _checkAchievements(ReviewRating rating, Flashcard card) async {
    final achievements = <Achievement>[];
    final gamificationData = await _loadGamificationData();
    
    // First card achievement
    if (gamificationData.totalCardsReviewed == 1) {
      achievements.add(Achievement(
        id: 'first_card',
        title: 'First Steps',
        description: 'Reviewed your first flashcard!',
        iconUrl: 'assets/badges/first_card.svg',
        xpReward: 25,
      ));
    }
    
    // Perfect streak achievements
    if (rating == ReviewRating.good || rating == ReviewRating.easy) {
      final newStreak = gamificationData.currentStreak + 1;
      if (newStreak == 5) {
        achievements.add(Achievement(
          id: 'streak_5',
          title: 'On Fire!',
          description: 'Maintained a 5-card streak!',
          iconUrl: 'assets/badges/streak_5.svg',
          xpReward: 50,
        ));
      } else if (newStreak == 10) {
        achievements.add(Achievement(
          id: 'streak_10',
          title: 'Unstoppable',
          description: 'Achieved a 10-card streak!',
          iconUrl: 'assets/badges/streak_10.svg',
          xpReward: 100,
        ));
      }
    }
    
    // Subject mastery achievements
    final subjectProgress = await _getSubjectProgress(card.subjectId);
    if (subjectProgress >= 0.5 && !gamificationData.unlockedBadges.contains('${card.subjectId}_half')) {
      achievements.add(Achievement(
        id: '${card.subjectId}_half',
        title: 'Subject Explorer',
        description: 'Completed 50% of ${card.subjectId} flashcards!',
        iconUrl: 'assets/badges/subject_half.svg',
        xpReward: 200,
      ));
    }
    
    return achievements;
  }

  /// Get subject progress percentage
  Future<double> _getSubjectProgress(String subjectId) async {
    final flashcards = await _loadFlashcards();
    final subjectCards = flashcards.where((card) => card.subjectId == subjectId).toList();
    
    if (subjectCards.isEmpty) return 0.0;
    
    final reviewedCards = subjectCards.where((card) => card.repetitions > 0).length;
    return reviewedCards / subjectCards.length;
  }

  /// Start a study session with gamification tracking
  Future<StudySession> startStudySession({
    String? subjectId,
    int targetCards = 20,
  }) async {
    final dueCards = await getDueFlashcards(limit: targetCards);
    final session = StudySession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      startTime: DateTime.now(),
      targetCards: targetCards,
      flashcards: dueCards,
      subjectId: subjectId,
    );
    
    await _saveCurrentSession(session);
    return session;
  }

  /// Complete study session and calculate rewards
  Future<SessionResult> completeStudySession(StudySession session) async {
    final completedSession = session.copyWith(
      endTime: DateTime.now(),
      isCompleted: true,
    );
    
    // Calculate session statistics
    final totalXp = session.results.fold(0, (sum, result) => sum + result.xpEarned);
    final accuracy = session.results.isEmpty ? 0.0 : 
        session.results.where((r) => r.rating == ReviewRating.good || r.rating == ReviewRating.easy).length / session.results.length;
    
    // Session bonuses
    int bonusXp = 0;
    final achievements = <Achievement>[];
    
    // Perfect session bonus
    if (accuracy == 1.0 && session.results.length >= 10) {
      bonusXp += _perfectSessionBonus;
      achievements.add(Achievement(
        id: 'perfect_session',
        title: 'Perfect Session',
        description: 'Completed a session with 100% accuracy!',
        iconUrl: 'assets/badges/perfect_session.svg',
        xpReward: _perfectSessionBonus,
      ));
    }
    
    // Update gamification data
    await _updateGamificationData(totalXp + bonusXp, session.results.length, accuracy);
    
    return SessionResult(
      session: completedSession,
      totalXp: totalXp + bonusXp,
      accuracy: accuracy,
      achievements: achievements,
      studyTime: completedSession.endTime!.difference(completedSession.startTime),
    );
  }

  /// Update gamification data after session
  Future<void> _updateGamificationData(int xpEarned, int cardsReviewed, double accuracy) async {
    final data = await _loadGamificationData();
    final updatedData = data.copyWith(
      totalXp: data.totalXp + xpEarned,
      totalCardsReviewed: data.totalCardsReviewed + cardsReviewed,
      currentStreak: accuracy >= 0.8 ? data.currentStreak + cardsReviewed : 0,
      longestStreak: max(data.longestStreak, data.currentStreak),
      lastStudyDate: DateTime.now(),
    );
    
    await _saveGamificationData(updatedData);
  }

  /// Get user's gamification statistics
  Future<GamificationData> getGamificationData() async {
    return await _loadGamificationData();
  }

  /// Get daily study progress
  Future<DailyProgress> getDailyProgress() async {
    final data = await _loadGamificationData();
    final today = DateTime.now();
    final isToday = data.lastStudyDate?.day == today.day &&
                   data.lastStudyDate?.month == today.month &&
                   data.lastStudyDate?.year == today.year;
    
    final todayXp = isToday ? data.dailyXp : 0;
    
    return DailyProgress(
      currentXp: todayXp,
      targetXp: _dailyGoalXp,
      cardsReviewed: isToday ? data.dailyCardsReviewed : 0,
      streak: data.currentStreak,
      isGoalMet: todayXp >= _dailyGoalXp,
    );
  }

  // Storage methods
  Future<void> _saveFlashcards(List<Flashcard> flashcards) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = flashcards.map((card) => card.toJson()).toList();
    await prefs.setString('flashcards', jsonEncode(jsonList));
  }

  Future<List<Flashcard>> _loadFlashcards() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('flashcards') ?? '[]';
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => Flashcard.fromJson(json)).toList();
  }

  Future<void> _saveCurrentSession(StudySession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_session', jsonEncode(session.toJson()));
  }

  Future<StudySession?> _loadCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('current_session');
    if (jsonString == null) return null;
    return StudySession.fromJson(jsonDecode(jsonString));
  }

  Future<void> _saveGamificationData(GamificationData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gamification_data', jsonEncode(data.toJson()));
  }

  Future<GamificationData> _loadGamificationData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('gamification_data');
    if (jsonString == null) {
      return GamificationData.initial();
    }
    return GamificationData.fromJson(jsonDecode(jsonString));
  }
}