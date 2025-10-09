import 'package:flutter/material.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/shared/widgets/elevated_card.dart';

class SkillTree extends StatelessWidget {
  final Unit unit;
  final Function(Skill) onSkillTap;

  const SkillTree({
    super.key,
    required this.unit,
    required this.onSkillTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: unit.isUnlocked
                  ? [
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                    ]
                  : [
                      theme.colorScheme.outline.withValues(alpha: 0.1),
                      theme.colorScheme.outline.withValues(alpha: 0.05),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: unit.isUnlocked 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  unit.isUnlocked ? Icons.lock_open : Icons.lock,
                  color: unit.isUnlocked 
                      ? theme.colorScheme.onPrimary 
                      : theme.colorScheme.outline,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: unit.isUnlocked 
                            ? null 
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      unit.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: unit.isUnlocked ? 0.7 : 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (unit.isUnlocked)
          ...unit.skills.asMap().entries.map((entry) {
            final index = entry.key;
            final skill = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                left: (index % 2) * 40.0 + 20,
                bottom: 16,
              ),
              child: SkillNode(
                skill: skill,
                onTap: () => onSkillTap(skill),
              ),
            );
          }),
      ],
    );
  }
}

class SkillNode extends StatelessWidget {
  final Skill skill;
  final VoidCallback onTap;

  const SkillNode({
    super.key,
    required this.skill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedLessons = skill.lessons.where((l) => l.isCompleted).length;
    final totalLessons = skill.lessons.length;

    return ElevatedCard(
      onTap: skill.isUnlocked ? onTap : null,
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 120,
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: skill.isUnlocked
                        ? (skill.crowns > 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primaryContainer)
                        : theme.colorScheme.outline.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: skill.crowns > 0
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Icon(
                    _getSkillIcon(skill.id),
                    color: skill.isUnlocked
                        ? (skill.crowns > 0
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary)
                        : theme.colorScheme.outline,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  skill.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: skill.isUnlocked
                        ? null
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Level progress badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: skill.isUnlocked
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.outline.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$completedLessons/$totalLessons',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: skill.isUnlocked
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    skill.maxCrowns.clamp(0, 5),
                    (index) => Icon(
                      index < skill.crowns ? Icons.star : Icons.star_border,
                      color: skill.isUnlocked
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            // Level badge in top-right corner
            if (skill.isUnlocked)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Lv ${completedLessons + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getSkillIcon(String skillId) {
    switch (skillId) {
      case 'addition':
        return Icons.add;
      case 'multiplication':
        return Icons.close;
      case 'fractions':
        return Icons.pie_chart;
      case 'variables':
        return Icons.functions;
      default:
        return Icons.school;
    }
  }
}
