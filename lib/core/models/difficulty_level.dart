/// Difficulty levels for adaptive learning system
enum DifficultyLevel {
  beginner,
  easy,
  medium,
  hard,
  expert,
}

extension DifficultyLevelExtension on DifficultyLevel {
  /// Get the display name for the difficulty level
  String get displayName {
    switch (this) {
      case DifficultyLevel.beginner:
        return 'Beginner';
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
      case DifficultyLevel.expert:
        return 'Expert';
    }
  }

  /// Get the numeric level (1-10 scale)
  int get numericLevel {
    switch (this) {
      case DifficultyLevel.beginner:
        return 1;
      case DifficultyLevel.easy:
        return 3;
      case DifficultyLevel.medium:
        return 5;
      case DifficultyLevel.hard:
        return 7;
      case DifficultyLevel.expert:
        return 10;
    }
  }

  /// Get the color associated with this difficulty level
  int get colorValue {
    switch (this) {
      case DifficultyLevel.beginner:
        return 0xFF4CAF50; // Green
      case DifficultyLevel.easy:
        return 0xFF8BC34A; // Light Green
      case DifficultyLevel.medium:
        return 0xFFFF9800; // Orange
      case DifficultyLevel.hard:
        return 0xFFFF5722; // Deep Orange
      case DifficultyLevel.expert:
        return 0xFFF44336; // Red
    }
  }

  /// Get points awarded for completing this difficulty level
  int get points {
    switch (this) {
      case DifficultyLevel.beginner:
        return 10;
      case DifficultyLevel.easy:
        return 20;
      case DifficultyLevel.medium:
        return 30;
      case DifficultyLevel.hard:
        return 40;
      case DifficultyLevel.expert:
        return 50;
    }
  }
}