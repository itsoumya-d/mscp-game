import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/question_pool.dart';

/// Service for managing improvement videos based on performance
class VideoImprovementService {
  static const String _videoRecommendationsKey = 'video_recommendations_v1';
  static const String _watchHistoryKey = 'video_watch_history_v1';
  static const String _videoLibraryKey = 'video_library_v1';

  Map<String, VideoRecommendation> _recommendations = {};
  List<VideoWatchRecord> _watchHistory = [];
  VideoLibrary? _videoLibrary;

  /// Initialize the service
  Future<void> initialize() async {
    await _loadVideoLibrary();
    await _loadRecommendations();
    await _loadWatchHistory();
  }

  /// Load video library from storage or initialize default
  Future<void> _loadVideoLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_videoLibraryKey);
    
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString);
        _videoLibrary = VideoLibrary.fromJson(json);
      } catch (e) {
        _videoLibrary = VideoLibrary.createDefault();
      }
    } else {
      _videoLibrary = VideoLibrary.createDefault();
      await _saveVideoLibrary();
    }
  }

  /// Save video library to storage
  Future<void> _saveVideoLibrary() async {
    if (_videoLibrary == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_videoLibrary!.toJson());
    await prefs.setString(_videoLibraryKey, jsonString);
  }

  /// Load recommendations from storage
  Future<void> _loadRecommendations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_videoRecommendationsKey);
    
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _recommendations = json.map(
          (k, v) => MapEntry(k, VideoRecommendation.fromJson(v as Map<String, dynamic>))
        );
      } catch (e) {
        _recommendations = {};
      }
    }
  }

  /// Save recommendations to storage
  Future<void> _saveRecommendations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(
      _recommendations.map((k, v) => MapEntry(k, v.toJson()))
    );
    await prefs.setString(_videoRecommendationsKey, jsonString);
  }

  /// Load watch history from storage
  Future<void> _loadWatchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_watchHistoryKey);
    
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as List;
        _watchHistory = json
            .map((r) => VideoWatchRecord.fromJson(r as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _watchHistory = [];
      }
    }
  }

  /// Save watch history to storage
  Future<void> _saveWatchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_watchHistory.map((r) => r.toJson()).toList());
    await prefs.setString(_watchHistoryKey, jsonString);
  }

  /// Generate video recommendations based on performance analysis
  Future<List<VideoRecommendation>> generateRecommendations({
    required SubjectType subject,
    required String skillId,
    required List<QuestionCategory> weakCategories,
    required double averageAccuracy,
    required double difficultyLevel,
  }) async {
    final recommendations = <VideoRecommendation>[];
    
    // Get videos for the subject and skill
    final subjectVideos = _videoLibrary?.getVideosForSubject(subject) ?? [];
    final skillVideos = subjectVideos.where((v) => v.skillIds.contains(skillId)).toList();
    
    // Recommend videos for weak categories
    for (final category in weakCategories) {
      final categoryVideos = skillVideos
          .where((v) => v.categories.contains(category))
          .toList();
      
      if (categoryVideos.isNotEmpty) {
        // Sort by relevance and difficulty appropriateness
        categoryVideos.sort((a, b) {
          final aDiffScore = (a.difficultyLevel - difficultyLevel).abs();
          final bDiffScore = (b.difficultyLevel - difficultyLevel).abs();
          return aDiffScore.compareTo(bDiffScore);
        });
        
        final topVideo = categoryVideos.first;
        final recommendation = VideoRecommendation(
          video: topVideo,
          reason: _generateRecommendationReason(category, averageAccuracy, difficultyLevel),
          priority: _calculatePriority(category, averageAccuracy, topVideo),
          recommendedAt: DateTime.now(),
          subject: subject,
          skillId: skillId,
          targetCategory: category,
        );
        
        recommendations.add(recommendation);
      }
    }
    
    // Add general improvement videos if accuracy is low
    if (averageAccuracy < 0.6) {
      final fundamentalVideos = skillVideos
          .where((v) => v.videoType == VideoType.fundamentals)
          .toList();
      
      for (final video in fundamentalVideos.take(2)) {
        final recommendation = VideoRecommendation(
          video: video,
          reason: 'Fundamental concepts review recommended due to low accuracy (${(averageAccuracy * 100).toStringAsFixed(1)}%)',
          priority: VideoPriority.high,
          recommendedAt: DateTime.now(),
          subject: subject,
          skillId: skillId,
          targetCategory: QuestionCategory.conceptual,
        );
        
        recommendations.add(recommendation);
      }
    }
    
    // Sort by priority and limit to top 5
    recommendations.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    final topRecommendations = recommendations.take(5).toList();
    
    // Store recommendations
    for (final rec in topRecommendations) {
      final key = '${subject.name}_${skillId}_${rec.targetCategory.name}';
      _recommendations[key] = rec;
    }
    
    await _saveRecommendations();
    
    return topRecommendations;
  }

  /// Get stored recommendations for a subject and skill
  List<VideoRecommendation> getRecommendations({
    required SubjectType subject,
    required String skillId,
  }) {
    return _recommendations.values
        .where((r) => r.subject == subject && r.skillId == skillId)
        .toList()
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
  }

  /// Record video watch activity
  Future<void> recordVideoWatch({
    required String videoId,
    required Duration watchDuration,
    required Duration totalDuration,
    required SubjectType subject,
    required String skillId,
    bool completed = false,
  }) async {
    final watchRecord = VideoWatchRecord(
      videoId: videoId,
      watchDuration: watchDuration,
      totalDuration: totalDuration,
      completionPercentage: (watchDuration.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0),
      completed: completed,
      watchedAt: DateTime.now(),
      subject: subject,
      skillId: skillId,
    );
    
    _watchHistory.add(watchRecord);
    
    // Keep only last 500 records
    if (_watchHistory.length > 500) {
      _watchHistory = _watchHistory.sublist(_watchHistory.length - 500);
    }
    
    await _saveWatchHistory();
  }

  /// Get watch history for analysis
  List<VideoWatchRecord> getWatchHistory({
    SubjectType? subject,
    String? skillId,
    int? limit,
  }) {
    var history = _watchHistory.where((r) {
      if (subject != null && r.subject != subject) return false;
      if (skillId != null && r.skillId != skillId) return false;
      return true;
    }).toList();
    
    history.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    
    if (limit != null) {
      history = history.take(limit).toList();
    }
    
    return history;
  }

  /// Get video engagement analytics
  VideoEngagementAnalytics getEngagementAnalytics({
    SubjectType? subject,
    String? skillId,
  }) {
    final relevantHistory = getWatchHistory(subject: subject, skillId: skillId);
    
    if (relevantHistory.isEmpty) {
      return VideoEngagementAnalytics.empty();
    }
    
    final totalVideosWatched = relevantHistory.length;
    final completedVideos = relevantHistory.where((r) => r.completed).length;
    final averageCompletion = relevantHistory
        .map((r) => r.completionPercentage)
        .reduce((a, b) => a + b) / relevantHistory.length;
    
    final totalWatchTime = relevantHistory
        .map((r) => r.watchDuration)
        .fold(Duration.zero, (a, b) => a + b);
    
    final engagementScore = _calculateEngagementScore(relevantHistory);
    
    return VideoEngagementAnalytics(
      totalVideosWatched: totalVideosWatched,
      completedVideos: completedVideos,
      completionRate: completedVideos / totalVideosWatched,
      averageCompletionPercentage: averageCompletion,
      totalWatchTime: totalWatchTime,
      engagementScore: engagementScore,
      lastWatchedAt: relevantHistory.first.watchedAt,
    );
  }

  /// Calculate engagement score based on watch patterns
  double _calculateEngagementScore(List<VideoWatchRecord> history) {
    if (history.isEmpty) return 0.0;
    
    double score = 0.0;
    
    // Completion rate factor (40% of score)
    final completionRate = history.where((r) => r.completed).length / history.length;
    score += completionRate * 0.4;
    
    // Average completion percentage factor (30% of score)
    final avgCompletion = history
        .map((r) => r.completionPercentage)
        .reduce((a, b) => a + b) / history.length;
    score += avgCompletion * 0.3;
    
    // Consistency factor (20% of score)
    final recentWatches = history.take(10).length;
    final consistencyScore = (recentWatches / 10.0).clamp(0.0, 1.0);
    score += consistencyScore * 0.2;
    
    // Recency factor (10% of score)
    final daysSinceLastWatch = DateTime.now().difference(history.first.watchedAt).inDays;
    final recencyScore = (1.0 - (daysSinceLastWatch / 30.0)).clamp(0.0, 1.0);
    score += recencyScore * 0.1;
    
    return score.clamp(0.0, 1.0);
  }

  /// Generate recommendation reason
  String _generateRecommendationReason(
    QuestionCategory category,
    double averageAccuracy,
    double difficultyLevel,
  ) {
    final accuracyPercent = (averageAccuracy * 100).toStringAsFixed(1);
    
    switch (category) {
      case QuestionCategory.conceptual:
        return 'Conceptual understanding needs improvement (${accuracyPercent}% accuracy)';
      case QuestionCategory.computational:
        return 'Computational skills require practice (${accuracyPercent}% accuracy)';
      case QuestionCategory.analytical:
        return 'Analytical thinking can be enhanced (${accuracyPercent}% accuracy)';
      case QuestionCategory.factual:
        return 'Factual knowledge gaps identified (${accuracyPercent}% accuracy)';
      case QuestionCategory.practical:
        return 'Practical application skills need development (${accuracyPercent}% accuracy)';
      case QuestionCategory.comparative:
        return 'Comparative analysis skills require strengthening (${accuracyPercent}% accuracy)';
      case QuestionCategory.creative:
        return 'Creative problem-solving approaches recommended (${accuracyPercent}% accuracy)';
    }
  }

  /// Calculate recommendation priority
  VideoPriority _calculatePriority(
    QuestionCategory category,
    double averageAccuracy,
    ImprovementVideo video,
  ) {
    // Lower accuracy = higher priority
    if (averageAccuracy < 0.4) return VideoPriority.high;
    if (averageAccuracy < 0.6) return VideoPriority.medium;
    
    // Fundamental concepts get higher priority
    if (video.videoType == VideoType.fundamentals) {
      return VideoPriority.medium;
    }
    
    return VideoPriority.low;
  }

  /// Add custom video to library
  Future<void> addCustomVideo(ImprovementVideo video) async {
    if (_videoLibrary == null) return;
    
    _videoLibrary = _videoLibrary!.addVideo(video);
    await _saveVideoLibrary();
  }

  /// Get video library
  VideoLibrary? get videoLibrary => _videoLibrary;
}

/// Represents a video recommendation
class VideoRecommendation {
  final ImprovementVideo video;
  final String reason;
  final VideoPriority priority;
  final DateTime recommendedAt;
  final SubjectType subject;
  final String skillId;
  final QuestionCategory targetCategory;

  const VideoRecommendation({
    required this.video,
    required this.reason,
    required this.priority,
    required this.recommendedAt,
    required this.subject,
    required this.skillId,
    required this.targetCategory,
  });

  Map<String, dynamic> toJson() => {
    'video': video.toJson(),
    'reason': reason,
    'priority': priority.name,
    'recommendedAt': recommendedAt.toIso8601String(),
    'subject': subject.name,
    'skillId': skillId,
    'targetCategory': targetCategory.name,
  };

  factory VideoRecommendation.fromJson(Map<String, dynamic> json) => VideoRecommendation(
    video: ImprovementVideo.fromJson(json['video'] as Map<String, dynamic>),
    reason: json['reason'] as String,
    priority: VideoPriority.values.firstWhere((p) => p.name == json['priority']),
    recommendedAt: DateTime.parse(json['recommendedAt'] as String),
    subject: SubjectType.values.firstWhere((s) => s.name == json['subject']),
    skillId: json['skillId'] as String,
    targetCategory: QuestionCategory.values.firstWhere((c) => c.name == json['targetCategory']),
  );
}

/// Represents a video watch record
class VideoWatchRecord {
  final String videoId;
  final Duration watchDuration;
  final Duration totalDuration;
  final double completionPercentage;
  final bool completed;
  final DateTime watchedAt;
  final SubjectType subject;
  final String skillId;

  const VideoWatchRecord({
    required this.videoId,
    required this.watchDuration,
    required this.totalDuration,
    required this.completionPercentage,
    required this.completed,
    required this.watchedAt,
    required this.subject,
    required this.skillId,
  });

  Map<String, dynamic> toJson() => {
    'videoId': videoId,
    'watchDuration': watchDuration.inMilliseconds,
    'totalDuration': totalDuration.inMilliseconds,
    'completionPercentage': completionPercentage,
    'completed': completed,
    'watchedAt': watchedAt.toIso8601String(),
    'subject': subject.name,
    'skillId': skillId,
  };

  factory VideoWatchRecord.fromJson(Map<String, dynamic> json) => VideoWatchRecord(
    videoId: json['videoId'] as String,
    watchDuration: Duration(milliseconds: json['watchDuration'] as int),
    totalDuration: Duration(milliseconds: json['totalDuration'] as int),
    completionPercentage: (json['completionPercentage'] as num).toDouble(),
    completed: json['completed'] as bool,
    watchedAt: DateTime.parse(json['watchedAt'] as String),
    subject: SubjectType.values.firstWhere((s) => s.name == json['subject']),
    skillId: json['skillId'] as String,
  );
}

/// Represents video engagement analytics
class VideoEngagementAnalytics {
  final int totalVideosWatched;
  final int completedVideos;
  final double completionRate;
  final double averageCompletionPercentage;
  final Duration totalWatchTime;
  final double engagementScore;
  final DateTime lastWatchedAt;

  const VideoEngagementAnalytics({
    required this.totalVideosWatched,
    required this.completedVideos,
    required this.completionRate,
    required this.averageCompletionPercentage,
    required this.totalWatchTime,
    required this.engagementScore,
    required this.lastWatchedAt,
  });

  factory VideoEngagementAnalytics.empty() => VideoEngagementAnalytics(
    totalVideosWatched: 0,
    completedVideos: 0,
    completionRate: 0.0,
    averageCompletionPercentage: 0.0,
    totalWatchTime: Duration.zero,
    engagementScore: 0.0,
    lastWatchedAt: DateTime.now(),
  );
}

/// Represents an improvement video
class ImprovementVideo {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String videoUrl;
  final Duration duration;
  final VideoType videoType;
  final List<SubjectType> subjects;
  final List<String> skillIds;
  final List<QuestionCategory> categories;
  final double difficultyLevel;
  final List<String> tags;
  final DateTime createdAt;

  const ImprovementVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.duration,
    required this.videoType,
    required this.subjects,
    required this.skillIds,
    required this.categories,
    required this.difficultyLevel,
    required this.tags,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'thumbnailUrl': thumbnailUrl,
    'videoUrl': videoUrl,
    'duration': duration.inMilliseconds,
    'videoType': videoType.name,
    'subjects': subjects.map((s) => s.name).toList(),
    'skillIds': skillIds,
    'categories': categories.map((c) => c.name).toList(),
    'difficultyLevel': difficultyLevel,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ImprovementVideo.fromJson(Map<String, dynamic> json) => ImprovementVideo(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    thumbnailUrl: json['thumbnailUrl'] as String,
    videoUrl: json['videoUrl'] as String,
    duration: Duration(milliseconds: json['duration'] as int),
    videoType: VideoType.values.firstWhere((t) => t.name == json['videoType']),
    subjects: (json['subjects'] as List)
        .map((s) => SubjectType.values.firstWhere((sub) => sub.name == s))
        .toList(),
    skillIds: (json['skillIds'] as List).cast<String>(),
    categories: (json['categories'] as List)
        .map((c) => QuestionCategory.values.firstWhere((cat) => cat.name == c))
        .toList(),
    difficultyLevel: (json['difficultyLevel'] as num).toDouble(),
    tags: (json['tags'] as List).cast<String>(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// Video library for managing all improvement videos
class VideoLibrary {
  final Map<SubjectType, List<ImprovementVideo>> videosBySubject;
  final DateTime lastUpdated;

  const VideoLibrary({
    required this.videosBySubject,
    required this.lastUpdated,
  });

  factory VideoLibrary.createDefault() {
    final defaultVideos = _createDefaultVideos();
    final videosBySubject = <SubjectType, List<ImprovementVideo>>{};
    
    for (final video in defaultVideos) {
      for (final subject in video.subjects) {
        videosBySubject.putIfAbsent(subject, () => []).add(video);
      }
    }
    
    return VideoLibrary(
      videosBySubject: videosBySubject,
      lastUpdated: DateTime.now(),
    );
  }

  List<ImprovementVideo> getVideosForSubject(SubjectType subject) {
    return videosBySubject[subject] ?? [];
  }

  VideoLibrary addVideo(ImprovementVideo video) {
    final updatedVideosBySubject = Map<SubjectType, List<ImprovementVideo>>.from(videosBySubject);
    
    for (final subject in video.subjects) {
      updatedVideosBySubject.putIfAbsent(subject, () => []).add(video);
    }
    
    return VideoLibrary(
      videosBySubject: updatedVideosBySubject,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'videosBySubject': videosBySubject.map(
      (k, v) => MapEntry(k.name, v.map((video) => video.toJson()).toList())
    ),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory VideoLibrary.fromJson(Map<String, dynamic> json) {
    final videosBySubject = <SubjectType, List<ImprovementVideo>>{};
    
    (json['videosBySubject'] as Map<String, dynamic>).forEach((k, v) {
      final subject = SubjectType.values.firstWhere((s) => s.name == k);
      final videos = (v as List)
          .map((videoJson) => ImprovementVideo.fromJson(videoJson as Map<String, dynamic>))
          .toList();
      videosBySubject[subject] = videos;
    });
    
    return VideoLibrary(
      videosBySubject: videosBySubject,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  static List<ImprovementVideo> _createDefaultVideos() {
    return [
      // Math videos
      ImprovementVideo(
        id: 'math_algebra_basics',
        title: 'Algebra Fundamentals',
        description: 'Master the basics of algebraic expressions and equations',
        thumbnailUrl: 'https://example.com/thumbnails/algebra_basics.jpg',
        videoUrl: 'https://example.com/videos/algebra_basics.mp4',
        duration: const Duration(minutes: 15),
        videoType: VideoType.fundamentals,
        subjects: [SubjectType.math],
        skillIds: ['algebra_basics', 'linear_equations'],
        categories: [QuestionCategory.conceptual, QuestionCategory.computational],
        difficultyLevel: 2.0,
        tags: ['algebra', 'equations', 'fundamentals'],
        createdAt: DateTime.now(),
      ),
      
      // Physics videos
      ImprovementVideo(
        id: 'physics_mechanics_intro',
        title: 'Introduction to Mechanics',
        description: 'Understanding force, motion, and energy concepts',
        thumbnailUrl: 'https://example.com/thumbnails/mechanics_intro.jpg',
        videoUrl: 'https://example.com/videos/mechanics_intro.mp4',
        duration: const Duration(minutes: 20),
        videoType: VideoType.conceptExplanation,
        subjects: [SubjectType.physics],
        skillIds: ['mechanics', 'forces'],
        categories: [QuestionCategory.conceptual, QuestionCategory.analytical],
        difficultyLevel: 2.5,
        tags: ['mechanics', 'force', 'motion'],
        createdAt: DateTime.now(),
      ),
      
      // Chemistry videos
      ImprovementVideo(
        id: 'chemistry_periodic_table',
        title: 'Periodic Table Mastery',
        description: 'Understanding element properties and periodic trends',
        thumbnailUrl: 'https://example.com/thumbnails/periodic_table.jpg',
        videoUrl: 'https://example.com/videos/periodic_table.mp4',
        duration: const Duration(minutes: 18),
        videoType: VideoType.fundamentals,
        subjects: [SubjectType.chemistry],
        skillIds: ['periodic_table', 'element_properties'],
        categories: [QuestionCategory.factual, QuestionCategory.comparative],
        difficultyLevel: 2.0,
        tags: ['periodic table', 'elements', 'properties'],
        createdAt: DateTime.now(),
      ),
    ];
  }
}

/// Video type enumeration
enum VideoType {
  fundamentals,
  conceptExplanation,
  problemSolving,
  practiceExercises,
  realWorldApplications,
}

/// Video priority enumeration
enum VideoPriority {
  low,
  medium,
  high,
}