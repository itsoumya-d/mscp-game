import 'package:flutter/material.dart';
import '../../core/models/subject.dart';
import '../../core/models/question.dart';
import '../lessons/widgets/question_widget.dart';
import '../../shared/widgets/interactive_button.dart';

class QuestionTypeDemoScreen extends StatefulWidget {
  const QuestionTypeDemoScreen({super.key});

  @override
  State<QuestionTypeDemoScreen> createState() => _QuestionTypeDemoScreenState();
}

class _QuestionTypeDemoScreenState extends State<QuestionTypeDemoScreen> {
  int _currentQuestionIndex = 0;
  final PageController _pageController = PageController();

  final List<Question> _demoQuestions = [
    // Multiple Choice Question
    Question(
      id: 'demo_mc_1',
      questionText: 'What is the derivative of x²?',
      type: QuestionType.multipleChoice,
      options: ['2x', 'x', '2', 'x²'],
      correctAnswer: '2x',
      explanation: 'Using the power rule: d/dx(x²) = 2x¹ = 2x',
      difficulty: 3,
      subject: SubjectType.math,
    ),
    
    // True/False Question
    Question(
      id: 'demo_tf_1',
      questionText: 'The speed of light in vacuum is approximately 3 × 10⁸ m/s.',
      type: QuestionType.trueFalse,
      options: ['True', 'False'],
      correctAnswer: 'True',
      explanation: 'The speed of light in vacuum is exactly 299,792,458 m/s, which is approximately 3 × 10⁸ m/s.',
      difficulty: 2,
      subject: SubjectType.physics,
    ),
    
    // Numeric Input Question
    Question(
      id: 'demo_ni_1',
      questionText: 'Calculate the area of a circle with radius 5 cm. (Use π ≈ 3.14)',
      type: QuestionType.numericInput,
      options: [],
      correctAnswer: '78.5',
      explanation: 'Area = πr² = 3.14 × 5² = 3.14 × 25 = 78.5 cm²',
      difficulty: 3,
      subject: SubjectType.math,
    ),
    
    // Fill in the Blank Question
    Question(
      id: 'demo_fib_1',
      questionText: 'The chemical formula for water is ___.',
      type: QuestionType.fillInTheBlank,
      options: [],
      correctAnswer: 'H2O',
      explanation: 'Water consists of two hydrogen atoms and one oxygen atom, hence H₂O.',
      difficulty: 1,
      subject: SubjectType.chemistry,
    ),
    
    // Drag and Drop (Match) Question
    Question(
      id: 'demo_dd_1',
      questionText: 'Match the organelles with their functions:',
      type: QuestionType.dragDrop,
      options: [
        'LEFT:Mitochondria|Nucleus|Ribosomes|Chloroplasts',
        'RIGHT:Energy production|Controls cell activities|Protein synthesis|Photosynthesis',
      ],
      correctAnswer: 'Mitochondria:Energy production;Nucleus:Controls cell activities;Ribosomes:Protein synthesis;Chloroplasts:Photosynthesis',
      explanation: 'Each organelle has a specific function in the cell.',
      difficulty: 4,
      subject: SubjectType.biology,
    ),
    
    // Clickable Answer Question
    Question(
      id: 'demo_ca_1',
      questionText: 'Click on the element that is a noble gas:',
      type: QuestionType.clickableAnswer,
      options: ['Oxygen', 'Helium', 'Carbon', 'Sodium'],
      correctAnswer: 'Helium',
      explanation: 'Helium is a noble gas in Group 18 of the periodic table.',
      difficulty: 2,
      subject: SubjectType.chemistry,
    ),
    
    // Short Answer Question
    Question(
      id: 'demo_sa_1',
      questionText: 'Explain Newton\'s First Law of Motion in your own words.',
      type: QuestionType.shortAnswer,
      options: [],
      correctAnswer: 'An object at rest stays at rest and an object in motion stays in motion unless acted upon by an external force.',
      explanation: 'Newton\'s First Law, also known as the Law of Inertia, states that objects resist changes in their state of motion.',
      difficulty: 4,
      subject: SubjectType.physics,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Types Demo'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${_demoQuestions.length}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getQuestionTypeLabel(_demoQuestions[_currentQuestionIndex].type),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _demoQuestions.length,
                  backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ],
            ),
          ),
          
          // Question content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentQuestionIndex = index;
                });
              },
              itemCount: _demoQuestions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getQuestionTypeColor(_demoQuestions[index].type).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _getQuestionTypeLabel(_demoQuestions[index].type),
                              style: TextStyle(
                                color: _getQuestionTypeColor(_demoQuestions[index].type),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Subject and difficulty info
                          Row(
                            children: [
                              Icon(
                                _getSubjectIcon(_demoQuestions[index].subject.name),
                                size: 16,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _demoQuestions[index].subject.name.toUpperCase(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.star,
                                size: 16,
                                color: _getDifficultyColor(_demoQuestions[index].difficulty),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Level ${_demoQuestions[index].difficulty}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _getDifficultyColor(_demoQuestions[index].difficulty),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Question widget
                          Expanded(
                            child: QuestionWidget(
                              question: _demoQuestions[index],
                              selectedAnswer: null,
                              onAnswerSubmitted: (answer) {
                                _showAnswerFeedback(true, _demoQuestions[index]);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),
                ElevatedButton.icon(
                  onPressed: _currentQuestionIndex < _demoQuestions.length - 1 ? _nextQuestion : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _demoQuestions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showAnswerFeedback(bool isCorrect, Question question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(isCorrect ? 'Correct!' : 'Incorrect'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCorrect) ...[
              Text('Correct answer: ${question.correctAnswer}'),
              const SizedBox(height: 8),
            ],
            Text('Explanation:'),
            const SizedBox(height: 4),
            Text(
              question.explanation,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Question Types Demo'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This demo showcases all the question types supported by the app:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• Multiple Choice - Select the correct option'),
              Text('• True/False - Choose true or false'),
              Text('• Numeric Input - Enter a numerical answer'),
              Text('• Fill in the Blank - Complete the sentence'),
              Text('• Drag & Drop - Match items by dragging'),
              Text('• Clickable Answer - Click on the correct element'),
              Text('• Short Answer - Provide a written response'),
              SizedBox(height: 12),
              Text(
                'Each question type is generated using AI and adapts to your learning progress.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          InteractiveButton(
            text: 'Got it',
            onPressed: () => Navigator.of(context).pop(),
            style: InteractiveButtonStyle.primary,
            enableSoundEffects: true,
            enableHapticFeedback: true,
          ),
        ],
      ),
    );
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True/False';
      case QuestionType.numericInput:
        return 'Numeric Input';
      case QuestionType.fillInTheBlank:
        return 'Fill in the Blank';
      case QuestionType.dragDrop:
        return 'Drag & Drop';
      case QuestionType.clickableAnswer:
        return 'Clickable Answer';
      case QuestionType.shortAnswer:
        return 'Short Answer';
    }
  }

  Color _getQuestionTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return Colors.blue;
      case QuestionType.trueFalse:
        return Colors.green;
      case QuestionType.numericInput:
        return Colors.orange;
      case QuestionType.fillInTheBlank:
        return Colors.purple;
      case QuestionType.dragDrop:
        return Colors.red;
      case QuestionType.clickableAnswer:
        return Colors.teal;
      case QuestionType.shortAnswer:
        return Colors.indigo;
      default:
        return Colors.grey; // Default color for unknown types
    }
  }

  IconData _getSubjectIcon(String subjectName) {
    switch (subjectName.toLowerCase()) {
      case 'math':
        return Icons.calculate;
      case 'physics':
        return Icons.science;
      case 'chemistry':
        return Icons.biotech;
      case 'biology':
        return Icons.eco;
      default:
        return Icons.book;
    }
  }

  Color _getDifficultyColor(int difficulty) {
    if (difficulty <= 2) return Colors.green;
    if (difficulty <= 4) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}