/// Represents a personalized learning path for a user
/// Manages progression through 50,000 educational levels with adaptive pathfinding
class LearningPath {
  final String id;
  final String userId;
  final String name;
  final String description;
  final LearningPathType type;
  final List<PathSegment> segments;
  final PathMetadata metadata;
  final PathProgress progress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const LearningPath({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.type,
    required this.segments,
    required this.metadata,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Creates LearningPath from JSON
  factory LearningPath.fromJson(Map<String, dynamic> json) {
    return LearningPath(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: LearningPathType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LearningPathType.adaptive,
      ),
      segments: (json['segments'] as List)
          .map((e) => PathSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: PathMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      progress: PathProgress.fromJson(json['progress'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'type': type.name,
      'segments': segments.map((e) => e.toJson()).toList(),
      'metadata': metadata.toJson(),
      'progress': progress.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Gets the current active segment
  PathSegment? get currentSegment {
    return segments.firstWhere(
      (segment) => segment.status == SegmentStatus.active,
      orElse: () => segments.firstWhere(
        (segment) => segment.status == SegmentStatus.pending,
        orElse: () => segments.isNotEmpty ? segments.first : PathSegment.empty(),
      ),
    );
  }

  /// Gets the next recommended level
  int? get nextRecommendedLevel {
    final current = currentSegment;
    if (current == null) return null;
    
    final nextLevel = current.levels.firstWhere(
      (level) => level.status == LevelStatus.locked || level.status == LevelStatus.available,
      orElse: () => PathLevel.empty(),
    );
    
    return nextLevel?.levelId;
  }

  /// Gets all recommended levels from all segments
  List<String> get recommendedLevels {
    final recommendedLevels = <String>[];
    for (final segment in segments) {
      for (final level in segment.levels) {
        if (level.status == LevelStatus.available || level.status == LevelStatus.inProgress) {
          recommendedLevels.add(level.levelId.toString());
        }
      }
    }
    return recommendedLevels;
  }

  /// Calculates overall completion percentage
  double get completionPercentage {
    if (segments.isEmpty) return 0.0;
    
    final totalLevels = segments.fold<int>(0, (sum, segment) => sum + segment.levels.length);
    final completedLevels = segments.fold<int>(0, (sum, segment) => 
      sum + segment.levels.where((level) => level.status == LevelStatus.completed).length);
    
    return totalLevels > 0 ? completedLevels / totalLevels : 0.0;
  }

  /// Creates a copy with updated properties
  LearningPath copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    LearningPathType? type,
    List<PathSegment>? segments,
    PathMetadata? metadata,
    PathProgress? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return LearningPath(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      segments: segments ?? this.segments,
      metadata: metadata ?? this.metadata,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LearningPath && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LearningPath(id: $id, name: $name, completion: ${(completionPercentage * 100).toInt()}%)';
  }
}

/// Types of learning paths
enum LearningPathType {
  adaptive,        // AI-generated adaptive path
  structured,      // Predefined curriculum path
  exploratory,     // User-driven exploration
  remedial,        // Focused on skill gaps
  accelerated,     // Fast-track for advanced learners
  collaborative,   // Group-based learning
  projectBased,    // Project-driven learning
  gamified,        // Game-like progression
}

/// Represents a segment of a learning path
class PathSegment {
  final String id;
  final String name;
  final String description;
  final SegmentType type;
  final List<PathLevel> levels;
  final SegmentStatus status;
  final Map<String, dynamic> requirements;
  final int order;
  final Duration estimatedDuration;
  final List<String> skillsFocused;

  const PathSegment({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.levels,
    required this.status,
    this.requirements = const {},
    required this.order,
    required this.estimatedDuration,
    this.skillsFocused = const [],
  });

  /// Creates an empty PathSegment
  factory PathSegment.empty() {
    return const PathSegment(
      id: '',
      name: '',
      description: '',
      type: SegmentType.sequential,
      levels: [],
      status: SegmentStatus.pending,
      order: 0,
      estimatedDuration: Duration.zero,
    );
  }

  /// Creates PathSegment from JSON
  factory PathSegment.fromJson(Map<String, dynamic> json) {
    return PathSegment(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: SegmentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SegmentType.sequential,
      ),
      levels: (json['levels'] as List)
          .map((e) => PathLevel.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: SegmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SegmentStatus.pending,
      ),
      requirements: json['requirements'] as Map<String, dynamic>? ?? {},
      order: json['order'] as int,
      estimatedDuration: Duration(minutes: json['estimatedDurationMinutes'] as int),
      skillsFocused: (json['skillsFocused'] as List?)?.cast<String>() ?? [],
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'levels': levels.map((e) => e.toJson()).toList(),
      'status': status.name,
      'requirements': requirements,
      'order': order,
      'estimatedDurationMinutes': estimatedDuration.inMinutes,
      'skillsFocused': skillsFocused,
    };
  }

  /// Calculates completion percentage for this segment
  double get completionPercentage {
    if (levels.isEmpty) return 0.0;
    final completed = levels.where((level) => level.status == LevelStatus.completed).length;
    return completed / levels.length;
  }

  @override
  String toString() {
    return 'PathSegment(id: $id, name: $name, completion: ${(completionPercentage * 100).toInt()}%)';
  }
}

/// Types of path segments
enum SegmentType {
  sequential,      // Linear progression
  branching,       // Multiple paths available
  mastery,         // Focus on skill mastery
  assessment,      // Evaluation segment
  project,         // Project-based segment
  review,          // Review and reinforcement
  challenge,       // Special challenge segment
}

/// Status of a path segment
enum SegmentStatus {
  pending,         // Not yet started
  active,          // Currently in progress
  completed,       // Finished successfully
  skipped,         // Bypassed by user/system
  blocked,         // Cannot proceed due to requirements
}

/// Represents a level within a path segment
class PathLevel {
  final int levelId;
  final String name;
  final LevelStatus status;
  final double? score;
  final int attempts;
  final DateTime? completedAt;
  final Duration? timeSpent;
  final Map<String, dynamic> metadata;

  const PathLevel({
    required this.levelId,
    required this.name,
    required this.status,
    this.score,
    this.attempts = 0,
    this.completedAt,
    this.timeSpent,
    this.metadata = const {},
  });

  /// Creates an empty PathLevel
  factory PathLevel.empty() {
    return const PathLevel(
      levelId: 0,
      name: '',
      status: LevelStatus.locked,
    );
  }

  /// Creates PathLevel from JSON
  factory PathLevel.fromJson(Map<String, dynamic> json) {
    return PathLevel(
      levelId: json['levelId'] as int,
      name: json['name'] as String,
      status: LevelStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LevelStatus.locked,
      ),
      score: json['score'] as double?,
      attempts: json['attempts'] as int? ?? 0,
      completedAt: json['completedAt'] != null 
        ? DateTime.parse(json['completedAt'] as String)
        : null,
      timeSpent: json['timeSpentMinutes'] != null 
        ? Duration(minutes: json['timeSpentMinutes'] as int)
        : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'levelId': levelId,
      'name': name,
      'status': status.name,
      'score': score,
      'attempts': attempts,
      'completedAt': completedAt?.toIso8601String(),
      'timeSpentMinutes': timeSpent?.inMinutes,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'PathLevel(id: $levelId, name: $name, status: ${status.name})';
  }
}

/// Status of a level in the learning path
enum LevelStatus {
  locked,          // Not yet available
  available,       // Ready to be attempted
  inProgress,      // Currently being played
  completed,       // Successfully finished
  mastered,        // Completed with high score
  failed,          // Failed multiple attempts
  skipped,         // Bypassed by user/system
}

/// Metadata for a learning path
class PathMetadata {
  final LearningStyle learningStyle;
  final DifficultyPreference difficultyPreference;
  final List<String> preferredSubjects;
  final List<String> weakAreas;
  final List<String> strongAreas;
  final Map<String, dynamic> personalizations;
  final DateTime lastAnalyzed;

  const PathMetadata({
    required this.learningStyle,
    required this.difficultyPreference,
    this.preferredSubjects = const [],
    this.weakAreas = const [],
    this.strongAreas = const [],
    this.personalizations = const {},
    required this.lastAnalyzed,
  });

  /// Creates PathMetadata from JSON
  factory PathMetadata.fromJson(Map<String, dynamic> json) {
    return PathMetadata(
      learningStyle: LearningStyle.values.firstWhere(
        (e) => e.name == json['learningStyle'],
        orElse: () => LearningStyle.balanced,
      ),
      difficultyPreference: DifficultyPreference.values.firstWhere(
        (e) => e.name == json['difficultyPreference'],
        orElse: () => DifficultyPreference.adaptive,
      ),
      preferredSubjects: (json['preferredSubjects'] as List?)?.cast<String>() ?? [],
      weakAreas: (json['weakAreas'] as List?)?.cast<String>() ?? [],
      strongAreas: (json['strongAreas'] as List?)?.cast<String>() ?? [],
      personalizations: json['personalizations'] as Map<String, dynamic>? ?? {},
      lastAnalyzed: DateTime.parse(json['lastAnalyzed'] as String),
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'learningStyle': learningStyle.name,
      'difficultyPreference': difficultyPreference.name,
      'preferredSubjects': preferredSubjects,
      'weakAreas': weakAreas,
      'strongAreas': strongAreas,
      'personalizations': personalizations,
      'lastAnalyzed': lastAnalyzed.toIso8601String(),
    };
  }
}

/// Learning style preferences
enum LearningStyle {
  visual,          // Prefers visual content
  auditory,        // Prefers audio content
  kinesthetic,     // Prefers interactive content
  reading,         // Prefers text-based content
  balanced,        // No strong preference
}

/// Difficulty preference settings
enum DifficultyPreference {
  easy,            // Prefers easier challenges
  moderate,        // Prefers moderate challenges
  hard,            // Prefers difficult challenges
  adaptive,        // System determines optimal difficulty
}

/// Progress tracking for a learning path
class PathProgress {
  final int totalLevels;
  final int completedLevels;
  final int masteredLevels;
  final double averageScore;
  final Duration totalTimeSpent;
  final DateTime lastActivity;
  final int currentStreak;
  final int longestStreak;
  final Map<String, double> skillProgress;

  const PathProgress({
    required this.totalLevels,
    required this.completedLevels,
    required this.masteredLevels,
    required this.averageScore,
    required this.totalTimeSpent,
    required this.lastActivity,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.skillProgress = const {},
  });

  /// Creates PathProgress from JSON
  factory PathProgress.fromJson(Map<String, dynamic> json) {
    return PathProgress(
      totalLevels: json['totalLevels'] as int,
      completedLevels: json['completedLevels'] as int,
      masteredLevels: json['masteredLevels'] as int,
      averageScore: (json['averageScore'] as num).toDouble(),
      totalTimeSpent: Duration(minutes: json['totalTimeSpentMinutes'] as int),
      lastActivity: DateTime.parse(json['lastActivity'] as String),
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      skillProgress: (json['skillProgress'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {},
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalLevels': totalLevels,
      'completedLevels': completedLevels,
      'masteredLevels': masteredLevels,
      'averageScore': averageScore,
      'totalTimeSpentMinutes': totalTimeSpent.inMinutes,
      'lastActivity': lastActivity.toIso8601String(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'skillProgress': skillProgress,
    };
  }

  /// Calculates completion percentage
  double get completionPercentage {
    return totalLevels > 0 ? completedLevels / totalLevels : 0.0;
  }

  /// Calculates mastery percentage
  double get masteryPercentage {
    return completedLevels > 0 ? masteredLevels / completedLevels : 0.0;
  }

  @override
  String toString() {
    return 'PathProgress(completed: $completedLevels/$totalLevels, avg: ${(averageScore * 100).toInt()}%)';
  }
}