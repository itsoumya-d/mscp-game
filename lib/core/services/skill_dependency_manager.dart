import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/skill_node.dart';
import '../models/unlock_condition.dart';

/// Manages the hierarchical skill dependency tree for progressive unlocking
/// Handles 50,000 educational levels across multiple subjects and skill categories
class SkillDependencyManager {
  static SkillDependencyManager? _instance;
  static SkillDependencyManager get instance => _instance ??= SkillDependencyManager._();
  
  SkillDependencyManager._();

  // Cache for skill nodes and dependencies
  final Map<String, SkillNode> _skillCache = {};
  final Map<String, List<String>> _dependencyCache = {};
  final Map<String, List<String>> _childrenCache = {};
  
  // Storage keys
  static const String _skillTreeKey = 'skill_dependency_tree';
  static const String _userSkillProgressKey = 'user_skill_progress';
  static const String _lastUpdateKey = 'skill_tree_last_update';

  /// Initializes the skill dependency manager
  Future<void> initialize() async {
    await _loadSkillTree();
    await _buildDependencyCache();
  }

  /// Loads the skill tree from storage or creates default structure
  Future<void> _loadSkillTree() async {
    final prefs = await SharedPreferences.getInstance();
    final skillTreeJson = prefs.getString(_skillTreeKey);
    
    if (skillTreeJson != null) {
      try {
        final Map<String, dynamic> treeData = json.decode(skillTreeJson);
        _skillCache.clear();
        
        for (final entry in treeData.entries) {
          _skillCache[entry.key] = SkillNode.fromJson(entry.value);
        }
      } catch (e) {
        print('Error loading skill tree: $e');
        await _createDefaultSkillTree();
      }
    } else {
      await _createDefaultSkillTree();
    }
  }

  /// Creates a default skill tree structure for 50,000 levels
  Future<void> _createDefaultSkillTree() async {
    _skillCache.clear();
    
    // Create foundation skills for each subject
    final subjects = ['Mathematics', 'Science', 'Programming', 'Language', 'History'];
    
    for (final subject in subjects) {
      await _createSubjectSkillTree(subject);
    }
    
    // Create cross-subject skills
    await _createCrossSubjectSkills();
    
    // Save the created tree
    await _saveSkillTree();
  }

  /// Creates skill tree for a specific subject
  Future<void> _createSubjectSkillTree(String subject) async {
    final subjectId = subject.toLowerCase();
    
    // Foundation level (Levels 1-1000)
    final foundationSkills = _createFoundationSkills(subjectId, subject);
    
    // Core level (Levels 1001-5000)
    final coreSkills = _createCoreSkills(subjectId, subject, foundationSkills);
    
    // Advanced level (Levels 5001-15000)
    final advancedSkills = _createAdvancedSkills(subjectId, subject, coreSkills);
    
    // Application level (Levels 15001-35000)
    final applicationSkills = _createApplicationSkills(subjectId, subject, advancedSkills);
    
    // Mastery level (Levels 35001-50000)
    final masterySkills = _createMasterySkills(subjectId, subject, applicationSkills);
    
    // Add all skills to cache
    for (final skill in [
      ...foundationSkills,
      ...coreSkills,
      ...advancedSkills,
      ...applicationSkills,
      ...masterySkills,
    ]) {
      _skillCache[skill.id] = skill;
    }
  }

  /// Creates foundation skills (basic concepts)
  List<SkillNode> _createFoundationSkills(String subjectId, String subject) {
    final skills = <SkillNode>[];
    
    // Create 10 foundation skill groups, each covering 100 levels
    for (int i = 1; i <= 10; i++) {
      final startLevel = (i - 1) * 100 + 1;
      final endLevel = i * 100;
      
      final skill = SkillNode(
        id: '${subjectId}_foundation_$i',
        name: '$subject Foundation $i',
        description: 'Basic concepts and fundamentals for $subject (Levels $startLevel-$endLevel)',
        subject: subject,
        levelRange: [startLevel, endLevel],
        prerequisites: i > 1 ? ['${subjectId}_foundation_${i-1}'] : [],
        children: [],
        unlockCriteria: UnlockCriteria(
          minAccuracy: 0.7,
          minXP: startLevel * 10,
          requiredLevels: i > 1 ? [endLevel - 100] : [],
          minMasteryScore: 0.6,
        ),
        category: SkillCategory.foundation,
        difficulty: (1 + (i - 1) * 0.1).round(),
        metadata: {
          'estimatedHours': 5 + i,
          'concepts': _getFoundationConcepts(subjectId, i),
          'levelCount': 100,
        },
      );
      
      skills.add(skill);
    }
    
    return skills;
  }

  /// Creates core skills (intermediate concepts)
  List<SkillNode> _createCoreSkills(String subjectId, String subject, List<SkillNode> foundationSkills) {
    final skills = <SkillNode>[];
    
    // Create 40 core skill groups, each covering 100 levels
    for (int i = 1; i <= 40; i++) {
      final startLevel = 1000 + (i - 1) * 100 + 1;
      final endLevel = 1000 + i * 100;
      
      // Determine prerequisites from foundation skills
      final prerequisites = <String>[];
      if (i <= 10) {
        prerequisites.add(foundationSkills[i - 1].id);
      } else {
        prerequisites.add('${subjectId}_core_${i - 1}');
        if (i % 5 == 0) {
          // Every 5th core skill requires multiple foundation skills
          prerequisites.addAll(foundationSkills.take(3).map((s) => s.id));
        }
      }
      
      final skill = SkillNode(
        id: '${subjectId}_core_$i',
        name: '$subject Core $i',
        description: 'Intermediate concepts for $subject (Levels $startLevel-$endLevel)',
        subject: subject,
        levelRange: [startLevel, endLevel],
        prerequisites: prerequisites,
        children: [],
        unlockCriteria: UnlockCriteria(
          minAccuracy: 0.75,
          minXP: startLevel * 12,
          requiredLevels: [startLevel - 1],
          minMasteryScore: 0.7,
          minCompletedSkills: prerequisites.length,
        ),
        category: SkillCategory.core,
        difficulty: (2 + (i - 1) * 0.05).round(),
        metadata: {
          'estimatedHours': 8 + i * 0.5,
          'concepts': _getCoreConcepts(subjectId, i),
          'levelCount': 100,
        },
      );
      
      skills.add(skill);
    }
    
    return skills;
  }

  /// Creates advanced skills (complex concepts)
  List<SkillNode> _createAdvancedSkills(String subjectId, String subject, List<SkillNode> coreSkills) {
    final skills = <SkillNode>[];
    
    // Create 100 advanced skill groups, each covering 100 levels
    for (int i = 1; i <= 100; i++) {
      final startLevel = 5000 + (i - 1) * 100 + 1;
      final endLevel = 5000 + i * 100;
      
      // Complex prerequisite structure
      final prerequisites = <String>[];
      if (i <= 40) {
        prerequisites.add(coreSkills[i - 1].id);
      } else {
        prerequisites.add('${subjectId}_advanced_${i - 1}');
        if (i % 10 == 0) {
          // Every 10th advanced skill requires multiple core skills
          final requiredCoreSkills = (i / 10).floor();
          prerequisites.addAll(coreSkills.take(requiredCoreSkills).map((s) => s.id));
        }
      }
      
      final skill = SkillNode(
        id: '${subjectId}_advanced_$i',
        name: '$subject Advanced $i',
        description: 'Advanced concepts for $subject (Levels $startLevel-$endLevel)',
        subject: subject,
        levelRange: [startLevel, endLevel],
        prerequisites: prerequisites,
        children: [],
        unlockCriteria: UnlockCriteria(
          minAccuracy: 0.8,
          minXP: startLevel * 15,
          requiredLevels: [startLevel - 1],
          minMasteryScore: 0.75,
          minCompletedSkills: prerequisites.length,
          timeRequirement: Duration(hours: 2),
        ),
        category: SkillCategory.advanced,
        difficulty: (3 + (i - 1) * 0.02).round(),
        metadata: {
          'estimatedHours': 12 + i * 0.3,
          'concepts': _getAdvancedConcepts(subjectId, i),
          'levelCount': 100,
        },
      );
      
      skills.add(skill);
    }
    
    return skills;
  }

  /// Creates application skills (practical application)
  List<SkillNode> _createApplicationSkills(String subjectId, String subject, List<SkillNode> advancedSkills) {
    final skills = <SkillNode>[];
    
    // Create 200 application skill groups, each covering 100 levels
    for (int i = 1; i <= 200; i++) {
      final startLevel = 15000 + (i - 1) * 100 + 1;
      final endLevel = 15000 + i * 100;
      
      // Application skills require mastery of multiple advanced skills
      final prerequisites = <String>[];
      final requiredAdvancedSkills = ((i - 1) / 2).floor() + 1;
      if (requiredAdvancedSkills <= advancedSkills.length) {
        prerequisites.add(advancedSkills[requiredAdvancedSkills - 1].id);
      }
      
      if (i > 1) {
        prerequisites.add('${subjectId}_application_${i - 1}');
      }
      
      // Every 20th application skill requires cross-subject knowledge
      if (i % 20 == 0) {
        prerequisites.add('cross_subject_integration_${(i / 20).floor()}');
      }
      
      final skill = SkillNode(
        id: '${subjectId}_application_$i',
        name: '$subject Application $i',
        description: 'Practical application of $subject (Levels $startLevel-$endLevel)',
        subject: subject,
        levelRange: [startLevel, endLevel],
        prerequisites: prerequisites,
        children: [],
        unlockCriteria: UnlockCriteria(
          minAccuracy: 0.85,
          minXP: startLevel * 18,
          requiredLevels: [startLevel - 1],
          minMasteryScore: 0.8,
          minCompletedSkills: prerequisites.length,
          timeRequirement: Duration(hours: 3),
          requiredAchievements: ['problem_solver', 'critical_thinker'],
        ),
        category: SkillCategory.application,
        difficulty: (4 + (i - 1) * 0.01).round(),
        metadata: {
          'estimatedHours': 15 + i * 0.2,
          'concepts': _getApplicationConcepts(subjectId, i),
          'levelCount': 100,
          'projectBased': true,
        },
      );
      
      skills.add(skill);
    }
    
    return skills;
  }

  /// Creates mastery skills (expert level)
  List<SkillNode> _createMasterySkills(String subjectId, String subject, List<SkillNode> applicationSkills) {
    final skills = <SkillNode>[];
    
    // Create 150 mastery skill groups, each covering 100 levels
    for (int i = 1; i <= 150; i++) {
      final startLevel = 35000 + (i - 1) * 100 + 1;
      final endLevel = 35000 + i * 100;
      
      // Mastery skills require extensive prerequisites
      final prerequisites = <String>[];
      final requiredApplicationSkills = ((i - 1) / 1.5).floor() + 1;
      if (requiredApplicationSkills <= applicationSkills.length) {
        prerequisites.add(applicationSkills[requiredApplicationSkills - 1].id);
      }
      
      if (i > 1) {
        prerequisites.add('${subjectId}_mastery_${i - 1}');
      }
      
      // Mastery skills require achievements and cross-subject mastery
      if (i % 10 == 0) {
        prerequisites.add('cross_subject_mastery_${(i / 10).floor()}');
      }
      
      final skill = SkillNode(
        id: '${subjectId}_mastery_$i',
        name: '$subject Mastery $i',
        description: 'Expert mastery of $subject (Levels $startLevel-$endLevel)',
        subject: subject,
        levelRange: [startLevel, endLevel],
        prerequisites: prerequisites,
        children: [],
        unlockCriteria: UnlockCriteria(
          minAccuracy: 0.9,
          minXP: startLevel * 25,
          requiredLevels: [startLevel - 1],
          minMasteryScore: 0.9,
          minCompletedSkills: prerequisites.length,
          timeRequirement: Duration(hours: 5),
          requiredAchievements: ['expert_${subjectId}', 'master_problem_solver', 'innovation_leader'],
        ),
        category: SkillCategory.mastery,
        difficulty: (5 + (i - 1) * 0.005).round(),
        metadata: {
          'estimatedHours': 20 + i * 0.1,
          'concepts': _getMasteryConcepts(subjectId, i),
          'levelCount': 100,
          'researchBased': true,
          'mentorshipRequired': i > 50,
        },
      );
      
      skills.add(skill);
    }
    
    return skills;
  }

  /// Creates cross-subject integration skills
  Future<void> _createCrossSubjectSkills() async {
    // Integration skills that span multiple subjects
    for (int i = 1; i <= 50; i++) {
      final startLevel = 10000 + (i - 1) * 200 + 1;
      final endLevel = 10000 + i * 200;
      
      final skill = SkillNode(
        id: 'cross_subject_integration_$i',
        name: 'Cross-Subject Integration $i',
        description: 'Integration of multiple subject areas (Levels $startLevel-$endLevel)',
        subject: 'Cross-Subject',
        levelRange: [startLevel, endLevel],
        prerequisites: _getCrossSubjectPrerequisites(i),
        children: [],
        unlockCriteria: UnlockCriteria(
          minAccuracy: 0.85,
          minXP: startLevel * 20,
          requiredLevels: [startLevel - 1],
          minMasteryScore: 0.8,
          minCompletedSkills: 3,
          timeRequirement: Duration(hours: 4),
          requiredAchievements: ['interdisciplinary_thinker'],
        ),
        category: SkillCategory.crossSubject,
        difficulty: (4.5 + (i - 1) * 0.02).round(),
        metadata: {
          'estimatedHours': 25 + i * 0.5,
          'concepts': ['synthesis', 'integration', 'holistic_thinking'],
          'levelCount': 200,
          'collaborativeRequired': true,
        },
      );
      
      _skillCache[skill.id] = skill;
    }
  }

  /// Gets prerequisites for cross-subject skills
  List<String> _getCrossSubjectPrerequisites(int level) {
    final prerequisites = <String>[];
    final subjects = ['mathematics', 'science', 'programming', 'language', 'history'];
    
    for (final subject in subjects) {
      final requiredCoreLevel = (level / 10).floor() + 1;
      if (requiredCoreLevel <= 40) {
        prerequisites.add('${subject}_core_$requiredCoreLevel');
      }
    }
    
    return prerequisites;
  }

  /// Builds dependency cache for efficient lookups
  Future<void> _buildDependencyCache() async {
    _dependencyCache.clear();
    _childrenCache.clear();
    
    for (final skill in _skillCache.values) {
      // Cache prerequisites
      _dependencyCache[skill.id] = List.from(skill.prerequisites);
      
      // Cache children relationships
      for (final prerequisite in skill.prerequisites) {
        _childrenCache.putIfAbsent(prerequisite, () => []).add(skill.id);
      }
    }
  }

  /// Gets a skill node by ID
  SkillNode? getSkill(String skillId) {
    return _skillCache[skillId];
  }

  /// Gets all skills for a subject
  List<SkillNode> getSkillsForSubject(String subject) {
    return _skillCache.values
        .where((skill) => skill.subject == subject)
        .toList()
      ..sort((a, b) => a.levelRange[0].compareTo(b.levelRange[0]));
  }

  /// Gets skills by category
  List<SkillNode> getSkillsByCategory(SkillCategory category) {
    return _skillCache.values
        .where((skill) => skill.category == category)
        .toList()
      ..sort((a, b) => a.levelRange[0].compareTo(b.levelRange[0]));
  }

  /// Gets direct prerequisites for a skill
  List<String> getPrerequisites(String skillId) {
    return _dependencyCache[skillId] ?? [];
  }

  /// Gets all transitive prerequisites for a skill
  List<String> getAllPrerequisites(String skillId) {
    final allPrereqs = <String>{};
    final toProcess = <String>[skillId];
    
    while (toProcess.isNotEmpty) {
      final current = toProcess.removeAt(0);
      final prereqs = _dependencyCache[current] ?? [];
      
      for (final prereq in prereqs) {
        if (!allPrereqs.contains(prereq)) {
          allPrereqs.add(prereq);
          toProcess.add(prereq);
        }
      }
    }
    
    return allPrereqs.toList();
  }

  /// Gets direct children of a skill
  List<String> getChildren(String skillId) {
    return _childrenCache[skillId] ?? [];
  }

  /// Gets skills that cover a specific level
  List<SkillNode> getSkillsForLevel(int level) {
    return _skillCache.values
        .where((skill) => 
            level >= skill.levelRange[0] && 
            level <= skill.levelRange[1])
        .toList();
  }

  /// Checks if a skill is unlocked for a user
  Future<bool> isSkillUnlocked(String skillId, String userId) async {
    final skill = getSkill(skillId);
    if (skill == null) return false;
    
    final userProgress = await _getUserSkillProgress(userId);
    
    // Check if skill is already unlocked
    if (userProgress[skillId]?['unlocked'] == true) {
      return true;
    }
    
    // Check prerequisites
    for (final prereqId in skill.prerequisites) {
      final prereqProgress = userProgress[prereqId];
      if (prereqProgress == null || prereqProgress['completed'] != true) {
        return false;
      }
    }
    
    return true;
  }

  /// Gets user's skill progress
  Future<Map<String, Map<String, dynamic>>> _getUserSkillProgress(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString('${_userSkillProgressKey}_$userId');
    
    if (progressJson != null) {
      try {
        final Map<String, dynamic> data = json.decode(progressJson);
        return data.map((k, v) => MapEntry(k, v as Map<String, dynamic>));
      } catch (e) {
        print('Error loading user skill progress: $e');
      }
    }
    
    return {};
  }

  /// Updates user's skill progress
  Future<void> updateSkillProgress(String userId, String skillId, Map<String, dynamic> progress) async {
    final userProgress = await _getUserSkillProgress(userId);
    userProgress[skillId] = progress;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_userSkillProgressKey}_$userId', json.encode(userProgress));
  }

  /// Saves the skill tree to storage
  Future<void> _saveSkillTree() async {
    final prefs = await SharedPreferences.getInstance();
    final treeData = _skillCache.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_skillTreeKey, json.encode(treeData));
    await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  /// Gets concept lists for different skill levels
  List<String> _getFoundationConcepts(String subject, int level) {
    switch (subject) {
      case 'mathematics':
        return ['numbers', 'counting', 'basic_operations', 'patterns'];
      case 'science':
        return ['observation', 'classification', 'measurement', 'hypothesis'];
      case 'programming':
        return ['sequences', 'variables', 'input_output', 'debugging'];
      case 'language':
        return ['vocabulary', 'grammar', 'reading', 'writing'];
      case 'history':
        return ['chronology', 'cause_effect', 'sources', 'context'];
      default:
        return ['fundamentals', 'basics', 'introduction'];
    }
  }

  List<String> _getCoreConcepts(String subject, int level) {
    switch (subject) {
      case 'mathematics':
        return ['algebra', 'geometry', 'statistics', 'functions'];
      case 'science':
        return ['experimentation', 'analysis', 'theory', 'application'];
      case 'programming':
        return ['algorithms', 'data_structures', 'functions', 'objects'];
      case 'language':
        return ['composition', 'analysis', 'rhetoric', 'literature'];
      case 'history':
        return ['interpretation', 'synthesis', 'perspective', 'evidence'];
      default:
        return ['intermediate', 'core_concepts', 'application'];
    }
  }

  List<String> _getAdvancedConcepts(String subject, int level) {
    switch (subject) {
      case 'mathematics':
        return ['calculus', 'linear_algebra', 'discrete_math', 'modeling'];
      case 'science':
        return ['research_methods', 'advanced_theory', 'interdisciplinary'];
      case 'programming':
        return ['design_patterns', 'optimization', 'systems', 'architecture'];
      case 'language':
        return ['critical_theory', 'advanced_composition', 'linguistics'];
      case 'history':
        return ['historiography', 'methodology', 'comparative_analysis'];
      default:
        return ['advanced', 'complex_concepts', 'specialization'];
    }
  }

  List<String> _getApplicationConcepts(String subject, int level) {
    switch (subject) {
      case 'mathematics':
        return ['real_world_modeling', 'optimization', 'data_science'];
      case 'science':
        return ['research_projects', 'innovation', 'problem_solving'];
      case 'programming':
        return ['software_engineering', 'project_management', 'deployment'];
      case 'language':
        return ['professional_writing', 'communication', 'media_literacy'];
      case 'history':
        return ['policy_analysis', 'contemporary_issues', 'leadership'];
      default:
        return ['practical_application', 'projects', 'real_world'];
    }
  }

  List<String> _getMasteryConcepts(String subject, int level) {
    switch (subject) {
      case 'mathematics':
        return ['research', 'theorem_proving', 'mathematical_discovery'];
      case 'science':
        return ['original_research', 'peer_review', 'scientific_leadership'];
      case 'programming':
        return ['system_design', 'technical_leadership', 'innovation'];
      case 'language':
        return ['scholarly_writing', 'literary_criticism', 'cultural_analysis'];
      case 'history':
        return ['original_research', 'historical_methodology', 'expertise'];
      default:
        return ['mastery', 'expertise', 'leadership', 'innovation'];
    }
  }

  /// Clears all cached data
  void clearCache() {
    _skillCache.clear();
    _dependencyCache.clear();
    _childrenCache.clear();
  }

  /// Gets statistics about the skill tree
  Map<String, dynamic> getSkillTreeStats() {
    final stats = <String, dynamic>{};
    
    stats['totalSkills'] = _skillCache.length;
    stats['skillsBySubject'] = <String, int>{};
    stats['skillsByCategory'] = <String, int>{};
    
    for (final skill in _skillCache.values) {
      stats['skillsBySubject'][skill.subject] = 
          (stats['skillsBySubject'][skill.subject] ?? 0) + 1;
      stats['skillsByCategory'][skill.category.name] = 
          (stats['skillsByCategory'][skill.category.name] ?? 0) + 1;
    }
    
    return stats;
  }
}