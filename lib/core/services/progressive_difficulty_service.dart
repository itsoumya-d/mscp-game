import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import 'daily_content_service.dart';

/// Service for managing progressive difficulty levels across the app
/// Integrates with procedural generation for adaptive content generation
class ProgressiveDifficultyService {
  static ProgressiveDifficultyService? _instance;
  
  static ProgressiveDifficultyService getInstance() {
    _instance ??= ProgressiveDifficultyService._internal();
    return _instance!;
  }
  
  // Keep the getter for backward compatibility but mark as deprecated
  @deprecated
  static ProgressiveDifficultyService get instance => getInstance();
  
  ProgressiveDifficultyService._internal();

  // Storage keys
  static const String _difficultyAnalyticsKey = 'difficulty_analytics';
  static const String _adaptiveSettingsKey = 'adaptive_settings';
  static const String _performanceHistoryKey = 'performance_history';

  // Difficulty configuration
  static const int maxDifficultyLevel = 10;
  static const int minDifficultyLevel = 1;
  static const double difficultyIncrementThreshold = 0.8; // 80% success rate
  static const double difficultyDecrementThreshold = 0.4; // 40% success rate

  /// Initialize the progressive difficulty system
  Future<void> initialize() async {
    await _ensureDefaultSettings();
    await _analyzeUserPerformance();
    
    if (kDebugMode) {
      print('Progressive Difficulty Service initialized');
    }
  }

  /// Get current difficulty level for a subject with AI-enhanced analysis
  Future<int> getAdaptiveDifficulty(SubjectType subject) async {
    final baseLevel = await DailyContentService.getInstance().getSubjectDifficulty(subject);
    final performanceData = await _getPerformanceHistory(subject);
    final adaptiveSettings = await _getAdaptiveSettings();

    if (!adaptiveSettings['enabled']) {
      return baseLevel;
    }

    // Analyze recent performance to adjust difficulty
    final recentPerformance = _analyzeRecentPerformance(performanceData);
    final adjustedLevel = _calculateAdaptiveDifficulty(baseLevel, recentPerformance);

    return adjustedLevel.clamp(minDifficultyLevel, maxDifficultyLevel);
  }

  /// Generate adaptive questions using procedural generation with progressive difficulty
  Future<List<Map<String, dynamic>>> generateAdaptiveQuestions({
    required SubjectType subject,
    required String skillId,
    required String skillName,
    required int baseQuestionCount,
  }) async {
    final difficulty = await getAdaptiveDifficulty(subject);
    final performanceHistory = await _getPerformanceHistory(subject);
    final weakAreas = _identifyWeakAreas(performanceHistory);

    final prompt = _buildAdaptiveQuestionPrompt(
      subject: subject,
      skillId: skillId,
      skillName: skillName,
      difficulty: difficulty,
      questionCount: baseQuestionCount,
      weakAreas: weakAreas,
    );

    try {
      // Use procedural generation instead of AI
      final questions = _generateProceduralQuestions(
        subject: subject,
        difficulty: difficulty,
        questionCount: baseQuestionCount,
        weakAreas: weakAreas,
      );
      
      // Track question generation for analytics
      await _trackQuestionGeneration(subject, difficulty, questions.length);
      
      return questions;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating adaptive questions: $e');
      }
      return _generateFallbackQuestions(subject, skillId, difficulty, baseQuestionCount);
    }
  }

  /// Record user performance for adaptive learning
  Future<void> recordPerformance({
    required SubjectType subject,
    required String skillId,
    required int difficulty,
    required bool isCorrect,
    required int timeSpentSeconds,
    required String questionType,
  }) async {
    final performance = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'subject': subject.name,
      'skillId': skillId,
      'difficulty': difficulty,
      'isCorrect': isCorrect,
      'timeSpent': timeSpentSeconds,
      'questionType': questionType,
    };

    final history = await _getPerformanceHistory(subject);
    history.add(performance);

    // Keep only last 100 records per subject
    if (history.length > 100) {
      history.removeRange(0, history.length - 100);
    }

    await _savePerformanceHistory(subject, history);
    await _updateDifficultyBasedOnPerformance(subject, isCorrect, difficulty);
  }

  /// Get difficulty analytics for display
  Future<Map<String, dynamic>> getDifficultyAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    final analyticsJson = prefs.getString(_difficultyAnalyticsKey);
    
    if (analyticsJson != null) {
      return json.decode(analyticsJson);
    }

    return _getDefaultAnalytics();
  }

  /// Get adaptive learning recommendations
  Future<Map<String, dynamic>> getAdaptiveRecommendations(SubjectType subject) async {
    final difficulty = await getAdaptiveDifficulty(subject);
    final performance = await _getPerformanceHistory(subject);
    final weakAreas = _identifyWeakAreas(performance);
    final strongAreas = _identifyStrongAreas(performance);

    return {
      'currentDifficulty': difficulty,
      'recommendedDifficulty': await _getRecommendedDifficulty(subject),
      'weakAreas': weakAreas,
      'strongAreas': strongAreas,
      'focusSkills': _getFocusSkills(weakAreas),
      'nextMilestone': _getNextMilestone(difficulty),
      'estimatedTimeToNextLevel': await _estimateTimeToNextLevel(subject),
    };
  }

  /// Update adaptive settings
  Future<void> updateAdaptiveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adaptiveSettingsKey, json.encode(settings));
  }

  // Private helper methods

  String _buildAdaptiveQuestionPrompt({
    required SubjectType subject,
    required String skillId,
    required String skillName,
    required int difficulty,
    required int questionCount,
    required List<String> weakAreas,
  }) {
    final difficultyLabel = _getDifficultyLabel(difficulty);
    final focusAreas = weakAreas.isNotEmpty 
        ? 'Focus extra attention on: ${weakAreas.join(', ')}'
        : 'Maintain balanced coverage of all concepts';

    return '''
Generate $questionCount adaptive questions for $skillName in ${subject.name} at $difficultyLabel level (difficulty $difficulty/10).

$focusAreas

Return ONLY a valid JSON array with this structure:
[
  {
    "id": "unique_question_id",
    "type": "multiple_choice|true_false|fill_in_the_blank|clickable_answer|short_answer|numeric_input|drag_drop",
    "questionText": "Question text here",
    "options": ["option1", "option2", "option3", "option4"],
    "correctAnswer": "correct answer",
    "explanation": "Detailed explanation",
    "hint": "Helpful hint",
    "difficulty": $difficulty,
    "estimatedTime": 30,
    "tags": ["tag1", "tag2"]
  }
]

Question type distribution:
- 40% multiple_choice
- 20% true_false  
- 15% fill_in_the_blank
- 10% clickable_answer
- 10% short_answer
- 5% numeric_input

Difficulty $difficulty requirements:
${_getDifficultyRequirements(difficulty)}

Subject-specific focus for ${subject.name}:
${_getSubjectSpecificFocus(subject, difficulty)}

Ensure questions are:
- Progressively challenging at level $difficulty
- Educationally sound with clear explanations
- Varied in format to maintain engagement
- Aligned with learning objectives
''';
  }

  String _getDifficultyLabel(int level) {
    if (level <= 2) return 'Beginner';
    if (level <= 4) return 'Elementary';
    if (level <= 6) return 'Intermediate';
    if (level <= 8) return 'Advanced';
    return 'Expert';
  }

  String _getDifficultyRequirements(int difficulty) {
    switch (difficulty) {
      case 1:
      case 2:
        return '- Basic recall and recognition\n- Simple application of concepts\n- Clear, direct questions';
      case 3:
      case 4:
        return '- Understanding and comprehension\n- Basic problem-solving\n- Some multi-step processes';
      case 5:
      case 6:
        return '- Analysis and synthesis\n- Complex problem-solving\n- Integration of multiple concepts';
      case 7:
      case 8:
        return '- Evaluation and critical thinking\n- Advanced applications\n- Real-world problem scenarios';
      case 9:
      case 10:
        return '- Expert-level analysis\n- Research-oriented questions\n- Cutting-edge applications';
      default:
        return '- Appropriate for difficulty level $difficulty';
    }
  }

  String _getSubjectSpecificFocus(SubjectType subject, int difficulty) {
    switch (subject) {
      case SubjectType.math:
        if (difficulty <= 3) return 'Basic arithmetic, simple algebra, geometry fundamentals';
        if (difficulty <= 6) return 'Advanced algebra, trigonometry, calculus introduction';
        return 'Advanced calculus, linear algebra, discrete mathematics';
      case SubjectType.physics:
        if (difficulty <= 3) return 'Basic mechanics, simple circuits, wave properties';
        if (difficulty <= 6) return 'Thermodynamics, electromagnetism, modern physics';
        return 'Quantum mechanics, relativity, advanced field theory';
      case SubjectType.chemistry:
        if (difficulty <= 3) return 'Atomic structure, basic bonding, simple reactions';
        if (difficulty <= 6) return 'Organic chemistry, thermochemistry, kinetics';
        return 'Advanced organic synthesis, physical chemistry, biochemistry';
      case SubjectType.biology:
        if (difficulty <= 3) return 'Cell biology, basic genetics, simple ecology';
        if (difficulty <= 6) return 'Molecular biology, evolution, human physiology';
        return 'Systems biology, biotechnology, advanced genetics';
      case SubjectType.computerScience:
        if (difficulty <= 3) return 'Basic programming, variables, simple loops and conditionals';
        if (difficulty <= 6) return 'Object-oriented programming, data structures, algorithms';
        return 'Advanced algorithms, system design, machine learning concepts';
      case SubjectType.geography:
        if (difficulty <= 3) return 'Physical features, countries and capitals, basic climate';
        if (difficulty <= 6) return 'Economic geography, population patterns, environmental systems';
        return 'Advanced spatial analysis, GIS applications, global interconnections';
      case SubjectType.history:
        if (difficulty <= 3) return 'Ancient civilizations, basic chronology, key historical figures';
        if (difficulty <= 6) return 'Medieval to modern periods, cause and effect relationships';
        return 'Historical methodology, historiography, complex historical analysis';
      case SubjectType.science:
        if (difficulty <= 3) return 'Basic scientific method, simple observations, hypothesis formation';
        if (difficulty <= 6) return 'Experimental design, data analysis, scientific reasoning';
        return 'Advanced research methods, scientific theory, interdisciplinary science';
      case SubjectType.english:
        if (difficulty <= 3) return 'Basic grammar, simple vocabulary, reading comprehension';
        if (difficulty <= 6) return 'Advanced grammar, literature analysis, writing skills';
        return 'Literary criticism, advanced composition, linguistic analysis';
      case SubjectType.art:
        if (difficulty <= 3) return 'Basic color theory, simple drawing, art appreciation';
        if (difficulty <= 6) return 'Advanced techniques, art history, composition principles';
        return 'Art criticism, advanced media, contemporary art theory';
      case SubjectType.music:
        if (difficulty <= 3) return 'Basic notes, simple rhythms, music appreciation';
        if (difficulty <= 6) return 'Music theory, composition basics, instrument techniques';
        return 'Advanced composition, music analysis, performance mastery';
      case SubjectType.physicalEducation:
        if (difficulty <= 3) return 'Basic fitness, simple exercises, health awareness';
        if (difficulty <= 6) return 'Exercise physiology, sports techniques, nutrition';
        return 'Advanced training methods, sports psychology, performance optimization';
    }
  }

  List<Map<String, dynamic>> _parseQuestionsFromResponse(String response) {
    try {
      // Extract JSON from response
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        throw Exception('No JSON array found in response');
      }
      
      final jsonString = response.substring(jsonStart, jsonEnd);
      final List<dynamic> questionsList = json.decode(jsonString);
      
      return questionsList.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing questions from response: $e');
      }
      return [];
    }
  }

  List<Map<String, dynamic>> _generateFallbackQuestions(
    SubjectType subject,
    String skillId,
    int difficulty,
    int count,
  ) {
    // Generate basic fallback questions when AI fails
    return List.generate(count, (index) => {
      'id': 'fallback_${skillId}_$index',
      'type': 'multiple_choice',
      'questionText': 'Practice question ${index + 1} for $skillId',
      'options': ['Option A', 'Option B', 'Option C', 'Option D'],
      'correctAnswer': 'Option A',
      'explanation': 'This is a fallback question generated when AI is unavailable.',
      'hint': 'Choose the best answer.',
      'difficulty': difficulty,
      'estimatedTime': 30,
      'tags': [subject.name.toLowerCase(), skillId],
    });
  }

  double _analyzeRecentPerformance(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return 0.5; // Neutral performance

    // Analyze last 20 questions or all if less than 20
    final recentCount = min(20, history.length);
    final recentQuestions = history.sublist(history.length - recentCount);
    
    final correctCount = recentQuestions.where((q) => q['isCorrect'] == true).length;
    return correctCount / recentCount;
  }

  int _calculateAdaptiveDifficulty(int baseLevel, double performance) {
    if (performance >= difficultyIncrementThreshold) {
      return min(baseLevel + 1, maxDifficultyLevel);
    } else if (performance <= difficultyDecrementThreshold) {
      return max(baseLevel - 1, minDifficultyLevel);
    }
    return baseLevel;
  }

  List<String> _identifyWeakAreas(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return [];

    final skillPerformance = <String, List<bool>>{};
    
    for (final record in history) {
      final skillId = record['skillId'] as String;
      final isCorrect = record['isCorrect'] as bool;
      
      skillPerformance.putIfAbsent(skillId, () => []).add(isCorrect);
    }

    final weakAreas = <String>[];
    skillPerformance.forEach((skill, results) {
      final accuracy = results.where((r) => r).length / results.length;
      if (accuracy < 0.6) { // Less than 60% accuracy
        weakAreas.add(skill);
      }
    });

    return weakAreas;
  }

  List<String> _identifyStrongAreas(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return [];

    final skillPerformance = <String, List<bool>>{};
    
    for (final record in history) {
      final skillId = record['skillId'] as String;
      final isCorrect = record['isCorrect'] as bool;
      
      skillPerformance.putIfAbsent(skillId, () => []).add(isCorrect);
    }

    final strongAreas = <String>[];
    skillPerformance.forEach((skill, results) {
      final accuracy = results.where((r) => r).length / results.length;
      if (accuracy >= 0.85) { // 85% or higher accuracy
        strongAreas.add(skill);
      }
    });

    return strongAreas;
  }

  List<String> _getFocusSkills(List<String> weakAreas) {
    return weakAreas.take(3).toList(); // Focus on top 3 weak areas
  }

  String _getNextMilestone(int currentDifficulty) {
    final nextLevel = currentDifficulty + 1;
    if (nextLevel > maxDifficultyLevel) {
      return 'Maximum difficulty achieved!';
    }
    return 'Reach difficulty level $nextLevel';
  }

  Future<int> _estimateTimeToNextLevel(SubjectType subject) async {
    final performance = await _getPerformanceHistory(subject);
    if (performance.isEmpty) return 7; // Default 7 days

    final recentPerformance = _analyzeRecentPerformance(performance);
    
    if (recentPerformance >= 0.8) return 3; // 3 days if performing well
    if (recentPerformance >= 0.6) return 7; // 1 week if moderate
    return 14; // 2 weeks if struggling
  }

  Future<int> _getRecommendedDifficulty(SubjectType subject) async {
    final current = await getAdaptiveDifficulty(subject);
    final performance = await _getPerformanceHistory(subject);
    final recentPerformance = _analyzeRecentPerformance(performance);

    if (recentPerformance >= 0.85) return min(current + 1, maxDifficultyLevel);
    if (recentPerformance <= 0.4) return max(current - 1, minDifficultyLevel);
    return current;
  }

  Future<void> _updateDifficultyBasedOnPerformance(
    SubjectType subject,
    bool isCorrect,
    int currentDifficulty,
  ) async {
    final history = await _getPerformanceHistory(subject);
    final recentPerformance = _analyzeRecentPerformance(history);
    
    // Update difficulty if performance warrants it
    if (recentPerformance >= difficultyIncrementThreshold && history.length >= 10) {
      final newDifficulty = min(currentDifficulty + 1, maxDifficultyLevel);
      // Note: This would integrate with existing difficulty services
      if (kDebugMode) {
        print('Recommending difficulty increase for ${subject.name}: $currentDifficulty -> $newDifficulty');
      }
    } else if (recentPerformance <= difficultyDecrementThreshold && history.length >= 10) {
      final newDifficulty = max(currentDifficulty - 1, minDifficultyLevel);
      if (kDebugMode) {
        print('Recommending difficulty decrease for ${subject.name}: $currentDifficulty -> $newDifficulty');
      }
    }
  }

  Future<void> _trackQuestionGeneration(SubjectType subject, int difficulty, int count) async {
    final analytics = await getDifficultyAnalytics();
    final subjectKey = subject.name;
    
    analytics['questionsGenerated'] = (analytics['questionsGenerated'] ?? 0) + count;
    analytics['bySubject'] ??= <String, dynamic>{};
    analytics['bySubject'][subjectKey] = (analytics['bySubject'][subjectKey] ?? 0) + count;
    analytics['byDifficulty'] ??= <String, dynamic>{};
    analytics['byDifficulty']['level_$difficulty'] = (analytics['byDifficulty']['level_$difficulty'] ?? 0) + count;
    analytics['lastGeneration'] = DateTime.now().millisecondsSinceEpoch;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_difficultyAnalyticsKey, json.encode(analytics));
  }

  Future<List<Map<String, dynamic>>> _getPerformanceHistory(SubjectType subject) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('${_performanceHistoryKey}_${subject.name}');
    
    if (historyJson != null) {
      final List<dynamic> historyList = json.decode(historyJson);
      return historyList.cast<Map<String, dynamic>>();
    }
    
    return [];
  }

  Future<void> _savePerformanceHistory(SubjectType subject, List<Map<String, dynamic>> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_performanceHistoryKey}_${subject.name}', json.encode(history));
  }

  // Get adaptive settings (make public)
  Future<Map<String, dynamic>> getAdaptiveSettings() async {
    return await _getAdaptiveSettings();
  }

  Future<Map<String, dynamic>> _getAdaptiveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_adaptiveSettingsKey);
    
    if (settingsJson != null) {
      return json.decode(settingsJson);
    }
    
    return {
      'enabled': true,
      'aggressiveness': 0.5, // How quickly to adjust difficulty
      'focusOnWeakAreas': true,
      'balanceQuestionTypes': true,
    };
  }

  Future<void> _ensureDefaultSettings() async {
    final settings = await _getAdaptiveSettings();
    if (settings.isEmpty) {
      await updateAdaptiveSettings({
        'enabled': true,
        'aggressiveness': 0.5,
        'focusOnWeakAreas': true,
        'balanceQuestionTypes': true,
      });
    }
  }

  Future<void> _analyzeUserPerformance() async {
    // Analyze overall user performance across subjects
    final analytics = await getDifficultyAnalytics();
    
    for (final subject in SubjectType.values) {
      final history = await _getPerformanceHistory(subject);
      if (history.isNotEmpty) {
        final performance = _analyzeRecentPerformance(history);
        analytics['subjectPerformance'] ??= <String, dynamic>{};
        analytics['subjectPerformance'][subject.name] = performance;
      }
    }
    
    analytics['lastAnalysis'] = DateTime.now().millisecondsSinceEpoch;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_difficultyAnalyticsKey, json.encode(analytics));
  }

  Map<String, dynamic> _getDefaultAnalytics() {
    return {
      'questionsGenerated': 0,
      'bySubject': <String, dynamic>{},
      'byDifficulty': <String, dynamic>{},
      'subjectPerformance': <String, dynamic>{},
      'lastGeneration': 0,
      'lastAnalysis': 0,
    };
  }

  /// Generate procedural questions without AI
  List<Map<String, dynamic>> _generateProceduralQuestions({
    required SubjectType subject,
    required int difficulty,
    required int questionCount,
    required List<String> weakAreas,
  }) {
    final Random random = Random();
    final List<Map<String, dynamic>> questions = [];
    
    for (int i = 0; i < questionCount; i++) {
      final question = _generateSingleProceduralQuestion(
        subject: subject,
        difficulty: difficulty,
        index: i,
        random: random,
        weakAreas: weakAreas,
      );
      questions.add(question);
    }
    
    return questions;
  }

  /// Generate a single procedural question
  Map<String, dynamic> _generateSingleProceduralQuestion({
    required SubjectType subject,
    required int difficulty,
    required int index,
    required Random random,
    required List<String> weakAreas,
  }) {
    switch (subject) {
      case SubjectType.math:
        return _generateMathQuestion(difficulty, index, random);
      case SubjectType.science:
        return _generateScienceQuestion(difficulty, index, random);
      case SubjectType.english:
        return _generateEnglishQuestion(difficulty, index, random);
      case SubjectType.history:
        return _generateHistoryQuestion(difficulty, index, random);
      case SubjectType.geography:
        return _generateGeographyQuestion(difficulty, index, random);
      case SubjectType.physics:
        return _generatePhysicsQuestion(difficulty, index, random);
      case SubjectType.chemistry:
        return _generateChemistryQuestion(difficulty, index, random);
      case SubjectType.biology:
        return _generateBiologyQuestion(difficulty, index, random);
      case SubjectType.computerScience:
        return _generateComputerScienceQuestion(difficulty, index, random);
      case SubjectType.art:
        return _generateArtQuestion(difficulty, index, random);
      case SubjectType.music:
        return _generateMusicQuestion(difficulty, index, random);
      case SubjectType.physicalEducation:
        return _generatePhysicalEducationQuestion(difficulty, index, random);
    }
  }

  Map<String, dynamic> _generateMathQuestion(int difficulty, int index, Random random) {
    final operations = ['+', '-', '*', '/'];
    final operation = operations[random.nextInt(operations.length)];
    
    int a, b, answer;
    String questionText;
    
    final multiplier = (difficulty + 1) * 10;
    
    switch (operation) {
      case '+':
        a = random.nextInt(multiplier) + 1;
        b = random.nextInt(multiplier) + 1;
        answer = a + b;
        questionText = 'What is $a + $b?';
        break;
      case '-':
        a = random.nextInt(multiplier) + multiplier;
        b = random.nextInt(a);
        answer = a - b;
        questionText = 'What is $a - $b?';
        break;
      case '*':
        a = random.nextInt(12) + 1;
        b = random.nextInt(12) + 1;
        answer = a * b;
        questionText = 'What is $a × $b?';
        break;
      case '/':
        answer = random.nextInt(12) + 1;
        b = random.nextInt(12) + 1;
        a = answer * b;
        questionText = 'What is $a ÷ $b?';
        break;
      default:
        a = 1; b = 1; answer = 2;
        questionText = 'What is 1 + 1?';
    }
    
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
      'difficulty': difficulty,
      'subject': 'math',
      'explanation': 'The correct answer is $answer.',
    };
  }

  Map<String, dynamic> _generateScienceQuestion(int difficulty, int index, Random random) {
    final questions = [
      {
        'text': 'Which planet is closest to the Sun?',
        'options': ['Mercury', 'Venus', 'Earth', 'Mars'],
        'correct': 'Mercury',
        'explanation': 'Mercury is the closest planet to the Sun.',
      },
      {
        'text': 'What gas do plants absorb from the atmosphere?',
        'options': ['Oxygen', 'Carbon Dioxide', 'Nitrogen', 'Hydrogen'],
        'correct': 'Carbon Dioxide',
        'explanation': 'Plants absorb carbon dioxide during photosynthesis.',
      },
      {
        'text': 'How many bones are in the adult human body?',
        'options': ['206', '208', '210', '212'],
        'correct': '206',
        'explanation': 'The adult human body has 206 bones.',
      },
    ];
    
    final question = questions[random.nextInt(questions.length)];
    
    return {
      'id': 'science_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'difficulty': difficulty,
      'subject': 'science',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generateEnglishQuestion(int difficulty, int index, Random random) {
    final questions = [
      {
        'text': 'What is the plural of "child"?',
        'options': ['childs', 'children', 'childes', 'child'],
        'correct': 'children',
        'explanation': 'The plural of "child" is "children".',
      },
      {
        'text': 'Which word is a synonym for "happy"?',
        'options': ['sad', 'joyful', 'angry', 'tired'],
        'correct': 'joyful',
        'explanation': 'Joyful is a synonym for happy.',
      },
      {
        'text': 'What type of word is "quickly"?',
        'options': ['noun', 'verb', 'adjective', 'adverb'],
        'correct': 'adverb',
        'explanation': 'Quickly is an adverb that describes how something is done.',
      },
    ];
    
    final question = questions[random.nextInt(questions.length)];
    
    return {
      'id': 'english_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'difficulty': difficulty,
      'subject': 'english',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generateHistoryQuestion(int difficulty, int index, Random random) {
    final questions = [
      {
        'text': 'Who was the first President of the United States?',
        'options': ['George Washington', 'Thomas Jefferson', 'John Adams', 'Benjamin Franklin'],
        'correct': 'George Washington',
        'explanation': 'George Washington was the first President of the United States.',
      },
      {
        'text': 'In which year did World War II end?',
        'options': ['1944', '1945', '1946', '1947'],
        'correct': '1945',
        'explanation': 'World War II ended in 1945.',
      },
      {
        'text': 'Which ancient wonder was located in Egypt?',
        'options': ['Hanging Gardens', 'Colossus of Rhodes', 'Great Pyramid', 'Lighthouse of Alexandria'],
        'correct': 'Great Pyramid',
        'explanation': 'The Great Pyramid of Giza was located in Egypt.',
      },
    ];
    
    final question = questions[random.nextInt(questions.length)];
    
    return {
      'id': 'history_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'difficulty': difficulty,
      'subject': 'history',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generateGeographyQuestion(int difficulty, int index, Random random) {
    final questions = [
      {
        'text': 'What is the capital of France?',
        'options': ['London', 'Berlin', 'Paris', 'Madrid'],
        'correct': 'Paris',
        'explanation': 'Paris is the capital of France.',
      },
      {
        'text': 'Which is the largest continent?',
        'options': ['Africa', 'Asia', 'North America', 'Europe'],
        'correct': 'Asia',
        'explanation': 'Asia is the largest continent by both area and population.',
      },
      {
        'text': 'What is the longest river in the world?',
        'options': ['Amazon', 'Nile', 'Mississippi', 'Yangtze'],
        'correct': 'Nile',
        'explanation': 'The Nile River is the longest river in the world.',
      },
    ];
    
    final question = questions[random.nextInt(questions.length)];
    
    return {
      'id': 'geography_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'difficulty': difficulty,
      'subject': 'geography',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generatePhysicsQuestion(int difficulty, int index, Random random) {
    final questions = [
      {
        'text': 'What is the unit of force?',
        'options': ['Newton', 'Joule', 'Watt', 'Pascal'],
        'correct': 'Newton',
        'explanation': 'The Newton is the SI unit of force.',
      },
      {
        'text': 'What is the speed of light in vacuum?',
        'options': ['300,000 km/s', '299,792,458 m/s', '186,000 miles/s', 'All of the above'],
        'correct': 'All of the above',
        'explanation': 'The speed of light is approximately 299,792,458 m/s or 300,000 km/s or 186,000 miles/s.',
      },
    ];
    
    final question = questions[random.nextInt(questions.length)];
    
    return {
      'id': 'physics_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'difficulty': difficulty,
      'subject': 'physics',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generateChemistryQuestion(int difficulty, int index, Random random) {
    final questions = [
      {
        'text': 'What is the chemical symbol for water?',
        'options': ['H2O', 'CO2', 'NaCl', 'O2'],
        'correct': 'H2O',
        'explanation': 'Water is composed of two hydrogen atoms and one oxygen atom (H2O).',
      },
      {
        'text': 'What is the atomic number of carbon?',
        'options': ['6', '12', '14', '8'],
        'correct': '6',
        'explanation': 'Carbon has 6 protons, so its atomic number is 6.',
      },
    ];
    
    final question = questions[random.nextInt(questions.length)];
    
    return {
      'id': 'chemistry_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'difficulty': difficulty,
      'subject': 'chemistry',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generateBiologyQuestion(int difficulty, int index, Random random) {
    final questions = [
      {
        'text': 'What is the powerhouse of the cell?',
        'options': ['Nucleus', 'Mitochondria', 'Ribosome', 'Cytoplasm'],
        'correct': 'Mitochondria',
        'explanation': 'Mitochondria are known as the powerhouse of the cell because they produce ATP.',
      },
      {
        'text': 'How many chambers does a human heart have?',
        'options': ['2', '3', '4', '5'],
        'correct': '4',
        'explanation': 'The human heart has four chambers: two atria and two ventricles.',
      },
    ];
    
    final question = questions[random.nextInt(questions.length)];
    
    return {
      'id': 'biology_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'difficulty': difficulty,
      'subject': 'biology',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generateComputerScienceQuestion(int difficulty, int index, Random random) {
    final questions = [
      {
        'text': 'What does CPU stand for?',
        'options': ['Central Processing Unit', 'Computer Processing Unit', 'Central Program Unit', 'Computer Program Unit'],
        'correct': 'Central Processing Unit',
        'explanation': 'CPU stands for Central Processing Unit.',
      },
      {
        'text': 'Which programming language is known for web development?',
        'options': ['Python', 'JavaScript', 'C++', 'Java'],
        'correct': 'JavaScript',
        'explanation': 'JavaScript is primarily used for web development.',
      },
    ];
    
    final question = questions[random.nextInt(questions.length)];
    
    return {
      'id': 'computer_science_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'difficulty': difficulty,
      'subject': 'computer_science',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generateArtQuestion(int difficulty, int index, Random random) {
    final questions = [
      {
        'text': 'Who painted the Mona Lisa?',
        'options': ['Vincent van Gogh', 'Leonardo da Vinci', 'Pablo Picasso', 'Michelangelo'],
        'correct': 'Leonardo da Vinci',
        'explanation': 'The Mona Lisa was painted by Leonardo da Vinci.',
      },
      {
        'text': 'What are the primary colors?',
        'options': ['Red, Blue, Yellow', 'Red, Green, Blue', 'Blue, Yellow, Green', 'Red, Orange, Yellow'],
        'correct': 'Red, Blue, Yellow',
        'explanation': 'The primary colors are red, blue, and yellow.',
      },
    ];
    
    final question = questions[random.nextInt(questions.length)];
    
    return {
      'id': 'art_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'difficulty': difficulty,
      'subject': 'art',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generateMusicQuestion(int difficulty, int index, Random random) {
    final questions = [
      {
        'text': 'How many strings does a standard guitar have?',
        'options': ['4', '5', '6', '7'],
        'correct': '6',
        'explanation': 'A standard guitar has 6 strings.',
      },
      {
        'text': 'What is the highest voice type in a choir?',
        'options': ['Alto', 'Soprano', 'Tenor', 'Bass'],
        'correct': 'Soprano',
        'explanation': 'Soprano is the highest voice type in a choir.',
      },
    ];
    
    final question = questions[random.nextInt(questions.length)];
    
    return {
      'id': 'music_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'difficulty': difficulty,
      'subject': 'music',
      'explanation': question['explanation'],
    };
  }

  Map<String, dynamic> _generatePhysicalEducationQuestion(int difficulty, int index, Random random) {
    final questions = [
      {
        'text': 'How many players are on a basketball team on the court at one time?',
        'options': ['4', '5', '6', '7'],
        'correct': '5',
        'explanation': 'There are 5 players on a basketball team on the court at one time.',
      },
      {
        'text': 'What is the maximum score in a single frame of bowling?',
        'options': ['10', '20', '30', '300'],
        'correct': '30',
        'explanation': 'The maximum score in a single frame is 30 (strike followed by two more strikes).',
      },
    ];
    
    final question = questions[random.nextInt(questions.length)];
    
    return {
      'id': 'physical_education_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'text': question['text'],
      'options': question['options'],
      'correctAnswer': question['correct'],
      'type': 'multiple_choice',
      'difficulty': difficulty,
      'subject': 'physical_education',
      'explanation': question['explanation'],
    };
  }
}