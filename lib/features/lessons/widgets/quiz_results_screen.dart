import 'package:flutter/material.dart';
import 'package:sp/core/models/question.dart';
import 'package:sp/shared/widgets/interactive_button.dart';
import 'package:sp/shared/widgets/reward_collection_widget.dart';
import 'package:sp/shared/widgets/achievement_celebration_widget.dart';
import 'package:sp/theme.dart';

/// Quiz results screen showing all answers after completion
class QuizResultsScreen extends StatefulWidget {
  final List<Question> questions;
  final Map<String, String> selectedAnswers;
  final int correctAnswers;
  final int totalAnswers;
  final int coinsEarned;
  final int xpEarned;
  final VoidCallback onContinue;

  const QuizResultsScreen({
    super.key,
    required this.questions,
    required this.selectedAnswers,
    required this.correctAnswers,
    required this.totalAnswers,
    this.coinsEarned = 0,
    this.xpEarned = 0,
    required this.onContinue,
  });

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  bool _showRewards = false;

  @override
  void initState() {
    super.initState();
    // Show rewards after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showRewards = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (widget.correctAnswers / widget.totalAnswers * 100).round();
    final isPerfect = widget.correctAnswers == widget.totalAnswers;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Quiz Results'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(InteractiveDesign.mediumSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Score card
                Container(
                  padding: const EdgeInsets.all(InteractiveDesign.largeSpacing),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPerfect
                          ? [
                              LightModeColors.lightSuccess,
                              LightModeColors.lightSuccess.withOpacity(0.7),
                            ]
                          : percentage >= 70
                              ? [
                                  LightModeColors.lightInfo,
                                  LightModeColors.lightInfo.withOpacity(0.7),
                                ]
                              : [
                                  LightModeColors.lightWarning,
                                  LightModeColors.lightWarning.withOpacity(0.7),
                                ],
                    ),
                    borderRadius: BorderRadius.circular(InteractiveDesign.largeRadius),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isPerfect
                            ? Icons.emoji_events
                            : percentage >= 70
                                ? Icons.thumb_up
                                : Icons.school,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: InteractiveDesign.mediumSpacing),
                      Text(
                        isPerfect
                            ? 'Perfect Score!'
                            : percentage >= 70
                                ? 'Great Job!'
                                : 'Keep Learning!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: InteractiveDesign.smallSpacing),
                      Text(
                        '${widget.correctAnswers} / ${widget.totalAnswers} Correct',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: InteractiveDesign.tinySpacing),
                      Text(
                        '$percentage%',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: InteractiveDesign.largeSpacing),

                // Rewards section
                if (_showRewards && (widget.coinsEarned > 0 || widget.xpEarned > 0))
                  RewardCollectionWidget(
                    coins: widget.coinsEarned,
                    xp: widget.xpEarned,
                  ),

                const SizedBox(height: InteractiveDesign.largeSpacing),

                // Question review section
                Text(
                  'Review Your Answers',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: InteractiveDesign.mediumSpacing),

                ...widget.questions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final question = entry.value;
                  final selectedAnswer = widget.selectedAnswers[question.id];
                  final isCorrect = selectedAnswer == question.correctAnswer;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: InteractiveDesign.mediumSpacing),
                    child: _QuestionReviewCard(
                      questionNumber: index + 1,
                      question: question,
                      selectedAnswer: selectedAnswer,
                      isCorrect: isCorrect,
                    ),
                  );
                }),

                const SizedBox(height: InteractiveDesign.largeSpacing),

                // Continue button
                InteractiveButton(
                  text: 'Continue Learning',
                  onPressed: widget.onContinue,
                  style: InteractiveButtonStyle.primary,
                  enableSoundEffects: true,
                  enableHapticFeedback: true,
                ),

                const SizedBox(height: InteractiveDesign.largeSpacing),
              ],
            ),
          ),

          // Perfect score celebration
          if (isPerfect)
            Positioned.fill(
              child: AchievementCelebrationWidget(
                title: 'Perfect Score!',
                description: 'You answered all questions correctly!',
                icon: Icons.emoji_events,
                color: LightModeColors.lightSuccess,
              ),
            ),
        ],
      ),
    );
  }
}

/// Question review card showing answer feedback
class _QuestionReviewCard extends StatelessWidget {
  final int questionNumber;
  final Question question;
  final String? selectedAnswer;
  final bool isCorrect;

  const _QuestionReviewCard({
    required this.questionNumber,
    required this.question,
    required this.selectedAnswer,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(InteractiveDesign.mediumSpacing),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(InteractiveDesign.mediumRadius),
        border: Border.all(
          color: isCorrect
              ? LightModeColors.lightSuccess
              : LightModeColors.lightError,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(InteractiveDesign.smallSpacing),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? LightModeColors.lightSuccess.withOpacity(0.1)
                      : LightModeColors.lightError.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect
                      ? LightModeColors.lightSuccess
                      : LightModeColors.lightError,
                  size: 24,
                ),
              ),
              const SizedBox(width: InteractiveDesign.smallSpacing),
              Expanded(
                child: Text(
                  'Question $questionNumber',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: InteractiveDesign.mediumSpacing),

          // Question text
          Text(
            question.questionText,
            style: theme.textTheme.bodyLarge,
          ),

          const SizedBox(height: InteractiveDesign.mediumSpacing),

          // Your answer
          if (selectedAnswer != null) ...[
            Text(
              'Your Answer:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: InteractiveDesign.tinySpacing),
            Text(
              selectedAnswer ?? 'No answer',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isCorrect
                    ? LightModeColors.lightSuccess
                    : LightModeColors.lightError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          // Correct answer (if wrong)
          if (!isCorrect) ...[
            const SizedBox(height: InteractiveDesign.smallSpacing),
            Text(
              'Correct Answer:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: InteractiveDesign.tinySpacing),
            Text(
              question.correctAnswer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: LightModeColors.lightSuccess,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          // Explanation
          if (question.explanation != null && question.explanation!.isNotEmpty) ...[
            const SizedBox(height: InteractiveDesign.mediumSpacing),
            Container(
              padding: const EdgeInsets.all(InteractiveDesign.smallSpacing),
              decoration: BoxDecoration(
                color: LightModeColors.lightInfo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(InteractiveDesign.smallRadius),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: LightModeColors.lightInfo,
                  ),
                  const SizedBox(width: InteractiveDesign.smallSpacing),
                  Expanded(
                    child: Text(
                      question.explanation!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

