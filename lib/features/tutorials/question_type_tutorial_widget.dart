import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../core/services/tutorial_service.dart';

/// Tutorial widget for demonstrating question types
/// Shows an interactive demo the first time user encounters each question type
class QuestionTypeTutorialWidget extends StatefulWidget {
  final String questionType;
  final Widget child;
  final VoidCallback? onComplete;

  const QuestionTypeTutorialWidget({
    super.key,
    required this.questionType,
    required this.child,
    this.onComplete,
  });

  @override
  State<QuestionTypeTutorialWidget> createState() =>
      _QuestionTypeTutorialWidgetState();
}

class _QuestionTypeTutorialWidgetState
    extends State<QuestionTypeTutorialWidget> {
  final _tutorialService = TutorialService();
  bool _shouldShowTutorial = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  Future<void> _checkTutorialStatus() async {
    final hasCompleted = await _tutorialService
        .hasShownTutorial('question_type_${widget.questionType}');
    
    setState(() {
      _shouldShowTutorial = !hasCompleted;
      _isLoading = false;
    });

    if (_shouldShowTutorial) {
      // Show tutorial after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showTutorialDialog();
        }
      });
    }
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildTutorialDialog(),
    );
  }

  Widget _buildTutorialDialog() {
    final tutorialInfo = _getTutorialInfo(widget.questionType);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tutorialInfo['color'].withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                tutorialInfo['icon'],
                size: 48,
                color: tutorialInfo['color'],
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              tutorialInfo['title'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              tutorialInfo['description'],
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'How to answer:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tutorialInfo['instructions'],
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _skipTutorial(context),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _completeTutorial(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tutorialInfo['color'],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Got it!'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getTutorialInfo(String questionType) {
    switch (questionType) {
      case 'multipleChoice':
        return {
          'title': 'Multiple Choice',
          'icon': Icons.radio_button_checked,
          'color': Colors.blue,
          'description':
              'Choose the correct answer from the options provided.',
          'instructions':
              '1. Read the question carefully\n2. Tap on the answer you think is correct\n3. Click Submit to check your answer',
        };
      case 'trueFalse':
        return {
          'title': 'True or False',
          'icon': Icons.check_circle,
          'color': Colors.green,
          'description': 'Decide if the statement is true or false.',
          'instructions':
              '1. Read the statement\n2. Tap True if correct, False if incorrect\n3. Click Submit',
        };
      case 'numericInput':
        return {
          'title': 'Numeric Input',
          'icon': Icons.numbers,
          'color': Colors.purple,
          'description': 'Type the correct number as your answer.',
          'instructions':
              '1. Calculate the answer\n2. Tap on the correct number\n3. Click Submit',
        };
      case 'fillInTheBlank':
        return {
          'title': 'Fill in the Blank',
          'icon': Icons.edit,
          'color': Colors.orange,
          'description': 'Complete the sentence with the right word.',
          'instructions':
              '1. Read the sentence\n2. Choose the word that fits best\n3. Click Submit',
        };
      case 'dragDrop':
        return {
          'title': 'Drag & Drop',
          'icon': Icons.drag_indicator,
          'color': Colors.teal,
          'description': 'Drag items to their correct positions.',
          'instructions':
              '1. Press and hold an item\n2. Drag it to the correct position\n3. Release to drop\n4. Click Submit when done',
        };
      case 'clickableAnswer':
        return {
          'title': 'Clickable Answer',
          'icon': Icons.touch_app,
          'color': Colors.pink,
          'description': 'Click on the correct part of the image or diagram.',
          'instructions':
              '1. Look at the image carefully\n2. Tap on the correct area\n3. Click Submit',
        };
      case 'shortAnswer':
        return {
          'title': 'Short Answer',
          'icon': Icons.keyboard,
          'color': Colors.indigo,
          'description': 'Type your answer in your own words.',
          'instructions':
              '1. Think about the answer\n2. Type your response\n3. Click Submit',
        };
      default:
        return {
          'title': 'Question',
          'icon': Icons.help,
          'color': Colors.grey,
          'description': 'Answer the question.',
          'instructions': 'Follow the instructions provided.',
        };
    }
  }

  Future<void> _completeTutorial(BuildContext context) async {
    await _tutorialService
        .markTutorialComplete('question_type_${widget.questionType}');
    if (context.mounted) {
      Navigator.of(context).pop();
      widget.onComplete?.call();
    }
  }

  Future<void> _skipTutorial(BuildContext context) async {
    await _tutorialService
        .markTutorialSkipped('question_type_${widget.questionType}');
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return widget.child;
  }
}

/// Helper function to wrap a question widget with tutorial
Widget withQuestionTypeTutorial({
  required String questionType,
  required Widget child,
  VoidCallback? onComplete,
}) {
  return QuestionTypeTutorialWidget(
    questionType: questionType,
    onComplete: onComplete,
    child: child,
  );
}

