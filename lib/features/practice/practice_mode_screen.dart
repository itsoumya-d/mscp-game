/// Practice mode screen for learning question types
/// 
/// This screen allows kids to practice each question type without pressure:
/// - No lives lost
/// - No score tracking
/// - Unlimited hints
/// - Can retry unlimited times
/// - Immediate feedback

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/question.dart';
import '../../core/services/tutorial_service.dart';
import '../../shared/widgets/tutorial_overlay.dart';
import '../../core/models/tutorial_content.dart';
import '../lessons/widgets/question_widget.dart';

/// Practice mode screen
class PracticeModeScreen extends ConsumerStatefulWidget {
  const PracticeModeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PracticeModeScreen> createState() => _PracticeModeScreenState();
}

class _PracticeModeScreenState extends ConsumerState<PracticeModeScreen> {
  int _currentQuestionTypeIndex = 0;
  bool _showingQuestion = false;
  String? _selectedAnswer;
  bool? _isCorrect;
  
  final List<QuestionType> _questionTypes = [
    QuestionType.multipleChoice,
    QuestionType.trueFalse,
    QuestionType.numericInput,
    QuestionType.fillInTheBlank,
    QuestionType.dragDrop,
    QuestionType.clickableAnswer,
    QuestionType.shortAnswer,
  ];
  
  final Map<QuestionType, bool> _completedTypes = {};

  @override
  void initState() {
    super.initState();
    _showTutorialIfNeeded();
  }

  Future<void> _showTutorialIfNeeded() async {
    final tutorialService = ref.read(tutorialServiceProvider);
    final hasShown = await tutorialService.hasShownTutorial('practice_mode');
    
    if (!hasShown && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await showTutorialOverlay(
          context,
          const Tutorial(
            id: 'practice_mode',
            name: 'Practice Mode',
            steps: [
              TutorialStep(
                id: 'welcome',
                title: 'Welcome to Practice Mode! 🎯',
                description: 'Here you can practice each question type without any pressure!',
                icon: '🎯',
              ),
              TutorialStep(
                id: 'no_pressure',
                title: 'No Lives, No Score! 😊',
                description: 'Take your time, use hints, and retry as many times as you want!',
                icon: '😊',
              ),
              TutorialStep(
                id: 'learn',
                title: 'Learn Each Type 📚',
                description: 'Practice all 7 question types to become a pro!',
                icon: '📚',
              ),
            ],
          ),
          onComplete: () {
            tutorialService.markTutorialComplete('practice_mode');
          },
        );
      }
    }
  }

  QuestionType get _currentQuestionType => _questionTypes[_currentQuestionTypeIndex];
  
  String _getQuestionTypeName(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True or False';
      case QuestionType.numericInput:
        return 'Number Answer';
      case QuestionType.fillInTheBlank:
        return 'Fill in the Blank';
      case QuestionType.dragDrop:
        return 'Drag and Drop';
      case QuestionType.clickableAnswer:
        return 'Select All That Apply';
      case QuestionType.shortAnswer:
        return 'Short Answer';
    }
  }
  
  String _getQuestionTypeIcon(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return '✅';
      case QuestionType.trueFalse:
        return '✓✗';
      case QuestionType.numericInput:
        return '123';
      case QuestionType.fillInTheBlank:
        return '___';
      case QuestionType.dragDrop:
        return '↔️';
      case QuestionType.clickableAnswer:
        return '☑️';
      case QuestionType.shortAnswer:
        return '✍️';
    }
  }
  
  Question _createPracticeQuestion(QuestionType type) {
    // Create simple practice questions for each type
    switch (type) {
      case QuestionType.multipleChoice:
        return Question(
          id: 'practice_mc',
          text: 'What is 2 + 2?',
          type: QuestionType.multipleChoice,
          options: ['3', '4', '5', '6'],
          correctAnswer: '4',
          explanation: 'Great job! 2 + 2 = 4',
          hint: 'Count on your fingers: 2... 3, 4!',
          difficulty: 1,
        );
      
      case QuestionType.trueFalse:
        return Question(
          id: 'practice_tf',
          text: 'The sun rises in the east.',
          type: QuestionType.trueFalse,
          options: ['True', 'False'],
          correctAnswer: 'True',
          explanation: 'Correct! The sun rises in the east every morning.',
          hint: 'Think about where you see the sun in the morning.',
          difficulty: 1,
        );
      
      case QuestionType.numericInput:
        return Question(
          id: 'practice_num',
          text: 'How many fingers do you have on one hand?',
          type: QuestionType.numericInput,
          correctAnswer: '5',
          explanation: 'Perfect! You have 5 fingers on each hand.',
          hint: 'Count the fingers on your hand!',
          difficulty: 1,
        );
      
      case QuestionType.fillInTheBlank:
        return Question(
          id: 'practice_fib',
          text: 'The sky is ___.',
          type: QuestionType.fillInTheBlank,
          correctAnswer: 'blue',
          explanation: 'Excellent! The sky is blue on a clear day.',
          hint: 'What color do you see when you look up on a sunny day?',
          difficulty: 1,
        );
      
      case QuestionType.dragDrop:
        return Question(
          id: 'practice_dd',
          text: 'Match the animals to their sounds:',
          type: QuestionType.dragDrop,
          options: ['LEFT:Dog|Cat|Cow', 'RIGHT:Bark|Meow|Moo'],
          correctAnswer: 'Dog:Bark,Cat:Meow,Cow:Moo',
          explanation: 'Great matching! You know your animal sounds!',
          hint: 'Think about what sound each animal makes.',
          difficulty: 1,
        );
      
      case QuestionType.clickableAnswer:
        return Question(
          id: 'practice_ca',
          text: 'Select all the fruits: (You can choose more than one!)',
          type: QuestionType.clickableAnswer,
          options: ['Apple', 'Carrot', 'Banana', 'Broccoli'],
          correctAnswer: 'Apple,Banana',
          explanation: 'Perfect! Apple and Banana are fruits. Carrot and Broccoli are vegetables.',
          hint: 'Fruits are usually sweet. Vegetables are not.',
          difficulty: 1,
        );
      
      case QuestionType.shortAnswer:
        return Question(
          id: 'practice_sa',
          text: 'What is your favorite color and why?',
          type: QuestionType.shortAnswer,
          correctAnswer: 'any',
          explanation: 'Great answer! There\'s no wrong answer for this question.',
          hint: 'Just write what you think! Any answer is correct.',
          difficulty: 1,
        );
    }
  }

  void _startPractice() {
    setState(() {
      _showingQuestion = true;
      _selectedAnswer = null;
      _isCorrect = null;
    });
  }

  void _onAnswerSubmitted(String answer, bool isCorrect) {
    setState(() {
      _selectedAnswer = answer;
      _isCorrect = isCorrect;
      if (isCorrect) {
        _completedTypes[_currentQuestionType] = true;
      }
    });
  }

  void _tryNextType() {
    if (_currentQuestionTypeIndex < _questionTypes.length - 1) {
      setState(() {
        _currentQuestionTypeIndex++;
        _showingQuestion = false;
        _selectedAnswer = null;
        _isCorrect = null;
      });
    } else {
      // All types completed!
      _showCompletionDialog();
    }
  }

  void _tryAgain() {
    setState(() {
      _selectedAnswer = null;
      _isCorrect = null;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Congratulations!'),
        content: const Text(
          'You\'ve practiced all question types! You\'re ready to play for real!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('I\'m Ready!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Mode 🎯'),
        backgroundColor: Colors.purple,
      ),
      body: _showingQuestion
          ? _buildQuestionView()
          : _buildTypeSelectionView(),
    );
  }

  Widget _buildTypeSelectionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Practice Question Types',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Try each question type to learn how they work!',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // List of question types
          ...List.generate(_questionTypes.length, (index) {
            final type = _questionTypes[index];
            final isCompleted = _completedTypes[type] ?? false;
            final isCurrent = index == _currentQuestionTypeIndex;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isCurrent ? Colors.purple.shade50 : null,
              child: ListTile(
                leading: Text(
                  _getQuestionTypeIcon(type),
                  style: const TextStyle(fontSize: 32),
                ),
                title: Text(
                  _getQuestionTypeName(type),
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isCompleted
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : isCurrent
                        ? const Icon(Icons.play_arrow, color: Colors.purple)
                        : const Icon(Icons.circle_outlined, color: Colors.grey),
              ),
            );
          }),
          
          const SizedBox(height: 32),
          
          // Start button
          ElevatedButton(
            onPressed: _startPractice,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Practice ${_getQuestionTypeName(_currentQuestionType)}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Done button (if all completed)
          if (_completedTypes.length == _questionTypes.length)
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'I\'m Ready to Play!',
                style: TextStyle(fontSize: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionView() {
    final question = _createPracticeQuestion(_currentQuestionType);
    
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.purple.shade50,
          child: Column(
            children: [
              Text(
                'Practicing: ${_getQuestionTypeName(_currentQuestionType)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No pressure! Take your time and use hints if you need help.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        // Question
        Expanded(
          child: QuestionWidget(
            question: question,
            onAnswerSubmitted: (answer) {
              setState(() {
                _selectedAnswer = answer;
              });
              final isCorrect = answer == question.correctAnswer;
              _onAnswerSubmitted(answer, isCorrect);
            },
            selectedAnswer: _selectedAnswer,
            canUseHint: true,
          ),
        ),
        
        // Bottom controls
        if (_isCorrect != null)
          Container(
            padding: const EdgeInsets.all(16),
            color: _isCorrect! ? Colors.green.shade50 : Colors.red.shade50,
            child: Column(
              children: [
                Text(
                  _isCorrect! ? '✅ Correct!' : '❌ Try Again!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _isCorrect! ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (!_isCorrect!)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _tryAgain,
                          child: const Text('Try Again'),
                        ),
                      ),
                    if (_isCorrect!) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _showingQuestion = false;
                            });
                          },
                          child: const Text('Back to List'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _tryNextType,
                          child: Text(
                            _currentQuestionTypeIndex < _questionTypes.length - 1
                                ? 'Next Type'
                                : 'Finish',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

