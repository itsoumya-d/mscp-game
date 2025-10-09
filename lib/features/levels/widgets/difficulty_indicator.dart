import 'package:flutter/material.dart';

/// A widget that displays difficulty level with visual indicators
class DifficultyIndicator extends StatelessWidget {
  final int difficulty;
  final bool showLabel;
  final double size;
  final bool showStars;

  const DifficultyIndicator({
    Key? key,
    required this.difficulty,
    this.showLabel = true,
    this.size = 24.0,
    this.showStars = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficultyData = _getDifficultyData(difficulty);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showStars) ...[
          _buildStarIndicator(difficultyData),
          if (showLabel) const SizedBox(width: 8),
        ] else ...[
          _buildBarIndicator(difficultyData),
          if (showLabel) const SizedBox(width: 8),
        ],
        if (showLabel)
          Text(
            difficultyData.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: difficultyData.color,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildBarIndicator(DifficultyData data) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isActive = index < data.level;
        return Container(
          width: size * 0.3,
          height: size,
          margin: EdgeInsets.only(right: size * 0.1),
          decoration: BoxDecoration(
            color: isActive ? data.color : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildStarIndicator(DifficultyData data) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isActive = index < data.level;
        return Icon(
          isActive ? Icons.star : Icons.star_border,
          color: isActive ? data.color : Colors.grey.withOpacity(0.3),
          size: size,
        );
      }),
    );
  }

  DifficultyData _getDifficultyData(int difficulty) {
    if (difficulty <= 2) {
      return DifficultyData(
        level: 1,
        label: 'Beginner',
        color: Colors.green,
      );
    } else if (difficulty <= 4) {
      return DifficultyData(
        level: 2,
        label: 'Easy',
        color: Colors.lightGreen,
      );
    } else if (difficulty <= 6) {
      return DifficultyData(
        level: 3,
        label: 'Medium',
        color: Colors.orange,
      );
    } else if (difficulty <= 8) {
      return DifficultyData(
        level: 4,
        label: 'Hard',
        color: Colors.deepOrange,
      );
    } else {
      return DifficultyData(
        level: 5,
        label: 'Expert',
        color: Colors.red,
      );
    }
  }
}

/// Data class for difficulty information
class DifficultyData {
  final int level;
  final String label;
  final Color color;

  DifficultyData({
    required this.level,
    required this.label,
    required this.color,
  });
}

/// A compact difficulty badge widget
class DifficultyBadge extends StatelessWidget {
  final int difficulty;
  final double size;

  const DifficultyBadge({
    Key? key,
    required this.difficulty,
    this.size = 32.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = _getDifficultyData(difficulty);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: data.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${data.level}',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }

  DifficultyData _getDifficultyData(int difficulty) {
    if (difficulty <= 2) {
      return DifficultyData(level: 1, label: 'Beginner', color: Colors.green);
    } else if (difficulty <= 4) {
      return DifficultyData(level: 2, label: 'Easy', color: Colors.lightGreen);
    } else if (difficulty <= 6) {
      return DifficultyData(level: 3, label: 'Medium', color: Colors.orange);
    } else if (difficulty <= 8) {
      return DifficultyData(level: 4, label: 'Hard', color: Colors.deepOrange);
    } else {
      return DifficultyData(level: 5, label: 'Expert', color: Colors.red);
    }
  }
}