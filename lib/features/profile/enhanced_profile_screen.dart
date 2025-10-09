import 'package:flutter/material.dart';
import '../../core/services/asset_service.dart';
import 'package:provider/provider.dart';
import '../../core/services/asset_service.dart';
import 'dart:math' as math;

/// Enhanced Profile Screen - Task B9
/// Redesigned profile with avatar customization, stats dashboard, achievement showcase
class EnhancedProfileScreen extends StatefulWidget {
  final String userId;

  const EnhancedProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data - replace with actual data from backend
  final UserProfile _profile = UserProfile(
    id: 'user_123',
    name: 'Alex Johnson',
    username: '@alexj',
    bio: 'Learning enthusiast | Math lover | Future engineer',
    avatarUrl: null,
    level: 42,
    totalXP: 15750,
    streak: 28,
    joinedDate: DateTime(2024, 1, 15),
    stats: ProfileStats(
      questionsAnswered: 1250,
      accuracy: 87.5,
      studyTime: 3420, // minutes
      achievements: 24,
      friends: 156,
      rank: 'Gold',
    ),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileHeader(),
                _buildStatsGrid(),
                _buildTabBar(),
              ],
            ),
          ),
          _buildTabContent(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareProfile,
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _openSettings,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar with level badge
          Stack(
            children: [
              GestureDetector(
                onTap: _editAvatar,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: AssetService.getAvatarIcon(
                      'default_avatar',
                      width: 120,
                      height: 120,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 3,
                    ),
                  ),
                  child: Text(
                    'Lv ${_profile.level}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Name and username
          Text(
            _profile.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _profile.username,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 12),
          
          // Bio
          Text(
            _profile.bio,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          
          // Edit profile button
          OutlinedButton.icon(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: [
          _buildStatCard(
            icon: Icons.stars,
            value: '${_profile.totalXP}',
            label: 'Total XP',
            color: Colors.amber,
          ),
          _buildStatCard(
            icon: Icons.local_fire_department,
            value: '${_profile.streak}',
            label: 'Day Streak',
            color: Colors.orange,
          ),
          _buildStatCard(
            icon: Icons.emoji_events,
            value: _profile.stats.rank,
            label: 'Rank',
            color: Colors.purple,
          ),
          _buildStatCard(
            icon: Icons.quiz,
            value: '${_profile.stats.questionsAnswered}',
            label: 'Questions',
            color: Colors.blue,
          ),
          _buildStatCard(
            icon: Icons.check_circle,
            value: '${_profile.stats.accuracy.toStringAsFixed(1)}%',
            label: 'Accuracy',
            color: Colors.green,
          ),
          _buildStatCard(
            icon: Icons.people,
            value: '${_profile.stats.friends}',
            label: 'Friends',
            color: Colors.pink,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        tabs: const [
          Tab(text: 'Activity'),
          Tab(text: 'Achievements'),
          Tab(text: 'Stats'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildActivityTab(),
          _buildAchievementsTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.primaries[index % Colors.primaries.length],
              child: const Icon(Icons.check, color: Colors.white),
            ),
            title: Text('Completed Level ${index + 1}'),
            subtitle: Text('${index + 1} hours ago'),
            trailing: Text(
              '+${(index + 1) * 10} XP',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _profile.stats.achievements,
      itemBuilder: (context, index) {
        return Card(
          child: InkWell(
            onTap: () => _showAchievementDetails(index),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AssetService.getAchievementIcon(
                  'badge_${index + 1}',
                  width: 40,
                  height: 40,
                  color: Colors.primaries[index % Colors.primaries.length],
                ),
                const SizedBox(height: 8),
                Text(
                  'Badge ${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow('Study Time', '${_profile.stats.studyTime ~/ 60} hours'),
                  const Divider(),
                  _buildStatRow('Questions Answered', '${_profile.stats.questionsAnswered}'),
                  const Divider(),
                  _buildStatRow('Accuracy Rate', '${_profile.stats.accuracy}%'),
                  const Divider(),
                  _buildStatRow('Current Streak', '${_profile.streak} days'),
                  const Divider(),
                  _buildStatRow('Member Since', _formatDate(_profile.joinedDate)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _editAvatar() {
    // Navigate to avatar customization
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Avatar Customization'),
        content: const Text('Avatar customization coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editProfile() {
    // Navigate to edit profile screen
  }

  void _shareProfile() {
    // Share profile functionality
  }

  void _openSettings() {
    // Navigate to settings
  }

  void _showAchievementDetails(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Achievement ${index + 1}'),
        content: const Text('Achievement details coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// User profile data model
class UserProfile {
  final String id;
  final String name;
  final String username;
  final String bio;
  final String? avatarUrl;
  final int level;
  final int totalXP;
  final int streak;
  final DateTime joinedDate;
  final ProfileStats stats;

  UserProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.bio,
    this.avatarUrl,
    required this.level,
    required this.totalXP,
    required this.streak,
    required this.joinedDate,
    required this.stats,
  });
}

/// Profile statistics
class ProfileStats {
  final int questionsAnswered;
  final double accuracy;
  final int studyTime; // in minutes
  final int achievements;
  final int friends;
  final String rank;

  ProfileStats({
    required this.questionsAnswered,
    required this.accuracy,
    required this.studyTime,
    required this.achievements,
    required this.friends,
    required this.rank,
  });
}

