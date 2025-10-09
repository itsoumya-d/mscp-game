import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lottie/lottie.dart';
import '../../core/services/tutorial_service.dart';
import '../home/home_screen.dart';

/// Comprehensive onboarding screen for first-time users
/// Shows 5 screens explaining key features of LearnoSphere
class AppOnboardingScreen extends StatefulWidget {
  const AppOnboardingScreen({super.key});

  @override
  State<AppOnboardingScreen> createState() => _AppOnboardingScreenState();
}

class _AppOnboardingScreenState extends State<AppOnboardingScreen> {
  final _tutorialService = TutorialService();
  final _introKey = GlobalKey<IntroductionScreenState>();

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      key: _introKey,
      pages: [
        _buildWelcomePage(),
        _buildLearningPage(),
        _buildProgressPage(),
        _buildRewardsPage(),
        _buildReadyPage(),
      ],
      onDone: () => _onOnboardingComplete(context),
      onSkip: () => _onOnboardingComplete(context),
      showSkipButton: true,
      skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Start Learning!', style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: Theme.of(context).colorScheme.primary,
        color: Colors.grey,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
    );
  }

  /// Page 1: Welcome to LearnoSphere
  PageViewModel _buildWelcomePage() {
    return PageViewModel(
      title: "Welcome to LearnoSphere! 🎓",
      body: "Your journey to mastering Math, Physics, Chemistry, and Biology starts here. "
          "Learn through fun, interactive games and challenges!",
      image: Center(
        child: Icon(
          Icons.school,
          size: 150,
          color: Colors.orange,
        ),
      ),
      decoration: _getPageDecoration(),
    );
  }

  /// Page 2: How Learning Works
  PageViewModel _buildLearningPage() {
    return PageViewModel(
      title: "Learn Through Play 🎮",
      body: "Answer questions in 7 different formats:\n"
          "• Multiple Choice\n"
          "• True/False\n"
          "• Fill in the Blank\n"
          "• Drag & Drop\n"
          "• And more!\n\n"
          "Each question type has its own tutorial to help you get started.",
      image: Center(
        child: Icon(
          Icons.games,
          size: 150,
          color: Colors.blue,
        ),
      ),
      decoration: _getPageDecoration(),
    );
  }

  /// Page 3: Progress & Unlocking
  PageViewModel _buildProgressPage() {
    return PageViewModel(
      title: "Unlock New Levels 🔓",
      body: "Complete levels to unlock new chapters and subjects!\n\n"
          "• Start with easy levels\n"
          "• Earn XP for correct answers\n"
          "• Unlock harder challenges\n"
          "• Track your progress\n\n"
          "The more you play, the more you unlock!",
      image: Center(
        child: Icon(
          Icons.lock_open,
          size: 150,
          color: Colors.green,
        ),
      ),
      decoration: _getPageDecoration(),
    );
  }

  /// Page 4: Gems, Lives & Rewards
  PageViewModel _buildRewardsPage() {
    return PageViewModel(
      title: "Earn Rewards 💎",
      body: "Collect gems and earn achievements!\n\n"
          "💎 Gems: Use for hints and power-ups\n"
          "❤️ Lives: You have 5 lives - use them wisely!\n"
          "⭐ XP: Gain experience to level up\n"
          "🏆 Achievements: Complete challenges\n\n"
          "The better you perform, the more you earn!",
      image: Center(
        child: Icon(
          Icons.emoji_events,
          size: 150,
          color: Colors.amber,
        ),
      ),
      decoration: _getPageDecoration(),
    );
  }

  /// Page 5: Ready to Start
  PageViewModel _buildReadyPage() {
    return PageViewModel(
      title: "You're All Set! 🚀",
      body: "Ready to start your learning adventure?\n\n"
          "Don't worry - we'll guide you through each question type "
          "the first time you see it.\n\n"
          "You can always access help from the settings menu.\n\n"
          "Let's begin!",
      image: Center(
        child: Icon(
          Icons.rocket_launch,
          size: 150,
          color: Colors.purple,
        ),
      ),
      decoration: _getPageDecoration(),
    );
  }

  /// Common page decoration
  PageDecoration _getPageDecoration() {
    return PageDecoration(
      titleTextStyle: const TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
      ),
      bodyTextStyle: const TextStyle(
        fontSize: 18.0,
        height: 1.5,
      ),
      imagePadding: const EdgeInsets.only(top: 40),
      pageColor: Colors.white,
      bodyPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      titlePadding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
      contentMargin: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }

  /// Handle onboarding completion
  Future<void> _onOnboardingComplete(BuildContext context) async {
    // Mark onboarding as complete
    await _tutorialService.markTutorialComplete(TutorialIds.onboarding);
    
    // Navigate to home screen
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }
}

/// Tutorial IDs for tracking completion
class TutorialIds {
  static const String onboarding = 'onboarding';
  static const String homeScreen = 'home_screen';
  static const String subjectSelection = 'subject_selection';
  static const String levelSelection = 'level_selection';
  static const String gameSession = 'game_session';
  static const String multipleChoice = 'multiple_choice';
  static const String trueFalse = 'true_false';
  static const String numericInput = 'numeric_input';
  static const String fillInBlank = 'fill_in_blank';
  static const String dragDrop = 'drag_drop';
  static const String clickableAnswer = 'clickable_answer';
  static const String shortAnswer = 'short_answer';
  static const String hints = 'hints';
  static const String lives = 'lives';
  static const String xpSystem = 'xp_system';
  static const String levelUnlocking = 'level_unlocking';
}

