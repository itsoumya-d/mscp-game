import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Learning Insights Service - Task G3
/// Provide actionable insights based on learning patterns
/// 
/// Features:
/// - Optimal study times
/// - Effective strategies
/// - Personalized tips
/// - Learning patterns
/// - Performance insights

class LearningInsightsService {
  static final LearningInsightsService _instance = LearningInsightsService._internal();
  factory LearningInsightsService() => _instance;
  LearningInsightsService._internal();

  /// Get all insights for a user
  Future<UserInsights> getUserInsights(String userId) async {
    return UserInsights(
      optimalStudyTimes: await _getOptimalStudyTimes(userId),
      effectiveStrategies: await _getEffectiveStrategies(userId),
      personalizedTips: await _getPersonalizedTips(userId),
      learningPatterns: await _getLearningPatterns(userId),
      performanceInsights: await _getPerformanceInsights(userId),
      motivationalInsights: await _getMotivationalInsights(userId),
      socialInsights: await _getSocialInsights(userId),
    );
  }

  Future<List<OptimalStudyTime>> _getOptimalStudyTimes(String userId) async {
    // In production, analyze historical data
    return [
      OptimalStudyTime(
        timeOfDay: 'Afternoon (2-4 PM)',
        averageAccuracy: 0.88,
        averageSpeed: const Duration(seconds: 28),
        sessionsAnalyzed: 45,
        recommendation: 'Your peak performance time! Schedule difficult topics during this window.',
      ),
      OptimalStudyTime(
        timeOfDay: 'Morning (9-11 AM)',
        averageAccuracy: 0.82,
        averageSpeed: const Duration(seconds: 32),
        sessionsAnalyzed: 38,
        recommendation: 'Good for review and practice. Your second-best time slot.',
      ),
      OptimalStudyTime(
        timeOfDay: 'Evening (7-9 PM)',
        averageAccuracy: 0.75,
        averageSpeed: const Duration(seconds: 38),
        sessionsAnalyzed: 28,
        recommendation: 'Better for lighter topics. Consider moving challenging subjects earlier.',
      ),
    ];
  }

  Future<List<EffectiveStrategy>> _getEffectiveStrategies(String userId) async {
    return [
      EffectiveStrategy(
        name: 'Short, Frequent Sessions',
        description: 'You perform 15% better in 20-minute sessions vs 60-minute sessions',
        effectiveness: 0.92,
        dataPoints: 120,
        recommendation: 'Break study time into 20-minute focused sessions with 5-minute breaks',
        icon: '⏱️',
      ),
      EffectiveStrategy(
        name: 'Morning Review',
        description: 'Reviewing previous day\'s material in the morning improves retention by 25%',
        effectiveness: 0.88,
        dataPoints: 85,
        recommendation: 'Spend 10 minutes each morning reviewing yesterday\'s topics',
        icon: '🌅',
      ),
      EffectiveStrategy(
        name: 'Practice Before Theory',
        description: 'You learn 20% faster when attempting problems before watching explanations',
        effectiveness: 0.85,
        dataPoints: 95,
        recommendation: 'Try practice problems first, then watch video explanations',
        icon: '🎯',
      ),
      EffectiveStrategy(
        name: 'Spaced Repetition',
        description: 'Topics reviewed 3 times over a week show 40% better retention',
        effectiveness: 0.90,
        dataPoints: 150,
        recommendation: 'Review new topics on days 1, 3, and 7 for optimal retention',
        icon: '🔄',
      ),
    ];
  }

  Future<List<PersonalizedTip>> _getPersonalizedTips(String userId) async {
    return [
      PersonalizedTip(
        category: TipCategory.performance,
        title: 'Boost Your Algebra Skills',
        message: 'You\'ve improved 15% in Algebra this week! Keep practicing daily to reach 70% accuracy.',
        priority: TipPriority.high,
        actionable: true,
        action: 'Start Algebra Practice',
        icon: '📈',
      ),
      PersonalizedTip(
        category: TipCategory.motivation,
        title: 'You\'re on Fire! 🔥',
        message: '12-day streak! Just 3 more days to beat your personal record of 14 days.',
        priority: TipPriority.medium,
        actionable: false,
        icon: '🔥',
      ),
      PersonalizedTip(
        category: TipCategory.social,
        title: 'Challenge Your Friends',
        message: 'You\'re ahead of 8 friends in Math. Challenge them to catch up!',
        priority: TipPriority.low,
        actionable: true,
        action: 'Send Challenge',
        icon: '👥',
      ),
      PersonalizedTip(
        category: TipCategory.learning,
        title: 'Try Video Lessons',
        message: 'Students who watch videos score 20% higher. Try video lessons for Chemistry.',
        priority: TipPriority.medium,
        actionable: true,
        action: 'Watch Videos',
        icon: '🎥',
      ),
      PersonalizedTip(
        category: TipCategory.health,
        title: 'Take a Break',
        message: 'You\'ve studied for 90 minutes straight. A 10-minute break will improve focus.',
        priority: TipPriority.high,
        actionable: true,
        action: 'Start Break Timer',
        icon: '☕',
      ),
    ];
  }

  Future<List<LearningPattern>> _getLearningPatterns(String userId) async {
    return [
      LearningPattern(
        pattern: 'Consistent Daily Practice',
        description: 'You study at similar times each day, which builds strong habits',
        impact: PatternImpact.positive,
        strength: 0.85,
        suggestion: 'Maintain this consistency for best results',
      ),
      LearningPattern(
        pattern: 'Weekend Dip',
        description: 'Your accuracy drops 12% on weekends',
        impact: PatternImpact.negative,
        strength: 0.72,
        suggestion: 'Try lighter topics on weekends or take scheduled breaks',
      ),
      LearningPattern(
        pattern: 'Fast Learner',
        description: 'You master new topics 30% faster than average',
        impact: PatternImpact.positive,
        strength: 0.90,
        suggestion: 'Challenge yourself with advanced topics',
      ),
      LearningPattern(
        pattern: 'Visual Learner',
        description: 'You perform 25% better with visual content',
        impact: PatternImpact.positive,
        strength: 0.88,
        suggestion: 'Prioritize video lessons and diagrams',
      ),
    ];
  }

  Future<List<PerformanceInsight>> _getPerformanceInsights(String userId) async {
    return [
      PerformanceInsight(
        metric: 'Accuracy Trend',
        value: '+15%',
        trend: Trend.up,
        message: 'Your accuracy has improved 15% over the past month',
        details: 'From 67% to 82% - excellent progress!',
      ),
      PerformanceInsight(
        metric: 'Speed Improvement',
        value: '-8 seconds',
        trend: Trend.up,
        message: 'You\'re answering questions 8 seconds faster on average',
        details: 'From 36s to 28s per question',
      ),
      PerformanceInsight(
        metric: 'Consistency Score',
        value: '85%',
        trend: Trend.stable,
        message: 'You maintain consistent performance across sessions',
        details: 'Very stable - keep up the routine!',
      ),
      PerformanceInsight(
        metric: 'Topic Mastery',
        value: '8 topics',
        trend: Trend.up,
        message: 'You\'ve mastered 8 topics this month',
        details: '3 more than last month',
      ),
    ];
  }

  Future<List<MotivationalInsight>> _getMotivationalInsights(String userId) async {
    return [
      MotivationalInsight(
        message: 'You\'re in the top 15% of learners this week!',
        type: MotivationType.achievement,
        icon: '🏆',
      ),
      MotivationalInsight(
        message: 'Your dedication is paying off - keep going!',
        type: MotivationType.encouragement,
        icon: '💪',
      ),
      MotivationalInsight(
        message: 'You\'ve answered 2,340 questions - that\'s impressive!',
        type: MotivationType.milestone,
        icon: '🎯',
      ),
    ];
  }

  Future<List<SocialInsight>> _getSocialInsights(String userId) async {
    return [
      SocialInsight(
        message: 'You\'re ahead of 8 out of 12 friends in Math',
        type: SocialInsightType.comparison,
        icon: '📊',
      ),
      SocialInsight(
        message: '3 friends completed the same topic this week',
        type: SocialInsightType.activity,
        icon: '👥',
      ),
      SocialInsight(
        message: 'Join the "Math Masters" study group',
        type: SocialInsightType.suggestion,
        icon: '🎓',
      ),
    ];
  }
}

/// User insights model
class UserInsights {
  final List<OptimalStudyTime> optimalStudyTimes;
  final List<EffectiveStrategy> effectiveStrategies;
  final List<PersonalizedTip> personalizedTips;
  final List<LearningPattern> learningPatterns;
  final List<PerformanceInsight> performanceInsights;
  final List<MotivationalInsight> motivationalInsights;
  final List<SocialInsight> socialInsights;

  UserInsights({
    required this.optimalStudyTimes,
    required this.effectiveStrategies,
    required this.personalizedTips,
    required this.learningPatterns,
    required this.performanceInsights,
    required this.motivationalInsights,
    required this.socialInsights,
  });
}

class OptimalStudyTime {
  final String timeOfDay;
  final double averageAccuracy;
  final Duration averageSpeed;
  final int sessionsAnalyzed;
  final String recommendation;

  OptimalStudyTime({
    required this.timeOfDay,
    required this.averageAccuracy,
    required this.averageSpeed,
    required this.sessionsAnalyzed,
    required this.recommendation,
  });
}

class EffectiveStrategy {
  final String name;
  final String description;
  final double effectiveness;
  final int dataPoints;
  final String recommendation;
  final String icon;

  EffectiveStrategy({
    required this.name,
    required this.description,
    required this.effectiveness,
    required this.dataPoints,
    required this.recommendation,
    required this.icon,
  });
}

class PersonalizedTip {
  final TipCategory category;
  final String title;
  final String message;
  final TipPriority priority;
  final bool actionable;
  final String? action;
  final String icon;

  PersonalizedTip({
    required this.category,
    required this.title,
    required this.message,
    required this.priority,
    required this.actionable,
    this.action,
    required this.icon,
  });
}

class LearningPattern {
  final String pattern;
  final String description;
  final PatternImpact impact;
  final double strength;
  final String suggestion;

  LearningPattern({
    required this.pattern,
    required this.description,
    required this.impact,
    required this.strength,
    required this.suggestion,
  });
}

class PerformanceInsight {
  final String metric;
  final String value;
  final Trend trend;
  final String message;
  final String details;

  PerformanceInsight({
    required this.metric,
    required this.value,
    required this.trend,
    required this.message,
    required this.details,
  });
}

class MotivationalInsight {
  final String message;
  final MotivationType type;
  final String icon;

  MotivationalInsight({
    required this.message,
    required this.type,
    required this.icon,
  });
}

class SocialInsight {
  final String message;
  final SocialInsightType type;
  final String icon;

  SocialInsight({
    required this.message,
    required this.type,
    required this.icon,
  });
}

enum TipCategory { performance, motivation, social, learning, health }
enum TipPriority { low, medium, high }
enum PatternImpact { positive, negative, neutral }
enum Trend { up, down, stable }
enum MotivationType { achievement, encouragement, milestone }
enum SocialInsightType { comparison, activity, suggestion }

/// Learning Insights model for screen display
class LearningInsights {
  final TimeOfDay optimalStudyTime;
  final Map<String, double> learningPatterns;
  final int currentStreak;
  final int longestStreak;
  final double performanceTrend;
  final List<String> recommendations;
  final List<String> focusAreas;

  LearningInsights({
    required this.optimalStudyTime,
    required this.learningPatterns,
    required this.currentStreak,
    required this.longestStreak,
    required this.performanceTrend,
    required this.recommendations,
    required this.focusAreas,
  });
}

extension LearningInsightsServiceExtension on LearningInsightsService {
  /// Generate insights for screen display
  Future<LearningInsights> generateInsights(String userId) async {
    final insights = await getUserInsights(userId);
    final optimalTimes = insights.optimalStudyTimes;

    return LearningInsights(
      optimalStudyTime: optimalTimes.isNotEmpty
        ? _parseTimeOfDay(optimalTimes.first.timeOfDay)
        : const TimeOfDay(hour: 14, minute: 0),
      learningPatterns: {
        'Morning': 0.82,
        'Afternoon': 0.88,
        'Evening': 0.75,
      },
      currentStreak: 7,
      longestStreak: 15,
      performanceTrend: 0.15, // 15% improvement
      recommendations: insights.personalizedTips.map((t) => t.message).toList(),
      focusAreas: insights.learningPatterns
        .where((p) => p.impact == PatternImpact.negative)
        .map((p) => p.pattern)
        .toList(),
    );
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    // Parse "Afternoon (2-4 PM)" to TimeOfDay
    if (timeString.contains('Afternoon')) return const TimeOfDay(hour: 14, minute: 0);
    if (timeString.contains('Morning')) return const TimeOfDay(hour: 9, minute: 0);
    if (timeString.contains('Evening')) return const TimeOfDay(hour: 19, minute: 0);
    return const TimeOfDay(hour: 14, minute: 0);
  }
}
