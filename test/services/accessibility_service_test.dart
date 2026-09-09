import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp/core/services/accessibility_service.dart';

void main() {
  group('AccessibilityService Tests', () {
    late AccessibilityService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = AccessibilityService();
      await service.initialize();
    });

    tearDown(() {
      service.dispose();
    });

    group('Initialization', () {
      test('should initialize with default preferences', () {
        final preferences = service.getPreferences();
        expect(preferences.textSize, equals(TextSize.normal));
        expect(preferences.contrastTheme, equals(ContrastTheme.normal));
        expect(preferences.colorBlindType, equals(ColorBlindType.none));
        expect(preferences.animationSpeed, equals(AnimationSpeed.normal));
        expect(preferences.hapticIntensity, equals(0.5));
        expect(preferences.enableAudioCues, isFalse);
        expect(preferences.enableVoiceAnnouncements, isFalse);
        expect(preferences.enableKeyboardShortcuts, isTrue);
        expect(preferences.enableFocusIndicators, isTrue);
        expect(preferences.uiScale, equals(1.0));
      });

      test('should load saved preferences', () async {
        // Set up mock preferences
        final mockPrefs = {
          'accessibility_preferences': '{"enabled_features":{"AccessibilityFeature.screenReader":true,"AccessibilityFeature.highContrast":true},"text_size":"TextSize.large","contrast_theme":"ContrastTheme.high","color_blind_type":"ColorBlindType.protanopia","animation_speed":"AnimationSpeed.slow","haptic_intensity":0.8,"enable_audio_cues":true,"enable_voice_announcements":true,"enable_keyboard_shortcuts":true,"enable_focus_indicators":true,"ui_scale":1.5}'
        };
        SharedPreferences.setMockInitialValues(mockPrefs);

        final newService = AccessibilityService();
        await newService.initialize();

        final preferences = newService.getPreferences();
        expect(preferences.textSize, equals(TextSize.large));
        expect(preferences.contrastTheme, equals(ContrastTheme.high));
        expect(preferences.colorBlindType, equals(ColorBlindType.protanopia));
        expect(preferences.animationSpeed, equals(AnimationSpeed.slow));
        expect(preferences.hapticIntensity, equals(0.8));
        expect(preferences.enableAudioCues, isTrue);
        expect(preferences.enableVoiceAnnouncements, isTrue);
        expect(preferences.uiScale, equals(1.5));

        newService.dispose();
      });

      test('should handle corrupted preferences gracefully', () async {
        final mockPrefs = {
          'accessibility_preferences': 'invalid_json'
        };
        SharedPreferences.setMockInitialValues(mockPrefs);

        final newService = AccessibilityService();
        await newService.initialize();

        final preferences = newService.getPreferences();
        expect(preferences.textSize, equals(TextSize.normal));
        expect(preferences.contrastTheme, equals(ContrastTheme.normal));

        newService.dispose();
      });
    });

    group('Preference Management', () {
      test('should update and save preferences', () async {
        final newPreferences = AccessibilityPreferences(
          enabledFeatures: {
            AccessibilityFeature.screenReader: true,
            AccessibilityFeature.largeText: true,
          },
          textSize: TextSize.extraLarge,
          contrastTheme: ContrastTheme.high,
          colorBlindType: ColorBlindType.deuteranopia,
          animationSpeed: AnimationSpeed.slow,
          hapticIntensity: 0.9,
          enableAudioCues: true,
          enableVoiceAnnouncements: true,
          uiScale: 2.0,
        );

        await service.updatePreferences(newPreferences);

        final savedPreferences = service.getPreferences();
        expect(savedPreferences.enabledFeatures[AccessibilityFeature.screenReader], isTrue);
        expect(savedPreferences.enabledFeatures[AccessibilityFeature.largeText], isTrue);
        expect(savedPreferences.textSize, equals(TextSize.extraLarge));
        expect(savedPreferences.contrastTheme, equals(ContrastTheme.high));
        expect(savedPreferences.colorBlindType, equals(ColorBlindType.deuteranopia));
        expect(savedPreferences.animationSpeed, equals(AnimationSpeed.slow));
        expect(savedPreferences.hapticIntensity, equals(0.9));
        expect(savedPreferences.enableAudioCues, isTrue);
        expect(savedPreferences.enableVoiceAnnouncements, isTrue);
        expect(savedPreferences.uiScale, equals(2.0));
      });

      test('should check if specific features are enabled', () async {
        final preferences = AccessibilityPreferences(
          enabledFeatures: {
            AccessibilityFeature.screenReader: true,
            AccessibilityFeature.highContrast: false,
            AccessibilityFeature.largeText: true,
          },
        );

        await service.updatePreferences(preferences);

        expect(service.isFeatureEnabled(AccessibilityFeature.screenReader), isTrue);
        expect(service.isFeatureEnabled(AccessibilityFeature.highContrast), isFalse);
        expect(service.isFeatureEnabled(AccessibilityFeature.largeText), isTrue);
        expect(service.isFeatureEnabled(AccessibilityFeature.voiceCommands), isFalse);
      });
    });

    group('Text and UI Scaling', () {
      test('should return correct text scale factors', () async {
        // Test small text
        await service.updatePreferences(
          service.getPreferences().copyWith(textSize: TextSize.small),
        );
        expect(service.getTextScaleFactor(), equals(0.8));

        // Test normal text
        await service.updatePreferences(
          service.getPreferences().copyWith(textSize: TextSize.normal),
        );
        expect(service.getTextScaleFactor(), equals(1.0));

        // Test large text
        await service.updatePreferences(
          service.getPreferences().copyWith(textSize: TextSize.large),
        );
        expect(service.getTextScaleFactor(), equals(1.2));

        // Test extra large text
        await service.updatePreferences(
          service.getPreferences().copyWith(textSize: TextSize.extraLarge),
        );
        expect(service.getTextScaleFactor(), equals(1.5));

        // Test huge text
        await service.updatePreferences(
          service.getPreferences().copyWith(textSize: TextSize.huge),
        );
        expect(service.getTextScaleFactor(), equals(2.0));
      });

      test('should return correct UI scale factor', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(uiScale: 1.5),
        );
        expect(service.getUIScaleFactor(), equals(1.5));

        // Test clamping
        await service.updatePreferences(
          service.getPreferences().copyWith(uiScale: 5.0),
        );
        expect(service.getUIScaleFactor(), equals(3.0));

        await service.updatePreferences(
          service.getPreferences().copyWith(uiScale: 0.5),
        );
        expect(service.getUIScaleFactor(), equals(1.0));
      });
    });

    group('Animation Control', () {
      test('should return correct animation duration multipliers', () async {
        // Test normal speed
        await service.updatePreferences(
          service.getPreferences().copyWith(animationSpeed: AnimationSpeed.normal),
        );
        expect(service.getAnimationDurationMultiplier(), equals(1.0));

        // Test slow speed
        await service.updatePreferences(
          service.getPreferences().copyWith(animationSpeed: AnimationSpeed.slow),
        );
        expect(service.getAnimationDurationMultiplier(), equals(2.0));

        // Test very slow speed
        await service.updatePreferences(
          service.getPreferences().copyWith(animationSpeed: AnimationSpeed.verySlow),
        );
        expect(service.getAnimationDurationMultiplier(), equals(4.0));

        // Test disabled animations
        await service.updatePreferences(
          service.getPreferences().copyWith(animationSpeed: AnimationSpeed.disabled),
        );
        expect(service.getAnimationDurationMultiplier(), equals(0.0));
      });

      test('should correctly determine if animations should be disabled', () async {
        // Test disabled animation speed
        await service.updatePreferences(
          service.getPreferences().copyWith(animationSpeed: AnimationSpeed.disabled),
        );
        expect(service.shouldDisableAnimations(), isTrue);

        // Test reduced motion feature
        await service.updatePreferences(
          service.getPreferences().copyWith(
            animationSpeed: AnimationSpeed.normal,
            enabledFeatures: {AccessibilityFeature.reducedMotion: true},
          ),
        );
        expect(service.shouldDisableAnimations(), isTrue);

        // Test normal animations
        await service.updatePreferences(
          service.getPreferences().copyWith(
            animationSpeed: AnimationSpeed.normal,
            enabledFeatures: {AccessibilityFeature.reducedMotion: false},
          ),
        );
        expect(service.shouldDisableAnimations(), isFalse);
      });
    });

    group('Haptic Feedback', () {
      test('should return correct haptic intensity', () async {
        // Test with haptic feedback enabled
        await service.updatePreferences(
          service.getPreferences().copyWith(
            enabledFeatures: {AccessibilityFeature.hapticFeedback: true},
            hapticIntensity: 0.7,
          ),
        );
        expect(service.getHapticIntensity(), equals(0.7));

        // Test with haptic feedback disabled
        await service.updatePreferences(
          service.getPreferences().copyWith(
            enabledFeatures: {AccessibilityFeature.hapticFeedback: false},
            hapticIntensity: 0.7,
          ),
        );
        expect(service.getHapticIntensity(), equals(0.0));

        // Test clamping
        await service.updatePreferences(
          service.getPreferences().copyWith(
            enabledFeatures: {AccessibilityFeature.hapticFeedback: true},
            hapticIntensity: 1.5,
          ),
        );
        expect(service.getHapticIntensity(), equals(1.0));

        await service.updatePreferences(
          service.getPreferences().copyWith(
            enabledFeatures: {AccessibilityFeature.hapticFeedback: true},
            hapticIntensity: -0.5,
          ),
        );
        expect(service.getHapticIntensity(), equals(0.0));
      });
    });

    group('Announcements', () {
      test('should make announcements when screen reader is enabled', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(
            enabledFeatures: {AccessibilityFeature.screenReader: true},
          ),
        );

        final announcements = <AccessibilityAnnouncement>[];
        service.announcements.listen((announcement) {
          announcements.add(announcement);
        });

        service.announce('Test announcement');
        await Future.delayed(const Duration(milliseconds: 10));

        expect(announcements.length, equals(1));
        expect(announcements.first.message, equals('Test announcement'));
        expect(announcements.first.isPolite, isTrue);
      });

      test('should make announcements when voice announcements are enabled', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(
            enabledFeatures: {AccessibilityFeature.screenReader: false},
            enableVoiceAnnouncements: true,
          ),
        );

        final announcements = <AccessibilityAnnouncement>[];
        service.announcements.listen((announcement) {
          announcements.add(announcement);
        });

        service.announce('Test announcement', isPolite: false);
        await Future.delayed(const Duration(milliseconds: 10));

        expect(announcements.length, equals(1));
        expect(announcements.first.message, equals('Test announcement'));
        expect(announcements.first.isPolite, isFalse);
      });

      test('should not make announcements when disabled', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(
            enabledFeatures: {AccessibilityFeature.screenReader: false},
            enableVoiceAnnouncements: false,
          ),
        );

        final announcements = <AccessibilityAnnouncement>[];
        service.announcements.listen((announcement) {
          announcements.add(announcement);
        });

        service.announce('Test announcement');
        await Future.delayed(const Duration(milliseconds: 10));

        expect(announcements.length, equals(0));
      });

      test('should announce question content', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(
            enabledFeatures: {AccessibilityFeature.screenReader: true},
          ),
        );

        final announcements = <AccessibilityAnnouncement>[];
        service.announcements.listen((announcement) {
          announcements.add(announcement);
        });

        service.announceQuestion(
          questionText: 'What is 2 + 2?',
          options: ['3', '4', '5', '6'],
          subject: 'Mathematics',
          difficulty: 'Easy',
        );

        await Future.delayed(const Duration(milliseconds: 10));

        expect(announcements.length, equals(1));
        expect(announcements.first.message, contains('Question in Mathematics, Easy difficulty'));
        expect(announcements.first.message, contains('What is 2 + 2?'));
        expect(announcements.first.message, contains('Option 1: 3'));
        expect(announcements.first.message, contains('Option 4: 6'));
        expect(announcements.first.isPolite, isFalse);
      });

      test('should announce answer feedback', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(
            enabledFeatures: {AccessibilityFeature.screenReader: true},
          ),
        );

        final announcements = <AccessibilityAnnouncement>[];
        service.announcements.listen((announcement) {
          announcements.add(announcement);
        });

        // Test correct answer
        service.announceAnswerFeedback(
          isCorrect: true,
          correctAnswer: '4',
          explanation: 'Two plus two equals four.',
        );

        await Future.delayed(const Duration(milliseconds: 10));

        expect(announcements.length, equals(1));
        expect(announcements.first.message, contains('Correct!'));
        expect(announcements.first.message, contains('Two plus two equals four.'));

        announcements.clear();

        // Test incorrect answer
        service.announceAnswerFeedback(
          isCorrect: false,
          correctAnswer: '4',
          explanation: 'Remember basic addition.',
        );

        await Future.delayed(const Duration(milliseconds: 10));

        expect(announcements.length, equals(1));
        expect(announcements.first.message, contains('Incorrect'));
        expect(announcements.first.message, contains('The correct answer is: 4'));
        expect(announcements.first.message, contains('Remember basic addition.'));
      });

      test('should announce progress updates', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(
            enabledFeatures: {AccessibilityFeature.screenReader: true},
          ),
        );

        final announcements = <AccessibilityAnnouncement>[];
        service.announcements.listen((announcement) {
          announcements.add(announcement);
        });

        service.announceProgress(
          subject: 'Mathematics',
          questionsAnswered: 10,
          questionsCorrect: 8,
          accuracy: 0.8,
        );

        await Future.delayed(const Duration(milliseconds: 10));

        expect(announcements.length, equals(1));
        expect(announcements.first.message, contains('Progress update for Mathematics'));
        expect(announcements.first.message, contains('10 questions answered'));
        expect(announcements.first.message, contains('8 correct'));
        expect(announcements.first.message, contains('80% accuracy'));
        expect(announcements.first.isPolite, isTrue);
      });

      test('should announce achievements', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(
            enabledFeatures: {AccessibilityFeature.screenReader: true},
          ),
        );

        final announcements = <AccessibilityAnnouncement>[];
        service.announcements.listen((announcement) {
          announcements.add(announcement);
        });

        service.announceAchievement(
          title: 'Math Master',
          description: 'Completed 100 math questions with 90% accuracy.',
        );

        await Future.delayed(const Duration(milliseconds: 10));

        expect(announcements.length, equals(1));
        expect(announcements.first.message, contains('Achievement unlocked: Math Master'));
        expect(announcements.first.message, contains('Completed 100 math questions'));
        expect(announcements.first.isPolite, isFalse);
      });
    });

    group('Color Adjustments', () {
      test('should adjust colors for protanopia', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(colorBlindType: ColorBlindType.protanopia),
        );

        const originalColor = 0xFFFF0000; // Red
        final adjustedColor = service.adjustColorForColorBlindness(originalColor);
        
        // Should have modified the red channel
        expect(adjustedColor, isNot(equals(originalColor)));
        
        // Alpha should remain unchanged
        expect((adjustedColor >> 24) & 0xFF, equals(0xFF));
      });

      test('should adjust colors for deuteranopia', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(colorBlindType: ColorBlindType.deuteranopia),
        );

        const originalColor = 0xFF00FF00; // Green
        final adjustedColor = service.adjustColorForColorBlindness(originalColor);
        
        expect(adjustedColor, isNot(equals(originalColor)));
        expect((adjustedColor >> 24) & 0xFF, equals(0xFF));
      });

      test('should adjust colors for tritanopia', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(colorBlindType: ColorBlindType.tritanopia),
        );

        const originalColor = 0xFF0000FF; // Blue
        final adjustedColor = service.adjustColorForColorBlindness(originalColor);
        
        expect(adjustedColor, isNot(equals(originalColor)));
        expect((adjustedColor >> 24) & 0xFF, equals(0xFF));
      });

      test('should convert to grayscale for achromatopsia', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(colorBlindType: ColorBlindType.achromatopsia),
        );

        const originalColor = 0xFFFF0000; // Red
        final adjustedColor = service.adjustColorForColorBlindness(originalColor);
        
        // All RGB channels should be equal (grayscale)
        final red = (adjustedColor >> 16) & 0xFF;
        final green = (adjustedColor >> 8) & 0xFF;
        final blue = adjustedColor & 0xFF;
        
        expect(red, equals(green));
        expect(green, equals(blue));
        expect((adjustedColor >> 24) & 0xFF, equals(0xFF));
      });

      test('should not adjust colors when no color blindness', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(colorBlindType: ColorBlindType.none),
        );

        const originalColor = 0xFFFF0000;
        final adjustedColor = service.adjustColorForColorBlindness(originalColor);
        
        expect(adjustedColor, equals(originalColor));
      });
    });

    group('Contrast Themes', () {
      test('should return correct colors for normal contrast', () {
        final colors = service.getContrastAdjustedColors();
        
        expect(colors['background'], equals(0xFFFFFFFF));
        expect(colors['text'], equals(0xFF000000));
        expect(colors, containsPair('primary', anything));
        expect(colors, containsPair('surface', anything));
        expect(colors, containsPair('textSecondary', anything));
      });

      test('should return high contrast colors', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(contrastTheme: ContrastTheme.high),
        );

        final colors = service.getContrastAdjustedColors();
        
        expect(colors['background'], equals(0xFFFFFFFF));
        expect(colors['text'], equals(0xFF000000));
        // Primary should be darker for higher contrast
        expect(colors['primary'], equals(0xFF0D47A1));
      });

      test('should return white on black colors', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(contrastTheme: ContrastTheme.whiteOnBlack),
        );

        final colors = service.getContrastAdjustedColors();
        
        expect(colors['background'], equals(0xFF000000));
        expect(colors['text'], equals(0xFFFFFFFF));
        expect(colors['primary'], equals(0xFFFFFFFF));
      });

      test('should return yellow on black colors', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(contrastTheme: ContrastTheme.yellowOnBlack),
        );

        final colors = service.getContrastAdjustedColors();
        
        expect(colors['background'], equals(0xFF000000));
        expect(colors['text'], equals(0xFFFFFF00));
        expect(colors['primary'], equals(0xFFFFFF00));
      });
    });

    group('Usage Statistics', () {
      test('should track feature usage', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(
            enabledFeatures: {AccessibilityFeature.screenReader: true},
          ),
        );

        // Make some announcements to trigger usage tracking
        final before = service.getUsageStatistics()['announcements'] ?? 0;
        service.announce('Test 1');
        service.announce('Test 2');
        service.announce('Test 3');

        await Future.delayed(const Duration(milliseconds: 50));

        final stats = service.getUsageStatistics();
        expect((stats['announcements'] ?? 0) - before, equals(3));
      });

      test('should persist usage statistics', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(
            enabledFeatures: {AccessibilityFeature.screenReader: true},
          ),
        );

        service.announce('Test');
        await Future.delayed(const Duration(milliseconds: 50));

        final expected = service.getUsageStatistics()['announcements'];
        expect(expected, isNotNull);

        // Create new service instance
        final newService = AccessibilityService();
        await newService.initialize();

        final stats = newService.getUsageStatistics();
        expect(stats['announcements'], equals(expected));

        newService.dispose();
      });
    });

    group('Data Management', () {
      test('should clear all data', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(
            textSize: TextSize.large,
            enabledFeatures: {AccessibilityFeature.screenReader: true},
          ),
        );

        service.announce('Test');
        await Future.delayed(const Duration(milliseconds: 50));

        await service.clearAllData();

        final preferences = service.getPreferences();
        expect(preferences.textSize, equals(TextSize.normal));
        expect(preferences.enabledFeatures[AccessibilityFeature.screenReader], isFalse);

        final stats = service.getUsageStatistics();
        expect(stats.isEmpty, isTrue);
      });

      test('should export data', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(
            textSize: TextSize.large,
            enabledFeatures: {AccessibilityFeature.screenReader: true},
          ),
        );

        service.announce('Test');
        await Future.delayed(const Duration(milliseconds: 50));

        final exportedData = service.exportData();

        expect(exportedData, containsPair('preferences', anything));
        expect(exportedData, containsPair('usage_statistics', anything));
        expect(exportedData, containsPair('export_timestamp', anything));

        final preferences = exportedData['preferences'] as Map<String, dynamic>;
        expect(preferences['text_size'], equals('TextSize.large'));

        final stats = exportedData['usage_statistics'] as Map<String, int>;
        expect(stats['announcements'], equals(service.getUsageStatistics()['announcements']));
      });
    });

    group('Edge Cases', () {
      test('should handle invalid enum values gracefully', () async {
        final mockPrefs = {
          'accessibility_preferences': '{"text_size":"InvalidTextSize","contrast_theme":"InvalidTheme","enabled_features":{}}'
        };
        SharedPreferences.setMockInitialValues(mockPrefs);

        final newService = AccessibilityService();
        await newService.initialize();

        final preferences = newService.getPreferences();
        expect(preferences.textSize, equals(TextSize.normal));
        expect(preferences.contrastTheme, equals(ContrastTheme.normal));

        newService.dispose();
      });

      test('should handle missing preference keys', () async {
        final mockPrefs = {
          'accessibility_preferences': '{"enabled_features":{}}'
        };
        SharedPreferences.setMockInitialValues(mockPrefs);

        final newService = AccessibilityService();
        await newService.initialize();

        final preferences = newService.getPreferences();
        expect(preferences.textSize, equals(TextSize.normal));
        expect(preferences.hapticIntensity, equals(0.5));
        expect(preferences.uiScale, equals(1.0));

        newService.dispose();
      });

      test('should handle extreme color values', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(colorBlindType: ColorBlindType.protanopia),
        );

        // Test with extreme values
        const whiteColor = 0xFFFFFFFF;
        const blackColor = 0xFF000000;
        
        final adjustedWhite = service.adjustColorForColorBlindness(whiteColor);
        final adjustedBlack = service.adjustColorForColorBlindness(blackColor);
        
        // Should still be valid colors
        expect((adjustedWhite >> 24) & 0xFF, equals(0xFF));
        expect((adjustedBlack >> 24) & 0xFF, equals(0xFF));
        
        // RGB values should be within valid range
        for (final color in [adjustedWhite, adjustedBlack]) {
          final red = (color >> 16) & 0xFF;
          final green = (color >> 8) & 0xFF;
          final blue = color & 0xFF;
          
          expect(red, inInclusiveRange(0, 255));
          expect(green, inInclusiveRange(0, 255));
          expect(blue, inInclusiveRange(0, 255));
        }
      });
    });

    group('Performance', () {
      test('should handle rapid preference updates efficiently', () async {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 100; i++) {
          await service.updatePreferences(
            service.getPreferences().copyWith(
              textSize: i % 2 == 0 ? TextSize.large : TextSize.normal,
            ),
          );
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('should handle many announcements efficiently', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(
            enabledFeatures: {AccessibilityFeature.screenReader: true},
          ),
        );

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          service.announce('Test announcement $i');
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('should handle color adjustments efficiently', () async {
        await service.updatePreferences(
          service.getPreferences().copyWith(colorBlindType: ColorBlindType.protanopia),
        );

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 10000; i++) {
          service.adjustColorForColorBlindness(0xFF000000 + i);
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}