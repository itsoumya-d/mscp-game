/// Represents a skill node in the dependency tree for progressive unlock system
/// Supports hierarchical skill structure for 50,000 educational levels
class SkillNode {
  final String id;
  final String name;
  final String description;
  final String subject;
  final List<int> levelRange; // [startLevel, endLevel]
  final List<String> prerequisites;
  final List<String> children;
  final UnlockCriteria unlockCriteria;
  final SkillCategory category;
  final int difficulty; // 1-10 scale
  final Map<String, dynamic> metadata;

  const SkillNode({
    required this.id,
    required this.name,
    required this.description,
    required this.subject,
    required this.levelRange,
    required this.prerequisites,
    required this.children,
    required this.unlockCriteria,
    required this.category,
    required this.difficulty,
    this.metadata = const {},
  });

  /// Creates a SkillNode from JSON data
  factory SkillNode.fromJson(Map<String, dynamic> json) {
    return SkillNode(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      subject: json['subject'] as String,
      levelRange: List<int>.from(json['levelRange'] as List),
      prerequisites: List<String>.from(json['prerequisites'] as List),
      children: List<String>.from(json['children'] as List),
      unlockCriteria: UnlockCriteria.fromJson(json['unlockCriteria'] as Map<String, dynamic>),
      category: SkillCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => SkillCategory.foundation,
      ),
      difficulty: json['difficulty'] as int,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Converts SkillNode to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subject': subject,
      'levelRange': levelRange,
      'prerequisites': prerequisites,
      'children': children,
      'unlockCriteria': unlockCriteria.toJson(),
      'category': category.name,
      'difficulty': difficulty,
      'metadata': metadata,
    };
  }

  /// Checks if this skill contains a specific level
  bool containsLevel(int level) {
    return level >= levelRange[0] && level <= levelRange[1];
  }

  /// Gets the total number of levels in this skill
  int get totalLevels => levelRange[1] - levelRange[0] + 1;

  /// Checks if this is a root skill (no prerequisites)
  bool get isRoot => prerequisites.isEmpty;

  /// Checks if this is a leaf skill (no children)
  bool get isLeaf => children.isEmpty;

  /// Creates a copy with updated properties
  SkillNode copyWith({
    String? id,
    String? name,
    String? description,
    String? subject,
    List<int>? levelRange,
    List<String>? prerequisites,
    List<String>? children,
    UnlockCriteria? unlockCriteria,
    SkillCategory? category,
    int? difficulty,
    Map<String, dynamic>? metadata,
  }) {
    return SkillNode(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      levelRange: levelRange ?? this.levelRange,
      prerequisites: prerequisites ?? this.prerequisites,
      children: children ?? this.children,
      unlockCriteria: unlockCriteria ?? this.unlockCriteria,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SkillNode && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SkillNode(id: $id, name: $name, levels: ${levelRange[0]}-${levelRange[1]})';
  }
}

/// Categories for organizing skills in the dependency tree
enum SkillCategory {
  foundation,     // Basic foundational skills
  core,          // Core subject skills
  advanced,      // Advanced concepts
  application,   // Real-world applications
  mastery,       // Mastery-level skills
  crossSubject,  // Cross-subject integration
  special,       // Special topics or challenges
}

/// Criteria required to unlock a skill
class UnlockCriteria {
  final double minAccuracy;
  final int minXP;
  final List<int> requiredLevels;
  final double minMasteryScore;
  final int minCompletedSkills;
  final Duration? timeRequirement;
  final List<String> requiredAchievements;
  final Map<String, dynamic> customCriteria;

  const UnlockCriteria({
    this.minAccuracy = 0.0,
    this.minXP = 0,
    this.requiredLevels = const [],
    this.minMasteryScore = 0.0,
    this.minCompletedSkills = 0,
    this.timeRequirement,
    this.requiredAchievements = const [],
    this.customCriteria = const {},
  });

  /// Creates UnlockCriteria from JSON
  factory UnlockCriteria.fromJson(Map<String, dynamic> json) {
    return UnlockCriteria(
      minAccuracy: (json['minAccuracy'] as num?)?.toDouble() ?? 0.0,
      minXP: json['minXP'] as int? ?? 0,
      requiredLevels: List<int>.from(json['requiredLevels'] as List? ?? []),
      minMasteryScore: (json['minMasteryScore'] as num?)?.toDouble() ?? 0.0,
      minCompletedSkills: json['minCompletedSkills'] as int? ?? 0,
      timeRequirement: json['timeRequirement'] != null 
        ? Duration(seconds: json['timeRequirement'] as int)
        : null,
      requiredAchievements: List<String>.from(json['requiredAchievements'] as List? ?? []),
      customCriteria: json['customCriteria'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'minAccuracy': minAccuracy,
      'minXP': minXP,
      'requiredLevels': requiredLevels,
      'minMasteryScore': minMasteryScore,
      'minCompletedSkills': minCompletedSkills,
      'timeRequirement': timeRequirement?.inSeconds,
      'requiredAchievements': requiredAchievements,
      'customCriteria': customCriteria,
    };
  }

  /// Creates a copy with updated properties
  UnlockCriteria copyWith({
    double? minAccuracy,
    int? minXP,
    List<int>? requiredLevels,
    double? minMasteryScore,
    int? minCompletedSkills,
    Duration? timeRequirement,
    List<String>? requiredAchievements,
    Map<String, dynamic>? customCriteria,
  }) {
    return UnlockCriteria(
      minAccuracy: minAccuracy ?? this.minAccuracy,
      minXP: minXP ?? this.minXP,
      requiredLevels: requiredLevels ?? this.requiredLevels,
      minMasteryScore: minMasteryScore ?? this.minMasteryScore,
      minCompletedSkills: minCompletedSkills ?? this.minCompletedSkills,
      timeRequirement: timeRequirement ?? this.timeRequirement,
      requiredAchievements: requiredAchievements ?? this.requiredAchievements,
      customCriteria: customCriteria ?? this.customCriteria,
    );
  }
}