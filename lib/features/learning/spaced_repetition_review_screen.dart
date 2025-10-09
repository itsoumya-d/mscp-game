import 'package:flutter/material.dart';

/// Spaced Repetition Review Screen
/// Implements spaced repetition algorithm for optimal learning retention
class SpacedRepetitionReviewScreen extends StatefulWidget {
  final String userId;

  const SpacedRepetitionReviewScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<SpacedRepetitionReviewScreen> createState() => _SpacedRepetitionReviewScreenState();
}

class _SpacedRepetitionReviewScreenState extends State<SpacedRepetitionReviewScreen> {
  List<ReviewItem> _dueReviews = [];
  List<ReviewItem> _upcomingReviews = [];
  int _reviewStreak = 7;
  double _retentionRate = 0.85;

  @override
  void initState() {
    super.initState();
    _loadReviewData();
  }

  void _loadReviewData() {
    // Mock data - in real app, this would come from a service
    setState(() {
      _dueReviews = [
        ReviewItem(
          id: '1',
          question: 'What is 2 + 2?',
          subject: 'Math',
          difficulty: 1,
          lastReviewed: DateTime.now().subtract(const Duration(days: 1)),
          nextReview: DateTime.now(),
          interval: 1,
          easeFactor: 2.5,
        ),
        ReviewItem(
          id: '2',
          question: 'What is the capital of France?',
          subject: 'Geography',
          difficulty: 2,
          lastReviewed: DateTime.now().subtract(const Duration(days: 3)),
          nextReview: DateTime.now(),
          interval: 3,
          easeFactor: 2.3,
        ),
      ];

      _upcomingReviews = [
        ReviewItem(
          id: '3',
          question: 'What is photosynthesis?',
          subject: 'Science',
          difficulty: 3,
          lastReviewed: DateTime.now().subtract(const Duration(days: 2)),
          nextReview: DateTime.now().add(const Duration(days: 1)),
          interval: 7,
          easeFactor: 2.8,
        ),
      ];
    });
  }

  void _startReviewSession() {
    if (_dueReviews.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No reviews due at this time!'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Review Session'),
        content: Text('You have ${_dueReviews.length} items to review. Ready to start?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _conductReview();
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _conductReview() {
    // Mock review session - in real app, this would navigate to a review screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Complete!'),
        content: const Text('Great job! You\'ve completed your review session.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _dueReviews.clear();
                _reviewStreak++;
              });
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spaced Repetition'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Review Streak',
                    '$_reviewStreak days',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Retention Rate',
                    '${(_retentionRate * 100).toInt()}%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Due Reviews Section
            Text(
              'Due for Review',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            if (_dueReviews.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: Colors.green[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'All caught up!',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No reviews due at this time. Check back later!',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  ..._dueReviews.map((review) => _buildReviewCard(review, true)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startReviewSession,
                      icon: const Icon(Icons.play_arrow),
                      label: Text('Start Review Session (${_dueReviews.length} items)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16.0),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 32),

            // Upcoming Reviews Section
            Text(
              'Upcoming Reviews',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            if (_upcomingReviews.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No upcoming reviews scheduled.'),
                ),
              )
            else
              ..._upcomingReviews.map((review) => _buildReviewCard(review, false)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(ReviewItem review, bool isDue) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDue ? Colors.red[100] : Colors.blue[100],
          child: Icon(
            _getSubjectIcon(review.subject),
            color: isDue ? Colors.red[700] : Colors.blue[700],
          ),
        ),
        title: Text(
          review.question,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject: ${review.subject}'),
            Text(
              isDue
                  ? 'Due now'
                  : 'Due: ${_formatDate(review.nextReview)}',
              style: TextStyle(
                color: isDue ? Colors.red[700] : Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Chip(
          label: Text('Level ${review.difficulty}'),
          backgroundColor: _getDifficultyColor(review.difficulty),
        ),
      ),
    );
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'math':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'geography':
        return Icons.public;
      default:
        return Icons.book;
    }
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green[100]!;
      case 2:
        return Colors.yellow[100]!;
      case 3:
        return Colors.orange[100]!;
      default:
        return Colors.red[100]!;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference > 1) {
      return 'In $difference days';
    } else {
      return '${-difference} days ago';
    }
  }
}

/// Model class for review items
class ReviewItem {
  final String id;
  final String question;
  final String subject;
  final int difficulty;
  final DateTime lastReviewed;
  final DateTime nextReview;
  final int interval;
  final double easeFactor;

  ReviewItem({
    required this.id,
    required this.question,
    required this.subject,
    required this.difficulty,
    required this.lastReviewed,
    required this.nextReview,
    required this.interval,
    required this.easeFactor,
  });
}