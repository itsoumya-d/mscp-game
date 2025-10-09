import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sp/core/services/daily_content_service.dart';
import 'package:sp/core/services/progressive_difficulty_service.dart';
import 'package:sp/core/services/sound_manager_service.dart';
import 'package:sp/features/syllabus/dynamic_syllabus_service.dart';
import 'package:sp/shared/widgets/animated_background.dart';
import 'package:sp/shared/widgets/enhanced_loading_indicator.dart';

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize fade animation for logo
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start fade animation
    _fadeController.forward();

    _boot();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      // Trace boot sequence for debugging
      // ignore: avoid_print
      print('[SplashRouter] Starting boot...');

      // Firebase is already initialized in main(); load prefs next.
      // ignore: avoid_print
      print('[SplashRouter] Loading SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      final welcomeComplete = prefs.getBool('welcome_complete') ?? false;
      final onboarded = prefs.getBool('onboarding_complete_v1') ?? false;
      // ignore: avoid_print
      print('[SplashRouter] welcomeComplete=$welcomeComplete, onboarded=$onboarded, userLoggedIn=true (local mode)');

      if (!mounted) return;

      // Initialize services in the background (non-blocking)
      // These services are already initialized in main(), so this is just for additional setup
      _initializeServicesInBackground();

      // Wait a minimum time to show the splash screen (for better UX)
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // Play page transition sound
      SoundManagerService.instance.playPageTransition();

      // Show welcome screen first, then onboarding, then home
      if (!welcomeComplete) {
        // ignore: avoid_print
        print('[SplashRouter] Navigating to /welcome');
        Navigator.of(context).pushReplacementNamed('/welcome');
      } else if (!onboarded) {
        // ignore: avoid_print
        print('[SplashRouter] Navigating to /onboarding');
        Navigator.of(context).pushReplacementNamed('/onboarding');
      } else {
        // ignore: avoid_print
        print('[SplashRouter] Navigating to /home');
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[SplashRouter] Boot error: $e');
      if (!mounted) return;
      // Fallback to welcome screen so user can still proceed
      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  /// Initialize services in the background without blocking navigation
  void _initializeServicesInBackground() {
    // Run service initializations in the background
    // These are non-critical and can happen after navigation
    Future.microtask(() async {
      try {
        // ignore: avoid_print
        print('[SplashRouter] Initializing background services...');
        await DailyContentService.getInstance().generateDailyContentIfDue();
        await ProgressiveDifficultyService.getInstance().initialize();
        await DynamicSyllabusService.getInstance().generateDynamicSyllabusIfDue();
        // ignore: avoid_print
        print('[SplashRouter] Background services initialized successfully');
      } catch (e) {
        // ignore: avoid_print
        print('[SplashRouter] Background service initialization error: $e');
        // Non-critical error, app can continue without these services
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Logo/Icon with animation
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.school,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),

                // App Name
                Text(
                  'LearnoSphere',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Your Learning Journey Starts Here',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 48),

                // Enhanced Loading Indicator
                const EnhancedLoadingIndicator(
                  title: 'Loading...',
                ),
                const SizedBox(height: 16),

                Text(
                  'Loading...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
