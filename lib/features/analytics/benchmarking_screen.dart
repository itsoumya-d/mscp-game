import 'package:flutter/material.dart';
import 'package:sp/core/services/analytics/benchmarking_service.dart';

/// Benchmarking Screen - Compare with peers and grade-level standards
class BenchmarkingScreen extends StatefulWidget {
  final String userId;

  const BenchmarkingScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<BenchmarkingScreen> createState() => _BenchmarkingScreenState();
}

class _BenchmarkingScreenState extends State<BenchmarkingScreen> {
  final _benchmarkingService = BenchmarkingService();
  BenchmarkData? _benchmarkData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBenchmarkData();
  }

  Future<void> _loadBenchmarkData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _benchmarkingService.getBenchmarkData(widget.userId);

      setState(() {
        _benchmarkData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading benchmark data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benchmarking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBenchmarkData,
              child: _buildBenchmarkView(),
            ),
    );
  }

  Widget _buildBenchmarkView() {
    if (_benchmarkData == null) {
      return const Center(child: Text('No benchmark data available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        _buildHeaderCard(),
        const SizedBox(height: 16),

        // Overall Comparison
        _buildOverallComparisonCard(),
        const SizedBox(height: 16),

        // Grade Level Standards
        _buildGradeLevelStandardsCard(),
        const SizedBox(height: 16),

        // Peer Comparison
        _buildPeerComparisonCard(),
        const SizedBox(height: 16),

        // Subject Comparisons
        _buildSubjectComparisonsCard(),
        const SizedBox(height: 16),

        // Percentile Ranking
        _buildPercentileRankingCard(),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.compare_arrows, size: 32, color: Colors.green),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Performance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Compared to peers and standards',
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

  Widget _buildOverallComparisonCard() {
    final userScore = _benchmarkData!.userOverallScore;
    final peerAverage = _benchmarkData!.peerAverageScore;
    final gradeStandard = _benchmarkData!.gradeStandardScore;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Comparison',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildComparisonBar('You', userScore, Colors.blue),
            const SizedBox(height: 12),
            _buildComparisonBar('Peer Average', peerAverage, Colors.orange),
            const SizedBox(height: 12),
            _buildComparisonBar('Grade Standard', gradeStandard, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonBar(String label, double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '${(score * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: score,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildGradeLevelStandardsCard() {
    final standards = _benchmarkData!.gradeLevelStandards;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Grade Level Standards',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...standards.entries.map((entry) {
              final subject = entry.key;
              final standard = entry.value;
              final userScore = _benchmarkData!.subjectScores[subject] ?? 0.0;
              final meetsStandard = userScore >= standard.standard;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: meetsStandard
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      meetsStandard ? Icons.check_circle : Icons.warning,
                      color: meetsStandard ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Your score: ${(userScore * 100).toStringAsFixed(0)}% | Standard: ${(standard.standard * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
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

  Widget _buildPeerComparisonCard() {
    final peerComparison = _benchmarkData!.peerComparison;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Peer Comparison',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPeerStat(
                    'Better Than',
                    '${(peerComparison['betterThan'] ?? 0.0).toStringAsFixed(0)}%',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPeerStat(
                    'Similar To',
                    '${(peerComparison['similarTo'] ?? 0.0).toStringAsFixed(0)}%',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPeerStat(
                    'Behind',
                    '${(peerComparison['behind'] ?? 0.0).toStringAsFixed(0)}%',
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeerStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectComparisonsCard() {
    final subjectScores = _benchmarkData!.subjectScores;
    final peerAverages = _benchmarkData!.subjectPeerAverages;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject Comparisons',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...subjectScores.entries.map((entry) {
              final subject = entry.key;
              final userScore = entry.value;
              final peerAverage = peerAverages[subject] ?? 0.0;
              final difference = userScore - peerAverage;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          subject,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Icon(
                              difference >= 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                              color: difference >= 0 ? Colors.green : Colors.red,
                            ),
                            Text(
                              '${difference >= 0 ? '+' : ''}${(difference * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: difference >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Stack(
                      children: [
                        LinearProgressIndicator(
                          value: peerAverage,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.orange,
                          ),
                          minHeight: 8,
                        ),
                        LinearProgressIndicator(
                          value: userScore,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                          minHeight: 8,
                        ),
                      ],
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

  Widget _buildPercentileRankingCard() {
    final percentile = _benchmarkData!.overallPercentile;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Percentile Ranking',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    '${percentile.toStringAsFixed(0)}th',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  Text(
                    'Percentile',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re performing better than ${percentile.toStringAsFixed(0)}% of students',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Benchmarking'),
        content: const Text(
          'Benchmarking compares your performance with:\n\n'
          '• Peer Average: Students in your grade level\n'
          '• Grade Standards: Expected proficiency levels\n'
          '• Percentile: Your ranking among all students\n\n'
          'This helps you understand where you stand and identify areas for improvement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

