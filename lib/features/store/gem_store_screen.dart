import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sp/core/services/progress_service.dart';
import 'package:sp/shared/widgets/elevated_card.dart';

class GemStoreScreen extends ConsumerWidget {
  const GemStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(progressProvider);
    final user = progress.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gem Store'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.diamond,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${user.gems}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Spend Your Gems',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use gems to get helpful items and maintain your progress',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          
          // Heart Refill
          _StoreItem(
            icon: Icons.favorite,
            iconColor: Colors.red,
            title: 'Refill Hearts',
            description: 'Restore all hearts to continue learning',
            cost: 10,
            isAvailable: user.lives < 5,
            onPurchase: () async {
              final success = await ref.read(progressProvider.notifier).refillHeartsWithGems(cost: 10);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                      ? 'Hearts refilled successfully!' 
                      : 'Not enough gems to refill hearts'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Streak Freeze
          _StoreItem(
            icon: Icons.ac_unit,
            iconColor: Colors.blue,
            title: 'Streak Freeze',
            description: 'Protect your streak for one missed day',
            cost: 5,
            isAvailable: true,
            onPurchase: () async {
              final success = await ref.read(progressProvider.notifier).freezeStreakWithGems(cost: 5);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                      ? 'Streak freeze activated!' 
                      : 'Not enough gems for streak freeze'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Hint Pack
          _StoreItem(
            icon: Icons.lightbulb,
            iconColor: Colors.amber,
            title: 'Hint Pack (10 Hints)',
            description: 'Get 10 free hints for difficult questions',
            cost: 15,
            isAvailable: true,
            onPurchase: () async {
              final success = await ref.read(progressProvider.notifier).spendGems(15);
              if (success) {
                // Add 50 coins (equivalent to 10 hints at 5 coins each)
                await ref.read(progressProvider.notifier).addCoins(50);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hint pack purchased! 50 coins added for hints.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Not enough gems for hint pack'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Double XP Boost
          _StoreItem(
            icon: Icons.flash_on,
            iconColor: Colors.orange,
            title: 'Double XP Boost',
            description: 'Earn 2x XP for the next 5 lessons',
            cost: 20,
            isAvailable: true,
            onPurchase: () async {
              final success = await ref.read(progressProvider.notifier).spendGems(20);
              if (success) {
                // TODO: Implement XP boost tracking
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Double XP boost activated! (Feature coming soon)'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Not enough gems for XP boost'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          
          const SizedBox(height: 32),
          
          // How to earn gems section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.diamond,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'How to Earn Gems',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _EarnGemsItem(
                  icon: Icons.trending_up,
                  text: 'Level up: +5 gems per level',
                ),
                const SizedBox(height: 8),
                _EarnGemsItem(
                  icon: Icons.local_fire_department,
                  text: 'Maintain daily streaks: +2 gems per week',
                ),
                const SizedBox(height: 8),
                _EarnGemsItem(
                  icon: Icons.star,
                  text: 'Complete perfect lessons: +1 gem',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final int cost;
  final bool isAvailable;
  final VoidCallback onPurchase;

  const _StoreItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.cost,
    required this.isAvailable,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ElevatedCard(
      onTap: isAvailable ? onPurchase : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isAvailable 
                        ? theme.colorScheme.onSurface 
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isAvailable 
                        ? theme.colorScheme.onSurface.withOpacity(0.7)
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isAvailable 
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.diamond,
                    color: isAvailable 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$cost',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isAvailable 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarnGemsItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EarnGemsItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}