import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/services/sound_manager_service.dart';
import 'package:sp/features/subjects/widgets/skill_tree.dart';
import 'package:sp/features/lessons/lesson_screen.dart';
import 'package:sp/shared/widgets/animated_background.dart';
import 'package:sp/shared/widgets/progress_ring.dart';
import '../../core/widgets/enhanced_lesson_widget.dart';

final mathSubjectProvider = Provider<Subject>((ref) => const Subject(
      id: 'math',
      name: 'Mathematics',
      type: SubjectType.math,
      description: 'From basic arithmetic to advanced algebra',
      iconUrl: '',
      units: [
        Unit(
          id: 'arithmetic',
          name: 'Arithmetic Basics',
          description: 'Foundation of math with numbers',
          isUnlocked: true,
          skills: [
            Skill(
              id: 'addition',
              name: 'Addition & Subtraction',
              description: 'Learn to add and subtract numbers',
              crowns: 2,
              maxCrowns: 5,
              isUnlocked: true,
              lessons: [
                Lesson(
                  id: 'add_1',
                  title: 'Basic Addition',
                  description: 'Adding single-digit numbers',
                  xpReward: 10,
                  isCompleted: true,
                  questions: [],
                ),
                Lesson(
                  id: 'add_2',
                  title: 'Addition with Carrying',
                  description: 'Adding numbers with regrouping',
                  xpReward: 15,
                  isCompleted: true,
                  questions: [],
                ),
                Lesson(
                  id: 'sub_1',
                  title: 'Basic Subtraction',
                  description: 'Subtracting single-digit numbers',
                  xpReward: 10,
                  isCompleted: false,
                  questions: [],
                ),
              ],
            ),
            Skill(
              id: 'multiplication',
              name: 'Multiplication & Division',
              description: 'Master times tables and division',
              crowns: 1,
              maxCrowns: 5,
              isUnlocked: true,
              lessons: [
                Lesson(
                  id: 'mult_1',
                  title: 'Times Tables 1-5',
                  description: 'Learn multiplication tables 1 through 5',
                  xpReward: 15,
                  isCompleted: true,
                  questions: [],
                ),
                Lesson(
                  id: 'mult_2',
                  title: 'Times Tables 6-10',
                  description: 'Learn multiplication tables 6 through 10',
                  xpReward: 15,
                  isCompleted: false,
                  questions: [],
                ),
                Lesson(
                  id: 'div_1',
                  title: 'Basic Division',
                  description: 'Division with simple numbers',
                  xpReward: 20,
                  isCompleted: false,
                  questions: [],
                ),
              ],
            ),
            Skill(
              id: 'fractions',
              name: 'Fractions Fundamentals',
              description: 'Understanding parts of a whole',
              crowns: 0,
              maxCrowns: 5,
              isUnlocked: true,
              lessons: [
                Lesson(
                  id: 'frac_1',
                  title: 'What are Fractions?',
                  description: 'Introduction to fractions and parts',
                  xpReward: 10,
                  isCompleted: false,
                  questions: [],
                ),
                Lesson(
                  id: 'frac_2',
                  title: 'Comparing Fractions',
                  description: 'Which fraction is larger?',
                  xpReward: 15,
                  isCompleted: false,
                  questions: [],
                ),
              ],
            ),
          ],
        ),
        Unit(
          id: 'algebra',
          name: 'Algebra Introduction',
          description: 'Working with variables and expressions',
          isUnlocked: false,
          skills: [
            Skill(
              id: 'variables',
              name: 'Variables & Expressions',
              description: 'What is x? Working with unknowns',
              crowns: 0,
              maxCrowns: 5,
              isUnlocked: false,
              lessons: [],
            ),
          ],
        ),
      ],
      totalSkills: 24,
      completedSkills: 8,
    ));

class MathScreen extends ConsumerWidget {
  const MathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mathSubject = ref.watch(mathSubjectProvider);
    final theme = Theme.of(context);

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            mathSubject.name,
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
                          child: Icon(
                            Icons.calculate,
                            color: theme.colorScheme.onPrimary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Progress: ${mathSubject.completedSkills}/${mathSubject.totalSkills}',
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
                                    end: mathSubject.progressPercentage / 100,
                                  ),
                                  builder: (context, value, child) {
                                    return LinearProgressIndicator(
                                      value: value,
                                      backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.3),
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
                          progress: mathSubject.progressPercentage / 100,
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
                  final unit = mathSubject.units[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: SkillTree(
                      unit: unit,
                      onSkillTap: (skill) {
                        if (skill.isUnlocked) {
                          SoundManagerService.instance.playButtonClick();
                          _showLessonsBottomSheet(context, skill);
                        } else {
                          SoundManagerService.instance.playIncorrectAnswer();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Complete previous skills to unlock!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
                childCount: mathSubject.units.length,
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

  void _showLessonsBottomSheet(BuildContext context, Skill skill) {
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
                  child: Row(
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
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: List.generate(
                          skill.maxCrowns,
                          (index) => Icon(
                            index < skill.crowns ? Icons.star : Icons.star_border,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: EnhancedLessonWidget(
                    skillId: skill.id,
                    skillName: skill.name,
                    subject: SubjectType.math,
                    difficulty: null,
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
                            subjectType: SubjectType.math,
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
}
