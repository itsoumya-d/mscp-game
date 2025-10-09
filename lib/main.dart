import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sp/theme.dart';
import 'package:sp/features/onboarding/onboarding_screen.dart';
import 'package:sp/features/auth/login_screen.dart';
import 'package:sp/features/splash/splash_router.dart';
import 'package:sp/features/home/home_screen.dart';
import 'package:sp/features/home/main_navigation_screen.dart';
import 'package:sp/features/welcome/welcome_screen.dart';
import 'package:sp/core/services/level_preloader_service.dart';
import 'package:sp/core/services/sound_manager_service.dart';
import 'package:sp/core/services/content_preloader_service.dart';
import 'package:sp/core/services/enhanced_firebase_sync.dart';
import 'package:sp/core/services/fallback_content_preloader.dart';
import 'package:sp/core/services/smart_cache_service.dart';
// Performance & Polish Services
import 'package:sp/core/services/performance/performance_optimization_service.dart';
import 'package:sp/core/services/offline/offline_mode_service.dart';
import 'package:sp/core/services/error_tracking_service.dart';
// Accessibility Services
import 'package:sp/core/services/accessibility/accessibility_service.dart';
import 'package:sp/core/services/accessibility/text_to_speech_service.dart';
// Feature Screens
import 'package:sp/features/analytics/learning_analytics_dashboard.dart';
import 'package:sp/features/analytics/progress_reports_screen.dart';
import 'package:sp/features/analytics/learning_insights_screen.dart';
import 'package:sp/features/analytics/benchmarking_screen.dart';
import 'package:sp/features/analytics/parent_teacher_portal_screen.dart';
// Removed missing learning feature imports
import 'package:sp/features/content/learning_hub_screen.dart';
import 'package:sp/features/learning/spaced_repetition_review_screen.dart';
import 'package:sp/features/learning/learning_path_screen.dart';
import 'package:sp/features/social/social_hub_screen.dart';
import 'package:sp/features/social/leaderboard_screen.dart';
import 'package:sp/features/social/friends_screen.dart';
import 'package:sp/features/social/challenges_screen.dart';
import 'package:sp/debug_unlock_screen.dart';
import 'firebase_options.dart';

void main() async {
  debugPrint('[main] ========== APP STARTING ==========');
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('[main] Initializing Firebase...');
  // Initialize Firebase (required before app starts)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('[main] Firebase initialized');

  // Initialize critical services (blocking - must complete before app starts)
  debugPrint('[main] Initializing critical services...');

  // 1. Performance Optimization (must be first)
  await PerformanceOptimizationService().initialize();
  debugPrint('[main] ✅ Performance optimization initialized');

  // 2. Error Tracking (catch errors early)
  await ErrorTrackingService().initialize();
  debugPrint('[main] ✅ Error tracking initialized');

  // 3. Offline Mode (for offline-first architecture)
  await OfflineModeService().initialize();
  debugPrint('[main] ✅ Offline mode initialized');

  // 4. Accessibility Services
  await AccessibilityService().initialize();
  await TextToSpeechService().initialize();
  debugPrint('[main] ✅ Accessibility services initialized');

  // 5. Sound Manager
  await SoundManagerService.instance.initialize();
  debugPrint('[main] ✅ Sound manager initialized');

  // Initialize other services in the background (non-blocking)
  debugPrint('[main] Starting background service initialization...');
  _initializeServicesInBackground();

  debugPrint('[main] Running app...');
  runApp(const ProviderScope(child: LearnoSphereApp()));
  debugPrint('[main] App started!');
}

/// Initialize non-critical services in the background without blocking app startup
void _initializeServicesInBackground() {
  Future.microtask(() async {
    try {
      debugPrint('[main] Initializing background services...');

      // PRIORITY 1: Initialize fallback content preloader FIRST for instant content availability
      // This provides immediate access to hardcoded questions without API calls
      debugPrint('[main] Initializing fallback content preloader...');
      final fallbackPreloader = FallbackContentPreloader.getInstance();
      await fallbackPreloader.initialize();

      // Log cache statistics
      final stats = fallbackPreloader.getCacheStats();
      debugPrint('[main] Fallback content preloader initialized: ${stats['total_sessions']} sessions, ${stats['total_questions']} questions');

      // PRIORITY 2: Initialize level preloader service for background caching
      // This will attempt API calls but won't block since fallback is already available
      final preloaderService = LevelPreloaderService.getInstance();
      await preloaderService.initialize();

      // PRIORITY 3: Initialize smart cache service for LRU caching
      final smartCache = SmartCacheService.getInstance();
      await smartCache.initialize();
      debugPrint('[main] Smart cache service initialized');

      // PRIORITY 4: Initialize content preloader service for zero loading times
      await ContentPreloaderService.instance.initialize();

      // TEMPORARILY DISABLED: Background content workers are causing main thread blocking
      // await BackgroundWorkerManager.instance.initialize();

      // PRIORITY 5: Initialize enhanced Firebase sync
      await EnhancedFirebaseSync.instance.initialize();

      debugPrint('[main] Background services initialized successfully');
    } catch (e) {
      debugPrint('[main] Background service initialization error: $e');
    }
  });
}

class LearnoSphereApp extends StatelessWidget {
  const LearnoSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LearnoSphere',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashRouter(),
      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/main': (_) => const MainNavigationScreen(),
        // Analytics Routes
        '/analytics': (_) => const LearningAnalyticsDashboard(userId: 'current_user'),
        '/analytics/reports': (_) => const ProgressReportsScreen(userId: 'current_user'),
        '/analytics/insights': (_) => const LearningInsightsScreen(userId: 'current_user'),
        '/analytics/benchmarking': (_) => const BenchmarkingScreen(userId: 'current_user'),
        '/analytics/parent-portal': (_) => const ParentTeacherPortalScreen(studentId: 'current_user'),
        // Learning Routes
        '/learning/spaced-repetition': (_) => SpacedRepetitionReviewScreen(userId: 'current_user'),
         '/learning/path': (_) => LearningPathScreen(userId: 'current_user', subject: 'Math'),
        '/learning-hub': (_) => const LearningHubScreen(),
        // Social Routes
        '/social-hub': (_) => const SocialHubScreen(),
        '/social/leaderboard': (_) => const LeaderboardScreen(),
        '/social/friends': (_) => const FriendsScreen(),
        '/social/challenges': (_) => const ChallengesScreen(),
        // Debug Routes
        '/debug/unlock': (_) => const DebugUnlockScreen(),
      },
    );
  }
}
