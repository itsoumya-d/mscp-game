import 'package:flutter/material.dart';
import 'package:sp/features/social/leaderboard_screen.dart';
import 'package:sp/features/social/friends_screen.dart';
import 'package:sp/features/social/challenges_screen.dart';
import 'package:sp/features/avatar/avatar_customization_screen.dart';
import 'package:sp/features/achievements/achievement_badges_screen.dart';

/// Social Hub Screen - Central hub for all social features
/// Integrates: Leaderboards, Friends, Challenges, Avatar, Achievements
class SocialHubScreen extends StatelessWidget {
  const SocialHubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Hub'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          _buildHeader(context),
          const SizedBox(height: 24),

          // Quick Stats
          _buildQuickStats(context),
          const SizedBox(height: 24),

          // Feature Cards
          _buildFeatureCard(
            context,
            title: 'Leaderboards',
            subtitle: 'Compete with friends and global players',
            icon: Icons.leaderboard,
            color: Colors.amber,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            ),
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            context,
            title: 'Friends',
            subtitle: 'Connect and learn together',
            icon: Icons.people,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FriendsScreen()),
            ),
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            context,
            title: 'Challenges',
            subtitle: 'Daily and friend challenges',
            icon: Icons.emoji_events,
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChallengesScreen()),
            ),
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            context,
            title: 'Avatar',
            subtitle: 'Customize your character',
            icon: Icons.face,
            color: Colors.pink,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AvatarCustomizationScreen(userId: 'current_user')),
            ),
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            context,
            title: 'Achievements',
            subtitle: 'View your badges and trophies',
            icon: Icons.military_tech,
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AchievementBadgesScreen(userId: 'current_user')),
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.orange,
              child: const Icon(Icons.person, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Connect with friends and compete',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            label: 'Rank',
            value: '#42',
            icon: Icons.trending_up,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            label: 'Friends',
            value: '12',
            icon: Icons.people,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            label: 'Badges',
            value: '8',
            icon: Icons.military_tech,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
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

