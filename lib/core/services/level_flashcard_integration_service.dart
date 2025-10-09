import 'dart:math';
import '../models/subject.dart';
import '../models/flashcard.dart';
import '../models/question.dart';
import 'level_generation_service.dart';
import 'flashcard_service.dart';
import 'progressive_unlock_service.dart';
import 'unified_xp_service.dart';

/// Service for integrating flashcards with the level progression system
class LevelFlashcardIntegrationService {
  static final LevelFlashcardIntegrationService _instance = 
      LevelFlashcardIntegrationService._internal();
  factory LevelFlashcardIntegrationService() => _instance;
  LevelFlashcardIntegrationService._internal();

  final LevelGenerationService _levelService = LevelGenerationService();
  final FlashcardService _flashcardService = FlashcardService.getInstance();
  final ProgressiveUnlockService _unlockService = ProgressiveUnlockService();
  final UnifiedXPService _xpService = UnifiedXPService.getInstance();
  final Random _random = Random();

  /// Generate flashcards from completed lessons for spaced repetition
  Future<List<Flashcard>> generateFlashcardsFromLessons({
    required String subjectId,
    String? skillId,
    int maxCards = 50,
  }) async {
    final flashcards = <Flashcard>[];
    
    // Get completed lessons for the subject/skill
    final completedLessons = await _getCompletedLessons(subjectId, skillId);
    
    if (completedLessons.isEmpty) {
      return flashcards;
    }

    // Generate flashcards from lesson content
    for (final lesson in completedLessons) {
      if (flashcards.length >= maxCards) break;
      
      final lessonFlashcards = await _generateFlashcardsFromLesson(lesson);
      flashcards.addAll(lessonFlashcards);
    }

    // Shuffle and limit to requested count
    flashcards.shuffle(_random);
    return flashcards.take(maxCards).toList();
  }

  /// Generate flashcards specifically for skill reinforcement
  Future<List<Flashcard>> generateSkillReinforcementCards({
    required String subjectId,
    required String skillId,
    int count = 20,
  }) async {
    final skill = await _getSkillById(subjectId, skillId);
    if (skill == null) return [];

    final flashcards = <Flashcard>[];
    
    // Generate cards from all lessons in the skill
    for (final lesson in skill.lessons) {
      if (!lesson.isCompleted) continue;
      
      final lessonCards = await _generateFlashcardsFromLesson(lesson);
      flashcards.addAll(lessonCards);
    }

    // Prioritize cards based on skill difficulty and user performance
    flashcards.sort((a, b) => _prioritizeCard(a, b, skill));
    
    return flashcards.take(count).toList();
  }

  /// Generate review flashcards for weak areas
  Future<List<Flashcard>> generateWeakAreaReviewCards({
    required String subjectId,
    int count = 30,
  }) async {
    final flashcards = <Flashcard>[];
    
    // Get user's performance data to identify weak areas
    final weakSkills = await _identifyWeakSkills(subjectId);
    
    for (final skillId in weakSkills) {
      if (flashcards.length >= count) break;
      
      final skillCards = await generateSkillReinforcementCards(
        subjectId: subjectId,
        skillId: skillId,
        count: count ~/ weakSkills.length,
      );
      
      flashcards.addAll(skillCards);
    }

    return flashcards.take(count).toList();
  }

  /// Generate mastery flashcards for completed skills
  Future<List<Flashcard>> generateMasteryCards({
    required String subjectId,
    int count = 25,
  }) async {
    final flashcards = <Flashcard>[];
    
    // Get skills with high completion rates
    final masteredSkills = await _getMasteredSkills(subjectId);
    
    for (final skillId in masteredSkills) {
      if (flashcards.length >= count) break;
      
      final skill = await _getSkillById(subjectId, skillId);
      if (skill == null) continue;
      
      // Generate advanced/synthesis questions for mastered content
      final masteryCards = await _generateMasteryFlashcards(skill);
      flashcards.addAll(masteryCards);
    }

    return flashcards.take(count).toList();
  }

  /// Update skill progress based on flashcard performance
  Future<void> updateSkillProgressFromFlashcards({
    required String subjectId,
    required String skillId,
    required List<ReviewResult> reviewResults,
  }) async {
    if (reviewResults.isEmpty) return;

    // Calculate performance metrics
    final totalReviews = reviewResults.length;
    final correctReviews = reviewResults.where((r) => 
        r.rating == ReviewRating.good || r.rating == ReviewRating.easy).length;
    final accuracy = correctReviews / totalReviews;

    // Award XP based on performance
    final xpEarned = _calculateFlashcardXp(reviewResults);
    final subjectType = SubjectType.values.firstWhere(
      (s) => s.name == subjectId,
      orElse: () => SubjectType.math,
    );
    await _xpService.addXP(subjectType, xpEarned);

    // Note: Skill mastery tracking is handled by ProgressiveUnlockService
    // through level completion rather than individual flashcard reviews

    // Unlock next content if thresholds are met
    await _checkUnlockConditions(subjectId, skillId);
  }

  /// Get available flashcard types for a subject
  Future<List<String>> getAvailableFlashcardTypes(String subjectId) async {
    final completedLessons = await _getCompletedLessons(subjectId, null);
    final weakAreas = await _identifyWeakSkills(subjectId);
    
    List<String> availableTypes = [];
    
    if (completedLessons.isNotEmpty) {
      availableTypes.add('quick');
      availableTypes.add('adaptive');
    }
    
    if (weakAreas.isNotEmpty) {
      availableTypes.add('weak');
    }
    
    // Check if user has high enough progress for mastery cards
    final masteredSkills = await _getMasteredSkills(subjectId);
    if (masteredSkills.isNotEmpty) {
      availableTypes.add('mastery');
    }
    
    return availableTypes.isEmpty ? ['quick'] : availableTypes;
  }

  /// Get flashcard session recommendations
  Future<Map<String, dynamic>> getFlashcardRecommendations(String subjectId) async {
    final weakAreas = await _identifyWeakSkills(subjectId);
    final masteredSkills = await _getMasteredSkills(subjectId);
    final userPerformance = await _getUserPerformanceData(subjectId, null);
    
    Map<String, dynamic> recommendations = {
      'primaryRecommendation': 'quick',
      'recommendationReason': 'Continue your learning journey',
      'estimatedTime': '10-15 minutes',
      'cardCount': 20,
    };
    
    // Determine best recommendation based on user data
    if (weakAreas.isNotEmpty && userPerformance.accuracy < 0.7) {
      recommendations['primaryRecommendation'] = 'weak';
      recommendations['recommendationReason'] = 'Focus on areas that need improvement';
      recommendations['estimatedTime'] = '15-20 minutes';
      recommendations['cardCount'] = 25;
    } else if (userPerformance.accuracy >= 0.85 && masteredSkills.isNotEmpty) {
      recommendations['primaryRecommendation'] = 'mastery';
      recommendations['recommendationReason'] = 'Challenge yourself with advanced problems';
      recommendations['estimatedTime'] = '20-25 minutes';
      recommendations['cardCount'] = 15;
    } else if (userPerformance.accuracy >= 0.6) {
      recommendations['primaryRecommendation'] = 'adaptive';
      recommendations['recommendationReason'] = 'Personalized mix based on your progress';
      recommendations['estimatedTime'] = '12-18 minutes';
      recommendations['cardCount'] = 20;
    }
    
    return recommendations;
  }

  /// Generate adaptive flashcards based on user performance
  Future<List<Flashcard>> generateAdaptiveFlashcards({
    required String subjectId,
    String? skillId,
    int count = 20,
  }) async {
    final userPerformance = await _getUserPerformanceData(subjectId, skillId);
    final flashcards = <Flashcard>[];

    // Mix different types of cards based on performance
    if (userPerformance.accuracy < 0.6) {
      // Focus on reinforcement for struggling users
      final reinforcementCards = await generateSkillReinforcementCards(
        subjectId: subjectId,
        skillId: skillId ?? '',
        count: (count * 0.7).round(),
      );
      flashcards.addAll(reinforcementCards);
      
      // Add some review cards
      final reviewCards = await generateWeakAreaReviewCards(
        subjectId: subjectId,
        count: (count * 0.3).round(),
      );
      flashcards.addAll(reviewCards);
      
    } else if (userPerformance.accuracy > 0.85) {
      // Challenge advanced users with mastery content
      final masteryCards = await generateMasteryCards(
        subjectId: subjectId,
        count: (count * 0.6).round(),
      );
      flashcards.addAll(masteryCards);
      
      // Add some mixed review
      final mixedCards = await generateFlashcardsFromLessons(
        subjectId: subjectId,
        skillId: skillId,
        maxCards: (count * 0.4).round(),
      );
      flashcards.addAll(mixedCards);
      
    } else {
      // Balanced approach for average performers
      final balancedCards = await generateFlashcardsFromLessons(
        subjectId: subjectId,
        skillId: skillId,
        maxCards: count,
      );
      flashcards.addAll(balancedCards);
    }

    // Shuffle and limit
    flashcards.shuffle(_random);
    return flashcards.take(count).toList();
  }

  /// Private helper methods

  Future<List<Lesson>> _getCompletedLessons(String subjectId, String? skillId) async {
    // This would typically query a database or storage
    // For now, we'll simulate with generated data
    final subject = _levelService.generateSubject(
      SubjectType.values.firstWhere((s) => s.name == subjectId),
    );
    
    final lessons = <Lesson>[];
    for (final unit in subject.units) {
      for (final skill in unit.skills) {
        if (skillId != null && skill.id != skillId) continue;
        
        // Simulate some completed lessons
        final completedCount = _random.nextInt(skill.lessons.length);
        for (int i = 0; i < completedCount; i++) {
          final lesson = skill.lessons[i];
          lessons.add(lesson.copyWith(isCompleted: true));
        }
      }
    }
    
    return lessons;
  }

  Future<List<Flashcard>> _generateFlashcardsFromLesson(Lesson lesson) async {
    final flashcards = <Flashcard>[];
    
    // Generate 2-4 flashcards per lesson
    final cardCount = 2 + _random.nextInt(3);
    
    for (int i = 0; i < cardCount && i < lesson.questions.length; i++) {
      final question = lesson.questions[i];
      final flashcard = await _convertQuestionToFlashcard(question, lesson);
      flashcards.add(flashcard);
    }
    
    return flashcards;
  }

  Future<Flashcard> _convertQuestionToFlashcard(Question question, Lesson lesson) async {
    final now = DateTime.now();
    final multimediaList = _generateMultimediaContent(question);
    
    return Flashcard(
      id: 'fc_${question.id}',
      front: question.questionText,
      back: question.explanation ?? _generateExplanation(question),
      type: _mapQuestionTypeToFlashcardType(question.type),
      subjectId: question.subject.name,
      skillId: _extractSkillId(lesson.id),
      difficulty: question.difficulty,
      tags: [lesson.title, question.subject.name],
      createdAt: now,
      lastReviewDate: null,
      nextReviewDate: now,
      interval: 1,
      easeFactor: 2.5,
      repetitions: 0,
      multimedia: multimediaList.isNotEmpty ? multimediaList.first : null,
    );
  }

  FlashcardType _mapQuestionTypeToFlashcardType(QuestionType questionType) {
    switch (questionType) {
      case QuestionType.multipleChoice:
        return FlashcardType.multiple_choice;
      case QuestionType.trueFalse:
        return FlashcardType.true_false;
      case QuestionType.fillInTheBlank:
        return FlashcardType.fill_blank;
      case QuestionType.shortAnswer:
        return FlashcardType.basic;
      case QuestionType.numericInput:
        return FlashcardType.basic;
      case QuestionType.dragDrop:
        return FlashcardType.matching;
      case QuestionType.clickableAnswer:
        return FlashcardType.basic;
      default:
        return FlashcardType.basic;
    }
  }

  String _generateExplanation(Question question) {
    // Generate a basic explanation if none exists
    return 'The correct answer is: ${question.correctAnswer}';
  }

  List<MultimediaContent> _generateMultimediaContent(Question question) {
    final content = <MultimediaContent>[];
    
    // Add subject-specific multimedia based on question content
    if (question.subject == 'math' && question.questionText.contains('graph')) {
      content.add(MultimediaContent(
        id: 'graph_${question.id}',
        type: MultimediaType.image,
        url: 'assets/images/math/graph_placeholder.svg',
        description: 'Mathematical graph illustration',
      ));
    }
    
    return content;
  }

  /// Clear flashcard cache for a subject
  Future<void> clearFlashcardCache(String subjectId) async {
    // This would clear any cached flashcard data
    // Implementation would depend on the caching strategy
  }

  /// Get flashcard statistics for a subject
  Future<Map<String, int>> getFlashcardStatistics(String subjectId) async {
    final completedLessons = await _getCompletedLessons(subjectId, null);
    final weakAreas = await _identifyWeakSkills(subjectId);
    final masteredSkills = await _getMasteredSkills(subjectId);
    
    int totalPossibleCards = 0;
    for (final lesson in completedLessons) {
      totalPossibleCards += lesson.questions.length;
    }
    
    return {
      'totalAvailable': totalPossibleCards,
      'weakAreaCards': weakAreas.length * 5, // Estimate
      'masteryCards': masteredSkills.length * 3, // Estimate
      'completedLessons': completedLessons.length,
    };
  }

  String _extractSkillId(String lessonId) {
    // Extract skill ID from lesson ID pattern
    final parts = lessonId.split('_');
    if (parts.length >= 4) {
      return '${parts[0]}_${parts[1]}_${parts[2]}_${parts[3]}';
    }
    return '';
  }

  Future<Skill?> _getSkillById(String subjectId, String skillId) async {
    final subject = _levelService.generateSubject(
      SubjectType.values.firstWhere((s) => s.name == subjectId),
    );
    
    for (final unit in subject.units) {
      for (final skill in unit.skills) {
        if (skill.id == skillId) {
          return skill;
        }
      }
    }
    
    return null;
  }

  int _prioritizeCard(Flashcard a, Flashcard b, Skill skill) {
    // Prioritize based on difficulty and review history
    final aDifficulty = a.difficulty;
    final bDifficulty = b.difficulty;
    
    // Higher difficulty cards get higher priority for reinforcement
    return bDifficulty.compareTo(aDifficulty);
  }

  Future<List<String>> _identifyWeakSkills(String subjectId) async {
    // This would analyze user performance data
    // For now, return some mock weak skills
    return ['${subjectId}_unit_0_skill_1', '${subjectId}_unit_1_skill_2'];
  }

  Future<List<String>> _getMasteredSkills(String subjectId) async {
    // This would identify skills with high completion rates
    return ['${subjectId}_unit_0_skill_0'];
  }

  Future<List<Flashcard>> _generateMasteryFlashcards(Skill skill) async {
    // Generate advanced synthesis questions for mastered skills
    final flashcards = <Flashcard>[];
    final now = DateTime.now();
    
    // Create 2-3 advanced flashcards per mastered skill
    for (int i = 0; i < 3; i++) {
      flashcards.add(Flashcard(
        id: 'mastery_${skill.id}_$i',
        front: 'Advanced: ${skill.name} - Synthesis Question ${i + 1}',
        back: 'This requires deep understanding of ${skill.name} concepts.',
        type: FlashcardType.basic,
        subjectId: _extractSubjectId(skill.id),
        skillId: skill.id,
        difficulty: (8.0 + _random.nextDouble() * 2.0).round(), // High difficulty
        tags: ['mastery', 'advanced', skill.name],
        createdAt: now,
        lastReviewDate: null,
        nextReviewDate: now,
        interval: 1,
        easeFactor: 2.5,
        repetitions: 0,
        multimedia: null,
      ));
    }
    
    return flashcards;
  }

  String _extractSubjectId(String skillId) {
    return skillId.split('_')[0];
  }

  int _calculateFlashcardXp(List<ReviewResult> results) {
    int totalXp = 0;
    
    for (final result in results) {
      switch (result.rating) {
        case ReviewRating.again:
          totalXp += 1;
          break;
        case ReviewRating.hard:
          totalXp += 3;
          break;
        case ReviewRating.good:
          totalXp += 5;
          break;
        case ReviewRating.easy:
          totalXp += 8;
          break;
      }
    }
    
    return totalXp;
  }

  Future<void> _checkUnlockConditions(String subjectId, String skillId) async {
    // Parse skill ID to extract unit and skill indices
    // Assuming skillId format is "unitIndex_skillIndex" or similar
    final parts = skillId.split('_');
    final unitIndex = parts.length > 0 ? int.tryParse(parts[0]) ?? 0 : 0;
    final skillIndex = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    
    // Check if skill mastery unlocks new content
    final skillProgress = _unlockService.getSkillProgress(subjectId, unitIndex, skillIndex);
    
    if (skillProgress >= 0.8) {
      // Unlock next skill or unit - assuming lessonIndex 0 for simplicity
      await _unlockService.unlockNextContent(subjectId, unitIndex, skillIndex, 0);
    }
  }

  Future<UserPerformanceData> _getUserPerformanceData(String subjectId, String? skillId) async {
    // This would fetch real user performance data
    // For now, return mock data
    return UserPerformanceData(
      accuracy: 0.7 + _random.nextDouble() * 0.3,
      averageResponseTime: 5.0 + _random.nextDouble() * 10.0,
      totalReviews: 50 + _random.nextInt(200),
      streakDays: _random.nextInt(30),
    );
  }

  /// Get subject progress summary
  Future<Map<String, dynamic>> getSubjectProgressSummary(String subjectId) async {
    final userPerformance = await _getUserPerformanceData(subjectId, null);
    final completedLessons = await _getCompletedLessons(subjectId, null);
    final weakAreas = await _identifyWeakSkills(subjectId);
    final masteredSkills = await _getMasteredSkills(subjectId);
    
    return {
      'accuracy': userPerformance.accuracy,
      'totalReviews': userPerformance.totalReviews,
      'streakDays': userPerformance.streakDays,
      'completedLessons': completedLessons.length,
      'weakAreas': weakAreas.length,
      'masteredSkills': masteredSkills.length,
      'averageResponseTime': userPerformance.averageResponseTime,
    };
  }
}

/// Data class for user performance metrics
class UserPerformanceData {
  final double accuracy;
  final double averageResponseTime;
  final int totalReviews;
  final int streakDays;

  UserPerformanceData({
    required this.accuracy,
    required this.averageResponseTime,
    required this.totalReviews,
    required this.streakDays,
  });
}

/// Enum for review ratings
enum ReviewRating {
  again,
  hard,
  good,
  easy,
}

/// Class for review results
class ReviewResult {
  final String flashcardId;
  final ReviewRating rating;
  final DateTime reviewedAt;
  final double responseTime;

  ReviewResult({
    required this.flashcardId,
    required this.rating,
    required this.reviewedAt,
    required this.responseTime,
  });
}

/// Extension methods for Lesson
extension LessonExtension on Lesson {
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
}