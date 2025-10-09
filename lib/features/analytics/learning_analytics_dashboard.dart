import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sp/core/services/analytics/learning_analytics_service.dart';
import 'package:sp/features/analytics/progress_reports_screen.dart';
import 'package:sp/features/analytics/learning_insights_screen.dart';
import 'package:sp/features/analytics/benchmarking_screen.dart';
import 'package:sp/features/analytics/parent_teacher_portal_screen.dart';

/// Learning Analytics Dashboard - Task G1
/// Comprehensive analytics dashboard with charts and insights
class LearningAnalyticsDashboard extends StatefulWidget {
  final String userId;

  const LearningAnalyticsDashboard({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<LearningAnalyticsDashboard> createState() =>
      _LearningAnalyticsDashboardState();
}

class _LearningAnalyticsDashboardState
    extends State<LearningAnalyticsDashboard> {
  final _analyticsService = LearningAnalyticsService();
  UserAnalytics? _analytics;
  List<AccuracyDataPoint>? _accuracyTrends;
  List<TopicPerformance>? _strongTopics;
  List<TopicPerformance>? _weakTopics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    final analytics = await _analyticsService.getUserAnalytics(widget.userId);
    final trends = await _analyticsService.getAccuracyTrends(widget.userId);
    final strong = await _analyticsService.getStrongTopics(widget.userId);
    final weak = await _analyticsService.getWeakTopics(widget.userId);

    setState(() {
      _analytics = analytics;
      _accuracyTrends = trends;
      _strongTopics = strong;
      _weakTopics = weak;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildOverviewCards(),
            const SizedBox(height: 24),
            _buildQuickAccessCards(),
            const SizedBox(height: 24),
            _buildAccuracyTrendChart(),
            const SizedBox(height: 24),
            _buildStrongTopicsSection(),
            const SizedBox(height: 24),
            _buildWeakTopicsSection(),
            const SizedBox(height: 24),
            _buildTimeSpentChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More Analytics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildQuickAccessCard(
              'Progress Reports',
              Icons.assessment,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProgressReportsScreen(userId: widget.userId),
                ),
              ),
            ),
            _buildQuickAccessCard(
              'Learning Insights',
              Icons.psychology,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LearningInsightsScreen(userId: widget.userId),
                ),
              ),
            ),
            _buildQuickAccessCard(
              'Benchmarking',
              Icons.compare_arrows,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BenchmarkingScreen(userId: widget.userId),
                ),
              ),
            ),
            _buildQuickAccessCard(
              'Parent Portal',
              Icons.family_restroom,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ParentTeacherPortalScreen(studentId: widget.userId),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Time',
          '${_analytics!.totalTimeSpent.inHours}h ${_analytics!.totalTimeSpent.inMinutes % 60}m',
          Icons.access_time,
          Colors.blue,
        ),
        _buildStatCard(
          'Questions',
          '${_analytics!.totalQuestionsAnswered}',
          Icons.quiz,
          Colors.green,
        ),
        _buildStatCard(
          'Accuracy',
          '${(_analytics!.overallAccuracy * 100).toStringAsFixed(1)}%',
          Icons.check_circle,
          Colors.orange,
        ),
        _buildStatCard(
          'Streak',
          '${_analytics!.currentStreak} days',
          Icons.local_fire_department,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyTrendChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accuracy Trend (30 Days)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${(value * 100).toInt()}%');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 5 == 0) {
                            return Text('${value.toInt()}');
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _accuracyTrends!
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.accuracy))
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrongTopicsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Strong Topics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._strongTopics!.map((topic) => _buildTopicCard(topic, true)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakTopicsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Areas to Improve',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._weakTopics!.map((topic) => _buildTopicCard(topic, false)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(TopicPerformance topic, bool isStrong) {
    final color = isStrong ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            '${(topic.accuracy * 100).toInt()}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text('${topic.subject} - ${topic.topic}'),
        subtitle: Text(
          '${topic.questionsAnswered} questions • ${topic.masteryLevel.name}',
        ),
        trailing: Icon(
          isStrong ? Icons.check_circle : Icons.trending_up,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTimeSpentChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time by Subject',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 12.5,
                      title: 'Math\n12.5h',
                      color: Colors.blue,
                      radius: 80,
                    ),
                    PieChartSectionData(
                      value: 8.75,
                      title: 'Science\n8.75h',
                      color: Colors.green,
                      radius: 80,
                    ),
                    PieChartSectionData(
                      value: 6.25,
                      title: 'English\n6.25h',
                      color: Colors.orange,
                      radius: 80,
                    ),
                    PieChartSectionData(
                      value: 4.33,
                      title: 'History\n4.33h',
                      color: Colors.purple,
                      radius: 80,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

