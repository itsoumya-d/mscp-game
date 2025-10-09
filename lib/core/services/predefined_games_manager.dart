import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/educational_game.dart';
import '../models/question_pool.dart';
import '../models/question.dart';
import 'game_save_service.dart';
import 'predefined_games_service.dart';
import 'game_session_service.dart';
import 'skill_id_registry.dart';

/// Service to manage predefined educational games and integrate with existing game system
class PredefinedGamesManager {
  static PredefinedGamesManager? _instance;
  static PredefinedGamesManager getInstance() {
    _instance ??= PredefinedGamesManager._internal();
    return _instance!;
  }
  PredefinedGamesManager._internal();

  final PredefinedGamesService _predefinedGamesService = PredefinedGamesService();
  // AI content generation removed - using fallback questions only

  /// Convert EducationalGame to SevenQuestionGameSession for compatibility
  SevenQuestionGameSession convertToGameSession(EducationalGame game, {String? skillId}) {
    // Convert GameQuestion to Question for compatibility
    final questions = game.questions.map((gameQuestion) => Question(
      id: gameQuestion.id,
      type: gameQuestion.type,
      questionText: gameQuestion.questionText,
      options: gameQuestion.options,
      correctAnswer: gameQuestion.correctAnswer,
      explanation: gameQuestion.explanation,
      hint: gameQuestion.hint,
      difficulty: _mapDifficultyToInt(game.difficulty),
      subject: game.subject,
    )).toList();

    return SevenQuestionGameSession(
      id: game.id,
      subject: game.subject,
      level: game.level,
      skillId: skillId ?? game.skillId ?? 'general',  // Use provided skillId or game's skillId
      questions: questions,
      userAnswers: List.filled(7, ''),
      answerCorrectness: List.filled(7, false),
      currentQuestionIndex: 0,
      startTime: DateTime.now(),
      score: 0,
      isCompleted: false,
      endTime: null,
    );
  }

  /// Get predefined game for subject and level
  Future<SevenQuestionGameSession> getPredefinedGameSession({
    required SubjectType subject,
    required int level,
    String? skillId,
  }) async {
    try {
      // Use default skill ID if none provided
      final effectiveSkillId = skillId ?? SkillIdRegistry.getDefaultSkillId(subject);

      if (kDebugMode) {
        debugPrint('[PredefinedGamesManager] Getting game session for ${subject.name} - Skill: $effectiveSkillId - Level: $level');
      }

      // Try to get existing predefined game for this skill
      final games = await _predefinedGamesService.getGamesForSubject(subject);

      // Filter by skill ID and level
      final skillLevelGames = games.where((g) =>
        (g.skillId == effectiveSkillId || g.skillId == null) && g.level == level
      ).toList();

      if (skillLevelGames.isNotEmpty) {
        // Return random game from available skill/level games
        final randomGame = skillLevelGames[Random().nextInt(skillLevelGames.length)];
        if (kDebugMode) {
          debugPrint('[PredefinedGamesManager] Using existing game for ${subject.name} - $effectiveSkillId - Level $level');
        }
        return convertToGameSession(randomGame, skillId: effectiveSkillId);
      }

      // If no predefined game exists, create fallback game session
      if (kDebugMode) {
        debugPrint('[PredefinedGamesManager] No predefined game found, using fallback for ${subject.name} - $effectiveSkillId - Level $level');
      }

      return _createFallbackGameSession(subject, level, effectiveSkillId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PredefinedGamesManager] Error getting game session: $e');
      }
      // Fallback: create a basic game session with template questions
      return _createFallbackGameSession(subject, level, skillId);
    }
  }

  /// Create fallback game session with template questions
  SevenQuestionGameSession _createFallbackGameSession(
    SubjectType subject,
    int level,
    String? skillId
  ) {
    // Pass skillId to generate skill-specific questions
    final questions = _generateFallbackQuestions(subject, level, skillId);

    return SevenQuestionGameSession(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      subject: subject,
      level: level,
      skillId: skillId ?? 'fallback',
      questions: questions,
      userAnswers: List.filled(7, ''),
      answerCorrectness: List.filled(7, false),
      currentQuestionIndex: 0,
      startTime: DateTime.now(),
      score: 0,
      isCompleted: false,
      endTime: null,
    );
  }

  /// Generate 7 fallback questions for a subject and level
  List<Question> _generateFallbackQuestions(SubjectType subject, int level, String? skillId) {
    final questions = <Question>[];
    final questionTypes = QuestionType.values;

    for (int i = 0; i < 7; i++) {
      final type = questionTypes[i % questionTypes.length];
      questions.add(_createFallbackQuestion(subject, level, type, i, skillId));
    }

    return questions;
  }

  /// Create a single fallback question with difficulty filtering
  Question _createFallbackQuestion(SubjectType subject, int level, QuestionType type, int index, String? skillId) {
    // Pass skillId to get skill-specific templates
    final allTemplates = _getFallbackTemplates(subject, type, skillId);

    // Filter templates by difficulty level
    final suitableTemplates = allTemplates.where((template) {
      final templateDifficulty = template['difficulty'] ?? 5;
      // Allow templates within ±2 levels of the target level
      return (templateDifficulty >= level - 2) && (templateDifficulty <= level + 2);
    }).toList();

    // If no suitable templates, use all templates
    final templates = suitableTemplates.isNotEmpty ? suitableTemplates : allTemplates;

    final template = templates.isNotEmpty
        ? templates[Random().nextInt(templates.length)]
        : _getDefaultTemplate(type);

    return Question(
      id: 'fallback_${subject.name}_${skillId ?? "general"}_${level}_${type.name}_$index',
      type: type,
      questionText: template['question'] ?? 'Sample question',
      options: List<String>.from(template['options'] ?? []),
      correctAnswer: template['correct'] ?? '',
      explanation: template['explanation'] ?? 'This is a sample explanation.',
      hint: template['hint'] ?? 'Think carefully about the question.',
      difficulty: template['difficulty'] ?? level * 10,
      subject: subject,
    );
  }

  /// Get fallback question templates for subject and type
  /// NOW WITH SKILL-SPECIFIC SUPPORT FOR ALL SUBJECTS!
  List<Map<String, dynamic>> _getFallbackTemplates(SubjectType subject, QuestionType type, String? skillId) {
    // Use skill-specific templates if skillId is provided
    if (skillId != null) {
      switch (subject) {
        case SubjectType.math:
          return _getMathSkillSpecificTemplates(skillId, type);
        case SubjectType.physics:
          return _getPhysicsSkillSpecificTemplates(skillId, type);
        case SubjectType.chemistry:
          return _getChemistrySkillSpecificTemplates(skillId, type);
        case SubjectType.biology:
          return _getBiologySkillSpecificTemplates(skillId, type);
        default:
          break; // Fall through to generic templates
      }
    }

    // Fallback to generic subject templates
    switch (subject) {
      case SubjectType.math:
        return _getMathFallbackTemplates(type);
      case SubjectType.physics:
        return _getPhysicsFallbackTemplates(type);
      case SubjectType.chemistry:
        return _getChemistryFallbackTemplates(type);
      case SubjectType.biology:
        return _getBiologyFallbackTemplates(type);
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Get skill-specific templates for Math
  /// This is the KEY FIX for the "Division showing Addition" bug!
  List<Map<String, dynamic>> _getMathSkillSpecificTemplates(String skillId, QuestionType type) {
    switch (skillId) {
      case 'addition':
        return _getAdditionTemplates(type);
      case 'multiplication':
        return _getMultiplicationTemplates(type);
      case 'fractions':
        return _getFractionsTemplates(type);
      case 'variables':
        return _getAlgebraTemplates(type);
      case 'geometry':
        return _getGeometryTemplates(type);
      case 'measurement':
        return _getMeasurementTemplates(type);
      default:
        // Fallback to generic math templates
        return _getMathFallbackTemplates(type);
    }
  }

  /// Addition & Subtraction skill templates
  List<Map<String, dynamic>> _getAdditionTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          {
            'question': 'What is 5 + 3?',
            'options': ['6', '7', '8', '9'],
            'correct': '8',
            'explanation': '5 + 3 = 8. Count up from 5: 6, 7, 8.',
            'hint': 'Add the two numbers together.',
            'difficulty': 1
          },
          {
            'question': 'What is 12 - 4?',
            'options': ['6', '7', '8', '9'],
            'correct': '8',
            'explanation': '12 - 4 = 8. Count back from 12.',
            'hint': 'Subtract 4 from 12.',
            'difficulty': 1
          },
          {
            'question': 'What is 15 + 7?',
            'options': ['20', '21', '22', '23'],
            'correct': '22',
            'explanation': '15 + 7 = 22. Add 5 to get 20, then add 2 more.',
            'hint': 'Break it into 15 + 5 + 2.',
            'difficulty': 2
          },
          {
            'question': 'What is 23 - 8?',
            'options': ['13', '14', '15', '16'],
            'correct': '15',
            'explanation': '23 - 8 = 15. Subtract 3 to get 20, then subtract 5 more.',
            'hint': 'Break it into 23 - 3 - 5.',
            'difficulty': 2
          },
        ];
      case QuestionType.trueFalse:
        return [
          {
            'question': 'True or False: 8 + 7 = 15',
            'correct': 'True',
            'explanation': '8 + 7 = 15 is correct.',
            'hint': 'Add the two numbers.',
            'difficulty': 1
          },
          {
            'question': 'True or False: 10 - 3 = 8',
            'correct': 'False',
            'explanation': '10 - 3 = 7, not 8.',
            'hint': 'Count down from 10.',
            'difficulty': 1
          },
        ];
      case QuestionType.numericInput:
        return [
          {
            'question': 'Calculate: 6 + 9',
            'options': [],
            'correct': '15',
            'explanation': '6 + 9 = 15.',
            'hint': 'Add 6 and 9 together.',
            'difficulty': 1
          },
          {
            'question': 'Calculate: 20 - 7',
            'options': [],
            'correct': '13',
            'explanation': '20 - 7 = 13.',
            'hint': 'Subtract 7 from 20.',
            'difficulty': 1
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Multiplication & Division skill templates
  List<Map<String, dynamic>> _getMultiplicationTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          {
            'question': 'What is 6 × 7?',
            'options': ['40', '42', '44', '48'],
            'correct': '42',
            'explanation': '6 × 7 = 42. Think of 6 groups of 7.',
            'hint': 'Multiply 6 by 7.',
            'difficulty': 2
          },
          {
            'question': 'What is 24 ÷ 6?',
            'options': ['3', '4', '5', '6'],
            'correct': '4',
            'explanation': '24 ÷ 6 = 4. How many groups of 6 fit in 24?',
            'hint': 'Divide 24 by 6.',
            'difficulty': 2
          },
          {
            'question': 'What is 8 × 9?',
            'options': ['70', '72', '74', '76'],
            'correct': '72',
            'explanation': '8 × 9 = 72. Think of 8 groups of 9.',
            'hint': 'Multiply 8 by 9.',
            'difficulty': 3
          },
          {
            'question': 'What is 56 ÷ 8?',
            'options': ['6', '7', '8', '9'],
            'correct': '7',
            'explanation': '56 ÷ 8 = 7. How many groups of 8 fit in 56?',
            'hint': 'Divide 56 by 8.',
            'difficulty': 3
          },
        ];
      case QuestionType.trueFalse:
        return [
          {
            'question': 'True or False: 5 × 4 = 20',
            'correct': 'True',
            'explanation': '5 × 4 = 20 is correct.',
            'hint': 'Multiply 5 by 4.',
            'difficulty': 2
          },
          {
            'question': 'True or False: 18 ÷ 3 = 5',
            'correct': 'False',
            'explanation': '18 ÷ 3 = 6, not 5.',
            'hint': 'Divide 18 by 3.',
            'difficulty': 2
          },
        ];
      case QuestionType.numericInput:
        return [
          {
            'question': 'Calculate: 7 × 8',
            'options': [],
            'correct': '56',
            'explanation': '7 × 8 = 56.',
            'hint': 'Multiply 7 by 8.',
            'difficulty': 2
          },
          {
            'question': 'Calculate: 36 ÷ 4',
            'options': [],
            'correct': '9',
            'explanation': '36 ÷ 4 = 9.',
            'hint': 'Divide 36 by 4.',
            'difficulty': 2
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Fractions skill templates
  List<Map<String, dynamic>> _getFractionsTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          {
            'question': 'What is 1/2 + 1/4?',
            'options': ['1/4', '2/6', '3/4', '1/3'],
            'correct': '3/4',
            'explanation': '1/2 + 1/4 = 2/4 + 1/4 = 3/4.',
            'hint': 'Convert 1/2 to 2/4 first.',
            'difficulty': 3
          },
          {
            'question': 'Which fraction is equivalent to 0.5?',
            'options': ['1/4', '1/2', '3/4', '1/3'],
            'correct': '1/2',
            'explanation': '0.5 = 1/2. Half of 1 is 0.5.',
            'hint': 'Think about half.',
            'difficulty': 2
          },
        ];
      case QuestionType.trueFalse:
        return [
          {
            'question': 'True or False: 1/2 is greater than 1/4',
            'correct': 'True',
            'explanation': '1/2 (0.5) is greater than 1/4 (0.25).',
            'hint': 'Compare the decimal values.',
            'difficulty': 2
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Algebra (Variables) skill templates
  List<Map<String, dynamic>> _getAlgebraTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          {
            'question': 'If x = 5, what is 2x + 3?',
            'options': ['10', '11', '12', '13'],
            'correct': '13',
            'explanation': '2(5) + 3 = 10 + 3 = 13.',
            'hint': 'Replace x with 5, then calculate.',
            'difficulty': 4
          },
          {
            'question': 'Solve for x: x + 7 = 12',
            'options': ['3', '4', '5', '6'],
            'correct': '5',
            'explanation': 'x + 7 = 12, so x = 12 - 7 = 5.',
            'hint': 'Subtract 7 from both sides.',
            'difficulty': 4
          },
        ];
      case QuestionType.trueFalse:
        return [
          {
            'question': 'True or False: If x = 3, then 3x = 9',
            'correct': 'True',
            'explanation': '3 × 3 = 9, so 3x = 9 when x = 3.',
            'hint': 'Multiply 3 by x.',
            'difficulty': 3
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Geometry skill templates
  List<Map<String, dynamic>> _getGeometryTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          {
            'question': 'What is the area of a rectangle with length 5 and width 3?',
            'options': ['8', '12', '15', '18'],
            'correct': '15',
            'explanation': 'Area = length × width = 5 × 3 = 15.',
            'hint': 'Multiply length by width.',
            'difficulty': 3
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Measurement skill templates
  List<Map<String, dynamic>> _getMeasurementTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          {
            'question': 'How many centimeters are in 1 meter?',
            'options': ['10', '50', '100', '1000'],
            'correct': '100',
            'explanation': '1 meter = 100 centimeters.',
            'hint': 'Think about the metric system.',
            'difficulty': 2
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Get skill-specific templates for Physics
  List<Map<String, dynamic>> _getPhysicsSkillSpecificTemplates(String skillId, QuestionType type) {
    switch (skillId) {
      case 'newton':
        return _getNewtonianMotionTemplates(type);
      case 'energy':
        return _getWorkEnergyTemplates(type);
      case 'optics':
        return _getOpticsTemplates(type);
      default:
        return _getPhysicsFallbackTemplates(type);
    }
  }

  /// Newtonian Motion skill templates
  List<Map<String, dynamic>> _getNewtonianMotionTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          {
            'question': 'What is Newton\'s First Law of Motion?',
            'options': ['Objects at rest stay at rest', 'F = ma', 'Action-reaction', 'E = mc²'],
            'correct': 'Objects at rest stay at rest',
            'explanation': 'Newton\'s First Law states that objects at rest stay at rest unless acted upon by a force.',
            'hint': 'Think about inertia.',
            'difficulty': 2
          },
          {
            'question': 'If you push a box with 10N of force and it has a mass of 2kg, what is its acceleration?',
            'options': ['5 m/s²', '10 m/s²', '20 m/s²', '2 m/s²'],
            'correct': '5 m/s²',
            'explanation': 'Using F = ma, acceleration = F/m = 10N / 2kg = 5 m/s².',
            'hint': 'Use the formula F = ma.',
            'difficulty': 3
          },
        ];
      case QuestionType.trueFalse:
        return [
          {
            'question': 'True or False: Force equals mass times acceleration (F = ma)',
            'correct': 'True',
            'explanation': 'This is Newton\'s Second Law of Motion.',
            'hint': 'Think about Newton\'s Second Law.',
            'difficulty': 2
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Work & Energy skill templates
  List<Map<String, dynamic>> _getWorkEnergyTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          {
            'question': 'What type of energy does a moving car have?',
            'options': ['Potential energy', 'Kinetic energy', 'Chemical energy', 'Nuclear energy'],
            'correct': 'Kinetic energy',
            'explanation': 'Kinetic energy is the energy of motion.',
            'hint': 'Think about energy of movement.',
            'difficulty': 2
          },
          {
            'question': 'A ball at the top of a hill has what type of energy?',
            'options': ['Kinetic energy', 'Potential energy', 'Thermal energy', 'Sound energy'],
            'correct': 'Potential energy',
            'explanation': 'Potential energy is stored energy due to position.',
            'hint': 'Think about stored energy.',
            'difficulty': 2
          },
        ];
      case QuestionType.trueFalse:
        return [
          {
            'question': 'True or False: Energy can be created or destroyed',
            'correct': 'False',
            'explanation': 'Energy cannot be created or destroyed, only transformed (Law of Conservation of Energy).',
            'hint': 'Think about conservation laws.',
            'difficulty': 3
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Optics skill templates
  List<Map<String, dynamic>> _getOpticsTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          {
            'question': 'What happens when light bounces off a mirror?',
            'options': ['Refraction', 'Reflection', 'Absorption', 'Diffraction'],
            'correct': 'Reflection',
            'explanation': 'Reflection is when light bounces off a surface.',
            'hint': 'Think about mirrors.',
            'difficulty': 2
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Get skill-specific templates for Chemistry
  List<Map<String, dynamic>> _getChemistrySkillSpecificTemplates(String skillId, QuestionType type) {
    switch (skillId) {
      case 'periodic':
        return _getPeriodicTableTemplates(type);
      case 'bonding':
        return _getChemicalBondingTemplates(type);
      case 'stoich':
        return _getStoichiometryTemplates(type);
      default:
        return _getChemistryFallbackTemplates(type);
    }
  }

  /// Periodic Table skill templates
  List<Map<String, dynamic>> _getPeriodicTableTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          {
            'question': 'What is the chemical symbol for Oxygen?',
            'options': ['O', 'Ox', 'O2', 'Og'],
            'correct': 'O',
            'explanation': 'Oxygen\'s chemical symbol is O.',
            'hint': 'It\'s a single letter.',
            'difficulty': 1
          },
          {
            'question': 'How many elements are in the first row of the periodic table?',
            'options': ['1', '2', '8', '18'],
            'correct': '2',
            'explanation': 'The first row contains Hydrogen (H) and Helium (He).',
            'hint': 'Count H and He.',
            'difficulty': 2
          },
        ];
      case QuestionType.trueFalse:
        return [
          {
            'question': 'True or False: Gold\'s chemical symbol is Au',
            'correct': 'True',
            'explanation': 'Au comes from the Latin word "aurum" meaning gold.',
            'hint': 'Think about precious metals.',
            'difficulty': 2
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Chemical Bonding skill templates
  List<Map<String, dynamic>> _getChemicalBondingTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          {
            'question': 'What type of bond forms when atoms share electrons?',
            'options': ['Ionic bond', 'Covalent bond', 'Metallic bond', 'Hydrogen bond'],
            'correct': 'Covalent bond',
            'explanation': 'Covalent bonds form when atoms share electrons.',
            'hint': 'Think about sharing.',
            'difficulty': 2
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Stoichiometry skill templates
  List<Map<String, dynamic>> _getStoichiometryTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          {
            'question': 'How many atoms are in one mole of a substance?',
            'options': ['6.02 × 10²³', '1000', '100', '1 million'],
            'correct': '6.02 × 10²³',
            'explanation': 'Avogadro\'s number is 6.02 × 10²³ atoms per mole.',
            'hint': 'Think about Avogadro\'s number.',
            'difficulty': 3
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Get skill-specific templates for Biology
  List<Map<String, dynamic>> _getBiologySkillSpecificTemplates(String skillId, QuestionType type) {
    switch (skillId) {
      case 'cell_parts':
        return _getCellPartsTemplates(type);
      case 'genetics':
        return _getGeneticsTemplates(type);
      case 'food_chain':
        return _getFoodChainTemplates(type);
      default:
        return _getBiologyFallbackTemplates(type);
    }
  }

  /// Cell Parts skill templates
  List<Map<String, dynamic>> _getCellPartsTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          {
            'question': 'What is the powerhouse of the cell?',
            'options': ['Nucleus', 'Mitochondria', 'Ribosome', 'Cell membrane'],
            'correct': 'Mitochondria',
            'explanation': 'Mitochondria produce energy (ATP) for the cell.',
            'hint': 'Think about energy production.',
            'difficulty': 2
          },
          {
            'question': 'What part of the cell contains genetic material (DNA)?',
            'options': ['Cytoplasm', 'Nucleus', 'Cell wall', 'Vacuole'],
            'correct': 'Nucleus',
            'explanation': 'The nucleus contains the cell\'s DNA.',
            'hint': 'Think about the control center.',
            'difficulty': 2
          },
        ];
      case QuestionType.trueFalse:
        return [
          {
            'question': 'True or False: Plant cells have cell walls but animal cells do not',
            'correct': 'True',
            'explanation': 'Plant cells have rigid cell walls made of cellulose, while animal cells only have cell membranes.',
            'hint': 'Think about plant structure.',
            'difficulty': 2
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Genetics skill templates
  List<Map<String, dynamic>> _getGeneticsTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          {
            'question': 'What does DNA stand for?',
            'options': ['Deoxyribonucleic Acid', 'Deoxyribose Nucleic Acid', 'Dynamic Nuclear Acid', 'Double Nucleic Acid'],
            'correct': 'Deoxyribonucleic Acid',
            'explanation': 'DNA stands for Deoxyribonucleic Acid.',
            'hint': 'Think about the full name.',
            'difficulty': 2
          },
          {
            'question': 'How many chromosomes do humans have?',
            'options': ['23', '46', '48', '92'],
            'correct': '46',
            'explanation': 'Humans have 46 chromosomes (23 pairs).',
            'hint': 'Think about pairs.',
            'difficulty': 2
          },
        ];
      case QuestionType.trueFalse:
        return [
          {
            'question': 'True or False: Genes are made of DNA',
            'correct': 'True',
            'explanation': 'Genes are segments of DNA that code for traits.',
            'hint': 'Think about genetic material.',
            'difficulty': 2
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Food Chain skill templates
  List<Map<String, dynamic>> _getFoodChainTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          {
            'question': 'What are organisms that make their own food called?',
            'options': ['Consumers', 'Producers', 'Decomposers', 'Predators'],
            'correct': 'Producers',
            'explanation': 'Producers (like plants) make their own food through photosynthesis.',
            'hint': 'Think about plants.',
            'difficulty': 2
          },
          {
            'question': 'What do we call animals that eat only plants?',
            'options': ['Carnivores', 'Herbivores', 'Omnivores', 'Decomposers'],
            'correct': 'Herbivores',
            'explanation': 'Herbivores are animals that eat only plants.',
            'hint': 'Think about plant-eaters.',
            'difficulty': 2
          },
        ];
      case QuestionType.trueFalse:
        return [
          {
            'question': 'True or False: Decomposers break down dead organisms',
            'correct': 'True',
            'explanation': 'Decomposers (like fungi and bacteria) break down dead matter and return nutrients to the soil.',
            'hint': 'Think about recycling in nature.',
            'difficulty': 2
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Math fallback templates with difficulty scaling
  List<Map<String, dynamic>> _getMathFallbackTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          // Easy (Levels 1-3)
          {
            'question': 'What is 2 + 2?',
            'options': ['3', '4', '5', '6'],
            'correct': '4',
            'explanation': '2 + 2 equals 4. This is basic addition.',
            'hint': 'Add the two numbers together.',
            'difficulty': 1
          },
          {
            'question': 'What is 10 - 3?',
            'options': ['5', '6', '7', '8'],
            'correct': '7',
            'explanation': '10 - 3 equals 7. Count backwards from 10.',
            'hint': 'Subtract 3 from 10.',
            'difficulty': 1
          },
          {
            'question': 'What is 3 × 4?',
            'options': ['7', '10', '12', '15'],
            'correct': '12',
            'explanation': '3 × 4 equals 12. Think of 3 groups of 4.',
            'hint': 'Multiply 3 by 4.',
            'difficulty': 2
          },
          {
            'question': 'What is 15 ÷ 3?',
            'options': ['3', '4', '5', '6'],
            'correct': '5',
            'explanation': '15 ÷ 3 equals 5. How many groups of 3 fit in 15?',
            'hint': 'Divide 15 by 3.',
            'difficulty': 2
          },
          // Medium (Levels 4-7)
          {
            'question': 'What is 25% of 80?',
            'options': ['15', '20', '25', '30'],
            'correct': '20',
            'explanation': '25% of 80 is 20. Calculate 80 × 0.25.',
            'hint': '25% is the same as 1/4.',
            'difficulty': 5
          },
          {
            'question': 'Solve for x: 2x + 5 = 13',
            'options': ['2', '3', '4', '5'],
            'correct': '4',
            'explanation': 'x = 4. Subtract 5 from both sides: 2x = 8, then divide by 2.',
            'hint': 'Isolate x by performing inverse operations.',
            'difficulty': 5
          },
          {
            'question': 'What is the square root of 144?',
            'options': ['10', '11', '12', '13'],
            'correct': '12',
            'explanation': '√144 = 12 because 12 × 12 = 144.',
            'hint': 'What number multiplied by itself equals 144?',
            'difficulty': 6
          },
          {
            'question': 'What is 3² + 4²?',
            'options': ['7', '12', '25', '49'],
            'correct': '25',
            'explanation': '3² + 4² = 9 + 16 = 25. This is the Pythagorean theorem.',
            'hint': 'Calculate each square first, then add.',
            'difficulty': 6
          },
          // Hard (Levels 8-10)
          {
            'question': 'Solve: (x + 3)(x - 2) = 0',
            'options': ['x = -3 or x = 2', 'x = 3 or x = -2', 'x = -3 or x = -2', 'x = 3 or x = 2'],
            'correct': 'x = -3 or x = 2',
            'explanation': 'Using the zero product property: x + 3 = 0 gives x = -3, and x - 2 = 0 gives x = 2.',
            'hint': 'Set each factor equal to zero.',
            'difficulty': 8
          },
          {
            'question': 'What is the derivative of x³?',
            'options': ['x²', '2x²', '3x²', '3x'],
            'correct': '3x²',
            'explanation': 'Using the power rule: d/dx(x³) = 3x².',
            'hint': 'Apply the power rule: multiply by the exponent and reduce the exponent by 1.',
            'difficulty': 9
          },
          {
            'question': 'What is the integral of 2x?',
            'options': ['x', 'x²', 'x² + C', '2x² + C'],
            'correct': 'x² + C',
            'explanation': '∫2x dx = x² + C. The antiderivative of 2x is x².',
            'hint': 'Find the antiderivative and add the constant of integration.',
            'difficulty': 10
          },
        ];
      case QuestionType.numericInput:
        return [
          // Easy
          {
            'question': 'Calculate: 5 × 3',
            'options': [],
            'correct': '15',
            'explanation': '5 multiplied by 3 equals 15.',
            'hint': 'Multiply the two numbers.',
            'difficulty': 1
          },
          {
            'question': 'Calculate: 20 ÷ 4',
            'options': [],
            'correct': '5',
            'explanation': '20 divided by 4 equals 5.',
            'hint': 'How many groups of 4 fit in 20?',
            'difficulty': 2
          },
          {
            'question': 'Calculate: 7 + 8',
            'options': [],
            'correct': '15',
            'explanation': '7 + 8 equals 15.',
            'hint': 'Add the two numbers.',
            'difficulty': 1
          },
          // Medium
          {
            'question': 'Calculate: 12² (12 squared)',
            'options': [],
            'correct': '144',
            'explanation': '12² = 12 × 12 = 144.',
            'hint': 'Multiply 12 by itself.',
            'difficulty': 5
          },
          {
            'question': 'Calculate: √81',
            'options': [],
            'correct': '9',
            'explanation': '√81 = 9 because 9 × 9 = 81.',
            'hint': 'What number multiplied by itself equals 81?',
            'difficulty': 5
          },
          {
            'question': 'Solve for x: 3x = 21',
            'options': [],
            'correct': '7',
            'explanation': 'x = 7. Divide both sides by 3.',
            'hint': 'Divide 21 by 3.',
            'difficulty': 4
          },
          // Hard
          {
            'question': 'Calculate: 2³ + 3³',
            'options': [],
            'correct': '35',
            'explanation': '2³ + 3³ = 8 + 27 = 35.',
            'hint': 'Calculate each cube first, then add.',
            'difficulty': 7
          },
          {
            'question': 'Solve for x: x² = 49',
            'options': [],
            'correct': '7',
            'explanation': 'x = ±7, but we accept 7 as the positive solution.',
            'hint': 'Take the square root of both sides.',
            'difficulty': 8
          },
          {
            'question': 'Calculate: log₁₀(1000)',
            'options': [],
            'correct': '3',
            'explanation': 'log₁₀(1000) = 3 because 10³ = 1000.',
            'hint': '10 to what power equals 1000?',
            'difficulty': 9
          },
        ];
      case QuestionType.trueFalse:
        return [
          {
            'question': 'True or False: 5 + 5 = 10',
            'options': ['True', 'False'],
            'correct': 'True',
            'explanation': '5 + 5 does equal 10.',
            'hint': 'Add the numbers.',
            'difficulty': 1
          },
          {
            'question': 'True or False: A square has 5 sides',
            'options': ['True', 'False'],
            'correct': 'False',
            'explanation': 'A square has 4 sides, not 5.',
            'hint': 'Count the sides of a square.',
            'difficulty': 2
          },
          {
            'question': 'True or False: π (pi) is approximately 3.14',
            'options': ['True', 'False'],
            'correct': 'True',
            'explanation': 'π is approximately 3.14159...',
            'hint': 'Think about the value of pi.',
            'difficulty': 4
          },
          {
            'question': 'True or False: The sum of angles in a triangle is 180°',
            'options': ['True', 'False'],
            'correct': 'True',
            'explanation': 'The sum of all angles in any triangle is always 180°.',
            'hint': 'This is a fundamental property of triangles.',
            'difficulty': 5
          },
        ];
      case QuestionType.fillInTheBlank:
        return [
          {
            'question': 'Fill in the blank: 2 + 2 = ____',
            'options': [],
            'correct': '4',
            'explanation': '2 + 2 equals 4.',
            'hint': 'Add the two numbers.',
            'difficulty': 1
          },
          {
            'question': 'Fill in the blank: 10 × 10 = ____',
            'options': [],
            'correct': '100',
            'explanation': '10 × 10 equals 100.',
            'hint': 'Multiply 10 by itself.',
            'difficulty': 2
          },
          {
            'question': 'Fill in the blank: The formula for the area of a circle is A = πr____',
            'options': [],
            'correct': '²',
            'explanation': 'The formula is A = πr². The radius is squared.',
            'hint': 'The radius is raised to a power.',
            'difficulty': 6
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Physics fallback templates with difficulty scaling
  List<Map<String, dynamic>> _getPhysicsFallbackTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          // Easy (Levels 1-3)
          {
            'question': 'What is the unit of force?',
            'options': ['Newton', 'Joule', 'Watt', 'Pascal'],
            'correct': 'Newton',
            'explanation': 'The Newton (N) is the SI unit of force, named after Isaac Newton.',
            'hint': 'Think about Newton\'s laws of motion.',
            'difficulty': 1
          },
          {
            'question': 'What is the unit of energy?',
            'options': ['Newton', 'Joule', 'Watt', 'Meter'],
            'correct': 'Joule',
            'explanation': 'The Joule (J) is the SI unit of energy.',
            'hint': 'Energy is measured in this unit.',
            'difficulty': 2
          },
          {
            'question': 'What is the speed of light in vacuum?',
            'options': ['300,000 km/s', '3,000 km/s', '30,000 km/s', '3,000,000 km/s'],
            'correct': '300,000 km/s',
            'explanation': 'Light travels at approximately 300,000 km/s (or 3×10⁸ m/s) in vacuum.',
            'hint': 'It\'s a very large number.',
            'difficulty': 3
          },
          // Medium (Levels 4-7)
          {
            'question': 'What is Newton\'s Second Law of Motion?',
            'options': ['F = ma', 'E = mc²', 'V = IR', 'P = IV'],
            'correct': 'F = ma',
            'explanation': 'Newton\'s Second Law states that Force equals mass times acceleration (F = ma).',
            'hint': 'Force, mass, and acceleration are related.',
            'difficulty': 5
          },
          {
            'question': 'What type of energy does a moving object have?',
            'options': ['Kinetic', 'Potential', 'Thermal', 'Chemical'],
            'correct': 'Kinetic',
            'explanation': 'Kinetic energy is the energy of motion.',
            'hint': 'Think about energy in motion.',
            'difficulty': 4
          },
          {
            'question': 'What is the formula for kinetic energy?',
            'options': ['KE = ½mv²', 'KE = mgh', 'KE = mc²', 'KE = Fd'],
            'correct': 'KE = ½mv²',
            'explanation': 'Kinetic energy equals half the mass times velocity squared.',
            'hint': 'It involves mass and velocity.',
            'difficulty': 6
          },
          {
            'question': 'What is the acceleration due to gravity on Earth?',
            'options': ['9.8 m/s²', '10 m/s²', '8.9 m/s²', '11 m/s²'],
            'correct': '9.8 m/s²',
            'explanation': 'The acceleration due to gravity on Earth is approximately 9.8 m/s².',
            'hint': 'It\'s close to 10 m/s².',
            'difficulty': 5
          },
          // Hard (Levels 8-10)
          {
            'question': 'What is Einstein\'s mass-energy equivalence formula?',
            'options': ['E = mc²', 'E = hf', 'E = ½mv²', 'E = mgh'],
            'correct': 'E = mc²',
            'explanation': 'Einstein\'s famous equation E = mc² shows that energy and mass are equivalent.',
            'hint': 'This is Einstein\'s most famous equation.',
            'difficulty': 8
          },
          {
            'question': 'What is the first law of thermodynamics?',
            'options': ['Energy cannot be created or destroyed', 'Entropy always increases', 'F = ma', 'V = IR'],
            'correct': 'Energy cannot be created or destroyed',
            'explanation': 'The first law of thermodynamics states that energy is conserved.',
            'hint': 'It\'s about conservation of energy.',
            'difficulty': 9
          },
          {
            'question': 'What is Planck\'s constant approximately?',
            'options': ['6.626 × 10⁻³⁴ J·s', '3 × 10⁸ m/s', '9.8 m/s²', '1.6 × 10⁻¹⁹ C'],
            'correct': '6.626 × 10⁻³⁴ J·s',
            'explanation': 'Planck\'s constant (h) is approximately 6.626 × 10⁻³⁴ J·s.',
            'hint': 'It\'s a very small number used in quantum mechanics.',
            'difficulty': 10
          },
        ];
      case QuestionType.trueFalse:
        return [
          {
            'question': 'Light travels faster than sound.',
            'options': ['True', 'False'],
            'correct': 'True',
            'explanation': 'Light travels at approximately 300,000,000 m/s while sound travels at about 343 m/s.',
            'hint': 'Consider the speeds of light and sound.',
            'difficulty': 1
          },
          {
            'question': 'True or False: Gravity is a force that pulls objects together.',
            'options': ['True', 'False'],
            'correct': 'True',
            'explanation': 'Gravity is an attractive force between objects with mass.',
            'hint': 'Think about what gravity does.',
            'difficulty': 2
          },
          {
            'question': 'True or False: Energy can be created from nothing.',
            'options': ['True', 'False'],
            'correct': 'False',
            'explanation': 'Energy cannot be created or destroyed, only transformed (conservation of energy).',
            'hint': 'Think about the law of conservation of energy.',
            'difficulty': 5
          },
          {
            'question': 'True or False: An object in motion stays in motion unless acted upon by a force.',
            'options': ['True', 'False'],
            'correct': 'True',
            'explanation': 'This is Newton\'s First Law of Motion (law of inertia).',
            'hint': 'This is one of Newton\'s laws.',
            'difficulty': 4
          },
        ];
      case QuestionType.numericInput:
        return [
          {
            'question': 'Calculate the force: F = ma, where m = 5 kg and a = 2 m/s²',
            'options': [],
            'correct': '10',
            'explanation': 'F = 5 × 2 = 10 N (Newtons).',
            'hint': 'Multiply mass by acceleration.',
            'difficulty': 5
          },
          {
            'question': 'Calculate kinetic energy: KE = ½mv², where m = 2 kg and v = 3 m/s',
            'options': [],
            'correct': '9',
            'explanation': 'KE = ½ × 2 × 3² = ½ × 2 × 9 = 9 J (Joules).',
            'hint': 'Square the velocity first, then multiply.',
            'difficulty': 6
          },
          {
            'question': 'How long does it take for light to travel 1 km? (Answer in microseconds, speed of light = 300,000 km/s)',
            'options': [],
            'correct': '3.33',
            'explanation': 'Time = distance/speed = 1/300,000 s = 3.33 microseconds.',
            'hint': 'Use the formula: time = distance / speed.',
            'difficulty': 8
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Chemistry fallback templates with difficulty scaling
  List<Map<String, dynamic>> _getChemistryFallbackTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          // Easy (Levels 1-3)
          {
            'question': 'What is the chemical symbol for water?',
            'options': ['H2O', 'CO2', 'NaCl', 'O2'],
            'correct': 'H2O',
            'explanation': 'Water is composed of two hydrogen atoms and one oxygen atom (H₂O).',
            'hint': 'Water contains hydrogen and oxygen.',
            'difficulty': 1
          },
          {
            'question': 'What is the chemical symbol for oxygen gas?',
            'options': ['O', 'O2', 'O3', 'H2O'],
            'correct': 'O2',
            'explanation': 'Oxygen gas exists as diatomic molecules (O₂).',
            'hint': 'Oxygen gas has two oxygen atoms.',
            'difficulty': 2
          },
          {
            'question': 'What is the chemical symbol for table salt?',
            'options': ['NaCl', 'KCl', 'CaCl2', 'MgCl2'],
            'correct': 'NaCl',
            'explanation': 'Table salt is sodium chloride (NaCl).',
            'hint': 'It contains sodium and chlorine.',
            'difficulty': 2
          },
          {
            'question': 'What is the pH of pure water?',
            'options': ['5', '7', '9', '11'],
            'correct': '7',
            'explanation': 'Pure water has a pH of 7, which is neutral.',
            'hint': 'Water is neither acidic nor basic.',
            'difficulty': 3
          },
          // Medium (Levels 4-7)
          {
            'question': 'What is Avogadro\'s number?',
            'options': ['6.022 × 10²³', '3.14 × 10⁸', '9.8 × 10²', '1.6 × 10⁻¹⁹'],
            'correct': '6.022 × 10²³',
            'explanation': 'Avogadro\'s number is 6.022 × 10²³, the number of particles in one mole.',
            'hint': 'It\'s used to count atoms and molecules.',
            'difficulty': 5
          },
          {
            'question': 'What type of bond forms when electrons are shared?',
            'options': ['Covalent', 'Ionic', 'Metallic', 'Hydrogen'],
            'correct': 'Covalent',
            'explanation': 'Covalent bonds form when atoms share electrons.',
            'hint': 'Think about sharing electrons.',
            'difficulty': 4
          },
          {
            'question': 'What is the molecular formula for glucose?',
            'options': ['C6H12O6', 'C12H22O11', 'CH4', 'CO2'],
            'correct': 'C6H12O6',
            'explanation': 'Glucose has the molecular formula C₆H₁₂O₆.',
            'hint': 'It has 6 carbon atoms.',
            'difficulty': 6
          },
          {
            'question': 'What is the process of a solid turning directly into a gas?',
            'options': ['Sublimation', 'Evaporation', 'Condensation', 'Melting'],
            'correct': 'Sublimation',
            'explanation': 'Sublimation is the phase transition from solid directly to gas.',
            'hint': 'It skips the liquid phase.',
            'difficulty': 5
          },
          // Hard (Levels 8-10)
          {
            'question': 'What is the electron configuration of carbon?',
            'options': ['1s² 2s² 2p²', '1s² 2s² 2p⁶', '1s² 2s¹', '1s² 2p⁴'],
            'correct': '1s² 2s² 2p²',
            'explanation': 'Carbon has 6 electrons: 1s² 2s² 2p².',
            'hint': 'Carbon has 6 electrons total.',
            'difficulty': 8
          },
          {
            'question': 'What is the oxidation state of sulfur in H₂SO₄?',
            'options': ['+6', '+4', '+2', '-2'],
            'correct': '+6',
            'explanation': 'In sulfuric acid (H₂SO₄), sulfur has an oxidation state of +6.',
            'hint': 'Hydrogen is +1, oxygen is -2.',
            'difficulty': 9
          },
          {
            'question': 'What is the Gibbs free energy equation?',
            'options': ['ΔG = ΔH - TΔS', 'ΔG = ΔH + TΔS', 'ΔG = RT ln K', 'ΔG = -nFE'],
            'correct': 'ΔG = ΔH - TΔS',
            'explanation': 'The Gibbs free energy equation is ΔG = ΔH - TΔS.',
            'hint': 'It relates enthalpy, temperature, and entropy.',
            'difficulty': 10
          },
        ];
      case QuestionType.trueFalse:
        return [
          {
            'question': 'True or False: Water is a compound.',
            'options': ['True', 'False'],
            'correct': 'True',
            'explanation': 'Water (H₂O) is a compound made of hydrogen and oxygen.',
            'hint': 'Compounds are made of multiple elements.',
            'difficulty': 1
          },
          {
            'question': 'True or False: Acids have a pH greater than 7.',
            'options': ['True', 'False'],
            'correct': 'False',
            'explanation': 'Acids have a pH less than 7. Bases have a pH greater than 7.',
            'hint': 'Think about the pH scale.',
            'difficulty': 3
          },
          {
            'question': 'True or False: Noble gases are highly reactive.',
            'options': ['True', 'False'],
            'correct': 'False',
            'explanation': 'Noble gases are very unreactive due to their full outer electron shells.',
            'hint': 'Noble gases are known for being stable.',
            'difficulty': 5
          },
        ];
      case QuestionType.numericInput:
        return [
          {
            'question': 'How many protons does carbon have?',
            'options': [],
            'correct': '6',
            'explanation': 'Carbon has 6 protons (atomic number 6).',
            'hint': 'Check the periodic table.',
            'difficulty': 2
          },
          {
            'question': 'What is the molar mass of water (H₂O) in g/mol? (H=1, O=16)',
            'options': [],
            'correct': '18',
            'explanation': 'H₂O = 2(1) + 16 = 18 g/mol.',
            'hint': 'Add the masses of 2 hydrogen and 1 oxygen.',
            'difficulty': 5
          },
          {
            'question': 'How many electrons can the second energy level hold?',
            'options': [],
            'correct': '8',
            'explanation': 'The second energy level can hold up to 8 electrons.',
            'hint': 'It\'s 2n², where n=2.',
            'difficulty': 6
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Biology fallback templates with difficulty scaling
  List<Map<String, dynamic>> _getBiologyFallbackTemplates(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return [
          // Easy (Levels 1-3)
          {
            'question': 'What is the powerhouse of the cell?',
            'options': ['Nucleus', 'Mitochondria', 'Ribosome', 'Golgi apparatus'],
            'correct': 'Mitochondria',
            'explanation': 'Mitochondria produce ATP, the energy currency of the cell.',
            'hint': 'This organelle produces energy for the cell.',
            'difficulty': 1
          },
          {
            'question': 'What is the control center of the cell?',
            'options': ['Nucleus', 'Mitochondria', 'Ribosome', 'Chloroplast'],
            'correct': 'Nucleus',
            'explanation': 'The nucleus contains DNA and controls cell activities.',
            'hint': 'It contains the cell\'s genetic material.',
            'difficulty': 1
          },
          {
            'question': 'What process do plants use to make food?',
            'options': ['Photosynthesis', 'Respiration', 'Digestion', 'Fermentation'],
            'correct': 'Photosynthesis',
            'explanation': 'Photosynthesis converts light energy into chemical energy (glucose).',
            'hint': 'Plants use sunlight for this process.',
            'difficulty': 2
          },
          {
            'question': 'What is the basic unit of life?',
            'options': ['Cell', 'Atom', 'Molecule', 'Organ'],
            'correct': 'Cell',
            'explanation': 'The cell is the smallest unit of life.',
            'hint': 'All living things are made of these.',
            'difficulty': 2
          },
          // Medium (Levels 4-7)
          {
            'question': 'What is the molecule that carries genetic information?',
            'options': ['DNA', 'RNA', 'Protein', 'Lipid'],
            'correct': 'DNA',
            'explanation': 'DNA (deoxyribonucleic acid) carries genetic information.',
            'hint': 'It\'s a double helix structure.',
            'difficulty': 4
          },
          {
            'question': 'What is the process of cell division called?',
            'options': ['Mitosis', 'Meiosis', 'Photosynthesis', 'Respiration'],
            'correct': 'Mitosis',
            'explanation': 'Mitosis is the process of cell division for growth and repair.',
            'hint': 'It produces two identical daughter cells.',
            'difficulty': 5
          },
          {
            'question': 'What are the building blocks of proteins?',
            'options': ['Amino acids', 'Nucleotides', 'Fatty acids', 'Monosaccharides'],
            'correct': 'Amino acids',
            'explanation': 'Proteins are made of amino acid chains.',
            'hint': 'There are 20 different types of these.',
            'difficulty': 5
          },
          {
            'question': 'What is the equation for photosynthesis?',
            'options': ['6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂', 'C₆H₁₂O₆ + 6O₂ → 6CO₂ + 6H₂O', 'CO₂ + H₂O → CH₄', 'N₂ + 3H₂ → 2NH₃'],
            'correct': '6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂',
            'explanation': 'Photosynthesis converts carbon dioxide and water into glucose and oxygen.',
            'hint': 'It produces glucose and oxygen.',
            'difficulty': 6
          },
          // Hard (Levels 8-10)
          {
            'question': 'What is the central dogma of molecular biology?',
            'options': ['DNA → RNA → Protein', 'Protein → RNA → DNA', 'RNA → DNA → Protein', 'DNA → Protein → RNA'],
            'correct': 'DNA → RNA → Protein',
            'explanation': 'The central dogma describes the flow of genetic information: DNA is transcribed to RNA, which is translated to protein.',
            'hint': 'It describes the flow of genetic information.',
            'difficulty': 8
          },
          {
            'question': 'What is the Hardy-Weinberg equation?',
            'options': ['p² + 2pq + q² = 1', 'p + q = 1', 'p² + q² = 1', 'pq = 1'],
            'correct': 'p² + 2pq + q² = 1',
            'explanation': 'The Hardy-Weinberg equation describes allele frequencies in a population.',
            'hint': 'It\'s used in population genetics.',
            'difficulty': 9
          },
          {
            'question': 'What is the Krebs cycle also known as?',
            'options': ['Citric acid cycle', 'Calvin cycle', 'Glycolysis', 'Electron transport chain'],
            'correct': 'Citric acid cycle',
            'explanation': 'The Krebs cycle (citric acid cycle) is a key part of cellular respiration.',
            'hint': 'It\'s also called the citric acid cycle.',
            'difficulty': 10
          },
        ];
      case QuestionType.trueFalse:
        return [
          {
            'question': 'True or False: All living things are made of cells.',
            'options': ['True', 'False'],
            'correct': 'True',
            'explanation': 'The cell theory states that all living things are made of one or more cells.',
            'hint': 'This is a fundamental principle of biology.',
            'difficulty': 1
          },
          {
            'question': 'True or False: Plants produce oxygen during photosynthesis.',
            'options': ['True', 'False'],
            'correct': 'True',
            'explanation': 'Photosynthesis produces oxygen as a byproduct.',
            'hint': 'Think about what plants release.',
            'difficulty': 2
          },
          {
            'question': 'True or False: DNA is single-stranded.',
            'options': ['True', 'False'],
            'correct': 'False',
            'explanation': 'DNA is double-stranded, forming a double helix. RNA is single-stranded.',
            'hint': 'Think about the structure of DNA.',
            'difficulty': 5
          },
          {
            'question': 'True or False: Humans have 46 chromosomes.',
            'options': ['True', 'False'],
            'correct': 'True',
            'explanation': 'Humans have 46 chromosomes (23 pairs) in each cell.',
            'hint': 'Count the chromosome pairs.',
            'difficulty': 4
          },
        ];
      case QuestionType.numericInput:
        return [
          {
            'question': 'How many chambers does the human heart have?',
            'options': [],
            'correct': '4',
            'explanation': 'The human heart has 4 chambers: 2 atria and 2 ventricles.',
            'hint': 'Count the atria and ventricles.',
            'difficulty': 2
          },
          {
            'question': 'How many chromosomes do humans have?',
            'options': [],
            'correct': '46',
            'explanation': 'Humans have 46 chromosomes (23 pairs).',
            'hint': 'It\'s 23 pairs.',
            'difficulty': 4
          },
          {
            'question': 'How many amino acids are there in the genetic code?',
            'options': [],
            'correct': '20',
            'explanation': 'There are 20 standard amino acids used to build proteins.',
            'hint': 'It\'s a round number between 15 and 25.',
            'difficulty': 6
          },
        ];
      case QuestionType.fillInTheBlank:
        return [
          {
            'question': 'Fill in the blank: The process by which plants make food is called ____.',
            'options': [],
            'correct': 'photosynthesis',
            'explanation': 'Photosynthesis is the process plants use to make food.',
            'hint': 'It involves sunlight.',
            'difficulty': 2
          },
          {
            'question': 'Fill in the blank: The genetic material in cells is ____.',
            'options': [],
            'correct': 'DNA',
            'explanation': 'DNA (deoxyribonucleic acid) is the genetic material.',
            'hint': 'It\'s a three-letter abbreviation.',
            'difficulty': 3
          },
        ];
      default:
        return [_getDefaultTemplate(type)];
    }
  }

  /// Get default template for any question type
  Map<String, dynamic> _getDefaultTemplate(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return {
          'question': 'Sample multiple choice question?',
          'options': ['Option A', 'Option B', 'Option C', 'Option D'],
          'correct': 'Option A',
          'explanation': 'This is a sample explanation.',
          'hint': 'This is a sample hint.'
        };
      case QuestionType.trueFalse:
        return {
          'question': 'This is a true/false question.',
          'options': ['True', 'False'],
          'correct': 'True',
          'explanation': 'This is a sample explanation.',
          'hint': 'Consider the statement carefully.'
        };
      case QuestionType.numericInput:
        return {
          'question': 'Enter a number:',
          'options': [],
          'correct': '42',
          'explanation': 'The answer is 42.',
          'hint': 'Think about the ultimate answer.'
        };
      case QuestionType.fillInTheBlank:
        return {
          'question': 'Fill in the blank: The sky is ____.',
          'options': [],
          'correct': 'blue',
          'explanation': 'The sky appears blue due to light scattering.',
          'hint': 'What color do you see when you look up?'
        };
      case QuestionType.dragDrop:
        return {
          'question': 'Match the items:',
          'options': ['Item 1', 'Item 2', 'Item 3'],
          'correct': 'Item 1',
          'explanation': 'This is the correct match.',
          'hint': 'Look for logical connections.'
        };
      case QuestionType.clickableAnswer:
        return {
          'question': 'Click the correct answer:',
          'options': ['Answer 1', 'Answer 2', 'Answer 3'],
          'correct': 'Answer 1',
          'explanation': 'This is the correct answer.',
          'hint': 'Choose carefully.'
        };
      case QuestionType.shortAnswer:
        return {
          'question': 'Provide a short answer:',
          'options': [],
          'correct': 'sample answer',
          'explanation': 'This is a sample answer.',
          'hint': 'Keep your answer brief and clear.'
        };
    }
  }

  /// Helper methods
  String _getTopicForLevel(SubjectType subject, int level) {
    switch (subject) {
      case SubjectType.math:
        return level <= 3 ? 'Basic Arithmetic' : level <= 6 ? 'Algebra' : 'Calculus';
      case SubjectType.physics:
        return level <= 3 ? 'Motion' : level <= 6 ? 'Forces' : 'Energy';
      case SubjectType.chemistry:
        return level <= 3 ? 'Atoms' : level <= 6 ? 'Molecules' : 'Reactions';
      case SubjectType.biology:
        return level <= 3 ? 'Cells' : level <= 6 ? 'Genetics' : 'Evolution';
      default:
        return 'General';
    }
  }

  GameDifficulty _getDifficultyForLevel(int level) {
    if (level <= 3) return GameDifficulty.beginner;
    if (level <= 6) return GameDifficulty.intermediate;
    if (level <= 9) return GameDifficulty.advanced;
    return GameDifficulty.expert;
  }

  int _mapDifficultyToInt(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.beginner:
        return 30;
      case GameDifficulty.intermediate:
        return 60;
      case GameDifficulty.advanced:
        return 90;
      case GameDifficulty.expert:
        return 120;
    }
  }
}