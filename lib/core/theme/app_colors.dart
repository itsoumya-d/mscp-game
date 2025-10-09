import 'package:flutter/material.dart';

/// Unified color palette for the LearnoSphere educational app
/// Based on research of top educational apps (Duolingo, Khan Academy, Brilliant.org, Photomath)
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Brand Colors
  static const Color primaryBlue = Color(0xFF2196F3);      // Main brand color
  static const Color primaryDark = Color(0xFF1976D2);      // Dark variant
  static const Color primaryLight = Color(0xFF64B5F6);     // Light variant

  // Secondary Colors
  static const Color secondaryGreen = Color(0xFF4CAF50);   // Success/Correct
  static const Color secondaryOrange = Color(0xFFFF9800);  // Warning/In Progress
  static const Color secondaryRed = Color(0xFFF44336);     // Error/Incorrect
  static const Color secondaryPurple = Color(0xFF9C27B0);  // Special actions

  // Background Colors
  static const Color backgroundPrimary = Color(0xFFFAFAFA);   // Main background
  static const Color backgroundSecondary = Color(0xFFFFFFFF); // Card backgrounds
  static const Color backgroundTertiary = Color(0xFFF5F5F5);  // Section backgrounds
  static const Color backgroundOverlay = Color(0x80000000);   // Modal overlays

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);      // Main text
  static const Color textSecondary = Color(0xFF757575);    // Secondary text
  static const Color textHint = Color(0xFF9E9E9E);         // Hint text
  static const Color textOnPrimary = Color(0xFFFFFFFF);    // Text on colored backgrounds
  static const Color textOnDark = Color(0xFFFFFFFF);       // Text on dark backgrounds

  // Subject-Specific Colors
  static const Color mathColor = Color(0xFF3F51B5);        // Indigo
  static const Color physicsColor = Color(0xFF9C27B0);     // Purple
  static const Color chemistryColor = Color(0xFF009688);   // Teal
  static const Color biologyColor = Color(0xFF8BC34A);     // Light Green
  static const Color historyColor = Color(0xFF795548);     // Brown
  static const Color geographyColor = Color(0xFF607D8B);   // Blue Grey
  static const Color englishColor = Color(0xFFE91E63);     // Pink
  static const Color artColor = Color(0xFFFF5722);         // Deep Orange

  // Game State Colors
  static const Color correctAnswer = Color(0xFF4CAF50);     // Green
  static const Color incorrectAnswer = Color(0xFFF44336);   // Red
  static const Color selectedAnswer = Color(0xFF2196F3);    // Blue
  static const Color neutralAnswer = Color(0xFFE0E0E0);     // Grey

  // Progress Colors
  static const Color progressComplete = Color(0xFF4CAF50);  // Green
  static const Color progressInProgress = Color(0xFFFF9800); // Orange
  static const Color progressLocked = Color(0xFF9E9E9E);    // Grey

  // Level State Colors
  static const Color levelUnlocked = Color(0xFF4CAF50);     // Green
  static const Color levelLocked = Color(0xFF9E9E9E);       // Grey
  static const Color levelCompleted = Color(0xFFFFD700);    // Gold

  // Star Rating Colors
  static const Color starFilled = Color(0xFFFFD700);        // Gold
  static const Color starEmpty = Color(0xFFE0E0E0);         // Light Grey

  // Border Colors
  static const Color borderLight = Color(0xFFE0E0E0);       // Light border
  static const Color borderMedium = Color(0xFFBDBDBD);      // Medium border
  static const Color borderDark = Color(0xFF757575);        // Dark border

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);       // 10% black
  static const Color shadowMedium = Color(0x33000000);      // 20% black
  static const Color shadowDark = Color(0x4D000000);        // 30% black

  /// Get subject color by subject type
  static Color getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'math':
      case 'mathematics':
        return mathColor;
      case 'physics':
        return physicsColor;
      case 'chemistry':
        return chemistryColor;
      case 'biology':
        return biologyColor;
      case 'history':
        return historyColor;
      case 'geography':
        return geographyColor;
      case 'english':
        return englishColor;
      case 'art':
        return artColor;
      default:
        return primaryBlue;
    }
  }

  /// Get lighter version of a color
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }

  /// Get darker version of a color
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  /// Material Color Swatch for primary color
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF2196F3,
    <int, Color>{
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5),
      500: Color(0xFF2196F3),
      600: Color(0xFF1E88E5),
      700: Color(0xFF1976D2),
      800: Color(0xFF1565C0),
      900: Color(0xFF0D47A1),
    },
  );
}
