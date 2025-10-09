import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/services/progress_service.dart';
import 'package:sp/core/services/sound_manager_service.dart';
import 'package:sp/core/services/asset_service.dart';
import 'package:sp/features/lessons/lesson_screen.dart';
import 'package:sp/features/subjects/widgets/skill_tree.dart';
import 'package:sp/features/levels/level_selection_screen.dart';
import 'package:sp/screens/game_session_screen.dart';
import 'package:sp/shared/widgets/animated_background.dart';
import 'package:sp/shared/widgets/progress_ring.dart';
import '../../core/widgets/enhanced_lesson_widget.dart';

class SubjectScreen extends ConsumerWidget {
  final SubjectType subjectType;

  const SubjectScreen({super.key, required this.subjectType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(progressProvider.notifier);
    final subject = controller.subjectByType(subjectType);
    final theme = Theme.of(context);

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            subject.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                          theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _subjectIcon(subject.type, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Progress: ${subject.completedSkills}/${subject.totalSkills}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 1000),
                                  tween: Tween(
                                    begin: 0.0,
                                    end: subject.totalSkills == 0
                                        ? 0
                                        : subject.progressPercentage / 100,
                                  ),
                                  builder: (context, value, child) {
                                    return LinearProgressIndicator(
                                      value: value,
                                      backgroundColor: theme.colorScheme.outline
                                          .withValues(alpha: 0.3),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.primary,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ProgressRing(
                          progress: subject.totalSkills == 0
                              ? 0
                              : subject.progressPercentage / 100,
                          size: 50,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final unit = subject.units[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: SkillTree(
                      unit: unit,
                      onSkillTap: (skill) {
                        if (skill.isUnlocked) {
                          SoundManagerService.instance.playButtonClick();
                          // Navigate to Level Selection Screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LevelSelectionScreen(
                                subject: subject.type,
                                skillId: skill.id,
                                skillName: skill.name,
                              ),
                            ),
                          );
                        } else {
                          SoundManagerService.instance.playIncorrectAnswer();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Complete previous skills to unlock!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
                childCount: subject.units.length,
              ),
            ),
          ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }

  void _startGameMode(BuildContext context, SubjectType subjectType, Skill skill) {
    Navigator.pop(context); // Close the bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameSessionScreen(
          subject: subjectType,
          level: skill.crowns + 1, // Use skill progress as level (1-6)
          skillId: skill.id,
        ),
      ),
    );
  }

  void _showLessonsBottomSheet(
      BuildContext context, SubjectType subjectType, Skill skill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.school,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  skill.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  skill.description,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(
                              skill.maxCrowns,
                              (index) => Icon(
                                index < skill.crowns
                                    ? Icons.star
                                    : Icons.star_border,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Game Mode Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.secondary,
                              theme.colorScheme.secondary.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _startGameMode(context, subjectType, skill),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videogame_asset,
                                  color: theme.colorScheme.onSecondary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Game Mode - 7 Questions',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Practice Lessons',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: EnhancedLessonWidget(
                    skillId: skill.id,
                    skillName: skill.name,
                    subject: subjectType,
                    difficulty: 1, // Default difficulty since Skill doesn't have difficulty property
                    lessonCount: skill.lessons.length,
                    showProgress: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    onLessonTap: (lesson) {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LessonScreen(
                            lesson: lesson,
                            subjectType: subjectType,
                            skillId: skill.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _subjectIcon(SubjectType type, {double size = 24}) {
    return AssetService.getSubjectIcon(
      type,
      width: size,
      height: size,
      color: AssetService.getSubjectColor(type),
    );
  }
}
