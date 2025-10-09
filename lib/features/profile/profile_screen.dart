import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/asset_service.dart';
import 'package:sp/core/services/progress_service.dart';
import 'package:sp/core/services/analytics_service.dart';
import 'package:sp/core/services/progressive_difficulty_service.dart';
import 'package:sp/core/services/game_save_service.dart';
import 'package:sp/core/services/daily_content_service.dart';
import 'package:sp/core/services/progress_upload_service.dart';
import 'package:sp/core/services/unified_xp_service.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/models/user.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _analyticsData;
  Map<String, dynamic>? _performanceData;
  Map<String, dynamic>? _usageStats;
  Map<String, dynamic>? _gameStats;
  Map<String, dynamic>? _xpStats;
  Map<String, dynamic>? _uploadEligibility;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final analyticsService = AnalyticsService();
      final progressiveDifficultyService = ProgressiveDifficultyService.getInstance();
      final gameSaveService = GameSaveService();
      final xpService = UnifiedXPService.getInstance();
      final uploadService = ProgressUploadService.getInstance();

      // Load all analytics and statistics
      final analytics = analyticsService.getPrivacyCompliantSummary();
      final engagement = analyticsService.getEngagementSummary();
      final learningPatterns = analyticsService.getLearningPatterns();
      final consistency = analyticsService.getLearningConsistency();
      final sessionInfo = analyticsService.getCurrentSessionInfo();
      
      final performance = await progressiveDifficultyService.getDifficultyAnalytics();
      final usageStats = await DailyContentService.getInstance().getUsageStats();
      final gameStats = await gameSaveService.getPerformanceAnalytics();
      final xpStats = await xpService.getAllXPStats();
      final uploadEligibility = await uploadService.getUploadEligibility();

      setState(() {
        _analyticsData = {
          'summary': analytics,
          'engagement': engagement,
          'patterns': learningPatterns,
          'consistency': consistency,
          'session': sessionInfo,
        };
        _performanceData = performance;
        _usageStats = usageStats;
        _gameStats = gameStats;
        _xpStats = xpStats;
        _uploadEligibility = uploadEligibility;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = ref.watch(progressProvider);
    final user = progress.user;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profile & Statistics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadAllData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Statistics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserHeader(theme, user),
                    const SizedBox(height: 24),
                    _buildXPProgressSection(theme),
                    const SizedBox(height: 24),
                    _buildProgressUploadSection(theme),
                    const SizedBox(height: 24),
                    _buildLifetimeStatsSection(theme),
                    const SizedBox(height: 24),
                    _buildLearningPatternsSection(theme),
                    const SizedBox(height: 24),
                    _buildPerformanceSection(theme),
                    const SizedBox(height: 24),
                    _buildAPIUsageSection(theme),
                    const SizedBox(height: 24),
                    _buildGameStatsSection(theme),
                    const SizedBox(height: 24),
                    _buildSessionInfoSection(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildXPProgressSection(ThemeData theme) {
    if (_xpStats == null) return const SizedBox.shrink();

    return _buildSection(
      theme,
      'XP Progress by Subject',
      Icons.trending_up,
      [
        ..._xpStats!.entries.map((entry) {
          final subject = entry.key;
          final stats = entry.value as Map<String, dynamic>;
          final currentLevel = stats['currentLevel'] as int;
          final currentXP = stats['currentXP'] as int;
          final nextLevelXP = stats['nextLevelXP'] as int;
          final progress = currentXP / nextLevelXP;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getSubjectIcon(subject),
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        subject,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Level $currentLevel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '$currentXP XP',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      '$nextLevelXP XP',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildProgressUploadSection(ThemeData theme) {
    if (_uploadEligibility == null) return const SizedBox.shrink();

    final canUpload = _uploadEligibility!['canUpload'] as bool;
    final requirement = _uploadEligibility!['requirement'] as String;
    final subjectDetails = _uploadEligibility!['subjectDetails'] as Map<String, dynamic>;

    return _buildSection(
      theme,
      'Progress Upload',
      Icons.cloud_upload,
      [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: canUpload 
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: canUpload 
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.orange.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    canUpload ? Icons.check_circle : Icons.info,
                    color: canUpload ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      canUpload ? 'Ready to Upload' : 'Upload Requirements',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: canUpload ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                requirement,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Subject Progress:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...subjectDetails.entries.map((entry) {
                final subject = entry.key;
                final details = entry.value as Map<String, dynamic>;
                final level = details['currentLevel'] as int;
                final meetsRequirement = details['meetsRequirement'] as bool;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        _getSubjectIcon(subject),
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subject,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        'Level $level',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: meetsRequirement ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        meetsRequirement ? Icons.check : Icons.close,
                        size: 16,
                        color: meetsRequirement ? Colors.green : Colors.orange,
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (canUpload) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadProgress,
                    icon: _isUploading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(_isUploading ? 'Uploading...' : 'Upload Progress'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _uploadProgress() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final uploadService = ProgressUploadService.getInstance();
      final result = await uploadService.uploadProgress();

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildUserHeader(ThemeData theme, User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primary,
              child: ClipOval(
                child: AssetService.getAvatarIcon(
                  'default_avatar',
                  width: 80,
                  height: 80,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isNotEmpty ? user.name : 'User',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildUserStat(theme, 'Level', user.level.toString(), Icons.trending_up),
                      const SizedBox(width: 16),
                      _buildUserStat(theme, 'XP', user.totalXP.toString(), Icons.star),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildUserStat(theme, 'Streak', '${user.currentStreak} days', Icons.local_fire_department),
                      const SizedBox(width: 16),
                      _buildUserStat(theme, 'Gems', user.gems.toString(), Icons.diamond),
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

  Widget _buildUserStat(ThemeData theme, String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLifetimeStatsSection(ThemeData theme) {
    if (_analyticsData == null) return const SizedBox.shrink();

    final summary = _analyticsData!['summary'] as Map<String, dynamic>? ?? {};
    final consistency = _analyticsData!['consistency'] as Map<String, dynamic>? ?? {};

    return _buildSection(
      theme,
      'Lifetime Statistics',
      Icons.timeline,
      [
        _buildStatGrid(theme, [
          _buildStatCard(
            theme,
            'Total Learning Time',
            '${summary['total_learning_time_hours'] ?? 0} hours',
            Icons.access_time,
            theme.colorScheme.primary,
          ),
          _buildStatCard(
            theme,
            'Learning Streak',
            '${summary['learning_streak_days'] ?? 0} days',
            Icons.local_fire_department,
            Colors.orange,
          ),
          _buildStatCard(
            theme,
            'Total Sessions',
            '${consistency['total_sessions'] ?? 0}',
            Icons.play_circle,
            theme.colorScheme.secondary,
          ),
          _buildStatCard(
            theme,
            'Consistency Score',
            '${((summary['learning_consistency'] ?? 0.0) * 100).toInt()}%',
            Icons.trending_up,
            Colors.green,
          ),
        ]),
      ],
    );
  }

  Widget _buildLearningPatternsSection(ThemeData theme) {
    if (_analyticsData == null) return const SizedBox.shrink();

    final summary = _analyticsData!['summary'] as Map<String, dynamic>? ?? {};
    final favoriteSubjects = summary['favorite_subjects'] as List? ?? [];
    final preferredCategories = summary['preferred_categories'] as List? ?? [];

    return _buildSection(
      theme,
      'Learning Patterns',
      Icons.psychology,
      [
        if (favoriteSubjects.isNotEmpty) ...[
          _buildSubsectionHeader(theme, 'Favorite Subjects'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: favoriteSubjects.take(5).map((subject) => Chip(
              label: Text(subject.toString()),
              backgroundColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (preferredCategories.isNotEmpty) ...[
          _buildSubsectionHeader(theme, 'Preferred Question Types'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: preferredCategories.take(5).map((category) => Chip(
              label: Text(category.toString()),
              backgroundColor: theme.colorScheme.secondaryContainer,
              labelStyle: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPerformanceSection(ThemeData theme) {
    if (_performanceData == null) return const SizedBox.shrink();

    final questionsGenerated = _performanceData!['questionsGenerated'] ?? 0;
    final subjectPerformance = _performanceData!['subjectPerformance'] as Map<String, dynamic>? ?? {};

    return _buildSection(
      theme,
      'Performance Analytics',
      Icons.analytics,
      [
        _buildStatCard(
          theme,
          'Questions Generated',
          questionsGenerated.toString(),
          Icons.quiz,
          theme.colorScheme.tertiary,
        ),
        const SizedBox(height: 16),
        if (subjectPerformance.isNotEmpty) ...[
          _buildSubsectionHeader(theme, 'Subject Performance'),
          const SizedBox(height: 8),
          ...subjectPerformance.entries.map((entry) {
            final percentage = entry.value as double? ?? 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${percentage.toInt()}%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getPerformanceColor(percentage),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildAPIUsageSection(ThemeData theme) {
    if (_usageStats == null) return const SizedBox.shrink();

    final dailyUsage = _usageStats!['dailyUsage'] ?? 0;
    final maxRequests = _usageStats!['maxDailyRequests'] ?? 100;
    final remainingRequests = _usageStats!['remainingRequests'] ?? 0;
    final hasContent = _usageStats!['hasDailyContent'] ?? false;
    final lastGeneration = _usageStats!['lastGeneration'] as String?;

    return _buildSection(
      theme,
      'AI Usage Statistics',
      Icons.smart_toy,
      [
        _buildStatGrid(theme, [
          _buildStatCard(
            theme,
            'Daily Usage',
            '$dailyUsage / $maxRequests',
            Icons.today,
            theme.colorScheme.primary,
          ),
          _buildStatCard(
            theme,
            'Remaining',
            remainingRequests.toString(),
            Icons.hourglass_empty,
            Colors.blue,
          ),
          _buildStatCard(
            theme,
            'Content Available',
            hasContent ? 'Yes' : 'No',
            hasContent ? Icons.check_circle : Icons.cancel,
            hasContent ? Colors.green : Colors.red,
          ),
        ]),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: dailyUsage / maxRequests,
          backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            dailyUsage / maxRequests > 0.8 ? Colors.red : theme.colorScheme.primary,
          ),
        ),
        if (lastGeneration != null) ...[
          const SizedBox(height: 8),
          Text(
            'Last Generation: $lastGeneration',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGameStatsSection(ThemeData theme) {
    if (_gameStats == null) return const SizedBox.shrink();

    final totalSetsCompleted = _gameStats!['totalSetsCompleted'] ?? 0;
    final averageScore = _gameStats!['averageScore'] ?? 0.0;
    final subjectPerformance = _gameStats!['subjectPerformance'] as Map<String, dynamic>? ?? {};

    return _buildSection(
      theme,
      'Game Statistics',
      Icons.games,
      [
        _buildStatGrid(theme, [
          _buildStatCard(
            theme,
            'Sets Completed',
            totalSetsCompleted.toString(),
            Icons.check_circle,
            Colors.green,
          ),
          _buildStatCard(
            theme,
            'Average Score',
            '${(averageScore * 100).toInt()}%',
            Icons.star,
            Colors.amber,
          ),
        ]),
        if (subjectPerformance.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSubsectionHeader(theme, 'Subject Game Performance'),
          const SizedBox(height: 8),
          ...subjectPerformance.entries.map((entry) {
            final data = entry.value as Map<String, dynamic>;
            final completed = data['completed'] ?? 0;
            final avgScore = data['averageScore'] ?? 0.0;
            return ListTile(
              leading: Icon(
                _getSubjectIcon(entry.key),
                color: theme.colorScheme.primary,
              ),
              title: Text(entry.key),
              subtitle: Text('$completed sets completed'),
              trailing: Text(
                '${(avgScore * 100).toInt()}%',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getPerformanceColor(avgScore * 100),
                ),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildSessionInfoSection(ThemeData theme) {
    if (_analyticsData == null) return const SizedBox.shrink();

    final session = _analyticsData!['session'] as Map<String, dynamic>? ?? {};
    final consistency = _analyticsData!['consistency'] as Map<String, dynamic>? ?? {};

    if (session.isEmpty && consistency.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      theme,
      'Current Session',
      Icons.timer,
      [
        if (session.isNotEmpty) ...[
          _buildStatGrid(theme, [
            _buildStatCard(
              theme,
              'Session Duration',
              '${(session['duration_seconds'] ?? 0) ~/ 60} min',
              Icons.access_time,
              theme.colorScheme.primary,
            ),
            _buildStatCard(
              theme,
              'Events',
              '${session['events_count'] ?? 0}',
              Icons.event,
              theme.colorScheme.secondary,
            ),
          ]),
        ],
        if (consistency.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildStatGrid(theme, [
            _buildStatCard(
              theme,
              'Longest Streak',
              '${consistency['longest_streak'] ?? 0} days',
              Icons.emoji_events,
              Colors.amber,
            ),
            _buildStatCard(
              theme,
              'Avg Session',
              '${(consistency['average_session_duration'] ?? 0.0).toInt()} min',
              Icons.schedule,
              Colors.blue,
            ),
          ]),
        ],
      ],
    );
  }

  Widget _buildSection(ThemeData theme, String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSubsectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildStatGrid(ThemeData theme, List<Widget> children) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: children,
    );
  }

  Widget _buildStatCard(ThemeData theme, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'math':
      case 'mathematics':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'english':
      case 'language':
        return Icons.language;
      case 'history':
        return Icons.history_edu;
      case 'geography':
        return Icons.public;
      default:
        return Icons.school;
    }
  }
}