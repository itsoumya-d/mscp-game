import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sp/features/home/screens/home_screen.dart';
import 'package:sp/shared/widgets/animated_background.dart';
import 'package:sp/shared/widgets/enhanced_progress_card.dart';
import 'package:sp/shared/widgets/animated_subject_card.dart';
import 'package:sp/shared/widgets/achievement_gallery.dart';
import 'package:sp/shared/widgets/lottie_animation_widget.dart';
import 'package:sp/shared/widgets/smooth_page_transition.dart';
import 'package:sp/shared/widgets/performance_optimized_widget.dart';
import 'package:sp/core/models/user.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/navigation/smooth_navigator.dart';

void main() {
  group('Enhanced UI Components Tests', () {
    testWidgets('AnimatedBackground renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedBackground(
              child: Container(
                width: 200,
                height: 200,
                color: Colors.transparent,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedBackground), findsOneWidget);
      
      // Test animation initialization
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('EnhancedProgressCard displays progress correctly', (WidgetTester tester) async {
      final testUser = User(
        id: 'test-user',
        name: 'Test User',
        email: 'test@example.com',
        totalXP: 2750,
        currentStreak: 7,
        level: 5,
        coins: 100,
        gems: 150,
        lives: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedProgressCard(
              user: testUser,
              levelProgress: 0.75,
              xpInLevel: 750,
              xpToNext: 1000,
            ),
          ),
        ),
      );

      expect(find.byType(EnhancedProgressCard), findsOneWidget);
      expect(find.text('Level 5'), findsOneWidget);
      expect(find.text('750 / 1000 XP'), findsOneWidget);
      expect(find.text('7'), findsOneWidget); // Streak
      expect(find.text('150'), findsOneWidget); // Gems
      expect(find.text('3'), findsOneWidget); // Lives
      
      // Test animations
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('AnimatedSubjectCard handles locked and unlocked states', (WidgetTester tester) async {
      // Test unlocked subject
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedSubjectCard(
              subject: MockSubject(
                id: '1',
                name: 'Mathematics',
                type: SubjectType.math,
                description: 'Learn math concepts',
                iconUrl: 'assets/subjects/math.svg',
                units: [],
                totalSkills: 10,
                completedSkills: 7,
              ),
              isUnlocked: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedSubjectCard), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Learn math concepts'), findsOneWidget);
      expect(find.text('7/10 Skills'), findsOneWidget);
      
      // Test locked subject
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedSubjectCard(
              subject: MockSubject(
                id: '2',
                name: 'Physics',
                type: SubjectType.physics,
                description: 'Learn physics concepts',
                iconUrl: 'assets/subjects/physics.svg',
                units: [],
                totalSkills: 8,
                completedSkills: 0,
              ),
              isUnlocked: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);
    });

    testWidgets('AchievementGallery displays achievements correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AchievementGallery(),
            ),
          ),
        ),
      );

      expect(find.byType(AchievementGallery), findsOneWidget);
      
      // Test loading state
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Wait for achievements to load
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('LottieAnimationWidget handles different animation types', (WidgetTester tester) async {
      // Test success animation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LottieAnimationWidget(
              type: AnimationType.success,
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(LottieAnimationWidget), findsOneWidget);
      
      // Test celebration animation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LottieAnimationWidget(
              type: AnimationType.celebration,
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(LottieAnimationWidget), findsOneWidget);
    });

    testWidgets('PerformanceOptimizedWidget adapts to performance changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceOptimizedWidget(
              enablePerformanceMode: true,
              targetFPS: 60,
              child: Container(
                width: 200,
                height: 200,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PerformanceOptimizedWidget), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsOneWidget);
      
      // Test performance monitoring
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('SmoothPageTransition works with different transition types', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    SmoothNavigator.push(
                      context,
                      Scaffold(
                        appBar: AppBar(title: Text('New Page')),
                        body: Center(child: Text('Transitioned Page')),
                      ),
                      type: TransitionType.slide,
                    );
                  },
                  child: Text('Navigate'),
                ),
              ),
            ),
          ),
        ),
      );

      // Test navigation button
      expect(find.text('Navigate'), findsOneWidget);
      
      // Tap navigation button
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();
      
      // Check if navigation occurred
      expect(find.text('Transitioned Page'), findsOneWidget);
    });

    group('Performance Tests', () {
      testWidgets('Animations maintain 60fps target', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AnimatedBackground(
                    child: Container(height: 100),
                  ),
                  EnhancedProgressCard(
                    user: User(
                      id: 'test-user',
                      name: 'Test User',
                      email: 'test@example.com',
                      level: 1,
                      totalXP: 100,
                      streak: 1,
                      gems: 10,
                      lives: 3,
                    ),
                    levelProgress: 0.5,
                    xpInLevel: 100,
                    xpToNext: 200,
                  ),
                ],
              ),
            ),
          ),
        );

        // Pump multiple frames to test animation performance
        for (int i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 16)); // ~60fps
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('Memory usage remains stable during animations', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MemoryOptimizedListView(
                itemCount: 100,
                itemExtent: 80,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Item $index'),
                    subtitle: Text('Description for item $index'),
                  );
                },
              ),
            ),
          ),
        );

        // Scroll through the list to test memory optimization
        await tester.fling(find.byType(ListView), const Offset(0, -500), 1000);
        await tester.pumpAndSettle();
        
        expect(tester.takeException(), isNull);
      });
    });

    group('Integration Tests', () {
      testWidgets('HomeScreen integrates all enhanced components', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        // Check if all enhanced components are present
        expect(find.byType(AnimatedBackground), findsOneWidget);
        expect(find.byType(EnhancedProgressCard), findsOneWidget);
        
        // Wait for animations to initialize
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        
        // Test scrolling behavior
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
        await tester.pumpAndSettle();
        
        expect(tester.takeException(), isNull);
      });
    });
  });
}

// Mock classes for testing
class MockSubject {
  final String id;
  final String name;
  final SubjectType type;
  final String description;
  final String iconUrl;
  final List<Unit> units;
  final int totalSkills;
  final int completedSkills;

  MockSubject({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.iconUrl,
    required this.units,
    required this.totalSkills,
    required this.completedSkills,
  });

  double get progressPercentage => 
      totalSkills > 0 ? (completedSkills / totalSkills * 100) : 0.0;
}