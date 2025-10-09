import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp/core/models/subject.dart';

class DynamicSyllabusService {
  static DynamicSyllabusService? _instance;
  
  static DynamicSyllabusService getInstance() {
    _instance ??= DynamicSyllabusService._internal();
    return _instance!;
  }
  
  @Deprecated('Use getInstance() instead')
  static DynamicSyllabusService get instance => getInstance();
  DynamicSyllabusService._internal();

  static const String _syllabusKey = 'dynamic_syllabus';
  static const String _syllabusVersionKey = 'syllabus_version';
  static const String _lastGenerationKey = 'last_syllabus_generation';
  static const String _userProgressKey = 'user_progress_levels';
  
  // Syllabus regeneration interval (7 days)
  static const int regenerationIntervalDays = 7;
  
  // Maximum units per subject based on difficulty
  static const Map<int, int> maxUnitsPerDifficulty = {
    1: 3, // Beginner
    2: 4, // Intermediate
    3: 5, // Advanced
    4: 6, // Expert
    5: 7, // Master
  };

  /// Check if syllabus generation is due
  Future<bool> isSyllabusGenerationDue() async {
    final prefs = await SharedPreferences.getInstance();
    final lastGeneration = prefs.getString(_lastGenerationKey);
    
    if (lastGeneration == null) return true;
    
    final lastDate = DateTime.parse(lastGeneration);
    final daysSinceGeneration = DateTime.now().difference(lastDate).inDays;
    
    return daysSinceGeneration >= regenerationIntervalDays;
  }

  /// Generate dynamic syllabus for all subjects based on user progress
  Future<void> generateDynamicSyllabusIfDue() async {
    if (!await isSyllabusGenerationDue()) {
      if (kDebugMode) {
        print('Dynamic syllabus generation not due yet');
      }
      return;
    }

    // Skip AI configuration checks - use procedural generation
    await _generateDynamicSyllabus();
  }

  /// Generate adaptive syllabus for all subjects
  Future<void> _generateDynamicSyllabus() async {
    final prefs = await SharedPreferences.getInstance();
    final userProgress = await _getUserProgressLevels();
    
    final Map<String, List<Map<String, dynamic>>> dynamicSyllabus = {};
    
    for (final subject in SubjectType.values) {
      final subjectProgress = userProgress[subject.name] ?? 1;
      final syllabus = await _generateSubjectSyllabus(subject, subjectProgress);
      
      if (syllabus.isNotEmpty) {
        dynamicSyllabus[subject.name] = syllabus;
        
        // TODO: Implement cloud service integration for scalable storage
        if (kDebugMode) {
          print('Generated dynamic syllabus for ${subject.name}');
        }
      }
    }
    
    // TODO: Implement cloud service integration for batch storage
    if (kDebugMode) {
      print('Generated dynamic syllabus batch for ${dynamicSyllabus.keys.length} subjects');
    }
    
    // Cache the generated syllabus
    await prefs.setString(_syllabusKey, json.encode(dynamicSyllabus));
    await prefs.setString(_lastGenerationKey, DateTime.now().toIso8601String());
    await prefs.setInt(_syllabusVersionKey, (prefs.getInt(_syllabusVersionKey) ?? 0) + 1);
    
    if (kDebugMode) {
      print('Generated dynamic syllabus for ${dynamicSyllabus.length} subjects');
    }
  }

  /// Generate syllabus for a specific subject with progressive difficulty
  Future<List<Map<String, dynamic>>> _generateSubjectSyllabus(
    SubjectType subject, 
    int progressLevel
  ) async {
    final maxUnits = maxUnitsPerDifficulty[min(progressLevel, 5)] ?? 3;
    final difficultyLevel = _getDifficultyLabel(progressLevel);
    
    final prompt = '''
Generate a dynamic, adaptive syllabus for ${subject.name} at $difficultyLevel level.
The user has progress level $progressLevel (1=Beginner, 2=Intermediate, 3=Advanced, 4=Expert, 5=Master).

Return ONLY a valid JSON array with this exact structure:
[
  {
    "unitId": "unique_unit_id",
    "unitName": "Unit Name",
    "description": "Detailed unit description",
    "difficulty": $progressLevel,
    "estimatedHours": 8,
    "prerequisites": ["prerequisite_unit_id"],
    "skills": [
      {
        "skillId": "unique_skill_id", 
        "skillName": "Skill Name",
        "description": "Detailed skill description",
        "difficulty": $progressLevel,
        "estimatedLessons": 5,
        "learningObjectives": ["objective1", "objective2"]
      }
    ]
  }
]

Subject-specific requirements for ${subject.name}:
${_getSubjectSpecificPrompt(subject, progressLevel)}

Generate exactly $maxUnits units, each with 3-5 skills.
Make content progressively challenging based on level $progressLevel.
Include real-world applications and practical examples.
Ensure logical prerequisite relationships between units.
''';

    try {
      // Use procedural generation instead of AI
      return _generateProceduralSyllabus(subject, progressLevel, maxUnits);
    } catch (e) {
      if (kDebugMode) {
        print('Error generating dynamic syllabus for ${subject.name}: $e');
      }
      // Fallback to enhanced default syllabus
      return _getEnhancedDefaultSyllabus(subject, progressLevel);
    }
  }

  /// Get subject-specific prompt content
  String _getSubjectSpecificPrompt(SubjectType subject, int level) {
    switch (subject) {
      case SubjectType.math:
        return '''
- Level 1: Basic arithmetic, simple fractions, basic geometry
- Level 2: Algebra basics, coordinate geometry, statistics intro
- Level 3: Advanced algebra, trigonometry, calculus prep
- Level 4: Calculus, advanced statistics, discrete math
- Level 5: Advanced calculus, linear algebra, number theory
Focus on problem-solving strategies and mathematical reasoning.
''';
      case SubjectType.physics:
        return '''
- Level 1: Basic mechanics, simple machines, energy concepts
- Level 2: Waves, thermodynamics, basic electricity
- Level 3: Advanced mechanics, electromagnetism, optics
- Level 4: Quantum mechanics intro, relativity basics, advanced electromagnetism
- Level 5: Advanced quantum physics, particle physics, cosmology
Emphasize experimental design and theoretical understanding.
''';
      case SubjectType.chemistry:
        return '''
- Level 1: Atomic structure, basic bonding, simple reactions
- Level 2: Stoichiometry, acids/bases, organic chemistry intro
- Level 3: Advanced organic chemistry, thermochemistry, kinetics
- Level 4: Physical chemistry, advanced organic synthesis, biochemistry
- Level 5: Quantum chemistry, advanced physical chemistry, materials science
Include laboratory techniques and safety protocols.
''';
      case SubjectType.biology:
        return '''
- Level 1: Cell biology basics, genetics intro, basic ecology
- Level 2: Human anatomy, evolution, plant biology
- Level 3: Advanced genetics, molecular biology, advanced ecology
- Level 4: Biochemistry, advanced molecular biology, biotechnology
- Level 5: Systems biology, advanced biotechnology, research methods
Focus on current research and biotechnology applications.
''';
      case SubjectType.computerScience:
        return '''
- Level 1: Basic programming concepts, variables, simple algorithms
- Level 2: Control structures, functions, basic data structures
- Level 3: Object-oriented programming, advanced algorithms, databases
- Level 4: Software engineering, system design, advanced data structures
- Level 5: Machine learning, distributed systems, advanced software architecture
Emphasize practical coding skills and problem-solving approaches.
''';
      case SubjectType.geography:
        return '''
- Level 1: Basic physical features, continents, countries, capitals
- Level 2: Climate patterns, ecosystems, population distribution
- Level 3: Economic geography, urbanization, cultural landscapes
- Level 4: Environmental issues, globalization, regional analysis
- Level 5: Advanced spatial analysis, GIS applications, research methods
Focus on spatial thinking and environmental awareness.
''';
      case SubjectType.history:
        return '''
- Level 1: Ancient civilizations, basic chronology, key historical figures
- Level 2: Medieval period, exploration, early modern developments
- Level 3: Industrial revolution, nationalism, world wars
- Level 4: Cold War, decolonization, contemporary global issues
- Level 5: Historical methodology, historiography, advanced analysis
Emphasize critical thinking and source analysis skills.
''';
      case SubjectType.science:
        return '''
- Level 1: Scientific method, basic observations, simple experiments
- Level 2: Classification systems, measurement, data collection
- Level 3: Hypothesis testing, advanced experiments, analysis
- Level 4: Research methods, scientific communication, peer review
- Level 5: Independent research, advanced methodology, innovation
Focus on inquiry-based learning and scientific thinking.
''';
      case SubjectType.english:
        return '''
- Level 1: Basic grammar, simple sentences, vocabulary building
- Level 2: Complex sentences, paragraph structure, reading comprehension
- Level 3: Essay writing, literary analysis, advanced grammar
- Level 4: Research papers, critical analysis, advanced composition
- Level 5: Creative writing, advanced literature, rhetoric
Emphasize communication skills and critical thinking.
''';
      case SubjectType.art:
        return '''
- Level 1: Basic drawing, color theory, simple compositions
- Level 2: Painting techniques, design principles, art history intro
- Level 3: Advanced techniques, mixed media, art criticism
- Level 4: Portfolio development, contemporary art, digital media
- Level 5: Professional practice, exhibition, advanced concepts
Focus on creativity and visual communication.
''';
      case SubjectType.music:
        return '''
- Level 1: Basic notation, rhythm, simple melodies
- Level 2: Scales, chords, music theory fundamentals
- Level 3: Composition basics, advanced theory, performance
- Level 4: Advanced composition, music history, analysis
- Level 5: Professional skills, advanced performance, music technology
Emphasize both theory and practical application.
''';
      case SubjectType.physicalEducation:
        return '''
- Level 1: Basic movement, fitness concepts, simple games
- Level 2: Sport skills, health education, teamwork
- Level 3: Advanced skills, fitness planning, leadership
- Level 4: Coaching basics, sports science, injury prevention
- Level 5: Advanced coaching, sports psychology, program design
Focus on lifelong fitness and healthy living.
''';
    }
  }

  /// Get difficulty label for progress level
  String _getDifficultyLabel(int level) {
    switch (level) {
      case 1: return 'Beginner';
      case 2: return 'Intermediate';
      case 3: return 'Advanced';
      case 4: return 'Expert';
      case 5: return 'Master';
      default: return 'Beginner';
    }
  }

  /// Get enhanced default syllabus as fallback
  List<Map<String, dynamic>> _getEnhancedDefaultSyllabus(SubjectType subject, int level) {
    // Enhanced fallback syllabi with progressive difficulty
    switch (subject) {
      case SubjectType.math:
        return _getMathSyllabus(level);
      case SubjectType.physics:
        return _getPhysicsSyllabus(level);
      case SubjectType.chemistry:
        return _getChemistrySyllabus(level);
      case SubjectType.biology:
        return _getBiologySyllabus(level);
      case SubjectType.computerScience:
        return _getComputerScienceSyllabus(level);
      case SubjectType.geography:
        return _getGeographySyllabus(level);
      case SubjectType.history:
        return _getHistorySyllabus(level);
      case SubjectType.science:
        return _getScienceSyllabus(level);
      case SubjectType.english:
        return _getEnglishSyllabus(level);
      case SubjectType.art:
        return _getArtSyllabus(level);
      case SubjectType.music:
        return _getMusicSyllabus(level);
      case SubjectType.physicalEducation:
        return _getPhysicalEducationSyllabus(level);
    }
  }

  List<Map<String, dynamic>> _getMathSyllabus(int level) {
    final baseUnits = [
      {
        "unitId": "arithmetic_$level",
        "unitName": "Arithmetic Foundations",
        "description": "Master fundamental arithmetic operations",
        "difficulty": level,
        "estimatedHours": 8,
        "prerequisites": [],
        "skills": [
          {
            "skillId": "basic_ops_$level",
            "skillName": "Basic Operations",
            "description": "Addition, subtraction, multiplication, division",
            "difficulty": level,
            "estimatedLessons": 5,
            "learningObjectives": ["Perform accurate calculations", "Apply order of operations"]
          }
        ]
      }
    ];

    if (level >= 2) {
      baseUnits.add({
        "unitId": "algebra_$level",
        "unitName": "Algebraic Thinking",
        "description": "Introduction to variables and equations",
        "difficulty": level,
        "estimatedHours": 12,
        "prerequisites": ["arithmetic_$level"],
        "skills": [
          {
            "skillId": "variables_$level",
            "skillName": "Variables and Expressions",
            "description": "Working with algebraic expressions",
            "difficulty": level,
            "estimatedLessons": 6,
            "learningObjectives": ["Simplify expressions", "Evaluate algebraic expressions"]
          }
        ]
      });
    }

    return baseUnits;
  }

  List<Map<String, dynamic>> _getPhysicsSyllabus(int level) {
    return [
      {
        "unitId": "mechanics_$level",
        "unitName": "Classical Mechanics",
        "description": "Study of motion and forces",
        "difficulty": level,
        "estimatedHours": 10,
        "prerequisites": [],
        "skills": [
          {
            "skillId": "motion_$level",
            "skillName": "Motion and Forces",
            "description": "Understanding velocity, acceleration, and Newton's laws",
            "difficulty": level,
            "estimatedLessons": 5,
            "learningObjectives": ["Calculate motion parameters", "Apply Newton's laws"]
          }
        ]
      }
    ];
  }

  List<Map<String, dynamic>> _getChemistrySyllabus(int level) {
    return [
      {
        "unitId": "atoms_$level",
        "unitName": "Atomic Structure",
        "description": "Understanding atoms and their properties",
        "difficulty": level,
        "estimatedHours": 8,
        "prerequisites": [],
        "skills": [
          {
            "skillId": "atomic_theory_$level",
            "skillName": "Atomic Theory",
            "description": "Structure of atoms and periodic trends",
            "difficulty": level,
            "estimatedLessons": 4,
            "learningObjectives": ["Describe atomic structure", "Predict periodic trends"]
          }
        ]
      }
    ];
  }

  List<Map<String, dynamic>> _getBiologySyllabus(int level) {
    return [
      {
        "unitId": "cells_$level",
        "unitName": "Cell Biology",
        "description": "The fundamental unit of life",
        "difficulty": level,
        "estimatedHours": 9,
        "prerequisites": [],
        "skills": [
          {
            "skillId": "cell_structure_$level",
            "skillName": "Cell Structure and Function",
            "description": "Organelles and cellular processes",
            "difficulty": level,
            "estimatedLessons": 5,
            "learningObjectives": ["Identify cell organelles", "Explain cellular processes"]
          }
        ]
      }
    ];
  }

  /// Get cached dynamic syllabus
  Future<Map<String, List<Map<String, dynamic>>>> getCachedSyllabus() async {
    final prefs = await SharedPreferences.getInstance();
    final syllabusJson = prefs.getString(_syllabusKey);
    
    if (syllabusJson != null) {
      final Map<String, dynamic> data = json.decode(syllabusJson);
      return data.map((key, value) => MapEntry(
        key, 
        (value as List).cast<Map<String, dynamic>>()
      ));
    }
    
    return {};
  }

  /// Get syllabus for specific subject
  Future<List<Map<String, dynamic>>> getSyllabusForSubject(SubjectType subject) async {
    final cachedSyllabus = await getCachedSyllabus();
    return cachedSyllabus[subject.name] ?? [];
  }

  /// Get user progress levels for all subjects
  Future<Map<String, int>> _getUserProgressLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_userProgressKey);
    
    if (progressJson != null) {
      final Map<String, dynamic> data = json.decode(progressJson);
      return data.map((key, value) => MapEntry(key, value as int));
    }
    
    // Default progress levels
    return {
      for (final subject in SubjectType.values)
        subject.name: 1
    };
  }

  /// Update user progress level for a subject
  Future<void> updateUserProgress(SubjectType subject, int newLevel) async {
    final prefs = await SharedPreferences.getInstance();
    final currentProgress = await _getUserProgressLevels();
    
    currentProgress[subject.name] = min(newLevel, 5); // Cap at level 5
    
    await prefs.setString(_userProgressKey, json.encode(currentProgress));
    
    if (kDebugMode) {
      print('Updated ${subject.name} progress to level ${currentProgress[subject.name]}');
    }
  }

  List<Map<String, dynamic>> _getComputerScienceSyllabus(int level) {
    return [
      {
        "unitId": "programming_$level",
        "unitName": "Programming Fundamentals",
        "description": "Learn basic programming concepts",
        "difficulty": level,
        "estimatedHours": 10,
        "prerequisites": [],
        "skills": [
          {"skillId": "variables", "skillName": "Variables & Data Types", "description": "Understanding variables and basic data types"},
          {"skillId": "loops", "skillName": "Loops & Control Flow", "description": "For loops, while loops, and conditionals"},
          {"skillId": "functions", "skillName": "Functions", "description": "Creating and using functions"},
        ]
      }
    ];
  }

  List<Map<String, dynamic>> _getGeographySyllabus(int level) {
    return [
      {
        "unitId": "physical_geography_$level",
        "unitName": "Physical Geography",
        "description": "Study Earth's physical features",
        "difficulty": level,
        "estimatedHours": 8,
        "prerequisites": [],
        "skills": [
          {"skillId": "landforms", "skillName": "Landforms", "description": "Mountains, valleys, and coastal features"},
          {"skillId": "climate", "skillName": "Climate & Weather", "description": "Weather patterns and climate zones"},
          {"skillId": "ecosystems", "skillName": "Ecosystems", "description": "Biomes and environmental interactions"},
        ]
      }
    ];
  }

  List<Map<String, dynamic>> _getHistorySyllabus(int level) {
    return [
      {
        "unitId": "ancient_history_$level",
        "unitName": "Ancient Civilizations",
        "description": "Explore ancient civilizations",
        "difficulty": level,
        "estimatedHours": 8,
        "prerequisites": [],
        "skills": [
          {"skillId": "mesopotamia", "skillName": "Mesopotamia", "description": "Sumerians and early writing systems"},
          {"skillId": "egypt", "skillName": "Ancient Egypt", "description": "Pharaohs, pyramids, and Egyptian society"},
          {"skillId": "greece", "skillName": "Ancient Greece", "description": "Greek philosophy, democracy, and culture"},
        ]
      }
    ];
  }

  /// Force regenerate syllabus (for testing or manual refresh)
  Future<void> forceRegenerateSyllabus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastGenerationKey);
    await generateDynamicSyllabusIfDue();
  }

  List<Map<String, dynamic>> _getScienceSyllabus(int level) {
    return [
      {
        "unitId": "scientific_method_$level",
        "unitName": "Scientific Method",
        "description": "Learn the fundamentals of scientific inquiry",
        "difficulty": level,
        "estimatedHours": 8,
        "prerequisites": [],
        "skills": [
          {
            "skillId": "observation_$level",
            "skillName": "Observation Skills",
            "description": "Making accurate scientific observations",
            "difficulty": level,
            "estimatedLessons": 4,
            "learningObjectives": ["Make detailed observations", "Record data accurately"]
          }
        ]
      }
    ];
  }

  List<Map<String, dynamic>> _getEnglishSyllabus(int level) {
    return [
      {
        "unitId": "grammar_basics_$level",
        "unitName": "Grammar Fundamentals",
        "description": "Master English grammar rules",
        "difficulty": level,
        "estimatedHours": 10,
        "prerequisites": [],
        "skills": [
          {
            "skillId": "parts_of_speech_$level",
            "skillName": "Parts of Speech",
            "description": "Understanding nouns, verbs, adjectives, etc.",
            "difficulty": level,
            "estimatedLessons": 5,
            "learningObjectives": ["Identify parts of speech", "Use grammar correctly"]
          }
        ]
      }
    ];
  }

  List<Map<String, dynamic>> _getArtSyllabus(int level) {
    return [
      {
        "unitId": "art_fundamentals_$level",
        "unitName": "Art Fundamentals",
        "description": "Learn basic art concepts and techniques",
        "difficulty": level,
        "estimatedHours": 12,
        "prerequisites": [],
        "skills": [
          {
            "skillId": "drawing_basics_$level",
            "skillName": "Drawing Basics",
            "description": "Fundamental drawing techniques",
            "difficulty": level,
            "estimatedLessons": 6,
            "learningObjectives": ["Master basic shapes", "Understand proportions"]
          }
        ]
      }
    ];
  }

  List<Map<String, dynamic>> _getMusicSyllabus(int level) {
    return [
      {
        "unitId": "music_theory_$level",
        "unitName": "Music Theory",
        "description": "Learn fundamental music theory concepts",
        "difficulty": level,
        "estimatedHours": 10,
        "prerequisites": [],
        "skills": [
          {
            "skillId": "notation_$level",
            "skillName": "Musical Notation",
            "description": "Reading and writing musical notes",
            "difficulty": level,
            "estimatedLessons": 5,
            "learningObjectives": ["Read musical notation", "Understand rhythm"]
          }
        ]
      }
    ];
  }

  List<Map<String, dynamic>> _getPhysicalEducationSyllabus(int level) {
    return [
      {
        "unitId": "fitness_basics_$level",
        "unitName": "Fitness Fundamentals",
        "description": "Learn about physical fitness and health",
        "difficulty": level,
        "estimatedHours": 8,
        "prerequisites": [],
        "skills": [
          {
            "skillId": "exercise_basics_$level",
            "skillName": "Exercise Basics",
            "description": "Understanding different types of exercise",
            "difficulty": level,
            "estimatedLessons": 4,
            "learningObjectives": ["Understand fitness components", "Plan exercise routines"]
          }
        ]
      }
    ];
  }

  /// Get syllabus generation statistics
  Future<Map<String, dynamic>> getSyllabusStats() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedSyllabus = await getCachedSyllabus();
    final userProgress = await _getUserProgressLevels();
    
    return {
      'totalSubjects': SubjectType.values.length,
      'generatedSubjects': cachedSyllabus.length,
      'syllabusVersion': prefs.getInt(_syllabusVersionKey) ?? 0,
      'lastGeneration': prefs.getString(_lastGenerationKey),
      'userProgress': userProgress,
      'nextGenerationDue': await isSyllabusGenerationDue(),
    };
  }

  /// Generate procedural syllabus without AI
  List<Map<String, dynamic>> _generateProceduralSyllabus(
    SubjectType subject, 
    int progressLevel, 
    int maxUnits
  ) {
    final Random random = Random();
    final List<Map<String, dynamic>> syllabus = [];
    
    for (int unitIndex = 0; unitIndex < maxUnits; unitIndex++) {
      final unitData = _generateProceduralUnit(subject, progressLevel, unitIndex, random);
      syllabus.add(unitData);
    }
    
    return syllabus;
  }

  /// Generate a single procedural unit
  Map<String, dynamic> _generateProceduralUnit(
    SubjectType subject, 
    int progressLevel, 
    int unitIndex, 
    Random random
  ) {
    final skillCount = 3 + random.nextInt(3); // 3-5 skills per unit
    final skills = <Map<String, dynamic>>[];
    
    for (int skillIndex = 0; skillIndex < skillCount; skillIndex++) {
      final skill = _generateProceduralSkill(subject, progressLevel, unitIndex, skillIndex);
      skills.add(skill);
    }
    
    return {
      'id': '${subject.name.toLowerCase()}_unit_${unitIndex + 1}',
      'title': _getUnitTitle(subject, unitIndex),
      'description': _getUnitDescription(subject, unitIndex),
      'order': unitIndex,
      'difficulty': progressLevel + (unitIndex ~/ 2),
      'estimatedHours': 2 + (skillCount * 0.5),
      'skills': skills,
      'prerequisites': unitIndex > 0 ? ['${subject.name.toLowerCase()}_unit_$unitIndex'] : [],
    };
  }

  /// Generate a single procedural skill
  Map<String, dynamic> _generateProceduralSkill(
    SubjectType subject, 
    int progressLevel, 
    int unitIndex, 
    int skillIndex
  ) {
    return {
      'id': '${subject.name.toLowerCase()}_unit_${unitIndex + 1}_skill_${skillIndex + 1}',
      'title': _getSkillTitle(subject, unitIndex, skillIndex),
      'description': _getSkillDescription(subject, unitIndex, skillIndex),
      'difficulty': progressLevel + (unitIndex ~/ 2),
      'estimatedMinutes': 15 + (skillIndex * 5),
      'practiceQuestions': 10 + (progressLevel * 2),
      'masteryThreshold': 0.8,
    };
  }

  /// Get unit title based on subject and index
  String _getUnitTitle(SubjectType subject, int unitIndex) {
    switch (subject) {
      case SubjectType.math:
        final mathUnits = [
          'Basic Arithmetic',
          'Fractions and Decimals',
          'Geometry Fundamentals',
          'Algebra Basics',
          'Statistics and Probability',
          'Advanced Algebra',
          'Trigonometry',
          'Calculus Introduction',
        ];
        return mathUnits[unitIndex % mathUnits.length];
      
      case SubjectType.science:
        final scienceUnits = [
          'Scientific Method',
          'Matter and Energy',
          'Living Things',
          'Earth and Space',
          'Forces and Motion',
          'Chemistry Basics',
          'Biology Systems',
          'Physics Principles',
        ];
        return scienceUnits[unitIndex % scienceUnits.length];
      
      case SubjectType.english:
        final englishUnits = [
          'Reading Comprehension',
          'Grammar Fundamentals',
          'Writing Skills',
          'Vocabulary Building',
          'Literature Analysis',
          'Creative Writing',
          'Research Skills',
          'Communication',
        ];
        return englishUnits[unitIndex % englishUnits.length];
      
      case SubjectType.history:
        final historyUnits = [
          'Ancient Civilizations',
          'Medieval Times',
          'Renaissance Period',
          'Industrial Revolution',
          'Modern History',
          'World Wars',
          'Contemporary Issues',
          'Cultural Heritage',
        ];
        return historyUnits[unitIndex % historyUnits.length];
      
      case SubjectType.geography:
        final geographyUnits = [
          'World Maps',
          'Continents and Oceans',
          'Climate and Weather',
          'Natural Resources',
          'Population and Cities',
          'Cultural Geography',
          'Environmental Issues',
          'Global Connections',
        ];
        return geographyUnits[unitIndex % geographyUnits.length];
      
      case SubjectType.physics:
        final physicsUnits = [
          'Mechanics',
          'Waves and Sound',
          'Electricity and Magnetism',
          'Thermodynamics',
          'Optics',
          'Modern Physics',
          'Nuclear Physics',
          'Quantum Mechanics',
        ];
        return physicsUnits[unitIndex % physicsUnits.length];
      
      case SubjectType.chemistry:
        final chemistryUnits = [
          'Atomic Structure',
          'Periodic Table',
          'Chemical Bonding',
          'Chemical Reactions',
          'Acids and Bases',
          'Organic Chemistry',
          'Thermochemistry',
          'Electrochemistry',
        ];
        return chemistryUnits[unitIndex % chemistryUnits.length];
      
      case SubjectType.biology:
        final biologyUnits = [
          'Cell Biology',
          'Genetics',
          'Evolution',
          'Ecology',
          'Human Biology',
          'Plant Biology',
          'Animal Biology',
          'Molecular Biology',
        ];
        return biologyUnits[unitIndex % biologyUnits.length];
      
      case SubjectType.computerScience:
        final computerScienceUnits = [
          'Programming Basics',
          'Data Structures',
          'Algorithms',
          'Object-Oriented Programming',
          'Database Systems',
          'Web Development',
          'Software Engineering',
          'Computer Networks',
        ];
        return computerScienceUnits[unitIndex % computerScienceUnits.length];
      
      case SubjectType.art:
        final artUnits = [
          'Drawing Fundamentals',
          'Color Theory',
          'Painting Techniques',
          'Sculpture Basics',
          'Art History',
          'Digital Art',
          'Mixed Media',
          'Portfolio Development',
        ];
        return artUnits[unitIndex % artUnits.length];
      
      case SubjectType.music:
        final musicUnits = [
          'Music Theory',
          'Rhythm and Beat',
          'Melody and Harmony',
          'Instrument Basics',
          'Music History',
          'Composition',
          'Performance Skills',
          'Music Technology',
        ];
        return musicUnits[unitIndex % musicUnits.length];
      
      case SubjectType.physicalEducation:
        final physicalEducationUnits = [
          'Fitness Fundamentals',
          'Team Sports',
          'Individual Sports',
          'Health and Nutrition',
          'Motor Skills',
          'Safety and First Aid',
          'Outdoor Activities',
          'Wellness Planning',
        ];
        return physicalEducationUnits[unitIndex % physicalEducationUnits.length];
    }
  }

  /// Get unit description
  String _getUnitDescription(SubjectType subject, int unitIndex) {
    return 'Learn fundamental concepts and skills in ${_getUnitTitle(subject, unitIndex).toLowerCase()}.';
  }

  /// Get skill title
  String _getSkillTitle(SubjectType subject, int unitIndex, int skillIndex) {
    final unitTitle = _getUnitTitle(subject, unitIndex);
    final skillSuffixes = ['Basics', 'Practice', 'Application', 'Mastery', 'Advanced'];
    return '$unitTitle - ${skillSuffixes[skillIndex % skillSuffixes.length]}';
  }

  /// Get skill description
  String _getSkillDescription(SubjectType subject, int unitIndex, int skillIndex) {
    final skillTitle = _getSkillTitle(subject, unitIndex, skillIndex);
    return 'Master the essential concepts and techniques in ${skillTitle.toLowerCase()}.';
  }
}