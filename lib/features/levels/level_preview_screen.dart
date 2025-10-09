import 'package:flutter/material.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/services/unified_xp_service.dart';
import 'package:sp/screens/game_session_screen.dart';
import 'package:sp/features/question_types/question_type_demo_screen.dart';
import 'package:sp/features/flashcards/pre_game_flashcard_screen.dart';

/// Pre-game screen showing comprehensive level information
class LevelPreviewScreen extends StatefulWidget {
  final SubjectType subject;
  final int level;
  final String skillId;
  final String skillName;

  const LevelPreviewScreen({
    Key? key,
    required this.subject,
    required this.level,
    required this.skillId,
    required this.skillName,
  }) : super(key: key);

  @override
  State<LevelPreviewScreen> createState() => _LevelPreviewScreenState();
}

class _LevelPreviewScreenState extends State<LevelPreviewScreen> {
  final UnifiedXPService _progressionService = UnifiedXPService.getInstance();
  
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLevelData();
  }

  Future<void> _loadLevelData() async {
    setState(() => _isLoading = true);
    
    try {
      final analytics = await _progressionService.getLevelAnalytics(
        subject: widget.subject.name,
      );
      
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading level data: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getDifficultyForLevel() {
    if (widget.level <= 3) return 'Easy';
    if (widget.level <= 7) return 'Medium';
    return 'Hard';
  }

  Color _getDifficultyColor() {
    final difficulty = _getDifficultyForLevel();
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Map<String, int> _getQuestionTypeBreakdown() {
    // Distribute 7 questions across types based on level
    if (widget.level <= 3) {
      return {
        'Multiple Choice': 3,
        'True/False': 2,
        'Numeric Input': 2,
      };
    } else if (widget.level <= 7) {
      return {
        'Multiple Choice': 2,
        'Numeric Input': 2,
        'Fill in the Blank': 2,
        'True/False': 1,
      };
    } else {
      return {
        'Multiple Choice': 2,
        'Numeric Input': 1,
        'Fill in the Blank': 2,
        'Drag and Drop': 1,
        'Short Answer': 1,
      };
    }
  }

  Map<String, int> _getRewards() {
    final baseXP = 50 + (widget.level * 10);
    final coins = 10 + (widget.level * 2);
    final gems = widget.level >= 5 ? 2 : 1;
    
    return {
      'xp': baseXP,
      'coins': coins,
      'gems': gems,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficulty = _getDifficultyForLevel();
    final difficultyColor = _getDifficultyColor();
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Level ${widget.level}',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLevelHeader(theme, difficulty, difficultyColor),
                        const SizedBox(height: 24),
                        _buildDifficultyInfo(theme, difficulty, difficultyColor),
                        const SizedBox(height: 20),
                        _buildQuestionTypeBreakdown(theme),
                        const SizedBox(height: 20),
                        _buildRewardsPreview(theme),
                        const SizedBox(height: 20),
                        _buildScoringRules(theme),
                        const SizedBox(height: 20),
                        _buildPerformanceHistory(theme),
                        const SizedBox(height: 32),
                        _buildActionButtons(theme),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLevelHeader(ThemeData theme, String difficulty, Color difficultyColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            difficultyColor.withValues(alpha: 0.2),
            difficultyColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: difficultyColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: difficultyColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    '${widget.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.skillName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Level ${widget.level} - $difficulty',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getLevelDescription(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _getLevelDescription() {
    if (widget.level <= 3) {
      return 'Master the fundamentals with easy questions designed for beginners.';
    } else if (widget.level <= 7) {
      return 'Challenge yourself with medium difficulty questions that test your understanding.';
    } else {
      return 'Push your limits with advanced questions that require deep knowledge.';
    }
  }

  Widget _buildDifficultyInfo(ThemeData theme, String difficulty, Color difficultyColor) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.signal_cellular_alt, color: difficultyColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Difficulty: $difficulty',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: difficultyColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.quiz, size: 16),
                      const SizedBox(width: 4),
                      Text('7 Questions', style: theme.textTheme.bodySmall),
                      const SizedBox(width: 16),
                      const Icon(Icons.timer_off, size: 16),
                      const SizedBox(width: 4),
                      Text('No Time Limit', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionTypeBreakdown(ThemeData theme) {
    final breakdown = _getQuestionTypeBreakdown();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question Types',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...breakdown.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      _getQuestionTypeIcon(entry.key),
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  IconData _getQuestionTypeIcon(String type) {
    switch (type) {
      case 'Multiple Choice':
        return Icons.radio_button_checked;
      case 'True/False':
        return Icons.check_circle;
      case 'Numeric Input':
        return Icons.calculate;
      case 'Fill in the Blank':
        return Icons.edit;
      case 'Drag and Drop':
        return Icons.drag_indicator;
      case 'Short Answer':
        return Icons.text_fields;
      default:
        return Icons.help;
    }
  }

  Widget _buildRewardsPreview(ThemeData theme) {
    final rewards = _getRewards();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rewards',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRewardChip(Icons.star, '${rewards['xp']} XP', Colors.amber, theme),
                _buildRewardChip(Icons.monetization_on, '${rewards['coins']} Coins', Colors.yellow[700]!, theme),
                _buildRewardChip(Icons.diamond, '${rewards['gems']} Gems', Colors.blue, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardChip(IconData icon, String label, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoringRules(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scoring Rules',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildRuleItem('Correct Answer', '+10 points', Icons.check_circle, Colors.green, theme),
            _buildRuleItem('Passing Score', '5/7 correct (70%)', Icons.emoji_events, Colors.amber, theme),
            _buildRuleItem('Perfect Score Bonus', '+2 gems', Icons.diamond, Colors.blue, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceHistory(ThemeData theme) {
    final attempts = _analytics['gamesPlayed'] ?? 0;
    final bestScore = _analytics['bestScore'] ?? 0;
    final avgAccuracy = _analytics['averageAccuracy'] ?? 0.0;
    
    if (attempts == 0) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This level has not been attempted yet. Good luck!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Performance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Best Score', '$bestScore', Icons.emoji_events, theme),
                _buildStatItem('Accuracy', '${(avgAccuracy * 100).round()}%', Icons.percent, theme),
                _buildStatItem('Attempts', '$attempts', Icons.replay, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _startGame,
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text(
              'Start Game',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _previewQuestions,
            icon: const Icon(Icons.visibility),
            label: const Text('Preview Sample Questions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startGame() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreGameFlashcardScreen(
          subject: widget.subject,
          level: widget.level,
          skillId: widget.skillId,
          skillName: widget.skillName,
          onComplete: () async {
            final gameResult = await Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GameSessionScreen(
                  subject: widget.subject,
                  level: widget.level,
                  skillId: widget.skillId,
                ),
              ),
            );
            // Return the game result back through the navigation chain
            if (mounted) {
              Navigator.of(context).pop(gameResult);
            }
          },
        ),
      ),
    );

    // If level was completed, return true to level selection screen
    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _previewQuestions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuestionTypeDemoScreen(),
      ),
    );
  }
}

