import 'package:flutter/material.dart';

/// Types of unlock events that can occur
enum UnlockType {
  level,
  multipleLevels,
  chapter,
  achievement,
  skillMastery,
  bonus,
  milestone,
}

/// Represents an unlock event with all necessary data for animations and celebrations
class UnlockEvent {
  final String id;
  final UnlockType type;
  final String title;
  final String subtitle;
  final String description;
  final IconData iconData;
  final Color primaryColor;
  final Color secondaryColor;
  final int animationDuration; // in milliseconds
  final Map<String, int> rewards; // e.g., {'xp': 100, 'gems': 5}
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  UnlockEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.iconData,
    required this.primaryColor,
    required this.secondaryColor,
    required this.animationDuration,
    this.rewards = const {},
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a copy with updated values
  UnlockEvent copyWith({
    String? id,
    UnlockType? type,
    String? title,
    String? subtitle,
    String? description,
    IconData? iconData,
    Color? primaryColor,
    Color? secondaryColor,
    int? animationDuration,
    Map<String, int>? rewards,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) {
    return UnlockEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      iconData: iconData ?? this.iconData,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      animationDuration: animationDuration ?? this.animationDuration,
      rewards: rewards ?? this.rewards,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'iconData': iconData.codePoint,
      'primaryColor': primaryColor.value,
      'secondaryColor': secondaryColor.value,
      'animationDuration': animationDuration,
      'rewards': rewards,
      'metadata': metadata,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// Create from JSON
  factory UnlockEvent.fromJson(Map<String, dynamic> json) {
    return UnlockEvent(
      id: json['id'] as String,
      type: UnlockType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => UnlockType.level,
      ),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String,
      iconData: IconData(
        json['iconData'] as int,
        fontFamily: 'MaterialIcons',
      ),
      primaryColor: Color(json['primaryColor'] as int),
      secondaryColor: Color(json['secondaryColor'] as int),
      animationDuration: json['animationDuration'] as int,
      rewards: Map<String, int>.from(json['rewards'] as Map),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }

  /// Get total XP reward
  int get xpReward => rewards['xp'] ?? 0;

  /// Get total gem reward
  int get gemReward => rewards['gems'] ?? 0;

  /// Check if event has rewards
  bool get hasRewards => rewards.isNotEmpty;

  /// Get formatted rewards string
  String get rewardsText {
    if (!hasRewards) return '';
    
    final parts = <String>[];
    if (xpReward > 0) parts.add('+$xpReward XP');
    if (gemReward > 0) parts.add('+$gemReward Gems');
    
    return parts.join(' • ');
  }

  /// Get type display name
  String get typeDisplayName {
    switch (type) {
      case UnlockType.level:
        return 'Level';
      case UnlockType.multipleLevels:
        return 'Levels';
      case UnlockType.chapter:
        return 'Chapter';
      case UnlockType.achievement:
        return 'Achievement';
      case UnlockType.skillMastery:
        return 'Skill Mastery';
      case UnlockType.bonus:
        return 'Bonus';
      case UnlockType.milestone:
        return 'Milestone';
    }
  }

  @override
  String toString() {
    return 'UnlockEvent(id: $id, type: $type, title: $title, subtitle: $subtitle)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnlockEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}