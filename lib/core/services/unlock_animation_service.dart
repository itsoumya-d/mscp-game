import 'dart:async';
import 'package:flutter/material.dart';
import '../models/unlock_event.dart';

/// Service responsible for managing and triggering unlock animations
/// when new levels, chapters, or achievements become available
class UnlockAnimationService {
  static UnlockAnimationService? _instance;
  static UnlockAnimationService get instance => _instance ??= UnlockAnimationService._();
  
  UnlockAnimationService._();

  final StreamController<UnlockEvent> _unlockEventController = StreamController<UnlockEvent>.broadcast();
  final List<UnlockEvent> _pendingUnlocks = [];
  bool _isShowingAnimation = false;

  /// Stream of unlock events for widgets to listen to
  Stream<UnlockEvent> get unlockEvents => _unlockEventController.stream;

  /// Queue an unlock animation to be shown
  Future<void> queueUnlockAnimation(UnlockEvent event) async {
    _pendingUnlocks.add(event);
    
    // If no animation is currently showing, start the next one
    if (!_isShowingAnimation) {
      await _processNextUnlock();
    }
  }

  /// Queue multiple unlock animations
  Future<void> queueMultipleUnlocks(List<UnlockEvent> events) async {
    _pendingUnlocks.addAll(events);
    
    if (!_isShowingAnimation) {
      await _processNextUnlock();
    }
  }

  /// Process the next unlock in the queue
  Future<void> _processNextUnlock() async {
    if (_pendingUnlocks.isEmpty || _isShowingAnimation) return;

    _isShowingAnimation = true;
    final event = _pendingUnlocks.removeAt(0);
    
    // Emit the unlock event
    _unlockEventController.add(event);
    
    // Wait for animation duration plus buffer
    await Future.delayed(Duration(milliseconds: event.animationDuration + 500));
    
    _isShowingAnimation = false;
    
    // Process next unlock if any
    if (_pendingUnlocks.isNotEmpty) {
      await _processNextUnlock();
    }
  }

  /// Create unlock event for a single level
  UnlockEvent createLevelUnlockEvent({
    required String levelId,
    required String levelName,
    required String subject,
    String? description,
    int? xpReward,
    int? gemReward,
  }) {
    return UnlockEvent(
      id: 'level_$levelId',
      type: UnlockType.level,
      title: 'New Level Unlocked!',
      subtitle: levelName,
      description: description ?? 'You can now access $levelName in $subject',
      iconData: Icons.star,
      primaryColor: _getSubjectColor(subject),
      secondaryColor: _getSubjectColor(subject).withOpacity(0.3),
      animationDuration: 3000,
      rewards: _createRewards(xpReward, gemReward),
      metadata: {
        'levelId': levelId,
        'subject': subject,
        'levelName': levelName,
      },
    );
  }

  /// Create unlock event for multiple levels
  UnlockEvent createMultipleLevelsUnlockEvent({
    required List<String> levelIds,
    required String subject,
    int? totalXpReward,
    int? totalGemReward,
  }) {
    return UnlockEvent(
      id: 'levels_${levelIds.join('_')}',
      type: UnlockType.multipleLevels,
      title: '${levelIds.length} New Levels Unlocked!',
      subtitle: 'Great progress in $subject!',
      description: 'You\'ve unlocked ${levelIds.length} new levels to explore',
      iconData: Icons.auto_awesome,
      primaryColor: _getSubjectColor(subject),
      secondaryColor: _getSubjectColor(subject).withOpacity(0.3),
      animationDuration: 4000,
      rewards: _createRewards(totalXpReward, totalGemReward),
      metadata: {
        'levelIds': levelIds,
        'subject': subject,
        'count': levelIds.length,
      },
    );
  }

  /// Create unlock event for a chapter
  UnlockEvent createChapterUnlockEvent({
    required String chapterId,
    required String chapterName,
    required String subject,
    String? description,
    int? xpReward,
    int? gemReward,
  }) {
    return UnlockEvent(
      id: 'chapter_$chapterId',
      type: UnlockType.chapter,
      title: 'New Chapter Unlocked!',
      subtitle: chapterName,
      description: description ?? 'Explore new challenges in $chapterName',
      iconData: Icons.menu_book,
      primaryColor: _getSubjectColor(subject),
      secondaryColor: _getSubjectColor(subject).withOpacity(0.3),
      animationDuration: 3500,
      rewards: _createRewards(xpReward, gemReward),
      metadata: {
        'chapterId': chapterId,
        'subject': subject,
        'chapterName': chapterName,
      },
    );
  }

  /// Create unlock event for an achievement
  UnlockEvent createAchievementUnlockEvent({
    required String achievementId,
    required String achievementName,
    String? description,
    int? xpReward,
    int? gemReward,
    IconData? iconData,
  }) {
    return UnlockEvent(
      id: 'achievement_$achievementId',
      type: UnlockType.achievement,
      title: 'Achievement Unlocked!',
      subtitle: achievementName,
      description: description ?? 'Congratulations on earning this achievement!',
      iconData: iconData ?? Icons.emoji_events,
      primaryColor: Colors.amber,
      secondaryColor: Colors.amber.withOpacity(0.3),
      animationDuration: 3000,
      rewards: _createRewards(xpReward, gemReward),
      metadata: {
        'achievementId': achievementId,
        'achievementName': achievementName,
      },
    );
  }

  /// Create unlock event for skill mastery
  UnlockEvent createSkillMasteryUnlockEvent({
    required String skillId,
    required String skillName,
    required String subject,
    String? description,
    int? xpReward,
    int? gemReward,
  }) {
    return UnlockEvent(
      id: 'skill_mastery_$skillId',
      type: UnlockType.skillMastery,
      title: 'Skill Mastered!',
      subtitle: skillName,
      description: description ?? 'You\'ve mastered $skillName in $subject!',
      iconData: Icons.psychology,
      primaryColor: Colors.purple,
      secondaryColor: Colors.purple.withOpacity(0.3),
      animationDuration: 3500,
      rewards: _createRewards(xpReward, gemReward),
      metadata: {
        'skillId': skillId,
        'skillName': skillName,
        'subject': subject,
      },
    );
  }

  /// Get color for subject
  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'math':
      case 'mathematics':
        return Colors.blue;
      case 'science':
        return Colors.green;
      case 'english':
      case 'language':
        return Colors.orange;
      case 'history':
        return Colors.brown;
      case 'geography':
        return Colors.teal;
      default:
        return Colors.indigo;
    }
  }

  /// Create rewards map
  Map<String, int> _createRewards(int? xpReward, int? gemReward) {
    final rewards = <String, int>{};
    if (xpReward != null && xpReward > 0) {
      rewards['xp'] = xpReward;
    }
    if (gemReward != null && gemReward > 0) {
      rewards['gems'] = gemReward;
    }
    return rewards;
  }

  /// Create unlock event for a single level (alias for backward compatibility)
  UnlockEvent createSingleLevelUnlockEvent({
    required String levelId,
    required String levelName,
    required String subjectName,
    String? description,
    int? xpReward,
    int? gemReward,
    Map<String, dynamic>? metadata,
  }) {
    return createLevelUnlockEvent(
      levelId: levelId,
      levelName: levelName,
      subject: subjectName,
      description: description,
      xpReward: xpReward,
      gemReward: gemReward,
    );
  }

  /// Queue an unlock event (alias for backward compatibility)
  Future<void> queueUnlockEvent(UnlockEvent event) async {
    await queueUnlockAnimation(event);
  }

  /// Clear all pending unlocks
  void clearPendingUnlocks() {
    _pendingUnlocks.clear();
    _isShowingAnimation = false;
  }

  /// Check if animations are currently being shown
  bool get isShowingAnimation => _isShowingAnimation;

  /// Get count of pending unlocks
  int get pendingUnlocksCount => _pendingUnlocks.length;

  /// Dispose resources
  void dispose() {
    _unlockEventController.close();
    _pendingUnlocks.clear();
  }
}