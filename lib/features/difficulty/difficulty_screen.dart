import 'package:flutter/material.dart';
import '../../core/models/subject.dart';
import '../../core/services/progressive_difficulty_service.dart';


class DifficultyScreen extends StatefulWidget {
  const DifficultyScreen({super.key});

  @override
  State<DifficultyScreen> createState() => _DifficultyScreenState();
}

class _DifficultyScreenState extends State<DifficultyScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? _adaptiveSettings;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final analytics = await ProgressiveDifficultyService.getInstance().getDifficultyAnalytics();
    final settings = await ProgressiveDifficultyService.getInstance().getAdaptiveSettings();
      
      setState(() {
        _analytics = analytics;
        _adaptiveSettings = settings;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading difficulty data: $e')),
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
        title: const Text('Progressive Difficulty'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                  _buildOverviewCard(theme),
                  const SizedBox(height: 16),
                  _buildSubjectDifficultyCard(theme),
                  const SizedBox(height: 16),
                  _buildPerformanceAnalyticsCard(theme),
                  const SizedBox(height: 16),
                  _buildAdaptiveSettingsCard(theme),
                  const SizedBox(height: 16),
                  _buildRecommendationsCard(theme),
                  const SizedBox(height: 16),
                  _buildAPIUsageCard(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCard(ThemeData theme) {
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
                  'Adaptive Learning Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'The Progressive Difficulty System uses AI to adapt question difficulty based on your performance, ensuring optimal learning progression.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Manual difficulty adjustment with template-based content generation',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectDifficultyCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Current Difficulty Levels',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...SubjectType.values.map((subject) => 
              FutureBuilder<int>(
                future: ProgressiveDifficultyService.getInstance().getAdaptiveDifficulty(subject),
                builder: (context, snapshot) {
                  final difficulty = snapshot.data ?? 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          _getSubjectIcon(subject.name),
                          color: theme.colorScheme.outline,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject.name.toUpperCase(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: difficulty / 10.0,
                                backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getDifficultyColor(difficulty, theme),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(difficulty, theme).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Level $difficulty',
                            style: TextStyle(
                              color: _getDifficultyColor(difficulty, theme),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceAnalyticsCard(ThemeData theme) {
    if (_analytics == null) return const SizedBox.shrink();

    final questionsGenerated = _analytics!['questionsGenerated'] ?? 0;
    final bySubject = _analytics!['bySubject'] as Map<String, dynamic>? ?? {};
    final subjectPerformance = _analytics!['subjectPerformance'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'Performance Analytics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    theme,
                    'Questions Generated',
                    questionsGenerated.toString(),
                    Icons.quiz,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    theme,
                    'Subjects Active',
                    bySubject.length.toString(),
                    Icons.subject,
                  ),
                ),
              ],
            ),
            if (subjectPerformance.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Subject Performance',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ...subjectPerformance.entries.map((entry) {
                final performance = (entry.value as double) * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key.toUpperCase()),
                      Text(
                        '${performance.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: performance >= 70 ? Colors.green : 
                                 performance >= 50 ? Colors.orange : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdaptiveSettingsCard(ThemeData theme) {
    if (_adaptiveSettings == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Adaptive Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Adaptive Difficulty'),
              subtitle: const Text('Automatically adjust difficulty based on performance'),
              value: _adaptiveSettings!['enabled'] ?? true,
              onChanged: (value) async {
                final newSettings = Map<String, dynamic>.from(_adaptiveSettings!);
                newSettings['enabled'] = value;
                await ProgressiveDifficultyService.getInstance().updateAdaptiveSettings(newSettings);
                setState(() => _adaptiveSettings = newSettings);
              },
            ),
            SwitchListTile(
              title: const Text('Focus on Weak Areas'),
              subtitle: const Text('Generate more questions for struggling topics'),
              value: _adaptiveSettings!['focusOnWeakAreas'] ?? true,
              onChanged: (value) async {
                final newSettings = Map<String, dynamic>.from(_adaptiveSettings!);
                newSettings['focusOnWeakAreas'] = value;
                await ProgressiveDifficultyService.getInstance().updateAdaptiveSettings(newSettings);
                setState(() => _adaptiveSettings = newSettings);
              },
            ),
            SwitchListTile(
              title: const Text('Balance Question Types'),
              subtitle: const Text('Ensure variety in question formats'),
              value: _adaptiveSettings!['balanceQuestionTypes'] ?? true,
              onChanged: (value) async {
                final newSettings = Map<String, dynamic>.from(_adaptiveSettings!);
                newSettings['balanceQuestionTypes'] = value;
                await ProgressiveDifficultyService.getInstance().updateAdaptiveSettings(newSettings);
                setState(() => _adaptiveSettings = newSettings);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'AI Recommendations',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...SubjectType.values.take(2).map((subject) => 
              FutureBuilder<Map<String, dynamic>>(
                future: ProgressiveDifficultyService.getInstance().getAdaptiveRecommendations(subject),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  final recommendations = snapshot.data!;
                  final weakAreas = recommendations['weakAreas'] as List<String>? ?? [];
                  final nextMilestone = recommendations['nextMilestone'] as String? ?? '';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name.toUpperCase(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (weakAreas.isNotEmpty)
                          Text(
                            'Focus areas: ${weakAreas.join(', ')}',
                            style: theme.textTheme.bodySmall,
                          ),
                        if (nextMilestone.isNotEmpty)
                          Text(
                            'Next goal: $nextMilestone',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAPIUsageCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.api, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'Template-based Content Generation',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _getAPIUsageStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                
                final stats = snapshot.data!;
                final dailyUsage = stats['dailyUsage'] ?? 0;
                final remainingRequests = stats['remainingRequests'] ?? 0;
                final maxRequests = stats['maxDailyRequests'] ?? 100;
                
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            theme,
                            'Used Today',
                            dailyUsage.toString(),
                            Icons.today,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            theme,
                            'Remaining',
                            remainingRequests.toString(),
                            Icons.hourglass_empty,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: dailyUsage / maxRequests,
                      backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        dailyUsage / maxRequests > 0.8 ? Colors.red : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$dailyUsage / $maxRequests requests used today',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getAPIUsageStats() async {
    // Return default values since we're using procedural generation
    return {
      'dailyUsage': 0,
      'remainingRequests': 1000,
      'maxDailyRequests': 1000,
    };
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

  Color _getDifficultyColor(int difficulty, ThemeData theme) {
    if (difficulty <= 3) return Colors.green;
    if (difficulty <= 6) return Colors.orange;
    if (difficulty <= 8) return Colors.red;
    return Colors.purple;
  }
}