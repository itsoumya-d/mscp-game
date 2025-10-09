import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/question.dart';
import '../models/educational_game.dart';
import '../models/question_pool.dart';
import 'predefined_games_manager.dart';
import 'game_save_service.dart';
import 'game_session_service.dart';
import 'loading_progress_service.dart';
import 'skill_id_registry.dart';

/// Optimized preloader service that uses fallback content immediately
/// Provides instant content availability without waiting for API calls
class FallbackContentPreloader {
  static FallbackContentPreloader? _instance;
  
  static FallbackContentPreloader getInstance() {
    return _instance ??= FallbackContentPreloader._();
  }
  
  FallbackContentPreloader._();
  
  final PredefinedGamesManager _predefinedGamesManager = PredefinedGamesManager.getInstance();
  final GameSaveService _gameSaveService = GameSaveService();
  final LoadingProgressService _progressService = LoadingProgressService.getInstance();

  bool _isInitialized = false;
  final Map<String, List<SevenQuestionGameSession>> _contentCache = {};

  static const int _levelsPerSubjectSkill = 10; // Preload 10 levels per subject/skill
  
  /// Initialize the fallback content preloader
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[FallbackContentPreloader] Already initialized');
      return;
    }
    
    try {
      debugPrint('[FallbackContentPreloader] Starting initialization...');
      
      // Preload fallback content for all subjects immediately
      await _preloadAllFallbackContent();
      
      _isInitialized = true;
      debugPrint('[FallbackContentPreloader] Initialization complete');
    } catch (e) {
      debugPrint('[FallbackContentPreloader] Error during initialization: $e');
    }
  }
  
  /// Preload fallback content for all subjects
  Future<void> _preloadAllFallbackContent() async {
    final subjects = [
      SubjectType.math,
      SubjectType.physics,
      SubjectType.chemistry,
      SubjectType.biology,
      SubjectType.computerScience,
      SubjectType.geography,
      SubjectType.history,
    ];

    // Calculate total items for progress tracking
    int totalSkills = 0;
    for (final subject in subjects) {
      totalSkills += _getSkillsForSubject(subject).length;
    }
    final totalSessions = totalSkills * _levelsPerSubjectSkill;

    // Start progress tracking
    final progressTracker = BatchProgressTracker(
      progressService: _progressService,
      operationId: 'fallback_preload',
      title: 'Loading Educational Content',
      subtitle: 'Preparing $totalSessions lessons across all subjects',
      totalItems: totalSessions,
    );

    int totalPreloaded = 0;

    for (final subject in subjects) {
      try {
        final skills = _getSkillsForSubject(subject);

        for (final skillId in skills) {
          final cacheKey = '${subject.name}_$skillId';

          // Generate fallback game sessions for this subject/skill
          final gameSessions = <SevenQuestionGameSession>[];

          for (int level = 1; level <= _levelsPerSubjectSkill; level++) {
            try {
              final gameSession = await _predefinedGamesManager.getPredefinedGameSession(
                subject: subject,
                level: level,
                skillId: skillId,
              );

              gameSessions.add(gameSession);
              totalPreloaded++;

              // Update progress
              progressTracker.incrementProgress(
                message: 'Loaded ${subject.name} - $skillId - Level $level',
              );
            } catch (e) {
              debugPrint('[FallbackContentPreloader] Error generating level $level for ${subject.name} - $skillId: $e');
            }
          }

          // Cache the generated sessions
          _contentCache[cacheKey] = gameSessions;

          debugPrint('[FallbackContentPreloader] Preloaded ${gameSessions.length} levels for ${subject.name} - $skillId');
        }
      } catch (e) {
        debugPrint('[FallbackContentPreloader] Error preloading ${subject.name}: $e');
      }
    }

    // Complete progress tracking
    progressTracker.complete();

    debugPrint('[FallbackContentPreloader] Total preloaded: $totalPreloaded levels across all subjects');
  }
  
  /// Get preloaded content for a subject and skill
  Future<SevenQuestionGameSession?> getPreloadedContent({
    required SubjectType subject,
    required String skillId,
    required int level,
  }) async {
    final cacheKey = '${subject.name}_$skillId';
    
    if (_contentCache.containsKey(cacheKey)) {
      final sessions = _contentCache[cacheKey]!;
      
      // Find session for the requested level
      final session = sessions.where((s) => s.level == level).firstOrNull;
      
      if (session != null) {
        debugPrint('[FallbackContentPreloader] Cache HIT for ${subject.name} - $skillId - Level $level');
        return session;
      }
    }
    
    debugPrint('[FallbackContentPreloader] Cache MISS for ${subject.name} - $skillId - Level $level');
    
    // Generate on-demand if not in cache
    return await _predefinedGamesManager.getPredefinedGameSession(
      subject: subject,
      level: level,
      skillId: skillId,
    );
  }
  
  /// Check if content is available for a subject/skill
  bool hasPreloadedContent(SubjectType subject, String skillId) {
    final cacheKey = '${subject.name}_$skillId';
    return _contentCache.containsKey(cacheKey) && _contentCache[cacheKey]!.isNotEmpty;
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    int totalSessions = 0;
    int totalQuestions = 0;
    
    for (final sessions in _contentCache.values) {
      totalSessions += sessions.length;
      for (final session in sessions) {
        totalQuestions += session.questions.length;
      }
    }
    
    return {
      'total_subjects': _contentCache.keys.length,
      'total_sessions': totalSessions,
      'total_questions': totalQuestions,
      'cache_size_mb': (totalQuestions * 500 / 1024 / 1024).toStringAsFixed(2), // Rough estimate
      'is_initialized': _isInitialized,
    };
  }
  
  /// Get skills for a subject using the centralized SkillIdRegistry
  List<String> _getSkillsForSubject(SubjectType subject) {
    // Use the centralized SkillIdRegistry to ensure consistency
    return SkillIdRegistry.getSkillIdsForSubject(subject);
  }
  
  /// Clear cache
  void clearCache() {
    _contentCache.clear();
    _isInitialized = false;
    debugPrint('[FallbackContentPreloader] Cache cleared');
  }
  
  /// Dispose resources
  void dispose() {
    clearCache();
    debugPrint('[FallbackContentPreloader] Disposed');
  }
}

