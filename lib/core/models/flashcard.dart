import 'dart:convert';

/// Flashcard types for different learning approaches
enum FlashcardType {
  basic,           // Simple question-answer
  definition,      // Term-definition pairs
  multiple_choice, // Multiple choice questions
  true_false,      // True/false questions
  fill_blank,      // Fill in the blank
  matching,        // Match items
  problem_solving, // Math/science problems
  code,           // Code examples/exercises
}

/// Review rating based on user performance (FSRS-inspired)
enum ReviewRating {
  again,  // Incorrect/need to review again
  hard,   // Correct but difficult
  good,   // Correct with normal effort
  easy,   // Correct and easy
}

/// Multimedia content types
enum MultimediaType {
  image,
  audio,
  video,
  code,
  animation,
}

/// Multimedia content class
class MultimediaContent {
  final String id;
  final MultimediaType type;
  final String url;
  final String description;
  final Map<String, dynamic> metadata;

  MultimediaContent({
    required this.id,
    required this.type,
    required this.url,
    required this.description,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'url': url,
    'description': description,
    'metadata': metadata,
  };

  factory MultimediaContent.fromJson(Map<String, dynamic> json) => MultimediaContent(
    id: json['id'],
    type: MultimediaType.values.firstWhere((e) => e.toString() == json['type']),
    url: json['url'],
    description: json['description'],
    metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
  );
}

/// Main flashcard model with spaced repetition data
class Flashcard {
  final String id;
  final String subjectId;
  final String skillId;
  final String front;
  final String back;
  final FlashcardType type;
  final List<String> tags;
  final MultimediaContent? multimedia;
  
  // Spaced repetition algorithm data (FSRS-inspired)
  final int difficulty;        // 1-10 difficulty level
  final double easeFactor;     // Ease factor for interval calculation
  final int interval;          // Days until next review
  final int repetitions;       // Number of times reviewed
  final DateTime nextReviewDate;
  final DateTime? lastReviewDate;
  final DateTime createdAt;
  
  // Performance tracking
  final int totalReviews;
  final int correctReviews;
  final double averageResponseTime; // in seconds
  final List<ReviewRating> recentRatings;

  const Flashcard({
    required this.id,
    required this.subjectId,
    required this.skillId,
    required this.front,
    required this.back,
    required this.type,
    required this.difficulty,
    required this.easeFactor,
    required this.interval,
    required this.repetitions,
    required this.nextReviewDate,
    required this.createdAt,
    this.tags = const [],
    this.multimedia,
    this.lastReviewDate,
    this.totalReviews = 0,
    this.correctReviews = 0,
    this.averageResponseTime = 0.0,
    this.recentRatings = const [],
  });

  /// Calculate accuracy percentage
  double get accuracy => totalReviews > 0 ? correctReviews / totalReviews : 0.0;

  /// Check if card is due for review
  bool get isDue => DateTime.now().isAfter(nextReviewDate);

  /// Check if card is new (never reviewed)
  bool get isNew => repetitions == 0;

  /// Get difficulty level as string
  String get difficultyLevel {
    if (difficulty <= 2) return 'Beginner';
    if (difficulty <= 5) return 'Intermediate';
    if (difficulty <= 8) return 'Advanced';
    return 'Expert';
  }

  /// Get retention rate based on recent performance
  double get retentionRate {
    if (recentRatings.isEmpty) return 0.0;
    final goodRatings = recentRatings.where((r) => r == ReviewRating.good || r == ReviewRating.easy).length;
    return goodRatings / recentRatings.length;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'skillId': skillId,
    'front': front,
    'back': back,
    'type': type.name,
    'tags': tags,
    'multimedia': multimedia?.toJson(),
    'difficulty': difficulty,
    'easeFactor': easeFactor,
    'interval': interval,
    'repetitions': repetitions,
    'nextReviewDate': nextReviewDate.toIso8601String(),
    'lastReviewDate': lastReviewDate?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'totalReviews': totalReviews,
    'correctReviews': correctReviews,
    'averageResponseTime': averageResponseTime,
    'recentRatings': recentRatings.map((r) => r.name).toList(),
  };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
    id: json['id'],
    subjectId: json['subjectId'],
    skillId: json['skillId'],
    front: json['front'],
    back: json['back'],
    type: FlashcardType.values.firstWhere((e) => e.name == json['type']),
    tags: List<String>.from(json['tags'] ?? []),
    multimedia: json['multimedia'] != null ? MultimediaContent.fromJson(json['multimedia']) : null,
    difficulty: json['difficulty'],
    easeFactor: json['easeFactor'],
    interval: json['interval'],
    repetitions: json['repetitions'],
    nextReviewDate: DateTime.parse(json['nextReviewDate']),
    lastReviewDate: json['lastReviewDate'] != null ? DateTime.parse(json['lastReviewDate']) : null,
    createdAt: DateTime.parse(json['createdAt']),
    totalReviews: json['totalReviews'] ?? 0,
    correctReviews: json['correctReviews'] ?? 0,
    averageResponseTime: json['averageResponseTime'] ?? 0.0,
    recentRatings: (json['recentRatings'] as List?)?.map((r) => ReviewRating.values.firstWhere((e) => e.name == r)).toList() ?? [],
  );

  Flashcard copyWith({
    String? id,
    String? subjectId,
    String? skillId,
    String? front,
    String? back,
    FlashcardType? type,
    List<String>? tags,
    MultimediaContent? multimedia,
    int? difficulty,
    double? easeFactor,
    int? interval,
    int? repetitions,
    DateTime? nextReviewDate,
    DateTime? lastReviewDate,
    DateTime? createdAt,
    int? totalReviews,
    int? correctReviews,
    double? averageResponseTime,
    List<ReviewRating>? recentRatings,
  }) => Flashcard(
    id: id ?? this.id,
    subjectId: subjectId ?? this.subjectId,
    skillId: skillId ?? this.skillId,
    front: front ?? this.front,
    back: back ?? this.back,
    type: type ?? this.type,
    tags: tags ?? this.tags,
    multimedia: multimedia ?? this.multimedia,
    difficulty: difficulty ?? this.difficulty,
    easeFactor: easeFactor ?? this.easeFactor,
    interval: interval ?? this.interval,
    repetitions: repetitions ?? this.repetitions,
    nextReviewDate: nextReviewDate ?? this.nextReviewDate,
    lastReviewDate: lastReviewDate ?? this.lastReviewDate,
    createdAt: createdAt ?? this.createdAt,
    totalReviews: totalReviews ?? this.totalReviews,
    correctReviews: correctReviews ?? this.correctReviews,
    averageResponseTime: averageResponseTime ?? this.averageResponseTime,
    recentRatings: recentRatings ?? this.recentRatings,
  );
}

/// Review result for a single flashcard
class ReviewResult {
  final String flashcardId;
  final ReviewRating rating;
  final double responseTime; // in seconds
  final DateTime reviewedAt;
  final int xpEarned;

  const ReviewResult({
    required this.flashcardId,
    required this.rating,
    required this.responseTime,
    required this.reviewedAt,
    required this.xpEarned,
  });

  Map<String, dynamic> toJson() => {
    'flashcardId': flashcardId,
    'rating': rating.name,
    'responseTime': responseTime,
    'reviewedAt': reviewedAt.toIso8601String(),
    'xpEarned': xpEarned,
  };

  factory ReviewResult.fromJson(Map<String, dynamic> json) => ReviewResult(
    flashcardId: json['flashcardId'],
    rating: ReviewRating.values.firstWhere((e) => e.name == json['rating']),
    responseTime: json['responseTime'],
    reviewedAt: DateTime.parse(json['reviewedAt']),
    xpEarned: json['xpEarned'],
  );
}

/// Study result including achievements and rewards
class StudyResult {
  final Flashcard flashcard;
  final int xpEarned;
  final List<Achievement> achievements;
  final DateTime nextReviewDate;

  const StudyResult({
    required this.flashcard,
    required this.xpEarned,
    required this.achievements,
    required this.nextReviewDate,
  });
}

/// Achievement/badge model for gamification
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final int xpReward;
  final DateTime? unlockedAt;
  final bool isUnlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.xpReward,
    this.unlockedAt,
    this.isUnlocked = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'iconUrl': iconUrl,
    'xpReward': xpReward,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'isUnlocked': isUnlocked,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    iconUrl: json['iconUrl'],
    xpReward: json['xpReward'],
    unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
    isUnlocked: json['isUnlocked'] ?? false,
  );

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconUrl,
    int? xpReward,
    DateTime? unlockedAt,
    bool? isUnlocked,
  }) => Achievement(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    iconUrl: iconUrl ?? this.iconUrl,
    xpReward: xpReward ?? this.xpReward,
    unlockedAt: unlockedAt ?? this.unlockedAt,
    isUnlocked: isUnlocked ?? this.isUnlocked,
  );
}

/// Daily progress tracking
class DailyProgress {
  final int currentXp;
  final int targetXp;
  final int cardsReviewed;
  final int streak;
  final bool isGoalMet;

  const DailyProgress({
    required this.currentXp,
    required this.targetXp,
    required this.cardsReviewed,
    required this.streak,
    required this.isGoalMet,
  });

  double get progressPercentage => targetXp > 0 ? (currentXp / targetXp).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() => {
    'currentXp': currentXp,
    'targetXp': targetXp,
    'cardsReviewed': cardsReviewed,
    'streak': streak,
    'isGoalMet': isGoalMet,
  };

  factory DailyProgress.fromJson(Map<String, dynamic> json) => DailyProgress(
    currentXp: json['currentXp'],
    targetXp: json['targetXp'],
    cardsReviewed: json['cardsReviewed'],
    streak: json['streak'],
    isGoalMet: json['isGoalMet'],
  );
}