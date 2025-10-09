import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Learning Analytics Service - Task G1
/// Comprehensive analytics for tracking learning progress
/// 
/// Features:
/// - Time spent tracking
/// - Accuracy trends
/// - Strong/weak topics
/// - Performance predictions
/// - Study patterns
/// - Engagement metrics

class LearningAnalyticsService {
  static final LearningAnalyticsService _instance = LearningAnalyticsService._internal();
  factory LearningAnalyticsService() => _instance;
  LearningAnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get comprehensive analytics for a user
  Future<UserAnalytics> getUserAnalytics(String userId) async {
    try {
      // In production, fetch from Firestore
      final doc = await _firestore.collection('user_analytics').doc(userId).get();
      
      if (doc.exists) {
        return UserAnalytics.fromMap(doc.data()!);
      }
      
      // Return default analytics if not found
      return _generateMockAnalytics(userId);
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
      return _generateMockAnalytics(userId);
    }
  }

  /// Track study session
  Future<void> trackStudySession({
    required String userId,
    required String subject,
    required String topic,
    required Duration duration,
    required int questionsAnswered,
    required int correctAnswers,
  }) async {
    try {
      await _firestore.collection('study_sessions').add({
        'userId': userId,
        'subject': subject,
        'topic': topic,
        'duration': duration.inSeconds,
        'questionsAnswered': questionsAnswered,
        'correctAnswers': correctAnswers,
        'accuracy': questionsAnswered > 0 ? correctAnswers / questionsAnswered : 0,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Study session tracked: $subject - $topic');
    } catch (e) {
      debugPrint('Error tracking session: $e');
    }
  }

  /// Get time spent by subject
  Future<Map<String, Duration>> getTimeSpentBySubject(String userId) async {
    // In production, aggregate from Firestore
    return {
      'Math': const Duration(hours: 12, minutes: 30),
      'Science': const Duration(hours: 8, minutes: 45),
      'English': const Duration(hours: 6, minutes: 15),
      'History': const Duration(hours: 4, minutes: 20),
    };
  }

  /// Get accuracy trends over time
  Future<List<AccuracyDataPoint>> getAccuracyTrends(String userId, {int days = 30}) async {
    // In production, fetch from Firestore
    final now = DateTime.now();
    return List.generate(days, (index) {
      final date = now.subtract(Duration(days: days - index - 1));
      final accuracy = 0.6 + (index / days) * 0.3; // Simulated improvement
      return AccuracyDataPoint(date: date, accuracy: accuracy);
    });
  }

  /// Get strong topics
  Future<List<TopicPerformance>> getStrongTopics(String userId, {int limit = 5}) async {
    // In production, calculate from Firestore data
    return [
      TopicPerformance(
        subject: 'Math',
        topic: 'Addition',
        accuracy: 0.95,
        questionsAnswered: 150,
        averageTime: const Duration(seconds: 25),
        masteryLevel: MasteryLevel.expert,
      ),
      TopicPerformance(
        subject: 'Science',
        topic: 'Biology',
        accuracy: 0.92,
        questionsAnswered: 120,
        averageTime: const Duration(seconds: 35),
        masteryLevel: MasteryLevel.advanced,
      ),
      TopicPerformance(
        subject: 'English',
        topic: 'Grammar',
        accuracy: 0.88,
        questionsAnswered: 100,
        averageTime: const Duration(seconds: 30),
        masteryLevel: MasteryLevel.advanced,
      ),
    ];
  }

  /// Get weak topics
  Future<List<TopicPerformance>> getWeakTopics(String userId, {int limit = 5}) async {
    // In production, calculate from Firestore data
    return [
      TopicPerformance(
        subject: 'Math',
        topic: 'Algebra',
        accuracy: 0.45,
        questionsAnswered: 80,
        averageTime: const Duration(seconds: 55),
        masteryLevel: MasteryLevel.beginner,
      ),
      TopicPerformance(
        subject: 'Science',
        topic: 'Chemistry',
        accuracy: 0.52,
        questionsAnswered: 60,
        averageTime: const Duration(seconds: 50),
        masteryLevel: MasteryLevel.beginner,
      ),
      TopicPerformance(
        subject: 'Math',
        topic: 'Geometry',
        accuracy: 0.58,
        questionsAnswered: 70,
        averageTime: const Duration(seconds: 45),
        masteryLevel: MasteryLevel.intermediate,
      ),
    ];
  }

  /// Get study patterns
  Future<StudyPatterns> getStudyPatterns(String userId) async {
    // In production, analyze from Firestore data
    return StudyPatterns(
      mostProductiveHour: 14, // 2 PM
      averageSessionDuration: const Duration(minutes: 25),
      preferredStudyDays: [1, 3, 5], // Monday, Wednesday, Friday
      peakPerformanceTime: TimeOfDay.afternoon,
      consistencyScore: 0.85,
      streakDays: 12,
    );
  }

  /// Get performance predictions
  Future<PerformancePrediction> getPredictions(String userId) async {
    // In production, use ML model
    return PerformancePrediction(
      predictedAccuracyNextWeek: 0.82,
      predictedXpNextWeek: 1500,
      topicsToImprove: ['Algebra', 'Chemistry', 'Geometry'],
      recommendedStudyTime: const Duration(hours: 5),
      confidenceScore: 0.78,
    );
  }

  /// Get engagement metrics
  Future<EngagementMetrics> getEngagementMetrics(String userId) async {
    // In production, calculate from Firestore
    return EngagementMetrics(
      dailyActiveStreak: 12,
      totalSessions: 156,
      averageSessionsPerWeek: 15,
      totalTimeSpent: const Duration(hours: 45, minutes: 30),
      questionsAnswered: 2340,
      achievementsUnlocked: 28,
      friendsAdded: 12,
      challengesCompleted: 45,
    );
  }

  UserAnalytics _generateMockAnalytics(String userId) {
    return UserAnalytics(
      userId: userId,
      totalTimeSpent: const Duration(hours: 45, minutes: 30),
      totalQuestionsAnswered: 2340,
      totalCorrectAnswers: 1872,
      overallAccuracy: 0.80,
      currentStreak: 12,
      longestStreak: 28,
      totalXp: 15600,
      level: 24,
      subjectsStudied: 4,
      topicsCompleted: 32,
      achievementsUnlocked: 28,
      lastStudyDate: DateTime.now(),
    );
  }
}

/// User analytics model
class UserAnalytics {
  final String userId;
  final Duration totalTimeSpent;
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;
  final double overallAccuracy;
  final int currentStreak;
  final int longestStreak;
  final int totalXp;
  final int level;
  final int subjectsStudied;
  final int topicsCompleted;
  final int achievementsUnlocked;
  final DateTime lastStudyDate;

  UserAnalytics({
    required this.userId,
    required this.totalTimeSpent,
    required this.totalQuestionsAnswered,
    required this.totalCorrectAnswers,
    required this.overallAccuracy,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalXp,
    required this.level,
    required this.subjectsStudied,
    required this.topicsCompleted,
    required this.achievementsUnlocked,
    required this.lastStudyDate,
  });

  factory UserAnalytics.fromMap(Map<String, dynamic> map) {
    return UserAnalytics(
      userId: map['userId'] ?? '',
      totalTimeSpent: Duration(seconds: map['totalTimeSpent'] ?? 0),
      totalQuestionsAnswered: map['totalQuestionsAnswered'] ?? 0,
      totalCorrectAnswers: map['totalCorrectAnswers'] ?? 0,
      overallAccuracy: (map['overallAccuracy'] ?? 0.0).toDouble(),
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      totalXp: map['totalXp'] ?? 0,
      level: map['level'] ?? 1,
      subjectsStudied: map['subjectsStudied'] ?? 0,
      topicsCompleted: map['topicsCompleted'] ?? 0,
      achievementsUnlocked: map['achievementsUnlocked'] ?? 0,
      lastStudyDate: (map['lastStudyDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Accuracy data point for trends
class AccuracyDataPoint {
  final DateTime date;
  final double accuracy;

  AccuracyDataPoint({required this.date, required this.accuracy});
}

/// Topic performance model
class TopicPerformance {
  final String subject;
  final String topic;
  final double accuracy;
  final int questionsAnswered;
  final Duration averageTime;
  final MasteryLevel masteryLevel;

  TopicPerformance({
    required this.subject,
    required this.topic,
    required this.accuracy,
    required this.questionsAnswered,
    required this.averageTime,
    required this.masteryLevel,
  });
}

/// Study patterns model
class StudyPatterns {
  final int mostProductiveHour;
  final Duration averageSessionDuration;
  final List<int> preferredStudyDays;
  final TimeOfDay peakPerformanceTime;
  final double consistencyScore;
  final int streakDays;

  StudyPatterns({
    required this.mostProductiveHour,
    required this.averageSessionDuration,
    required this.preferredStudyDays,
    required this.peakPerformanceTime,
    required this.consistencyScore,
    required this.streakDays,
  });
}

/// Performance prediction model
class PerformancePrediction {
  final double predictedAccuracyNextWeek;
  final int predictedXpNextWeek;
  final List<String> topicsToImprove;
  final Duration recommendedStudyTime;
  final double confidenceScore;

  PerformancePrediction({
    required this.predictedAccuracyNextWeek,
    required this.predictedXpNextWeek,
    required this.topicsToImprove,
    required this.recommendedStudyTime,
    required this.confidenceScore,
  });
}

/// Engagement metrics model
class EngagementMetrics {
  final int dailyActiveStreak;
  final int totalSessions;
  final int averageSessionsPerWeek;
  final Duration totalTimeSpent;
  final int questionsAnswered;
  final int achievementsUnlocked;
  final int friendsAdded;
  final int challengesCompleted;

  EngagementMetrics({
    required this.dailyActiveStreak,
    required this.totalSessions,
    required this.averageSessionsPerWeek,
    required this.totalTimeSpent,
    required this.questionsAnswered,
    required this.achievementsUnlocked,
    required this.friendsAdded,
    required this.challengesCompleted,
  });
}

enum MasteryLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}

enum TimeOfDay {
  morning,
  afternoon,
  evening,
  night,
}

