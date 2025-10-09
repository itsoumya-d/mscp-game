import 'package:flutter/material.dart';
import '../core/models/question.dart';
import '../core/models/subject.dart';
import '../core/services/game_save_service.dart';

class GameResultsScreen extends StatefulWidget {
  final GameSession session;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToMenu;

  const GameResultsScreen({
    Key? key,
    required this.session,
    required this.onPlayAgain,
    required this.onBackToMenu,
  }) : super(key: key);

  @override
  State<GameResultsScreen> createState() => _GameResultsScreenState();
}

class _GameResultsScreenState extends State<GameResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scoreController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutBack,
    ));
    
    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _scoreController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final correctAnswers = _calculateCorrectAnswers();
    final accuracy = correctAnswers / 7.0;
    final performance = _getPerformanceLevel(accuracy);
    final subjectColor = _getSubjectColor(widget.session.subject);

    return Scaffold(
      backgroundColor: subjectColor.withOpacity(0.05),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Header
                SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Performance icon
                      ScaleTransition(
                        scale: _scoreAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: subjectColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: subjectColor.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getPerformanceIcon(accuracy),
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Performance title
                      Text(
                        performance.title,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: subjectColor,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        performance.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Score card
                SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Final score
                        AnimatedBuilder(
                          animation: _scoreAnimation,
                          builder: (context, child) {
                            return Text(
                              '${(widget.session.score * _scoreAnimation.value).round()}',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: subjectColor,
                              ),
                            );
                          },
                        ),
                        
                        Text(
                          'Final Score',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Statistics
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              'Correct',
                              '$correctAnswers/7',
                              Icons.check_circle,
                              Colors.green,
                            ),
                            _buildStatItem(
                              'Accuracy',
                              '${(accuracy * 100).round()}%',
                              Icons.track_changes,
                              Colors.blue,
                            ),
                            _buildStatItem(
                              'Level',
                              widget.session.skillId ?? '1',
                              Icons.trending_up,
                              Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Question breakdown
                SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question Breakdown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        ...List.generate(7, (index) {
                          final question = widget.session.questions[index];
                          final userAnswer = index < widget.session.userAnswers.length
                              ? widget.session.userAnswers[index]
                              : '';
                          final isCorrect = _isAnswerCorrect(question, userAnswer);
                          
                          return _buildQuestionResult(
                            index + 1,
                            question,
                            userAnswer,
                            isCorrect,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Action buttons
                SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onPlayAgain,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Play Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: subjectColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.onBackToMenu,
                          icon: const Icon(Icons.home),
                          label: const Text('Back to Menu'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: subjectColor,
                            side: BorderSide(color: subjectColor),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionResult(int questionNumber, Question question, String userAnswer, bool isCorrect) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCorrect ? Colors.green[200]! : Colors.red[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$questionNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.questionText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isCorrect) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Correct: ${question.correctAnswer}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? Colors.green : Colors.red,
            size: 20,
          ),
        ],
      ),
    );
  }

  int _calculateCorrectAnswers() {
    int correct = 0;
    for (int i = 0; i < widget.session.questions.length && i < widget.session.userAnswers.length; i++) {
      if (_isAnswerCorrect(widget.session.questions[i], widget.session.userAnswers[i])) {
        correct++;
      }
    }
    return correct;
  }

  bool _isAnswerCorrect(Question question, String userAnswer) {
    final correctAnswer = question.correctAnswer.toLowerCase().trim();
    final userAnswerNormalized = userAnswer.toLowerCase().trim();
    
    switch (question.type) {
      case QuestionType.numericInput:
        final correctNum = double.tryParse(correctAnswer);
        final userNum = double.tryParse(userAnswerNormalized);
        if (correctNum != null && userNum != null) {
          return (correctNum - userNum).abs() < 0.01;
        }
        return correctAnswer == userAnswerNormalized;
      default:
        return correctAnswer == userAnswerNormalized;
    }
  }

  PerformanceLevel _getPerformanceLevel(double accuracy) {
    if (accuracy >= 0.9) {
      return PerformanceLevel(
        title: 'Excellent!',
        subtitle: 'Outstanding performance! You\'ve mastered this level.',
      );
    } else if (accuracy >= 0.7) {
      return PerformanceLevel(
        title: 'Great Job!',
        subtitle: 'Well done! You\'re making good progress.',
      );
    } else if (accuracy >= 0.5) {
      return PerformanceLevel(
        title: 'Good Effort!',
        subtitle: 'Keep practicing to improve your skills.',
      );
    } else {
      return PerformanceLevel(
        title: 'Keep Trying!',
        subtitle: 'Don\'t give up! Practice makes perfect.',
      );
    }
  }

  IconData _getPerformanceIcon(double accuracy) {
    if (accuracy >= 0.9) {
      return Icons.emoji_events;
    } else if (accuracy >= 0.7) {
      return Icons.thumb_up;
    } else if (accuracy >= 0.5) {
      return Icons.trending_up;
    } else {
      return Icons.school;
    }
  }

  Color _getSubjectColor(SubjectType subject) {
    switch (subject) {
      case SubjectType.math:
        return Colors.blue;
      case SubjectType.physics:
        return Colors.purple;
      case SubjectType.chemistry:
        return Colors.green;
      case SubjectType.biology:
        return Colors.orange;
      case SubjectType.science:
        return Colors.lightBlue;
      case SubjectType.english:
        return Colors.indigo;
      case SubjectType.history:
        return Colors.red;
      case SubjectType.geography:
        return Colors.brown;
      case SubjectType.art:
        return Colors.pink;
      case SubjectType.music:
        return Colors.deepPurple;
      case SubjectType.physicalEducation:
        return Colors.amber;
      case SubjectType.computerScience:
        return Colors.teal;
    }
  }
}

class PerformanceLevel {
  final String title;
  final String subtitle;

  PerformanceLevel({
    required this.title,
    required this.subtitle,
  });
}