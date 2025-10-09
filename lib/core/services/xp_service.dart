import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';

/// Service to manage XP (Experience Points) for user progress
class XPService {
  static XPService? _instance;
  static XPService getInstance() {
    _instance ??= XPService._internal();
    return _instance!;
  }
  XPService._internal();

  static const String _xpDataKey = 'user_xp_data';
  static const String _totalXpKey = 'total_xp';

  /// Base XP rewards for different activities
  static const int baseQuestionXP = 10;
  static const int baseLessonXP = 50;
  static const int perfectScoreBonus = 25;
  static const int streakBonus = 5;

  /// Get current XP for a specific subject
  Future<int> getXP(SubjectType subject) async {
    final prefs = await SharedPreferences.getInstance();
    final xpData = prefs.getString(_xpDataKey);
    
    if (xpData == null) return 0;
    
    final Map<String, dynamic> data = jsonDecode(xpData);
    return data[subject.name] ?? 0;
  }

  /// Get total XP across all subjects
  Future<int> getTotalXP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalXpKey) ?? 0;
  }

  /// Add XP to a specific subject
  Future<Map<String, dynamic>> addXP(SubjectType subject, int xpToAdd) async {
    final prefs = await SharedPreferences.getInstance();
    final currentXP = await getXP(subject);
    final currentTotalXP = await getTotalXP();
    
    final newXP = currentXP + xpToAdd;
    final newTotalXP = currentTotalXP + xpToAdd;
    
    // Save subject-specific XP
    final xpData = prefs.getString(_xpDataKey);
    Map<String, dynamic> data = xpData != null ? jsonDecode(xpData) : {};
    data[subject.name] = newXP;
    await prefs.setString(_xpDataKey, jsonEncode(data));
    
    // Save total XP
    await prefs.setInt(_totalXpKey, newTotalXP);
    
    return {
      'previousXP': currentXP,
      'newXP': newXP,
      'xpGained': xpToAdd,
      'totalXP': newTotalXP,
      'subject': subject.name,
    };
  }

  /// Update XP for a subject (set to specific value)
  Future<void> updateXP(SubjectType subject, int newXP) async {
    final prefs = await SharedPreferences.getInstance();
    final currentXP = await getXP(subject);
    final currentTotalXP = await getTotalXP();
    
    final difference = newXP - currentXP;
    final newTotalXP = currentTotalXP + difference;
    
    // Save subject-specific XP
    final xpData = prefs.getString(_xpDataKey);
    Map<String, dynamic> data = xpData != null ? jsonDecode(xpData) : {};
    data[subject.name] = newXP;
    await prefs.setString(_xpDataKey, jsonEncode(data));
    
    // Save total XP
    await prefs.setInt(_totalXpKey, max(0, newTotalXP));
  }

  /// Calculate XP reward based on performance
  int calculateXP({
    required int correctAnswers,
    required int totalQuestions,
    required Duration timeSpent,
    int? streakCount,
    bool isPerfectScore = false,
    int difficulty = 1,
  }) {
    // Base XP calculation
    final accuracy = correctAnswers / totalQuestions;
    final baseXP = (correctAnswers * baseQuestionXP * accuracy).round();
    
    // Difficulty multiplier (higher difficulty gives more XP)
    final difficultyMultiplier = 1.0 + (difficulty * 0.2);
    
    // Time bonus (reasonable time completion gets bonus)
    final timeInSeconds = timeSpent.inSeconds;
    final optimalTime = totalQuestions * 30; // 30 seconds per question
    final timeBonus = timeInSeconds <= optimalTime ? 1.2 : 1.0;
    
    // Streak bonus
    final streakMultiplier = 1.0 + ((streakCount ?? 0) * 0.1);
    
    // Perfect score bonus
    final perfectBonus = isPerfectScore ? 1.5 : 1.0;
    
    final finalXP = (baseXP * difficultyMultiplier * timeBonus * streakMultiplier * perfectBonus).round();
    
    return max(5, finalXP); // Minimum 5 XP
  }

  /// Calculate XP reward for lesson completion
  int calculateLessonXP({
    required int questionsCompleted,
    required double averageAccuracy,
    required Duration totalTime,
    int difficulty = 1,
  }) {
    final baseXP = baseLessonXP;
    final accuracyMultiplier = averageAccuracy;
    final difficultyMultiplier = 1.0 + (difficulty * 0.3);
    
    // Bonus for completing all questions
    final completionBonus = questionsCompleted >= 5 ? 1.2 : 1.0;
    
    final finalXP = (baseXP * accuracyMultiplier * difficultyMultiplier * completionBonus).round();
    
    return max(10, finalXP); // Minimum 10 XP for lesson completion
  }

  /// Get XP statistics for all subjects
  Future<Map<String, dynamic>> getAllXPStats() async {
    final stats = <String, dynamic>{};
    int totalXP = 0;
    
    for (final subject in SubjectType.values) {
      final xp = await getXP(subject);
      totalXP += xp;
      stats[subject.name] = xp;
    }
    
    stats['total'] = totalXP;
    return stats;
  }

  /// Get XP leaderboard (subjects ranked by XP)
  Future<List<Map<String, dynamic>>> getXPLeaderboard() async {
    final leaderboard = <Map<String, dynamic>>[];
    
    for (final subject in SubjectType.values) {
      final xp = await getXP(subject);
      leaderboard.add({
        'subject': subject.name,
        'xp': xp,
      });
    }
    
    // Sort by XP descending
    leaderboard.sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));
    
    return leaderboard;
  }

  /// Reset XP for a specific subject
  Future<void> resetSubjectXP(SubjectType subject) async {
    final prefs = await SharedPreferences.getInstance();
    final currentXP = await getXP(subject);
    final currentTotalXP = await getTotalXP();
    
    // Update subject XP to 0
    final xpData = prefs.getString(_xpDataKey);
    Map<String, dynamic> data = xpData != null ? jsonDecode(xpData) : {};
    data[subject.name] = 0;
    await prefs.setString(_xpDataKey, jsonEncode(data));
    
    // Update total XP
    final newTotalXP = max(0, currentTotalXP - currentXP);
    await prefs.setInt(_totalXpKey, newTotalXP);
  }

  /// Reset all XP data
  Future<void> resetAllXP() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_xpDataKey);
    await prefs.remove(_totalXpKey);
  }

  /// Get XP progress for a subject as percentage (0.0 to 1.0)
  Future<double> getXPProgress(SubjectType subject, int targetXP) async {
    final currentXP = await getXP(subject);
    if (targetXP <= 0) return 1.0;
    return (currentXP / targetXP).clamp(0.0, 1.0);
  }

  /// Check if user has enough XP in a subject
  Future<bool> hasEnoughXP(SubjectType subject, int requiredXP) async {
    final currentXP = await getXP(subject);
    return currentXP >= requiredXP;
  }

  /// Get daily XP goal progress
  Future<Map<String, dynamic>> getDailyXPProgress(int dailyGoal) async {
    final totalXP = await getTotalXP();
    final progress = (totalXP / dailyGoal).clamp(0.0, 1.0);
    
    return {
      'currentXP': totalXP,
      'dailyGoal': dailyGoal,
      'progress': progress,
      'remaining': max(0, dailyGoal - totalXP),
      'achieved': totalXP >= dailyGoal,
    };
  }
}