/// Tutorial service for managing tutorial state
/// 
/// This service tracks which tutorials have been shown to the user
/// and persists this information using SharedPreferences.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tutorial_content.dart';

/// Provider for TutorialService
final tutorialServiceProvider = Provider<TutorialService>((ref) {
  return TutorialService();
});

/// Service for managing tutorial state
class TutorialService {
  static const String _tutorialPrefix = 'tutorial_shown_';
  static const String _tutorialSkippedPrefix = 'tutorial_skipped_';
  static const String _allTutorialsResetKey = 'all_tutorials_reset';
  
  /// Check if a tutorial has been shown
  Future<bool> hasShownTutorial(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_tutorialPrefix$tutorialId') ?? false;
  }
  
  /// Mark a tutorial as complete
  Future<void> markTutorialComplete(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_tutorialPrefix$tutorialId', true);
  }
  
  /// Check if a tutorial was skipped
  Future<bool> wasTutorialSkipped(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_tutorialSkippedPrefix$tutorialId') ?? false;
  }
  
  /// Mark a tutorial as skipped
  Future<void> markTutorialSkipped(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_tutorialSkippedPrefix$tutorialId', true);
    // Also mark as shown so it doesn't appear again
    await markTutorialComplete(tutorialId);
  }
  
  /// Reset a specific tutorial (for testing or replay)
  Future<void> resetTutorial(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_tutorialPrefix$tutorialId');
    await prefs.remove('$_tutorialSkippedPrefix$tutorialId');
  }
  
  /// Reset all tutorials (for testing)
  Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    // Remove all tutorial-related keys
    for (final key in keys) {
      if (key.startsWith(_tutorialPrefix) || 
          key.startsWith(_tutorialSkippedPrefix)) {
        await prefs.remove(key);
      }
    }
    
    // Mark that we've reset all tutorials
    await prefs.setBool(_allTutorialsResetKey, true);
  }
  
  /// Get tutorial completion status for all tutorials
  Future<Map<String, bool>> getTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final status = <String, bool>{};
    
    // Get all tutorial IDs
    final tutorialIds = [
      TutorialIds.homeScreen,
      TutorialIds.subjectSelection,
      TutorialIds.levelSelection,
      TutorialIds.gameSession,
      TutorialIds.multipleChoice,
      TutorialIds.trueFalse,
      TutorialIds.numericInput,
      TutorialIds.fillInBlank,
      TutorialIds.dragDrop,
      TutorialIds.clickableAnswer,
      TutorialIds.shortAnswer,
      TutorialIds.hints,
      TutorialIds.lives,
      TutorialIds.xpSystem,
      TutorialIds.levelUnlocking,
    ];
    
    // Check status for each tutorial
    for (final id in tutorialIds) {
      status[id] = prefs.getBool('$_tutorialPrefix$id') ?? false;
    }
    
    return status;
  }
  
  /// Get completion percentage (0.0 to 1.0)
  Future<double> getTutorialCompletionPercentage() async {
    final status = await getTutorialStatus();
    if (status.isEmpty) return 0.0;
    
    final completed = status.values.where((shown) => shown).length;
    return completed / status.length;
  }
  
  /// Check if this is a first-time user (no tutorials shown)
  Future<bool> isFirstTimeUser() async {
    final status = await getTutorialStatus();
    return !status.values.any((shown) => shown);
  }
  
  /// Check if user should see a tutorial for a question type
  Future<bool> shouldShowQuestionTypeTutorial(String questionType) async {
    final tutorialId = 'question_type_$questionType';
    return !(await hasShownTutorial(tutorialId));
  }
  
  /// Mark question type tutorial as shown
  Future<void> markQuestionTypeTutorialShown(String questionType) async {
    final tutorialId = 'question_type_$questionType';
    await markTutorialComplete(tutorialId);
  }
  
  /// Get list of tutorials that haven't been shown yet
  Future<List<String>> getPendingTutorials() async {
    final status = await getTutorialStatus();
    return status.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Get list of tutorials that have been completed
  Future<List<String>> getCompletedTutorials() async {
    final status = await getTutorialStatus();
    return status.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Enable/disable tutorials globally
  Future<void> setTutorialsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorials_enabled', enabled);
  }
  
  /// Check if tutorials are enabled
  Future<bool> areTutorialsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tutorials_enabled') ?? true; // Enabled by default
  }
}

/// Provider for checking if a specific tutorial has been shown
final hasTutorialBeenShownProvider = FutureProvider.family<bool, String>((ref, tutorialId) async {
  final service = ref.read(tutorialServiceProvider);
  return await service.hasShownTutorial(tutorialId);
});

/// Provider for tutorial completion status
final tutorialStatusProvider = FutureProvider<Map<String, bool>>((ref) async {
  final service = ref.read(tutorialServiceProvider);
  return await service.getTutorialStatus();
});

/// Provider for tutorial completion percentage
final tutorialCompletionProvider = FutureProvider<double>((ref) async {
  final service = ref.read(tutorialServiceProvider);
  return await service.getTutorialCompletionPercentage();
});

/// Provider for checking if user is first-time
final isFirstTimeUserProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(tutorialServiceProvider);
  return await service.isFirstTimeUser();
});

/// Provider for checking if tutorials are enabled
final tutorialsEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(tutorialServiceProvider);
  return await service.areTutorialsEnabled();
});

