import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Accessibility feature types
enum AccessibilityFeature {
  screenReader,
  highContrast,
  largeText,
  reducedMotion,
  colorBlindSupport,
  keyboardNavigation,
  voiceCommands,
  hapticFeedback,
  audioDescriptions,
  slowAnimations,
}

/// Text size options
enum TextSize {
  small,
  normal,
  large,
  extraLarge,
  huge,
}

/// Color contrast themes
enum ContrastTheme {
  normal,
  high,
  extraHigh,
  blackOnWhite,
  whiteOnBlack,
  yellowOnBlack,
}

/// Color blind support types
enum ColorBlindType {
  none,
  protanopia,    // Red-blind
  deuteranopia,  // Green-blind
  tritanopia,    // Blue-blind
  achromatopsia, // Complete color blindness
}

/// Animation speed settings
enum AnimationSpeed {
  normal,
  slow,
  verySlow,
  disabled,
}

/// Accessibility preferences for the user
class AccessibilityPreferences {
  final Map<AccessibilityFeature, bool> enabledFeatures;
  final TextSize textSize;
  final ContrastTheme contrastTheme;
  final ColorBlindType colorBlindType;
  final AnimationSpeed animationSpeed;
  final double hapticIntensity; // 0.0 to 1.0
  final bool enableAudioCues;
  final bool enableVoiceAnnouncements;
  final bool enableKeyboardShortcuts;
  final bool enableFocusIndicators;
  final double uiScale; // 1.0 to 3.0

  AccessibilityPreferences({
    required this.enabledFeatures,
    this.textSize = TextSize.normal,
    this.contrastTheme = ContrastTheme.normal,
    this.colorBlindType = ColorBlindType.none,
    this.animationSpeed = AnimationSpeed.normal,
    this.hapticIntensity = 0.5,
    this.enableAudioCues = false,
    this.enableVoiceAnnouncements = false,
    this.enableKeyboardShortcuts = true,
    this.enableFocusIndicators = true,
    this.uiScale = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled_features': enabledFeatures.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'text_size': textSize.toString(),
      'contrast_theme': contrastTheme.toString(),
      'color_blind_type': colorBlindType.toString(),
      'animation_speed': animationSpeed.toString(),
      'haptic_intensity': hapticIntensity,
      'enable_audio_cues': enableAudioCues,
      'enable_voice_announcements': enableVoiceAnnouncements,
      'enable_keyboard_shortcuts': enableKeyboardShortcuts,
      'enable_focus_indicators': enableFocusIndicators,
      'ui_scale': uiScale,
    };
  }

  factory AccessibilityPreferences.fromJson(Map<String, dynamic> json) {
    final enabledFeatures = <AccessibilityFeature, bool>{};
    final featuresJson = json['enabled_features'] as Map<String, dynamic>? ?? {};
    
    for (final entry in featuresJson.entries) {
      try {
        final feature = AccessibilityFeature.values.firstWhere(
          (e) => e.toString() == entry.key,
        );
        enabledFeatures[feature] = entry.value as bool;
      } catch (e) {
        // Skip unknown features
      }
    }

    return AccessibilityPreferences(
      enabledFeatures: enabledFeatures,
      textSize: _parseEnum(json['text_size'], TextSize.values, TextSize.normal),
      contrastTheme: _parseEnum(json['contrast_theme'], ContrastTheme.values, ContrastTheme.normal),
      colorBlindType: _parseEnum(json['color_blind_type'], ColorBlindType.values, ColorBlindType.none),
      animationSpeed: _parseEnum(json['animation_speed'], AnimationSpeed.values, AnimationSpeed.normal),
      hapticIntensity: (json['haptic_intensity'] as num?)?.toDouble() ?? 0.5,
      enableAudioCues: json['enable_audio_cues'] as bool? ?? false,
      enableVoiceAnnouncements: json['enable_voice_announcements'] as bool? ?? false,
      enableKeyboardShortcuts: json['enable_keyboard_shortcuts'] as bool? ?? true,
      enableFocusIndicators: json['enable_focus_indicators'] as bool? ?? true,
      uiScale: (json['ui_scale'] as num?)?.toDouble() ?? 1.0,
    );
  }

  static T _parseEnum<T>(dynamic value, List<T> values, T defaultValue) {
    if (value == null) return defaultValue;
    try {
      return values.firstWhere((e) => e.toString() == value);
    } catch (e) {
      return defaultValue;
    }
  }

  static AccessibilityPreferences defaultPreferences() {
    return AccessibilityPreferences(
      enabledFeatures: {
        for (final feature in AccessibilityFeature.values) feature: false,
      },
    );
  }

  AccessibilityPreferences copyWith({
    Map<AccessibilityFeature, bool>? enabledFeatures,
    TextSize? textSize,
    ContrastTheme? contrastTheme,
    ColorBlindType? colorBlindType,
    AnimationSpeed? animationSpeed,
    double? hapticIntensity,
    bool? enableAudioCues,
    bool? enableVoiceAnnouncements,
    bool? enableKeyboardShortcuts,
    bool? enableFocusIndicators,
    double? uiScale,
  }) {
    return AccessibilityPreferences(
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      textSize: textSize ?? this.textSize,
      contrastTheme: contrastTheme ?? this.contrastTheme,
      colorBlindType: colorBlindType ?? this.colorBlindType,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      hapticIntensity: hapticIntensity ?? this.hapticIntensity,
      enableAudioCues: enableAudioCues ?? this.enableAudioCues,
      enableVoiceAnnouncements: enableVoiceAnnouncements ?? this.enableVoiceAnnouncements,
      enableKeyboardShortcuts: enableKeyboardShortcuts ?? this.enableKeyboardShortcuts,
      enableFocusIndicators: enableFocusIndicators ?? this.enableFocusIndicators,
      uiScale: uiScale ?? this.uiScale,
    );
  }
}

/// Accessibility announcement for screen readers
class AccessibilityAnnouncement {
  final String message;
  final bool isPolite; // true for polite, false for assertive
  final DateTime timestamp;

  AccessibilityAnnouncement({
    required this.message,
    this.isPolite = true,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Service for managing accessibility features
class AccessibilityService {
  static const String _preferencesKey = 'accessibility_preferences';
  static const String _usageStatsKey = 'accessibility_usage_stats';

  late SharedPreferences _prefs;
  AccessibilityPreferences _preferences = AccessibilityPreferences.defaultPreferences();
  final StreamController<AccessibilityAnnouncement> _announcementController = 
      StreamController<AccessibilityAnnouncement>.broadcast();
  final Map<String, int> _featureUsageStats = {};
  Timer? _statsTimer;

  /// Stream of accessibility announcements
  Stream<AccessibilityAnnouncement> get announcements => _announcementController.stream;

  /// Initialize the accessibility service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPreferences();
    await _loadUsageStats();
    _startStatsTracking();
    await _detectSystemAccessibilitySettings();
  }

  /// Load accessibility preferences
  Future<void> _loadPreferences() async {
    try {
      final prefsJson = _prefs.getString(_preferencesKey);
      if (prefsJson != null) {
        _preferences = AccessibilityPreferences.fromJson(jsonDecode(prefsJson));
      }
    } catch (e) {
      print('Error loading accessibility preferences: $e');
      _preferences = AccessibilityPreferences.defaultPreferences();
    }
  }

  /// Save accessibility preferences
  Future<void> _savePreferences() async {
    try {
      await _prefs.setString(_preferencesKey, jsonEncode(_preferences.toJson()));
    } catch (e) {
      print('Error saving accessibility preferences: $e');
    }
  }

  /// Load usage statistics
  Future<void> _loadUsageStats() async {
    try {
      final statsJson = _prefs.getString(_usageStatsKey);
      if (statsJson != null) {
        final stats = Map<String, dynamic>.from(jsonDecode(statsJson));
        _featureUsageStats.clear();
        stats.forEach((key, value) {
          _featureUsageStats[key] = value as int;
        });
      }
    } catch (e) {
      print('Error loading accessibility usage stats: $e');
    }
  }

  /// Save usage statistics
  Future<void> _saveUsageStats() async {
    try {
      await _prefs.setString(_usageStatsKey, jsonEncode(_featureUsageStats));
    } catch (e) {
      print('Error saving accessibility usage stats: $e');
    }
  }

  /// Start tracking usage statistics
  void _startStatsTracking() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _saveUsageStats(),
    );
  }

  /// Detect system accessibility settings
  Future<void> _detectSystemAccessibilitySettings() async {
    // This would integrate with platform-specific accessibility APIs
    // For now, we'll simulate detection
    
    // Mock detection of system settings
    final Map<AccessibilityFeature, bool> detectedFeatures = {};
    
    // In a real implementation, this would check:
    // - iOS: UIAccessibility APIs
    // - Android: AccessibilityManager
    // - Web: media queries and browser APIs
    
    // For demonstration, we'll assume some common settings
    detectedFeatures[AccessibilityFeature.screenReader] = false; // Would check if TalkBack/VoiceOver is enabled
    detectedFeatures[AccessibilityFeature.highContrast] = false; // Would check system contrast settings
    detectedFeatures[AccessibilityFeature.largeText] = false; // Would check system text size
    detectedFeatures[AccessibilityFeature.reducedMotion] = false; // Would check motion preferences
    
    // Update preferences with detected settings
    bool hasChanges = false;
    for (final entry in detectedFeatures.entries) {
      if (_preferences.enabledFeatures[entry.key] != entry.value) {
        _preferences.enabledFeatures[entry.key] = entry.value;
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      await _savePreferences();
      _announceSystemSettingsDetected();
    }
  }

  /// Announce that system settings were detected
  void _announceSystemSettingsDetected() {
    announce(
      'System accessibility settings detected and applied.',
      isPolite: true,
    );
  }

  /// Update accessibility preferences
  Future<void> updatePreferences(AccessibilityPreferences preferences) async {
    final oldPreferences = _preferences;
    _preferences = preferences;
    await _savePreferences();
    
    // Track feature usage
    for (final entry in preferences.enabledFeatures.entries) {
      if (entry.value && !(oldPreferences.enabledFeatures[entry.key] ?? false)) {
        _trackFeatureUsage(entry.key.toString());
      }
    }
    
    // Announce significant changes
    _announcePreferenceChanges(oldPreferences, preferences);
  }

  /// Announce preference changes
  void _announcePreferenceChanges(
    AccessibilityPreferences oldPrefs,
    AccessibilityPreferences newPrefs,
  ) {
    final changes = <String>[];
    
    // Check for enabled features
    for (final entry in newPrefs.enabledFeatures.entries) {
      final wasEnabled = oldPrefs.enabledFeatures[entry.key] ?? false;
      if (entry.value && !wasEnabled) {
        changes.add('${_getFeatureName(entry.key)} enabled');
      } else if (!entry.value && wasEnabled) {
        changes.add('${_getFeatureName(entry.key)} disabled');
      }
    }
    
    // Check for text size changes
    if (oldPrefs.textSize != newPrefs.textSize) {
      changes.add('Text size changed to ${_getTextSizeName(newPrefs.textSize)}');
    }
    
    // Check for contrast changes
    if (oldPrefs.contrastTheme != newPrefs.contrastTheme) {
      changes.add('Contrast theme changed to ${_getContrastThemeName(newPrefs.contrastTheme)}');
    }
    
    if (changes.isNotEmpty) {
      announce(
        'Accessibility settings updated: ${changes.join(', ')}',
        isPolite: true,
      );
    }
  }

  /// Get user-friendly feature name
  String _getFeatureName(AccessibilityFeature feature) {
    switch (feature) {
      case AccessibilityFeature.screenReader:
        return 'Screen reader support';
      case AccessibilityFeature.highContrast:
        return 'High contrast';
      case AccessibilityFeature.largeText:
        return 'Large text';
      case AccessibilityFeature.reducedMotion:
        return 'Reduced motion';
      case AccessibilityFeature.colorBlindSupport:
        return 'Color blind support';
      case AccessibilityFeature.keyboardNavigation:
        return 'Keyboard navigation';
      case AccessibilityFeature.voiceCommands:
        return 'Voice commands';
      case AccessibilityFeature.hapticFeedback:
        return 'Haptic feedback';
      case AccessibilityFeature.audioDescriptions:
        return 'Audio descriptions';
      case AccessibilityFeature.slowAnimations:
        return 'Slow animations';
    }
  }

  /// Get user-friendly text size name
  String _getTextSizeName(TextSize size) {
    switch (size) {
      case TextSize.small:
        return 'small';
      case TextSize.normal:
        return 'normal';
      case TextSize.large:
        return 'large';
      case TextSize.extraLarge:
        return 'extra large';
      case TextSize.huge:
        return 'huge';
    }
  }

  /// Get user-friendly contrast theme name
  String _getContrastThemeName(ContrastTheme theme) {
    switch (theme) {
      case ContrastTheme.normal:
        return 'normal';
      case ContrastTheme.high:
        return 'high contrast';
      case ContrastTheme.extraHigh:
        return 'extra high contrast';
      case ContrastTheme.blackOnWhite:
        return 'black on white';
      case ContrastTheme.whiteOnBlack:
        return 'white on black';
      case ContrastTheme.yellowOnBlack:
        return 'yellow on black';
    }
  }

  /// Track feature usage
  void _trackFeatureUsage(String feature) {
    _featureUsageStats[feature] = (_featureUsageStats[feature] ?? 0) + 1;
    _saveUsageStats();
  }

  /// Get current accessibility preferences
  AccessibilityPreferences getPreferences() {
    return _preferences;
  }

  /// Check if a specific feature is enabled
  bool isFeatureEnabled(AccessibilityFeature feature) {
    return _preferences.enabledFeatures[feature] ?? false;
  }

  /// Get text scale factor based on text size preference
  double getTextScaleFactor() {
    switch (_preferences.textSize) {
      case TextSize.small:
        return 0.8;
      case TextSize.normal:
        return 1.0;
      case TextSize.large:
        return 1.2;
      case TextSize.extraLarge:
        return 1.5;
      case TextSize.huge:
        return 2.0;
    }
  }

  /// Get UI scale factor
  double getUIScaleFactor() {
    return _preferences.uiScale.clamp(1.0, 3.0);
  }

  /// Get animation duration multiplier
  double getAnimationDurationMultiplier() {
    switch (_preferences.animationSpeed) {
      case AnimationSpeed.normal:
        return 1.0;
      case AnimationSpeed.slow:
        return 2.0;
      case AnimationSpeed.verySlow:
        return 4.0;
      case AnimationSpeed.disabled:
        return 0.0;
    }
  }

  /// Check if animations should be disabled
  bool shouldDisableAnimations() {
    return _preferences.animationSpeed == AnimationSpeed.disabled ||
           isFeatureEnabled(AccessibilityFeature.reducedMotion);
  }

  /// Get haptic feedback intensity
  double getHapticIntensity() {
    if (!isFeatureEnabled(AccessibilityFeature.hapticFeedback)) {
      return 0.0;
    }
    return _preferences.hapticIntensity.clamp(0.0, 1.0);
  }

  /// Make an accessibility announcement
  void announce(String message, {bool isPolite = true}) {
    if (isFeatureEnabled(AccessibilityFeature.screenReader) ||
        _preferences.enableVoiceAnnouncements) {
      final announcement = AccessibilityAnnouncement(
        message: message,
        isPolite: isPolite,
      );
      _announcementController.add(announcement);
      _trackFeatureUsage('announcements');
    }
  }

  /// Announce question content for screen readers
  void announceQuestion({
    required String questionText,
    required List<String> options,
    required String subject,
    required String difficulty,
  }) {
    if (!isFeatureEnabled(AccessibilityFeature.screenReader)) return;

    final announcement = StringBuffer();
    announcement.write('Question in $subject, $difficulty difficulty. ');
    announcement.write(questionText);
    announcement.write(' Options: ');
    
    for (int i = 0; i < options.length; i++) {
      announcement.write('Option ${i + 1}: ${options[i]}. ');
    }

    announce(announcement.toString(), isPolite: false);
  }

  /// Announce answer feedback
  void announceAnswerFeedback({
    required bool isCorrect,
    required String correctAnswer,
    String? explanation,
  }) {
    if (!isFeatureEnabled(AccessibilityFeature.screenReader)) return;

    String message = isCorrect ? 'Correct!' : 'Incorrect. ';
    if (!isCorrect) {
      message += 'The correct answer is: $correctAnswer. ';
    }
    if (explanation != null) {
      message += explanation;
    }

    announce(message, isPolite: false);
  }

  /// Announce progress update
  void announceProgress({
    required String subject,
    required int questionsAnswered,
    required int questionsCorrect,
    required double accuracy,
  }) {
    if (!isFeatureEnabled(AccessibilityFeature.screenReader)) return;

    final message = 'Progress update for $subject: '
        '$questionsAnswered questions answered, '
        '$questionsCorrect correct, '
        '${(accuracy * 100).round()}% accuracy.';

    announce(message, isPolite: true);
  }

  /// Announce achievement
  void announceAchievement({
    required String title,
    required String description,
  }) {
    if (!isFeatureEnabled(AccessibilityFeature.screenReader)) return;

    announce('Achievement unlocked: $title. $description', isPolite: false);
  }

  /// Get color-adjusted color for color blind support
  int adjustColorForColorBlindness(int originalColor) {
    if (_preferences.colorBlindType == ColorBlindType.none) {
      return originalColor;
    }

    // Extract RGB components
    final alpha = (originalColor >> 24) & 0xFF;
    final red = (originalColor >> 16) & 0xFF;
    final green = (originalColor >> 8) & 0xFF;
    final blue = originalColor & 0xFF;

    // Apply color blind adjustments
    int adjustedRed = red;
    int adjustedGreen = green;
    int adjustedBlue = blue;

    switch (_preferences.colorBlindType) {
      case ColorBlindType.protanopia:
        // Red-blind: adjust red channel
        adjustedRed = ((green * 0.567) + (blue * 0.433)).round();
        break;
      case ColorBlindType.deuteranopia:
        // Green-blind: adjust green channel
        adjustedGreen = ((red * 0.625) + (blue * 0.375)).round();
        break;
      case ColorBlindType.tritanopia:
        // Blue-blind: adjust blue channel
        adjustedBlue = ((red * 0.95) + (green * 0.05)).round();
        break;
      case ColorBlindType.achromatopsia:
        // Complete color blindness: convert to grayscale
        final gray = ((red * 0.299) + (green * 0.587) + (blue * 0.114)).round();
        adjustedRed = adjustedGreen = adjustedBlue = gray;
        break;
      case ColorBlindType.none:
        break;
    }

    // Clamp values and reconstruct color
    adjustedRed = adjustedRed.clamp(0, 255);
    adjustedGreen = adjustedGreen.clamp(0, 255);
    adjustedBlue = adjustedBlue.clamp(0, 255);

    return (alpha << 24) | (adjustedRed << 16) | (adjustedGreen << 8) | adjustedBlue;
  }

  /// Get contrast-adjusted colors based on theme
  Map<String, int> getContrastAdjustedColors() {
    switch (_preferences.contrastTheme) {
      case ContrastTheme.normal:
        return {
          'background': 0xFFFFFFFF,
          'surface': 0xFFF5F5F5,
          'primary': 0xFF2196F3,
          'text': 0xFF000000,
          'textSecondary': 0xFF666666,
        };
      case ContrastTheme.high:
        return {
          'background': 0xFFFFFFFF,
          'surface': 0xFFE0E0E0,
          'primary': 0xFF0D47A1,
          'text': 0xFF000000,
          'textSecondary': 0xFF333333,
        };
      case ContrastTheme.extraHigh:
        return {
          'background': 0xFFFFFFFF,
          'surface': 0xFFCCCCCC,
          'primary': 0xFF000080,
          'text': 0xFF000000,
          'textSecondary': 0xFF000000,
        };
      case ContrastTheme.blackOnWhite:
        return {
          'background': 0xFFFFFFFF,
          'surface': 0xFFFFFFFF,
          'primary': 0xFF000000,
          'text': 0xFF000000,
          'textSecondary': 0xFF000000,
        };
      case ContrastTheme.whiteOnBlack:
        return {
          'background': 0xFF000000,
          'surface': 0xFF000000,
          'primary': 0xFFFFFFFF,
          'text': 0xFFFFFFFF,
          'textSecondary': 0xFFFFFFFF,
        };
      case ContrastTheme.yellowOnBlack:
        return {
          'background': 0xFF000000,
          'surface': 0xFF000000,
          'primary': 0xFFFFFF00,
          'text': 0xFFFFFF00,
          'textSecondary': 0xFFFFFF00,
        };
    }
  }

  /// Get usage statistics
  Map<String, int> getUsageStatistics() {
    return Map<String, int>.from(_featureUsageStats);
  }

  /// Clear all accessibility data
  Future<void> clearAllData() async {
    _featureUsageStats.clear();
    _preferences = AccessibilityPreferences.defaultPreferences();
    
    await _prefs.remove(_preferencesKey);
    await _prefs.remove(_usageStatsKey);
  }

  /// Export accessibility data
  Map<String, dynamic> exportData() {
    return {
      'preferences': _preferences.toJson(),
      'usage_statistics': Map<String, int>.from(_featureUsageStats),
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Dispose of resources
  void dispose() {
    _statsTimer?.cancel();
    _announcementController.close();
  }
}