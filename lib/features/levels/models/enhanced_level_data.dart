import 'package:flutter/material.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/features/levels/widgets/level_node.dart';

/// Enhanced level data structure for progressive unlock system
class EnhancedLevelData {
  final int level;
  final LevelNodeState state;
  final int stars;
  final int bestScore;
  final double accuracy;
  final Color difficultyColor;
  final double difficulty;
  final String unlockReason;
  final double skillProgress;
  final bool isRecommended;
  final bool isUnlocked;
  final int attempts;
  final double bestAccuracy;

  EnhancedLevelData({
    required this.level,
    required this.state,
    this.stars = 0,
    this.bestScore = 0,
    this.accuracy = 0.0,
    required this.difficultyColor,
    required this.difficulty,
    this.unlockReason = '',
    this.skillProgress = 0.0,
    this.isRecommended = false,
    required this.isUnlocked,
    this.attempts = 0,
    this.bestAccuracy = 0.0,
  });

  /// Convert to LevelNodeData for widget compatibility
  LevelNodeData toLevelNodeData() {
    return LevelNodeData(
      level: level,
      state: state,
      stars: stars,
      bestScore: bestScore,
      accuracy: accuracy,
      difficultyColor: difficultyColor,
      difficulty: difficulty.round(),
    );
  }

  /// Create a copy with updated values
  EnhancedLevelData copyWith({
    int? level,
    LevelNodeState? state,
    int? stars,
    int? bestScore,
    double? accuracy,
    Color? difficultyColor,
    double? difficulty,
    String? unlockReason,
    double? skillProgress,
    bool? isRecommended,
    bool? isUnlocked,
    int? attempts,
    double? bestAccuracy,
  }) {
    return EnhancedLevelData(
      level: level ?? this.level,
      state: state ?? this.state,
      stars: stars ?? this.stars,
      bestScore: bestScore ?? this.bestScore,
      accuracy: accuracy ?? this.accuracy,
      difficultyColor: difficultyColor ?? this.difficultyColor,
      difficulty: difficulty ?? this.difficulty,
      unlockReason: unlockReason ?? this.unlockReason,
      skillProgress: skillProgress ?? this.skillProgress,
      isRecommended: isRecommended ?? this.isRecommended,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      attempts: attempts ?? this.attempts,
      bestAccuracy: bestAccuracy ?? this.bestAccuracy,
    );
  }
}