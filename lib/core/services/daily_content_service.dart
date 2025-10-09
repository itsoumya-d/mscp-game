import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/subject.dart';
import 'unified_xp_service.dart';

class DailyContentService {
  static const String _lastGenerationKey = 'daily_content_last_generation';
  static const String _dailyContentKey = 'daily_content_cache';
  static const String _difficultyProgressKey = 'difficulty_progress';
  
  // Content generation limits per day
  static const int maxDailyLessons = 50; // Conservative limit to stay within API quota
  static const int questionsPerLesson = 5;
  static const int maxDifficultyLevel = 10;
  
  static DailyContentService? _instance;
  
  static DailyContentService getInstance() {
    _instance ??= DailyContentService._internal();
    return _instance!;
  }
  
  @Deprecated('Use getInstance() instead')
  static DailyContentService get instance => getInstance();
  
  DailyContentService._internal();
  
  /// Check if daily content generation is due and generate new content
  Future<void> generateDailyContentIfDue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastGeneration = prefs.getString(_lastGenerationKey);
      
      // Only generate once per day
      if (lastGeneration == today) {
        if (kDebugMode) {
          print('Daily content already generated for today');
        }
        return;
      }
      
      // Generate procedural content directly
      await _generateDailyContent();
      await prefs.setString(_lastGenerationKey, today);
      
      if (kDebugMode) {
        print('Daily content generation completed for $today');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Daily content generation failed: $e');
      }
    }
  }
  
  /// Generate daily content for all subjects with progressive difficulty
  Future<void> _generateDailyContent() async {
    final prefs = await SharedPreferences.getInstance();
    final difficultyProgress = await _getDifficultyProgress();
    
    final Map<String, List<Map<String, dynamic>>> dailyContent = {};
    int totalLessonsGenerated = 0;
    
    // Generate content for each subject
    for (final subject in SubjectType.values) {
      if (totalLessonsGenerated >= maxDailyLessons) break;
      
      final subjectDifficulty = difficultyProgress[subject.name] ?? 1;
      final lessonsToGenerate = min(
        maxDailyLessons ~/ SubjectType.values.length, // Distribute evenly
        maxDailyLessons - totalLessonsGenerated
      );
      
      final subjectContent = await _generateSubjectContent(
        subject, 
        subjectDifficulty, 
        lessonsToGenerate
      );
      
      if (subjectContent.isNotEmpty) {
        dailyContent[subject.name] = subjectContent;
        totalLessonsGenerated += subjectContent.length;
        
        // Gradually increase difficulty over time
        if (subjectContent.length >= lessonsToGenerate * 0.8) { // 80% success rate
          await _incrementDifficultyProgress(subject);
        }
      }
    }
    
    // Cache the generated content
    await prefs.setString(_dailyContentKey, json.encode(dailyContent));
    
    if (kDebugMode) {
      print('Generated $totalLessonsGenerated lessons across ${dailyContent.length} subjects');
    }
  }
  
  /// Generate content for a specific subject
  Future<List<Map<String, dynamic>>> _generateSubjectContent(
    SubjectType subject, 
    int difficulty, 
    int lessonCount
  ) async {
    final List<Map<String, dynamic>> lessons = [];
    
    try {
      // Generate procedural content for the subject
      final syllabus = _generateProceduralSyllabus(subject);
      
      for (int i = 0; i < lessonCount && i < syllabus.length; i++) {
        final unit = syllabus[i];
        final skills = unit['skills'] as List<dynamic>;
        
        for (final skillData in skills) {
          if (lessons.length >= lessonCount) break;
          
          final skillId = skillData['skillId'] as String;
          final skillName = skillData['skillName'] as String;
          
          // Generate questions for this skill
          final questions = _generateProceduralQuestions(
            subject,
            skillId,
            skillName,
            difficulty,
            count: questionsPerLesson,
          );
          
          if (questions.isNotEmpty) {
            lessons.add({
              'id': '${subject.name.toLowerCase()}_${skillId}_${DateTime.now().millisecondsSinceEpoch}',
              'title': skillName,
              'description': skillData['description'] as String,
              'subject': subject.name,
              'skillId': skillId,
              'difficulty': difficulty,
              'xpReward': _calculateXpReward(difficulty),
              'questions': questions,
              'generatedAt': DateTime.now().toIso8601String(),
            });
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to generate content for ${subject.name}: $e');
      }
    }
    
    return lessons;
  }
  
  /// Calculate XP reward based on difficulty
  int _calculateXpReward(int difficulty) {
    return UnifiedXPService.getInstance().calculateLessonXP(difficulty);
  }
  
  /// Get current difficulty progress for all subjects
  Future<Map<String, int>> _getDifficultyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_difficultyProgressKey);
    
    if (progressJson != null) {
      final Map<String, dynamic> progress = json.decode(progressJson);
      return progress.map((key, value) => MapEntry(key, value as int));
    }
    
    // Initialize with difficulty level 1 for all subjects
    final initialProgress = <String, int>{};
    for (final subject in SubjectType.values) {
      initialProgress[subject.name] = 1;
    }
    
    return initialProgress;
  }
  
  /// Increment difficulty progress for a subject
  Future<void> _incrementDifficultyProgress(SubjectType subject) async {
    final prefs = await SharedPreferences.getInstance();
    final progress = await _getDifficultyProgress();
    
    final currentDifficulty = progress[subject.name] ?? 1;
    final newDifficulty = min(currentDifficulty + 1, maxDifficultyLevel);
    
    progress[subject.name] = newDifficulty;
    await prefs.setString(_difficultyProgressKey, json.encode(progress));
    
    if (kDebugMode) {
      print('${subject.name} difficulty increased to $newDifficulty');
    }
  }
  
  /// Get cached daily content
  Future<Map<String, List<Map<String, dynamic>>>> getDailyContent() async {
    final prefs = await SharedPreferences.getInstance();
    final contentJson = prefs.getString(_dailyContentKey);
    
    if (contentJson != null) {
      final Map<String, dynamic> content = json.decode(contentJson);
      return content.map((key, value) => 
        MapEntry(key, (value as List).cast<Map<String, dynamic>>())
      );
    }
    
    return {};
  }
  
  /// Get daily content for a specific subject
  Future<List<Map<String, dynamic>>> getSubjectDailyContent(SubjectType subject) async {
    final dailyContent = await getDailyContent();
    return dailyContent[subject.name] ?? [];
  }
  
  /// Check if daily content is available
  Future<bool> hasDailyContent() async {
    final dailyContent = await getDailyContent();
    return dailyContent.isNotEmpty;
  }
  
  /// Get current difficulty level for a subject
  Future<int> getSubjectDifficulty(SubjectType subject) async {
    final progress = await _getDifficultyProgress();
    return progress[subject.name] ?? 1;
  }
  
  /// Get API usage statistics
  Future<Map<String, dynamic>> getUsageStats() async {
    final hasContent = await hasDailyContent();
    
    return {
      'dailyUsage': 0,
      'remainingRequests': 1000,
      'maxDailyRequests': 1000,
      'hasDailyContent': hasContent,
      'lastGeneration': await _getLastGenerationDate(),
    };
  }
  
  /// Get last generation date
  Future<String?> _getLastGenerationDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastGenerationKey);
  }
  
  /// Force regenerate daily content (for testing/admin purposes)
  Future<void> forceRegenerateContent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastGenerationKey);
    await generateDailyContentIfDue();
  }
  
  /// Clear all cached content
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dailyContentKey);
    await prefs.remove(_lastGenerationKey);
    await prefs.remove(_difficultyProgressKey);
  }

  /// Generate procedural syllabus for a subject
  List<Map<String, dynamic>> _generateProceduralSyllabus(SubjectType subject) {
    final Random random = Random();
    
    switch (subject) {
      case SubjectType.math:
        return [
          {
            'unitId': 'arithmetic',
            'unitName': 'Basic Arithmetic',
            'skills': [
              {'skillId': 'addition', 'skillName': 'Addition', 'description': 'Adding numbers together'},
              {'skillId': 'subtraction', 'skillName': 'Subtraction', 'description': 'Subtracting numbers'},
              {'skillId': 'multiplication', 'skillName': 'Multiplication', 'description': 'Multiplying numbers'},
              {'skillId': 'division', 'skillName': 'Division', 'description': 'Dividing numbers'},
            ]
          },
          {
            'unitId': 'fractions',
            'unitName': 'Fractions',
            'skills': [
              {'skillId': 'fraction_basics', 'skillName': 'Fraction Basics', 'description': 'Understanding fractions'},
              {'skillId': 'fraction_operations', 'skillName': 'Fraction Operations', 'description': 'Adding and subtracting fractions'},
            ]
          }
        ];
      case SubjectType.science:
        return [
          {
            'unitId': 'biology',
            'unitName': 'Biology Basics',
            'skills': [
              {'skillId': 'human_body', 'skillName': 'Human Body', 'description': 'Learning about the human body'},
              {'skillId': 'plants', 'skillName': 'Plants', 'description': 'Understanding plant life'},
            ]
          },
          {
            'unitId': 'physics',
            'unitName': 'Physics Basics',
            'skills': [
              {'skillId': 'forces', 'skillName': 'Forces', 'description': 'Understanding forces and motion'},
              {'skillId': 'energy', 'skillName': 'Energy', 'description': 'Types of energy'},
            ]
          }
        ];
      case SubjectType.english:
        return [
          {
            'unitId': 'grammar',
            'unitName': 'Grammar',
            'skills': [
              {'skillId': 'nouns', 'skillName': 'Nouns', 'description': 'Understanding nouns'},
              {'skillId': 'verbs', 'skillName': 'Verbs', 'description': 'Understanding verbs'},
              {'skillId': 'adjectives', 'skillName': 'Adjectives', 'description': 'Understanding adjectives'},
            ]
          }
        ];
      case SubjectType.history:
        return [
          {
            'unitId': 'ancient_history',
            'unitName': 'Ancient History',
            'skills': [
              {'skillId': 'ancient_civilizations', 'skillName': 'Ancient Civilizations', 'description': 'Learning about ancient civilizations'},
              {'skillId': 'historical_figures', 'skillName': 'Historical Figures', 'description': 'Important people in history'},
            ]
          }
        ];
      case SubjectType.geography:
        return [
          {
            'unitId': 'world_geography',
            'unitName': 'World Geography',
            'skills': [
              {'skillId': 'continents', 'skillName': 'Continents', 'description': 'Learning about continents'},
              {'skillId': 'countries', 'skillName': 'Countries', 'description': 'Learning about countries'},
              {'skillId': 'capitals', 'skillName': 'Capitals', 'description': 'Capital cities of countries'},
            ]
          }
        ];
      case SubjectType.chemistry:
        return [
          {
            'unitId': 'atoms_molecules',
            'unitName': 'Atoms and Molecules',
            'skills': [
              {'skillId': 'atomic_structure', 'skillName': 'Atomic Structure', 'description': 'Understanding atoms and their components'},
              {'skillId': 'periodic_table', 'skillName': 'Periodic Table', 'description': 'Elements and their properties'},
              {'skillId': 'chemical_bonds', 'skillName': 'Chemical Bonds', 'description': 'How atoms bond together'},
            ]
          },
          {
            'unitId': 'reactions',
            'unitName': 'Chemical Reactions',
            'skills': [
              {'skillId': 'reaction_types', 'skillName': 'Reaction Types', 'description': 'Different types of chemical reactions'},
              {'skillId': 'balancing_equations', 'skillName': 'Balancing Equations', 'description': 'Balancing chemical equations'},
            ]
          }
        ];
      case SubjectType.physics:
        return [
          {
            'unitId': 'mechanics',
            'unitName': 'Mechanics',
            'skills': [
              {'skillId': 'motion', 'skillName': 'Motion', 'description': 'Understanding motion and velocity'},
              {'skillId': 'forces', 'skillName': 'Forces', 'description': 'Understanding forces and Newton\'s laws'},
              {'skillId': 'energy', 'skillName': 'Energy', 'description': 'Kinetic and potential energy'},
            ]
          },
          {
            'unitId': 'waves',
            'unitName': 'Waves and Sound',
            'skills': [
              {'skillId': 'wave_properties', 'skillName': 'Wave Properties', 'description': 'Understanding wave characteristics'},
              {'skillId': 'sound_waves', 'skillName': 'Sound Waves', 'description': 'How sound travels'},
            ]
          }
        ];
      case SubjectType.biology:
        return [
          {
            'unitId': 'cell_biology',
            'unitName': 'Cell Biology',
            'skills': [
              {'skillId': 'cell_structure', 'skillName': 'Cell Structure', 'description': 'Understanding cell components'},
              {'skillId': 'cell_functions', 'skillName': 'Cell Functions', 'description': 'How cells work and reproduce'},
              {'skillId': 'cell_types', 'skillName': 'Cell Types', 'description': 'Different types of cells'},
            ]
          },
          {
            'unitId': 'genetics',
            'unitName': 'Genetics',
            'skills': [
              {'skillId': 'dna_structure', 'skillName': 'DNA Structure', 'description': 'Understanding DNA and genes'},
              {'skillId': 'inheritance', 'skillName': 'Inheritance', 'description': 'How traits are passed down'},
            ]
          }
        ];
      case SubjectType.computerScience:
        return [
          {
            'unitId': 'programming_basics',
            'unitName': 'Programming Basics',
            'skills': [
              {'skillId': 'variables', 'skillName': 'Variables', 'description': 'Understanding variables and data types'},
              {'skillId': 'loops', 'skillName': 'Loops', 'description': 'For loops and while loops'},
              {'skillId': 'conditionals', 'skillName': 'Conditionals', 'description': 'If statements and boolean logic'},
            ]
          },
          {
            'unitId': 'algorithms',
            'unitName': 'Algorithms',
            'skills': [
              {'skillId': 'sorting', 'skillName': 'Sorting', 'description': 'Sorting algorithms and techniques'},
              {'skillId': 'searching', 'skillName': 'Searching', 'description': 'Search algorithms and data structures'},
            ]
          }
        ];
      case SubjectType.art:
        return [
          {
            'unitId': 'drawing_basics',
            'unitName': 'Drawing Basics',
            'skills': [
              {'skillId': 'shapes', 'skillName': 'Basic Shapes', 'description': 'Drawing circles, squares, and triangles'},
              {'skillId': 'lines', 'skillName': 'Line Drawing', 'description': 'Different types of lines and strokes'},
              {'skillId': 'shading', 'skillName': 'Shading', 'description': 'Creating depth with light and shadow'},
            ]
          },
          {
            'unitId': 'color_theory',
            'unitName': 'Color Theory',
            'skills': [
              {'skillId': 'primary_colors', 'skillName': 'Primary Colors', 'description': 'Understanding red, blue, and yellow'},
              {'skillId': 'color_mixing', 'skillName': 'Color Mixing', 'description': 'Creating secondary colors'},
            ]
          }
        ];
      case SubjectType.music:
        return [
          {
            'unitId': 'music_basics',
            'unitName': 'Music Basics',
            'skills': [
              {'skillId': 'notes', 'skillName': 'Musical Notes', 'description': 'Understanding musical notes and staff'},
              {'skillId': 'rhythm', 'skillName': 'Rhythm', 'description': 'Beat and timing in music'},
              {'skillId': 'instruments', 'skillName': 'Instruments', 'description': 'Different types of musical instruments'},
            ]
          }
        ];
      case SubjectType.physicalEducation:
        return [
          {
            'unitId': 'fitness_basics',
            'unitName': 'Fitness Basics',
            'skills': [
              {'skillId': 'exercises', 'skillName': 'Basic Exercises', 'description': 'Fundamental physical exercises'},
              {'skillId': 'sports_rules', 'skillName': 'Sports Rules', 'description': 'Rules of common sports'},
              {'skillId': 'health', 'skillName': 'Health & Wellness', 'description': 'Understanding physical health'},
            ]
          }
        ];
    }
  }

  /// Generate procedural questions for a skill
  List<Map<String, dynamic>> _generateProceduralQuestions(
    SubjectType subject,
    String skillId,
    String skillName,
    int difficulty, {
    required int count,
  }) {
    final Random random = Random();
    final List<Map<String, dynamic>> questions = [];
    
    for (int i = 0; i < count; i++) {
      final question = _generateSingleQuestion(subject, skillId, difficulty, i, random);
      questions.add(question);
    }
    
    return questions;
  }

  /// Generate a single question based on subject and skill
  Map<String, dynamic> _generateSingleQuestion(
    SubjectType subject,
    String skillId,
    int difficulty,
    int index,
    Random random,
  ) {
    switch (subject) {
      case SubjectType.math:
        return _generateMathQuestionBySkill(skillId, difficulty, index, random);
      case SubjectType.science:
        return _generateScienceQuestionBySkill(skillId, difficulty, index, random);
      case SubjectType.english:
        return _generateEnglishQuestionBySkill(skillId, difficulty, index, random);
      case SubjectType.history:
        return _generateHistoryQuestionBySkill(skillId, difficulty, index, random);
      case SubjectType.geography:
        return _generateGeographyQuestionBySkill(skillId, difficulty, index, random);
      case SubjectType.chemistry:
        return _generateChemistryQuestionBySkill(skillId, difficulty, index, random);
      case SubjectType.physics:
        return _generatePhysicsQuestionBySkill(skillId, difficulty, index, random);
      case SubjectType.biology:
        return _generateBiologyQuestionBySkill(skillId, difficulty, index, random);
      case SubjectType.computerScience:
        return _generateComputerScienceQuestionBySkill(skillId, difficulty, index, random);
      case SubjectType.art:
        return _generateArtQuestionBySkill(skillId, difficulty, index, random);
      case SubjectType.music:
        return _generateMusicQuestionBySkill(skillId, difficulty, index, random);
      case SubjectType.physicalEducation:
        return _generatePhysicalEducationQuestionBySkill(skillId, difficulty, index, random);
    }
  }

  Map<String, dynamic> _generateMathQuestionBySkill(String skillId, int difficulty, int index, Random random) {
    final multiplier = (difficulty + 1) * 10;
    
    switch (skillId) {
      case 'addition':
        final a = random.nextInt(multiplier) + 1;
        final b = random.nextInt(multiplier) + 1;
        final answer = a + b;
        return _createMathQuestion('What is $a + $b?', answer, index);
      case 'subtraction':
        final a = random.nextInt(multiplier) + multiplier;
        final b = random.nextInt(a);
        final answer = a - b;
        return _createMathQuestion('What is $a - $b?', answer, index);
      case 'multiplication':
        final a = random.nextInt(12) + 1;
        final b = random.nextInt(12) + 1;
        final answer = a * b;
        return _createMathQuestion('What is $a × $b?', answer, index);
      case 'division':
        final answer = random.nextInt(12) + 1;
        final b = random.nextInt(12) + 1;
        final a = answer * b;
        return _createMathQuestion('What is $a ÷ $b?', answer, index);
      default:
        return _createMathQuestion('What is 1 + 1?', 2, index);
    }
  }

  Map<String, dynamic> _createMathQuestion(String questionText, int answer, int index) {
    final Random random = Random();
    final wrongAnswers = <int>[];
    
    while (wrongAnswers.length < 3) {
      final wrong = answer + random.nextInt(20) - 10;
      if (wrong != answer && !wrongAnswers.contains(wrong) && wrong > 0) {
        wrongAnswers.add(wrong);
      }
    }
    
    final options = [answer.toString(), ...wrongAnswers.map((w) => w.toString())];
    options.shuffle(random);
    
    return {
      'id': 'math_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': questionText,
      'options': options,
      'correctAnswer': answer.toString(),
      'type': 'multiple_choice',
      'explanation': 'The correct answer is $answer.',
    };
  }

  Map<String, dynamic> _generateScienceQuestionBySkill(String skillId, int difficulty, int index, Random random) {
    final questions = {
      'human_body': [
        {
          'text': 'How many bones are in the adult human body?',
          'options': ['206', '208', '210', '212'],
          'correct': '206',
          'explanation': 'The adult human body has 206 bones.',
        }
      ],
      'plants': [
        {
          'text': 'What gas do plants absorb from the atmosphere?',
          'options': ['Oxygen', 'Carbon Dioxide', 'Nitrogen', 'Hydrogen'],
          'correct': 'Carbon Dioxide',
          'explanation': 'Plants absorb carbon dioxide during photosynthesis.',
        }
      ],
    };
    
    final skillQuestions = questions[skillId] ?? questions['human_body']!;
    final question = skillQuestions[random.nextInt(skillQuestions.length)];
    
    return {
      'id': 'science_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generateEnglishQuestionBySkill(String skillId, int difficulty, int index, Random random) {
    final questions = {
      'nouns': [
        {
          'text': 'Which word is a noun?',
          'options': ['run', 'happy', 'book', 'quickly'],
          'correct': 'book',
          'explanation': 'A noun is a person, place, or thing. Book is a thing.',
        }
      ],
      'verbs': [
        {
          'text': 'Which word is a verb?',
          'options': ['table', 'run', 'blue', 'slowly'],
          'correct': 'run',
          'explanation': 'A verb is an action word. Run is an action.',
        }
      ],
    };
    
    final skillQuestions = questions[skillId] ?? questions['nouns']!;
    final question = skillQuestions[random.nextInt(skillQuestions.length)];
    
    return {
      'id': 'english_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generateHistoryQuestionBySkill(String skillId, int difficulty, int index, Random random) {
    final questions = [
      {
        'text': 'Who was the first President of the United States?',
        'options': ['George Washington', 'Thomas Jefferson', 'John Adams', 'Benjamin Franklin'],
        'correct': 'George Washington',
        'explanation': 'George Washington was the first President of the United States.',
      }
    ];
    
    final question = questions[random.nextInt(questions.length)];
    
    return {
      'id': 'history_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generateGeographyQuestionBySkill(String skillId, int difficulty, int index, Random random) {
    final questions = {
      'continents': [
        {
          'text': 'Which is the largest continent?',
          'options': ['Africa', 'Asia', 'North America', 'Europe'],
          'correct': 'Asia',
          'explanation': 'Asia is the largest continent by both area and population.',
        }
      ],
      'capitals': [
        {
          'text': 'What is the capital of France?',
          'options': ['London', 'Berlin', 'Paris', 'Madrid'],
          'correct': 'Paris',
          'explanation': 'Paris is the capital of France.',
        }
      ],
    };
    
    final skillQuestions = questions[skillId] ?? questions['continents']!;
    final question = skillQuestions[random.nextInt(skillQuestions.length)];
    
    return {
      'id': 'geography_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generatePhysicsQuestionBySkill(String skillId, int difficulty, int index, Random random) {
    final questions = {
      'motion': [
        {
          'text': 'What is the unit of velocity?',
          'options': ['m/s', 'm/s²', 'kg', 'N'],
          'correct': 'm/s',
          'explanation': 'Velocity is measured in meters per second (m/s).'
        },
        {
          'text': 'What is acceleration?',
          'options': ['Change in position', 'Change in velocity', 'Change in mass', 'Change in force'],
          'correct': 'Change in velocity',
          'explanation': 'Acceleration is the rate of change of velocity.'
        }
      ],
      'forces': [
        {
          'text': 'What is Newton\'s first law?',
          'options': ['F = ma', 'Objects at rest stay at rest', 'Action-reaction', 'E = mc²'],
          'correct': 'Objects at rest stay at rest',
          'explanation': 'Newton\'s first law states that objects at rest stay at rest unless acted upon by a force.'
        },
        {
          'text': 'What is the unit of force?',
          'options': ['Newton (N)', 'Joule (J)', 'Watt (W)', 'Pascal (Pa)'],
          'correct': 'Newton (N)',
          'explanation': 'Force is measured in Newtons (N).'
        }
      ],
      'energy': [
        {
          'text': 'What is kinetic energy?',
          'options': ['Energy of motion', 'Stored energy', 'Heat energy', 'Light energy'],
          'correct': 'Energy of motion',
          'explanation': 'Kinetic energy is the energy an object has due to its motion.'
        }
      ],
      'wave_properties': [
        {
          'text': 'What is frequency?',
          'options': ['Wave height', 'Wave speed', 'Waves per second', 'Wave length'],
          'correct': 'Waves per second',
          'explanation': 'Frequency is the number of waves that pass a point per second.'
        }
      ],
      'sound_waves': [
        {
          'text': 'How does sound travel?',
          'options': ['Through vibrations', 'Through light', 'Through magnetism', 'Through electricity'],
          'correct': 'Through vibrations',
          'explanation': 'Sound travels through vibrations in matter.'
        }
      ]
    };
    
    final skillQuestions = questions[skillId] ?? questions['motion']!;
    final question = skillQuestions[random.nextInt(skillQuestions.length)];
    
    return {
      'id': 'physics_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generateChemistryQuestionBySkill(String skillId, int difficulty, int index, Random random) {
    final questions = {
      'atomic_structure': [
        {
          'text': 'What is the center of an atom called?',
          'options': ['Nucleus', 'Electron', 'Proton', 'Neutron'],
          'correct': 'Nucleus',
          'explanation': 'The nucleus is the center of an atom containing protons and neutrons.'
        },
        {
          'text': 'Which particle has a negative charge?',
          'options': ['Electron', 'Proton', 'Neutron', 'Nucleus'],
          'correct': 'Electron',
          'explanation': 'Electrons have a negative charge and orbit the nucleus.'
        }
      ],
      'periodic_table': [
        {
          'text': 'What is the chemical symbol for water?',
          'options': ['H2O', 'CO2', 'NaCl', 'O2'],
          'correct': 'H2O',
          'explanation': 'Water is composed of two hydrogen atoms and one oxygen atom.'
        },
        {
          'text': 'Which element has the symbol "O"?',
          'options': ['Oxygen', 'Gold', 'Silver', 'Iron'],
          'correct': 'Oxygen',
          'explanation': 'Oxygen has the chemical symbol "O" on the periodic table.'
        }
      ],
      'chemical_bonds': [
        {
          'text': 'What type of bond forms when electrons are shared?',
          'options': ['Covalent', 'Ionic', 'Metallic', 'Hydrogen'],
          'correct': 'Covalent',
          'explanation': 'Covalent bonds form when atoms share electrons.'
        }
      ],
      'reaction_types': [
        {
          'text': 'What happens in a combustion reaction?',
          'options': ['Substance burns with oxygen', 'Substance dissolves', 'Substance freezes', 'Substance melts'],
          'correct': 'Substance burns with oxygen',
          'explanation': 'Combustion reactions involve burning with oxygen to produce heat and light.'
        }
      ],
      'balancing_equations': [
        {
          'text': 'In a balanced equation, what must be equal on both sides?',
          'options': ['Number of atoms', 'Number of molecules', 'Temperature', 'Pressure'],
          'correct': 'Number of atoms',
          'explanation': 'In balanced equations, the number of each type of atom must be equal on both sides.'
        }
      ]
    };
    
    final skillQuestions = questions[skillId] ?? questions['atomic_structure']!;
    final question = skillQuestions[random.nextInt(skillQuestions.length)];
    
    return {
      'id': 'chemistry_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'explanation': question['explanation'],
    };
  }

  /// Generate biology questions by skill
  Map<String, dynamic> _generateBiologyQuestionBySkill(
    String skillId,
    int difficulty,
    int index,
    Random random,
  ) {
    final Map<String, List<Map<String, dynamic>>> questions = {
      'cell_structure': [
        {
          'text': 'What is the control center of a cell?',
          'options': ['Nucleus', 'Mitochondria', 'Cytoplasm', 'Cell membrane'],
          'correct': 'Nucleus',
          'explanation': 'The nucleus controls all cell activities and contains the cell\'s DNA.'
        },
        {
          'text': 'Which organelle produces energy for the cell?',
          'options': ['Nucleus', 'Mitochondria', 'Ribosome', 'Vacuole'],
          'correct': 'Mitochondria',
          'explanation': 'Mitochondria are known as the powerhouses of the cell, producing ATP energy.'
        }
      ],
      'cell_functions': [
        {
          'text': 'What process do plants use to make their own food?',
          'options': ['Respiration', 'Photosynthesis', 'Digestion', 'Circulation'],
          'correct': 'Photosynthesis',
          'explanation': 'Photosynthesis is the process where plants use sunlight to convert carbon dioxide and water into glucose.'
        }
      ],
      'cell_types': [
        {
          'text': 'Which type of cell has a nucleus?',
          'options': ['Prokaryotic', 'Eukaryotic', 'Bacterial', 'Viral'],
          'correct': 'Eukaryotic',
          'explanation': 'Eukaryotic cells have a membrane-bound nucleus, unlike prokaryotic cells.'
        }
      ],
      'dna_structure': [
        {
          'text': 'What does DNA stand for?',
          'options': ['Deoxyribonucleic Acid', 'Deoxyribose Nucleic Acid', 'Dynamic Nuclear Acid', 'Double Nuclear Acid'],
          'correct': 'Deoxyribonucleic Acid',
          'explanation': 'DNA stands for Deoxyribonucleic Acid, which carries genetic information.'
        }
      ],
      'inheritance': [
        {
          'text': 'What are the basic units of heredity?',
          'options': ['Chromosomes', 'Genes', 'Proteins', 'Cells'],
          'correct': 'Genes',
          'explanation': 'Genes are the basic units of heredity that determine traits passed from parents to offspring.'
        }
      ]
    };
    
    final skillQuestions = questions[skillId] ?? questions['cell_structure']!;
    final question = skillQuestions[random.nextInt(skillQuestions.length)];
    
    return {
      'id': 'biology_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generateComputerScienceQuestionBySkill(String skillId, int difficulty, int index, Random random) {
    final questions = <String, List<Map<String, dynamic>>>{
      'variables': [
        {
          'text': 'Which of the following is a valid variable name in most programming languages?',
          'options': ['123name', 'my_variable', 'class', 'for'],
          'correct': 'my_variable',
          'explanation': 'Variable names cannot start with numbers or be reserved keywords.'
        },
        {
          'text': 'What data type would you use to store a whole number?',
          'options': ['String', 'Boolean', 'Integer', 'Float'],
          'correct': 'Integer',
          'explanation': 'Integer data type is used to store whole numbers without decimal points.'
        }
      ],
      'loops': [
        {
          'text': 'Which loop is best when you know exactly how many times to repeat?',
          'options': ['while loop', 'for loop', 'do-while loop', 'infinite loop'],
          'correct': 'for loop',
          'explanation': 'For loops are ideal when you know the exact number of iterations needed.'
        }
      ],
      'conditionals': [
        {
          'text': 'What does an if statement do?',
          'options': ['Repeats code', 'Stores data', 'Makes decisions', 'Defines functions'],
          'correct': 'Makes decisions',
          'explanation': 'If statements allow programs to make decisions based on conditions.'
        }
      ],
      'sorting': [
        {
          'text': 'Which sorting algorithm is generally fastest for large datasets?',
          'options': ['Bubble Sort', 'Quick Sort', 'Selection Sort', 'Insertion Sort'],
          'correct': 'Quick Sort',
          'explanation': 'Quick Sort has an average time complexity of O(n log n), making it efficient for large datasets.'
        }
      ],
      'searching': [
        {
          'text': 'Binary search requires the data to be:',
          'options': ['Unsorted', 'Sorted', 'Duplicated', 'Encrypted'],
          'correct': 'Sorted',
          'explanation': 'Binary search only works on sorted data as it relies on comparing middle elements.'
        }
      ]
    };
    
    final skillQuestions = questions[skillId] ?? questions['variables']!;
    final question = skillQuestions[random.nextInt(skillQuestions.length)];
    
    return {
      'id': 'cs_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generateArtQuestionBySkill(String skillId, int difficulty, int index, Random random) {
    final questions = <String, List<Map<String, dynamic>>>{
      'shapes': [
        {
          'text': 'Which shape has three sides?',
          'options': ['Circle', 'Square', 'Triangle', 'Rectangle'],
          'correct': 'Triangle',
          'explanation': 'A triangle is a polygon with three sides and three angles.'
        },
        {
          'text': 'What is the basic shape with no corners?',
          'options': ['Square', 'Triangle', 'Circle', 'Diamond'],
          'correct': 'Circle',
          'explanation': 'A circle is a round shape with no corners or edges.'
        }
      ],
      'primary_colors': [
        {
          'text': 'Which of these is a primary color?',
          'options': ['Green', 'Orange', 'Red', 'Purple'],
          'correct': 'Red',
          'explanation': 'Red is one of the three primary colors, along with blue and yellow.'
        },
        {
          'text': 'How many primary colors are there?',
          'options': ['2', '3', '4', '5'],
          'correct': '3',
          'explanation': 'There are three primary colors: red, blue, and yellow.'
        }
      ],
      'color_mixing': [
        {
          'text': 'What color do you get when you mix red and yellow?',
          'options': ['Purple', 'Green', 'Orange', 'Brown'],
          'correct': 'Orange',
          'explanation': 'Red and yellow mix to create orange, a secondary color.'
        }
      ]
    };

    final skillQuestions = questions[skillId] ?? questions['shapes']!;
    final question = skillQuestions[index % skillQuestions.length];
    
    return {
      'id': 'art_${skillId}_${index}',
      'question': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generateMusicQuestionBySkill(String skillId, int difficulty, int index, Random random) {
    final questions = <String, List<Map<String, dynamic>>>{
      'notes': [
        {
          'text': 'How many lines are there on a musical staff?',
          'options': ['4', '5', '6', '7'],
          'correct': '5',
          'explanation': 'A musical staff has five horizontal lines where notes are placed.'
        },
        {
          'text': 'What are the seven letter names used for musical notes?',
          'options': ['A-G', 'A-H', 'C-I', 'D-J'],
          'correct': 'A-G',
          'explanation': 'Musical notes use the letters A, B, C, D, E, F, and G.'
        }
      ],
      'rhythm': [
        {
          'text': 'What is the steady pulse in music called?',
          'options': ['Melody', 'Harmony', 'Beat', 'Pitch'],
          'correct': 'Beat',
          'explanation': 'The beat is the steady pulse that you can clap along to in music.'
        }
      ],
      'instruments': [
        {
          'text': 'Which instrument has black and white keys?',
          'options': ['Guitar', 'Drums', 'Piano', 'Violin'],
          'correct': 'Piano',
          'explanation': 'A piano has black and white keys that produce different pitches when pressed.'
        }
      ]
    };

    final skillQuestions = questions[skillId] ?? questions['notes']!;
    final question = skillQuestions[index % skillQuestions.length];
    
    return {
      'id': 'music_${skillId}_${index}',
      'question': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generatePhysicalEducationQuestionBySkill(String skillId, int difficulty, int index, Random random) {
    final questions = <String, List<Map<String, dynamic>>>{
      'exercises': [
        {
          'text': 'Which exercise helps strengthen your leg muscles?',
          'options': ['Push-ups', 'Squats', 'Sit-ups', 'Pull-ups'],
          'correct': 'Squats',
          'explanation': 'Squats are exercises that primarily work the muscles in your legs and glutes.'
        },
        {
          'text': 'How many minutes of exercise should children get each day?',
          'options': ['30 minutes', '60 minutes', '90 minutes', '120 minutes'],
          'correct': '60 minutes',
          'explanation': 'Children should get at least 60 minutes of physical activity each day.'
        }
      ],
      'sports_rules': [
        {
          'text': 'In basketball, how many players from each team are on the court at once?',
          'options': ['4', '5', '6', '7'],
          'correct': '5',
          'explanation': 'Each basketball team has 5 players on the court during play.'
        }
      ],
      'health': [
        {
          'text': 'What should you do before exercising?',
          'options': ['Eat a big meal', 'Warm up', 'Take a nap', 'Drink soda'],
          'correct': 'Warm up',
          'explanation': 'Warming up prepares your body for exercise and helps prevent injuries.'
        }
      ]
    };

    final skillQuestions = questions[skillId] ?? questions['exercises']!;
    final question = skillQuestions[index % skillQuestions.length];
    
    return {
      'id': 'pe_${skillId}_${index}',
      'question': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'explanation': question['explanation'],
    };
  }
}