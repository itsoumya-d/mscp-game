import 'package:flutter/material.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/shared/widgets/elevated_card.dart';
import 'package:sp/shared/widgets/progress_ring.dart';
import 'package:sp/shared/widgets/interactive_lesson_widget.dart';
import 'package:sp/core/services/sound_manager_service.dart';
import 'package:sp/core/services/asset_service.dart';
import 'package:sp/theme.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback? onTap;

  const SubjectCard({
    super.key,
    required this.subject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = subject.progressPercentage / 100;

    return InteractiveLessonWidget(
      enableSoundEffects: true,
      onTap: () {
        SoundManagerService.instance.playButtonClick();
        onTap?.call();
      },
      child: ElevatedCard(
        onTap: null, // Handled by InteractiveLessonWidget
        child: IntrinsicHeight(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ProgressRing(
                    progress: progress,
                    size: 60,
                    strokeWidth: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(InteractiveDesign.mediumRadius),
                      child: Image.network(
                        subject.iconUrl,
                        width: 35,
                        height: 35,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(17.5),
                          ),
                          child: AssetService.getSubjectIcon(
                            subject.type,
                            width: 20,
                            height: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subject.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Text(
                      subject.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(InteractiveDesign.smallRadius),
                    ),
                    child: Text(
                      '${subject.completedSkills}/${subject.totalSkills} skills',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }


}
