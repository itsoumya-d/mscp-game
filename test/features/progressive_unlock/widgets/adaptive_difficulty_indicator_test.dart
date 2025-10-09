import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sp/features/adaptive_difficulty/widgets/adaptive_difficulty_indicator.dart';
import 'package:sp/core/models/difficulty_level.dart';

void main() {
  group('AdaptiveDifficultyIndicator Widget Tests', () {
    testWidgets('should display when adaptive mode is enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveDifficultyIndicator(
              isAdaptive: true,
              currentDifficulty: DifficultyLevel.medium,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(AdaptiveDifficultyIndicator), findsOneWidget);
    });

    testWidgets('should handle tap events', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveDifficultyIndicator(
              isAdaptive: true,
              currentDifficulty: DifficultyLevel.medium,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AdaptiveDifficultyIndicator));
      expect(tapped, isTrue);
    });

    testWidgets('should handle null onTap gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveDifficultyIndicator(
              isAdaptive: true,
              currentDifficulty: DifficultyLevel.medium,
              onTap: null,
            ),
          ),
        ),
      );

      // Should not throw when tapped
      await tester.tap(find.byType(AdaptiveDifficultyIndicator));
      await tester.pump();
    });


















  });
}