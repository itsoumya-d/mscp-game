import 'package:flutter/material.dart';

/// Learning Style Assessment Screen
/// Helps users discover their optimal learning style through a questionnaire
class LearningStyleAssessmentScreen extends StatefulWidget {
  final String userId;

  const LearningStyleAssessmentScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<LearningStyleAssessmentScreen> createState() => _LearningStyleAssessmentScreenState();
}

class _LearningStyleAssessmentScreenState extends State<LearningStyleAssessmentScreen> {
  int _currentQuestionIndex = 0;
  final Map<String, int> _scores = {
    'visual': 0,
    'auditory': 0,
    'kinesthetic': 0,
    'reading': 0,
  };

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'When learning something new, I prefer to:',
      'options': [
        {'text': 'See diagrams and visual aids', 'style': 'visual'},
        {'text': 'Listen to explanations', 'style': 'auditory'},
        {'text': 'Try it hands-on', 'style': 'kinesthetic'},
        {'text': 'Read detailed instructions', 'style': 'reading'},
      ],
    },
    {
      'question': 'I remember information best when:',
      'options': [
        {'text': 'I can visualize it', 'style': 'visual'},
        {'text': 'I hear it repeated', 'style': 'auditory'},
        {'text': 'I practice doing it', 'style': 'kinesthetic'},
        {'text': 'I write it down', 'style': 'reading'},
      ],
    },
    {
      'question': 'When solving problems, I tend to:',
      'options': [
        {'text': 'Draw diagrams or charts', 'style': 'visual'},
        {'text': 'Talk through the problem', 'style': 'auditory'},
        {'text': 'Use trial and error', 'style': 'kinesthetic'},
        {'text': 'Make lists and notes', 'style': 'reading'},
      ],
    },
    {
      'question': 'In a classroom, I learn best when:',
      'options': [
        {'text': 'There are visual presentations', 'style': 'visual'},
        {'text': 'There are discussions', 'style': 'auditory'},
        {'text': 'There are activities and experiments', 'style': 'kinesthetic'},
        {'text': 'There are reading materials', 'style': 'reading'},
      ],
    },
    {
      'question': 'When I need to concentrate, I:',
      'options': [
        {'text': 'Need a clean, organized space', 'style': 'visual'},
        {'text': 'Need quiet or background music', 'style': 'auditory'},
        {'text': 'Need to move around or fidget', 'style': 'kinesthetic'},
        {'text': 'Need to take notes', 'style': 'reading'},
      ],
    },
  ];

  void _answerQuestion(String learningStyle) {
    setState(() {
      _scores[learningStyle] = _scores[learningStyle]! + 1;
      
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _showResults();
      }
    });
  }

  void _showResults() {
    final dominantStyle = _scores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Your Learning Style'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getStyleDescription(dominantStyle),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Recommendations:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _getRecommendations(dominantStyle),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _getStyleDescription(String style) {
    switch (style) {
      case 'visual':
        return 'You are a Visual Learner! You learn best through seeing and visualizing information.';
      case 'auditory':
        return 'You are an Auditory Learner! You learn best through listening and discussing.';
      case 'kinesthetic':
        return 'You are a Kinesthetic Learner! You learn best through hands-on activities and movement.';
      case 'reading':
        return 'You are a Reading/Writing Learner! You learn best through reading and writing.';
      default:
        return 'You have a balanced learning style!';
    }
  }

  String _getRecommendations(String style) {
    switch (style) {
      case 'visual':
        return '• Use diagrams and charts\n• Watch educational videos\n• Use color coding\n• Create mind maps';
      case 'auditory':
        return '• Listen to explanations\n• Discuss topics with others\n• Use audio recordings\n• Read aloud';
      case 'kinesthetic':
        return '• Practice hands-on activities\n• Take breaks to move\n• Use manipulatives\n• Try real-world applications';
      case 'reading':
        return '• Take detailed notes\n• Read extensively\n• Make lists and outlines\n• Write summaries';
      default:
        return '• Try different learning methods\n• Combine visual, auditory, and hands-on approaches';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Style Assessment'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          
          // Question counter
          Text(
            'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          
          // Question
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _questions[_currentQuestionIndex]['question'],
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Options
                  ...(_questions[_currentQuestionIndex]['options'] as List)
                      .map((option) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _answerQuestion(option['style']),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16.0),
                                  alignment: Alignment.centerLeft,
                                ),
                                child: Text(option['text']),
                              ),
                            ),
                          ))
                      .toList(),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}