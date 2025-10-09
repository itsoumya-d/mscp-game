import 'package:flutter/material.dart';
import 'package:sp/core/models/user.dart';
import 'package:sp/shared/widgets/elevated_card.dart';
import 'package:sp/shared/widgets/progress_ring.dart';
import 'package:sp/shared/widgets/interactive_lesson_widget.dart';
import 'package:sp/theme.dart';

class UserProgressCard extends StatelessWidget {
  final User user;
  final double levelProgress;
  final int xpInLevel;
  final int xpToNext;

  const UserProgressCard({
    super.key,
    required this.user,
    required this.levelProgress,
    required this.xpInLevel,
    required this.xpToNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InteractiveLessonWidget(
      enableSoundEffects: false, // No sound for progress display
      child: ElevatedCard(
        child: Column(
        children: [
          Row(
            children: [
              ProgressRing(
                progress: levelProgress,
                size: 60,
                child: Text(
                  '${user.level}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${user.level}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.totalXP} XP total',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$xpInLevel / $xpToNext XP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(InteractiveDesign.smallRadius),
                      child: LinearProgressIndicator(
                        value: levelProgress,
                        backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.local_fire_department,
                  label: 'Streak',
                  value: '${user.currentStreak}',
                  color: LightModeColors.lightWarning,
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.diamond,
                  label: 'Gems',
                  value: '${user.gems}',
                  color: LightModeColors.lightInfo,
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.favorite,
                  label: 'Lives',
                  value: '${user.lives}',
                  color: LightModeColors.lightError,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
