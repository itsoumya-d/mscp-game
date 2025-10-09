import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/question.dart';
import 'game_save_service.dart';
import 'unlimited_level_generator.dart';
// AI service removed for AI cleanup
import 'game_session_service.dart';
import 'skill_id_registry.dart';

/// Background service for pre-loading and caching game levels
/// Ensures levels are ready before users need them
class LevelPreloaderService {
  static const String _preloadStatusKey = 'level_preload_status';
  static const String _lastPreloadKey = 'last_preload_timestamp';
  static const int _preloadLevelsPerSubject = 15; // Pre-load 15 levels per subject/skill
  static const int _preloadCooldownHours = 6; // Re-preload every 6 hours
  
  static LevelPreloaderService? _instance;
  
  static LevelPreloaderService getInstance() {
    return _instance ??= LevelPreloaderService._();
  }
  
  LevelPreloaderService._();
  
  final UnlimitedLevelGenerator _levelGenerator = UnlimitedLevelGenerator.getInstance();
  // AI service removed for AI cleanup
  
  bool _isPreloading = false;
  Timer? _backgroundTimer;
  
  /// Initialize the preloader service
  Future<void> initialize() async {
    try {
      // Check if we need to preload
      if (await _shouldPreload()) {
        // Start background preloading
        _startBackgroundPreloading();
      }
      
      // Set up periodic preloading (every 6 hours)
      _backgroundTimer = Timer.periodic(
        const Duration(hours: _preloadCooldownHours),
        (_) => _startBackgroundPreloading(),
      );
      
      debugPrint('LevelPreloaderService initialized');
    } catch (e) {
      debugPrint('Error initializing LevelPreloaderService: $e');
    }
  }
  
  /// Start background preloading of levels
  Future<void> _startBackgroundPreloading() async {
    if (_isPreloading) {
      debugPrint('Preloading already in progress, skipping');
      return;
    }
    
    _isPreloading = true;
    
    try {
      debugPrint('Starting background level preloading...');
      
      // Get all subjects that need preloading
      final subjects = [
        SubjectType.math,
        SubjectType.physics,
        SubjectType.chemistry,
        SubjectType.biology,
        SubjectType.computerScience,
        SubjectType.geography,
        SubjectType.history,
      ];
      
      int totalPreloaded = 0;
      
      for (final subject in subjects) {
        final skills = await _getSkillsForSubject(subject);
        
        for (final skillId in skills) {
          try {
            // Check if this skill already has enough cached levels
            final existingLevels = await _levelGenerator.getGeneratedLevels(subject, skillId);
            
            if (existingLevels.length < _preloadLevelsPerSubject) {
              final skillName = await _getSkillName(subject, skillId);
              
              // Generate missing levels
              final levelsToGenerate = _preloadLevelsPerSubject - existingLevels.length;
              
              debugPrint('Preloading $levelsToGenerate levels for ${subject.name} - $skillName');
              
              final result = await _levelGenerator.generateUnlimitedLevels(
                subject: subject,
                skillId: skillId,
                skillName: skillName,
                numberOfLevels: levelsToGenerate,
              );
              
              if (result['success'] == true) {
                totalPreloaded += result['totalGenerated'] as int;
                debugPrint('Successfully preloaded ${result['totalGenerated']} levels for ${subject.name} - $skillName');
              }
              
              // Small delay to prevent overwhelming the API
              await Future.delayed(const Duration(milliseconds: 300));
            }
          } catch (e) {
            debugPrint('Error preloading levels for ${subject.name} - $skillId: $e');
            // Continue with next skill even if one fails
          }
        }
      }
      
      // Update preload status
      await _updatePreloadStatus(totalPreloaded);
      
      debugPrint('Background preloading completed. Total levels preloaded: $totalPreloaded');
      
    } catch (e) {
      debugPrint('Error during background preloading: $e');
    } finally {
      _isPreloading = false;
    }
  }
  
  /// Check if we should preload levels
  Future<bool> _shouldPreload() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPreloadStr = prefs.getString(_lastPreloadKey);
      
      if (lastPreloadStr == null) {
        return true; // Never preloaded before
      }
      
      final lastPreload = DateTime.parse(lastPreloadStr);
      final now = DateTime.now();
      final hoursSinceLastPreload = now.difference(lastPreload).inHours;
      
      return hoursSinceLastPreload >= _preloadCooldownHours;
    } catch (e) {
      return true; // If error, assume we should preload
    }
  }
  
  /// Update preload status in SharedPreferences
  Future<void> _updatePreloadStatus(int levelsPreloaded) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final status = {
        'lastPreload': DateTime.now().toIso8601String(),
        'levelsPreloaded': levelsPreloaded,
        'version': '1.0',
      };
      
      await prefs.setString(_preloadStatusKey, jsonEncode(status));
      await prefs.setString(_lastPreloadKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error updating preload status: $e');
    }
  }
  
  /// Get cached level for immediate use
  Future<Map<String, dynamic>?> getCachedLevel({
    required SubjectType subject,
    required int level,
    String? skillId,
  }) async {
    try {
      // Use provided skillId or default to subject-based skill
      final targetSkillId = skillId ?? _getDefaultSkillForSubject(subject);
      
      // Get cached levels for this subject/skill
      final cachedLevels = await _levelGenerator.getGeneratedLevels(subject, targetSkillId);
      
      if (cachedLevels.isNotEmpty) {
        // Find level that matches the requested difficulty
        final matchingLevel = cachedLevels.where((l) => l['level'] == level).toList();
        
        if (matchingLevel.isNotEmpty) {
          debugPrint('Found cached level $level for ${subject.name} - $targetSkillId');
          return matchingLevel.first;
        }
        
        // If exact level not found, return closest level
        cachedLevels.sort((a, b) => (a['level'] as int).compareTo(b['level'] as int));
        final closestLevel = cachedLevels.firstWhere(
          (l) => (l['level'] as int) >= level,
          orElse: () => cachedLevels.last,
        );
        
        debugPrint('Using closest cached level ${closestLevel['level']} for requested level $level');
        return closestLevel;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting cached level: $e');
      return null;
    }
  }
  
  /// Force preload levels for a specific subject/skill
  Future<bool> forcePreloadForSubject({
    required SubjectType subject,
    String? skillId,
    int numberOfLevels = 10,
  }) async {
    try {
      final targetSkillId = skillId ?? _getDefaultSkillForSubject(subject);
      final skillName = await _getSkillName(subject, targetSkillId);
      
      debugPrint('Force preloading $numberOfLevels levels for ${subject.name} - $skillName');
      
      final result = await _levelGenerator.generateUnlimitedLevels(
        subject: subject,
        skillId: targetSkillId,
        skillName: skillName,
        numberOfLevels: numberOfLevels,
      );
      
      return result['success'] == true;
    } catch (e) {
      debugPrint('Error force preloading for ${subject.name}: $e');
      return false;
    }
  }
  
  /// Get preload status
  Future<Map<String, dynamic>> getPreloadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = prefs.getString(_preloadStatusKey);
      
      if (statusJson != null) {
        return jsonDecode(statusJson);
      }
      
      return {
        'lastPreload': null,
        'levelsPreloaded': 0,
        'version': '1.0',
      };
    } catch (e) {
      return {
        'lastPreload': null,
        'levelsPreloaded': 0,
        'version': '1.0',
        'error': e.toString(),
      };
    }
  }
  
  /// Get skills for a subject using the centralized SkillIdRegistry
  Future<List<String>> _getSkillsForSubject(SubjectType subject) async {
    // Use the centralized SkillIdRegistry to ensure consistency
    return SkillIdRegistry.getSkillIdsForSubject(subject);
  }
  
  /// Get default skill for a subject using the centralized SkillIdRegistry
  String _getDefaultSkillForSubject(SubjectType subject) {
    // Use the centralized SkillIdRegistry to ensure consistency
    return SkillIdRegistry.getDefaultSkillId(subject);
  }
  
  /// Get skill name from skill ID using the centralized SkillIdRegistry
  Future<String> _getSkillName(SubjectType subject, String skillId) async {
    // Use the centralized SkillIdRegistry to ensure consistency
    return SkillIdRegistry.getSkillName(skillId);
  }

  /// Get cached game session for immediate use
  Future<SevenQuestionGameSession?> getCachedGameSession(SubjectType subject, int level) async {
    try {
      // Use the existing getCachedLevel method to get level data
      final cachedLevel = await getCachedLevel(
        subject: subject,
        level: level,
      );
      
      if (cachedLevel != null) {
        // Convert cached level data to SevenQuestionGameSession
        return _convertLevelToGameSession(cachedLevel, subject, level);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting cached game session: $e');
      return null;
    }
  }

  /// Cache a game session for future use
  Future<void> cacheGameSession(SubjectType subject, int level, SevenQuestionGameSession session) async {
    try {
      // Convert game session to level format and cache it
      final levelData = _convertGameSessionToLevel(session);
      
      // Store in the level generator's cache
      await _levelGenerator.saveGeneratedLevels(subject, session.skillId, [levelData]);
      
      debugPrint('Cached game session for ${subject.name} level $level');
    } catch (e) {
      debugPrint('Error caching game session: $e');
    }
  }

  /// Preload levels in background for upcoming gameplay
  void preloadLevelsInBackground(SubjectType subject, int startingLevel) {
    // Start background preloading without blocking
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        final skillId = _getDefaultSkillForSubject(subject);
        final skillName = await _getSkillName(subject, skillId);
        
        // Preload next 5 levels
        final result = await _levelGenerator.generateUnlimitedLevels(
          subject: subject,
          skillId: skillId,
          skillName: skillName,
          numberOfLevels: 5,
        );
        
        if (result['success'] == true) {
          debugPrint('Background preloaded ${result['totalGenerated']} levels for ${subject.name}');
        }
      } catch (e) {
        debugPrint('Error in background preloading: $e');
      }
    });
  }

  /// Convert cached level data to SevenQuestionGameSession
  SevenQuestionGameSession? _convertLevelToGameSession(
    Map<String, dynamic> levelData, 
    SubjectType subject, 
    int level
  ) {
    try {
      final questions = levelData['questions'] as List<dynamic>?;
      if (questions == null || questions.isEmpty) {
        return null;
      }

      // Convert questions to Question objects
      final questionObjects = questions.map((q) {
        return Question(
          id: q['id'] ?? 'q_${DateTime.now().millisecondsSinceEpoch}',
          type: QuestionType.values.firstWhere(
            (type) => type.name == q['type'],
            orElse: () => QuestionType.multipleChoice,
          ),
          questionText: q['questionText'] ?? '',
          options: List<String>.from(q['options'] ?? []),
          correctAnswer: q['correctAnswer'] ?? '',
          explanation: q['explanation'] ?? '',
          hint: q['hint'] ?? '',
          difficulty: q['difficulty'] ?? level,
          subject: subject,
        );
      }).toList();

      // Ensure we have exactly 7 questions
      while (questionObjects.length < 7) {
        questionObjects.add(_generateFallbackQuestion(subject, level, questionObjects.length + 1));
      }

      return SevenQuestionGameSession(
        id: levelData['id'] ?? 'cached_${DateTime.now().millisecondsSinceEpoch}',
        subject: subject,
        level: level,
        skillId: levelData['skillId'] ?? _getDefaultSkillForSubject(subject),
        questions: questionObjects.take(7).toList(),
        userAnswers: List.filled(7, ''),
        answerCorrectness: List.filled(7, false),
        currentQuestionIndex: 0,
        startTime: DateTime.now(),
        score: 0,
        isCompleted: false,
      );
    } catch (e) {
      debugPrint('Error converting level to game session: $e');
      return null;
    }
  }

  /// Convert SevenQuestionGameSession to level format for caching
  Map<String, dynamic> _convertGameSessionToLevel(SevenQuestionGameSession session) {
    return {
      'id': session.id,
      'level': session.level,
      'skillId': session.skillId,
      'subject': session.subject.name,
      'questions': session.questions.map((q) => {
        'id': q.id,
        'type': q.type.name,
        'questionText': q.questionText,
        'options': q.options,
        'correctAnswer': q.correctAnswer,
        'explanation': q.explanation,
        'hint': q.hint,
        'difficulty': q.difficulty,
      }).toList(),
      'createdAt': session.startTime.toIso8601String(),
    };
  }

  /// Generate a fallback question when needed
  Question _generateFallbackQuestion(SubjectType subject, int level, int questionNumber) {
    final subjectName = subject.name.toLowerCase();
    
    return Question(
      id: 'fallback_${questionNumber}_${DateTime.now().millisecondsSinceEpoch}',
      type: QuestionType.multipleChoice,
      questionText: 'What is a key concept in $subjectName at level $level?',
      options: [
        'Concept A',
        'Concept B', 
        'Concept C',
        'Concept D'
      ],
      correctAnswer: 'Concept A',
      explanation: 'This is a fundamental concept in $subjectName.',
      hint: 'Think about the basic principles of $subjectName.',
      difficulty: level,
      subject: subject,
    );
  }
  
  /// Check if preloading is currently in progress
  bool get isPreloading => _isPreloading;
  
  /// Dispose the service
  void dispose() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
  }
}