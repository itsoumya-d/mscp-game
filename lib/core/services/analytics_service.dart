import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question_pool.dart';

/// Service for tracking analytics and user engagement patterns
/// while maintaining strict privacy compliance
class AnalyticsService {
  static const String _analyticsKey = 'analytics_data';
  static const String _sessionKey = 'current_session';
  static const String _engagementKey = 'engagement_metrics';
  static const String _learningPatternsKey = 'learning_patterns';
  
  late SharedPreferences _prefs;
  Timer? _sessionTimer;
  DateTime? _sessionStartTime;
  final Map<String, dynamic> _currentSession = {};
  final Map<String, dynamic> _engagementMetrics = {};
  final Map<String, dynamic> _learningPatterns = {};
  
  /// Initialize the analytics service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAnalyticsData();
    _startSession();
  }
  
  /// Load existing analytics data from storage
  Future<void> _loadAnalyticsData() async {
    try {
      // Load engagement metrics
      final engagementJson = _prefs.getString(_engagementKey);
      if (engagementJson != null) {
        _engagementMetrics.addAll(
          Map<String, dynamic>.from(jsonDecode(engagementJson))
        );
      }
      
      // Load learning patterns
      final patternsJson = _prefs.getString(_learningPatternsKey);
      if (patternsJson != null) {
        _learningPatterns.addAll(
          Map<String, dynamic>.from(jsonDecode(patternsJson))
        );
      }
    } catch (e) {
      print('Error loading analytics data: $e');
    }
  }
  
  /// Save analytics data to storage
  Future<void> _saveAnalyticsData() async {
    try {
      await _prefs.setString(_engagementKey, jsonEncode(_engagementMetrics));
      await _prefs.setString(_learningPatternsKey, jsonEncode(_learningPatterns));
    } catch (e) {
      print('Error saving analytics data: $e');
    }
  }
  
  /// Start a new analytics session
  void _startSession() {
    _sessionStartTime = DateTime.now();
    _currentSession.clear();
    _currentSession['start_time'] = _sessionStartTime!.toIso8601String();
    _currentSession['events'] = <Map<String, dynamic>>[];
    
    // Start session timer for periodic saves
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _saveCurrentSession(),
    );
  }
  
  /// End the current analytics session
  Future<void> endSession() async {
    if (_sessionStartTime != null) {
      final duration = DateTime.now().difference(_sessionStartTime!);
      _currentSession['duration_seconds'] = duration.inSeconds;
      _currentSession['end_time'] = DateTime.now().toIso8601String();
      
      await _processSessionData();
      await _saveCurrentSession();
    }
    
    _sessionTimer?.cancel();
    _sessionStartTime = null;
  }
  
  /// Save current session data
  Future<void> _saveCurrentSession() async {
    try {
      await _prefs.setString(_sessionKey, jsonEncode(_currentSession));
    } catch (e) {
      print('Error saving session data: $e');
    }
  }
  
  /// Process session data for insights
  Future<void> _processSessionData() async {
    if (_currentSession.isEmpty) return;
    
    try {
      // Update engagement metrics
      _updateEngagementMetrics();
      
      // Update learning patterns
      _updateLearningPatterns();
      
      // Save processed data
      await _saveAnalyticsData();
    } catch (e) {
      print('Error processing session data: $e');
    }
  }
  
  /// Update engagement metrics based on session data
  void _updateEngagementMetrics() {
    final events = _currentSession['events'] as List<Map<String, dynamic>>? ?? [];
    final duration = _currentSession['duration_seconds'] as int? ?? 0;
    
    // Update total session count
    _engagementMetrics['total_sessions'] = 
        (_engagementMetrics['total_sessions'] as int? ?? 0) + 1;
    
    // Update total time spent
    _engagementMetrics['total_time_seconds'] = 
        (_engagementMetrics['total_time_seconds'] as int? ?? 0) + duration;
    
    // Update average session duration
    final totalSessions = _engagementMetrics['total_sessions'] as int;
    final totalTime = _engagementMetrics['total_time_seconds'] as int;
    _engagementMetrics['average_session_duration'] = totalTime / totalSessions;
    
    // Update event counts
    final eventCounts = _engagementMetrics['event_counts'] as Map<String, dynamic>? ?? {};
    for (final event in events) {
      final eventType = event['type'] as String;
      eventCounts[eventType] = (eventCounts[eventType] as int? ?? 0) + 1;
    }
    _engagementMetrics['event_counts'] = eventCounts;
    
    // Update last session date
    _engagementMetrics['last_session_date'] = DateTime.now().toIso8601String();
  }
  
  /// Update learning patterns based on session data
  void _updateLearningPatterns() {
    final events = _currentSession['events'] as List<Map<String, dynamic>>? ?? [];
    
    // Track subject preferences
    final subjectCounts = _learningPatterns['subject_counts'] as Map<String, dynamic>? ?? {};
    final categoryCounts = _learningPatterns['category_counts'] as Map<String, dynamic>? ?? {};
    final difficultyPreferences = _learningPatterns['difficulty_preferences'] as Map<String, dynamic>? ?? {};
    
    for (final event in events) {
      if (event['type'] == 'question_answered') {
        final subject = event['subject'] as String?;
        final category = event['category'] as String?;
        final difficulty = event['difficulty'] as String?;
        
        if (subject != null) {
          subjectCounts[subject] = (subjectCounts[subject] as int? ?? 0) + 1;
        }
        
        if (category != null) {
          categoryCounts[category] = (categoryCounts[category] as int? ?? 0) + 1;
        }
        
        if (difficulty != null) {
          difficultyPreferences[difficulty] = (difficultyPreferences[difficulty] as int? ?? 0) + 1;
        }
      }
    }
    
    _learningPatterns['subject_counts'] = subjectCounts;
    _learningPatterns['category_counts'] = categoryCounts;
    _learningPatterns['difficulty_preferences'] = difficultyPreferences;
    
    // Calculate learning streaks
    _calculateLearningStreaks();
  }
  
  /// Calculate learning streaks and consistency
  void _calculateLearningStreaks() {
    final today = DateTime.now();
    final lastSessionDate = _engagementMetrics['last_session_date'] as String?;
    
    if (lastSessionDate != null) {
      final lastSession = DateTime.parse(lastSessionDate);
      final daysDifference = today.difference(lastSession).inDays;
      
      if (daysDifference <= 1) {
        // Continue or start streak
        _learningPatterns['current_streak'] = 
            (_learningPatterns['current_streak'] as int? ?? 0) + 1;
      } else {
        // Reset streak
        _learningPatterns['current_streak'] = 1;
      }
      
      // Update longest streak
      final currentStreak = _learningPatterns['current_streak'] as int;
      final longestStreak = _learningPatterns['longest_streak'] as int? ?? 0;
      if (currentStreak > longestStreak) {
        _learningPatterns['longest_streak'] = currentStreak;
      }
    }
  }
  
  /// Track a user event (privacy-compliant)
  void trackEvent(String eventType, Map<String, dynamic> properties) {
    if (_currentSession.isEmpty) return;
    
    final event = {
      'type': eventType,
      'timestamp': DateTime.now().toIso8601String(),
      ...properties,
    };
    
    final events = _currentSession['events'] as List<Map<String, dynamic>>;
    events.add(event);
    
    // Limit event history to prevent excessive storage
    if (events.length > 1000) {
      events.removeRange(0, events.length - 1000);
    }
  }
  
  /// Track question answered event
  void trackQuestionAnswered({
    required String subject,
    required QuestionCategory category,
    required String difficulty,
    required bool isCorrect,
    required int responseTimeMs,
  }) {
    trackEvent('question_answered', {
      'subject': subject,
      'category': category.toString().split('.').last,
      'difficulty': difficulty,
      'is_correct': isCorrect,
      'response_time_ms': responseTimeMs,
    });
  }
  
  /// Track skill practice event
  void trackSkillPractice({
    required String subject,
    required String skill,
    required int questionsAttempted,
    required int questionsCorrect,
    required int totalTimeMs,
  }) {
    trackEvent('skill_practice', {
      'subject': subject,
      'skill': skill,
      'questions_attempted': questionsAttempted,
      'questions_correct': questionsCorrect,
      'accuracy': questionsAttempted > 0 ? questionsCorrect / questionsAttempted : 0.0,
      'total_time_ms': totalTimeMs,
    });
  }
  
  /// Track achievement unlocked event
  void trackAchievementUnlocked({
    required String achievementId,
    required String achievementType,
    required String subject,
  }) {
    trackEvent('achievement_unlocked', {
      'achievement_id': achievementId,
      'achievement_type': achievementType,
      'subject': subject,
    });
  }
  
  /// Track video watched event
  void trackVideoWatched({
    required String videoId,
    required String subject,
    required String category,
    required int watchDurationMs,
    required int totalDurationMs,
  }) {
    trackEvent('video_watched', {
      'video_id': videoId,
      'subject': subject,
      'category': category,
      'watch_duration_ms': watchDurationMs,
      'total_duration_ms': totalDurationMs,
      'completion_rate': totalDurationMs > 0 ? watchDurationMs / totalDurationMs : 0.0,
    });
  }
  
  /// Get engagement summary
  Map<String, dynamic> getEngagementSummary() {
    return Map<String, dynamic>.from(_engagementMetrics);
  }
  
  /// Get learning patterns summary
  Map<String, dynamic> getLearningPatterns() {
    return Map<String, dynamic>.from(_learningPatterns);
  }
  
  /// Get current session info
  Map<String, dynamic> getCurrentSessionInfo() {
    if (_sessionStartTime == null) return {};
    
    final duration = DateTime.now().difference(_sessionStartTime!);
    return {
      'start_time': _sessionStartTime!.toIso8601String(),
      'duration_seconds': duration.inSeconds,
      'events_count': (_currentSession['events'] as List?)?.length ?? 0,
    };
  }
  
  /// Get subject preferences based on usage
  Map<String, double> getSubjectPreferences() {
    final subjectCounts = _learningPatterns['subject_counts'] as Map<String, dynamic>? ?? {};
    final totalQuestions = subjectCounts.values.fold<int>(0, (sum, count) => sum + (count as int));
    
    if (totalQuestions == 0) return {};
    
    return subjectCounts.map((subject, count) => 
        MapEntry(subject, (count as int) / totalQuestions));
  }
  
  /// Get category preferences based on usage
  Map<String, double> getCategoryPreferences() {
    final categoryCounts = _learningPatterns['category_counts'] as Map<String, dynamic>? ?? {};
    final totalQuestions = categoryCounts.values.fold<int>(0, (sum, count) => sum + (count as int));
    
    if (totalQuestions == 0) return {};
    
    return categoryCounts.map((category, count) => 
        MapEntry(category, (count as int) / totalQuestions));
  }
  
  /// Get learning consistency metrics
  Map<String, dynamic> getLearningConsistency() {
    return {
      'current_streak': _learningPatterns['current_streak'] ?? 0,
      'longest_streak': _learningPatterns['longest_streak'] ?? 0,
      'total_sessions': _engagementMetrics['total_sessions'] ?? 0,
      'average_session_duration': _engagementMetrics['average_session_duration'] ?? 0.0,
    };
  }
  
  /// Clear all analytics data (for privacy compliance)
  Future<void> clearAllData() async {
    _engagementMetrics.clear();
    _learningPatterns.clear();
    _currentSession.clear();
    _sessionStartTime = null;
    _sessionTimer?.cancel();
    
    await _prefs.remove(_analyticsKey);
    await _prefs.remove(_sessionKey);
    await _prefs.remove(_engagementKey);
    await _prefs.remove(_learningPatternsKey);
  }
  
  /// Export analytics data (for user data requests)
  Map<String, dynamic> exportData() {
    return {
      'engagement_metrics': Map<String, dynamic>.from(_engagementMetrics),
      'learning_patterns': Map<String, dynamic>.from(_learningPatterns),
      'current_session': Map<String, dynamic>.from(_currentSession),
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Get privacy-compliant analytics summary
  Map<String, dynamic> getPrivacyCompliantSummary() {
    // Return only aggregated, non-identifying data
    return {
      'total_learning_time_hours': 
          ((_engagementMetrics['total_time_seconds'] as int? ?? 0) / 3600).round(),
      'learning_streak_days': _learningPatterns['current_streak'] ?? 0,
      'favorite_subjects': _getTopSubjects(3),
      'preferred_categories': _getTopCategories(3),
      'learning_consistency': _calculateConsistencyScore(),
    };
  }
  
  /// Get top subjects by usage
  List<String> _getTopSubjects(int limit) {
    final subjectCounts = _learningPatterns['subject_counts'] as Map<String, dynamic>? ?? {};
    final sortedSubjects = subjectCounts.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    
    return sortedSubjects
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Get top categories by usage
  List<String> _getTopCategories(int limit) {
    final categoryCounts = _learningPatterns['category_counts'] as Map<String, dynamic>? ?? {};
    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    
    return sortedCategories
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Calculate learning consistency score (0.0 to 1.0)
  double _calculateConsistencyScore() {
    final totalSessions = _engagementMetrics['total_sessions'] as int? ?? 0;
    final currentStreak = _learningPatterns['current_streak'] as int? ?? 0;
    
    if (totalSessions == 0) return 0.0;
    
    // Simple consistency score based on streak and total sessions
    final streakScore = (currentStreak / 30).clamp(0.0, 1.0); // Max 30 days
    final sessionScore = (totalSessions / 100).clamp(0.0, 1.0); // Max 100 sessions
    
    return (streakScore + sessionScore) / 2;
  }
  
  /// Dispose of resources
  void dispose() {
    _sessionTimer?.cancel();
    endSession();
  }
}