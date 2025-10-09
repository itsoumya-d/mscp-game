import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/skill_node.dart';
import '../models/learning_path.dart';
import '../models/unlock_condition.dart';
import 'skill_dependency_manager.dart';
import 'adaptive_difficulty_calculator.dart';

/// Generates personalized learning paths using AI-driven algorithms
/// Creates adaptive learning journeys for 50,000 educational levels
class PersonalizedPathGenerator {
  static PersonalizedPathGenerator? _instance;
  static PersonalizedPathGenerator get instance => _instance ??= PersonalizedPathGenerator._();
  
  PersonalizedPathGenerator._();

  final SkillDependencyManager _skillManager = SkillDependencyManager.instance;
  final AdaptiveDifficultyCalculator _difficultyCalculator = AdaptiveDifficultyCalculator.instance;
  
  // Cache for generated paths and user preferences
  final Map<String, List<LearningPath>> _pathCache = {};
  final Map<String, UserLearningPreferences> _preferencesCache = {};
  
  // Path generation parameters
  static const int _maxPathLength = 100;
  static const int _minPathLength = 10;
  static const double _difficultyProgressionRate = 0.1;
  static const double _varietyWeight = 0.3;
  static const double _efficiencyWeight = 0.4;
  static const double _engagementWeight = 0.3;

  /// Initializes the personalized path generator
  Future<void> initialize() async {
    await _skillManager.initialize();
    await _difficultyCalculator.initialize();
    await _loadUserPreferences();
  }

  /// Generates a personalized learning path for a user
  Future<LearningPath> generatePersonalizedPath(
    String userId,
    String subject,
    {
      LearningPathType? pathType,
      int? targetLevels,
      List<String>? focusAreas,
      double? targetDifficulty,
      Duration? timeConstraint,
    }
  ) async {
    final preferences = await _getUserPreferences(userId);
    final skillTree = _skillManager.getSkillsForSubject(subject);
    
    // Determine path type if not specified
    pathType ??= _determineOptimalPathType(preferences, subject);
    
    // Calculate path parameters
    final pathParams = PathGenerationParameters(
      userId: userId,
      subject: subject,
      pathType: pathType,
      targetLevels: targetLevels ?? _calculateOptimalPathLength(preferences),
      focusAreas: focusAreas ?? _identifyFocusAreas(preferences, subject),
      targetDifficulty: targetDifficulty ?? await _calculateTargetDifficulty(preferences, subject),
      timeConstraint: timeConstraint,
      preferences: preferences,
    );

    // Generate path based on type
    LearningPath path;
    switch (pathType) {
      case LearningPathType.adaptive:
        path = await _generateAdaptivePath(pathParams, skillTree);
        break;
      case LearningPathType.structured:
        path = await _generateStructuredPath(pathParams, skillTree);
        break;
      case LearningPathType.exploratory:
        path = await _generateExploratoryPath(pathParams, skillTree);
        break;
      case LearningPathType.remedial:
        path = await _generateRemedialPath(pathParams, skillTree);
        break;
      case LearningPathType.accelerated:
        path = await _generateAcceleratedPath(pathParams, skillTree);
        break;
      case LearningPathType.collaborative:
        path = await _generateCollaborativePath(pathParams, skillTree);
        break;
      case LearningPathType.projectBased:
        path = await _generateProjectBasedPath(pathParams, skillTree);
        break;
      case LearningPathType.gamified:
        path = await _generateGamifiedPath(pathParams, skillTree);
        break;
    }

    // Cache and save the generated path
    await _cachePath(userId, path);
    
    return path;
  }

  /// Generates an adaptive learning path that adjusts based on performance
  Future<LearningPath> _generateAdaptivePath(
    PathGenerationParameters params,
    List<SkillNode> skillTree
  ) async {
    final segments = <PathSegment>[];
    final usedSkills = <String>{};
    
    // Start with foundation skills
    final foundationSkills = skillTree
        .where((skill) => skill.category == SkillCategory.foundation)
        .toList()
      ..sort((a, b) => a.difficulty.compareTo(b.difficulty));

    // Create foundation segment
    if (foundationSkills.isNotEmpty) {
      final foundationSegment = await _createSkillBasedSegment(
        'Foundation Building',
        'Master fundamental concepts',
        foundationSkills.take(5).toList(),
        params,
        SegmentType.sequential,
      );
      segments.add(foundationSegment);
      usedSkills.addAll(foundationSkills.take(5).map((s) => s.id));
    }

    // Create adaptive core segments
    final coreSkills = skillTree
        .where((skill) => 
            skill.category == SkillCategory.core && 
            !usedSkills.contains(skill.id))
        .toList();

    final coreSegments = await _createAdaptiveSegments(
      coreSkills,
      params,
      'Core Concepts',
      maxSegments: 3,
    );
    segments.addAll(coreSegments);
    usedSkills.addAll(coreSegments.expand((s) => s.levels.map((l) => l.levelId.toString())));

    // Create advanced segments based on focus areas
    final advancedSkills = skillTree
        .where((skill) => 
            skill.category == SkillCategory.advanced && 
            params.focusAreas.any((area) => skill.name.toLowerCase().contains(area.toLowerCase())))
        .toList();

    if (advancedSkills.isNotEmpty) {
      final advancedSegment = await _createSkillBasedSegment(
        'Advanced Applications',
        'Apply concepts to complex problems',
        advancedSkills.take(3).toList(),
        params,
        SegmentType.branching,
      );
      segments.add(advancedSegment);
    }

    return LearningPath(
      id: _generatePathId(),
      userId: params.userId,
      name: 'Adaptive ${params.subject} Journey',
      description: 'Personalized adaptive path that adjusts to your learning pace and performance',
      type: LearningPathType.adaptive,
      segments: segments,
      metadata: PathMetadata(
        learningStyle: params.preferences.learningStyle,
        difficultyPreference: params.preferences.difficultyPreference,
        preferredSubjects: [params.subject],
        personalizations: {
          'adaptiveAdjustments': true,
          'performanceTracking': true,
          'difficultyScaling': true,
        },
        lastAnalyzed: DateTime.now(),
      ),
      progress: PathProgress(
        totalLevels: segments.fold(0, (sum, segment) => sum + segment.levels.length),
        completedLevels: 0,
        masteredLevels: 0,
        averageScore: 0.0,
        totalTimeSpent: Duration.zero,
        lastActivity: DateTime.now(),
        currentStreak: 0,
        longestStreak: 0,
        skillProgress: {},
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generates a structured learning path with clear progression
  Future<LearningPath> _generateStructuredPath(
    PathGenerationParameters params,
    List<SkillNode> skillTree
  ) async {
    final segments = <PathSegment>[];
    
    // Organize skills by category and difficulty
    final skillsByCategory = <SkillCategory, List<SkillNode>>{};
    for (final skill in skillTree) {
      skillsByCategory.putIfAbsent(skill.category, () => []).add(skill);
    }

    // Create sequential segments for each category
    final categoryOrder = [
      SkillCategory.foundation,
      SkillCategory.core,
      SkillCategory.advanced,
      SkillCategory.application,
      SkillCategory.mastery,
    ];

    for (final category in categoryOrder) {
      final categorySkills = skillsByCategory[category];
      if (categorySkills == null || categorySkills.isEmpty) continue;

      categorySkills.sort((a, b) => a.difficulty.compareTo(b.difficulty));
      
      final segment = await _createSkillBasedSegment(
        _getCategoryDisplayName(category),
        _getCategoryDescription(category),
        categorySkills,
        params,
        SegmentType.sequential,
      );
      
      segments.add(segment);
    }

    return LearningPath(
      id: _generatePathId(),
      userId: params.userId,
      name: 'Structured ${params.subject} Course',
      description: 'Systematic progression through all key concepts with clear milestones',
      type: LearningPathType.structured,
      segments: segments,
      metadata: PathMetadata(
        learningStyle: params.preferences.learningStyle,
        difficultyPreference: params.preferences.difficultyPreference,
        preferredSubjects: [params.subject],
        personalizations: {
          'structuredProgression': true,
          'clearMilestones': true,
          'systematicCoverage': true,
        },
        lastAnalyzed: DateTime.now(),
      ),
      progress: PathProgress(
        totalLevels: segments.fold(0, (sum, segment) => sum + segment.levels.length),
        completedLevels: 0,
        masteredLevels: 0,
        averageScore: 0.0,
        totalTimeSpent: Duration.zero,
        lastActivity: DateTime.now(),
        currentStreak: 0,
        longestStreak: 0,
        skillProgress: {},
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generates an exploratory learning path for discovery-based learning
  Future<LearningPath> _generateExploratoryPath(
    PathGenerationParameters params,
    List<SkillNode> skillTree
  ) async {
    final segments = <PathSegment>[];
    final random = Random();
    
    // Create diverse exploration segments
    final explorationThemes = [
      'Creative Problem Solving',
      'Real-World Applications',
      'Cross-Disciplinary Connections',
      'Advanced Challenges',
      'Innovation Projects',
    ];

    for (final theme in explorationThemes.take(3)) {
      final themeSkills = _selectSkillsForTheme(skillTree, theme, random);
      
      if (themeSkills.isNotEmpty) {
        final segment = await _createSkillBasedSegment(
          theme,
          'Explore $theme through hands-on activities',
          themeSkills,
          params,
          SegmentType.branching,
        );
        segments.add(segment);
      }
    }

    return LearningPath(
      id: _generatePathId(),
      userId: params.userId,
      name: 'Exploratory ${params.subject} Adventure',
      description: 'Discover concepts through exploration and creative problem-solving',
      type: LearningPathType.exploratory,
      segments: segments,
      metadata: PathMetadata(
        learningStyle: params.preferences.learningStyle,
        difficultyPreference: params.preferences.difficultyPreference,
        preferredSubjects: [params.subject],
        personalizations: {
          'exploratoryLearning': true,
          'creativeChallenges': true,
          'flexibleProgression': true,
        },
        lastAnalyzed: DateTime.now(),
      ),
      progress: PathProgress(
        totalLevels: segments.fold(0, (sum, segment) => sum + segment.levels.length),
        completedLevels: 0,
        masteredLevels: 0,
        averageScore: 0.0,
        totalTimeSpent: Duration.zero,
        lastActivity: DateTime.now(),
        currentStreak: 0,
        longestStreak: 0,
        skillProgress: {},
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generates a remedial learning path for skill reinforcement
  Future<LearningPath> _generateRemedialPath(
    PathGenerationParameters params,
    List<SkillNode> skillTree
  ) async {
    final segments = <PathSegment>[];
    
    // Identify weak areas from user preferences
    final weakAreas = params.preferences.weakAreas;
    final relevantSkills = skillTree
        .where((skill) => weakAreas.any((area) => 
            skill.name.toLowerCase().contains(area.toLowerCase()) ||
            skill.description.toLowerCase().contains(area.toLowerCase())))
        .toList();

    // Focus on foundation and core skills for remediation
    final remediationSkills = relevantSkills
        .where((skill) => 
            skill.category == SkillCategory.foundation ||
            skill.category == SkillCategory.core)
        .toList()
      ..sort((a, b) => a.difficulty.compareTo(b.difficulty));

    // Create focused remediation segments
    final segmentSize = max(3, remediationSkills.length ~/ 3);
    for (int i = 0; i < remediationSkills.length; i += segmentSize) {
      final segmentSkills = remediationSkills.skip(i).take(segmentSize).toList();
      
      final segment = await _createSkillBasedSegment(
        'Skill Reinforcement ${(i ~/ segmentSize) + 1}',
        'Strengthen fundamental understanding',
        segmentSkills,
        params,
        SegmentType.sequential,
      );
      
      segments.add(segment);
    }

    return LearningPath(
      id: _generatePathId(),
      userId: params.userId,
      name: 'Remedial ${params.subject} Support',
      description: 'Targeted practice to strengthen foundational skills and build confidence',
      type: LearningPathType.remedial,
      segments: segments,
      metadata: PathMetadata(
        learningStyle: params.preferences.learningStyle,
        difficultyPreference: DifficultyPreference.easy,
        preferredSubjects: [params.subject],
        weakAreas: weakAreas,
        personalizations: {
          'skillReinforcement': true,
          'foundationFocus': true,
          'confidenceBuilding': true,
        },
        lastAnalyzed: DateTime.now(),
      ),
      progress: PathProgress(
        totalLevels: segments.fold(0, (sum, segment) => sum + segment.levels.length),
        completedLevels: 0,
        masteredLevels: 0,
        averageScore: 0.0,
        totalTimeSpent: Duration.zero,
        lastActivity: DateTime.now(),
        currentStreak: 0,
        longestStreak: 0,
        skillProgress: {},
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generates an accelerated learning path for advanced learners
  Future<LearningPath> _generateAcceleratedPath(
    PathGenerationParameters params,
    List<SkillNode> skillTree
  ) async {
    final segments = <PathSegment>[];
    
    // Focus on advanced and mastery skills
    final acceleratedSkills = skillTree
        .where((skill) => 
            skill.category == SkillCategory.advanced ||
            skill.category == SkillCategory.mastery ||
            skill.category == SkillCategory.application)
        .toList()
      ..sort((a, b) => b.difficulty.compareTo(a.difficulty)); // Descending difficulty

    // Create challenging segments
    final challengeSegment = await _createSkillBasedSegment(
      'Advanced Challenges',
      'Tackle complex problems and advanced concepts',
      acceleratedSkills.take(8).toList(),
      params,
      SegmentType.branching,
    );
    segments.add(challengeSegment);

    // Add cross-subject integration if available
    final crossSubjectSkills = skillTree
        .where((skill) => skill.category == SkillCategory.crossSubject)
        .toList();

    if (crossSubjectSkills.isNotEmpty) {
      final integrationSegment = await _createSkillBasedSegment(
        'Cross-Disciplinary Integration',
        'Connect concepts across different subjects',
        crossSubjectSkills,
        params,
        SegmentType.branching,
      );
      segments.add(integrationSegment);
    }

    return LearningPath(
      id: _generatePathId(),
      userId: params.userId,
      name: 'Accelerated ${params.subject} Track',
      description: 'Fast-paced learning for advanced students with challenging content',
      type: LearningPathType.accelerated,
      segments: segments,
      metadata: PathMetadata(
        learningStyle: params.preferences.learningStyle,
        difficultyPreference: DifficultyPreference.hard,
        preferredSubjects: [params.subject],
        strongAreas: params.preferences.strongAreas,
        personalizations: {
          'acceleratedPace': true,
          'advancedContent': true,
          'challengingProblems': true,
        },
        lastAnalyzed: DateTime.now(),
      ),
      progress: PathProgress(
        totalLevels: segments.fold(0, (sum, segment) => sum + segment.levels.length),
        completedLevels: 0,
        masteredLevels: 0,
        averageScore: 0.0,
        totalTimeSpent: Duration.zero,
        lastActivity: DateTime.now(),
        currentStreak: 0,
        longestStreak: 0,
        skillProgress: {},
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generates a review learning path for concept reinforcement
  Future<LearningPath> _generateReviewPath(
    PathGenerationParameters params,
    List<SkillNode> skillTree
  ) async {
    final segments = <PathSegment>[];
    
    // Select skills for review based on user's learning history
    final reviewSkills = skillTree
        .where((skill) => 
            skill.category != SkillCategory.mastery) // Exclude mastery for review
        .toList()
      ..shuffle(Random()); // Randomize for variety

    // Create mixed review segments
    final reviewSegment = await _createSkillBasedSegment(
      'Comprehensive Review',
      'Reinforce and consolidate your learning',
      reviewSkills.take(15).toList(),
      params,
      SegmentType.review,
    );
    segments.add(reviewSegment);

    return LearningPath(
      id: _generatePathId(),
      userId: params.userId,
      name: '${params.subject} Review Session',
      description: 'Comprehensive review to reinforce and consolidate learning',
      type: LearningPathType.structured,
      segments: segments,
      metadata: PathMetadata(
        learningStyle: params.preferences.learningStyle,
        difficultyPreference: params.preferences.difficultyPreference,
        preferredSubjects: [params.subject],
        personalizations: {
          'comprehensiveReview': true,
          'conceptReinforcement': true,
          'knowledgeConsolidation': true,
        },
        lastAnalyzed: DateTime.now(),
      ),
      progress: PathProgress(
        totalLevels: segments.fold(0, (sum, segment) => sum + segment.levels.length),
        completedLevels: 0,
        masteredLevels: 0,
        averageScore: 0.0,
        totalTimeSpent: Duration.zero,
        lastActivity: DateTime.now(),
        currentStreak: 0,
        longestStreak: 0,
        skillProgress: {},
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Creates adaptive segments that adjust based on performance
  Future<List<PathSegment>> _createAdaptiveSegments(
    List<SkillNode> skills,
    PathGenerationParameters params,
    String baseTitle,
    {int maxSegments = 3}
  ) async {
    final segments = <PathSegment>[];
    final segmentSize = max(2, skills.length ~/ maxSegments);
    
    for (int i = 0; i < min(maxSegments, (skills.length / segmentSize).ceil()); i++) {
      final segmentSkills = skills.skip(i * segmentSize).take(segmentSize).toList();
      
      final segment = await _createSkillBasedSegment(
        '$baseTitle ${i + 1}',
        'Adaptive learning segment that adjusts to your progress',
        segmentSkills,
        params,
        SegmentType.mastery,
      );
      
      segments.add(segment);
    }
    
    return segments;
  }

  /// Creates a segment based on a list of skills
  Future<PathSegment> _createSkillBasedSegment(
    String name,
    String description,
    List<SkillNode> skills,
    PathGenerationParameters params,
    SegmentType type,
  ) async {
    final levels = <PathLevel>[];
    
    for (final skill in skills) {
      // Get levels for this skill
      final skillLevels = _getSkillLevels(skill, params);
      levels.addAll(skillLevels);
    }

    // Calculate estimated duration
    final estimatedMinutes = levels.length * 8; // 8 minutes per level average
    
    return PathSegment(
      id: _generateSegmentId(),
      name: name,
      description: description,
      type: type,
      levels: levels,
      status: SegmentStatus.pending,
      requirements: _generateSegmentRequirements(skills),
      order: 0, // Will be set by caller
      estimatedDuration: Duration(minutes: estimatedMinutes),
      skillsFocused: skills.map((s) => s.id).toList(),
    );
  }

  /// Gets levels for a specific skill
  List<PathLevel> _getSkillLevels(SkillNode skill, PathGenerationParameters params) {
    final levels = <PathLevel>[];
    
    // Generate levels within the skill's level range
    final startLevel = skill.levelRange[0];
    final endLevel = min(skill.levelRange[1], startLevel + 10); // Limit to 10 levels per skill
    
    for (int levelId = startLevel; levelId <= endLevel; levelId++) {
      levels.add(PathLevel(
        levelId: levelId,
        name: '${skill.name} - Level $levelId',
        status: LevelStatus.locked,
        metadata: {
          'skillId': skill.id,
          'difficulty': skill.difficulty,
          'category': skill.category.name,
        },
      ));
    }
    
    return levels;
  }

  /// Generates requirements for a segment
  Map<String, dynamic> _generateSegmentRequirements(List<SkillNode> skills) {
    final allPrerequisites = skills.expand((s) => s.prerequisites).toSet().toList();
    
    return {
      'prerequisites': allPrerequisites,
      'minAccuracy': 0.7,
      'skillsRequired': skills.map((s) => s.id).toList(),
    };
  }

  /// Selects skills for a specific exploration theme
  List<SkillNode> _selectSkillsForTheme(List<SkillNode> skillTree, String theme, Random random) {
    final themeKeywords = _getThemeKeywords(theme);
    
    final relevantSkills = skillTree
        .where((skill) => themeKeywords.any((keyword) => 
            skill.name.toLowerCase().contains(keyword) ||
            skill.description.toLowerCase().contains(keyword)))
        .toList();
    
    // Add some random skills for variety
    final otherSkills = skillTree.where((s) => !relevantSkills.contains(s)).toList()
      ..shuffle(random);
    
    relevantSkills.addAll(otherSkills.take(2));
    relevantSkills.shuffle(random);
    
    return relevantSkills.take(5).toList();
  }

  /// Gets keywords associated with an exploration theme
  List<String> _getThemeKeywords(String theme) {
    switch (theme.toLowerCase()) {
      case 'creative problem solving':
        return ['creative', 'problem', 'innovation', 'design', 'solution'];
      case 'real-world applications':
        return ['application', 'real', 'practical', 'world', 'use'];
      case 'cross-disciplinary connections':
        return ['cross', 'interdisciplinary', 'connection', 'integration'];
      case 'advanced challenges':
        return ['advanced', 'challenge', 'complex', 'difficult'];
      case 'innovation projects':
        return ['innovation', 'project', 'creative', 'new', 'invention'];
      default:
        return [theme.toLowerCase()];
    }
  }

  /// Determines the optimal path type for a user
  LearningPathType _determineOptimalPathType(UserLearningPreferences preferences, String subject) {
    // Analyze user preferences and performance to suggest path type
    if (preferences.learningStyle == LearningStyle.balanced) {
      return LearningPathType.exploratory;
    }
    
    if (preferences.difficultyPreference == DifficultyPreference.hard) {
      return LearningPathType.accelerated;
    }
    
    if (preferences.difficultyPreference == DifficultyPreference.easy) {
      return LearningPathType.remedial;
    }
    
    if (preferences.weakAreas.contains(subject.toLowerCase())) {
      return LearningPathType.remedial;
    }
    
    if (preferences.strongAreas.contains(subject.toLowerCase())) {
      return LearningPathType.accelerated;
    }
    
    // Default to adaptive for most users
    return LearningPathType.adaptive;
  }

  /// Calculates optimal path length based on user preferences
  int _calculateOptimalPathLength(UserLearningPreferences preferences) {
    int baseLength = 30; // Default path length
    
    // Adjust based on learning style
    switch (preferences.learningStyle) {
      case LearningStyle.visual:
        baseLength += 10; // More visual content takes time
        break;
      case LearningStyle.kinesthetic:
        baseLength += 15; // Interactive content takes longer
        break;
      case LearningStyle.auditory:
        baseLength += 5; // Audio content is efficient
        break;
      case LearningStyle.reading:
        baseLength += 5; // Moderate adjustment for reading
        break;
      case LearningStyle.balanced:
        baseLength += 5; // Moderate adjustment
        break;
    }
    
    // Adjust based on difficulty preference
    switch (preferences.difficultyPreference) {
      case DifficultyPreference.easy:
        baseLength += 20; // More practice at easier levels
        break;
      case DifficultyPreference.moderate:
        baseLength += 10; // Moderate progression
        break;
      case DifficultyPreference.hard:
        baseLength -= 10; // Faster progression
        break;
      case DifficultyPreference.adaptive:
        // No adjustment for adaptive
        break;
    }
    
    return baseLength.clamp(_minPathLength, _maxPathLength);
  }

  /// Identifies focus areas based on user preferences
  List<String> _identifyFocusAreas(UserLearningPreferences preferences, String subject) {
    final focusAreas = <String>[];
    
    // Add strong areas as focus
    focusAreas.addAll(preferences.strongAreas);
    
    // Add subject-specific focus areas
    focusAreas.add(subject.toLowerCase());
    
    // Add learning style specific areas
    switch (preferences.learningStyle) {
      case LearningStyle.visual:
        focusAreas.addAll(['visualization', 'graphics', 'diagrams']);
        break;
      case LearningStyle.kinesthetic:
        focusAreas.addAll(['hands-on', 'interactive', 'practical']);
        break;
      case LearningStyle.auditory:
        focusAreas.addAll(['explanation', 'discussion', 'verbal']);
        break;
      case LearningStyle.reading:
        focusAreas.addAll(['text', 'writing', 'reading']);
        break;
      case LearningStyle.balanced:
        focusAreas.addAll(['exploration', 'discovery', 'investigation']);
        break;
    }
    
    return focusAreas.take(5).toList(); // Limit to 5 focus areas
  }

  /// Calculates target difficulty based on user preferences
  Future<double> _calculateTargetDifficulty(UserLearningPreferences preferences, String subject) async {
    double baseDifficulty = 0.5; // Default medium difficulty
    
    // Adjust based on difficulty preference
    switch (preferences.difficultyPreference) {
      case DifficultyPreference.easy:
        baseDifficulty = 0.3;
        break;
      case DifficultyPreference.moderate:
        baseDifficulty = 0.5;
        break;
      case DifficultyPreference.hard:
        baseDifficulty = 0.8;
        break;
      case DifficultyPreference.adaptive:
        // Use adaptive calculator if available
        try {
          final recommendation = await _difficultyCalculator.calculateOptimalDifficulty(
            preferences.userId, 
            1, // Placeholder level
            subject
          );
          baseDifficulty = recommendation.recommendedDifficulty;
        } catch (e) {
          // Fall back to default if calculation fails
          baseDifficulty = 0.5;
        }
        break;
    }
    
    return baseDifficulty.clamp(0.1, 1.0);
  }

  /// Gets user learning preferences
  Future<UserLearningPreferences> _getUserPreferences(String userId) async {
    if (_preferencesCache.containsKey(userId)) {
      return _preferencesCache[userId]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final preferencesJson = prefs.getString('learning_preferences_$userId');
    
    UserLearningPreferences preferences;
    if (preferencesJson != null) {
      try {
        preferences = UserLearningPreferences.fromJson(json.decode(preferencesJson));
      } catch (e) {
        print('Error loading user preferences: $e');
        preferences = UserLearningPreferences(userId: userId);
      }
    } else {
      preferences = UserLearningPreferences(userId: userId);
    }

    _preferencesCache[userId] = preferences;
    return preferences;
  }

  /// Loads user preferences from storage
  Future<void> _loadUserPreferences() async {
    // Implementation would load frequently accessed preferences
    // For now, preferences are loaded on-demand
  }

  /// Caches a generated learning path
  Future<void> _cachePath(String userId, LearningPath path) async {
    _pathCache.putIfAbsent(userId, () => []).add(path);
    
    // Keep only last 10 paths per user
    if (_pathCache[userId]!.length > 10) {
      _pathCache[userId]!.removeAt(0);
    }
    
    // Save to persistent storage
    final prefs = await SharedPreferences.getInstance();
    final pathsJson = _pathCache[userId]!.map((p) => p.toJson()).toList();
    await prefs.setString('learning_paths_$userId', json.encode(pathsJson));
  }

  /// Gets cached learning paths for a user
  Future<List<LearningPath>> getCachedPaths(String userId) async {
    if (_pathCache.containsKey(userId)) {
      return _pathCache[userId]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final pathsJson = prefs.getString('learning_paths_$userId');
    
    if (pathsJson != null) {
      try {
        final pathsData = (json.decode(pathsJson) as List).cast<Map<String, dynamic>>();
        final paths = pathsData.map((data) => LearningPath.fromJson(data)).toList();
        _pathCache[userId] = paths;
        return paths;
      } catch (e) {
        print('Error loading cached paths: $e');
      }
    }
    
    return [];
  }

  /// Updates user learning preferences
  Future<void> updateUserPreferences(String userId, UserLearningPreferences preferences) async {
    _preferencesCache[userId] = preferences;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('learning_preferences_$userId', json.encode(preferences.toJson()));
  }

  /// Gets display name for skill category
  String _getCategoryDisplayName(SkillCategory category) {
    switch (category) {
      case SkillCategory.foundation:
        return 'Foundation Skills';
      case SkillCategory.core:
        return 'Core Concepts';
      case SkillCategory.advanced:
        return 'Advanced Topics';
      case SkillCategory.application:
        return 'Practical Applications';
      case SkillCategory.mastery:
        return 'Mastery Challenges';
      case SkillCategory.crossSubject:
        return 'Cross-Subject Integration';
      case SkillCategory.special:
        return 'Special Topics';
    }
  }

  /// Gets description for skill category
  String _getCategoryDescription(SkillCategory category) {
    switch (category) {
      case SkillCategory.foundation:
        return 'Build essential foundational knowledge';
      case SkillCategory.core:
        return 'Master core concepts and principles';
      case SkillCategory.advanced:
        return 'Explore advanced topics and techniques';
      case SkillCategory.application:
        return 'Apply knowledge to real-world problems';
      case SkillCategory.mastery:
        return 'Achieve mastery through challenging exercises';
      case SkillCategory.crossSubject:
        return 'Connect concepts across different subjects';
      case SkillCategory.special:
        return 'Explore specialized topics and interests';
    }
  }

  /// Generates a unique path ID
  String _generatePathId() {
    return 'path_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// Generates a unique segment ID
  String _generateSegmentId() {
    return 'segment_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// Clears all cached data
  void clearCache() {
    _pathCache.clear();
    _preferencesCache.clear();
  }

  /// Generates a collaborative learning path for group-based learning
  Future<LearningPath> _generateCollaborativePath(
    PathGenerationParameters params,
    List<SkillNode> skillTree,
  ) async {
    // For now, use structured path as base and add collaborative elements
    final basePath = await _generateStructuredPath(params, skillTree);
    
    return LearningPath(
      id: _generatePathId(),
      userId: params.userId,
      name: 'Collaborative ${params.subject} Journey',
      description: 'Group-based learning with peer interaction and shared challenges',
      type: LearningPathType.collaborative,
      segments: basePath.segments,
      metadata: PathMetadata(
        learningStyle: params.preferences.learningStyle,
        difficultyPreference: params.preferences.difficultyPreference,
        preferredSubjects: [params.subject],
        personalizations: {
          ...basePath.metadata.personalizations,
          'collaborative': true,
          'groupSize': 4,
          'socialFeatures': ['peer_review', 'group_challenges'],
        },
        lastAnalyzed: DateTime.now(),
      ),
      progress: PathProgress(
        totalLevels: basePath.progress.totalLevels,
        completedLevels: basePath.progress.completedLevels,
        masteredLevels: basePath.progress.masteredLevels,
        averageScore: basePath.progress.averageScore,
        totalTimeSpent: basePath.progress.totalTimeSpent,
        lastActivity: basePath.progress.lastActivity,
        currentStreak: basePath.progress.currentStreak,
        longestStreak: basePath.progress.longestStreak,
        skillProgress: basePath.progress.skillProgress,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generates a project-based learning path
  Future<LearningPath> _generateProjectBasedPath(
    PathGenerationParameters params,
    List<SkillNode> skillTree,
  ) async {
    // For now, use adaptive path as base and add project elements
    final basePath = await _generateAdaptivePath(params, skillTree);
    
    return LearningPath(
      id: _generatePathId(),
      userId: params.userId,
      name: 'Project-Based ${params.subject} Track',
      description: 'Learn through hands-on projects and practical applications',
      type: LearningPathType.projectBased,
      segments: basePath.segments,
      metadata: PathMetadata(
        learningStyle: params.preferences.learningStyle,
        difficultyPreference: params.preferences.difficultyPreference,
        preferredSubjects: [params.subject],
        personalizations: {
          ...basePath.metadata.personalizations,
          'projectBased': true,
          'projectCount': 3,
          'practicalApplication': true,
        },
        lastAnalyzed: DateTime.now(),
      ),
      progress: PathProgress(
        totalLevels: basePath.progress.totalLevels,
        completedLevels: basePath.progress.completedLevels,
        masteredLevels: basePath.progress.masteredLevels,
        averageScore: basePath.progress.averageScore,
        totalTimeSpent: basePath.progress.totalTimeSpent,
        lastActivity: basePath.progress.lastActivity,
        currentStreak: basePath.progress.currentStreak,
        longestStreak: basePath.progress.longestStreak,
        skillProgress: basePath.progress.skillProgress,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generates a gamified learning path
  Future<LearningPath> _generateGamifiedPath(
    PathGenerationParameters params,
    List<SkillNode> skillTree,
  ) async {
    // For now, use adaptive path as base and add gamification elements
    final basePath = await _generateAdaptivePath(params, skillTree);
    
    return LearningPath(
      id: _generatePathId(),
      userId: params.userId,
      name: 'Gamified ${params.subject} Adventure',
      description: 'Learn through game-like challenges with achievements and rewards',
      type: LearningPathType.gamified,
      segments: basePath.segments,
      metadata: PathMetadata(
        learningStyle: params.preferences.learningStyle,
        difficultyPreference: params.preferences.difficultyPreference,
        preferredSubjects: [params.subject],
        personalizations: {
          ...basePath.metadata.personalizations,
          'gamified': true,
          'achievements': true,
          'leaderboards': true,
          'badges': true,
        },
        lastAnalyzed: DateTime.now(),
      ),
      progress: PathProgress(
        totalLevels: basePath.progress.totalLevels,
        completedLevels: basePath.progress.completedLevels,
        masteredLevels: basePath.progress.masteredLevels,
        averageScore: basePath.progress.averageScore,
        totalTimeSpent: basePath.progress.totalTimeSpent,
        lastActivity: basePath.progress.lastActivity,
        currentStreak: basePath.progress.currentStreak,
        longestStreak: basePath.progress.longestStreak,
        skillProgress: basePath.progress.skillProgress,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

/// Parameters for path generation
class PathGenerationParameters {
  final String userId;
  final String subject;
  final LearningPathType pathType;
  final int targetLevels;
  final List<String> focusAreas;
  final double targetDifficulty;
  final Duration? timeConstraint;
  final UserLearningPreferences preferences;

  PathGenerationParameters({
    required this.userId,
    required this.subject,
    required this.pathType,
    required this.targetLevels,
    required this.focusAreas,
    required this.targetDifficulty,
    this.timeConstraint,
    required this.preferences,
  });
}

/// Represents user learning preferences and patterns
class UserLearningPreferences {
  final String userId;
  LearningStyle learningStyle;
  DifficultyPreference difficultyPreference;
  List<String> preferredSubjects;
  List<String> weakAreas;
  List<String> strongAreas;
  Map<String, dynamic> personalizations;
  DateTime lastUpdated;

  UserLearningPreferences({
    required this.userId,
    this.learningStyle = LearningStyle.balanced,
    this.difficultyPreference = DifficultyPreference.adaptive,
    List<String>? preferredSubjects,
    List<String>? weakAreas,
    List<String>? strongAreas,
    Map<String, dynamic>? personalizations,
    DateTime? lastUpdated,
  }) : preferredSubjects = preferredSubjects ?? [],
       weakAreas = weakAreas ?? [],
       strongAreas = strongAreas ?? [],
       personalizations = personalizations ?? {},
       lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'learningStyle': learningStyle.name,
    'difficultyPreference': difficultyPreference.name,
    'preferredSubjects': preferredSubjects,
    'weakAreas': weakAreas,
    'strongAreas': strongAreas,
    'personalizations': personalizations,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory UserLearningPreferences.fromJson(Map<String, dynamic> json) => UserLearningPreferences(
    userId: json['userId'],
    learningStyle: LearningStyle.values.firstWhere(
      (style) => style.name == json['learningStyle'],
      orElse: () => LearningStyle.balanced,
    ),
    difficultyPreference: DifficultyPreference.values.firstWhere(
      (pref) => pref.name == json['difficultyPreference'],
      orElse: () => DifficultyPreference.adaptive,
    ),
    preferredSubjects: (json['preferredSubjects'] as List?)?.cast<String>() ?? [],
    weakAreas: (json['weakAreas'] as List?)?.cast<String>() ?? [],
    strongAreas: (json['strongAreas'] as List?)?.cast<String>() ?? [],
    personalizations: json['personalizations'] ?? {},
    lastUpdated: DateTime.parse(json['lastUpdated']),
  );
}