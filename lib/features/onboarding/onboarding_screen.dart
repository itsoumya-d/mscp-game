import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sp/core/services/progress_service.dart';
import 'package:sp/core/services/sound_manager_service.dart';
import 'package:sp/shared/widgets/interactive_button.dart';
import 'package:sp/shared/widgets/animated_background.dart';
import 'package:sp/shared/widgets/achievement_celebration_widget.dart';
import 'package:sp/features/question_types/question_type_demo_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _page = 0;
  final TextEditingController _nameCtrl = TextEditingController();
  bool _showCelebration = false;
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
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    // Show celebration animation
    setState(() => _showCelebration = true);
    SoundManagerService.instance.playAchievementUnlock();

    // Wait for celebration
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete_v1', true);
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) {
      ref.read(progressProvider.notifier).updateUserName(name);
    }
    if (!mounted) return;

    SoundManagerService.instance.playPageTransition();
    // After onboarding, go to home (local mode, no auth)
    Navigator.of(context).pushReplacementNamed('/');
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
                onPressed: _finish,
                style: InteractiveButtonStyle.ghost,
                enableSoundEffects: true,
                enableHapticFeedback: true,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Progress Indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: List.generate(
                          4,
                          (index) => Expanded(
                            child: Container(
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: index <= _page
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: PageView(
                        controller: _controller,
                        onPageChanged: (i) {
                          setState(() => _page = i);
                          SoundManagerService.instance.playPageTransition();
                        },
                        children: [
                          _IntroPage(
                            title: 'Welcome to LearnoSphere',
                            subtitle: 'Duolingo-style learning for Math, Physics, Chemistry, and Biology — adapted to your level.',
                            icon: Icons.auto_awesome,
                          ),
                          _IntroPage(
                            title: 'Play, Progress, Master',
                            subtitle: 'Earn XP, level up, collect crowns, and keep a daily streak. Difficulty ramps every level.',
                            icon: Icons.emoji_events,
                          ),
                          _QuestionTypesPage(),
                          _NamePage(controller: _nameCtrl),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          if (_page > 0)
                            InteractiveButton(
                              text: 'Back',
                              onPressed: () {
                                _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                              },
                              style: InteractiveButtonStyle.secondary,
                              enableSoundEffects: true,
                              enableHapticFeedback: true,
                            ),
                          const Spacer(),
                          InteractiveButton(
                            text: _page < 3 ? 'Next' : 'Start Learning',
                            onPressed: () {
                              if (_page < 3) {
                                _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                              } else {
                                _finish();
                              }
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

            // Celebration overlay
            if (_showCelebration)
              Positioned.fill(
                child: AchievementCelebrationWidget(
                  title: 'Welcome Aboard!',
                  description: 'Your learning journey begins now!',
                  icon: Icons.celebration,
                  onDismiss: () {
                    setState(() => _showCelebration = false);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _IntroPage({required this.title, required this.subtitle, required this.icon});

  @override
  State<_IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<_IntroPage> with SingleTickerProviderStateMixin {
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
                  style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
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

class _QuestionTypesPage extends StatefulWidget {
  const _QuestionTypesPage();

  @override
  State<_QuestionTypesPage> createState() => _QuestionTypesPageState();
}

class _QuestionTypesPageState extends State<_QuestionTypesPage> with SingleTickerProviderStateMixin {
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
              child: Icon(Icons.quiz, color: theme.colorScheme.primary, size: 60),
            ),
          ),
          const SizedBox(height: 32),
          SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                Text(
                  '7 Question Types',
                  style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Multiple choice, true/false, numeric input, fill in the blank, drag & drop, clickable answer, and short answer.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                InteractiveButton(
                  text: 'Preview Question Types',
                  icon: Icons.visibility,
                  onPressed: () {
                    SoundManagerService.instance.playButtonClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuestionTypeDemoScreen(),
                      ),
                    );
                  },
                  style: InteractiveButtonStyle.secondary,
                  enableSoundEffects: true,
                  enableHapticFeedback: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NamePage extends StatefulWidget {
  final TextEditingController controller;
  const _NamePage({required this.controller});

  @override
  State<_NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<_NamePage> with SingleTickerProviderStateMixin {
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
            child: Icon(
              Icons.person,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                Text(
                  'Tell us your name',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: widget.controller,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You can change this later in settings.',
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
