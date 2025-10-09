import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Accessibility Service - Category E
/// Comprehensive accessibility features for inclusive design
/// 
/// Features:
/// - Screen reader optimization (E1)
/// - High contrast mode (E2)
/// - Colorblind modes (E3)
/// - Text-to-speech (E4)
/// - Dyslexia-friendly fonts (E5)

class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  // Preferences keys
  static const String _keyHighContrast = 'accessibility_high_contrast';
  static const String _keyColorblindMode = 'accessibility_colorblind_mode';
  static const String _keyDyslexiaFont = 'accessibility_dyslexia_font';
  static const String _keyTextSize = 'accessibility_text_size';
  static const String _keyLineSpacing = 'accessibility_line_spacing';
  static const String _keyReduceMotion = 'accessibility_reduce_motion';
  static const String _keyTtsEnabled = 'accessibility_tts_enabled';
  static const String _keyTtsSpeed = 'accessibility_tts_speed';

  // Current settings
  bool _highContrastEnabled = false;
  ColorblindMode _colorblindMode = ColorblindMode.none;
  bool _dyslexiaFontEnabled = false;
  double _textSizeMultiplier = 1.0;
  double _lineSpacingMultiplier = 1.0;
  bool _reduceMotionEnabled = false;
  bool _ttsEnabled = false;
  double _ttsSpeed = 1.0;

  // Getters
  bool get highContrastEnabled => _highContrastEnabled;
  ColorblindMode get colorblindMode => _colorblindMode;
  bool get dyslexiaFontEnabled => _dyslexiaFontEnabled;
  double get textSizeMultiplier => _textSizeMultiplier;
  double get lineSpacingMultiplier => _lineSpacingMultiplier;
  bool get reduceMotionEnabled => _reduceMotionEnabled;
  bool get ttsEnabled => _ttsEnabled;
  double get ttsSpeed => _ttsSpeed;

  /// Initialize accessibility service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    _highContrastEnabled = prefs.getBool(_keyHighContrast) ?? false;
    _colorblindMode = ColorblindMode.values[prefs.getInt(_keyColorblindMode) ?? 0];
    _dyslexiaFontEnabled = prefs.getBool(_keyDyslexiaFont) ?? false;
    _textSizeMultiplier = prefs.getDouble(_keyTextSize) ?? 1.0;
    _lineSpacingMultiplier = prefs.getDouble(_keyLineSpacing) ?? 1.0;
    _reduceMotionEnabled = prefs.getBool(_keyReduceMotion) ?? false;
    _ttsEnabled = prefs.getBool(_keyTtsEnabled) ?? false;
    _ttsSpeed = prefs.getDouble(_keyTtsSpeed) ?? 1.0;

    debugPrint('✅ Accessibility service initialized');
  }

  /// Enable/disable high contrast mode
  Future<void> setHighContrast(bool enabled) async {
    _highContrastEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHighContrast, enabled);
  }

  /// Set colorblind mode
  Future<void> setColorblindMode(ColorblindMode mode) async {
    _colorblindMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyColorblindMode, mode.index);
  }

  /// Enable/disable dyslexia-friendly font
  Future<void> setDyslexiaFont(bool enabled) async {
    _dyslexiaFontEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDyslexiaFont, enabled);
  }

  /// Set text size multiplier (0.8 to 2.0)
  Future<void> setTextSize(double multiplier) async {
    _textSizeMultiplier = multiplier.clamp(0.8, 2.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTextSize, _textSizeMultiplier);
  }

  /// Set line spacing multiplier (1.0 to 2.0)
  Future<void> setLineSpacing(double multiplier) async {
    _lineSpacingMultiplier = multiplier.clamp(1.0, 2.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLineSpacing, _lineSpacingMultiplier);
  }

  /// Enable/disable reduced motion
  Future<void> setReduceMotion(bool enabled) async {
    _reduceMotionEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReduceMotion, enabled);
  }

  /// Enable/disable text-to-speech
  Future<void> setTtsEnabled(bool enabled) async {
    _ttsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTtsEnabled, enabled);
  }

  /// Set TTS speed (0.5 to 2.0)
  Future<void> setTtsSpeed(double speed) async {
    _ttsSpeed = speed.clamp(0.5, 2.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTtsSpeed, _ttsSpeed);
  }

  /// Get animation duration based on reduce motion setting
  Duration getAnimationDuration(Duration defaultDuration) {
    if (_reduceMotionEnabled) {
      return Duration.zero;
    }
    return defaultDuration;
  }

  /// Announce message to screen reader
  void announce(String message, {TextDirection textDirection = TextDirection.ltr}) {
    SemanticsService.announce(message, textDirection);
  }

  /// Check if screen reader is enabled
  bool get isScreenReaderEnabled {
    return WidgetsBinding.instance.accessibilityFeatures.accessibleNavigation;
  }

  /// Get font family based on dyslexia setting
  String? get fontFamily {
    if (_dyslexiaFontEnabled) {
      return 'OpenDyslexic';  // You need to add this font to pubspec.yaml
    }
    return null;
  }

  /// Apply color adjustments for colorblind mode
  Color adjustColor(Color color) {
    if (_colorblindMode == ColorblindMode.none) {
      return color;
    }

    // Convert to HSL for easier manipulation
    final hsl = HSLColor.fromColor(color);
    
    switch (_colorblindMode) {
      case ColorblindMode.protanopia:
        // Red-blind: Shift reds to yellows/browns
        if (hsl.hue >= 0 && hsl.hue <= 60) {
          return HSLColor.fromAHSL(
            hsl.alpha,
            hsl.hue + 30,
            hsl.saturation * 0.7,
            hsl.lightness,
          ).toColor();
        }
        break;
      case ColorblindMode.deuteranopia:
        // Green-blind: Shift greens to yellows/blues
        if (hsl.hue >= 60 && hsl.hue <= 180) {
          return HSLColor.fromAHSL(
            hsl.alpha,
            hsl.hue + 30,
            hsl.saturation * 0.7,
            hsl.lightness,
          ).toColor();
        }
        break;
      case ColorblindMode.tritanopia:
        // Blue-blind: Shift blues to greens/purples
        if (hsl.hue >= 180 && hsl.hue <= 270) {
          return HSLColor.fromAHSL(
            hsl.alpha,
            hsl.hue + 30,
            hsl.saturation * 0.7,
            hsl.lightness,
          ).toColor();
        }
        break;
      case ColorblindMode.none:
        break;
    }
    
    return color;
  }

  /// Get high contrast color scheme
  ColorScheme getHighContrastColorScheme(Brightness brightness) {
    if (!_highContrastEnabled) {
      return ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      );
    }

    if (brightness == Brightness.light) {
      return const ColorScheme.light(
        primary: Colors.black,
        secondary: Colors.black,
        background: Colors.white,
        surface: Colors.white,
        error: Color(0xFFD32F2F),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Colors.black,
        onSurface: Colors.black,
        onError: Colors.white,
      );
    } else {
      return const ColorScheme.dark(
        primary: Colors.white,
        secondary: Colors.white,
        background: Colors.black,
        surface: Color(0xFF121212),
        error: Color(0xFFFF5252),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onBackground: Colors.white,
        onSurface: Colors.white,
        onError: Colors.black,
      );
    }
  }

  /// Reset all accessibility settings
  Future<void> resetAll() async {
    await setHighContrast(false);
    await setColorblindMode(ColorblindMode.none);
    await setDyslexiaFont(false);
    await setTextSize(1.0);
    await setLineSpacing(1.0);
    await setReduceMotion(false);
    await setTtsEnabled(false);
    await setTtsSpeed(1.0);
  }
}

/// Colorblind modes
enum ColorblindMode {
  none,
  protanopia,    // Red-blind
  deuteranopia,  // Green-blind
  tritanopia,    // Blue-blind
}

extension ColorblindModeExtension on ColorblindMode {
  String get displayName {
    switch (this) {
      case ColorblindMode.none:
        return 'None';
      case ColorblindMode.protanopia:
        return 'Protanopia (Red-blind)';
      case ColorblindMode.deuteranopia:
        return 'Deuteranopia (Green-blind)';
      case ColorblindMode.tritanopia:
        return 'Tritanopia (Blue-blind)';
    }
  }

  String get description {
    switch (this) {
      case ColorblindMode.none:
        return 'No color adjustments';
      case ColorblindMode.protanopia:
        return 'Difficulty distinguishing red and green';
      case ColorblindMode.deuteranopia:
        return 'Difficulty distinguishing green and red';
      case ColorblindMode.tritanopia:
        return 'Difficulty distinguishing blue and yellow';
    }
  }
}

