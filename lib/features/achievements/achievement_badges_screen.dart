import 'package:flutter/material.dart';
import '../../core/services/asset_service.dart';

/// Achievement Badges System - Task D5
/// Comprehensive badge system with categories, rarity levels, and collection tracking
class AchievementBadgesScreen extends StatefulWidget {
  final String userId;

  const AchievementBadgesScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<AchievementBadgesScreen> createState() =>
      _AchievementBadgesScreenState();
}

class _AchievementBadgesScreenState extends State<AchievementBadgesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';

  // Mock data - replace with backend
  final List<Achievement> _achievements = [
    // Gameplay achievements
    Achievement(
      id: 'first_win',
      name: 'First Victory',
      description: 'Complete your first level',
      category: AchievementCategory.gameplay,
      rarity: AchievementRarity.common,
      isUnlocked: true,
      unlockedDate: DateTime.now().subtract(const Duration(days: 30)),
      progress: 1,
      maxProgress: 1,
      xpReward: 50,
    ),
    Achievement(
      id: 'perfect_score',
      name: 'Perfect Score',
      description: 'Get 100% on any level',
      category: AchievementCategory.gameplay,
      rarity: AchievementRarity.rare,
      isUnlocked: true,
      unlockedDate: DateTime.now().subtract(const Duration(days: 15)),
      progress: 1,
      maxProgress: 1,
      xpReward: 200,
    ),
    Achievement(
      id: 'speed_demon',
      name: 'Speed Demon',
      description: 'Complete a level in under 5 minutes',
      category: AchievementCategory.gameplay,
      rarity: AchievementRarity.epic,
      isUnlocked: false,
      progress: 0,
      maxProgress: 1,
      xpReward: 500,
    ),
    
    // Progress achievements
    Achievement(
      id: 'level_10',
      name: 'Rising Star',
      description: 'Reach level 10',
      category: AchievementCategory.progress,
      rarity: AchievementRarity.common,
      isUnlocked: true,
      unlockedDate: DateTime.now().subtract(const Duration(days: 20)),
      progress: 10,
      maxProgress: 10,
      xpReward: 100,
    ),
    Achievement(
      id: 'level_50',
      name: 'Expert Learner',
      description: 'Reach level 50',
      category: AchievementCategory.progress,
      rarity: AchievementRarity.legendary,
      isUnlocked: false,
      progress: 42,
      maxProgress: 50,
      xpReward: 2000,
    ),
    
    // Social achievements
    Achievement(
      id: 'first_friend',
      name: 'Social Butterfly',
      description: 'Add your first friend',
      category: AchievementCategory.social,
      rarity: AchievementRarity.common,
      isUnlocked: true,
      unlockedDate: DateTime.now().subtract(const Duration(days: 25)),
      progress: 1,
      maxProgress: 1,
      xpReward: 50,
    ),
    Achievement(
      id: 'friend_100',
      name: 'Popular',
      description: 'Have 100 friends',
      category: AchievementCategory.social,
      rarity: AchievementRarity.epic,
      isUnlocked: false,
      progress: 45,
      maxProgress: 100,
      xpReward: 1000,
    ),
    
    // Special achievements
    Achievement(
      id: 'early_bird',
      name: 'Early Bird',
      description: 'Complete a lesson before 8 AM',
      category: AchievementCategory.special,
      rarity: AchievementRarity.rare,
      isUnlocked: false,
      progress: 0,
      maxProgress: 1,
      xpReward: 300,
    ),
    Achievement(
      id: 'night_owl',
      name: 'Night Owl',
      description: 'Complete a lesson after 10 PM',
      category: AchievementCategory.special,
      rarity: AchievementRarity.rare,
      isUnlocked: true,
      unlockedDate: DateTime.now().subtract(const Duration(days: 5)),
      progress: 1,
      maxProgress: 1,
      xpReward: 300,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Achievement> get _filteredAchievements {
    if (_selectedCategory == 'all') return _achievements;
    final category = AchievementCategory.values.firstWhere(
      (c) => c.toString().split('.').last == _selectedCategory,
    );
    return _achievements.where((a) => a.category == category).toList();
  }

  int get _unlockedCount =>
      _achievements.where((a) => a.isUnlocked).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: Column(
        children: [
          _buildProgressHeader(),
          _buildCategoryFilter(),
          Expanded(
            child: _buildAchievementGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    final total = _achievements.length;
    final progress = _unlockedCount / total;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            '$_unlockedCount / $total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Achievements Unlocked',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Gameplay', 'gameplay'),
            const SizedBox(width: 8),
            _buildFilterChip('Progress', 'progress'),
            const SizedBox(width: 8),
            _buildFilterChip('Social', 'social'),
            const SizedBox(width: 8),
            _buildFilterChip('Special', 'special'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementGrid() {
    final achievements = _filteredAchievements;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(achievements[index]);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Card(
      child: InkWell(
        onTap: () => _showAchievementDetails(achievement),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: achievement.isUnlocked
                      ? _getRarityColor(achievement.rarity).withOpacity(0.2)
                      : Colors.grey[300],
                  border: Border.all(
                    color: achievement.isUnlocked
                        ? _getRarityColor(achievement.rarity)
                        : Colors.grey,
                    width: 3,
                  ),
                ),
                child: achievement.isUnlocked 
                    ? AssetService.getAchievementIcon(
                        achievement.id,
                        width: 40,
                        height: 40,
                        color: _getRarityColor(achievement.rarity),
                      )
                    : Icon(
                        Icons.lock,
                        size: 40,
                        color: Colors.grey,
                      ),
              ),
              const SizedBox(height: 12),
              
              // Name
              Text(
                achievement.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: achievement.isUnlocked ? null : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Rarity badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRarityColor(achievement.rarity).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getRarityLabel(achievement.rarity),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getRarityColor(achievement.rarity),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Progress bar (if not unlocked)
              if (!achievement.isUnlocked && achievement.maxProgress > 1)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: achievement.progress / achievement.maxProgress,
                        minHeight: 6,
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${achievement.progress}/${achievement.maxProgress}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.amber;
    }
  }

  String _getRarityLabel(AchievementRarity rarity) {
    return rarity.toString().split('.').last.toUpperCase();
  }

  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Rarity: '),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRarityColor(achievement.rarity).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRarityLabel(achievement.rarity),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getRarityColor(achievement.rarity),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Reward: ${achievement.xpReward} XP'),
            if (achievement.isUnlocked) ...[
              const SizedBox(height: 8),
              Text(
                'Unlocked: ${_formatDate(achievement.unlockedDate!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else if (achievement.maxProgress > 1) ...[
              const SizedBox(height: 8),
              Text('Progress: ${achievement.progress}/${achievement.maxProgress}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Achievement categories
enum AchievementCategory {
  gameplay,
  progress,
  social,
  special,
}

/// Achievement rarity levels
enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

/// Achievement data model
class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final bool isUnlocked;
  final DateTime? unlockedDate;
  final int progress;
  final int maxProgress;
  final int xpReward;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.isUnlocked,
    this.unlockedDate,
    required this.progress,
    required this.maxProgress,
    required this.xpReward,
  });
}

