import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Video Content Service - Task F1
/// Manage video explanations for concepts
/// 
/// Features:
/// - Video library management
/// - YouTube/Vimeo integration
/// - Custom video player
/// - Captions support
/// - Playback speed control
/// - Progress tracking

class VideoContentService {
  static final VideoContentService _instance = VideoContentService._internal();
  factory VideoContentService() => _instance;
  VideoContentService._internal();

  /// Get videos for a topic
  Future<List<VideoContent>> getVideosForTopic({
    required String subject,
    required String topic,
  }) async {
    // In production, fetch from Firestore or API
    return _mockVideos(subject, topic);
  }

  /// Get featured videos
  Future<List<VideoContent>> getFeaturedVideos() async {
    // In production, fetch from Firestore
    return _mockVideos('Featured', 'All');
  }

  /// Search videos
  Future<List<VideoContent>> searchVideos(String query) async {
    // In production, implement full-text search
    return _mockVideos('Search', query);
  }

  /// Get videos by subject
  Future<List<VideoContent>> getVideos({required String subject}) async {
    return _mockVideos(subject, 'All');
  }

  /// Track video progress
  Future<void> trackProgress({
    required String userId,
    required String videoId,
    required Duration position,
    required Duration duration,
  }) async {
    final progress = (position.inSeconds / duration.inSeconds * 100).toInt();
    debugPrint('Video $videoId progress: $progress%');
    // In production, save to Firestore
  }

  /// Mark video as completed
  Future<void> markCompleted({
    required String userId,
    required String videoId,
  }) async {
    debugPrint('Video $videoId completed by user $userId');
    // In production, save to Firestore and award XP
  }

  /// Get user's video history
  Future<List<VideoProgress>> getVideoHistory(String userId) async {
    // In production, fetch from Firestore
    return [];
  }

  List<VideoContent> _mockVideos(String subject, String topic) {
    return [
      VideoContent(
        id: 'video_1',
        title: 'Introduction to $topic',
        description: 'Learn the basics of $topic in this comprehensive video',
        subject: subject,
        topic: topic,
        duration: const Duration(minutes: 10, seconds: 30),
        thumbnailUrl: 'https://via.placeholder.com/640x360',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        videoType: VideoType.youtube,
        difficulty: VideoDifficulty.beginner,
        views: 1234,
        likes: 98,
        hasSubtitles: true,
        languages: ['en', 'es', 'fr'],
        tags: ['basics', 'introduction', topic.toLowerCase()],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      VideoContent(
        id: 'video_2',
        title: 'Advanced $topic Techniques',
        description: 'Master advanced concepts in $topic',
        subject: subject,
        topic: topic,
        duration: const Duration(minutes: 15, seconds: 45),
        thumbnailUrl: 'https://via.placeholder.com/640x360',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        videoType: VideoType.youtube,
        difficulty: VideoDifficulty.advanced,
        views: 567,
        likes: 45,
        hasSubtitles: true,
        languages: ['en'],
        tags: ['advanced', topic.toLowerCase()],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      VideoContent(
        id: 'video_3',
        title: 'Practice Problems: $topic',
        description: 'Work through example problems step by step',
        subject: subject,
        topic: topic,
        duration: const Duration(minutes: 20, seconds: 0),
        thumbnailUrl: 'https://via.placeholder.com/640x360',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        videoType: VideoType.youtube,
        difficulty: VideoDifficulty.intermediate,
        views: 890,
        likes: 72,
        hasSubtitles: true,
        languages: ['en', 'es'],
        tags: ['practice', 'examples', topic.toLowerCase()],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }
}

/// Video content model
class VideoContent {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String topic;
  final Duration duration;
  final String thumbnailUrl;
  final String videoUrl;
  final VideoType videoType;
  final VideoDifficulty difficulty;
  final int views;
  final int likes;
  final bool hasSubtitles;
  final List<String> languages;
  final List<String> tags;
  final DateTime createdAt;

  VideoContent({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.topic,
    required this.duration,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.videoType,
    required this.difficulty,
    required this.views,
    required this.likes,
    required this.hasSubtitles,
    required this.languages,
    required this.tags,
    required this.createdAt,
  });

  String get durationFormatted {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Video progress model
class VideoProgress {
  final String videoId;
  final Duration position;
  final Duration duration;
  final DateTime lastWatched;
  final bool completed;

  VideoProgress({
    required this.videoId,
    required this.position,
    required this.duration,
    required this.lastWatched,
    required this.completed,
  });

  int get progressPercentage {
    return (position.inSeconds / duration.inSeconds * 100).toInt();
  }
}

enum VideoType {
  youtube,
  vimeo,
  custom,
}

enum VideoDifficulty {
  beginner,
  intermediate,
  advanced,
}

extension VideoDifficultyExtension on VideoDifficulty {
  String get displayName {
    switch (this) {
      case VideoDifficulty.beginner:
        return 'Beginner';
      case VideoDifficulty.intermediate:
        return 'Intermediate';
      case VideoDifficulty.advanced:
        return 'Advanced';
    }
  }

  Color get color {
    switch (this) {
      case VideoDifficulty.beginner:
        return const Color(0xFF4CAF50); // Green
      case VideoDifficulty.intermediate:
        return const Color(0xFFFF9800); // Orange
      case VideoDifficulty.advanced:
        return const Color(0xFFF44336); // Red
    }
  }
}

extension VideoContentServiceExtension on VideoContentService {
  /// Get videos by subject
  Future<List<VideoContent>> getVideosBySubject(String subject) async {
    return await getVideos(subject: subject);
  }
}

/// Usage Example:
/// 
/// ```dart
/// // Get videos for a topic
/// final videos = await VideoContentService().getVideosForTopic(
///   subject: 'Math',
///   topic: 'Algebra',
/// );
/// 
/// // Display in UI
/// VideoLibraryWidget(videos: videos)
/// 
/// // Track progress
/// await VideoContentService().trackProgress(
///   userId: 'user123',
///   videoId: 'video_1',
///   position: Duration(minutes: 5),
///   duration: Duration(minutes: 10),
/// );
/// ```

/// Note: To implement video playback, add these dependencies to pubspec.yaml:
/// - youtube_player_flutter: ^8.1.2 (for YouTube videos)
/// - video_player: ^2.8.1 (for custom videos)
/// - chewie: ^1.7.5 (for better video player UI)

