import 'package:flutter/material.dart';
import '../../core/services/tutorial_service.dart';

/// Help screen explaining how to play the game
/// Accessible from game screens and settings
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Play'),
        backgroundColor: Colors.orange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('🎮 Game Basics', context),
          _buildInfoCard(
            'Answer questions correctly to earn XP and gems. '
            'You have 5 lives - lose one for each wrong answer. '
            'Complete levels to unlock new content!',
            context,
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('📝 Question Types', context),
          _buildQuestionTypeCard(
            'Multiple Choice',
            'Tap the correct answer from 4 options',
            Icons.radio_button_checked,
            Colors.blue,
            context,
          ),
          _buildQuestionTypeCard(
            'True or False',
            'Decide if the statement is true or false',
            Icons.check_circle,
            Colors.green,
            context,
          ),
          _buildQuestionTypeCard(
            'Numeric Input',
            'Type the correct number as your answer',
            Icons.numbers,
            Colors.purple,
            context,
          ),
          _buildQuestionTypeCard(
            'Fill in the Blank',
            'Complete the sentence with the right word',
            Icons.edit,
            Colors.orange,
            context,
          ),
          _buildQuestionTypeCard(
            'Drag & Drop',
            'Drag items to their correct positions',
            Icons.drag_indicator,
            Colors.teal,
            context,
          ),
          _buildQuestionTypeCard(
            'Clickable Answer',
            'Click on the correct part of the image',
            Icons.touch_app,
            Colors.pink,
            context,
          ),
          _buildQuestionTypeCard(
            'Short Answer',
            'Type your answer in your own words',
            Icons.keyboard,
            Colors.indigo,
            context,
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('💎 Rewards & Progress', context),
          _buildInfoCard(
            '• Earn 10 XP for each correct answer\n'
            '• Collect gems to buy hints and power-ups\n'
            '• Complete levels to unlock new subjects\n'
            '• Track your progress on the level map',
            context,
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('💡 Tips & Tricks', context),
          _buildInfoCard(
            '• Read questions carefully before answering\n'
            '• Use hints if you\'re stuck (costs 5 gems)\n'
            '• Practice makes perfect - replay levels to improve\n'
            '• Check your profile to see achievements',
            context,
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('❓ Need More Help?', context),
          _buildInfoCard(
            'Each question type has its own tutorial that shows '
            'the first time you encounter it. You can also replay '
            'tutorials from the Settings menu.',
            context,
          ),
          const SizedBox(height: 32),
          
          Center(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Playing!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  Widget _buildInfoCard(String text, BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionTypeCard(
    String title,
    String description,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(description),
        contentPadding: const EdgeInsets.all(12.0),
      ),
    );
  }
}

/// Floating help button widget that can be added to any screen
class HelpButton extends StatelessWidget {
  final VoidCallback? onPressed;
  
  const HelpButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed ?? () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const HowToPlayScreen(),
          ),
        );
      },
      backgroundColor: Colors.orange,
      child: const Icon(Icons.help_outline),
    );
  }
}

/// Small help icon button for app bars
class HelpIconButton extends StatelessWidget {
  const HelpIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const HowToPlayScreen(),
          ),
        );
      },
      tooltip: 'How to Play',
    );
  }
}

