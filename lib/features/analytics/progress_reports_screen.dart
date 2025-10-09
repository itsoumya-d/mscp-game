import 'package:flutter/material.dart';
import 'package:sp/core/services/analytics/progress_report_service.dart';

/// Progress Reports Screen - Weekly/Monthly reports with PDF export
class ProgressReportsScreen extends StatefulWidget {
  final String userId;

  const ProgressReportsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ProgressReportsScreen> createState() => _ProgressReportsScreenState();
}

class _ProgressReportsScreenState extends State<ProgressReportsScreen> {
  final _reportService = ProgressReportService();
  ProgressReport? _weeklyReport;
  ProgressReport? _monthlyReport;
  bool _isLoading = true;
  String _selectedPeriod = 'weekly';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final weekly = await _reportService.generateWeeklyReport(widget.userId);
      final monthly = await _reportService.generateMonthlyReport(widget.userId);

      setState(() {
        _weeklyReport = weekly;
        _monthlyReport = monthly;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _isLoading ? null : _exportToPDF,
            tooltip: 'Export to PDF',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _isLoading ? null : _shareReport,
            tooltip: 'Share Report',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildPeriodSelector(),
                Expanded(
                  child: _selectedPeriod == 'weekly'
                      ? _buildReportView(_weeklyReport)
                      : _buildReportView(_monthlyReport),
                ),
              ],
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'weekly',
                  label: Text('Weekly'),
                  icon: Icon(Icons.calendar_view_week),
                ),
                ButtonSegment(
                  value: 'monthly',
                  label: Text('Monthly'),
                  icon: Icon(Icons.calendar_month),
                ),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedPeriod = newSelection.first;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportView(ProgressReport? report) {
    if (report == null) {
      return const Center(child: Text('No report available'));
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          _buildHeaderCard(report),
          const SizedBox(height: 16),

          // Summary Stats
          _buildSummaryStats(report),
          const SizedBox(height: 16),

          // Subject Performance
          _buildSectionTitle('Subject Performance'),
          const SizedBox(height: 12),
          ...report.subjectPerformance.entries.map(
            (entry) => _buildSubjectCard(entry.key, entry.value),
          ),
          const SizedBox(height: 16),

          // Achievements
          if (report.achievementsEarned.isNotEmpty) ...[
            _buildSectionTitle('Achievements Earned'),
            const SizedBox(height: 12),
            _buildAchievementsSection(report.achievementsEarned),
            const SizedBox(height: 16),
          ],

          // Recommendations
          if (report.recommendations.isNotEmpty) ...[
            _buildSectionTitle('Recommendations'),
            const SizedBox(height: 12),
            ...report.recommendations.map(
              (rec) => _buildRecommendationCard(rec),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCard(ProgressReport report) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedPeriod == 'weekly' ? 'Weekly' : 'Monthly'} Report',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${report.startDate.toString().split(' ')[0]} - ${report.endDate.toString().split(' ')[0]}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats(ProgressReport report) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Time',
            '${(report.totalTimeSpent.inMinutes / 60).toStringAsFixed(1)}h',
            Icons.access_time,
            Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Questions',
            '${report.questionsAnswered}',
            Icons.quiz,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Accuracy',
            '${(report.averageAccuracy * 100).toStringAsFixed(0)}%',
            Icons.check_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildSubjectCard(String subject, SubjectPerformance performance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAccuracyColor(performance.accuracy).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(performance.accuracy * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getAccuracyColor(performance.accuracy),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: performance.accuracy,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getAccuracyColor(performance.accuracy),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${performance.questionsAnswered} questions',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  '${(performance.timeSpent / 60).toStringAsFixed(0)} min',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(List<String> achievements) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: achievements.map((achievement) {
            return Chip(
              avatar: const Icon(Icons.emoji_events, size: 18),
              label: Text(achievement),
              backgroundColor: Colors.amber.shade50,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(String recommendation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lightbulb, color: Colors.blue),
        ),
        title: Text(recommendation),
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Future<void> _exportToPDF() async {
    try {
      final report = _selectedPeriod == 'weekly' ? _weeklyReport : _monthlyReport;
      if (report == null) return;

      final pdfBytes = await _reportService.exportToPDF(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exported successfully (${pdfBytes.length} bytes)'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Open PDF viewer
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    }
  }

  Future<void> _shareReport() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share functionality coming soon!')),
      );
    }
  }
}

