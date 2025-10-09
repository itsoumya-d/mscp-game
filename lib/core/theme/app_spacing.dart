import 'package:flutter/material.dart';

/// Unified spacing system for the LearnoSphere educational app
/// Provides consistent spacing values and edge insets
class AppSpacing {
  AppSpacing._(); // Private constructor to prevent instantiation

  // Base Spacing Values (following 8px grid system)
  static const double xs = 4.0;    // Extra small
  static const double sm = 8.0;    // Small
  static const double md = 12.0;   // Medium
  static const double lg = 16.0;   // Large
  static const double xl = 20.0;   // Extra large
  static const double xxl = 24.0;  // Double extra large
  static const double xxxl = 32.0; // Triple extra large
  static const double huge = 48.0; // Huge
  static const double massive = 64.0; // Massive

  // Semantic Spacing Names
  static const double tiny = xs;
  static const double small = sm;
  static const double medium = lg;
  static const double large = xxl;
  static const double extraLarge = xxxl;

  // Layout Spacing
  static const double screenPadding = lg;        // 16px - Standard screen padding
  static const double sectionSpacing = xxl;     // 24px - Between major sections
  static const double cardPadding = lg;         // 16px - Inside cards
  static const double buttonPadding = md;       // 12px - Button internal padding
  static const double listItemSpacing = sm;     // 8px - Between list items
  static const double gridSpacing = lg;         // 16px - Grid item spacing

  // Component Spacing
  static const double iconTextSpacing = sm;     // 8px - Between icon and text
  static const double labelInputSpacing = xs;   // 4px - Between label and input
  static const double buttonSpacing = md;       // 12px - Between buttons
  static const double chipSpacing = sm;         // 8px - Between chips
  static const double tabSpacing = lg;          // 16px - Between tabs

  // Game Screen Spacing
  static const double questionSpacing = xxl;    // 24px - Around question text
  static const double answerSpacing = md;       // 12px - Between answer options
  static const double progressSpacing = lg;     // 16px - Around progress indicators
  static const double feedbackSpacing = lg;     // 16px - Around feedback text

  // Edge Insets - All Sides
  static const EdgeInsets allXS = EdgeInsets.all(xs);
  static const EdgeInsets allSM = EdgeInsets.all(sm);
  static const EdgeInsets allMD = EdgeInsets.all(md);
  static const EdgeInsets allLG = EdgeInsets.all(lg);
  static const EdgeInsets allXL = EdgeInsets.all(xl);
  static const EdgeInsets allXXL = EdgeInsets.all(xxl);
  static const EdgeInsets allXXXL = EdgeInsets.all(xxxl);

  // Edge Insets - Horizontal
  static const EdgeInsets horizontalXS = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSM = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLG = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXL = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets horizontalXXL = EdgeInsets.symmetric(horizontal: xxl);
  static const EdgeInsets horizontalXXXL = EdgeInsets.symmetric(horizontal: xxxl);

  // Edge Insets - Vertical
  static const EdgeInsets verticalXS = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSM = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLG = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXL = EdgeInsets.symmetric(vertical: xl);
  static const EdgeInsets verticalXXL = EdgeInsets.symmetric(vertical: xxl);
  static const EdgeInsets verticalXXXL = EdgeInsets.symmetric(vertical: xxxl);

  // Common Layout Patterns
  static const EdgeInsets screenMargin = EdgeInsets.all(screenPadding);
  static const EdgeInsets cardMargin = EdgeInsets.all(cardPadding);
  static const EdgeInsets buttonMargin = EdgeInsets.symmetric(
    horizontal: buttonPadding,
    vertical: sm,
  );

  // Specific Component Spacing
  static const EdgeInsets appBarPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );

  static const EdgeInsets bottomNavPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );

  static const EdgeInsets dialogPadding = EdgeInsets.all(xxl);

  static const EdgeInsets modalPadding = EdgeInsets.all(lg);

  static const EdgeInsets listTilePadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: xs,
  );

  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  // Game Screen Specific
  static const EdgeInsets questionPadding = EdgeInsets.all(questionSpacing);
  static const EdgeInsets answerPadding = EdgeInsets.all(lg);
  static const EdgeInsets progressPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );

  // Level Selection Specific
  static const EdgeInsets levelNodePadding = EdgeInsets.all(md);
  static const EdgeInsets levelGridPadding = EdgeInsets.all(lg);

  // Subject Card Specific
  static const EdgeInsets subjectCardPadding = EdgeInsets.all(lg);
  static const EdgeInsets subjectCardMargin = EdgeInsets.all(sm);

  // SizedBox Helpers for Vertical Spacing
  static const SizedBox verticalSpaceXS = SizedBox(height: xs);
  static const SizedBox verticalSpaceSM = SizedBox(height: sm);
  static const SizedBox verticalSpaceMD = SizedBox(height: md);
  static const SizedBox verticalSpaceLG = SizedBox(height: lg);
  static const SizedBox verticalSpaceXL = SizedBox(height: xl);
  static const SizedBox verticalSpaceXXL = SizedBox(height: xxl);
  static const SizedBox verticalSpaceXXXL = SizedBox(height: xxxl);
  static const SizedBox verticalSpaceHuge = SizedBox(height: huge);

  // SizedBox Helpers for Horizontal Spacing
  static const SizedBox horizontalSpaceXS = SizedBox(width: xs);
  static const SizedBox horizontalSpaceSM = SizedBox(width: sm);
  static const SizedBox horizontalSpaceMD = SizedBox(width: md);
  static const SizedBox horizontalSpaceLG = SizedBox(width: lg);
  static const SizedBox horizontalSpaceXL = SizedBox(width: xl);
  static const SizedBox horizontalSpaceXXL = SizedBox(width: xxl);
  static const SizedBox horizontalSpaceXXXL = SizedBox(width: xxxl);
  static const SizedBox horizontalSpaceHuge = SizedBox(width: huge);

  // Responsive Spacing Helpers
  
  /// Get responsive horizontal padding based on screen width
  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return horizontalXXXL; // Desktop
    } else if (screenWidth > 600) {
      return horizontalXXL;  // Tablet
    } else {
      return horizontalLG;   // Mobile
    }
  }

  /// Get responsive screen padding based on screen width
  static EdgeInsets responsiveScreenPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return const EdgeInsets.all(xxxl); // Desktop
    } else if (screenWidth > 600) {
      return const EdgeInsets.all(xxl);  // Tablet
    } else {
      return const EdgeInsets.all(lg);   // Mobile
    }
  }

  /// Get responsive grid spacing based on screen width
  static double responsiveGridSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return xxl; // Desktop
    } else if (screenWidth > 600) {
      return lg;  // Tablet
    } else {
      return md;  // Mobile
    }
  }

  /// Create custom EdgeInsets
  static EdgeInsets custom({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    if (all != null) {
      return EdgeInsets.all(all);
    } else if (horizontal != null || vertical != null) {
      return EdgeInsets.symmetric(
        horizontal: horizontal ?? 0,
        vertical: vertical ?? 0,
      );
    } else {
      return EdgeInsets.only(
        top: top ?? 0,
        bottom: bottom ?? 0,
        left: left ?? 0,
        right: right ?? 0,
      );
    }
  }

  /// Create custom SizedBox for vertical spacing
  static SizedBox verticalSpace(double height) {
    return SizedBox(height: height);
  }

  /// Create custom SizedBox for horizontal spacing
  static SizedBox horizontalSpace(double width) {
    return SizedBox(width: width);
  }
}
