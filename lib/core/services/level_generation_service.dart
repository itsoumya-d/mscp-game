import 'dart:math';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/models/question.dart';

/// Service for generating scalable level content across subjects
class LevelGenerationService {
  static final LevelGenerationService _instance = LevelGenerationService._internal();
  factory LevelGenerationService() => _instance;
  LevelGenerationService._internal();

  static const int TOTAL_LEVELS = 50000;
  static const int LEVELS_PER_SUBJECT = 10000;
  static const int UNITS_PER_SUBJECT = 20;
  static const int SKILLS_PER_UNIT = 25;
  static const int LESSONS_PER_SKILL = 20;

  final Random _random = Random();

  /// Core subjects for level generation
  final List<SubjectType> coreSubjects = [
    SubjectType.math,
    SubjectType.physics,
    SubjectType.chemistry,
    SubjectType.biology,
    SubjectType.computerScience,
  ];

  /// Generate a complete subject with all units, skills, and lessons
  Subject generateSubject(SubjectType subjectType) {
    final subjectData = _getSubjectData(subjectType);
    final units = <Unit>[];

    for (int unitIndex = 0; unitIndex < UNITS_PER_SUBJECT; unitIndex++) {
      units.add(_generateUnit(subjectType, unitIndex));
    }

    return Subject(
      id: subjectType.name,
      name: subjectData['name'],
      type: subjectType,
      description: subjectData['description'],
      iconUrl: subjectData['iconUrl'],
      units: units,
      totalSkills: UNITS_PER_SUBJECT * SKILLS_PER_UNIT,
      completedSkills: 0,
    );
  }

  /// Generate a unit with progressive difficulty
  Unit _generateUnit(SubjectType subjectType, int unitIndex) {
    final unitData = _getUnitData(subjectType, unitIndex);
    final skills = <Skill>[];

    for (int skillIndex = 0; skillIndex < SKILLS_PER_UNIT; skillIndex++) {
      skills.add(_generateSkill(subjectType, unitIndex, skillIndex));
    }

    return Unit(
      id: '${subjectType.name}_unit_$unitIndex',
      name: unitData['name'],
      description: unitData['description'],
      skills: skills,
      isUnlocked: unitIndex == 0, // First unit is unlocked by default
    );
  }

  /// Generate a skill with lessons
  Skill _generateSkill(SubjectType subjectType, int unitIndex, int skillIndex) {
    final skillData = _getSkillData(subjectType, unitIndex, skillIndex);
    final lessons = <Lesson>[];

    for (int lessonIndex = 0; lessonIndex < LESSONS_PER_SKILL; lessonIndex++) {
      lessons.add(_generateLesson(subjectType, unitIndex, skillIndex, lessonIndex));
    }

    return Skill(
      id: '${subjectType.name}_unit_${unitIndex}_skill_$skillIndex',
      name: skillData['name'],
      description: skillData['description'],
      crowns: 0,
      maxCrowns: 5,
      isUnlocked: unitIndex == 0 && skillIndex == 0, // First skill is unlocked
      lessons: lessons,
    );
  }

  /// Generate a lesson with questions
  Lesson _generateLesson(SubjectType subjectType, int unitIndex, int skillIndex, int lessonIndex) {
    final lessonData = _getLessonData(subjectType, unitIndex, skillIndex, lessonIndex);
    final questions = <Question>[];

    // Generate 5-10 questions per lesson
    final questionCount = 5 + _random.nextInt(6);
    for (int questionIndex = 0; questionIndex < questionCount; questionIndex++) {
      questions.add(_generateQuestion(subjectType, unitIndex, skillIndex, lessonIndex, questionIndex));
    }

    return Lesson(
      id: '${subjectType.name}_unit_${unitIndex}_skill_${skillIndex}_lesson_$lessonIndex',
      title: lessonData['title'],
      description: lessonData['description'],
      xpReward: _calculateXpReward(unitIndex, skillIndex, lessonIndex),
      isCompleted: false,
      questions: questions,
    );
  }

  /// Generate a question with progressive difficulty
  Question _generateQuestion(SubjectType subjectType, int unitIndex, int skillIndex, int lessonIndex, int questionIndex) {
    final difficulty = _calculateDifficulty(unitIndex, skillIndex, lessonIndex);
    final questionData = _generateQuestionData(subjectType, unitIndex, skillIndex, lessonIndex, questionIndex, difficulty);

    return Question(
      id: '${subjectType.name}_u${unitIndex}_s${skillIndex}_l${lessonIndex}_q$questionIndex',
      questionText: questionData['text'],
      type: questionData['type'],
      options: questionData['options'],
      correctAnswer: questionData['correctAnswer'],
      explanation: questionData['explanation'],
      difficulty: difficulty.round(),
      subject: subjectType,
    );
  }

  /// Calculate progressive difficulty (1-10 scale)
  double _calculateDifficulty(int unitIndex, int skillIndex, int lessonIndex) {
    // Progressive difficulty: starts at 1, increases to 10
    final totalProgress = (unitIndex * SKILLS_PER_UNIT * LESSONS_PER_SKILL) + 
                         (skillIndex * LESSONS_PER_SKILL) + 
                         lessonIndex;
    final maxProgress = UNITS_PER_SUBJECT * SKILLS_PER_UNIT * LESSONS_PER_SKILL;
    
    return 1.0 + (9.0 * totalProgress / maxProgress);
  }

  /// Calculate XP reward based on difficulty and position
  int _calculateXpReward(int unitIndex, int skillIndex, int lessonIndex) {
    final baseDifficulty = _calculateDifficulty(unitIndex, skillIndex, lessonIndex);
    return (10 + (baseDifficulty * 5)).round();
  }

  /// Get subject-specific data
  Map<String, dynamic> _getSubjectData(SubjectType subjectType) {
    switch (subjectType) {
      case SubjectType.math:
        return {
          'name': 'Mathematics',
          'description': 'Master mathematical concepts from basic arithmetic to advanced calculus',
          'iconUrl': 'assets/icons/math.svg',
        };
      case SubjectType.physics:
        return {
          'name': 'Physics',
          'description': 'Explore the fundamental laws governing the universe',
          'iconUrl': 'assets/icons/physics.svg',
        };
      case SubjectType.chemistry:
        return {
          'name': 'Chemistry',
          'description': 'Understand the composition and behavior of matter',
          'iconUrl': 'assets/icons/chemistry.svg',
        };
      case SubjectType.biology:
        return {
          'name': 'Biology',
          'description': 'Study living organisms and life processes',
          'iconUrl': 'assets/icons/biology.svg',
        };
      case SubjectType.computerScience:
        return {
          'name': 'Computer Science',
          'description': 'Learn programming, algorithms, and computational thinking',
          'iconUrl': 'assets/icons/computer_science.svg',
        };
      default:
        return {
          'name': 'Unknown Subject',
          'description': 'Subject description not available',
          'iconUrl': 'assets/icons/default.svg',
        };
    }
  }

  /// Get unit-specific data with progressive topics
  Map<String, dynamic> _getUnitData(SubjectType subjectType, int unitIndex) {
    final unitTopics = _getUnitTopics(subjectType);
    final topicIndex = unitIndex % unitTopics.length;
    
    return {
      'name': '${unitTopics[topicIndex]} ${unitIndex + 1}',
      'description': 'Master ${unitTopics[topicIndex].toLowerCase()} concepts and applications',
    };
  }

  /// Get skill-specific data
  Map<String, dynamic> _getSkillData(SubjectType subjectType, int unitIndex, int skillIndex) {
    final skillTypes = _getSkillTypes(subjectType);
    final typeIndex = skillIndex % skillTypes.length;
    
    return {
      'name': '${skillTypes[typeIndex]} ${skillIndex + 1}',
      'description': 'Practice ${skillTypes[typeIndex].toLowerCase()} problems and concepts',
    };
  }

  /// Get lesson-specific data
  Map<String, dynamic> _getLessonData(SubjectType subjectType, int unitIndex, int skillIndex, int lessonIndex) {
    final lessonTypes = ['Introduction', 'Practice', 'Application', 'Review', 'Challenge'];
    final typeIndex = lessonIndex % lessonTypes.length;
    
    return {
      'title': '${lessonTypes[typeIndex]} ${lessonIndex + 1}',
      'description': '${lessonTypes[typeIndex]} lesson focusing on core concepts',
    };
  }

  /// Generate question data based on subject and difficulty
  Map<String, dynamic> _generateQuestionData(SubjectType subjectType, int unitIndex, int skillIndex, int lessonIndex, int questionIndex, double difficulty) {
    switch (subjectType) {
      case SubjectType.math:
        return _generateMathQuestion(unitIndex, skillIndex, lessonIndex, questionIndex, difficulty);
      case SubjectType.physics:
        return _generatePhysicsQuestion(unitIndex, skillIndex, lessonIndex, questionIndex, difficulty);
      case SubjectType.chemistry:
        return _generateChemistryQuestion(unitIndex, skillIndex, lessonIndex, questionIndex, difficulty);
      case SubjectType.biology:
        return _generateBiologyQuestion(unitIndex, skillIndex, lessonIndex, questionIndex, difficulty);
      case SubjectType.computerScience:
        return _generateComputerScienceQuestion(unitIndex, skillIndex, lessonIndex, questionIndex, difficulty);
      default:
        return _generateGenericQuestion(unitIndex, skillIndex, lessonIndex, questionIndex, difficulty);
    }
  }

  /// Generate math-specific questions
  Map<String, dynamic> _generateMathQuestion(int unitIndex, int skillIndex, int lessonIndex, int questionIndex, double difficulty) {
    final operations = ['+', '-', '×', '÷'];
    final operation = operations[_random.nextInt(operations.length)];
    
    // Scale numbers based on difficulty
    final maxNumber = (10 * difficulty).round();
    final num1 = 1 + _random.nextInt(maxNumber);
    final num2 = 1 + _random.nextInt(maxNumber);
    
    int correctAnswer;
    String questionText;
    
    switch (operation) {
      case '+':
        correctAnswer = num1 + num2;
        questionText = 'What is $num1 + $num2?';
        break;
      case '-':
        correctAnswer = num1 - num2;
        questionText = 'What is $num1 - $num2?';
        break;
      case '×':
        correctAnswer = num1 * num2;
        questionText = 'What is $num1 × $num2?';
        break;
      case '÷':
        final dividend = num1 * num2; // Ensure clean division
        correctAnswer = num1;
        questionText = 'What is $dividend ÷ $num2?';
        break;
      default:
        correctAnswer = num1 + num2;
        questionText = 'What is $num1 + $num2?';
    }
    
    // Generate wrong options
    final options = <String>[];
    options.add(correctAnswer.toString());
    
    while (options.length < 4) {
      final wrongAnswer = correctAnswer + (_random.nextInt(20) - 10);
      if (wrongAnswer != correctAnswer && !options.contains(wrongAnswer.toString())) {
        options.add(wrongAnswer.toString());
      }
    }
    
    options.shuffle();
    
    return {
      'text': questionText,
      'type': QuestionType.multipleChoice,
      'options': options,
      'correctAnswer': correctAnswer.toString(),
      'explanation': 'The correct answer is $correctAnswer.',
      'tags': ['arithmetic', operation.toLowerCase()],
    };
  }

  /// Generate physics-specific questions
  Map<String, dynamic> _generatePhysicsQuestion(int unitIndex, int skillIndex, int lessonIndex, int questionIndex, double difficulty) {
    final concepts = ['Force', 'Energy', 'Motion', 'Waves', 'Electricity'];
    final concept = concepts[unitIndex % concepts.length];
    
    return {
      'text': 'What is the unit of $concept in the SI system?',
      'type': QuestionType.multipleChoice,
      'options': ['Newton', 'Joule', 'Meter', 'Second'],
      'correctAnswer': 'Newton',
      'explanation': 'The SI unit of force is Newton (N).',
      'tags': ['physics', concept.toLowerCase(), 'units'],
    };
  }

  /// Generate chemistry-specific questions
  Map<String, dynamic> _generateChemistryQuestion(int unitIndex, int skillIndex, int lessonIndex, int questionIndex, double difficulty) {
    final elements = ['Hydrogen', 'Helium', 'Lithium', 'Carbon', 'Oxygen'];
    final element = elements[_random.nextInt(elements.length)];
    
    return {
      'text': 'What is the chemical symbol for $element?',
      'type': QuestionType.multipleChoice,
      'options': ['H', 'He', 'Li', 'C'],
      'correctAnswer': 'H',
      'explanation': 'The chemical symbol for Hydrogen is H.',
      'tags': ['chemistry', 'elements', 'symbols'],
    };
  }

  /// Generate biology-specific questions
  Map<String, dynamic> _generateBiologyQuestion(int unitIndex, int skillIndex, int lessonIndex, int questionIndex, double difficulty) {
    final topics = ['Cell Structure', 'Genetics', 'Evolution', 'Ecology', 'Anatomy'];
    final topic = topics[unitIndex % topics.length];
    
    return {
      'text': 'Which organelle is known as the powerhouse of the cell?',
      'type': QuestionType.multipleChoice,
      'options': ['Nucleus', 'Mitochondria', 'Ribosome', 'Golgi Apparatus'],
      'correctAnswer': 'Mitochondria',
      'explanation': 'Mitochondria are known as the powerhouse of the cell because they produce ATP.',
      'tags': ['biology', 'cell-biology', 'organelles'],
    };
  }

  /// Generate computer science-specific questions
  Map<String, dynamic> _generateComputerScienceQuestion(int unitIndex, int skillIndex, int lessonIndex, int questionIndex, double difficulty) {
    final topics = ['Programming', 'Algorithms', 'Data Structures', 'Databases', 'Networks'];
    final topic = topics[unitIndex % topics.length];
    
    return {
      'text': 'What is the time complexity of binary search?',
      'type': QuestionType.multipleChoice,
      'options': ['O(1)', 'O(log n)', 'O(n)', 'O(n²)'],
      'correctAnswer': 'O(log n)',
      'explanation': 'Binary search has O(log n) time complexity because it halves the search space each iteration.',
      'tags': ['computer-science', 'algorithms', 'complexity'],
    };
  }

  /// Generate generic questions as fallback
  Map<String, dynamic> _generateGenericQuestion(int unitIndex, int skillIndex, int lessonIndex, int questionIndex, double difficulty) {
    return {
      'text': 'Sample question ${questionIndex + 1} for unit ${unitIndex + 1}',
      'type': QuestionType.multipleChoice,
      'options': ['Option A', 'Option B', 'Option C', 'Option D'],
      'correctAnswer': 'Option A',
      'explanation': 'This is a sample explanation.',
      'tags': ['general'],
    };
  }

  /// Get unit topics for each subject
  List<String> _getUnitTopics(SubjectType subjectType) {
    switch (subjectType) {
      case SubjectType.math:
        return ['Arithmetic', 'Algebra', 'Geometry', 'Trigonometry', 'Calculus', 'Statistics', 'Probability'];
      case SubjectType.physics:
        return ['Mechanics', 'Thermodynamics', 'Electromagnetism', 'Optics', 'Modern Physics'];
      case SubjectType.chemistry:
        return ['Atomic Structure', 'Chemical Bonding', 'Reactions', 'Organic Chemistry', 'Physical Chemistry'];
      case SubjectType.biology:
        return ['Cell Biology', 'Genetics', 'Evolution', 'Ecology', 'Human Biology'];
      case SubjectType.computerScience:
        return ['Programming Basics', 'Data Structures', 'Algorithms', 'Software Engineering', 'Computer Systems'];
      default:
        return ['Topic 1', 'Topic 2', 'Topic 3', 'Topic 4', 'Topic 5'];
    }
  }

  /// Get skill types for each subject
  List<String> _getSkillTypes(SubjectType subjectType) {
    switch (subjectType) {
      case SubjectType.math:
        return ['Basic Operations', 'Problem Solving', 'Word Problems', 'Equations', 'Graphing'];
      case SubjectType.physics:
        return ['Concepts', 'Calculations', 'Experiments', 'Applications', 'Analysis'];
      case SubjectType.chemistry:
        return ['Theory', 'Reactions', 'Calculations', 'Lab Skills', 'Applications'];
      case SubjectType.biology:
        return ['Identification', 'Processes', 'Systems', 'Classification', 'Analysis'];
      case SubjectType.computerScience:
        return ['Syntax', 'Logic', 'Implementation', 'Debugging', 'Optimization'];
      default:
        return ['Skill 1', 'Skill 2', 'Skill 3', 'Skill 4', 'Skill 5'];
    }
  }

  /// Get total number of generated levels for a subject
  int getTotalLevelsForSubject(SubjectType subjectType) {
    return UNITS_PER_SUBJECT * SKILLS_PER_UNIT * LESSONS_PER_SKILL;
  }

  /// Get total number of generated levels across all subjects
  int getTotalLevels() {
    return coreSubjects.length * LEVELS_PER_SUBJECT;
  }
}