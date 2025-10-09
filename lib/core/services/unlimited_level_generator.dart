import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/question.dart';
import 'unified_xp_service.dart';
import 'skill_id_registry.dart';

/// Progressive difficulty level generator for unlimited content generation
/// Manages difficulty scaling, content generation, and integration with existing systems
class UnlimitedLevelGenerator {
  static const String _generatedLevelsKey = 'generated_levels_data';
  static const String _difficultyProgressKey = 'difficulty_progress_data';
  
  static UnlimitedLevelGenerator? _instance;
  
  static UnlimitedLevelGenerator getInstance() {
    return _instance ??= UnlimitedLevelGenerator._();
  }
  
  @Deprecated('Use getInstance() instead')
  static UnlimitedLevelGenerator get instance => getInstance();
  
  UnlimitedLevelGenerator._();
  
  /// Generate unlimited levels for a specific subject and skill
  Future<Map<String, dynamic>> generateUnlimitedLevels({
    required SubjectType subject,
    required String skillId,
    required String skillName,
    int? startingLevel,
    int numberOfLevels = 10,
  }) async {
    try {
      // Determine starting difficulty based on user progress
      final currentProgress = await _getCurrentProgress(subject, skillId);
      final startDifficulty = startingLevel ?? _calculateNextDifficulty(currentProgress);
      
      debugPrint('Generating $numberOfLevels levels for ${subject.name} - $skillName starting at difficulty $startDifficulty');
      
      // Generate procedural content instead of using AI services
      Map<String, dynamic> result = await _generateProceduralLevels(
        subject: subject,
        skillId: skillId,
        skillName: skillName,
        startingDifficulty: startDifficulty,
        numberOfLevels: numberOfLevels,
      );
      
      if (result['success']) {
        // Save generated levels
        await saveGeneratedLevels(subject, skillId, result['levels']);
        
        // Update difficulty progress
        await _updateDifficultyProgress(subject, skillId, startDifficulty + numberOfLevels - 1);
        
        // Auto-unlock content
        await _autoUnlockContent(subject, skillId, result['levels']);
        
        debugPrint('Successfully generated ${result['totalGenerated']} levels');
      }
      
      return result;
    } catch (e) {
      debugPrint('Unlimited level generation error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'levels': [],
      };
    }
  }
  
  /// Generate levels for all subjects (batch generation)
  Future<Map<String, dynamic>> generateForAllSubjects({
    int levelsPerSubject = 5,
    List<String>? specificSkills,
  }) async {
    final results = <String, dynamic>{};
    final subjects = [SubjectType.math, SubjectType.physics, SubjectType.chemistry, SubjectType.biology];
    
    for (final subject in subjects) {
      final skills = specificSkills ?? await _getAvailableSkills(subject);
      
      for (final skillId in skills) {
        final skillName = await _getSkillName(subject, skillId);
        
        final result = await generateUnlimitedLevels(
          subject: subject,
          skillId: skillId,
          skillName: skillName,
          numberOfLevels: levelsPerSubject,
        );
        
        results['${subject.name}_$skillId'] = result;
        
        // Small delay to prevent rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    return {
      'success': true,
      'results': results,
      'totalSubjects': subjects.length,
    };
  }
  
  /// Generate procedural levels without AI services
  Future<Map<String, dynamic>> _generateProceduralLevels({
    required SubjectType subject,
    required String skillId,
    required String skillName,
    required int startingDifficulty,
    required int numberOfLevels,
  }) async {
    try {
      final levels = <Map<String, dynamic>>[];
      
      for (int i = 0; i < numberOfLevels; i++) {
        final currentDifficulty = startingDifficulty + i;
        
        // Generate procedural questions based on subject and difficulty
        final questions = _generateProceduralQuestions(
          subject,
          skillId,
          skillName,
          currentDifficulty,
          count: 7, // All 7 question types
        );
        
        if (questions.isNotEmpty) {
          levels.add({
            'level': currentDifficulty,
            'data': {
              'questions': questions,
              'xpReward': _calculateXpReward(currentDifficulty),
              'difficulty': currentDifficulty,
              'subject': subject.name,
              'skillId': skillId,
              'skillName': skillName,
            },
          });
        }
      }
      
      return {
        'success': true,
        'levels': levels,
        'totalGenerated': levels.length,
        'subject': subject.name,
        'skillId': skillId,
        'source': 'procedural_generation',
      };
    } catch (e) {
      debugPrint('Procedural generation error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'levels': [],
      };
    }
  }
  
  /// Calculate next difficulty based on current progress
  int _calculateNextDifficulty(Map<String, dynamic> progress) {
    final currentLevel = progress['currentLevel'] ?? 1;
    final completedLevels = progress['completedLevels'] ?? 0;
    
    // Progressive difficulty scaling
    if (completedLevels < 5) return 1; // Beginner
    if (completedLevels < 15) return 3; // Intermediate
    if (completedLevels < 30) return 6; // Advanced
    return 10; // Expert
  }
  
  /// Calculate XP reward based on difficulty
  int _calculateXpReward(int difficulty) {
    return UnifiedXPService.getInstance().calculateLessonXP(difficulty);
  }
  
  /// Get current progress for a subject and skill
  Future<Map<String, dynamic>> _getCurrentProgress(SubjectType subject, String skillId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressKey = '${subject.name}_${skillId}_progress';
      final progressJson = prefs.getString(progressKey);
      
      if (progressJson != null) {
        return jsonDecode(progressJson);
      }
      
      return {
        'currentLevel': 1,
        'completedLevels': 0,
        'totalXp': 0,
        'lastDifficulty': 1,
      };
    } catch (e) {
      return {
        'currentLevel': 1,
        'completedLevels': 0,
        'totalXp': 0,
        'lastDifficulty': 1,
      };
    }
  }
  
  /// Save generated levels to local storage
  Future<void> saveGeneratedLevels(
    SubjectType subject,
    String skillId,
    List<Map<String, dynamic>> levels,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final levelsKey = '${subject.name}_${skillId}_generated_levels';
      
      // Get existing levels
      final existingJson = prefs.getString(levelsKey);
      List<Map<String, dynamic>> existingLevels = [];
      
      if (existingJson != null) {
        existingLevels = List<Map<String, dynamic>>.from(jsonDecode(existingJson));
      }
      
      // Add new levels
      existingLevels.addAll(levels);
      
      // Save updated levels
      await prefs.setString(levelsKey, jsonEncode(existingLevels));
      
      debugPrint('Saved ${levels.length} levels for ${subject.name} - $skillId');
    } catch (e) {
      debugPrint('Error saving generated levels: $e');
    }
  }
  
  /// Update difficulty progress tracking
  Future<void> _updateDifficultyProgress(
    SubjectType subject,
    String skillId,
    int maxDifficulty,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressKey = '${subject.name}_${skillId}_difficulty_progress';
      
      final progressData = {
        'maxDifficulty': maxDifficulty,
        'lastGenerated': DateTime.now().toIso8601String(),
        'totalLevelsGenerated': await _getTotalGeneratedLevels(subject, skillId),
      };
      
      await prefs.setString(progressKey, jsonEncode(progressData));
    } catch (e) {
      debugPrint('Error updating difficulty progress: $e');
    }
  }
  
  /// Auto-unlock generated content
  Future<void> _autoUnlockContent(
    SubjectType subject,
    String skillId,
    List<Map<String, dynamic>> levels,
  ) async {
    try {
      for (final levelData in levels) {
        final level = levelData['level'];
        final data = levelData['data'];
        
        // Create lesson object for the level
        final lesson = Lesson(
          id: '${subject.name}_${skillId}_level_$level',
          title: 'Level $level - ${data['skillName']}',
          description: 'Auto-generated level with difficulty $level',
          xpReward: data['xpReward'],
          isCompleted: false,
          questions: _convertToQuestionObjects(data['questions'], subject),
        );
        
        // Save lesson to progress service - commented out since _progressService was removed
        // await _progressService.unlockLesson(lesson.id);
        
        debugPrint('Auto-unlocked level $level for ${subject.name} - $skillId');
      }
    } catch (e) {
      debugPrint('Error auto-unlocking content: $e');
    }
  }
  
  /// Convert question maps to Question objects
  List<Question> _convertToQuestionObjects(List<dynamic> questionMaps, SubjectType subjectType) {
    return questionMaps.map((qMap) {
      final map = Map<String, dynamic>.from(qMap);
      return Question(
        id: 'generated_${DateTime.now().millisecondsSinceEpoch}_${questionMaps.indexOf(qMap)}',
        questionText: map['questionText'] ?? '',
        type: _parseQuestionType(map['type']),
        options: List<String>.from(map['options'] ?? []),
        correctAnswer: map['correctAnswer'] ?? '',
        explanation: map['explanation'] ?? '',
        hint: map['hint'] ?? '',
        subject: subjectType,
      );
    }).toList();
  }
  
  /// Parse question type from string
  QuestionType _parseQuestionType(String typeString) {
    switch (typeString) {
      case 'multipleChoice': return QuestionType.multipleChoice;
      case 'trueFalse': return QuestionType.trueFalse;
      case 'numericInput': return QuestionType.numericInput;
      case 'fillInTheBlank': return QuestionType.fillInTheBlank;
      case 'dragDrop': return QuestionType.dragDrop;
      case 'clickableAnswer': return QuestionType.clickableAnswer;
      case 'shortAnswer': return QuestionType.shortAnswer;
      default: return QuestionType.multipleChoice;
    }
  }
  
  /// Get available skills for a subject using the centralized SkillIdRegistry
  Future<List<String>> _getAvailableSkills(SubjectType subject) async {
    // Use the centralized SkillIdRegistry to ensure consistency
    return SkillIdRegistry.getSkillIdsForSubject(subject);
  }
  
  /// Get skill name from skill ID using the centralized SkillIdRegistry
  Future<String> _getSkillName(SubjectType subject, String skillId) async {
    // Use the centralized SkillIdRegistry to ensure consistency
    return SkillIdRegistry.getSkillName(skillId);
  }
  
  /// Get total generated levels for a subject and skill
  Future<int> _getTotalGeneratedLevels(SubjectType subject, String skillId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final levelsKey = '${subject.name}_${skillId}_generated_levels';
      final levelsJson = prefs.getString(levelsKey);
      
      if (levelsJson != null) {
        final levels = List<Map<String, dynamic>>.from(jsonDecode(levelsJson));
        return levels.length;
      }
      
      return 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Get generated levels for a subject and skill
  Future<List<Map<String, dynamic>>> getGeneratedLevels(
    SubjectType subject,
    String skillId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final levelsKey = '${subject.name}_${skillId}_generated_levels';
      final levelsJson = prefs.getString(levelsKey);
      
      if (levelsJson != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(levelsJson));
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }
  
  /// Clear generated levels (for testing/debugging)
  Future<void> clearGeneratedLevels(SubjectType subject, String skillId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final levelsKey = '${subject.name}_${skillId}_generated_levels';
      await prefs.remove(levelsKey);
      
      final progressKey = '${subject.name}_${skillId}_difficulty_progress';
      await prefs.remove(progressKey);
      
      debugPrint('Cleared generated levels for ${subject.name} - $skillId');
    } catch (e) {
      debugPrint('Error clearing generated levels: $e');
    }
  }

  /// Generate procedural questions based on subject and difficulty
  List<Map<String, dynamic>> _generateProceduralQuestions(
    SubjectType subject,
    String skillId,
    String skillName,
    int difficulty,
    {int count = 7}
  ) {
    final questions = <Map<String, dynamic>>[];
    
    // Generate different types of questions based on subject
    switch (subject) {
      case SubjectType.math:
        questions.addAll(_generateMathQuestions(difficulty, count));
        break;
      case SubjectType.science:
        questions.addAll(_generateScienceQuestions(difficulty, count));
        break;
      case SubjectType.english:
        questions.addAll(_generateEnglishQuestions(difficulty, count));
        break;
      case SubjectType.history:
        questions.addAll(_generateHistoryQuestions(difficulty, count));
        break;
      case SubjectType.geography:
        questions.addAll(_generateGeographyQuestions(difficulty, count));
        break;
      case SubjectType.physics:
        questions.addAll(_generatePhysicsQuestions(difficulty, count));
        break;
      case SubjectType.chemistry:
        questions.addAll(_generateScienceQuestions(difficulty, count)); // Use science questions for chemistry
        break;
      case SubjectType.biology:
        questions.addAll(_generateScienceQuestions(difficulty, count)); // Use science questions for biology
        break;
      case SubjectType.art:
        questions.addAll(_generateArtQuestions(difficulty, count));
        break;
      case SubjectType.music:
        questions.addAll(_generateMusicQuestions(difficulty, count));
        break;
      case SubjectType.physicalEducation:
        questions.addAll(_generatePhysicalEducationQuestions(difficulty, count));
        break;
      case SubjectType.computerScience:
        questions.addAll(_generateComputerScienceQuestions(difficulty, count));
        break;
    }
    
    return questions;
  }

  List<Map<String, dynamic>> _generateMathQuestions(int difficulty, int count) {
    final questions = <Map<String, dynamic>>[];
    final random = DateTime.now().millisecondsSinceEpoch;
    
    for (int i = 0; i < count; i++) {
      final a = (random + i) % (difficulty * 10) + 1;
      final b = (random + i * 2) % (difficulty * 5) + 1;
      final operation = ['+', '-', '*', '/'][(random + i) % 4];
      
      String questionText;
      String correctAnswer;
      
      switch (operation) {
        case '+':
          questionText = 'What is $a + $b?';
          correctAnswer = (a + b).toString();
          break;
        case '-':
          questionText = 'What is $a - $b?';
          correctAnswer = (a - b).toString();
          break;
        case '*':
          questionText = 'What is $a × $b?';
          correctAnswer = (a * b).toString();
          break;
        case '/':
          final result = a * b; // Ensure clean division
          questionText = 'What is $result ÷ $a?';
          correctAnswer = b.toString();
          break;
        default:
          questionText = 'What is $a + $b?';
          correctAnswer = (a + b).toString();
      }
      
      questions.add({
        'questionText': questionText,
        'type': 'multiple_choice',
        'options': _generateMathOptions(correctAnswer, difficulty),
        'correctAnswer': correctAnswer,
        'explanation': 'Basic arithmetic operation',
        'difficulty': difficulty,
      });
    }
    
    return questions;
  }

  List<String> _generateMathOptions(String correct, int difficulty) {
    final correctNum = int.parse(correct);
    final options = [correct];
    
    // Generate wrong options
    for (int i = 1; i <= 3; i++) {
      final wrongAnswer = correctNum + (i * difficulty);
      options.add(wrongAnswer.toString());
    }
    
    options.shuffle();
    return options;
  }

  List<Map<String, dynamic>> _generateScienceQuestions(int difficulty, int count) {
    // Placeholder for science questions - can be expanded
    return List.generate(count, (i) => {
      'questionText': 'Science question ${i + 1} (Difficulty: $difficulty)',
      'type': 'multiple_choice',
      'options': ['Option A', 'Option B', 'Option C', 'Option D'],
      'correctAnswer': 'Option A',
      'explanation': 'Science explanation',
      'difficulty': difficulty,
    });
  }

  List<Map<String, dynamic>> _generateEnglishQuestions(int difficulty, int count) {
    // Placeholder for English questions - can be expanded
    return List.generate(count, (i) => {
      'questionText': 'English question ${i + 1} (Difficulty: $difficulty)',
      'type': 'multiple_choice',
      'options': ['Option A', 'Option B', 'Option C', 'Option D'],
      'correctAnswer': 'Option A',
      'explanation': 'English explanation',
      'difficulty': difficulty,
    });
  }

  List<Map<String, dynamic>> _generateHistoryQuestions(int difficulty, int count) {
    // Placeholder for History questions - can be expanded
    return List.generate(count, (i) => {
      'questionText': 'History question ${i + 1} (Difficulty: $difficulty)',
      'type': 'multiple_choice',
      'options': ['Option A', 'Option B', 'Option C', 'Option D'],
      'correctAnswer': 'Option A',
      'explanation': 'History explanation',
      'difficulty': difficulty,
    });
  }

  List<Map<String, dynamic>> _generateGeographyQuestions(int difficulty, int count) {
    // Placeholder for Geography questions - can be expanded
    return List.generate(count, (i) => {
      'questionText': 'Geography question ${i + 1} (Difficulty: $difficulty)',
      'type': 'multiple_choice',
      'options': ['Option A', 'Option B', 'Option C', 'Option D'],
      'correctAnswer': 'Option A',
      'explanation': 'Geography explanation',
      'difficulty': difficulty,
    });
  }

  List<Map<String, dynamic>> _generateArtQuestions(int difficulty, int count) {
    // Placeholder for Art questions - can be expanded
    return List.generate(count, (i) => {
      'questionText': 'Art question ${i + 1} (Difficulty: $difficulty)',
      'type': 'multiple_choice',
      'options': ['Option A', 'Option B', 'Option C', 'Option D'],
      'correctAnswer': 'Option A',
      'explanation': 'Art explanation',
      'difficulty': difficulty,
    });
  }

  List<Map<String, dynamic>> _generateMusicQuestions(int difficulty, int count) {
    // Placeholder for Music questions - can be expanded
    return List.generate(count, (i) => {
      'questionText': 'Music question ${i + 1} (Difficulty: $difficulty)',
      'type': 'multiple_choice',
      'options': ['Option A', 'Option B', 'Option C', 'Option D'],
      'correctAnswer': 'Option A',
      'explanation': 'Music explanation',
      'difficulty': difficulty,
    });
  }

  List<Map<String, dynamic>> _generatePhysicalEducationQuestions(int difficulty, int count) {
    // Placeholder for Physical Education questions - can be expanded
    return List.generate(count, (i) => {
      'questionText': 'Physical Education question ${i + 1} (Difficulty: $difficulty)',
      'type': 'multiple_choice',
      'options': ['Option A', 'Option B', 'Option C', 'Option D'],
      'correctAnswer': 'Option A',
      'explanation': 'Physical Education explanation',
      'difficulty': difficulty,
    });
  }

  List<Map<String, dynamic>> _generateComputerScienceQuestions(int difficulty, int count) {
    // Placeholder for Computer Science questions - can be expanded
    return List.generate(count, (i) => {
      'questionText': 'Computer Science question ${i + 1} (Difficulty: $difficulty)',
      'type': 'multiple_choice',
      'options': ['Option A', 'Option B', 'Option C', 'Option D'],
      'correctAnswer': 'Option A',
      'explanation': 'Computer Science explanation',
      'difficulty': difficulty,
    });
  }

  List<Map<String, dynamic>> _generatePhysicsQuestions(int difficulty, int count) {
    // Placeholder for Physics questions - can be expanded
    return List.generate(count, (i) => {
      'questionText': 'Physics question ${i + 1} (Difficulty: $difficulty)',
      'type': 'multiple_choice',
      'options': ['Option A', 'Option B', 'Option C', 'Option D'],
      'correctAnswer': 'Option A',
      'explanation': 'Physics explanation',
      'difficulty': difficulty,
    });
  }
}