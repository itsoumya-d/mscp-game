import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/models/question.dart';
import 'package:sp/core/models/question_pool.dart';
import 'skill_id_registry.dart';

class QuestionPoolService {
  static const String _poolManagerKey = 'question_pool_manager';
  
  QuestionPoolManager? _poolManager;
  final Random _rng = Random();

  /// Initialize the question pool service
  Future<void> initialize() async {
    await _loadPoolManager();
    await _initializeDefaultPools();
  }

  /// Load the pool manager from storage
  Future<void> _loadPoolManager() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_poolManagerKey);
    
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString);
        _poolManager = QuestionPoolManager.fromJson(json);
      } catch (e) {
        // If loading fails, create a new manager
        _poolManager = const QuestionPoolManager(pools: {}, lastResetTimes: {});
      }
    } else {
      _poolManager = const QuestionPoolManager(pools: {}, lastResetTimes: {});
    }
  }

  /// Save the pool manager to storage
  Future<void> _savePoolManager() async {
    if (_poolManager == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_poolManager!.toJson());
    await prefs.setString(_poolManagerKey, jsonString);
  }

  /// Initialize default question pools for all subjects and skills
  Future<void> _initializeDefaultPools() async {
    if (_poolManager == null) return;

    // Initialize pools for each subject
    for (final subject in SubjectType.values) {
      await _initializeSubjectPools(subject);
    }
    
    await _savePoolManager();
  }

  /// Initialize question pools for a specific subject
  Future<void> _initializeSubjectPools(SubjectType subject) async {
    final skillIds = _getSkillIdsForSubject(subject);
    
    for (final skillId in skillIds) {
      for (final category in QuestionCategory.values) {
        final poolKey = '${subject.name}_${skillId}_${category.name}';
        
        // Only create pool if it doesn't exist
        if (_poolManager!.getPool(subject, skillId, category) == null) {
          final templates = _generateTemplatesForSkillCategory(subject, skillId, category);
          
          final pool = QuestionPool(
            id: poolKey,
            subject: subject,
            skillId: skillId,
            category: category,
            templates: templates,
            usedQuestionIds: <String>{},
            lastUsed: DateTime.now(),
          );
          
          _poolManager = _poolManager!.updatePool(pool);
        }
      }
    }
  }

  /// Get skill IDs for a subject using the centralized SkillIdRegistry
  List<String> _getSkillIdsForSubject(SubjectType subject) {
    // Use the centralized SkillIdRegistry to ensure consistency
    return SkillIdRegistry.getSkillIdsForSubject(subject);
  }

  /// Generate question templates for a specific skill and category
  List<QuestionTemplate> _generateTemplatesForSkillCategory(
    SubjectType subject, 
    String skillId, 
    QuestionCategory category
  ) {
    final templates = <QuestionTemplate>[];
    
    // Generate ALL 7 question types for each category
    templates.addAll(_generateAllQuestionTypes(subject, skillId, category));
    
    return templates;
  }

  /// Generate all 7 question types for a given subject, skill, and category
  List<QuestionTemplate> _generateAllQuestionTypes(
    SubjectType subject,
    String skillId,
    QuestionCategory category
  ) {
    final templates = <QuestionTemplate>[];
    
    // Generate templates for each question type
    for (final questionType in QuestionType.values) {
      final typeTemplates = _generateTemplatesForQuestionType(
        subject, skillId, category, questionType
      );
      templates.addAll(typeTemplates);
    }
    
    return templates;
  }

  /// Generate templates for a specific question type
  List<QuestionTemplate> _generateTemplatesForQuestionType(
    SubjectType subject,
    String skillId,
    QuestionCategory category,
    QuestionType questionType
  ) {
    switch (questionType) {
      case QuestionType.multipleChoice:
        return _generateMultipleChoiceTemplates(subject, skillId, category);
      case QuestionType.trueFalse:
        return _generateTrueFalseTemplates(subject, skillId, category);
      case QuestionType.numericInput:
        return _generateNumericInputTemplates(subject, skillId, category);
      case QuestionType.fillInTheBlank:
        return _generateFillInTheBlankTemplates(subject, skillId, category);
      case QuestionType.dragDrop:
        return _generateDragDropTemplates(subject, skillId, category);
      case QuestionType.clickableAnswer:
        return _generateClickableAnswerTemplates(subject, skillId, category);
      case QuestionType.shortAnswer:
        return _generateShortAnswerTemplates(subject, skillId, category);
    }
  }

  /// Generate multiple choice templates
  List<QuestionTemplate> _generateMultipleChoiceTemplates(
    SubjectType subject, String skillId, QuestionCategory category
  ) {
    final templates = <QuestionTemplate>[];
    
    switch (subject) {
      case SubjectType.math:
        if (skillId == 'algebra') {
          templates.add(QuestionTemplate(
            id: 'math_algebra_mc_${category.name}_1',
            type: QuestionType.multipleChoice,
            category: category,
            questionPattern: 'What is the value of x in the equation: x + {num} = {result}?',
            optionPatterns: ['{answer}', '{wrong1}', '{wrong2}', '{wrong3}'],
            correctAnswerPattern: '{answer}',
            explanationPattern: 'To solve x + {num} = {result}, subtract {num} from both sides: x = {result} - {num} = {answer}',
            hintPattern: 'Subtract {num} from both sides of the equation.',
            baseDifficulty: 2,
            variables: {
              'num': [3, 5, 7, 9, 12, 15],
              'result': [10, 15, 20, 25, 30],
              'answer': [], // Will be calculated as result - num
              'wrong1': [], // Will be calculated
              'wrong2': [], // Will be calculated
              'wrong3': [], // Will be calculated
            },
            tags: {'algebra', 'equations', 'multiple_choice'},
          ));
        }
        if (skillId == 'arithmetic') {
          templates.add(QuestionTemplate(
            id: 'math_arithmetic_mc_${category.name}_1',
            type: QuestionType.multipleChoice,
            category: category,
            questionPattern: 'What is {operation}?',
            optionPatterns: ['{correct_answer}', '{wrong_answer_1}', '{wrong_answer_2}', '{wrong_answer_3}'],
            correctAnswerPattern: '{correct_answer}',
            explanationPattern: '{operation} equals {correct_answer} using basic arithmetic.',
            hintPattern: 'Think about the mathematical operation carefully.',
            baseDifficulty: 2,
            variables: {
              'operation': ['2 + 3', '5 × 4', '15 ÷ 3', '8 - 2'],
              'correct_answer': ['5', '20', '5', '6'],
              'wrong_answer_1': ['4', '19', '4', '5'],
              'wrong_answer_2': ['6', '21', '6', '7'],
              'wrong_answer_3': ['3', '18', '3', '4']
            },
            tags: {'math', 'arithmetic', skillId},
          ));
        }
        if (skillId == 'multiplication') {
          templates.add(QuestionTemplate(
            id: 'math_multiplication_mc_${category.name}_1',
            type: QuestionType.multipleChoice,
            category: category,
            questionPattern: 'What is {num1} × {num2}?',
            optionPatterns: ['{correct_answer}', '{wrong_answer_1}', '{wrong_answer_2}', '{wrong_answer_3}'],
            correctAnswerPattern: '{correct_answer}',
            explanationPattern: '{num1} × {num2} = {correct_answer}',
            hintPattern: 'Multiply the two numbers together.',
            baseDifficulty: 2,
            variables: {
              'num1': [2, 3, 4, 5, 6, 7, 8, 9],
              'num2': [2, 3, 4, 5, 6, 7, 8, 9],
              'correct_answer': [], // Will be calculated as num1 * num2
              'wrong_answer_1': [], // Will be calculated
              'wrong_answer_2': [], // Will be calculated
              'wrong_answer_3': [], // Will be calculated
            },
            tags: {'math', 'multiplication', skillId},
          ));
        }
        break;
      case SubjectType.physics:
        if (skillId == 'energy') {
          templates.add(QuestionTemplate(
            id: 'physics_energy_mc_${category.name}_1',
            type: QuestionType.multipleChoice,
            category: category,
            questionPattern: 'Which of the following is a form of kinetic energy?',
            optionPatterns: [
              'A moving car',
              'A compressed spring',
              'Water behind a dam',
              'A book on a shelf'
            ],
            correctAnswerPattern: 'A moving car',
            explanationPattern: 'Kinetic energy is the energy of motion. A moving car has kinetic energy due to its motion.',
            hintPattern: 'Think about which option involves motion.',
            baseDifficulty: 2,
            variables: {},
            tags: {'energy', 'kinetic', 'multiple_choice'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'atoms') {
          templates.add(QuestionTemplate(
            id: 'chemistry_atoms_mc_${category.name}_1',
            type: QuestionType.multipleChoice,
            category: category,
            questionPattern: 'What is the chemical symbol for {element}?',
            optionPatterns: ['{correct_symbol}', '{wrong_symbol_1}', '{wrong_symbol_2}', '{wrong_symbol_3}'],
            correctAnswerPattern: '{correct_symbol}',
            explanationPattern: '{element} has the chemical symbol {correct_symbol}.',
            hintPattern: 'Think about the periodic table.',
            baseDifficulty: 2,
            variables: {
              'element': ['hydrogen', 'oxygen', 'carbon', 'nitrogen'],
              'correct_symbol': ['H', 'O', 'C', 'N'],
              'wrong_symbol_1': ['He', 'Os', 'Ca', 'Na'],
              'wrong_symbol_2': ['Hg', 'Og', 'Cl', 'Ni'],
              'wrong_symbol_3': ['Ho', 'Ox', 'Cr', 'Ne']
            },
            tags: {'chemistry', 'elements', skillId},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'cells') {
          templates.add(QuestionTemplate(
            id: 'biology_cells_mc_${category.name}_1',
            type: QuestionType.multipleChoice,
            category: category,
            questionPattern: 'Which organelle is responsible for {function}?',
            optionPatterns: ['{correct_organelle}', '{wrong_organelle_1}', '{wrong_organelle_2}', '{wrong_organelle_3}'],
            correctAnswerPattern: '{correct_organelle}',
            explanationPattern: 'The {correct_organelle} is responsible for {function} in the cell.',
            hintPattern: 'Think about cellular structures and their functions.',
            baseDifficulty: 2,
            variables: {
              'function': ['protein synthesis', 'energy production', 'waste removal', 'genetic material storage'],
              'correct_organelle': ['ribosome', 'mitochondria', 'lysosome', 'nucleus'],
              'wrong_organelle_1': ['cell wall', 'cytoplasm', 'cell membrane', 'vacuole'],
              'wrong_organelle_2': ['chloroplast', 'endoplasmic reticulum', 'golgi apparatus', 'centriole'],
              'wrong_organelle_3': ['peroxisome', 'cytoskeleton', 'nucleolus', 'chromatin']
            },
            tags: {'biology', 'cell_biology', skillId},
          ));
        }
        break;
      case SubjectType.computerScience:
        if (skillId == 'algorithms') {
          templates.add(QuestionTemplate(
            id: 'cs_algorithms_mc_${category.name}_1',
            type: QuestionType.multipleChoice,
            category: category,
            questionPattern: 'What is the time complexity of {algorithm}?',
            optionPatterns: ['{correct_complexity}', '{wrong_complexity_1}', '{wrong_complexity_2}', '{wrong_complexity_3}'],
            correctAnswerPattern: '{correct_complexity}',
            explanationPattern: '{algorithm} has {correct_complexity} time complexity because {reason}.',
            hintPattern: 'Consider how the algorithm scales with input size.',
            baseDifficulty: 3,
            variables: {
              'algorithm': ['binary search', 'bubble sort', 'merge sort', 'linear search'],
              'correct_complexity': ['O(log n)', 'O(n²)', 'O(n log n)', 'O(n)'],
              'wrong_complexity_1': ['O(1)', 'O(n)', 'O(n²)', 'O(log n)'],
              'wrong_complexity_2': ['O(n²)', 'O(log n)', 'O(1)', 'O(n²)'],
              'wrong_complexity_3': ['O(2^n)', 'O(n!)', 'O(n³)', 'O(√n)'],
              'reason': ['it divides the search space in half', 'it compares every element with every other', 'it uses divide and conquer', 'it checks each element once']
            },
            tags: {'computer_science', 'algorithms', skillId},
          ));
        }
        break;
      case SubjectType.geography:
        if (skillId == 'landforms') {
          templates.add(QuestionTemplate(
            id: 'geography_landforms_mc_${category.name}_1',
            type: QuestionType.multipleChoice,
            category: category,
            questionPattern: 'What is the capital of {country}?',
            optionPatterns: ['{correct_capital}', '{wrong_capital_1}', '{wrong_capital_2}', '{wrong_capital_3}'],
            correctAnswerPattern: '{correct_capital}',
            explanationPattern: '{correct_capital} is the capital city of {country}.',
            hintPattern: 'Think about major cities in {country}.',
            baseDifficulty: 1,
            variables: {
              'country': ['France', 'Germany', 'Italy', 'Spain'],
              'correct_capital': ['Paris', 'Berlin', 'Rome', 'Madrid'],
              'wrong_capital_1': ['Lyon', 'Munich', 'Milan', 'Barcelona'],
              'wrong_capital_2': ['Marseille', 'Hamburg', 'Naples', 'Valencia'],
              'wrong_capital_3': ['Nice', 'Cologne', 'Turin', 'Seville']
            },
            tags: {'geography', 'capitals', skillId},
          ));
        }
        break;
      case SubjectType.history:
        if (skillId == 'mesopotamia') {
          templates.add(QuestionTemplate(
            id: 'history_mesopotamia_mc_${category.name}_1',
            type: QuestionType.multipleChoice,
            category: category,
            questionPattern: 'In which year did {event} occur?',
            optionPatterns: ['{correct_year}', '{wrong_year_1}', '{wrong_year_2}', '{wrong_year_3}'],
            correctAnswerPattern: '{correct_year}',
            explanationPattern: '{event} occurred in {correct_year}.',
            hintPattern: 'Think about the timeline of major historical events.',
            baseDifficulty: 2,
            variables: {
              'event': ['World War I begin', 'the Berlin Wall fall', 'the American Civil War end', 'the French Revolution begin'],
              'correct_year': ['1914', '1989', '1865', '1789'],
              'wrong_year_1': ['1915', '1990', '1864', '1790'],
              'wrong_year_2': ['1913', '1988', '1866', '1788'],
              'wrong_year_3': ['1916', '1991', '1863', '1787']
            },
            tags: {'history', 'dates', skillId},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_method_mc_${category.name}_1',
            type: QuestionType.multipleChoice,
            category: category,
            questionPattern: 'What is the first step in the scientific method?',
            optionPatterns: ['Observation', 'Hypothesis', 'Experiment', 'Conclusion'],
            correctAnswerPattern: 'Observation',
            explanationPattern: 'The scientific method begins with observation of phenomena.',
            hintPattern: 'Think about what scientists do first when studying something.',
            baseDifficulty: 1,
            variables: {},
            tags: {'science', 'scientific_method', skillId},
          ));
        }
        break;
      case SubjectType.english:
        if (skillId == 'grammar') {
          templates.add(QuestionTemplate(
            id: 'english_grammar_mc_${category.name}_1',
            type: QuestionType.multipleChoice,
            category: category,
            questionPattern: 'What type of word is "{word}"?',
            optionPatterns: ['{correct_type}', '{wrong_type_1}', '{wrong_type_2}', '{wrong_type_3}'],
            correctAnswerPattern: '{correct_type}',
            explanationPattern: '"{word}" is a {correct_type}.',
            hintPattern: 'Think about the function of this word in a sentence.',
            baseDifficulty: 1,
            variables: {
              'word': ['quickly', 'beautiful', 'run', 'happiness'],
              'correct_type': ['adverb', 'adjective', 'verb', 'noun'],
              'wrong_type_1': ['noun', 'noun', 'noun', 'verb'],
              'wrong_type_2': ['verb', 'verb', 'adjective', 'adjective'],
              'wrong_type_3': ['adjective', 'adverb', 'adverb', 'adverb']
            },
            tags: {'english', 'grammar', skillId},
          ));
        }
        break;
      case SubjectType.art:
        if (skillId == 'color_theory') {
          templates.add(QuestionTemplate(
            id: 'art_color_mc_${category.name}_1',
            type: QuestionType.multipleChoice,
            category: category,
            questionPattern: 'What are the primary colors?',
            optionPatterns: ['Red, Blue, Yellow', 'Red, Green, Blue', 'Blue, Yellow, Green', 'Red, Yellow, Orange'],
            correctAnswerPattern: 'Red, Blue, Yellow',
            explanationPattern: 'The primary colors are red, blue, and yellow.',
            hintPattern: 'Think about the colors that cannot be created by mixing other colors.',
            baseDifficulty: 1,
            variables: {},
            tags: {'art', 'color_theory', skillId},
          ));
        }
        break;
      case SubjectType.music:
        if (skillId == 'notes') {
          templates.add(QuestionTemplate(
            id: 'music_notes_mc_${category.name}_1',
            type: QuestionType.multipleChoice,
            category: category,
            questionPattern: 'How many lines are in a musical staff?',
            optionPatterns: ['5', '4', '6', '7'],
            correctAnswerPattern: '5',
            explanationPattern: 'A musical staff has 5 lines.',
            hintPattern: 'Count the horizontal lines where notes are placed.',
            baseDifficulty: 1,
            variables: {},
            tags: {'music', 'notes', skillId},
          ));
        }
        break;
      case SubjectType.physicalEducation:
        if (skillId == 'fitness') {
          templates.add(QuestionTemplate(
            id: 'pe_fitness_mc_${category.name}_1',
            type: QuestionType.multipleChoice,
            category: category,
            questionPattern: 'Which exercise is best for cardiovascular health?',
            optionPatterns: ['Running', 'Weight lifting', 'Stretching', 'Yoga'],
            correctAnswerPattern: 'Running',
            explanationPattern: 'Running is an excellent cardiovascular exercise.',
            hintPattern: 'Think about exercises that increase heart rate.',
            baseDifficulty: 1,
            variables: {},
            tags: {'physical_education', 'fitness', skillId},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_method_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'If an experiment is repeated {trials} times and {successes} trials show the expected result, what is the success rate as a percentage?',
            optionPatterns: [],
            correctAnswerPattern: '{percentage}',
            explanationPattern: 'Success rate = ({successes}/{trials}) × 100 = {percentage}%',
            hintPattern: 'Divide successes by total trials and multiply by 100.',
            baseDifficulty: 2,
            variables: {
              'trials': [10, 20, 25, 50],
              'successes': [8, 16, 20, 40],
              'percentage': [80, 80, 80, 80],
            },
            tags: {'scientific_method', 'statistics', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_scientific_method_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A scientist conducts an experiment {trials} times. If each trial takes {minutes} minutes, how many total minutes are needed?',
            optionPatterns: [],
            correctAnswerPattern: '{totalMinutes}',
            explanationPattern: 'Total time = Number of trials × Time per trial = {trials} × {minutes} = {totalMinutes} minutes',
            hintPattern: 'Multiply the number of trials by the time per trial.',
            baseDifficulty: 1,
            variables: {
              'trials': [5, 8, 10, 12],
              'minutes': [15, 20, 25, 30],
              'totalMinutes': [], // Will be calculated as trials * minutes
            },
            tags: {'scientific_method', 'calculation', 'numeric_input'},
          ));
        }
        break;
      
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_method_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A scientist conducts an experiment with {trials} trials. If {percent}% of the trials show positive results, how many trials showed positive results?',
            optionPatterns: [],
            correctAnswerPattern: '{positiveTrials}',
            explanationPattern: 'Positive trials = {trials} × {percent}% = {trials} × {decimal} = {positiveTrials}',
            hintPattern: 'Convert the percentage to a decimal and multiply by the total number of trials.',
            baseDifficulty: 2,
            variables: {
              'trials': [50, 100, 200],
              'percent': [20, 25, 30, 40, 50, 60, 75, 80],
              'decimal': [0.20, 0.25, 0.30, 0.40, 0.50, 0.60, 0.75, 0.80],
              'positiveTrials': [10, 25, 60, 20, 50, 120, 150, 160], // calculated based on trials × decimal
            },
            tags: {'scientific_method', 'statistics', 'numeric_input'},
          ));
        }
        break;
      
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_method_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A scientist conducts an experiment with {trials} trials. If {percent}% of the trials show positive results, how many trials showed positive results?',
            optionPatterns: [],
            correctAnswerPattern: '{positiveTrials}',
            explanationPattern: 'Positive trials = {trials} × {percent}% = {trials} × {decimal} = {positiveTrials}',
            hintPattern: 'Convert the percentage to a decimal and multiply by the total number of trials.',
            baseDifficulty: 2,
            variables: {
              'trials': [50, 100, 200],
              'percent': [20, 25, 30, 40, 50, 60, 75, 80],
              'decimal': [0.20, 0.25, 0.30, 0.40, 0.50, 0.60, 0.75, 0.80],
              'positiveTrials': [10, 25, 60, 20, 50, 120, 150, 160], // calculated based on trials × decimal
            },
            tags: {'scientific_method', 'statistics', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_scientific_method_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'If a hypothesis is tested {trials} times and succeeds {successes} times, what is the success rate as a percentage?',
            optionPatterns: [],
            correctAnswerPattern: '{percentage}',
            explanationPattern: 'Success rate = (successes ÷ trials) × 100 = ({successes} ÷ {trials}) × 100 = {percentage}%',
            hintPattern: 'Divide successes by trials and multiply by 100.',
            baseDifficulty: 2,
            variables: {
              'trials': [10, 20, 25, 50],
              'successes': [8, 16, 20, 40],
              'percentage': [80, 80, 80, 80],
            },
            tags: {'scientific_method', 'percentage', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_scientific_method_ni_${category.name}_2',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'If a hypothesis is tested {trials} times and succeeds {successes} times, what is the success rate as a percentage?',
            optionPatterns: [],
            correctAnswerPattern: '{percentage}',
            explanationPattern: 'Success rate = (successes ÷ trials) × 100 = ({successes} ÷ {trials}) × 100 = {percentage}%',
            hintPattern: 'Divide successes by trials and multiply by 100.',
            baseDifficulty: 2,
            variables: {
              'trials': [10, 20, 25, 50],
              'successes': [8, 16, 20, 40],
              'percentage': [80, 80, 80, 80],
            },
            tags: {'scientific_method', 'percentage', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_scientific_method_ni_${category.name}_4',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A scientist conducts {trials} experiments and {successes} are successful. What is the success rate as a percentage?',
            optionPatterns: [],
            correctAnswerPattern: '{percentage}',
            explanationPattern: 'Success rate = (successful experiments ÷ total experiments) × 100 = ({successes} ÷ {trials}) × 100 = {percentage}%',
            hintPattern: 'Divide successful experiments by total experiments and multiply by 100.',
            baseDifficulty: 2,
            variables: {
              'trials': [20, 25, 50],
              'successes': [16, 20, 40],
              'percentage': [80, 80, 80],
            },
            tags: {'scientific_method', 'percentage', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_scientific_method_ni_${category.name}_5',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'In an experiment, {total} observations were made and {valid} were valid. What percentage were valid?',
            optionPatterns: [],
            correctAnswerPattern: '{percentage}',
            explanationPattern: 'Percentage of valid observations = (valid observations ÷ total observations) × 100 = ({valid} ÷ {total}) × 100 = {percentage}%',
            hintPattern: 'Divide valid observations by total observations and multiply by 100.',
            baseDifficulty: 2,
            variables: {
              'total': [40, 50, 80],
              'valid': [32, 40, 64],
              'percentage': [80, 80, 80],
            },
            tags: {'scientific_method', 'percentage', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_method_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'If an experiment has a {successRate}% success rate and is repeated {trials} times, how many successful outcomes would you expect?',
            optionPatterns: [],
            correctAnswerPattern: '{expectedSuccess}',
            explanationPattern: 'Expected successes = (Success rate / 100) × Number of trials = ({successRate} / 100) × {trials} = {expectedSuccess}',
            hintPattern: 'Multiply the success rate (as a decimal) by the number of trials.',
            baseDifficulty: 2,
            variables: {
              'successRate': [75, 80, 60],
              'trials': [20, 25, 30],
              'expectedSuccess': [15, 20, 18], // calculated based on rate and trials
            },
            tags: {'scientific_method', 'probability', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_method_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'If an experiment has a {successRate}% success rate and is repeated {trials} times, how many successful outcomes would you expect?',
            optionPatterns: [],
            correctAnswerPattern: '{expectedSuccess}',
            explanationPattern: 'Expected successes = (Success rate / 100) × Number of trials = ({successRate} / 100) × {trials} = {expectedSuccess}',
            hintPattern: 'Multiply the success rate (as a decimal) by the number of trials.',
            baseDifficulty: 2,
            variables: {
              'successRate': [75, 80, 60],
              'trials': [20, 25, 30],
              'expectedSuccess': [15, 20, 18], // calculated based on rate and trials
            },
            tags: {'scientific_method', 'probability', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_method_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'In an experiment, you test {trials} samples. If the success rate is {rate}%, how many successful outcomes do you expect?',
            optionPatterns: [],
            correctAnswerPattern: '{expected}',
            explanationPattern: 'Expected outcomes = Total trials × Success rate = {trials} × {rate}% = {expected}',
            hintPattern: 'Multiply the number of trials by the success rate percentage.',
            baseDifficulty: 2,
            variables: {
              'trials': [100, 200, 50],
              'rate': [75, 80, 60],
              'expected': [75, 160, 30],
            },
            tags: {'scientific_method', 'statistics', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_method_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'In an experiment, you test {trials} samples. If the success rate is {rate}%, how many successful outcomes do you expect?',
            optionPatterns: [],
            correctAnswerPattern: '{expected}',
            explanationPattern: 'Expected outcomes = Total trials × Success rate = {trials} × {rate}% = {expected}',
            hintPattern: 'Multiply the number of trials by the success rate percentage.',
            baseDifficulty: 2,
            variables: {
              'trials': [100, 200, 50],
              'rate': [75, 80, 60],
              'expected': [75, 160, 30],
            },
            tags: {'scientific_method', 'statistics', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_method_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'In an experiment with {trials} trials and a success rate of {rate}%, how many successful outcomes would you expect?',
            optionPatterns: [],
            correctAnswerPattern: '{expected}',
            explanationPattern: 'Expected outcomes = Total trials × Success rate. {trials} × {rate}% = {expected}',
            hintPattern: 'Multiply the number of trials by the success rate percentage.',
            baseDifficulty: 2,
            variables: {
              'trials': [50, 100, 200, 300],
              'rate': [20, 25, 30, 40, 50, 60, 75, 80],
              'expected': [], // Will be calculated
            },
            tags: {'scientific_method', 'probability', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_method_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'In an experiment with {trials} trials and a success rate of {rate}%, how many successful outcomes would you expect?',
            optionPatterns: [],
            correctAnswerPattern: '{expected}',
            explanationPattern: 'Expected outcomes = Total trials × Success rate. {trials} × {rate}% = {expected}',
            hintPattern: 'Multiply the number of trials by the success rate percentage.',
            baseDifficulty: 2,
            variables: {
              'trials': [50, 100, 200, 300],
              'rate': [20, 25, 30, 40, 50, 60, 75, 80],
              'expected': [], // Will be calculated
            },
            tags: {'scientific_method', 'probability', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_method_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'In an experiment with {trials} trials and a success rate of {rate}%, how many successful outcomes would you expect?',
            optionPatterns: [],
            correctAnswerPattern: '{expected}',
            explanationPattern: 'Expected outcomes = Total trials × Success rate. {trials} × {rate}% = {expected}',
            hintPattern: 'Multiply the number of trials by the success rate percentage.',
            baseDifficulty: 2,
            variables: {
              'trials': [50, 100, 200, 300],
              'rate': [20, 25, 30, 40, 50, 60, 75, 80],
              'expected': [], // Will be calculated
            },
            tags: {'scientific_method', 'probability', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'experiments') {
          templates.add(QuestionTemplate(
            id: 'science_experiments_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'If you plant 10 seeds and expect a 70% germination rate, how many plants do you expect to grow?',
            optionPatterns: [],
            correctAnswerPattern: '7',
            explanationPattern: '10 seeds × 0.70 = 7 expected plants to grow.',
            hintPattern: 'Multiply the total number by the percentage rate.',
            baseDifficulty: 2,
            variables: {},
            tags: {'experiments', 'probability', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'experiments') {
          templates.add(QuestionTemplate(
            id: 'science_experiments_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'If you plant 10 seeds and expect a 70% germination rate, how many plants do you expect to grow?',
            optionPatterns: [],
            correctAnswerPattern: '7',
            explanationPattern: '10 seeds × 0.70 = 7 expected plants to grow.',
            hintPattern: 'Multiply the total number by the percentage rate.',
            baseDifficulty: 2,
            variables: {},
            tags: {'experiments', 'probability', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'experiments') {
          templates.add(QuestionTemplate(
            id: 'science_experiments_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'If you plant 10 seeds and expect a 70% germination rate, how many plants do you expect to grow?',
            optionPatterns: [],
            correctAnswerPattern: '7',
            explanationPattern: '10 seeds × 0.70 = 7 expected plants to grow.',
            hintPattern: 'Multiply the total number by the percentage rate.',
            baseDifficulty: 2,
            variables: {},
            tags: {'experiments', 'probability', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'experiments') {
          templates.add(QuestionTemplate(
            id: 'science_experiments_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'In an experiment, if you test {trials} samples and expect a {percentage}% success rate, how many successful outcomes do you expect?',
            optionPatterns: [],
            correctAnswerPattern: '{expected}',
            explanationPattern: 'Expected outcomes = {trials} × ({percentage}/100) = {expected}',
            hintPattern: 'Multiply the number of trials by the success rate percentage.',
            baseDifficulty: 2,
            variables: {
              'trials': [20, 50, 100],
              'percentage': [25, 50, 75],
              'expected': [5, 25, 75], // calculated based on trials and percentage
            },
            tags: {'experiments', 'probability', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'experiments') {
          templates.add(QuestionTemplate(
            id: 'science_experiments_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'In an experiment, if you test {trials} samples and expect a {percentage}% success rate, how many successful outcomes do you expect?',
            optionPatterns: [],
            correctAnswerPattern: '{expected}',
            explanationPattern: 'Expected outcomes = {trials} × ({percentage}/100) = {expected}',
            hintPattern: 'Multiply the number of trials by the success rate percentage.',
            baseDifficulty: 2,
            variables: {
              'trials': [20, 50, 100],
              'percentage': [25, 50, 75],
              'expected': [5, 25, 75], // calculated based on trials and percentage
            },
            tags: {'experiments', 'probability', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'experiments') {
          templates.add(QuestionTemplate(
            id: 'science_experiments_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'In an experiment, if you test {trials} samples and expect a {percentage}% success rate, how many successful outcomes do you expect?',
            optionPatterns: [],
            correctAnswerPattern: '{expected}',
            explanationPattern: 'Expected outcomes = {trials} × ({percentage}/100) = {expected}',
            hintPattern: 'Multiply the number of trials by the success rate percentage.',
            baseDifficulty: 2,
            variables: {
              'trials': [20, 50, 100],
              'percentage': [25, 50, 75],
              'expected': [5, 25, 75], // calculated based on trials and percentage
            },
            tags: {'experiments', 'probability', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'experiments') {
          templates.add(QuestionTemplate(
            id: 'science_experiments_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'If you plant {seeds} seeds and {percent}% germinate, how many plants will grow?',
            optionPatterns: [],
            correctAnswerPattern: '{result}',
            explanationPattern: '{seeds} × {percent}/100 = {result} plants will grow.',
            hintPattern: 'Calculate the percentage of seeds that will germinate.',
            baseDifficulty: 2,
            variables: {
              'seeds': [20, 50, 100],
              'percent': [80, 90, 75],
              'result': [16, 45, 75], // seeds * percent / 100
            },
            tags: {'experiments', 'percentage', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'experiments') {
          templates.add(QuestionTemplate(
            id: 'science_experiments_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'If you plant {seeds} seeds and {percent}% germinate, how many plants will grow?',
            optionPatterns: [],
            correctAnswerPattern: '{result}',
            explanationPattern: '{seeds} × {percent}/100 = {result} plants will grow.',
            hintPattern: 'Calculate the percentage of seeds that will germinate.',
            baseDifficulty: 2,
            variables: {
              'seeds': [20, 50, 100],
              'percent': [80, 90, 75],
              'result': [16, 45, 75], // seeds * percent / 100
            },
            tags: {'experiments', 'percentage', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'experiments') {
          templates.add(QuestionTemplate(
            id: 'science_experiments_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'If you plant {seeds} seeds and {percent}% germinate, how many plants will grow?',
            optionPatterns: [],
            correctAnswerPattern: '{result}',
            explanationPattern: '{seeds} × {percent}/100 = {result} plants will grow.',
            hintPattern: 'Calculate the percentage of seeds that will germinate.',
            baseDifficulty: 2,
            variables: {
              'seeds': [20, 50, 100],
              'percent': [80, 90, 75],
              'result': [16, 45, 75], // seeds * percent / 100
            },
            tags: {'experiments', 'percentage', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'experiments') {
          templates.add(QuestionTemplate(
            id: 'science_experiments_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'If a pendulum swings {swings} times in {seconds} seconds, what is its frequency in Hz?',
            optionPatterns: [],
            correctAnswerPattern: '{frequency}',
            explanationPattern: 'Frequency = Number of swings / Time = {swings} / {seconds} = {frequency} Hz',
            hintPattern: 'Frequency is the number of cycles per second.',
            baseDifficulty: 2,
            variables: {
              'swings': [10, 20, 30],
              'seconds': [5, 10, 15],
              'frequency': [2, 2, 2], // swings / seconds
            },
            tags: {'experiments', 'frequency', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'experiments') {
          templates.add(QuestionTemplate(
            id: 'science_experiments_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A ball is dropped from {height} meters. Using the formula h = 0.5 × g × t², where g = 9.8 m/s², how long (in seconds) does it take to hit the ground?',
            optionPatterns: [],
            correctAnswerPattern: '{time}',
            explanationPattern: 'Using h = 0.5 × g × t², we get {height} = 0.5 × 9.8 × t², so t = √({height}/4.9) = {time} seconds',
            hintPattern: 'Rearrange the formula to solve for time: t = √(2h/g)',
            baseDifficulty: 3,
            variables: {
              'height': [20, 45, 80],
              'time': [2.02, 3.03, 4.04], // √(2*height/9.8)
            },
            tags: {'experiments', 'physics', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'physics') {
          templates.add(QuestionTemplate(
            id: 'science_physics_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A car travels at {speed} m/s for {time} seconds. What distance does it travel?',
            optionPatterns: [],
            correctAnswerPattern: '{distance}',
            explanationPattern: 'Distance = Speed × Time = {speed} × {time} = {distance} meters',
            hintPattern: 'Use the formula: Distance = Speed × Time',
            baseDifficulty: 2,
            variables: {
              'speed': [20, 25, 30],
              'time': [5, 8, 10],
              'distance': [100, 200, 300], // speed * time
            },
            tags: {'physics', 'motion', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'physics') {
          templates.add(QuestionTemplate(
            id: 'science_physics_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A spring with spring constant {k} N/m is compressed by {x} m. What is the elastic potential energy stored?',
            optionPatterns: [],
            correctAnswerPattern: '{energy}',
            explanationPattern: 'Elastic potential energy = ½kx² = ½ × {k} × {x}² = {energy} J',
            hintPattern: 'Use the formula: PE = ½kx²',
            baseDifficulty: 3,
            variables: {
              'k': [100, 200, 300],
              'x': [0.1, 0.2, 0.3],
              'energy': [0.5, 4.0, 13.5], // ½kx²
            },
            tags: {'physics', 'energy', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'physics') {
          templates.add(QuestionTemplate(
            id: 'science_physics_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A wave has a frequency of {frequency} Hz and a wavelength of {wavelength} m. What is its speed in m/s?',
            optionPatterns: [],
            correctAnswerPattern: '{speed}',
            explanationPattern: 'Wave speed = frequency × wavelength = {frequency} × {wavelength} = {speed} m/s',
            hintPattern: 'Use the formula: speed = frequency × wavelength',
            baseDifficulty: 2,
            variables: {
              'frequency': [10, 20, 50],
              'wavelength': [2, 3, 4],
              'speed': [20, 60, 200], // frequency × wavelength
            },
            tags: {'waves', 'physics', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'physics') {
          templates.add(QuestionTemplate(
            id: 'science_physics_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A car accelerates from rest at {acceleration} m/s². How far does it travel in {time} seconds?',
            optionPatterns: [],
            correctAnswerPattern: '{distance}',
            explanationPattern: 'Distance = ½ × acceleration × time² = ½ × {acceleration} × {time}² = {distance} m',
            hintPattern: 'Use the kinematic equation: s = ½at²',
            baseDifficulty: 2,
            variables: {
              'acceleration': [2, 3, 4],
              'time': [5, 6, 8],
              'distance': [25, 54, 128], // ½ × acceleration × time²
            },
            tags: {'kinematics', 'physics', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'physics') {
          templates.add(QuestionTemplate(
            id: 'science_physics_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A ball is thrown upward with an initial velocity of {velocity} m/s. What is the maximum height it reaches? (Use g = 9.8 m/s²)',
            optionPatterns: [],
            correctAnswerPattern: '{height}',
            explanationPattern: 'Maximum height = v²/(2g) = {velocity}²/(2×9.8) = {height} m',
            hintPattern: 'Use the kinematic equation: v² = u² + 2as, where final velocity is 0.',
            baseDifficulty: 3,
            variables: {
              'velocity': [20],
              'height': [20.4], // 20²/(2×9.8) = 400/19.6 ≈ 20.4
            },
            tags: {'kinematics', 'projectile', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'chemistry') {
          templates.add(QuestionTemplate(
            id: 'science_chemistry_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'How many moles of CO₂ are produced when {moles} moles of C₆H₁₂O₆ undergo complete combustion? (C₆H₁₂O₆ + 6O₂ → 6CO₂ + 6H₂O)',
            optionPatterns: [],
            correctAnswerPattern: '{co2Moles}',
            explanationPattern: 'From the balanced equation, 1 mole of glucose produces 6 moles of CO₂. So {moles} moles × 6 = {co2Moles} moles of CO₂.',
            hintPattern: 'Look at the stoichiometric coefficients in the balanced equation.',
            baseDifficulty: 3,
            variables: {
              'moles': [2],
              'co2Moles': [12], // 2 × 6 = 12
            },
            tags: {'stoichiometry', 'combustion', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'physics') {
          templates.add(QuestionTemplate(
            id: 'science_physics_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A car accelerates from rest at {acceleration} m/s² for {time} seconds. What is its final velocity in m/s?',
            optionPatterns: [],
            correctAnswerPattern: '{finalVelocity}',
            explanationPattern: 'Using v = u + at, where u = 0 (starts from rest), a = {acceleration} m/s², t = {time} s. So v = 0 + {acceleration} × {time} = {finalVelocity} m/s.',
            hintPattern: 'Use the equation v = u + at, where u is initial velocity.',
            baseDifficulty: 2,
            variables: {
              'acceleration': [5],
              'time': [4],
              'finalVelocity': [20], // 5 × 4 = 20
            },
            tags: {'kinematics', 'acceleration', 'numeric_input'},
          ));
        }
        break;

      case SubjectType.science:
        if (skillId == 'physics') {
          templates.add(QuestionTemplate(
            id: 'science_physics_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A ball is thrown upward with an initial velocity of {velocity} m/s. What is the maximum height it reaches? (Use g = 9.8 m/s²)',
            optionPatterns: [],
            correctAnswerPattern: '{height}',
            explanationPattern: 'Using v² = u² + 2as, at maximum height v = 0, so 0 = {velocity}² - 2(9.8)h, therefore h = {velocity}²/(2×9.8) = {height} m',
            hintPattern: 'Use the kinematic equation v² = u² + 2as where final velocity is zero at maximum height.',
            baseDifficulty: 3,
            variables: {
              'velocity': [20],
              'height': [20.4], // 20²/(2×9.8) ≈ 20.4
            },
            tags: {'physics', 'kinematics', 'numeric_input'},
          ));
        }
        break;

      case SubjectType.science:
        if (skillId == 'chemistry') {
          templates.add(QuestionTemplate(
            id: 'science_chemistry_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'How many moles of water (H₂O) are produced when {moles} moles of hydrogen gas react completely with oxygen gas?',
            optionPatterns: [],
            correctAnswerPattern: '{waterMoles}',
            explanationPattern: 'From the balanced equation 2H₂ + O₂ → 2H₂O, 2 moles of H₂ produce 2 moles of H₂O. So {moles} moles of H₂ produce {waterMoles} moles of H₂O.',
            hintPattern: 'Use the balanced chemical equation to find the mole ratio.',
            baseDifficulty: 3,
            variables: {
              'moles': [4],
              'waterMoles': [4], // 1:1 ratio from balanced equation
            },
            tags: {'chemistry', 'stoichiometry', 'numeric_input'},
          ));
        }
        break;

      case SubjectType.science:
        if (skillId == 'biology') {
          templates.add(QuestionTemplate(
            id: 'science_biology_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'If a cell divides every {hours} hours, how many cells will there be after {totalHours} hours starting with 1 cell?',
            optionPatterns: [],
            correctAnswerPattern: '{finalCells}',
            explanationPattern: 'Cell division follows exponential growth: Final cells = Initial cells × 2^(time/division_time) = 1 × 2^({totalHours}/{hours}) = {finalCells}',
            hintPattern: 'Use the exponential growth formula for cell division.',
            baseDifficulty: 3,
            variables: {
              'hours': [2],
              'totalHours': [6],
              'finalCells': [8], // 2^(6/2) = 2^3 = 8
            },
            tags: {'biology', 'cell_division', 'numeric_input'},
          ));
        }
        break;

      case SubjectType.science:
        if (skillId == 'physics') {
          templates.add(QuestionTemplate(
            id: 'science_physics_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A car accelerates from rest at 2 m/s². What is its velocity after 5 seconds?',
            optionPatterns: [],
            correctAnswerPattern: '10',
            explanationPattern: 'Using v = u + at, where u = 0, a = 2 m/s², t = 5s: v = 0 + (2)(5) = 10 m/s',
            hintPattern: 'Use the equation v = u + at',
            baseDifficulty: 3,
            variables: {},
            tags: {'kinematics', 'acceleration', 'numeric_input'},
          ));
        }
        break;

      case SubjectType.biology:
        if (skillId == 'cells') {
          templates.add(QuestionTemplate(
            id: 'biology_cells_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the cell organelles with their functions:',
            optionPatterns: [
              'LEFT:Nucleus|Mitochondria|Ribosomes|Chloroplasts',
              'RIGHT:Protein synthesis|Energy production|Controls cell activities|Photosynthesis',
            ],
            correctAnswerPattern: 'Nucleus:Controls cell activities;Mitochondria:Energy production;Ribosomes:Protein synthesis;Chloroplasts:Photosynthesis',
            explanationPattern: 'Each organelle has a specific function within the cell.',
            hintPattern: 'Think about what each organelle does in the cell.',
            baseDifficulty: 2,
            variables: {},
            tags: {'cells', 'organelles', 'drag_drop'},
          ));
        }
        break;

      case SubjectType.science:
        if (skillId == 'chemistry') {
          templates.add(QuestionTemplate(
            id: 'science_chemistry_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'How many moles of CO₂ are produced when 2 moles of CH₄ react completely with oxygen?',
            optionPatterns: [],
            correctAnswerPattern: '2',
            explanationPattern: 'From the balanced equation CH₄ + 2O₂ → CO₂ + 2H₂O, 1 mole of CH₄ produces 1 mole of CO₂. Therefore, 2 moles of CH₄ produce 2 moles of CO₂.',
            hintPattern: 'Use the balanced chemical equation for methane combustion.',
            baseDifficulty: 3,
            variables: {},
            tags: {'stoichiometry', 'combustion', 'numeric_input'},
          ));
        }
        break;

      case SubjectType.biology:
        if (skillId == 'genetics') {
          templates.add(QuestionTemplate(
            id: 'biology_genetics_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the genetic terms with their definitions:',
            optionPatterns: [
              'LEFT:Genotype|Phenotype|Allele|Chromosome',
              'RIGHT:Observable traits|Genetic makeup|Alternative gene form|DNA structure',
            ],
            correctAnswerPattern: 'Genotype:Genetic makeup;Phenotype:Observable traits;Allele:Alternative gene form;Chromosome:DNA structure',
            explanationPattern: 'Each genetic term has a specific meaning in heredity.',
            hintPattern: 'Think about what each term represents in genetics.',
            baseDifficulty: 2,
            variables: {},
            tags: {'genetics', 'heredity', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'physics') {
          templates.add(QuestionTemplate(
            id: 'science_physics_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A wave has a frequency of {frequency} Hz and a wavelength of {wavelength} m. What is its speed in m/s?',
            optionPatterns: [],
            correctAnswerPattern: '{speed}',
            explanationPattern: 'Wave speed = frequency × wavelength = {frequency} × {wavelength} = {speed} m/s',
            hintPattern: 'Use the formula: speed = frequency × wavelength',
            baseDifficulty: 2,
            variables: {
              'frequency': [10, 20, 50, 100, 200],
              'wavelength': [2, 5, 10, 15, 20],
              'speed': [], // Will be calculated as frequency * wavelength
            },
            tags: {'physics', 'waves', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'genetics') {
          templates.add(QuestionTemplate(
            id: 'biology_genetics_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the genetic terms with their definitions:',
            optionPatterns: [
              'LEFT:Allele|Genotype|Phenotype|Chromosome',
              'RIGHT:Observable traits|Genetic makeup|DNA structure containing genes|Alternative form of a gene',
            ],
            correctAnswerPattern: 'Allele:Alternative form of a gene;Genotype:Genetic makeup;Phenotype:Observable traits;Chromosome:DNA structure containing genes',
            explanationPattern: 'Each genetic term has a specific meaning in heredity and genetics.',
            hintPattern: 'Think about what each term describes in genetics.',
            baseDifficulty: 2,
            variables: {},
            tags: {'genetics', 'heredity', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'physics') {
          templates.add(QuestionTemplate(
            id: 'science_physics_ni_${category.name}_2',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'An object falls from rest for {time} seconds. How far does it fall? (Use g = 9.8 m/s²)',
            optionPatterns: [],
            correctAnswerPattern: '{distance}',
            explanationPattern: 'Distance = ½gt² = ½ × 9.8 × {time}² = {distance} m',
            hintPattern: 'Use the formula: d = ½gt²',
            baseDifficulty: 2,
            variables: {
              'time': [1, 2, 3, 4, 5],
              'distance': [], // Will be calculated as 0.5 * 9.8 * time²
            },
            tags: {'physics', 'kinematics', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'ecology') {
          templates.add(QuestionTemplate(
            id: 'biology_ecology_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the ecological terms with their definitions:',
            optionPatterns: [
              'LEFT:Producer|Consumer|Decomposer|Habitat',
              'RIGHT:Where an organism lives|Breaks down dead matter|Eats other organisms|Makes its own food',
            ],
            correctAnswerPattern: 'Producer:Makes its own food;Consumer:Eats other organisms;Decomposer:Breaks down dead matter;Habitat:Where an organism lives',
            explanationPattern: 'Each ecological role has a specific function in the ecosystem.',
            hintPattern: 'Think about what each organism does in nature.',
            baseDifficulty: 2,
            variables: {},
            tags: {'ecology', 'ecosystem', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'chemistry') {
          templates.add(QuestionTemplate(
            id: 'science_chemistry_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'How many moles of H₂O are produced when {moles} moles of H₂ react with excess O₂? (2H₂ + O₂ → 2H₂O)',
            optionPatterns: [],
            correctAnswerPattern: '{result}',
            explanationPattern: 'From the balanced equation, 2 moles H₂ produce 2 moles H₂O. So {moles} moles H₂ produce {result} moles H₂O.',
            hintPattern: 'Use the mole ratio from the balanced chemical equation.',
            baseDifficulty: 2,
            variables: {
              'moles': [1, 2, 3, 4, 5],
              'result': [], // Will be calculated as moles (1:1 ratio)
            },
            tags: {'chemistry', 'stoichiometry', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'cell_biology') {
          templates.add(QuestionTemplate(
            id: 'biology_cell_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the cell organelles with their functions:',
            optionPatterns: [
              'LEFT:Mitochondria|Nucleus|Ribosome|Chloroplast',
              'RIGHT:Controls cell activities|Produces energy|Makes proteins|Performs photosynthesis',
            ],
            correctAnswerPattern: 'Mitochondria:Produces energy;Nucleus:Controls cell activities;Ribosome:Makes proteins;Chloroplast:Performs photosynthesis',
            explanationPattern: 'Each organelle has a specific function that contributes to cell survival.',
            hintPattern: 'Think about what each organelle is known for doing.',
            baseDifficulty: 2,
            variables: {},
            tags: {'cell_biology', 'organelles', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'physics') {
          templates.add(QuestionTemplate(
            id: 'science_physics_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A car accelerates from rest at {acceleration} m/s². What is its velocity after {time} seconds?',
            optionPatterns: [],
            correctAnswerPattern: '{result}',
            explanationPattern: 'Using v = u + at, where u = 0, a = {acceleration} m/s², t = {time} s: v = {result} m/s',
            hintPattern: 'Use the equation v = u + at, where u is initial velocity (0 for rest).',
            baseDifficulty: 2,
            variables: {
              'acceleration': [2, 3, 4, 5],
              'time': [2, 3, 4, 5],
              'result': [], // Will be calculated as acceleration * time
            },
            tags: {'physics', 'kinematics', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'genetics') {
          templates.add(QuestionTemplate(
            id: 'biology_genetics_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the genetic terms with their definitions:',
            optionPatterns: [
              'LEFT:Genotype|Phenotype|Allele|Chromosome',
              'RIGHT:Observable traits|Genetic makeup|Version of a gene|Structure containing DNA',
            ],
            correctAnswerPattern: 'Genotype:Genetic makeup;Phenotype:Observable traits;Allele:Version of a gene;Chromosome:Structure containing DNA',
            explanationPattern: 'Understanding genetic terminology is fundamental to studying heredity.',
            hintPattern: 'Think about what each term represents in genetics.',
            baseDifficulty: 2,
            variables: {},
            tags: {'genetics', 'heredity', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'biology') {
          templates.add(QuestionTemplate(
            id: 'science_biology_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A population of bacteria doubles every {hours} hours. If you start with {initial} bacteria, how many will there be after {time} hours?',
            optionPatterns: [],
            correctAnswerPattern: '{result}',
            explanationPattern: 'Population growth: {initial} × 2^({time}/{hours}) = {result}',
            hintPattern: 'Use exponential growth formula: N = N₀ × 2^(t/doubling_time)',
            baseDifficulty: 3,
            variables: {
              'hours': [2, 3, 4],
              'initial': [100, 200, 500],
              'time': [4, 6, 8],
              'result': [], // Will be calculated as initial * 2^(time/hours)
            },
            tags: {'biology', 'population_growth', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'anatomy') {
          templates.add(QuestionTemplate(
            id: 'biology_anatomy_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the organ systems with their primary functions:',
            optionPatterns: [
              'LEFT:Circulatory system|Respiratory system|Digestive system|Nervous system',
              'RIGHT:Controls body functions|Breaks down food|Transports nutrients|Exchanges gases',
            ],
            correctAnswerPattern: 'Circulatory system:Transports nutrients;Respiratory system:Exchanges gases;Digestive system:Breaks down food;Nervous system:Controls body functions',
            explanationPattern: 'Each organ system has specialized functions that work together to maintain life.',
            hintPattern: 'Think about what each system does for the body.',
            baseDifficulty: 2,
            variables: {},
            tags: {'anatomy', 'organ_systems', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'chemistry') {
          templates.add(QuestionTemplate(
            id: 'science_chemistry_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'Calculate the molarity of a solution containing {moles} moles of solute in {volume} L of solution.',
            optionPatterns: [],
            correctAnswerPattern: '{result}',
            explanationPattern: 'Molarity = moles of solute / liters of solution = {moles} / {volume} = {result} M',
            hintPattern: 'Use the formula: M = n/V where M is molarity, n is moles, and V is volume in liters.',
            baseDifficulty: 3,
            variables: {
              'moles': [0.5, 1.0, 1.5, 2.0, 2.5],
              'volume': [0.5, 1.0, 2.0, 2.5, 5.0],
              'result': [], // Will be calculated as moles/volume
            },
            tags: {'chemistry', 'molarity', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'ecology') {
          templates.add(QuestionTemplate(
            id: 'biology_ecology_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the ecological terms with their definitions:',
            optionPatterns: [
              'LEFT:Producer|Primary consumer|Secondary consumer|Decomposer',
              'RIGHT:Breaks down dead organisms|Eats plants|Makes its own food|Eats other animals',
            ],
            correctAnswerPattern: 'Producer:Makes its own food;Primary consumer:Eats plants;Secondary consumer:Eats other animals;Decomposer:Breaks down dead organisms',
            explanationPattern: 'Each organism in an ecosystem has a specific role in the food chain.',
            hintPattern: 'Think about what each organism eats or how it gets energy.',
            baseDifficulty: 2,
            variables: {},
            tags: {'ecology', 'food_chain', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'physics') {
          templates.add(QuestionTemplate(
            id: 'science_physics_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A car accelerates from rest at {acceleration} m/s² for {time} seconds. What is its final velocity?',
            optionPatterns: [],
            correctAnswerPattern: '{result}',
            explanationPattern: 'Using v = u + at, where u = 0: v = 0 + {acceleration} × {time} = {result} m/s',
            hintPattern: 'Use the kinematic equation: v = u + at (where u = 0 for starting from rest)',
            baseDifficulty: 2,
            variables: {
              'acceleration': [2, 3, 4, 5],
              'time': [2, 3, 4, 5, 6],
              'result': [], // Will be calculated as acceleration * time
            },
            tags: {'physics', 'kinematics', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'genetics') {
          templates.add(QuestionTemplate(
            id: 'biology_genetics_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the genetic terms with their definitions:',
            optionPatterns: [
              'LEFT:Genotype|Phenotype|Allele|Dominant|Recessive',
              'RIGHT:Observable traits|Genetic makeup|Alternative gene form|Masks other traits|Hidden by dominant',
            ],
            correctAnswerPattern: 'Genotype:Genetic makeup;Phenotype:Observable traits;Allele:Alternative gene form;Dominant:Masks other traits;Recessive:Hidden by dominant',
            explanationPattern: 'Understanding genetic terminology is fundamental to studying heredity.',
            hintPattern: 'Think about what each term describes in genetics.',
            baseDifficulty: 2,
            variables: {},
            tags: {'genetics', 'heredity', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'chemistry') {
          templates.add(QuestionTemplate(
            id: 'science_chemistry_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'Calculate the molar mass of H₂SO₄ (sulfuric acid). Use atomic masses: H = 1, S = 32, O = 16.',
            optionPatterns: [],
            correctAnswerPattern: '{result}',
            explanationPattern: 'H₂SO₄ = 2(1) + 1(32) + 4(16) = 2 + 32 + 64 = {result} g/mol',
            hintPattern: 'Add up the atomic masses: 2 hydrogen + 1 sulfur + 4 oxygen atoms.',
            baseDifficulty: 2,
            variables: {
              'result': [98], // 2(1) + 32 + 4(16) = 98
            },
            tags: {'chemistry', 'molar_mass', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'cell_biology') {
          templates.add(QuestionTemplate(
            id: 'biology_cell_biology_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the cell organelles with their functions:',
            optionPatterns: [
              'LEFT:Nucleus|Mitochondria|Ribosomes|Chloroplasts|Vacuole',
              'RIGHT:Protein synthesis|Energy production|Controls cell activities|Photosynthesis|Storage and support',
            ],
            correctAnswerPattern: 'Nucleus:Controls cell activities;Mitochondria:Energy production;Ribosomes:Protein synthesis;Chloroplasts:Photosynthesis;Vacuole:Storage and support',
            explanationPattern: 'Each organelle has a specific function that contributes to cell survival.',
            hintPattern: 'Think about what each organelle does for the cell.',
            baseDifficulty: 2,
            variables: {},
            tags: {'cell_biology', 'organelles', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'chemistry') {
          templates.add(QuestionTemplate(
            id: 'science_chemistry_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'Calculate the number of moles in {mass}g of {compound}. (Molar mass = {molar_mass} g/mol)',
            optionPatterns: [],
            correctAnswerPattern: '{moles}',
            explanationPattern: 'Moles = mass ÷ molar mass = {mass} ÷ {molar_mass} = {moles} mol',
            hintPattern: 'Use the formula: moles = mass ÷ molar mass',
            baseDifficulty: 3,
            variables: {
              'mass': [10, 20, 25, 50, 100],
              'compound': ['H₂O', 'NaCl', 'CO₂', 'CaCO₃'],
              'molar_mass': [18, 58.5, 44, 100],
              'moles': [], // Will be calculated as mass / molar_mass
            },
            tags: {'chemistry', 'moles', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'genetics') {
          templates.add(QuestionTemplate(
            id: 'biology_genetics_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the genetic terms with their definitions:',
            optionPatterns: [
              'LEFT:Genotype|Phenotype|Allele|Chromosome',
              'RIGHT:Observable traits|Genetic makeup|Version of a gene|Structure containing DNA',
            ],
            correctAnswerPattern: 'Genotype:Genetic makeup;Phenotype:Observable traits;Allele:Version of a gene;Chromosome:Structure containing DNA',
            explanationPattern: 'Understanding genetic terminology is fundamental to studying heredity.',
            hintPattern: 'Think about what each term represents in genetics.',
            baseDifficulty: 2,
            variables: {},
            tags: {'genetics', 'heredity', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'physics') {
          templates.add(QuestionTemplate(
            id: 'science_physics_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A car accelerates from rest at {acceleration} m/s² for {time} seconds. What is its final velocity?',
            optionPatterns: [],
            correctAnswerPattern: '{velocity}',
            explanationPattern: 'Using v = u + at, where u = 0: v = 0 + {acceleration} × {time} = {velocity} m/s',
            hintPattern: 'Use the equation v = u + at, where u = 0 (starts from rest)',
            baseDifficulty: 3,
            variables: {
              'acceleration': [2, 3, 4, 5],
              'time': [5, 10, 15, 20],
              'velocity': [], // Will be calculated as acceleration * time
            },
            tags: {'physics', 'kinematics', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'ecology') {
          templates.add(QuestionTemplate(
            id: 'biology_ecology_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the ecological terms with their definitions:',
            optionPatterns: [
              'LEFT:Producer|Primary consumer|Secondary consumer|Decomposer',
              'RIGHT:Breaks down dead organisms|Eats plants|Makes its own food|Eats other animals',
            ],
            correctAnswerPattern: 'Producer:Makes its own food;Primary consumer:Eats plants;Secondary consumer:Eats other animals;Decomposer:Breaks down dead organisms',
            explanationPattern: 'Each organism has a specific role in the food chain and ecosystem.',
            hintPattern: 'Think about what each organism eats or how it gets energy.',
            baseDifficulty: 2,
            variables: {},
            tags: {'ecology', 'food_chain', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'chemistry') {
          templates.add(QuestionTemplate(
            id: 'science_chemistry_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'Calculate the molar mass of H₂O (water). (H = 1 g/mol, O = 16 g/mol)',
            optionPatterns: [],
            correctAnswerPattern: '18',
            explanationPattern: 'H₂O has 2 hydrogen atoms (2 × 1 = 2 g/mol) and 1 oxygen atom (1 × 16 = 16 g/mol). Total: 2 + 16 = 18 g/mol',
            hintPattern: 'Add the atomic masses: 2 hydrogen atoms + 1 oxygen atom',
            baseDifficulty: 2,
            variables: {},
            tags: {'chemistry', 'molar_mass', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'genetics') {
          templates.add(QuestionTemplate(
            id: 'biology_genetics_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the genetic terms with their definitions:',
            optionPatterns: [
              'LEFT:Genotype|Phenotype|Allele|Chromosome',
              'RIGHT:Physical appearance|Genetic makeup|Version of a gene|Structure containing DNA',
            ],
            correctAnswerPattern: 'Genotype:Genetic makeup;Phenotype:Physical appearance;Allele:Version of a gene;Chromosome:Structure containing DNA',
            explanationPattern: 'Each genetic term describes a different aspect of heredity and DNA organization.',
            hintPattern: 'Think about what each term represents in genetics.',
            baseDifficulty: 2,
            variables: {},
            tags: {'genetics', 'heredity', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'chemistry') {
          templates.add(QuestionTemplate(
            id: 'science_chemistry_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'Calculate the number of moles in {mass}g of NaCl (molar mass = 58.44 g/mol):',
            optionPatterns: [],
            correctAnswerPattern: '{moles}',
            explanationPattern: 'Moles = mass ÷ molar mass = {mass} ÷ 58.44 = {moles} mol',
            hintPattern: 'Use the formula: moles = mass ÷ molar mass',
            baseDifficulty: 2,
            variables: {
              'mass': [58.44, 116.88, 175.32, 233.76],
              'moles': [1.0, 2.0, 3.0, 4.0],
            },
            tags: {'chemistry', 'moles', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'cell_biology') {
          templates.add(QuestionTemplate(
            id: 'biology_cell_biology_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the cell organelles with their functions:',
            optionPatterns: [
              'LEFT:Nucleus|Mitochondria|Ribosome|Chloroplast',
              'RIGHT:Protein synthesis|Controls cell activities|Produces energy|Photosynthesis',
            ],
            correctAnswerPattern: 'Nucleus:Controls cell activities;Mitochondria:Produces energy;Ribosome:Protein synthesis;Chloroplast:Photosynthesis',
            explanationPattern: 'Each organelle has a specific function that helps the cell survive and function.',
            hintPattern: 'Think about what each organelle does inside the cell.',
            baseDifficulty: 2,
            variables: {},
            tags: {'cell_biology', 'organelles', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'physics') {
          templates.add(QuestionTemplate(
            id: 'science_physics_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'Calculate the velocity of an object that travels {distance}m in {time}s:',
            optionPatterns: [],
            correctAnswerPattern: '{velocity}',
            explanationPattern: 'Velocity = distance ÷ time = {distance} ÷ {time} = {velocity} m/s',
            hintPattern: 'Use the formula: velocity = distance ÷ time',
            baseDifficulty: 2,
            variables: {
              'distance': [10, 20, 30, 40, 50],
              'time': [2, 4, 5, 8, 10],
              'velocity': [5, 5, 6, 5, 5],
            },
            tags: {'physics', 'velocity', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'ecology') {
          templates.add(QuestionTemplate(
            id: 'biology_ecology_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the ecosystem components with their roles:',
            optionPatterns: [
              'LEFT:Producer|Primary Consumer|Secondary Consumer|Decomposer',
              'RIGHT:Eats plants|Makes food from sunlight|Eats other animals|Breaks down dead matter',
            ],
            correctAnswerPattern: 'Producer:Makes food from sunlight;Primary Consumer:Eats plants;Secondary Consumer:Eats other animals;Decomposer:Breaks down dead matter',
            explanationPattern: 'Each organism in an ecosystem has a specific role in the food chain.',
            hintPattern: 'Think about what each organism does in the ecosystem.',
            baseDifficulty: 2,
            variables: {},
            tags: {'ecology', 'food_chain', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'physics') {
          templates.add(QuestionTemplate(
            id: 'science_physics_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'Calculate the force: F = ma, where m = {mass} kg and a = {acceleration} m/s²',
            optionPatterns: [],
            correctAnswerPattern: '{force}',
            explanationPattern: 'Force = mass × acceleration = {mass} × {acceleration} = {force} N',
            hintPattern: 'Use Newton\'s second law: F = ma',
            baseDifficulty: 2,
            variables: {
              'mass': [2, 3, 4, 5, 6, 8, 10],
              'acceleration': [2, 3, 4, 5, 6, 8, 10],
              'force': [], // Will be calculated as mass * acceleration
            },
            tags: {'physics', 'force', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'genetics') {
          templates.add(QuestionTemplate(
            id: 'biology_genetics_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the genetic terms with their definitions:',
            optionPatterns: [
              'LEFT:Genotype|Phenotype|Allele|Dominant',
              'RIGHT:Observable traits|Genetic makeup|Version of a gene|Expressed trait',
            ],
            correctAnswerPattern: 'Genotype:Genetic makeup;Phenotype:Observable traits;Allele:Version of a gene;Dominant:Expressed trait',
            explanationPattern: 'These are fundamental concepts in genetics that describe inheritance patterns.',
            hintPattern: 'Think about what each term represents in genetics.',
            baseDifficulty: 2,
            variables: {},
            tags: {'genetics', 'inheritance', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'chemistry') {
          templates.add(QuestionTemplate(
            id: 'science_chemistry_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'Calculate the molar mass of CO₂ (C = 12, O = 16)',
            optionPatterns: [],
            correctAnswerPattern: '44',
            explanationPattern: 'Molar mass of CO₂ = 12 + (16 × 2) = 12 + 32 = 44 g/mol',
            hintPattern: 'Add the atomic masses: C + 2O',
            baseDifficulty: 2,
            variables: {},
            tags: {'chemistry', 'molar_mass', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'cell_biology') {
          templates.add(QuestionTemplate(
            id: 'biology_cell_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the cell organelles with their functions:',
            optionPatterns: [
              'LEFT:Nucleus|Mitochondria|Ribosome|Chloroplast',
              'RIGHT:Protein synthesis|Controls cell|Energy production|Photosynthesis',
            ],
            correctAnswerPattern: 'Nucleus:Controls cell;Mitochondria:Energy production;Ribosome:Protein synthesis;Chloroplast:Photosynthesis',
            explanationPattern: 'Each organelle has a specific function that helps the cell survive and function.',
            hintPattern: 'Think about what each organelle does in the cell.',
            baseDifficulty: 2,
            variables: {},
            tags: {'cell_biology', 'organelles', 'drag_drop'},
          ));
        }
        break;

      case SubjectType.science:
        if (skillId == 'physics') {
          templates.add(QuestionTemplate(
            id: 'science_physics_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A car travels at {speed} m/s for {time} seconds. How far does it travel in meters?',
            optionPatterns: [],
            correctAnswerPattern: '{distance}',
            explanationPattern: 'Distance = Speed × Time = {speed} × {time} = {distance} meters',
            hintPattern: 'Use the formula: Distance = Speed × Time',
            baseDifficulty: 2,
            variables: {
              'speed': [10, 15, 20, 25],
              'time': [5, 8, 10, 12],
              'distance': [], // Will be calculated as speed * time
            },
            tags: {'physics', 'motion', 'numeric_input'},
          ));
        }
        break;

      case SubjectType.science:
        if (skillId == 'chemistry') {
          templates.add(QuestionTemplate(
            id: 'science_chemistry_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'Calculate the molar mass of H₂SO₄ (H=1, S=32, O=16). What is the molar mass in g/mol?',
            optionPatterns: [],
            correctAnswerPattern: '98',
            explanationPattern: 'Molar mass = (2×1) + (1×32) + (4×16) = 2 + 32 + 64 = 98 g/mol',
            hintPattern: 'Add up the atomic masses: 2 hydrogen + 1 sulfur + 4 oxygen atoms.',
            baseDifficulty: 2,
            variables: {},
            tags: {'chemistry', 'molar_mass', 'numeric_input'},
          ));
        }
        break;

      case SubjectType.biology:
        if (skillId == 'ecology') {
          templates.add(QuestionTemplate(
            id: 'biology_ecology_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the ecological terms with their definitions:',
            optionPatterns: [
              'LEFT:Producer|Primary consumer|Secondary consumer|Decomposer',
              'RIGHT:Breaks down dead organisms|Eats plants only|Makes its own food|Eats primary consumers',
            ],
            correctAnswerPattern: 'Producer:Makes its own food;Primary consumer:Eats plants only;Secondary consumer:Eats primary consumers;Decomposer:Breaks down dead organisms',
            explanationPattern: 'Each organism has a specific role in the food chain and ecosystem.',
            hintPattern: 'Think about what each organism eats or how it gets energy.',
            baseDifficulty: 2,
            variables: {},
            tags: {'ecology', 'food_chain', 'drag_drop'},
          ));
        }
        break;

    }
    
    return templates;
  }

  /// Generate true/false templates
  List<QuestionTemplate> _generateTrueFalseTemplates(
    SubjectType subject, String skillId, QuestionCategory category
  ) {
    final templates = <QuestionTemplate>[];
    
    switch (subject) {
      case SubjectType.math:
        if (skillId == 'algebra') {
          templates.add(QuestionTemplate(
            id: 'math_algebra_tf_${category.name}_1',
            type: QuestionType.trueFalse,
            category: category,
            questionPattern: 'True or False: In the equation x + 5 = 10, x equals 5.',
            optionPatterns: ['True', 'False'],
            correctAnswerPattern: 'True',
            explanationPattern: 'x + 5 = 10, so x = 10 - 5 = 5. The statement is true.',
            hintPattern: 'Solve for x by subtracting 5 from both sides.',
            baseDifficulty: 1,
            variables: {},
            tags: {'algebra', 'equations', 'true_false'},
          ));
        }
        break;
      case SubjectType.physics:
        if (skillId == 'mechanics') {
          templates.add(QuestionTemplate(
            id: 'physics_mechanics_tf_${category.name}_1',
            type: QuestionType.trueFalse,
            category: category,
            questionPattern: 'True or False: Force equals mass times acceleration.',
            optionPatterns: ['True', 'False'],
            correctAnswerPattern: 'True',
            explanationPattern: 'Newton\'s second law states that F = ma (Force = mass × acceleration).',
            hintPattern: 'Think about Newton\'s second law of motion.',
            baseDifficulty: 2,
            variables: {},
            tags: {'mechanics', 'force', 'true_false'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'atoms') {
          templates.add(QuestionTemplate(
            id: 'chemistry_atoms_tf_${category.name}_1',
            type: QuestionType.trueFalse,
            category: category,
            questionPattern: 'True or False: Atoms are the smallest particles of matter.',
            optionPatterns: ['True', 'False'],
            correctAnswerPattern: 'False',
            explanationPattern: 'Atoms are made up of smaller particles: protons, neutrons, and electrons.',
            hintPattern: 'Think about what makes up an atom.',
            baseDifficulty: 2,
            variables: {},
            tags: {'atoms', 'particles', 'true_false'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'cells') {
          templates.add(QuestionTemplate(
            id: 'biology_cells_tf_${category.name}_1',
            type: QuestionType.trueFalse,
            category: category,
            questionPattern: 'True or False: All cells have a nucleus.',
            optionPatterns: ['True', 'False'],
            correctAnswerPattern: 'False',
            explanationPattern: 'Prokaryotic cells (like bacteria) do not have a nucleus, while eukaryotic cells do.',
            hintPattern: 'Think about the difference between prokaryotic and eukaryotic cells.',
            baseDifficulty: 2,
            variables: {},
            tags: {'cells', 'nucleus', 'true_false'},
          ));
        }
        break;
      case SubjectType.computerScience:
        if (skillId == 'algorithms') {
          templates.add(QuestionTemplate(
            id: 'cs_algorithms_tf_${category.name}_1',
            type: QuestionType.trueFalse,
            category: category,
            questionPattern: 'True or False: Binary search has O(log n) time complexity.',
            optionPatterns: ['True', 'False'],
            correctAnswerPattern: 'True',
            explanationPattern: 'Binary search divides the search space in half with each comparison, resulting in O(log n) complexity.',
            hintPattern: 'Think about how binary search works.',
            baseDifficulty: 3,
            variables: {},
            tags: {'algorithms', 'complexity', 'true_false'},
          ));
        }
        break;
      case SubjectType.geography:
        if (skillId == 'landforms') {
          templates.add(QuestionTemplate(
            id: 'geography_landforms_tf_${category.name}_1',
            type: QuestionType.trueFalse,
            category: category,
            questionPattern: 'True or False: Mountains are formed only by volcanic activity.',
            optionPatterns: ['True', 'False'],
            correctAnswerPattern: 'False',
            explanationPattern: 'Mountains can be formed by tectonic plate movement, folding, faulting, and volcanic activity.',
            hintPattern: 'Think about different ways mountains can form.',
            baseDifficulty: 2,
            variables: {},
            tags: {'landforms', 'mountains', 'true_false'},
          ));
        }
        break;
      case SubjectType.history:
        if (skillId == 'mesopotamia') {
          templates.add(QuestionTemplate(
            id: 'history_mesopotamia_tf_${category.name}_1',
            type: QuestionType.trueFalse,
            category: category,
            questionPattern: 'True or False: Mesopotamia is known as the cradle of civilization.',
            optionPatterns: ['True', 'False'],
            correctAnswerPattern: 'True',
            explanationPattern: 'Mesopotamia is often called the cradle of civilization because it was one of the first places where complex societies developed.',
            hintPattern: 'Think about early human civilizations.',
            baseDifficulty: 2,
            variables: {},
            tags: {'mesopotamia', 'civilization', 'true_false'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_method_tf_${category.name}_1',
            type: QuestionType.trueFalse,
            category: category,
            questionPattern: 'True or False: A hypothesis must be testable.',
            optionPatterns: ['True', 'False'],
            correctAnswerPattern: 'True',
            explanationPattern: 'A hypothesis must be testable through experiments or observations.',
            hintPattern: 'Think about what makes a good scientific hypothesis.',
            baseDifficulty: 2,
            variables: {},
            tags: {'scientific_method', 'hypothesis', 'true_false'},
          ));
        }
        break;
      case SubjectType.english:
        if (skillId == 'grammar') {
          templates.add(QuestionTemplate(
            id: 'english_grammar_tf_${category.name}_1',
            type: QuestionType.trueFalse,
            category: category,
            questionPattern: 'True or False: A noun is a person, place, or thing.',
            optionPatterns: ['True', 'False'],
            correctAnswerPattern: 'True',
            explanationPattern: 'A noun is indeed a word that represents a person, place, thing, or idea.',
            hintPattern: 'Think about what nouns represent.',
            baseDifficulty: 1,
            variables: {},
            tags: {'grammar', 'noun', 'true_false'},
          ));
        }
        break;
      case SubjectType.art:
        if (skillId == 'color_theory') {
          templates.add(QuestionTemplate(
            id: 'art_color_tf_${category.name}_1',
            type: QuestionType.trueFalse,
            category: category,
            questionPattern: 'True or False: Red, blue, and yellow are primary colors.',
            optionPatterns: ['True', 'False'],
            correctAnswerPattern: 'True',
            explanationPattern: 'Red, blue, and yellow are the three primary colors that cannot be created by mixing other colors.',
            hintPattern: 'Think about colors that cannot be mixed from others.',
            baseDifficulty: 1,
            variables: {},
            tags: {'color_theory', 'primary_colors', 'true_false'},
          ));
        }
        break;
      case SubjectType.music:
        if (skillId == 'notes') {
          templates.add(QuestionTemplate(
            id: 'music_notes_tf_${category.name}_1',
            type: QuestionType.trueFalse,
            category: category,
            questionPattern: 'True or False: There are seven notes in a major scale.',
            optionPatterns: ['True', 'False'],
            correctAnswerPattern: 'True',
            explanationPattern: 'A major scale contains seven different notes before repeating at the octave.',
            hintPattern: 'Think about the do-re-mi scale.',
            baseDifficulty: 2,
            variables: {},
            tags: {'notes', 'scale', 'true_false'},
          ));
        }
        break;
      case SubjectType.physicalEducation:
        if (skillId == 'fitness') {
          templates.add(QuestionTemplate(
            id: 'pe_fitness_tf_${category.name}_1',
            type: QuestionType.trueFalse,
            category: category,
            questionPattern: 'True or False: Regular exercise improves cardiovascular health.',
            optionPatterns: ['True', 'False'],
            correctAnswerPattern: 'True',
            explanationPattern: 'Regular exercise strengthens the heart and improves circulation.',
            hintPattern: 'Think about the benefits of exercise on the heart.',
            baseDifficulty: 1,
            variables: {},
            tags: {'fitness', 'cardiovascular', 'true_false'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_table_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match each chemical element with its symbol:',
            optionPatterns: [
              'Hydrogen',
              'Oxygen',
              'Carbon',
              'Nitrogen',
              'H',
              'O',
              'C',
              'N'
            ],
            correctAnswerPattern: 'Hydrogen:H;Oxygen:O;Carbon:C;Nitrogen:N',
            explanationPattern: 'Each element has a unique chemical symbol.',
            hintPattern: 'Think about the first letter(s) of each element name.',
            baseDifficulty: 1,
            variables: {},
            tags: {'periodic_table', 'elements', 'drag_drop'},
          ));
        }
        break;
      
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their symbols:',
            optionPatterns: [
              'LEFT:Hydrogen|Helium|Carbon|Oxygen|Sodium|Chlorine',
              'RIGHT:H|He|C|O|Na|Cl',
            ],
            correctAnswerPattern: 'Hydrogen:H;Helium:He;Carbon:C;Oxygen:O;Sodium:Na;Chlorine:Cl',
            explanationPattern: 'Each chemical element has a unique symbol, often derived from its English or Latin name.',
            hintPattern: 'Some symbols come from Latin names (Na for Natrium, Cl for Chlorum).',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'elements', 'drag_drop'},
          ));
        }
        break;
      
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their symbols:',
            optionPatterns: [
              'LEFT:Hydrogen|Helium|Carbon|Oxygen|Sodium|Chlorine',
              'RIGHT:H|He|C|O|Na|Cl',
            ],
            correctAnswerPattern: 'Hydrogen:H;Helium:He;Carbon:C;Oxygen:O;Sodium:Na;Chlorine:Cl',
            explanationPattern: 'Each chemical element has a unique symbol, often derived from its English or Latin name.',
            hintPattern: 'Some symbols come from Latin names (Na for Natrium, Cl for Chlorum).',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'elements', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_table_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their symbols:',
            optionPatterns: [
              'LEFT:Hydrogen|Helium|Carbon|Oxygen',
              'RIGHT:H|He|C|O',
            ],
            correctAnswerPattern: 'Hydrogen:H;Helium:He;Carbon:C;Oxygen:O',
            explanationPattern: 'Each element has a unique chemical symbol.',
            hintPattern: 'Think about the first letter(s) of each element name.',
            baseDifficulty: 1,
            variables: {},
            tags: {'periodic_table', 'symbols', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_table_dd_${category.name}_2',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Drag the chemical symbols to match their elements:',
            optionPatterns: [
              'H - Hydrogen',
              'He - Helium',
              'Li - Lithium',
              'Be - Beryllium',
            ],
            correctAnswerPattern: 'H - Hydrogen, He - Helium, Li - Lithium, Be - Beryllium',
            explanationPattern: 'These are the first four elements on the periodic table with their chemical symbols.',
            hintPattern: 'Remember the order of elements on the periodic table.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'elements', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_scientific_method_fib_${category.name}_3',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'A ___ is a testable explanation for a scientific observation.',
            optionPatterns: [],
            correctAnswerPattern: 'hypothesis',
            explanationPattern: 'A hypothesis is a proposed explanation that can be tested through experiments.',
            hintPattern: 'This is what scientists test in their experiments.',
            baseDifficulty: 2,
            variables: {},
            tags: {'scientific_method', 'hypothesis', 'fill_blank'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_table_dd_${category.name}_3',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their atomic numbers:',
            optionPatterns: [
              'LEFT:Hydrogen|Helium|Lithium|Beryllium',
              'RIGHT:1|2|3|4',
            ],
            correctAnswerPattern: 'Hydrogen:1;Helium:2;Lithium:3;Beryllium:4',
            explanationPattern: 'These are the first four elements on the periodic table with their atomic numbers.',
            hintPattern: 'Remember the order of elements on the periodic table.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'atomic_numbers', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'The chemical symbol for gold is ___.',
            optionPatterns: [],
            correctAnswerPattern: 'Au',
            explanationPattern: 'Gold\'s chemical symbol is Au, derived from the Latin word "aurum".',
            hintPattern: 'Think about the Latin name for gold.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'elements', 'fill_blank'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their atomic numbers:',
            optionPatterns: [
              'LEFT:Hydrogen|Carbon|Oxygen|Nitrogen',
              'RIGHT:1|6|8|7',
            ],
            correctAnswerPattern: 'Hydrogen:1;Carbon:6;Oxygen:8;Nitrogen:7',
            explanationPattern: 'Each element has a unique atomic number representing the number of protons.',
            hintPattern: 'Think about the position of elements in the periodic table.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'atomic_numbers', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their atomic numbers:',
            optionPatterns: [
              'LEFT:Hydrogen|Carbon|Oxygen|Nitrogen',
              'RIGHT:1|6|8|7',
            ],
            correctAnswerPattern: 'Hydrogen:1;Carbon:6;Oxygen:8;Nitrogen:7',
            explanationPattern: 'Each element has a unique atomic number representing the number of protons.',
            hintPattern: 'Think about the position of elements in the periodic table.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'atomic_numbers', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'The chemical symbol for gold is ___.',
            optionPatterns: [],
            correctAnswerPattern: 'Au',
            explanationPattern: 'Gold\'s chemical symbol is Au, derived from the Latin word "aurum".',
            hintPattern: 'Think about the Latin name for gold.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'elements', 'fill_blank'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their atomic numbers:',
            optionPatterns: [
              'LEFT:Hydrogen|Carbon|Oxygen|Nitrogen',
              'RIGHT:1|6|8|7',
            ],
            correctAnswerPattern: 'Hydrogen:1;Carbon:6;Oxygen:8;Nitrogen:7',
            explanationPattern: 'Each element has a unique atomic number representing the number of protons.',
            hintPattern: 'Think about the position of elements in the periodic table.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'atomic_numbers', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their atomic numbers:',
            optionPatterns: [
              'LEFT:Hydrogen|Carbon|Oxygen|Nitrogen',
              'RIGHT:1|6|8|7',
            ],
            correctAnswerPattern: 'Hydrogen:1;Carbon:6;Oxygen:8;Nitrogen:7',
            explanationPattern: 'Each element has a unique atomic number representing the number of protons.',
            hintPattern: 'Think about the position of elements in the periodic table.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'atomic_numbers', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their atomic numbers:',
            optionPatterns: [
              'LEFT:Hydrogen|Carbon|Oxygen|Nitrogen',
              'RIGHT:1|6|8|7',
            ],
            correctAnswerPattern: 'Hydrogen:1;Carbon:6;Oxygen:8;Nitrogen:7',
            explanationPattern: 'Each element has a unique atomic number representing the number of protons.',
            hintPattern: 'Think about the position of elements in the periodic table.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'atomic_numbers', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their atomic numbers:',
            optionPatterns: [
              'LEFT:Hydrogen|Carbon|Oxygen|Nitrogen',
              'RIGHT:1|6|8|7',
            ],
            correctAnswerPattern: 'Hydrogen:1;Carbon:6;Oxygen:8;Nitrogen:7',
            explanationPattern: 'Each element has a unique atomic number representing the number of protons.',
            hintPattern: 'Think about the position of elements in the periodic table.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'atomic_numbers', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their atomic numbers:',
            optionPatterns: [
              'LEFT:Hydrogen|Carbon|Oxygen|Nitrogen',
              'RIGHT:1|6|8|7',
            ],
            correctAnswerPattern: 'Hydrogen:1;Carbon:6;Oxygen:8;Nitrogen:7',
            explanationPattern: 'Each element has a unique atomic number representing the number of protons.',
            hintPattern: 'Think about the position of elements in the periodic table.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'atomic_numbers', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their atomic numbers:',
            optionPatterns: [
              'LEFT:Hydrogen|Carbon|Oxygen|Nitrogen',
              'RIGHT:1|6|8|7',
            ],
            correctAnswerPattern: 'Hydrogen:1;Carbon:6;Oxygen:8;Nitrogen:7',
            explanationPattern: 'Each element has a unique atomic number representing the number of protons.',
            hintPattern: 'Think about the position of elements in the periodic table.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'atomic_numbers', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their atomic numbers:',
            optionPatterns: [
              'LEFT:Hydrogen|Carbon|Oxygen|Nitrogen',
              'RIGHT:1|6|8|7',
            ],
            correctAnswerPattern: 'Hydrogen:1;Carbon:6;Oxygen:8;Nitrogen:7',
            explanationPattern: 'Each element has a unique atomic number representing the number of protons.',
            hintPattern: 'Think about the position of elements in the periodic table.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'atomic_numbers', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'The element with atomic number 6 is ___.',
            optionPatterns: [],
            correctAnswerPattern: 'Carbon',
            explanationPattern: 'Carbon has atomic number 6, meaning it has 6 protons in its nucleus.',
            hintPattern: 'This element is the basis of organic chemistry.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'elements', 'fill_blank'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their atomic numbers:',
            optionPatterns: [
              'LEFT:Hydrogen|Carbon|Oxygen|Nitrogen',
              'RIGHT:1|6|8|7',
            ],
            correctAnswerPattern: 'Hydrogen:1;Carbon:6;Oxygen:8;Nitrogen:7',
            explanationPattern: 'Each element has a unique atomic number representing the number of protons.',
            hintPattern: 'Think about the position of elements in the periodic table.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'atomic_numbers', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their atomic numbers:',
            optionPatterns: [
              'LEFT:Hydrogen|Carbon|Oxygen|Nitrogen',
              'RIGHT:1|6|8|7',
            ],
            correctAnswerPattern: 'Hydrogen:1;Carbon:6;Oxygen:8;Nitrogen:7',
            explanationPattern: 'Each element has a unique atomic number representing the number of protons.',
            hintPattern: 'Think about the position of elements in the periodic table.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'atomic_numbers', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their atomic numbers:',
            optionPatterns: [
              'LEFT:Hydrogen|Carbon|Oxygen|Nitrogen',
              'RIGHT:1|6|8|7',
            ],
            correctAnswerPattern: 'Hydrogen:1;Carbon:6;Oxygen:8;Nitrogen:7',
            explanationPattern: 'Each element has a unique atomic number representing the number of protons.',
            hintPattern: 'Think about the position of elements in the periodic table.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'atomic_numbers', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their atomic numbers:',
            optionPatterns: [
              'LEFT:Hydrogen|Carbon|Oxygen|Nitrogen',
              'RIGHT:1|6|8|7',
            ],
            correctAnswerPattern: 'Hydrogen:1;Carbon:6;Oxygen:8;Nitrogen:7',
            explanationPattern: 'Each element has a unique atomic number representing the number of protons.',
            hintPattern: 'Think about the position of elements in the periodic table.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'atomic_numbers', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'elements') {
          templates.add(QuestionTemplate(
            id: 'chemistry_elements_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their atomic numbers:',
            optionPatterns: [
              'LEFT:Hydrogen|Helium|Lithium|Carbon',
              'RIGHT:1|2|3|6',
            ],
            correctAnswerPattern: 'Hydrogen:1;Helium:2;Lithium:3;Carbon:6',
            explanationPattern: 'Each element has a unique atomic number representing the number of protons.',
            hintPattern: 'The atomic number increases as you go across the periodic table.',
            baseDifficulty: 2,
            variables: {},
            tags: {'elements', 'atomic_number', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'elements') {
          templates.add(QuestionTemplate(
            id: 'chemistry_elements_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their symbols:',
            optionPatterns: [
              'LEFT:Sodium|Potassium|Calcium|Iron',
              'RIGHT:Na|K|Ca|Fe',
            ],
            correctAnswerPattern: 'Sodium:Na;Potassium:K;Calcium:Ca;Iron:Fe',
            explanationPattern: 'Each element has a unique chemical symbol, often derived from its Latin name.',
            hintPattern: 'Some symbols come from Latin names (Na from Natrium, K from Kalium).',
            baseDifficulty: 2,
            variables: {},
            tags: {'elements', 'symbols', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their chemical symbols:',
            optionPatterns: [
              'LEFT:Hydrogen|Helium|Lithium|Carbon',
              'RIGHT:H|He|Li|C',
            ],
            correctAnswerPattern: 'Hydrogen:H;Helium:He;Lithium:Li;Carbon:C',
            explanationPattern: 'Each element has a unique chemical symbol, often derived from its name.',
            hintPattern: 'Think about the first letter(s) of each element name.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'symbols', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their atomic masses:',
            optionPatterns: [
              'LEFT:Hydrogen|Carbon|Oxygen|Nitrogen',
              'RIGHT:1.008|12.011|15.999|14.007',
            ],
            correctAnswerPattern: 'Hydrogen:1.008;Carbon:12.011;Oxygen:15.999;Nitrogen:14.007',
            explanationPattern: 'Each element has a specific atomic mass based on its protons and neutrons.',
            hintPattern: 'Think about the relative weights of these common elements.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'atomic_mass', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical compounds with their formulas:',
            optionPatterns: [
              'LEFT:Water|Carbon Dioxide|Methane|Ammonia',
              'RIGHT:H₂O|CO₂|CH₄|NH₃',
            ],
            correctAnswerPattern: 'Water:H₂O;Carbon Dioxide:CO₂;Methane:CH₄;Ammonia:NH₃',
            explanationPattern: 'Each compound has a specific chemical formula showing its atomic composition.',
            hintPattern: 'Think about the elements that make up each compound.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'compounds', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical reactions with their types:',
            optionPatterns: [
              'LEFT:2H₂ + O₂ → 2H₂O|CaCO₃ → CaO + CO₂|NaCl + AgNO₃ → AgCl + NaNO₃|CH₄ + 2O₂ → CO₂ + 2H₂O',
              'RIGHT:Synthesis|Decomposition|Single Replacement|Combustion',
            ],
            correctAnswerPattern: '2H₂ + O₂ → 2H₂O:Synthesis;CaCO₃ → CaO + CO₂:Decomposition;NaCl + AgNO₃ → AgCl + NaNO₃:Single Replacement;CH₄ + 2O₂ → CO₂ + 2H₂O:Combustion',
            explanationPattern: 'Different chemical reactions follow specific patterns and can be classified by type.',
            hintPattern: 'Look at the reactants and products to determine the reaction type.',
            baseDifficulty: 3,
            variables: {},
            tags: {'reactions', 'classification', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical bonds with their characteristics:',
            optionPatterns: [
              'LEFT:Ionic Bond|Covalent Bond|Metallic Bond|Hydrogen Bond',
              'RIGHT:Electron transfer|Electron sharing|Electron sea|Weak intermolecular force',
            ],
            correctAnswerPattern: 'Ionic Bond:Electron transfer;Covalent Bond:Electron sharing;Metallic Bond:Electron sea;Hydrogen Bond:Weak intermolecular force',
            explanationPattern: 'Different types of chemical bonds have distinct characteristics based on how electrons interact.',
            hintPattern: 'Think about how electrons behave in each type of bond.',
            baseDifficulty: 3,
            variables: {},
            tags: {'bonding', 'electrons', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'organic_chemistry') {
          templates.add(QuestionTemplate(
            id: 'chemistry_organic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the functional groups with their structures:',
            optionPatterns: [
              'LEFT:Alcohol|Aldehyde|Ketone|Carboxylic Acid',
              'RIGHT:-OH|-CHO|-CO-|-COOH',
            ],
            correctAnswerPattern: 'Alcohol:-OH;Aldehyde:-CHO;Ketone:-CO-;Carboxylic Acid:-COOH',
            explanationPattern: 'Each functional group has a characteristic structure that determines its chemical properties.',
            hintPattern: 'Think about the characteristic atoms and bonds in each functional group.',
            baseDifficulty: 3,
            variables: {},
            tags: {'organic', 'functional_groups', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'organic') {
          templates.add(QuestionTemplate(
            id: 'chemistry_organic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the organic compounds with their functional groups:',
            optionPatterns: [
              'LEFT:CH₃CH₂OH|CH₃COOH|CH₃CHO|CH₃COCH₃',
              'RIGHT:Alcohol|Carboxylic acid|Aldehyde|Ketone',
            ],
            correctAnswerPattern: 'CH₃CH₂OH:Alcohol;CH₃COOH:Carboxylic acid;CH₃CHO:Aldehyde;CH₃COCH₃:Ketone',
            explanationPattern: 'Each organic compound contains a characteristic functional group that determines its properties.',
            hintPattern: 'Look for the characteristic atoms and bonds in each structure.',
            baseDifficulty: 3,
            variables: {},
            tags: {'organic', 'functional_groups', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'inorganic') {
          templates.add(QuestionTemplate(
            id: 'chemistry_inorganic_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical elements with their symbols:',
            optionPatterns: [
              'LEFT:Sodium|Potassium|Calcium|Magnesium',
              'RIGHT:Na|K|Ca|Mg',
            ],
            correctAnswerPattern: 'Sodium:Na;Potassium:K;Calcium:Ca;Magnesium:Mg',
            explanationPattern: 'Each chemical element has a unique symbol, often derived from its Latin name.',
            hintPattern: 'Some symbols come from Latin names (e.g., Na from Natrium).',
            baseDifficulty: 2,
            variables: {},
            tags: {'elements', 'symbols', 'drag_drop'},
          ));
        }
        break;

      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_method_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'A _____ is an educated guess that can be tested through experiments.',
            optionPatterns: [],
            correctAnswerPattern: 'hypothesis',
            explanationPattern: 'A hypothesis is a testable prediction or educated guess about the relationship between variables.',
            hintPattern: 'This is what scientists test in their experiments.',
            baseDifficulty: 2,
            variables: {},
            tags: {'scientific_method', 'hypothesis', 'fill_blank'},
          ));
        }
        break;

      case SubjectType.biology:
        if (skillId == 'cell_structure') {
          templates.add(QuestionTemplate(
            id: 'biology_cell_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the cell organelles with their functions:',
            optionPatterns: [
              'LEFT:Nucleus|Mitochondria|Ribosomes|Chloroplasts',
              'RIGHT:Protein synthesis|Controls cell activities|Energy production|Photosynthesis',
            ],
            correctAnswerPattern: 'Nucleus:Controls cell activities;Mitochondria:Energy production;Ribosomes:Protein synthesis;Chloroplasts:Photosynthesis',
            explanationPattern: 'Each organelle has a specific function that helps the cell survive and function.',
            hintPattern: 'Think about what each organelle does for the cell.',
            baseDifficulty: 2,
            variables: {},
            tags: {'cell_structure', 'organelles', 'drag_drop'},
          ));
        }
        break;

      case SubjectType.biology:
        if (skillId == 'genetics') {
          templates.add(QuestionTemplate(
            id: 'biology_genetics_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the genetic terms with their definitions:',
            optionPatterns: [
              'LEFT:Gene|Allele|Chromosome|DNA',
              'RIGHT:Hereditary unit|Gene variant|Structure containing genes|Genetic material',
            ],
            correctAnswerPattern: 'Gene:Hereditary unit;Allele:Gene variant;Chromosome:Structure containing genes;DNA:Genetic material',
            explanationPattern: 'Each genetic term has a specific meaning in heredity and molecular biology.',
            hintPattern: 'Think about the hierarchy from molecules to traits.',
            baseDifficulty: 2,
            variables: {},
            tags: {'genetics', 'heredity', 'drag_drop'},
          ));
        }
        break;

      case SubjectType.chemistry:
        if (skillId == 'organic_chemistry') {
          templates.add(QuestionTemplate(
            id: 'chemistry_organic_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'The functional group -OH is called a _____ group.',
            optionPatterns: [],
            correctAnswerPattern: 'hydroxyl',
            explanationPattern: 'The hydroxyl group (-OH) is a functional group consisting of an oxygen atom bonded to a hydrogen atom.',
            hintPattern: 'This group is found in alcohols.',
            baseDifficulty: 2,
            variables: {},
            tags: {'organic_chemistry', 'functional_groups', 'fill_blank'},
          ));
        }
        break;

    }
    
    return templates;
  }

  /// Generate numeric input templates
  List<QuestionTemplate> _generateNumericInputTemplates(
    SubjectType subject, String skillId, QuestionCategory category
  ) {
    final templates = <QuestionTemplate>[];
    
    switch (subject) {
      case SubjectType.math:
        if (skillId == 'arithmetic') {
          templates.add(QuestionTemplate(
            id: 'math_arithmetic_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'Calculate: {num1} × {num2}',
            optionPatterns: [],
            correctAnswerPattern: '{result}',
            explanationPattern: '{num1} × {num2} = {result}',
            hintPattern: 'Multiply the two numbers.',
            baseDifficulty: 1,
            variables: {
              'num1': [2, 3, 4, 5, 6, 7, 8, 9],
              'num2': [2, 3, 4, 5, 6, 7, 8, 9],
              'result': [], // Will be calculated as num1 * num2
            },
            tags: {'arithmetic', 'multiplication', 'numeric_input'},
          ));
        }
        if (skillId == 'multiplication') {
          templates.add(QuestionTemplate(
            id: 'math_multiplication_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'Calculate: {num1} × {num2}',
            optionPatterns: [],
            correctAnswerPattern: '{result}',
            explanationPattern: '{num1} × {num2} = {result}',
            hintPattern: 'Multiply the two numbers.',
            baseDifficulty: 1,
            variables: {
              'num1': [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
              'num2': [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
              'result': [], // Will be calculated as num1 * num2
            },
            tags: {'multiplication', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.physics:
        if (skillId == 'mechanics') {
          templates.add(QuestionTemplate(
            id: 'physics_mechanics_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'A car travels {distance} km in {time} hours. What is its speed in km/h?',
            optionPatterns: [],
            correctAnswerPattern: '{speed}',
            explanationPattern: 'Speed = Distance ÷ Time = {distance} ÷ {time} = {speed} km/h',
            hintPattern: 'Use the formula: Speed = Distance ÷ Time',
            baseDifficulty: 2,
            variables: {
              'distance': [60, 80, 100, 120, 150, 200],
              'time': [2, 3, 4, 5, 6],
              'speed': [], // Will be calculated as distance / time
            },
            tags: {'mechanics', 'speed', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'atoms') {
          templates.add(QuestionTemplate(
            id: 'chemistry_atoms_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'How many protons does an atom with atomic number {atomicNumber} have?',
            optionPatterns: [],
            correctAnswerPattern: '{atomicNumber}',
            explanationPattern: 'The atomic number equals the number of protons in an atom.',
            hintPattern: 'The atomic number is the same as the number of protons.',
            baseDifficulty: 1,
            variables: {
              'atomicNumber': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            },
            tags: {'atoms', 'protons', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'cells') {
          templates.add(QuestionTemplate(
            id: 'biology_cells_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'If a cell divides every {hours} hours, how many cells will there be after {totalHours} hours starting with 1 cell?',
            optionPatterns: [],
            correctAnswerPattern: '{result}',
            explanationPattern: 'Cell division doubles the number of cells each time. After {divisions} divisions: 2^{divisions} = {result}',
            hintPattern: 'Each division doubles the number of cells.',
            baseDifficulty: 2,
            variables: {
              'hours': [2, 3, 4],
              'totalHours': [6, 8, 12],
              'divisions': [], // Will be calculated as totalHours / hours
              'result': [], // Will be calculated as 2^divisions
            },
            tags: {'cells', 'division', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.computerScience:
        if (skillId == 'algorithms') {
          templates.add(QuestionTemplate(
            id: 'cs_algorithms_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'How many comparisons does binary search make in the worst case for an array of {size} elements?',
            optionPatterns: [],
            correctAnswerPattern: '{comparisons}',
            explanationPattern: 'Binary search makes at most log₂({size}) = {comparisons} comparisons.',
            hintPattern: 'Think about the logarithmic nature of binary search.',
            baseDifficulty: 3,
            variables: {
              'size': [8, 16, 32, 64, 128],
              'comparisons': [3, 4, 5, 6, 7], // log₂ of the sizes
            },
            tags: {'algorithms', 'binary_search', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.geography:
        if (skillId == 'landforms') {
          templates.add(QuestionTemplate(
            id: 'geography_landforms_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'Mount Everest is {height} meters tall. How many kilometers is this?',
            optionPatterns: [],
            correctAnswerPattern: '{heightKm}',
            explanationPattern: 'To convert meters to kilometers, divide by 1000: {height} ÷ 1000 = {heightKm} km',
            hintPattern: 'Divide by 1000 to convert meters to kilometers.',
            baseDifficulty: 1,
            variables: {
              'height': [8848],
              'heightKm': [8.848],
            },
            tags: {'landforms', 'measurement', 'numeric_input'},
          ));
        }
        break;
      case SubjectType.history:
        if (skillId == 'mesopotamia') {
          templates.add(QuestionTemplate(
            id: 'history_mesopotamia_ni_${category.name}_1',
            type: QuestionType.numericInput,
            category: category,
            questionPattern: 'The Code of Hammurabi was written around {year} BCE. How many years ago was this (assuming current year is 2024)?',
            optionPatterns: [],
            correctAnswerPattern: '{yearsAgo}',
            explanationPattern: 'Years ago = Current year + BCE year = 2024 + {year} = {yearsAgo} years',
            hintPattern: 'Add the BCE year to the current year.',
            baseDifficulty: 2,
            variables: {
              'year': [1750],
              'yearsAgo': [3774], // 2024 + 1750
            },
            tags: {'mesopotamia', 'timeline', 'numeric_input'},
          ));
        }
        break;
      default:
        // Add default case for other subjects
        break;
    }

    return templates;
  }

  /// Generate fill in the blank templates
  List<QuestionTemplate> _generateFillInTheBlankTemplates(
    SubjectType subject, String skillId, QuestionCategory category
  ) {
    final templates = <QuestionTemplate>[];
    
    switch (subject) {
      case SubjectType.math:
        if (skillId == 'algebra') {
          templates.add(QuestionTemplate(
            id: 'math_algebra_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'In the equation x + 3 = 8, x equals ___.',
            optionPatterns: [],
            correctAnswerPattern: '5',
            explanationPattern: 'To solve x + 3 = 8, subtract 3 from both sides: x = 8 - 3 = 5.',
            hintPattern: 'Subtract 3 from both sides of the equation.',
            baseDifficulty: 1,
            variables: {},
            tags: {'algebra', 'equations', 'fill_blank'},
          ));
        }
        break;
      case SubjectType.physics:
        if (skillId == 'mechanics') {
          templates.add(QuestionTemplate(
            id: 'physics_mechanics_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'Newton\'s first law states that an object at rest stays at ___ unless acted upon by a force.',
            optionPatterns: [],
            correctAnswerPattern: 'rest',
            explanationPattern: 'Newton\'s first law of inertia states that objects at rest stay at rest unless acted upon by an external force.',
            hintPattern: 'Think about the law of inertia.',
            baseDifficulty: 2,
            variables: {},
            tags: {'mechanics', 'newton', 'fill_blank'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'atoms') {
          templates.add(QuestionTemplate(
            id: 'chemistry_atoms_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'The chemical symbol for water is ___.',
            optionPatterns: [],
            correctAnswerPattern: 'H2O',
            explanationPattern: 'Water consists of two hydrogen atoms and one oxygen atom, so its chemical formula is H₂O.',
            hintPattern: 'Think about the elements that make up water.',
            baseDifficulty: 1,
            variables: {},
            tags: {'atoms', 'water', 'fill_blank'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'cells') {
          templates.add(QuestionTemplate(
            id: 'biology_cells_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'The ___ is the control center of the cell.',
            optionPatterns: [],
            correctAnswerPattern: 'nucleus',
            explanationPattern: 'The nucleus controls all cell activities and contains the cell\'s DNA.',
            hintPattern: 'This organelle contains the cell\'s genetic material.',
            baseDifficulty: 1,
            variables: {},
            tags: {'cells', 'nucleus', 'fill_blank'},
          ));
        }
        break;
      case SubjectType.computerScience:
        if (skillId == 'algorithms') {
          templates.add(QuestionTemplate(
            id: 'cs_algorithms_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'The time complexity of binary search is O(___n).',
            optionPatterns: [],
            correctAnswerPattern: 'log',
            explanationPattern: 'Binary search has O(log n) time complexity because it divides the search space in half each time.',
            hintPattern: 'Think about how binary search reduces the problem size.',
            baseDifficulty: 3,
            variables: {},
            tags: {'algorithms', 'complexity', 'fill_blank'},
          ));
        }
        break;
      case SubjectType.geography:
        if (skillId == 'landforms') {
          templates.add(QuestionTemplate(
            id: 'geography_landforms_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'The highest mountain in the world is Mount ___.',
            optionPatterns: [],
            correctAnswerPattern: 'Everest',
            explanationPattern: 'Mount Everest, located in the Himalayas, is the highest mountain on Earth.',
            hintPattern: 'This mountain is located in the Himalayas.',
            baseDifficulty: 1,
            variables: {},
            tags: {'landforms', 'mountains', 'fill_blank'},
          ));
        }
        break;
      case SubjectType.history:
        if (skillId == 'mesopotamia') {
          templates.add(QuestionTemplate(
            id: 'history_mesopotamia_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'Mesopotamia is located between the ___ and Euphrates rivers.',
            optionPatterns: [],
            correctAnswerPattern: 'Tigris',
            explanationPattern: 'Mesopotamia, known as the "land between rivers," is located between the Tigris and Euphrates rivers.',
            hintPattern: 'Think about the two major rivers in ancient Mesopotamia.',
            baseDifficulty: 2,
            variables: {},
            tags: {'mesopotamia', 'rivers', 'fill_blank'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_method_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'The first step of the scientific method is to make an ___.',
            optionPatterns: [],
            correctAnswerPattern: 'observation',
            explanationPattern: 'The scientific method begins with making an observation about the natural world.',
            hintPattern: 'What do scientists do first when they notice something interesting?',
            baseDifficulty: 1,
            variables: {},
            tags: {'scientific_method', 'observation', 'fill_blank'},
          ));
        }
        break;
      case SubjectType.english:
        if (skillId == 'grammar') {
          templates.add(QuestionTemplate(
            id: 'english_grammar_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'A ___ is a word that describes a noun.',
            optionPatterns: [],
            correctAnswerPattern: 'adjective',
            explanationPattern: 'An adjective is a word that describes or modifies a noun.',
            hintPattern: 'Think about words like "big", "red", or "happy".',
            baseDifficulty: 1,
            variables: {},
            tags: {'grammar', 'adjective', 'fill_blank'},
          ));
        }
        break;
      case SubjectType.art:
        if (skillId == 'color_theory') {
          templates.add(QuestionTemplate(
            id: 'art_color_theory_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'The three primary colors are red, blue, and ___.',
            optionPatterns: [],
            correctAnswerPattern: 'yellow',
            explanationPattern: 'The primary colors are red, blue, and yellow. These cannot be created by mixing other colors.',
            hintPattern: 'Think about the basic colors that cannot be mixed.',
            baseDifficulty: 1,
            variables: {},
            tags: {'color_theory', 'primary_colors', 'fill_blank'},
          ));
        }
        break;
      case SubjectType.music:
        if (skillId == 'rhythm') {
          templates.add(QuestionTemplate(
            id: 'music_rhythm_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'A ___ note gets four beats in 4/4 time.',
            optionPatterns: [],
            correctAnswerPattern: 'whole',
            explanationPattern: 'A whole note receives four beats in 4/4 time signature.',
            hintPattern: 'Think about the longest note value.',
            baseDifficulty: 1,
            variables: {},
            tags: {'rhythm', 'note_values', 'fill_blank'},
          ));
        }
        break;
      case SubjectType.physicalEducation:
        if (skillId == 'fitness') {
          templates.add(QuestionTemplate(
            id: 'pe_fitness_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: '___ exercise strengthens the heart and lungs.',
            optionPatterns: [],
            correctAnswerPattern: 'Cardiovascular',
            explanationPattern: 'Cardiovascular exercise, also called aerobic exercise, strengthens the heart and improves lung capacity.',
            hintPattern: 'This type of exercise gets your heart pumping.',
            baseDifficulty: 2,
            variables: {},
            tags: {'fitness', 'cardiovascular', 'fill_blank'},
          ));
        }
        break;

      case SubjectType.chemistry:
        if (skillId == 'periodic_table') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_fib_${category.name}_1',
            type: QuestionType.fillInTheBlank,
            category: category,
            questionPattern: 'The element with atomic number 6 is _____.',
            optionPatterns: [],
            correctAnswerPattern: 'carbon',
            explanationPattern: 'Carbon has atomic number 6, meaning it has 6 protons in its nucleus.',
            hintPattern: 'This element is the basis of organic chemistry.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic_table', 'elements', 'fill_blank'},
          ));
        }
        break;

    }
    
    return templates;
  }

  /// Generate drag and drop templates
  List<QuestionTemplate> _generateDragDropTemplates(
    SubjectType subject, String skillId, QuestionCategory category
  ) {
    final templates = <QuestionTemplate>[];
    
    switch (subject) {
      case SubjectType.math:
        if (skillId == 'addition') {
          templates.add(QuestionTemplate(
            id: 'math_addition_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the addition problems with their answers:',
            optionPatterns: [
              'LEFT:2 + 3|4 + 1|3 + 2|1 + 4',
              'RIGHT:5|5|5|5',
            ],
            correctAnswerPattern: '2 + 3:5;4 + 1:5;3 + 2:5;1 + 4:5',
            explanationPattern: 'All these addition problems equal 5.',
            hintPattern: 'Add the numbers together to find the sum.',
            baseDifficulty: 1,
            variables: {},
            tags: {'addition', 'basic_math', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.english:
        if (skillId == 'grammar') {
          templates.add(QuestionTemplate(
            id: 'english_grammar_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the parts of speech with their functions:',
            optionPatterns: [
              'LEFT:Noun|Verb|Adjective|Adverb',
              'RIGHT:Names a person, place, or thing|Shows action or state|Describes a noun|Describes a verb',
            ],
            correctAnswerPattern: 'Noun:Names a person, place, or thing;Verb:Shows action or state;Adjective:Describes a noun;Adverb:Describes a verb',
            explanationPattern: 'Each part of speech has a specific role in sentence structure.',
            hintPattern: 'Think about what each word type does in a sentence.',
            baseDifficulty: 2,
            variables: {},
            tags: {'grammar', 'parts_of_speech', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.art:
        if (skillId == 'color_theory') {
          templates.add(QuestionTemplate(
            id: 'art_color_theory_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the color types with their examples:',
            optionPatterns: [
              'LEFT:Primary|Secondary|Warm|Cool',
              'RIGHT:Red, Blue, Yellow|Orange, Green, Purple|Red, Orange, Yellow|Blue, Green, Purple',
            ],
            correctAnswerPattern: 'Primary:Red, Blue, Yellow;Secondary:Orange, Green, Purple;Warm:Red, Orange, Yellow;Cool:Blue, Green, Purple',
            explanationPattern: 'Primary colors cannot be mixed, secondary colors are made from primaries, and colors have temperature associations.',
            hintPattern: 'Think about basic color relationships and temperature.',
            baseDifficulty: 2,
            variables: {},
            tags: {'color_theory', 'basics', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.music:
        if (skillId == 'rhythm') {
          templates.add(QuestionTemplate(
            id: 'music_rhythm_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the note values with their beat counts:',
            optionPatterns: [
              'LEFT:Whole note|Half note|Quarter note|Eighth note',
              'RIGHT:4 beats|2 beats|1 beat|1/2 beat',
            ],
            correctAnswerPattern: 'Whole note:4 beats;Half note:2 beats;Quarter note:1 beat;Eighth note:1/2 beat',
            explanationPattern: 'Note values determine how long each note is held in music.',
            hintPattern: 'Think about how notes divide time in music.',
            baseDifficulty: 2,
            variables: {},
            tags: {'rhythm', 'note_values', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.physicalEducation:
        if (skillId == 'fitness') {
          templates.add(QuestionTemplate(
            id: 'pe_fitness_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the fitness components with their definitions:',
            optionPatterns: [
              'LEFT:Strength|Endurance|Flexibility|Balance',
              'RIGHT:Muscle power|Lasting ability|Range of motion|Stability control',
            ],
            correctAnswerPattern: 'Strength:Muscle power;Endurance:Lasting ability;Flexibility:Range of motion;Balance:Stability control',
            explanationPattern: 'Each fitness component contributes to overall physical health and performance.',
            hintPattern: 'Think about what each fitness aspect helps you do.',
            baseDifficulty: 2,
            variables: {},
            tags: {'fitness', 'components', 'drag_drop'},
          ));
        }
        break;
      case SubjectType.physics:
        if (skillId == 'mechanics') {
          templates.add(QuestionTemplate(
            id: 'physics_mechanics_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the physics quantities with their units:',
            optionPatterns: [
              'LEFT:Force|Energy|Power|Velocity',
              'RIGHT:Newton (N)|Joule (J)|Watt (W)|m/s',
            ],
            correctAnswerPattern: 'Force:Newton (N);Energy:Joule (J);Power:Watt (W);Velocity:m/s',
            explanationPattern: 'Each physics quantity has a specific unit of measurement.',
            hintPattern: 'Think about what each quantity measures.',
            baseDifficulty: 2,
            variables: {},
            tags: {'mechanics', 'units', 'drag_drop'},
          ));
        }
        break;

      case SubjectType.chemistry:
        if (skillId == 'bonding') {
          templates.add(QuestionTemplate(
            id: 'chemistry_bonding_dd_${category.name}_1',
            type: QuestionType.dragDrop,
            category: category,
            questionPattern: 'Match the chemical bonds with their descriptions:',
            optionPatterns: [
              'LEFT:Ionic bond|Covalent bond|Metallic bond|Hydrogen bond',
              'RIGHT:Electrons shared between atoms|Electrons transferred between atoms|Sea of electrons|Weak attraction to hydrogen',
            ],
            correctAnswerPattern: 'Ionic bond:Electrons transferred between atoms;Covalent bond:Electrons shared between atoms;Metallic bond:Sea of electrons;Hydrogen bond:Weak attraction to hydrogen',
            explanationPattern: 'Different types of chemical bonds form through different electron interactions.',
            hintPattern: 'Think about how electrons behave in each type of bond.',
            baseDifficulty: 3,
            variables: {},
            tags: {'bonding', 'electrons', 'drag_drop'},
          ));
        }
        break;
      default:
        // Add default case for other subjects
        break;
    }

    return templates;
  }

  /// Generate clickable answer templates
  List<QuestionTemplate> _generateClickableAnswerTemplates(
    SubjectType subject, String skillId, QuestionCategory category
  ) {
    final templates = <QuestionTemplate>[];
    
    switch (subject) {
      case SubjectType.math:
        if (skillId == 'geometry') {
          templates.add(QuestionTemplate(
            id: 'math_geometry_ca_${category.name}_1',
            type: QuestionType.clickableAnswer,
            category: category,
            questionPattern: 'Click on the correct formula for the area of a circle:',
            optionPatterns: [
              'πr²',
              '2πr',
              'πd',
              'r²',
            ],
            correctAnswerPattern: 'πr²',
            explanationPattern: 'The area of a circle is π times the radius squared (πr²).',
            hintPattern: 'Think about the relationship between radius and area.',
            baseDifficulty: 2,
            variables: {},
            tags: {'geometry', 'area', 'clickable'},
          ));
        }
        break;
      case SubjectType.physics:
        if (skillId == 'waves') {
          templates.add(QuestionTemplate(
            id: 'physics_waves_ca_${category.name}_1',
            type: QuestionType.clickableAnswer,
            category: category,
            questionPattern: 'Click on the correct unit for frequency:',
            optionPatterns: [
              'Hertz (Hz)',
              'Meter (m)',
              'Second (s)',
              'Joule (J)',
            ],
            correctAnswerPattern: 'Hertz (Hz)',
            explanationPattern: 'Frequency is measured in Hertz (Hz), which represents cycles per second.',
            hintPattern: 'Think about what frequency measures.',
            baseDifficulty: 2,
            variables: {},
            tags: {'waves', 'frequency', 'clickable'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'periodic') {
          templates.add(QuestionTemplate(
            id: 'chemistry_periodic_ca_${category.name}_1',
            type: QuestionType.clickableAnswer,
            category: category,
            questionPattern: 'Click on the element with atomic number 6:',
            optionPatterns: [
              'Carbon',
              'Oxygen',
              'Nitrogen',
              'Hydrogen',
            ],
            correctAnswerPattern: 'Carbon',
            explanationPattern: 'Carbon has atomic number 6, meaning it has 6 protons in its nucleus.',
            hintPattern: 'Think about the periodic table arrangement.',
            baseDifficulty: 2,
            variables: {},
            tags: {'periodic', 'atomic_number', 'clickable'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'genetics') {
          templates.add(QuestionTemplate(
            id: 'biology_genetics_ca_${category.name}_1',
            type: QuestionType.clickableAnswer,
            category: category,
            questionPattern: 'Click on the correct base pair for Adenine in DNA:',
            optionPatterns: [
              'Thymine',
              'Guanine',
              'Cytosine',
              'Uracil',
            ],
            correctAnswerPattern: 'Thymine',
            explanationPattern: 'In DNA, Adenine pairs with Thymine through hydrogen bonds.',
            hintPattern: 'Remember the base pairing rules in DNA.',
            baseDifficulty: 2,
            variables: {},
            tags: {'genetics', 'base_pairs', 'clickable'},
          ));
        }
        break;
      case SubjectType.computerScience:
        if (skillId == 'data_structures') {
          templates.add(QuestionTemplate(
            id: 'cs_data_structures_ca_${category.name}_1',
            type: QuestionType.clickableAnswer,
            category: category,
            questionPattern: 'Click on the data structure that follows LIFO principle:',
            optionPatterns: [
              'Stack',
              'Queue',
              'Array',
              'Linked List',
            ],
            correctAnswerPattern: 'Stack',
            explanationPattern: 'A stack follows Last In, First Out (LIFO) principle.',
            hintPattern: 'Think about which structure adds and removes from the same end.',
            baseDifficulty: 2,
            variables: {},
            tags: {'data_structures', 'lifo', 'clickable'},
          ));
        }
        break;
      case SubjectType.geography:
        if (skillId == 'landforms') {
          templates.add(QuestionTemplate(
            id: 'geography_landforms_ca_${category.name}_1',
            type: QuestionType.clickableAnswer,
            category: category,
            questionPattern: 'Click on the largest desert in the world:',
            optionPatterns: [
              'Antarctica',
              'Sahara',
              'Gobi',
              'Kalahari',
            ],
            correctAnswerPattern: 'Antarctica',
            explanationPattern: 'Antarctica is technically the largest desert as it receives very little precipitation.',
            hintPattern: 'Remember that deserts are defined by low precipitation, not just heat.',
            baseDifficulty: 3,
            variables: {},
            tags: {'landforms', 'deserts', 'clickable'},
          ));
        }
        break;
      case SubjectType.history:
        if (skillId == 'ancient_civilizations') {
          templates.add(QuestionTemplate(
            id: 'history_ancient_ca_${category.name}_1',
            type: QuestionType.clickableAnswer,
            category: category,
            questionPattern: 'Click on the civilization that built the pyramids:',
            optionPatterns: [
              'Ancient Egypt',
              'Ancient Greece',
              'Roman Empire',
              'Mesopotamia',
            ],
            correctAnswerPattern: 'Ancient Egypt',
            explanationPattern: 'The ancient Egyptians built the famous pyramids, including the Great Pyramid of Giza.',
            hintPattern: 'Think about which civilization is famous for pyramid construction.',
            baseDifficulty: 2,
            variables: {},
            tags: {'ancient_civilizations', 'pyramids', 'clickable'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_method_ca_${category.name}_1',
            type: QuestionType.clickableAnswer,
            category: category,
            questionPattern: 'Click on the first step of the scientific method:',
            optionPatterns: [
              'Observation',
              'Hypothesis',
              'Experiment',
              'Conclusion',
            ],
            correctAnswerPattern: 'Observation',
            explanationPattern: 'The scientific method begins with observation of phenomena.',
            hintPattern: 'Think about what scientists do first when studying something.',
            baseDifficulty: 2,
            variables: {},
            tags: {'scientific_method', 'observation', 'clickable'},
          ));
        }
        break;
      case SubjectType.english:
        if (skillId == 'grammar') {
          templates.add(QuestionTemplate(
            id: 'english_grammar_ca_${category.name}_1',
            type: QuestionType.clickableAnswer,
            category: category,
            questionPattern: 'Click on the correct part of speech for "quickly":',
            optionPatterns: [
              'Adverb',
              'Adjective',
              'Noun',
              'Verb',
            ],
            correctAnswerPattern: 'Adverb',
            explanationPattern: '"Quickly" is an adverb that modifies verbs, adjectives, or other adverbs.',
            hintPattern: 'Think about what type of word ends in -ly and describes how something is done.',
            baseDifficulty: 2,
            variables: {},
            tags: {'grammar', 'parts_of_speech', 'clickable'},
          ));
        }
        break;
      case SubjectType.art:
        if (skillId == 'color_theory') {
          templates.add(QuestionTemplate(
            id: 'art_color_ca_${category.name}_1',
            type: QuestionType.clickableAnswer,
            category: category,
            questionPattern: 'Click on the primary color that is NOT red or blue:',
            optionPatterns: [
              'Yellow',
              'Green',
              'Orange',
              'Purple',
            ],
            correctAnswerPattern: 'Yellow',
            explanationPattern: 'The three primary colors are red, blue, and yellow.',
            hintPattern: 'Primary colors cannot be created by mixing other colors.',
            baseDifficulty: 1,
            variables: {},
            tags: {'color_theory', 'primary_colors', 'clickable'},
          ));
        }
        break;
      case SubjectType.music:
        if (skillId == 'music_theory') {
          templates.add(QuestionTemplate(
            id: 'music_theory_ca_${category.name}_1',
            type: QuestionType.clickableAnswer,
            category: category,
            questionPattern: 'Click on the note that comes after G in the musical alphabet:',
            optionPatterns: [
              'A',
              'H',
              'F',
              'B',
            ],
            correctAnswerPattern: 'A',
            explanationPattern: 'The musical alphabet goes A, B, C, D, E, F, G, then repeats with A.',
            hintPattern: 'The musical alphabet has only 7 letters and repeats.',
            baseDifficulty: 1,
            variables: {},
            tags: {'music_theory', 'musical_alphabet', 'clickable'},
          ));
        }
        break;
      case SubjectType.physicalEducation:
        if (skillId == 'sports_rules') {
          templates.add(QuestionTemplate(
            id: 'pe_sports_ca_${category.name}_1',
            type: QuestionType.clickableAnswer,
            category: category,
            questionPattern: 'Click on the number of players on a basketball team on the court:',
            optionPatterns: [
              '5',
              '6',
              '7',
              '11',
            ],
            correctAnswerPattern: '5',
            explanationPattern: 'A basketball team has 5 players on the court at any given time.',
            hintPattern: 'Think about how many positions there are in basketball.',
            baseDifficulty: 1,
            variables: {},
            tags: {'sports_rules', 'basketball', 'clickable'},
          ));
        }
        break;
    }
    
    return templates;
  }

  /// Generate short answer templates
  List<QuestionTemplate> _generateShortAnswerTemplates(
    SubjectType subject, String skillId, QuestionCategory category
  ) {
    final templates = <QuestionTemplate>[];
    
    switch (subject) {
      case SubjectType.math:
        if (skillId == 'calculus') {
          templates.add(QuestionTemplate(
            id: 'math_calculus_sa_${category.name}_1',
            type: QuestionType.shortAnswer,
            category: category,
            questionPattern: 'What is the derivative of x²?',
            optionPatterns: [],
            correctAnswerPattern: '2x',
            explanationPattern: 'The derivative of x² is 2x using the power rule.',
            hintPattern: 'Use the power rule: d/dx(xⁿ) = nxⁿ⁻¹',
            baseDifficulty: 3,
            variables: {},
            tags: {'calculus', 'derivative', 'short_answer'},
          ));
        }
        break;
      case SubjectType.physics:
        if (skillId == 'motion') {
          templates.add(QuestionTemplate(
            id: 'physics_motion_sa_${category.name}_1',
            type: QuestionType.shortAnswer,
            category: category,
            questionPattern: 'Explain Newton\'s First Law of Motion in your own words.',
            optionPatterns: [],
            correctAnswerPattern: 'An object at rest stays at rest and an object in motion stays in motion unless acted upon by an external force.',
            explanationPattern: 'Newton\'s First Law states that objects maintain their state of motion unless a force acts on them. This is also called the law of inertia.',
            hintPattern: 'Think about what happens to objects when no forces act on them.',
            baseDifficulty: 3,
            variables: {},
            tags: {'motion', 'newton', 'short_answer'},
          ));
        }
        break;
      case SubjectType.chemistry:
        if (skillId == 'stoichiometry') {
          templates.add(QuestionTemplate(
            id: 'chemistry_stoichiometry_sa_${category.name}_1',
            type: QuestionType.shortAnswer,
            category: category,
            questionPattern: 'What is the molecular formula for water?',
            optionPatterns: [],
            correctAnswerPattern: 'H2O',
            explanationPattern: 'Water consists of two hydrogen atoms and one oxygen atom, giving the formula H2O.',
            hintPattern: 'Think about the composition of water molecules.',
            baseDifficulty: 1,
            variables: {},
            tags: {'stoichiometry', 'molecular_formula', 'short_answer'},
          ));
        }
        break;
      case SubjectType.biology:
        if (skillId == 'photosynthesis') {
          templates.add(QuestionTemplate(
            id: 'biology_photosynthesis_sa_${category.name}_1',
            type: QuestionType.shortAnswer,
            category: category,
            questionPattern: 'What gas do plants release during photosynthesis?',
            optionPatterns: [],
            correctAnswerPattern: 'Oxygen',
            explanationPattern: 'During photosynthesis, plants release oxygen as a byproduct while producing glucose.',
            hintPattern: 'Think about what gas we breathe that plants produce.',
            baseDifficulty: 2,
            variables: {},
            tags: {'photosynthesis', 'gas_exchange', 'short_answer'},
          ));
        }
        break;
      case SubjectType.computerScience:
        if (skillId == 'programming') {
          templates.add(QuestionTemplate(
            id: 'cs_programming_sa_${category.name}_1',
            type: QuestionType.shortAnswer,
            category: category,
            questionPattern: 'What does HTML stand for?',
            optionPatterns: [],
            correctAnswerPattern: 'HyperText Markup Language',
            explanationPattern: 'HTML stands for HyperText Markup Language, used for creating web pages.',
            hintPattern: 'Think about the language used to structure web content.',
            baseDifficulty: 2,
            variables: {},
            tags: {'programming', 'html', 'short_answer'},
          ));
        }
        break;
      case SubjectType.geography:
        if (skillId == 'capitals') {
          templates.add(QuestionTemplate(
            id: 'geography_capitals_sa_${category.name}_1',
            type: QuestionType.shortAnswer,
            category: category,
            questionPattern: 'What is the capital of France?',
            optionPatterns: [],
            correctAnswerPattern: 'Paris',
            explanationPattern: 'Paris is the capital and largest city of France.',
            hintPattern: 'Think about the famous city known for the Eiffel Tower.',
            baseDifficulty: 1,
            variables: {},
            tags: {'capitals', 'france', 'short_answer'},
          ));
        }
        break;
      case SubjectType.history:
        if (skillId == 'mesopotamia') {
          templates.add(QuestionTemplate(
            id: 'history_mesopotamia_sa_${category.name}_1',
            type: QuestionType.shortAnswer,
            category: category,
            questionPattern: 'Describe three important contributions of Mesopotamian civilization.',
            optionPatterns: [],
            correctAnswerPattern: 'Writing system (cuneiform), wheel, code of laws (Hammurabi), irrigation systems, city-states',
            explanationPattern: 'Mesopotamians invented writing, the wheel, created the first written laws, developed irrigation, and established the first cities.',
            hintPattern: 'Think about inventions and systems that are still important today.',
            baseDifficulty: 4,
            variables: {},
            tags: {'mesopotamia', 'contributions', 'short_answer'},
          ));
        }
        break;
      case SubjectType.science:
        if (skillId == 'scientific_method') {
          templates.add(QuestionTemplate(
            id: 'science_method_sa_${category.name}_1',
            type: QuestionType.shortAnswer,
            category: category,
            questionPattern: 'Explain the difference between a hypothesis and a theory.',
            optionPatterns: [],
            correctAnswerPattern: 'A hypothesis is an educated guess that can be tested, while a theory is a well-supported explanation based on extensive evidence.',
            explanationPattern: 'Hypotheses are testable predictions, while theories are comprehensive explanations supported by multiple lines of evidence.',
            hintPattern: 'Think about the level of evidence and testing required for each.',
            baseDifficulty: 3,
            variables: {},
            tags: {'scientific_method', 'hypothesis', 'theory', 'short_answer'},
          ));
        }
        break;
      case SubjectType.english:
        if (skillId == 'literature') {
          templates.add(QuestionTemplate(
            id: 'english_literature_sa_${category.name}_1',
            type: QuestionType.shortAnswer,
            category: category,
            questionPattern: 'What is the main theme of Romeo and Juliet?',
            optionPatterns: [],
            correctAnswerPattern: 'Love conquers all, or the destructive nature of feuding families',
            explanationPattern: 'Romeo and Juliet explores themes of love, fate, family conflict, and the consequences of hatred.',
            hintPattern: 'Think about the central conflict between the two families.',
            baseDifficulty: 3,
            variables: {},
            tags: {'literature', 'shakespeare', 'themes', 'short_answer'},
          ));
        }
        break;
      case SubjectType.art:
        if (skillId == 'art_history') {
          templates.add(QuestionTemplate(
            id: 'art_history_sa_${category.name}_1',
            type: QuestionType.shortAnswer,
            category: category,
            questionPattern: 'Name three characteristics of Renaissance art.',
            optionPatterns: [],
            correctAnswerPattern: 'Realism, perspective, humanism, classical themes, sfumato technique',
            explanationPattern: 'Renaissance art featured realistic human figures, mathematical perspective, humanistic themes, and classical influences.',
            hintPattern: 'Think about how Renaissance art differed from medieval art.',
            baseDifficulty: 4,
            variables: {},
            tags: {'art_history', 'renaissance', 'characteristics', 'short_answer'},
          ));
        }
        break;
      case SubjectType.music:
        if (skillId == 'music_history') {
          templates.add(QuestionTemplate(
            id: 'music_history_sa_${category.name}_1',
            type: QuestionType.shortAnswer,
            category: category,
            questionPattern: 'Who composed "The Four Seasons"?',
            optionPatterns: [],
            correctAnswerPattern: 'Antonio Vivaldi',
            explanationPattern: 'Antonio Vivaldi, an Italian Baroque composer, wrote "The Four Seasons" violin concertos.',
            hintPattern: 'Think about famous Baroque composers from Italy.',
            baseDifficulty: 3,
            variables: {},
            tags: {'music_history', 'vivaldi', 'baroque', 'short_answer'},
          ));
        }
        break;
      case SubjectType.physicalEducation:
        if (skillId == 'fitness') {
          templates.add(QuestionTemplate(
            id: 'pe_fitness_sa_${category.name}_1',
            type: QuestionType.shortAnswer,
            category: category,
            questionPattern: 'What are the five components of physical fitness?',
            optionPatterns: [],
            correctAnswerPattern: 'Cardiovascular endurance, muscular strength, muscular endurance, flexibility, body composition',
            explanationPattern: 'The five components are cardiovascular endurance, muscular strength, muscular endurance, flexibility, and body composition.',
            hintPattern: 'Think about different aspects of being physically fit.',
            baseDifficulty: 3,
            variables: {},
            tags: {'fitness', 'components', 'health', 'short_answer'},
          ));
        }
        break;
    }
    
    return templates;
  }

  /// Generate questions from pools with anti-repetition
  Future<List<Question>> generateQuestionsFromPools(
    SubjectType subject,
    String skillId,
    int count,
    {List<QuestionCategory>? preferredCategories}
  ) async {
    final questions = <Question>[];
    final categories = preferredCategories ?? QuestionCategory.values;
    
    // Distribute questions across categories
    final questionsPerCategory = count ~/ categories.length;
    final remainder = count % categories.length;
    
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final categoryCount = questionsPerCategory + (i < remainder ? 1 : 0);
      
      if (categoryCount > 0) {
        final categoryQuestions = await _generateQuestionsFromCategory(
          subject, skillId, category, categoryCount
        );
        questions.addAll(categoryQuestions);
      }
    }
    
    // Shuffle the questions to mix categories
    questions.shuffle(_rng);
    return questions;
  }

  /// Generate questions from a specific category
  Future<List<Question>> _generateQuestionsFromCategory(
    SubjectType subject,
    String skillId,
    QuestionCategory category,
    int count
  ) async {
    final pool = _poolManager!.getPool(subject, skillId, category);
    if (pool == null) return [];
    
    final questions = <Question>[];
    var currentPool = pool;
    
    // Check if pool needs reset
    final poolKey = '${subject.name}_${skillId}_${category.name}';
    if (_poolManager!.shouldResetPools(poolKey)) {
      currentPool = currentPool.resetUsage();
      _poolManager = _poolManager!.updatePool(currentPool);
    }
    
    for (int i = 0; i < count; i++) {
      if (!currentPool.canGenerateQuestion()) {
        // Reset pool if no more questions available
        currentPool = currentPool.resetUsage();
      }
      
      final template = currentPool.getNextTemplate(_rng);
      if (template != null) {
        final question = template.generateQuestion(subject, _rng);
        questions.add(question);
        
        // Mark question as used
        currentPool = currentPool.markQuestionUsed(template.id);
      }
    }
    
    // Update the pool manager
    _poolManager = _poolManager!.updatePool(currentPool);
    await _savePoolManager();
    
    return questions;
  }

  /// Get statistics about question pools
  Future<Map<String, dynamic>> getPoolStatistics() async {
    if (_poolManager == null) return {};
    
    final stats = <String, dynamic>{};
    
    for (final subject in SubjectType.values) {
      final subjectStats = <String, dynamic>{};
      
      for (final category in QuestionCategory.values) {
        int totalQuestions = 0;
        int usedQuestions = 0;
        
        final skillIds = _getSkillIdsForSubject(subject);
        for (final skillId in skillIds) {
          final pool = _poolManager!.getPool(subject, skillId, category);
          if (pool != null) {
            totalQuestions += pool.templates.length;
            usedQuestions += pool.usedQuestionIds.length;
          }
        }
        
        subjectStats[category.name] = {
          'total': totalQuestions,
          'used': usedQuestions,
          'available': totalQuestions - usedQuestions,
        };
      }
      
      stats[subject.name] = subjectStats;
    }
    
    return stats;
  }

  /// Reset all pools for a subject
  Future<void> resetSubjectPools(SubjectType subject) async {
    _poolManager = _poolManager!.resetSubjectPools(subject);
    await _savePoolManager();
  }

  /// Get the current pool manager
  QuestionPoolManager? get poolManager => _poolManager;
}