import 'package:flutter/material.dart';
import 'package:sp/core/services/analytics/learning_insights_service.dart';

/// Learning Insights Screen - Optimal study times, patterns, and recommendations
class LearningInsightsScreen extends StatefulWidget {
  final String userId;

  const LearningInsightsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<LearningInsightsScreen> createState() => _LearningInsightsScreenState();
}

class _LearningInsightsScreenState extends State<LearningInsightsScreen> {
  final _insightsService = LearningInsightsService();
  LearningInsights? _insights;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);

    try {
      final insights = await _insightsService.generateInsights(widget.userId);

      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading insights: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInsights,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInsights,
              child: _buildInsightsView(),
            ),
    );
  }

  Widget _buildInsightsView() {
    if (_insights == null) {
      return const Center(child: Text('No insights available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        _buildHeaderCard(),
        const SizedBox(height: 16),

        // Optimal Study Time
        _buildOptimalStudyTimeCard(),
        const SizedBox(height: 16),

        // Learning Patterns
        _buildLearningPatternsCard(),
        const SizedBox(height: 16),

        // Study Streak
        _buildStudyStreakCard(),
        const SizedBox(height: 16),

        // Performance Trends
        _buildPerformanceTrendsCard(),
        const SizedBox(height: 16),

        // Personalized Recommendations
        _buildRecommendationsCard(),
        const SizedBox(height: 16),

        // Focus Areas
        _buildFocusAreasCard(),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, size: 32, color: Colors.purple),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Learning Insights',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Personalized analysis of your learning patterns',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimalStudyTimeCard() {
    final optimalTime = _insights!.optimalStudyTime;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Optimal Study Time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.wb_sunny, size: 48, color: Colors.orange),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTimeOfDay(optimalTime),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                        ),
                        Text(
                          'You perform best during this time',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Based on your accuracy and focus levels, we recommend studying during this time for maximum effectiveness.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningPatternsCard() {
    final patterns = _insights!.learningPatterns;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pattern, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Learning Patterns',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...patterns.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildStudyStreakCard() {
    final streak = _insights!.currentStreak;
    final longestStreak = _insights!.longestStreak;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Study Streak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStreakStat('Current', streak, Colors.orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStreakStat('Longest', longestStreak, Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakStat(String label, int days, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$days',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '$label Streak',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTrendsCard() {
    final trend = _insights!.performanceTrend;

    IconData trendIcon;
    Color trendColor;
    String trendText;

    if (trend > 0) {
      trendIcon = Icons.trending_up;
      trendColor = Colors.green;
      trendText = 'Improving';
    } else if (trend < 0) {
      trendIcon = Icons.trending_down;
      trendColor = Colors.red;
      trendText = 'Declining';
    } else {
      trendIcon = Icons.trending_flat;
      trendColor = Colors.orange;
      trendText = 'Stable';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Performance Trend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: trendColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(trendIcon, size: 48, color: trendColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trendText,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: trendColor,
                          ),
                        ),
                        Text(
                          '${(trend * 100).abs().toStringAsFixed(1)}% change',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
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

  Widget _buildRecommendationsCard() {
    final recommendations = _insights!.recommendations;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Personalized Recommendations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendations.map((rec) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.amber, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(rec)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusAreasCard() {
    final focusAreas = _insights!.focusAreas;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.center_focus_strong, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Focus Areas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Topics that need more attention:',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: focusAreas.map((area) {
                return Chip(
                  label: Text(area),
                  backgroundColor: Colors.red.shade50,
                  avatar: Icon(Icons.priority_high, size: 18, color: Colors.red),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour;
    if (hour < 12) {
      return '${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} AM';
    } else {
      return '${hour == 12 ? 12 : hour - 12}:${time.minute.toString().padLeft(2, '0')} PM';
    }
  }
}

