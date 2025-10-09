import 'package:flutter/material.dart';
import 'package:sp/core/services/content/practice_problem_generator.dart';

/// Infinite Practice Screen - Task F5
/// Endless practice mode with AI-generated problems
class InfinitePracticeScreen extends StatefulWidget {
  final String subject;
  final String topic;

  const InfinitePracticeScreen({
    Key? key,
    required this.subject,
    required this.topic,
  }) : super(key: key);

  @override
  State<InfinitePracticeScreen> createState() => _InfinitePracticeScreenState();
}

class _InfinitePracticeScreenState extends State<InfinitePracticeScreen> {
  final _generator = PracticeProblemGenerator();
  
  late PracticeProblem _currentProblem;
  DifficultyLevel _difficulty = DifficultyLevel.medium;
  int _questionsAnswered = 0;
  int _correctAnswers = 0;
  int _totalPoints = 0;
  String? _selectedAnswer;
  bool _showResult = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _generateNewProblem();
  }

  void _generateNewProblem() {
    setState(() {
      _currentProblem = _generator.generateProblem(
        subject: widget.subject,
        topic: widget.topic,
        difficulty: _difficulty,
      );
      _selectedAnswer = null;
      _showResult = false;
      _isCorrect = false;
    });
  }

  void _checkAnswer() {
    if (_selectedAnswer == null) return;

    setState(() {
      _isCorrect = _selectedAnswer == _currentProblem.correctAnswer;
      _showResult = true;
      _questionsAnswered++;
      
      if (_isCorrect) {
        _correctAnswers++;
        _totalPoints += _currentProblem.points;
        
        // Adaptive difficulty: increase if doing well
        if (_correctAnswers % 3 == 0 && _difficulty != DifficultyLevel.expert) {
          _difficulty = DifficultyLevel.values[_difficulty.index + 1];
        }
      } else {
        // Decrease difficulty if struggling
        if (_questionsAnswered % 3 == 0 && _difficulty != DifficultyLevel.easy) {
          _difficulty = DifficultyLevel.values[_difficulty.index - 1];
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject} - ${widget.topic}'),
        actions: [
          _buildStatsButton(),
        ],
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          _buildDifficultyIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuestionCard(),
                  const SizedBox(height: 24),
                  _buildOptionsGrid(),
                  if (_showResult) ...[
                    const SizedBox(height: 24),
                    _buildResultCard(),
                  ],
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStatsButton() {
    return IconButton(
      icon: const Icon(Icons.analytics),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => _buildStatsDialog(),
        );
      },
    );
  }

  Widget _buildStatsDialog() {
    final accuracy = _questionsAnswered > 0
        ? (_correctAnswers / _questionsAnswered * 100).toStringAsFixed(1)
        : '0.0';

    return AlertDialog(
      title: const Text('Practice Statistics'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatRow('Questions Answered', _questionsAnswered.toString()),
          _buildStatRow('Correct Answers', _correctAnswers.toString()),
          _buildStatRow('Accuracy', '$accuracy%'),
          _buildStatRow('Total Points', _totalPoints.toString()),
          _buildStatRow('Current Difficulty', _difficulty.displayName),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final accuracy = _questionsAnswered > 0
        ? _correctAnswers / _questionsAnswered
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip(
                Icons.check_circle,
                'Correct',
                _correctAnswers.toString(),
                Colors.green,
              ),
              _buildStatChip(
                Icons.cancel,
                'Wrong',
                (_questionsAnswered - _correctAnswers).toString(),
                Colors.red,
              ),
              _buildStatChip(
                Icons.star,
                'Points',
                _totalPoints.toString(),
                Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: accuracy,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              accuracy >= 0.8 ? Colors.green : accuracy >= 0.6 ? Colors.orange : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDifficultyIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Difficulty: '),
          Chip(
            label: Text(_difficulty.displayName),
            backgroundColor: _getDifficultyColor(),
          ),
          const Spacer(),
          Text(
            'Question ${_questionsAnswered + 1}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (_difficulty) {
      case DifficultyLevel.easy:
        return Colors.green.withOpacity(0.3);
      case DifficultyLevel.medium:
        return Colors.orange.withOpacity(0.3);
      case DifficultyLevel.hard:
        return Colors.red.withOpacity(0.3);
      case DifficultyLevel.expert:
        return Colors.purple.withOpacity(0.3);
    }
  }

  Widget _buildQuestionCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Question',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Chip(
                  label: Text('${_currentProblem.points} pts'),
                  backgroundColor: Colors.amber.withOpacity(0.3),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _currentProblem.questionText,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsGrid() {
    return Column(
      children: _currentProblem.options.map((option) {
        final isSelected = _selectedAnswer == option;
        final isCorrect = option == _currentProblem.correctAnswer;
        
        Color? backgroundColor;
        Color? borderColor;
        
        if (_showResult) {
          if (isCorrect) {
            backgroundColor = Colors.green.withOpacity(0.2);
            borderColor = Colors.green;
          } else if (isSelected && !isCorrect) {
            backgroundColor = Colors.red.withOpacity(0.2);
            borderColor = Colors.red;
          }
        } else if (isSelected) {
          backgroundColor = Theme.of(context).colorScheme.primaryContainer;
          borderColor = Theme.of(context).colorScheme.primary;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: _showResult ? null : () {
              setState(() {
                _selectedAnswer = option;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(
                  color: borderColor ?? Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (_showResult && isCorrect)
                    const Icon(Icons.check_circle, color: Colors.green),
                  if (_showResult && isSelected && !isCorrect)
                    const Icon(Icons.cancel, color: Colors.red),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultCard() {
    return Card(
      color: _isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isCorrect ? Icons.check_circle : Icons.cancel,
                  color: _isCorrect ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isCorrect ? 'Correct!' : 'Incorrect',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _isCorrect ? Colors.green : Colors.red,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Explanation:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(_currentProblem.explanation),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!_showResult) ...[
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedAnswer == null ? null : _checkAnswer,
                child: const Text('Check Answer'),
              ),
            ),
          ] else ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _generateNewProblem,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next Question'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

