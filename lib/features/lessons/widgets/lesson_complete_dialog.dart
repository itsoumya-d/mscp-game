import 'package:flutter/material.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/shared/widgets/interactive_button.dart';

class LessonCompleteDialog extends StatelessWidget {
  final Lesson lesson;
  final int correctAnswers;
  final int totalAnswers;
  final VoidCallback onContinue;

  const LessonCompleteDialog({
    super.key,
    required this.lesson,
    required this.correctAnswers,
    required this.totalAnswers,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = totalAnswers > 0 ? (correctAnswers / totalAnswers * 100) : 0;
    final xpEarned = (lesson.xpReward * (correctAnswers / totalAnswers)).round();
    final isPerfect = correctAnswers == totalAnswers;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                      theme.colorScheme.primary,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  isPerfect ? Icons.star : Icons.check,
                  color: theme.colorScheme.onPrimary,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                isPerfect ? 'Perfect!' : 'Great Job!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                'Lesson Complete',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              
              // Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatItem(
                          icon: Icons.check_circle,
                          label: 'Correct',
                          value: '$correctAnswers/$totalAnswers',
                          color: Colors.green,
                        ),
                        _StatItem(
                          icon: Icons.percent,
                          label: 'Accuracy',
                          value: '${accuracy.round()}%',
                          color: theme.colorScheme.primary,
                        ),
                        _StatItem(
                          icon: Icons.star,
                          label: 'XP Earned',
                          value: '+$xpEarned',
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: InteractiveButton(
                  text: 'Continue Learning',
                  onPressed: onContinue,
                  style: InteractiveButtonStyle.primary,
                  enableSoundEffects: true,
                  enableHapticFeedback: true,
                ),
              ),
              const SizedBox(height: 8),
              
              // Secondary actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onContinue,
                      child: Text(
                        'Review Mistakes',
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: onContinue,
                      child: Text(
                        'Practice Again',
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
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
