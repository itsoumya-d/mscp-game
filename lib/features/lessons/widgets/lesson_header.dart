import 'package:flutter/material.dart';
import 'package:sp/shared/widgets/progress_ring.dart';
import 'package:sp/features/lessons/widgets/interactive_lesson_screen_wrapper.dart';
import 'package:sp/theme.dart';

class LessonHeader extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final double progress;

  const LessonHeader({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(InteractiveDesign.mediumSpacing),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ProgressRing(
            progress: progress,
            size: 50,
            strokeWidth: 6,
            child: Text(
              '$currentQuestion',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: InteractiveDesign.mediumSpacing),
          Expanded(
            child: InteractiveProgressBar(
              progress: progress,
              currentQuestion: currentQuestion,
              totalQuestions: totalQuestions,
            ),
          ),
        ],
      ),
    );
  }
}
