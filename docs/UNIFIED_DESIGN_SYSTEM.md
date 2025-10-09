# Unified Design System
## Educational Game App - LearnoSphere

### Overview
This design system provides consistent visual and interaction patterns across all 52 screens of the LearnoSphere educational app, based on research of top educational apps (Duolingo, Khan Academy, Brilliant.org, Photomath).

---

## 1. Color Palette

### Primary Colors
```dart
// Primary Brand Colors
static const Color primaryBlue = Color(0xFF2196F3);      // Main brand color
static const Color primaryDark = Color(0xFF1976D2);      // Dark variant
static const Color primaryLight = Color(0xFF64B5F6);     // Light variant

// Secondary Colors
static const Color secondaryGreen = Color(0xFF4CAF50);   // Success/Correct
static const Color secondaryOrange = Color(0xFFFF9800);  // Warning/In Progress
static const Color secondaryRed = Color(0xFFF44336);     // Error/Incorrect
```

### Neutral Colors
```dart
// Background Colors
static const Color backgroundPrimary = Color(0xFFFAFAFA);   // Main background
static const Color backgroundSecondary = Color(0xFFFFFFFF); // Card backgrounds
static const Color backgroundTertiary = Color(0xFFF5F5F5);  // Section backgrounds

// Text Colors
static const Color textPrimary = Color(0xFF212121);      // Main text
static const Color textSecondary = Color(0xFF757575);    // Secondary text
static const Color textHint = Color(0xFF9E9E9E);         // Hint text
static const Color textOnPrimary = Color(0xFFFFFFFF);    // Text on colored backgrounds
```

### Subject-Specific Colors
```dart
// Subject Colors (for cards and icons)
static const Color mathColor = Color(0xFF3F51B5);        // Indigo
static const Color physicsColor = Color(0xFF9C27B0);     // Purple
static const Color chemistryColor = Color(0xFF009688);   // Teal
static const Color biologyColor = Color(0xFF8BC34A);     // Light Green
static const Color historyColor = Color(0xFF795548);     // Brown
static const Color geographyColor = Color(0xFF607D8B);   // Blue Grey
```

---

## 2. Typography System

### Font Families
```dart
// Primary Font: Roboto (system default)
static const String primaryFont = 'Roboto';

// Secondary Font: Roboto Slab (for headings)
static const String headingFont = 'Roboto';
```

### Text Styles
```dart
// Headings
static const TextStyle heading1 = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: textPrimary,
  letterSpacing: -0.5,
);

static const TextStyle heading2 = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: textPrimary,
  letterSpacing: -0.25,
);

static const TextStyle heading3 = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  color: textPrimary,
);

// Body Text
static const TextStyle bodyLarge = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.normal,
  color: textPrimary,
  height: 1.5,
);

static const TextStyle bodyMedium = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.normal,
  color: textPrimary,
  height: 1.4,
);

static const TextStyle bodySmall = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.normal,
  color: textSecondary,
  height: 1.3,
);

// Special Text
static const TextStyle buttonText = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.5,
);

static const TextStyle captionText = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.normal,
  color: textHint,
);
```

---

## 3. Component Styles

### Buttons
```dart
// Primary Button
static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
  backgroundColor: primaryBlue,
  foregroundColor: textOnPrimary,
  elevation: 2,
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  textStyle: buttonText,
);

// Secondary Button
static final ButtonStyle secondaryButton = OutlinedButton.styleFrom(
  foregroundColor: primaryBlue,
  side: BorderSide(color: primaryBlue, width: 2),
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  textStyle: buttonText,
);

// Answer Button (for game questions)
static final ButtonStyle answerButton = ElevatedButton.styleFrom(
  backgroundColor: backgroundSecondary,
  foregroundColor: textPrimary,
  elevation: 1,
  padding: EdgeInsets.all(16),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: Color(0xFFE0E0E0), width: 1),
  ),
);

// Correct Answer Button
static final ButtonStyle correctAnswerButton = answerButton.copyWith(
  backgroundColor: MaterialStateProperty.all(Color(0xFFE8F5E8)),
  side: MaterialStateProperty.all(BorderSide(color: secondaryGreen, width: 2)),
);

// Incorrect Answer Button
static final ButtonStyle incorrectAnswerButton = answerButton.copyWith(
  backgroundColor: MaterialStateProperty.all(Color(0xFFFFEBEE)),
  side: MaterialStateProperty.all(BorderSide(color: secondaryRed, width: 2)),
);
```

### Cards
```dart
// Standard Card
static final BoxDecoration standardCard = BoxDecoration(
  color: backgroundSecondary,
  borderRadius: BorderRadius.circular(12),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ],
);

// Subject Card
static final BoxDecoration subjectCard = BoxDecoration(
  color: backgroundSecondary,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ],
);

// Level Node (for level selection)
static final BoxDecoration levelNode = BoxDecoration(
  color: backgroundSecondary,
  shape: BoxShape.circle,
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ],
);
```

---

## 4. Spacing System

### Standard Spacing Values
```dart
// Spacing Constants
static const double spacing4 = 4.0;
static const double spacing8 = 8.0;
static const double spacing12 = 12.0;
static const double spacing16 = 16.0;
static const double spacing20 = 20.0;
static const double spacing24 = 24.0;
static const double spacing32 = 32.0;
static const double spacing48 = 48.0;
static const double spacing64 = 64.0;

// Layout Margins
static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
```

---

## 5. Animation System

### Standard Durations
```dart
// Animation Durations
static const Duration fastAnimation = Duration(milliseconds: 150);
static const Duration normalAnimation = Duration(milliseconds: 300);
static const Duration slowAnimation = Duration(milliseconds: 500);

// Curves
static const Curve standardCurve = Curves.easeInOut;
static const Curve bounceCurve = Curves.elasticOut;
static const Curve slideCurve = Curves.easeOutCubic;
```

### Common Animations
```dart
// Fade In Animation
static Animation<double> fadeIn(AnimationController controller) {
  return Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(parent: controller, curve: standardCurve),
  );
}

// Slide Up Animation
static Animation<Offset> slideUp(AnimationController controller) {
  return Tween<Offset>(begin: Offset(0, 1), end: Offset.zero).animate(
    CurvedAnimation(parent: controller, curve: slideCurve),
  );
}

// Scale Animation (for buttons)
static Animation<double> scaleAnimation(AnimationController controller) {
  return Tween<double>(begin: 0.8, end: 1.0).animate(
    CurvedAnimation(parent: controller, curve: bounceCurve),
  );
}
```

---

## 6. Icon System

### Standard Icon Sizes
```dart
static const double iconSmall = 16.0;
static const double iconMedium = 24.0;
static const double iconLarge = 32.0;
static const double iconXLarge = 48.0;
```

### Subject Icons
- **Math**: Icons.calculate
- **Physics**: Icons.science
- **Chemistry**: Icons.biotech
- **Biology**: Icons.eco
- **History**: Icons.history_edu
- **Geography**: Icons.public

---

## 7. Layout Patterns

### Screen Structure
```dart
// Standard Screen Layout
Scaffold(
  backgroundColor: backgroundPrimary,
  appBar: AppBar(
    backgroundColor: primaryBlue,
    foregroundColor: textOnPrimary,
    elevation: 0,
  ),
  body: SafeArea(
    child: Padding(
      padding: screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen content
        ],
      ),
    ),
  ),
)
```

### Grid Layouts
```dart
// Subject Grid (2 columns on mobile, 3+ on tablet)
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
    crossAxisSpacing: spacing16,
    mainAxisSpacing: spacing16,
    childAspectRatio: 1.2,
  ),
  // ...
)
```

---

## 8. Responsive Design

### Breakpoints
```dart
static const double mobileBreakpoint = 600;
static const double tabletBreakpoint = 900;
static const double desktopBreakpoint = 1200;
```

### Responsive Helpers
```dart
bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < mobileBreakpoint;
bool isTablet(BuildContext context) => MediaQuery.of(context).size.width < tabletBreakpoint;
bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= tabletBreakpoint;
```

---

## 9. Implementation Guidelines

### File Structure
```
lib/
├── core/
│   ├── theme/
│   │   ├── app_theme.dart          # Main theme configuration
│   │   ├── app_colors.dart         # Color definitions
│   │   ├── app_text_styles.dart    # Typography system
│   │   ├── app_decorations.dart    # Box decorations and borders
│   │   └── app_animations.dart     # Animation definitions
│   └── widgets/
│       ├── buttons/                # Reusable button components
│       ├── cards/                  # Card components
│       └── layouts/                # Layout components
```

### Usage Examples
```dart
// Using colors
Container(color: AppColors.primaryBlue)

// Using text styles
Text('Heading', style: AppTextStyles.heading2)

// Using decorations
Container(decoration: AppDecorations.standardCard)

// Using spacing
Padding(padding: EdgeInsets.all(AppSpacing.spacing16))
```

---

## 10. Next Steps

1. **Create Theme Files**: Implement the design system in Flutter theme files
2. **Build Component Library**: Create reusable widgets following the design system
3. **Update Existing Screens**: Apply the design system to all 52 screens systematically
4. **Test Consistency**: Ensure visual consistency across all screens and interactions
5. **Document Components**: Create component documentation for developers

This design system ensures consistency, accessibility, and a professional appearance across the entire LearnoSphere educational app.
