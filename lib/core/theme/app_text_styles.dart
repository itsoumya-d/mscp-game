import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Unified typography system for the LearnoSphere educational app
/// Based on Material Design 3 typography with educational app optimizations
class AppTextStyles {
  AppTextStyles._(); // Private constructor to prevent instantiation

  // Font Families
  static const String primaryFont = 'Roboto';
  static const String headingFont = 'Roboto';

  // Display Styles (for large headings)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: headingFont,
    fontSize: 57,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: headingFont,
    fontSize: 45,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: headingFont,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0,
    height: 1.22,
  );

  // Headline Styles (for section headings)
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: headingFont,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: headingFont,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: headingFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0,
    height: 1.33,
  );

  // Title Styles (for card titles, screen titles)
  static const TextStyle titleLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // Body Styles (for main content)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Label Styles (for buttons, form labels)
  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // Special Styles for Educational App
  
  // Question Text (large, readable for game questions)
  static const TextStyle questionText = TextStyle(
    fontFamily: primaryFont,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0,
    height: 1.4,
  );

  // Answer Option Text
  static const TextStyle answerText = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0.15,
    height: 1.5,
  );

  // Button Text
  static const TextStyle buttonText = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.5,
    height: 1.25,
  );

  // Score/Progress Text
  static const TextStyle scoreText = TextStyle(
    fontFamily: primaryFont,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBlue,
    letterSpacing: 0,
    height: 1.2,
  );

  // Caption Text (for hints, descriptions)
  static const TextStyle captionText = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Subject Title Text
  static const TextStyle subjectTitle = TextStyle(
    fontFamily: headingFont,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    letterSpacing: 0,
    height: 1.3,
  );

  // Level Number Text
  static const TextStyle levelNumber = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
    letterSpacing: 0,
    height: 1.25,
  );

  // Feedback Text (correct/incorrect)
  static const TextStyle feedbackText = TextStyle(
    fontFamily: primaryFont,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0,
    height: 1.3,
  );

  // Navigation Text
  static const TextStyle navigationText = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
    height: 1.33,
  );

  // Helper Methods

  /// Create a text style with custom color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Create a text style with custom weight
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Create a text style with custom size
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// Get text style for subject
  static TextStyle getSubjectTextStyle(String subject) {
    return subjectTitle.copyWith(
      color: AppColors.getSubjectColor(subject),
    );
  }

  /// Get feedback text style based on correctness
  static TextStyle getFeedbackTextStyle(bool isCorrect) {
    return feedbackText.copyWith(
      color: isCorrect ? AppColors.correctAnswer : AppColors.incorrectAnswer,
    );
  }

  /// Get answer text style based on state
  static TextStyle getAnswerTextStyle({
    bool isSelected = false,
    bool isCorrect = false,
    bool isIncorrect = false,
  }) {
    Color color = AppColors.textPrimary;
    
    if (isCorrect) {
      color = AppColors.correctAnswer;
    } else if (isIncorrect) {
      color = AppColors.incorrectAnswer;
    } else if (isSelected) {
      color = AppColors.selectedAnswer;
    }

    return answerText.copyWith(color: color);
  }
}
