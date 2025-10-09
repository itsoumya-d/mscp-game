/// Represents different types of unlock conditions for the progressive unlock system
/// Supports multiple unlock mechanisms for 50,000 educational levels
class UnlockCondition {
  final String id;
  final UnlockConditionType type;
  final Map<String, dynamic> parameters;
  final double weight; // Importance in unlock decision (0.0 - 1.0)
  final String description; // User-friendly explanation
  final bool isRequired; // Must be satisfied vs. optional
  final DateTime? validFrom; // Time-based availability
  final DateTime? validUntil; // Expiration date

  const UnlockCondition({
    required this.id,
    required this.type,
    required this.parameters,
    required this.weight,
    required this.description,
    this.isRequired = true,
    this.validFrom,
    this.validUntil,
  });

  /// Creates UnlockCondition from JSON
  factory UnlockCondition.fromJson(Map<String, dynamic> json) {
    return UnlockCondition(
      id: json['id'] as String,
      type: UnlockConditionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => UnlockConditionType.sequential,
      ),
      parameters: json['parameters'] as Map<String, dynamic>,
      weight: (json['weight'] as num).toDouble(),
      description: json['description'] as String,
      isRequired: json['isRequired'] as bool? ?? true,
      validFrom: json['validFrom'] != null 
        ? DateTime.parse(json['validFrom'] as String)
        : null,
      validUntil: json['validUntil'] != null 
        ? DateTime.parse(json['validUntil'] as String)
        : null,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'parameters': parameters,
      'weight': weight,
      'description': description,
      'isRequired': isRequired,
      'validFrom': validFrom?.toIso8601String(),
      'validUntil': validUntil?.toIso8601String(),
    };
  }

  /// Checks if this condition is currently valid (time-based)
  bool get isCurrentlyValid {
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    return true;
  }

  /// Creates a copy with updated properties
  UnlockCondition copyWith({
    String? id,
    UnlockConditionType? type,
    Map<String, dynamic>? parameters,
    double? weight,
    String? description,
    bool? isRequired,
    DateTime? validFrom,
    DateTime? validUntil,
  }) {
    return UnlockCondition(
      id: id ?? this.id,
      type: type ?? this.type,
      parameters: parameters ?? this.parameters,
      weight: weight ?? this.weight,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnlockCondition && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UnlockCondition(id: $id, type: ${type.name}, weight: $weight)';
  }
}

/// Types of unlock conditions supported by the progressive unlock system
enum UnlockConditionType {
  // Basic Conditions
  sequential,           // Complete previous level
  accuracyBased,       // Achieve X% accuracy
  xpBased,             // Earn X amount of XP
  timeBased,           // Available after date/time
  
  // Skill-Based Conditions
  skillMastery,        // Master specific skill
  conceptualUnderstanding, // Demonstrate concept grasp
  crossSubjectSkill,   // Skills from multiple subjects
  prerequisiteCompletion, // Complete prerequisite levels
  
  // Achievement-Based Conditions
  achievementUnlock,   // Complete specific achievement
  streakBased,         // Maintain performance streak
  challengeCompletion, // Complete special challenges
  badgeCollection,     // Collect specific badges
  
  // Adaptive Conditions
  personalizedPath,    // AI-recommended next step
  difficultyOptimal,   // Optimal difficulty match
  learningVelocity,    // Based on learning speed
  performanceTrend,    // Based on performance trends
  
  // Social Conditions
  peerComparison,      // Performance relative to peers
  collaborativeUnlock, // Group achievements
  mentorRecommendation, // Teacher/parent unlock
  socialChallenge,     // Social interaction requirements
  
  // Advanced Conditions
  multiFactorAuth,     // Multiple conditions combined
  adaptiveThreshold,   // Dynamic threshold adjustment
  contextualUnlock,    // Context-aware unlocking
  customCondition,     // Custom business logic
}

/// Result of evaluating an unlock condition
class UnlockEvaluation {
  final String conditionId;
  final bool isSatisfied;
  final double score; // 0.0 - 1.0, how well condition is met
  final String feedback; // Explanation for user
  final Map<String, dynamic> details; // Additional evaluation data
  final DateTime evaluatedAt;

  const UnlockEvaluation({
    required this.conditionId,
    required this.isSatisfied,
    required this.score,
    required this.feedback,
    this.details = const {},
    required this.evaluatedAt,
  });

  /// Creates UnlockEvaluation from JSON
  factory UnlockEvaluation.fromJson(Map<String, dynamic> json) {
    return UnlockEvaluation(
      conditionId: json['conditionId'] as String,
      isSatisfied: json['isSatisfied'] as bool,
      score: (json['score'] as num).toDouble(),
      feedback: json['feedback'] as String,
      details: json['details'] as Map<String, dynamic>? ?? {},
      evaluatedAt: DateTime.parse(json['evaluatedAt'] as String),
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'conditionId': conditionId,
      'isSatisfied': isSatisfied,
      'score': score,
      'feedback': feedback,
      'details': details,
      'evaluatedAt': evaluatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UnlockEvaluation(condition: $conditionId, satisfied: $isSatisfied, score: $score)';
  }
}

/// Final decision on whether to unlock a level
class UnlockDecision {
  final int levelId;
  final bool shouldUnlock;
  final double confidenceScore; // 0.0 - 1.0
  final List<UnlockEvaluation> evaluations;
  final String reasoning; // Explanation of decision
  final UnlockDecisionType decisionType;
  final Map<String, dynamic> metadata;
  final DateTime decidedAt;

  const UnlockDecision({
    required this.levelId,
    required this.shouldUnlock,
    required this.confidenceScore,
    required this.evaluations,
    required this.reasoning,
    required this.decisionType,
    this.metadata = const {},
    required this.decidedAt,
  });

  /// Creates UnlockDecision from multiple evaluations
  factory UnlockDecision.fromEvaluations({
    required int levelId,
    required List<UnlockEvaluation> evaluations,
    required List<UnlockCondition> conditions,
  }) {
    // Calculate weighted score
    double totalWeight = 0.0;
    double weightedScore = 0.0;
    bool allRequiredSatisfied = true;

    for (int i = 0; i < evaluations.length; i++) {
      final evaluation = evaluations[i];
      final condition = conditions.firstWhere((c) => c.id == evaluation.conditionId);
      
      totalWeight += condition.weight;
      weightedScore += evaluation.score * condition.weight;
      
      if (condition.isRequired && !evaluation.isSatisfied) {
        allRequiredSatisfied = false;
      }
    }

    final averageScore = totalWeight > 0 ? weightedScore / totalWeight : 0.0;
    final shouldUnlock = allRequiredSatisfied && averageScore >= 0.7; // 70% threshold

    // Determine decision type
    UnlockDecisionType decisionType;
    if (averageScore >= 0.9) {
      decisionType = UnlockDecisionType.confident;
    } else if (averageScore >= 0.7) {
      decisionType = UnlockDecisionType.standard;
    } else if (averageScore >= 0.5) {
      decisionType = UnlockDecisionType.conditional;
    } else {
      decisionType = UnlockDecisionType.denied;
    }

    // Generate reasoning
    final reasoning = _generateReasoning(evaluations, conditions, shouldUnlock, averageScore);

    return UnlockDecision(
      levelId: levelId,
      shouldUnlock: shouldUnlock,
      confidenceScore: averageScore,
      evaluations: evaluations,
      reasoning: reasoning,
      decisionType: decisionType,
      decidedAt: DateTime.now(),
    );
  }

  /// Generates human-readable reasoning for the unlock decision
  static String _generateReasoning(
    List<UnlockEvaluation> evaluations,
    List<UnlockCondition> conditions,
    bool shouldUnlock,
    double score,
  ) {
    if (shouldUnlock) {
      final satisfiedCount = evaluations.where((e) => e.isSatisfied).length;
      return 'Level unlocked! You satisfied $satisfiedCount/${evaluations.length} conditions with ${(score * 100).toInt()}% overall score.';
    } else {
      final unsatisfiedRequired = evaluations
          .where((e) => !e.isSatisfied)
          .where((e) => conditions.firstWhere((c) => c.id == e.conditionId).isRequired)
          .toList();
      
      if (unsatisfiedRequired.isNotEmpty) {
        return 'Level locked. Required conditions not met: ${unsatisfiedRequired.map((e) => e.feedback).join(', ')}';
      } else {
        return 'Level locked. Overall score ${(score * 100).toInt()}% is below the 70% threshold.';
      }
    }
  }

  /// Creates UnlockDecision from JSON
  factory UnlockDecision.fromJson(Map<String, dynamic> json) {
    return UnlockDecision(
      levelId: json['levelId'] as int,
      shouldUnlock: json['shouldUnlock'] as bool,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      evaluations: (json['evaluations'] as List)
          .map((e) => UnlockEvaluation.fromJson(e as Map<String, dynamic>))
          .toList(),
      reasoning: json['reasoning'] as String,
      decisionType: UnlockDecisionType.values.firstWhere(
        (e) => e.name == json['decisionType'],
        orElse: () => UnlockDecisionType.standard,
      ),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      decidedAt: DateTime.parse(json['decidedAt'] as String),
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'levelId': levelId,
      'shouldUnlock': shouldUnlock,
      'confidenceScore': confidenceScore,
      'evaluations': evaluations.map((e) => e.toJson()).toList(),
      'reasoning': reasoning,
      'decisionType': decisionType.name,
      'metadata': metadata,
      'decidedAt': decidedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UnlockDecision(level: $levelId, unlock: $shouldUnlock, confidence: ${(confidenceScore * 100).toInt()}%)';
  }
}

/// Types of unlock decisions
enum UnlockDecisionType {
  confident,    // High confidence unlock (90%+)
  standard,     // Standard unlock (70-89%)
  conditional,  // Conditional unlock (50-69%)
  denied,       // Access denied (<50%)
}