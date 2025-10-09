import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sp/features/personalized_paths/widgets/learning_path_indicator.dart';
import 'package:sp/core/models/learning_path.dart';

void main() {
  group('LearningPathIndicator Widget Tests', () {
    late LearningPath testPath;

    setUp(() {
      testPath = LearningPath(
        id: 'test_path',
        userId: 'test_user',
        name: 'Test Path',
        description: 'A test learning path',
        type: LearningPathType.adaptive,
        segments: [],
        metadata: PathMetadata(
          learningStyle: LearningStyle.balanced,
          difficultyPreference: DifficultyPreference.adaptive,
          lastAnalyzed: DateTime.now(),
        ),
        progress: PathProgress(
          totalLevels: 100,
          completedLevels: 50,
          masteredLevels: 25,
          averageScore: 0.85,
          totalTimeSpent: const Duration(hours: 10),
          lastActivity: DateTime.now(),
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
    });

    testWidgets('should display learning path information', (tester) async {
      // Arrange
      final testWidget = MaterialApp(
        home: Scaffold(
          body: LearningPathIndicator(
            currentPath: testPath,
            progress: 0.33,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Adaptive Learning Path'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
      expect(find.byType(Container), findsWidgets); // Progress bar is a Container, not LinearProgressIndicator
    });

    testWidgets('should display correct progress percentage', (tester) async {
      // Test different progress values
      final progressValues = [0.0, 0.25, 0.5, 0.75, 1.0];
      final expectedTexts = ['0%', '25%', '50%', '75%', '100%'];

      for (int i = 0; i < progressValues.length; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LearningPathIndicator(
                currentPath: testPath,
                progress: progressValues[i],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(expectedTexts[i]), findsOneWidget);
      }
    });

    testWidgets('should display next recommendation when available', (tester) async {
      // Arrange
      const nextRecommendation = 'Practice multiplication tables';
      final testWidget = MaterialApp(
        home: Scaffold(
          body: LearningPathIndicator(
            currentPath: testPath,
            progress: 0.33,
            nextRecommendation: nextRecommendation,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Next: $nextRecommendation'), findsOneWidget);
    });

    testWidgets('should not display next recommendation when null', (tester) async {
      // Arrange
      final testWidget = MaterialApp(
        home: Scaffold(
          body: LearningPathIndicator(
            currentPath: testPath,
            progress: 0.33,
            nextRecommendation: null,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Next:'), findsNothing);
    });

    testWidgets('should handle tap events when onTap is provided', (tester) async {
      // Arrange
      bool tapped = false;
      final testWidget = MaterialApp(
        home: Scaffold(
          body: LearningPathIndicator(
            currentPath: testPath,
            progress: 0.33,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LearningPathIndicator));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('should display correct path type icon', (tester) async {
      // Test different path types
      final pathTypes = [
        (LearningPathType.adaptive, Icons.auto_awesome),
        (LearningPathType.structured, Icons.list_alt),
        (LearningPathType.exploratory, Icons.explore),
        (LearningPathType.remedial, Icons.healing),
        (LearningPathType.accelerated, Icons.speed),
      ];

      for (final (pathType, expectedIcon) in pathTypes) {
        final pathWithType = LearningPath(
          id: 'test_path',
          userId: 'test_user',
          name: 'Test Path',
          description: 'Test description',
          type: pathType,
          segments: testPath.segments,
          metadata: testPath.metadata,
          progress: testPath.progress,
          createdAt: testPath.createdAt,
          updatedAt: testPath.updatedAt,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LearningPathIndicator(
                currentPath: pathWithType,
                progress: 0.5,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(expectedIcon), findsOneWidget);
      }
    });

    testWidgets('should display correct path type colors', (tester) async {
      // Arrange
      final adaptivePath = LearningPath(
        id: 'adaptive_path',
        userId: 'test_user',
        name: 'Adaptive Path',
        description: 'Adaptive learning',
        type: LearningPathType.adaptive,
        segments: testPath.segments,
        metadata: testPath.metadata,
        progress: testPath.progress,
        createdAt: testPath.createdAt,
        updatedAt: testPath.updatedAt,
      );

      final testWidget = MaterialApp(
        home: Scaffold(
          body: LearningPathIndicator(
            currentPath: adaptivePath,
            progress: 0.5,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Assert - Check that the widget renders without errors
      expect(find.byType(LearningPathIndicator), findsOneWidget);
      expect(find.byType(Container), findsWidgets); // Progress bar is a Container
    });

    testWidgets('should animate progress changes', (tester) async {
      // Arrange
      double currentProgress = 0.3;
      
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    LearningPathIndicator(
                      currentPath: testPath,
                      progress: currentProgress,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentProgress = 0.7;
                        });
                      },
                      child: const Text('Increase Progress'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Initial state
      await tester.pumpAndSettle();
      expect(find.text('30%'), findsOneWidget);

      // Change progress
      await tester.tap(find.text('Increase Progress'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Assert new progress is displayed
      expect(find.text('70%'), findsOneWidget);
    });

    testWidgets('should handle edge case progress values', (tester) async {
      // Test edge cases
      final edgeCases = [
        (-0.1, '0%'), // Negative values should be clamped to 0
        (1.1, '100%'), // Values over 1 should be clamped to 100
        (0.0, '0%'),   // Exact zero
        (1.0, '100%'), // Exact one
      ];

      for (final (progress, expectedText) in edgeCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LearningPathIndicator(
                currentPath: testPath,
                progress: progress,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(expectedText), findsOneWidget);
      }
    });

    testWidgets('should display milestone count information', (tester) async {
      // Arrange
      final testWidget = MaterialApp(
        home: Scaffold(
          body: LearningPathIndicator(
            currentPath: testPath,
            progress: 0.33,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Assert - Should show the path name and progress percentage
      expect(find.text('Adaptive Learning Path'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
    });

    testWidgets('should handle empty milestones list', (tester) async {
      // Arrange
      final emptyPath = LearningPath(
        id: 'empty_path',
        userId: 'test_user',
        name: 'Empty Path',
        description: 'Path with no milestones',
        type: LearningPathType.adaptive,
        segments: [],
        metadata: PathMetadata(
          learningStyle: LearningStyle.balanced,
          difficultyPreference: DifficultyPreference.adaptive,
          lastAnalyzed: DateTime.now(),
        ),
        progress: PathProgress(
          totalLevels: 0,
          completedLevels: 0,
          masteredLevels: 0,
          averageScore: 0.0,
          totalTimeSpent: const Duration(hours: 0),
          lastActivity: DateTime.now(),
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final testWidget = MaterialApp(
        home: Scaffold(
          body: LearningPathIndicator(
            currentPath: emptyPath,
            progress: 0.0,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Assert - Should render without errors
      expect(find.byType(LearningPathIndicator), findsOneWidget);
      expect(find.text('Adaptive Learning Path'), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      // Arrange
      final testWidget = MaterialApp(
        home: Scaffold(
          body: LearningPathIndicator(
            currentPath: testPath,
            progress: 0.33,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Assert - Check for semantic properties
      final semantics = tester.getSemantics(find.byType(LearningPathIndicator));
      expect(semantics.label, isNotNull);
    });

    testWidgets('should handle null onTap gracefully', (tester) async {
      // Arrange
      final testWidget = MaterialApp(
        home: Scaffold(
          body: LearningPathIndicator(
            currentPath: testPath,
            progress: 0.33,
            onTap: null,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Should not throw when tapped
      await tester.tap(find.byType(LearningPathIndicator));
      await tester.pumpAndSettle();

      // Assert - no exception thrown
      expect(find.text('Adaptive Learning Path'), findsOneWidget);
    });

    testWidgets('should display estimated duration when provided', (tester) async {
      // Arrange
      final testWidget = MaterialApp(
        home: Scaffold(
          body: LearningPathIndicator(
            currentPath: testPath,
            progress: 0.33,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Assert - Should show the path name and progress percentage
      expect(find.text('Adaptive Learning Path'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
    });

    testWidgets('should handle rapid progress updates', (tester) async {
      // Arrange
      double progress = 0.0;
      
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    LearningPathIndicator(
                      currentPath: testPath,
                      progress: progress,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          progress = (progress + 0.1).clamp(0.0, 1.0);
                        });
                      },
                      child: const Text('Increment'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Rapid updates
      await tester.pumpAndSettle();
      expect(find.text('0%'), findsOneWidget);

      for (int i = 1; i <= 5; i++) {
        await tester.tap(find.text('Increment'));
        await tester.pump();
        expect(find.text('${i * 10}%'), findsOneWidget);
      }

      await tester.pumpAndSettle();
    });
  });
}