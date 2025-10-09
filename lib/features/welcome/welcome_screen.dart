import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sp/shared/widgets/animated_background.dart';
import 'package:sp/shared/widgets/interactive_button.dart';
import 'package:sp/core/services/sound_manager_service.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _page = 0;
  bool _isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _skip() async {
    SoundManagerService.instance.playButtonClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_complete', true);
    if (!mounted) return;
    SoundManagerService.instance.playPageTransition();
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implement Google Sign-In
      // For now, just simulate the process
      await Future.delayed(const Duration(seconds: 2));
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('welcome_complete', true);
      await prefs.setBool('user_logged_in', true);
      
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InteractiveButton(
                text: 'Skip',
                onPressed: _skip,
                style: InteractiveButtonStyle.ghost,
                enableSoundEffects: true,
                enableHapticFeedback: true,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (i) {
                      setState(() => _page = i);
                      SoundManagerService.instance.playPageTransition();
                    },
                    children: [
                      _WelcomePage(
                        title: 'Welcome to LearnoSphere',
                        subtitle: 'Your personalized learning journey starts here. Master Math, Physics, Chemistry, and Biology with AI-powered content.',
                        icon: Icons.school,
                      ),
                      _WelcomePage(
                        title: 'Learn Smarter',
                        subtitle: 'Our AI adapts to your learning style and creates personalized content that grows with you.',
                        icon: Icons.psychology,
                      ),
                      _LoginPage(
                        onGoogleSignIn: _signInWithGoogle,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),

                // Page Indicators
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _page == index ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),

                // Navigation Buttons
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      if (_page > 0)
                        InteractiveButton(
                          text: 'Back',
                          onPressed: () {
                            _controller.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: InteractiveButtonStyle.secondary,
                          enableSoundEffects: true,
                          enableHapticFeedback: true,
                        ),
                      const Spacer(),
                      if (_page < 2)
                        InteractiveButton(
                          text: 'Next',
                          onPressed: () {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: InteractiveButtonStyle.primary,
                          enableSoundEffects: true,
                          enableHapticFeedback: true,
                        ),
                    ],
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

class _WelcomePage extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _WelcomePage({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  State<_WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<_WelcomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Icon(widget.icon, color: theme.colorScheme.primary, size: 60),
            ),
          ),
          const SizedBox(height: 32),
          SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginPage extends StatefulWidget {
  final VoidCallback onGoogleSignIn;
  final bool isLoading;

  const _LoginPage({
    required this.onGoogleSignIn,
    required this.isLoading,
  });

  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.person_add,
                color: theme.colorScheme.primary,
                size: 60,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                Text(
                  'Sign In to Continue',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign in with Google to sync your progress across devices and unlock personalized features.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                InteractiveButton(
                  text: widget.isLoading ? 'Signing In...' : 'Sign In with Google',
                  onPressed: widget.isLoading ? null : widget.onGoogleSignIn,
                  icon: Icons.login,
                  style: InteractiveButtonStyle.primary,
                  enableSoundEffects: true,
                  enableHapticFeedback: true,
                  isLoading: widget.isLoading,
                  width: double.infinity,
                ),
                const SizedBox(height: 16),
                Text(
                  'Or skip to continue without signing in',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}