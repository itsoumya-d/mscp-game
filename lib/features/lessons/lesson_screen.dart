import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sp/core/models/question.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/services/progress_service.dart';
import 'package:sp/features/lessons/widgets/question_widget.dart';
import 'package:sp/features/lessons/widgets/lesson_header.dart';
import 'package:sp/features/lessons/widgets/lesson_complete_dialog.dart';
import 'package:sp/shared/widgets/interactive_button.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final Lesson lesson;
  final SubjectType subjectType;
  final String skillId;

  const LessonScreen({
    super.key,
    required this.lesson,
    required this.subjectType,
    required this.skillId,
  });

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;
  final Map<String, String> _selectedAnswers = {};
  int _correctAnswers = 0;
  int _totalAnswers = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleSkip() async {
    // Skip is now FREE - no gems required
    // This allows users to skip difficult questions without penalty
    final questions = widget.lesson.questions;
    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        // Do not change _totalAnswers or _correctAnswers on skip
        _currentQuestionIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Show helpful message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Question skipped. You can come back to it later!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Last question skipped: finish lesson without counting it
      ref.read(progressProvider.notifier).completeLesson(
            subject: widget.subjectType,
            skillId: widget.skillId,
            lesson: widget.lesson,
            correctAnswers: _correctAnswers,
            totalAnswers: _totalAnswers,
            context: context,
          );
      _showLessonCompleteDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.lesson.questions;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showExitDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          LessonHeader(
            currentQuestion: _currentQuestionIndex + 1,
            totalQuestions: questions.length,
            progress: (_currentQuestionIndex + 1) / questions.length,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: QuestionWidget(
                    question: question,
                    selectedAnswer: _selectedAnswers[question.id],
                    onAnswerSubmitted: (answer) {
                      setState(() {
                        _selectedAnswers[question.id] = answer;
                      });
                      _handleSubmit(question);
                    },
                    onHint: () async {
                      final ok = await ref.read(progressProvider.notifier).spendCoins(5);
                      if (!mounted) return;
                      if (!ok) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Not enough coins for a hint.')),
                          );
                        }
                      }
                    },
                    onSkip: () => _handleSkip(),
                  ),
                );
              },
            ),
          ),
          // Navigation buttons
          _buildNavigationButtons(theme, questions.length),
        ],
      ),
    );
  }

  void _handleSubmit(Question question) async {
    final selectedAnswer = _selectedAnswers[question.id];
    final questions = widget.lesson.questions;

    if (selectedAnswer == null) return;

    final isCorrect = selectedAnswer == question.correctAnswer;

    // Update stats
    setState(() {
      _totalAnswers++;
      if (isCorrect) {
        _correctAnswers++;
      }
    });

    if (!isCorrect) {
      await ref.read(progressProvider.notifier).loseLife();
      final lives = ref.read(progressProvider).user.lives;
      if (lives <= 0) {
        _showOutOfLivesDialog();
        return;
      }
    }

    // Show explanation dialog
    _showExplanationDialog(
      question,
      isCorrect,
      () {
        if (_currentQuestionIndex < questions.length - 1) {
          // Move to next question
          setState(() {
            _currentQuestionIndex++;
          });
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          // Lesson complete -> commit progress, then show dialog
          ref.read(progressProvider.notifier).completeLesson(
                subject: widget.subjectType,
                skillId: widget.skillId,
                lesson: widget.lesson,
                correctAnswers: _correctAnswers,
                totalAnswers: _totalAnswers,
                context: context,
              );
          _showLessonCompleteDialog();
        }
      },
    );
  }

  void _showOutOfLivesDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Out of Lives'),
        content: const Text('You\'re out of hearts. Refill with gems or come back later.'),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await ref.read(progressProvider.notifier).refillHeartsWithGems(cost: 10);
              if (!mounted) return;
              if (ok) {
                if (mounted) {
                  Navigator.pop(context); // close dialog
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Not enough gems to refill.')),
                  );
                }
              }
            },
            child: const Text('Refill (-10 gems)'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _showExplanationDialog(
      Question question, bool isCorrect, VoidCallback onContinue) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isCorrect ? theme.colorScheme.tertiary : theme.colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCorrect ? Icons.check : Icons.close,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCorrect ? 'Correct!' : 'Not quite right',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isCorrect ? theme.colorScheme.tertiary : theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              question.explanation,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: InteractiveButton(
                text: 'Continue',
                onPressed: () {
                  Navigator.pop(context);
                  onContinue();
                },
                style: InteractiveButtonStyle.primary,
                enableSoundEffects: true,
                enableHapticFeedback: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLessonCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LessonCompleteDialog(
        lesson: widget.lesson,
        correctAnswers: _correctAnswers,
        totalAnswers: _totalAnswers,
        onContinue: () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context); // Return to previous screen
        },
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Lesson?'),
        content: const Text('Your progress will be lost if you exit now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit lesson
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  /// Build navigation buttons for moving between questions
  Widget _buildNavigationButtons(ThemeData theme, int totalQuestions) {
    final canGoPrevious = _currentQuestionIndex > 0;
    final canGoNext = _currentQuestionIndex < totalQuestions - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canGoPrevious ? _handlePrevious : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: canGoPrevious
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Next button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canGoNext ? _handleNext : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: canGoNext
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePrevious() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleNext() {
    final questions = widget.lesson.questions;
    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
