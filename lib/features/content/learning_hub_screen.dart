import 'package:flutter/material.dart';
import 'package:sp/features/content/infinite_practice_screen.dart';
import 'package:sp/features/content/video_library_screen.dart';
import 'package:sp/features/content/real_world_applications_screen.dart';
// AI chat screen removed for AI cleanup
// Removed missing learning feature imports
import 'package:sp/features/flashcards/flashcard_study_screen.dart';
import 'package:sp/features/learning/learning_style_assessment_screen.dart';
import 'package:sp/features/learning/spaced_repetition_review_screen.dart';
import 'package:sp/features/learning/learning_path_screen.dart';

/// Learning Hub Screen - Central hub for all learning features
/// Integrates: Practice, Videos, Real-World Apps, AI Agent, Learning Style
class LearningHubScreen extends StatelessWidget {
  const LearningHubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Hub'),
        elevation: 0,
        actions: [
          // AI Tutor button removed for AI cleanup
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          _buildHeader(context),
          const SizedBox(height: 24),

          // Daily Recommendation
          _buildDailyRecommendation(context),
          const SizedBox(height: 24),

          // Learning Features
          Text(
            'Learning Tools',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            context,
            title: 'Flashcard Study',
            subtitle: 'Master concepts with spaced repetition',
            icon: Icons.style,
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FlashcardStudyScreen(
                  subjectId: 'general',
                  targetCount: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            context,
            title: 'Infinite Practice',
            subtitle: 'Practice with unlimited AI-generated problems',
            icon: Icons.fitness_center,
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InfinitePracticeScreen(subject: 'Math', topic: 'Algebra')),
            ),
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            context,
            title: 'Video Library',
            subtitle: 'Watch concept explanations and tutorials',
            icon: Icons.video_library,
            color: Colors.red,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VideoLibraryScreen()),
            ),
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            context,
            title: 'Real-World Applications',
            subtitle: 'See how concepts apply to real life',
            icon: Icons.public,
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RealWorldApplicationsScreen()),
            ),
          ),
          const SizedBox(height: 16),

          // AI Tutor feature removed for AI cleanup
          const SizedBox(height: 16),

          _buildFeatureCard(
            context,
            title: 'Learning Style Assessment',
            subtitle: 'Discover your optimal learning style',
            icon: Icons.assessment,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LearningStyleAssessmentScreen(userId: 'current_user')),
            ),
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            context,
            title: 'Spaced Repetition',
            subtitle: 'Review concepts at optimal intervals',
            icon: Icons.repeat,
            color: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SpacedRepetitionReviewScreen(userId: 'current_user'),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            context,
            title: 'Learning Path',
            subtitle: 'Visualize your personalized learning journey',
            icon: Icons.route,
            color: Colors.indigo,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LearningPathScreen(
                  userId: 'current_user',
                  subject: 'Math',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, size: 32, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Learning Journey',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Explore personalized learning tools',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyRecommendation(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Recommendation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Based on your learning style, we recommend practicing Algebra today. You\'re 85% of the way to mastery!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InfinitePracticeScreen(subject: 'Math', topic: 'Algebra')),
                );
              },
              child: const Text('Start Practice'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

