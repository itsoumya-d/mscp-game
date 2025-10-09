import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Unified decoration system for the LearnoSphere educational app
/// Provides consistent box decorations, borders, and shadows
class AppDecorations {
  AppDecorations._(); // Private constructor to prevent instantiation

  // Standard Border Radius
  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(4));
  static const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusXLarge = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXXLarge = BorderRadius.all(Radius.circular(24));

  // Standard Shadows
  static const List<BoxShadow> shadowLight = [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: AppColors.shadowDark,
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  // Card Decorations
  static const BoxDecoration standardCard = BoxDecoration(
    color: AppColors.backgroundSecondary,
    borderRadius: radiusLarge,
    boxShadow: shadowLight,
  );

  static const BoxDecoration elevatedCard = BoxDecoration(
    color: AppColors.backgroundSecondary,
    borderRadius: radiusLarge,
    boxShadow: shadowMedium,
  );

  static const BoxDecoration prominentCard = BoxDecoration(
    color: AppColors.backgroundSecondary,
    borderRadius: radiusXLarge,
    boxShadow: shadowLarge,
  );

  // Subject Card Decorations
  static BoxDecoration subjectCard(String subject) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.getSubjectColor(subject),
          AppColors.darken(AppColors.getSubjectColor(subject), 0.1),
        ],
      ),
      borderRadius: radiusXLarge,
      boxShadow: shadowMedium,
    );
  }

  // Level Node Decorations
  static const BoxDecoration levelNodeUnlocked = BoxDecoration(
    color: AppColors.levelUnlocked,
    shape: BoxShape.circle,
    boxShadow: shadowMedium,
  );

  static const BoxDecoration levelNodeLocked = BoxDecoration(
    color: AppColors.levelLocked,
    shape: BoxShape.circle,
    boxShadow: shadowLight,
  );

  static const BoxDecoration levelNodeCompleted = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.levelCompleted,
        Color(0xFFFFB300), // Darker gold
      ],
    ),
    shape: BoxShape.circle,
    boxShadow: shadowMedium,
  );

  // Button Decorations
  static const BoxDecoration primaryButton = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primaryBlue,
        AppColors.primaryDark,
      ],
    ),
    borderRadius: radiusMedium,
    boxShadow: shadowLight,
  );

  static const BoxDecoration secondaryButton = BoxDecoration(
    color: AppColors.backgroundSecondary,
    borderRadius: radiusMedium,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.primaryBlue, width: 2),
    ),
    boxShadow: shadowLight,
  );

  // Answer Button Decorations
  static const BoxDecoration answerButton = BoxDecoration(
    color: AppColors.backgroundSecondary,
    borderRadius: radiusLarge,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.borderLight, width: 1),
    ),
    boxShadow: shadowLight,
  );

  static const BoxDecoration selectedAnswerButton = BoxDecoration(
    color: AppColors.backgroundSecondary,
    borderRadius: radiusLarge,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.selectedAnswer, width: 2),
    ),
    boxShadow: shadowMedium,
  );

  static const BoxDecoration correctAnswerButton = BoxDecoration(
    color: Color(0xFFE8F5E8), // Light green background
    borderRadius: radiusLarge,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.correctAnswer, width: 2),
    ),
    boxShadow: shadowMedium,
  );

  static const BoxDecoration incorrectAnswerButton = BoxDecoration(
    color: Color(0xFFFFEBEE), // Light red background
    borderRadius: radiusLarge,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.incorrectAnswer, width: 2),
    ),
    boxShadow: shadowMedium,
  );

  // Progress Decorations
  static const BoxDecoration progressBarBackground = BoxDecoration(
    color: AppColors.borderLight,
    borderRadius: radiusSmall,
  );

  static const BoxDecoration progressBarFill = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        AppColors.primaryLight,
        AppColors.primaryBlue,
      ],
    ),
    borderRadius: radiusSmall,
  );

  // Input Field Decorations
  static const BoxDecoration inputField = BoxDecoration(
    color: AppColors.backgroundSecondary,
    borderRadius: radiusMedium,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.borderLight, width: 1),
    ),
  );

  static const BoxDecoration inputFieldFocused = BoxDecoration(
    color: AppColors.backgroundSecondary,
    borderRadius: radiusMedium,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.primaryBlue, width: 2),
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryLight,
        blurRadius: 4,
        offset: Offset(0, 0),
      ),
    ],
  );

  static const BoxDecoration inputFieldError = BoxDecoration(
    color: AppColors.backgroundSecondary,
    borderRadius: radiusMedium,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.incorrectAnswer, width: 2),
    ),
  );

  // Modal Decorations
  static const BoxDecoration modalBackground = BoxDecoration(
    color: AppColors.backgroundSecondary,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(24),
    ),
    boxShadow: shadowLarge,
  );

  static const BoxDecoration dialogBackground = BoxDecoration(
    color: AppColors.backgroundSecondary,
    borderRadius: radiusXLarge,
    boxShadow: shadowLarge,
  );

  // Navigation Decorations
  static const BoxDecoration bottomNavigation = BoxDecoration(
    color: AppColors.backgroundSecondary,
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowLight,
        blurRadius: 8,
        offset: Offset(0, -2),
      ),
    ],
  );

  static const BoxDecoration appBarDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primaryBlue,
        AppColors.primaryDark,
      ],
    ),
  );

  // Game Screen Decorations
  static const BoxDecoration gameBackground = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.backgroundPrimary,
        AppColors.backgroundTertiary,
      ],
    ),
  );

  static const BoxDecoration questionCard = BoxDecoration(
    color: AppColors.backgroundSecondary,
    borderRadius: radiusXLarge,
    boxShadow: shadowMedium,
  );

  // Star Rating Decorations
  static const BoxDecoration starContainer = BoxDecoration(
    color: AppColors.backgroundSecondary,
    borderRadius: radiusSmall,
    boxShadow: shadowLight,
  );

  // Helper Methods

  /// Create a decoration with custom color
  static BoxDecoration withColor(BoxDecoration decoration, Color color) {
    return decoration.copyWith(color: color);
  }

  /// Create a decoration with custom border radius
  static BoxDecoration withRadius(BoxDecoration decoration, BorderRadius radius) {
    return decoration.copyWith(borderRadius: radius);
  }

  /// Create a decoration with custom shadow
  static BoxDecoration withShadow(BoxDecoration decoration, List<BoxShadow> shadow) {
    return decoration.copyWith(boxShadow: shadow);
  }

  /// Get answer button decoration based on state
  static BoxDecoration getAnswerButtonDecoration({
    bool isSelected = false,
    bool isCorrect = false,
    bool isIncorrect = false,
  }) {
    if (isCorrect) {
      return correctAnswerButton;
    } else if (isIncorrect) {
      return incorrectAnswerButton;
    } else if (isSelected) {
      return selectedAnswerButton;
    } else {
      return answerButton;
    }
  }

  /// Get level node decoration based on state
  static BoxDecoration getLevelNodeDecoration({
    bool isUnlocked = false,
    bool isCompleted = false,
  }) {
    if (isCompleted) {
      return levelNodeCompleted;
    } else if (isUnlocked) {
      return levelNodeUnlocked;
    } else {
      return levelNodeLocked;
    }
  }
}
