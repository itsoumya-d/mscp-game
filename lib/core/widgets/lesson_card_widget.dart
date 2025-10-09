import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/unified_lesson_service.dart';
import '../../features/lessons/lesson_screen.dart';
import '../../shared/widgets/interactive_button.dart';

/// Reusable lesson card widget that provides consistent UI and functionality
/// for displaying lessons with proper question-answering capabilities
class LessonCardWidget extends StatelessWidget {
  final Lesson lesson;
  final SubjectType subject;
  final String skillId;
  final bool isLocked;
  final VoidCallback? onTap;
  final bool showStats;
  final bool showProgress;
  final EdgeInsets? margin;

  const LessonCardWidget({
    Key? key,
    required this.lesson,
    required this.subject,
    required this.skillId,
    this.isLocked = false,
    this.onTap,
    this.showStats = true,
    this.showProgress = true,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Card(
        elevation: isLocked ? 1 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLocked ? null : _handleTap(context),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 12),
                _buildDescription(context),
                if (showStats) ...[
                  const SizedBox(height: 16),
                  _buildStats(context),
                ],
                if (showProgress && lesson.progress > 0) ...[
                  const SizedBox(height: 16),
                  _buildProgressBar(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildStatusIcon(context),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isLocked ? Colors.grey[600] : null,
                ),
              ),
              const SizedBox(height: 4),
              _buildSubtitle(context),
            ],
          ),
        ),
        if (!isLocked) _buildActionIcon(context),
      ],
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    IconData iconData;
    Color iconColor;
    Color backgroundColor;

    if (isLocked) {
      iconData = Icons.lock;
      iconColor = Colors.grey[600]!;
      backgroundColor = Colors.grey[200]!;
    } else if (lesson.isCompleted) {
      iconData = Icons.check_circle;
      iconColor = Colors.white;
      backgroundColor = Colors.green;
    } else if (lesson.progress > 0) {
      iconData = Icons.play_circle_filled;
      iconColor = Colors.white;
      backgroundColor = Colors.orange;
    } else {
      iconData = Icons.play_circle_outline;
      iconColor = Colors.white;
      backgroundColor = Theme.of(context).primaryColor;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: isLocked ? null : [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 28,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    String subtitle = '';
    if (lesson.isCompleted) {
      subtitle = 'Completed';
    } else if (lesson.progress > 0) {
      subtitle = 'In Progress (${(lesson.progress * 100).toInt()}%)';
    } else {
      subtitle = 'Not Started';
    }

    return Text(
      subtitle,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: isLocked ? Colors.grey[500] : Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildActionIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      lesson.description,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: isLocked ? Colors.grey[500] : Colors.grey[700],
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStats(BuildContext context) {
    return Row(
      children: [
        _buildStatChip(
          context,
          icon: Icons.quiz,
          label: '${lesson.questions.length} Questions',
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 12),
        _buildStatChip(
          context,
          icon: Icons.star,
          label: '${lesson.xpReward} XP',
          color: Colors.amber[700]!,
        ),
        const SizedBox(width: 12),
        _buildStatChip(
          context,
          icon: Icons.timer,
          label: '${lesson.estimatedDuration ?? 10} min',
          color: Colors.blue[600]!,
        ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLocked ? Colors.grey[200] : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isLocked ? Colors.grey[600] : color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isLocked ? Colors.grey[600] : color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '${(lesson.progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: lesson.progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
          minHeight: 6,
        ),
      ],
    );
  }

  VoidCallback? _handleTap(BuildContext context) {
    if (onTap != null) {
      return onTap;
    }

    return () {
      // Ensure lesson has questions before navigation
      if (lesson.questions.isEmpty) {
        _showNoQuestionsDialog(context);
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LessonScreen(
            lesson: lesson,
            subjectType: subject,
            skillId: skillId,
          ),
        ),
      );
    };
  }

  void _showNoQuestionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lesson Not Ready'),
        content: const Text(
          'This lesson is being prepared with questions. Please try again later.',
        ),
        actions: [
          InteractiveButton(
            text: 'OK',
            onPressed: () => Navigator.pop(context),
            style: InteractiveButtonStyle.primary,
            enableSoundEffects: true,
            enableHapticFeedback: true,
          ),
        ],
      ),
    );
  }
}

/// Extension to add progress tracking to Lesson model
extension LessonProgress on Lesson {
  double get progress {
    if (questions.isEmpty) return 0.0;
    // This would typically come from user progress data
    // For now, return based on completion status
    return isCompleted ? 1.0 : 0.0;
  }

  int? get estimatedDuration {
    // Estimate 1.5 minutes per question
    return questions.isEmpty ? null : (questions.length * 1.5).ceil();
  }
}