import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sp/core/services/daily_content_service.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/models/question.dart';
import 'package:sp/features/lessons/lesson_screen.dart';

class DailyContentScreen extends ConsumerStatefulWidget {
  const DailyContentScreen({super.key});

  @override
  ConsumerState<DailyContentScreen> createState() => _DailyContentScreenState();
}

class _DailyContentScreenState extends ConsumerState<DailyContentScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _usageStats;
  Map<String, List<Map<String, dynamic>>>? _dailyContent;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final stats = await DailyContentService.getInstance().getUsageStats();
      final content = await DailyContentService.getInstance().getDailyContent();
      
      setState(() {
        _usageStats = stats;
        _dailyContent = content;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _forceRegenerate() async {
    setState(() => _isLoading = true);
    
    try {
      await DailyContentService.getInstance().forceRegenerateContent();
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily content regenerated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to regenerate: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Content'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _forceRegenerate,
            icon: const Icon(Icons.refresh),
            tooltip: 'Regenerate Content',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUsageStatsCard(theme),
                  const SizedBox(height: 16),
                  _buildDifficultyProgressCard(theme),
                  const SizedBox(height: 16),
                  _buildContentOverviewCard(theme),
                  const SizedBox(height: 16),
                  _buildSubjectContentCards(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildUsageStatsCard(ThemeData theme) {
    if (_usageStats == null) return const SizedBox.shrink();
    
    final stats = _usageStats!;
    final dailyUsage = stats['dailyUsage'] as int;
    final maxRequests = stats['maxDailyRequests'] as int;
    final remainingRequests = stats['remainingRequests'] as int;
    final hasContent = stats['hasDailyContent'] as bool;
    final lastGeneration = stats['lastGeneration'] as String?;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'API Usage Statistics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatRow('Daily Usage', '$dailyUsage / $maxRequests requests'),
            _buildStatRow('Remaining', '$remainingRequests requests'),
            _buildStatRow('Content Available', hasContent ? 'Yes' : 'No'),
            if (lastGeneration != null)
              _buildStatRow('Last Generation', lastGeneration),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: dailyUsage / maxRequests,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                dailyUsage / maxRequests > 0.8
                    ? Colors.red
                    : theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyProgressCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Difficulty Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, int>>(
              future: _getDifficultyProgress(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                
                final progress = snapshot.data!;
                return Column(
                  children: SubjectType.values.map((subject) {
                    final difficulty = progress[subject.name] ?? 1;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(subject.name.toUpperCase()),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Level $difficulty',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentOverviewCard(ThemeData theme) {
    if (_dailyContent == null) return const SizedBox.shrink();
    
    final totalLessons = _dailyContent!.values
        .fold<int>(0, (sum, lessons) => sum + lessons.length);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.library_books, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Content Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatRow('Total Lessons', '$totalLessons'),
            _buildStatRow('Subjects', '${_dailyContent!.length}'),
            _buildStatRow('Status', totalLessons > 0 ? 'Ready' : 'No Content'),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectContentCards(ThemeData theme) {
    if (_dailyContent == null || _dailyContent!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'No daily content available',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Content will be generated automatically using template-based generation.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject Content',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._dailyContent!.entries.map((entry) {
          final subjectName = entry.key;
          final lessons = entry.value;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              leading: Icon(
                _getSubjectIcon(subjectName),
                color: theme.colorScheme.primary,
              ),
              title: Text(
                subjectName.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${lessons.length} lessons available'),
              children: lessons.map((lesson) {
                final questions = lesson['questions'] as List<dynamic>;
                return ListTile(
                  title: Text(lesson['title'] as String),
                  subtitle: Text(lesson['description'] as String),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${questions.length} questions'),
                      Text('${lesson['xpReward']} XP'),
                    ],
                  ),
                  onTap: () async {
                    // Convert the lesson data to a proper Lesson object
                    final lessonObj = Lesson(
                      id: lesson['id'] as String? ?? '',
                      title: lesson['title'] as String,
                      description: lesson['description'] as String,
                      xpReward: lesson['xpReward'] as int? ?? 10,
                      isCompleted: lesson['isCompleted'] as bool? ?? false,
                      questions: (lesson['questions'] as List<dynamic>)
                          .map((q) => Question(
                                id: q['id'] as String? ?? '',
                                type: _parseQuestionType(q['type'] as String? ?? 'multipleChoice'),
                                questionText: q['questionText'] as String? ?? '',
                                options: (q['options'] as List<dynamic>?)
                                    ?.map((o) => o.toString()).toList() ?? [],
                                correctAnswer: q['correctAnswer'] as String? ?? '',
                                explanation: q['explanation'] as String? ?? 'No explanation provided.',
                                hint: q['hint'] as String?,
                                difficulty: q['difficulty'] as int? ?? 1,
                                subject: _getSubjectTypeFromName(subjectName),
                              ))
                          .toList(),
                    );

                    // Navigate to LessonScreen if lesson has questions
                    if (lessonObj.questions.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LessonScreen(
                            lesson: lessonObj,
                            subjectType: _getSubjectTypeFromName(subjectName),
                            skillId: 'daily_content_${subjectName.toLowerCase()}',
                          ),
                        ),
                      );
                    } else {
                      // Show dialog if no questions available
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('No Questions Available'),
                          content: const Text('This lesson does not have any questions yet. Please try again later.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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

  Future<Map<String, int>> _getDifficultyProgress() async {
    final Map<String, int> progress = {};
    for (final subject in SubjectType.values) {
      progress[subject.name] = await DailyContentService.getInstance().getSubjectDifficulty(subject);
    }
    return progress;
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

  SubjectType _getSubjectTypeFromName(String subjectName) {
    switch (subjectName.toLowerCase()) {
      case 'math':
        return SubjectType.math;
      case 'physics':
        return SubjectType.physics;
      case 'chemistry':
        return SubjectType.chemistry;
      case 'biology':
        return SubjectType.biology;
      default:
        return SubjectType.math;
    }
  }

  QuestionType _parseQuestionType(String typeString) {
    // Handle various string formats that might be used
    final normalizedType = typeString.toLowerCase().replaceAll('_', '').replaceAll('-', '');
    
    switch (normalizedType) {
      case 'multiplechoice':
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'truefalse':
      case 'true_false':
        return QuestionType.trueFalse;
      case 'numericinput':
      case 'numeric_input':
        return QuestionType.numericInput;
      case 'fillintheblank':
      case 'fill_in_blank':
      case 'fillinblank':
        return QuestionType.fillInTheBlank;
      case 'dragdrop':
      case 'drag_drop':
      case 'matching':
        return QuestionType.dragDrop;
      case 'clickableanswer':
      case 'clickable_answer':
        return QuestionType.clickableAnswer;
      case 'shortanswer':
      case 'short_answer':
        return QuestionType.shortAnswer;
      default:
        print('Unknown question type: $typeString, defaulting to multipleChoice');
        return QuestionType.multipleChoice;
    }
  }
}