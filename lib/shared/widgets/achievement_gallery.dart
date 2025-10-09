import 'package:flutter/material.dart';
import '../../core/services/asset_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/achievement_service.dart';
import '../../core/providers/achievement_provider.dart';
import 'lottie_animation_widget.dart';

enum AchievementFilter {
  all,
  gameplay,
  progress,
  streak,
  mastery,
  social,
  special,
}

class AchievementGallery extends ConsumerStatefulWidget {
  const AchievementGallery({super.key});

  @override
  ConsumerState<AchievementGallery> createState() => _AchievementGalleryState();
}

class _AchievementGalleryState extends ConsumerState<AchievementGallery>
    with TickerProviderStateMixin {
  late AnimationController _gridController;
  late AnimationController _filterController;
  late Animation<double> _gridAnimation;
  late Animation<double> _filterAnimation;

  AchievementFilter _currentFilter = AchievementFilter.all;
  bool _showUnlockedOnly = false;

  @override
  void initState() {
    super.initState();
    _gridController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _gridAnimation = CurvedAnimation(
      parent: _gridController,
      curve: Curves.easeOutBack,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterController,
      curve: Curves.easeInOut,
    );

    _gridController.forward();
  }

  @override
  void dispose() {
    _gridController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final achievementService = ref.watch(achievementServiceProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showUnlockedOnly ? Icons.lock_open : Icons.lock,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              setState(() {
                _showUnlockedOnly = !_showUnlockedOnly;
              });
              _filterController.forward().then((_) {
                _filterController.reverse();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(theme),
          Expanded(
            child: _buildAchievementGrid(achievementService, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(ThemeData theme) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedBuilder(
        animation: _filterAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_filterAnimation.value * 0.05),
            child: Row(
              children: AchievementFilter.values.map((filter) {
                final isSelected = _currentFilter == filter;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _selectFilter(filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getFilterName(filter),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementGrid(
      AchievementService achievementService, ThemeData theme) {
    return FutureBuilder<List<Achievement>>(
      future: achievementService.getAllAchievements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: LottieAnimationWidget(
              type: AnimationType.loading,
              width: 100,
              height: 100,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const LottieAnimationWidget(
                  type: AnimationType.thinking,
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 16),
                Text(
                  'No achievements yet!',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start playing to unlock achievements',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

        final achievements = _filterAchievements(snapshot.data!);

        return AnimatedBuilder(
          animation: _gridAnimation,
          builder: (context, child) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                final delay = index * 0.1;
                final animationValue = (_gridAnimation.value - delay).clamp(0.0, 1.0);

                return Transform.scale(
                  scale: animationValue,
                  child: Transform.translate(
                    offset: Offset(0, 50 * (1 - animationValue)),
                    child: Opacity(
                      opacity: animationValue,
                      child: AchievementCard(
                        achievement: achievement,
                        onTap: () => _showAchievementDetail(context, achievement),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<Achievement> _filterAchievements(List<Achievement> achievements) {
    var filtered = achievements;

    if (_showUnlockedOnly) {
      filtered = filtered.where((a) => a.isUnlocked).toList();
    }

    if (_currentFilter != AchievementFilter.all) {
      filtered = filtered.where((a) => _matchesFilter(a.type, _currentFilter)).toList();
    }

    return filtered;
  }

  void _selectFilter(AchievementFilter filter) {
    if (_currentFilter != filter) {
      setState(() {
        _currentFilter = filter;
      });
      _filterController.forward().then((_) {
        _filterController.reverse();
      });
    }
  }

  bool _matchesFilter(AchievementType type, AchievementFilter filter) {
    switch (filter) {
      case AchievementFilter.all:
        return true;
      case AchievementFilter.gameplay:
        return type == AchievementType.gameplay;
      case AchievementFilter.progress:
        return type == AchievementType.progress;
      case AchievementFilter.streak:
        return type == AchievementType.streak;
      case AchievementFilter.mastery:
        return type == AchievementType.mastery;
      case AchievementFilter.social:
        return type == AchievementType.social;
      case AchievementFilter.special:
        return type == AchievementType.special;
    }
  }

  String _getFilterName(AchievementFilter filter) {
    switch (filter) {
      case AchievementFilter.all:
        return 'All';
      case AchievementFilter.gameplay:
        return 'Game';
      case AchievementFilter.progress:
        return 'Progress';
      case AchievementFilter.streak:
        return 'Streak';
      case AchievementFilter.mastery:
        return 'Mastery';
      case AchievementFilter.social:
        return 'Social';
      case AchievementFilter.special:
        return 'Special';
    }
  }

  void _showAchievementDetail(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AchievementDetailDialog(achievement: achievement),
    );
  }
}

class AchievementCard extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
  });

  @override
  State<AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<AchievementCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _unlockController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _unlockController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _unlockController,
      curve: Curves.easeInOut,
    ));

    if (widget.achievement.isUnlocked) {
      _unlockController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _unlockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnlocked = widget.achievement.isUnlocked;

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _glowAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: (_) => _hoverController.forward(),
            onTapUp: (_) => _hoverController.reverse(),
            onTapCancel: () => _hoverController.reverse(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isUnlocked
                      ? [
                          _getRarityColor(widget.achievement.rarity)
                              .withValues(alpha: 0.2),
                          _getRarityColor(widget.achievement.rarity)
                              .withValues(alpha: 0.1),
                        ]
                      : [
                          theme.colorScheme.surface,
                          theme.colorScheme.surface.withValues(alpha: 0.5),
                        ],
                ),
                border: Border.all(
                  color: isUnlocked
                      ? _getRarityColor(widget.achievement.rarity)
                          .withValues(alpha: 0.5 + (_glowAnimation.value * 0.5))
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: _getRarityColor(widget.achievement.rarity)
                              .withValues(alpha: 0.3 * _glowAnimation.value),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isUnlocked
                                    ? _getRarityColor(widget.achievement.rarity)
                                    : theme.colorScheme.outline
                                        .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: isUnlocked
                                  ? AssetService.getAchievementIcon(
                                      widget.achievement.id,
                                      width: 24,
                                      height: 24,
                                      color: Colors.white,
                                    )
                                  : Icon(
                                      _getTypeIcon(widget.achievement.type),
                                      color: theme.colorScheme.outline,
                                      size: 24,
                                    ),
                            ),
                            const Spacer(),
                            if (isUnlocked)
                              const LottieAnimationWidget(
                                type: AnimationType.sparkles,
                                width: 30,
                                height: 30,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.achievement.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isUnlocked
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.achievement.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isUnlocked
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7)
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRarityColor(widget.achievement.rarity)
                                    .withValues(alpha: isUnlocked ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getRarityName(widget.achievement.rarity),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _getRarityColor(widget.achievement.rarity),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (widget.achievement.xpReward > 0)
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.achievement.xpReward}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isUnlocked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }

  String _getRarityName(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  IconData _getTypeIcon(AchievementType type) {
    switch (type) {
      case AchievementType.gameplay:
        return Icons.games;
      case AchievementType.progress:
        return Icons.trending_up;
      case AchievementType.streak:
        return Icons.local_fire_department;
      case AchievementType.mastery:
        return Icons.school;
      case AchievementType.social:
        return Icons.people;
      case AchievementType.special:
        return Icons.star;
    }
  }
}

class AchievementDetailDialog extends StatelessWidget {
  final Achievement achievement;

  const AchievementDetailDialog({
    super.key,
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getRarityColor(achievement.rarity),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (achievement.isUnlocked)
              const LottieAnimationWidget(
                type: AnimationType.celebration,
                width: 100,
                height: 100,
                repeat: false,
              )
            else
              Icon(
                Icons.lock,
                size: 80,
                color: theme.colorScheme.outline,
              ),
            const SizedBox(height: 16),
            Text(
              achievement.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      'Rarity',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getRarityColor(achievement.rarity)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getRarityName(achievement.rarity),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getRarityColor(achievement.rarity),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (achievement.xpReward > 0)
                  Column(
                    children: [
                      Text(
                        'XP Reward',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 20,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${achievement.xpReward}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }

  String _getRarityName(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }
}