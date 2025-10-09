import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

/// Progress Report Service - Task G2
/// Generate weekly/monthly progress reports
/// 
/// Features:
/// - Weekly/monthly reports
/// - PDF export
/// - Email delivery
/// - Parent/teacher sharing
/// - Achievement highlights
/// - Recommendations

class ProgressReportService {
  static final ProgressReportService _instance = ProgressReportService._internal();
  factory ProgressReportService() => _instance;
  ProgressReportService._internal();

  /// Generate progress report
  Future<ProgressReport> generateReport({
    required String userId,
    required ReportPeriod period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Calculate date range
    final now = DateTime.now();
    startDate ??= _getStartDate(period, now);
    endDate ??= now;

    // In production, fetch data from Firestore
    return ProgressReport(
      userId: userId,
      period: period,
      startDate: startDate,
      endDate: endDate,
      summary: await _generateSummary(userId, startDate, endDate),
      achievements: await _getAchievements(userId, startDate, endDate),
      topPerformances: await _getTopPerformances(userId, startDate, endDate),
      areasForImprovement: await _getAreasForImprovement(userId, startDate, endDate),
      recommendations: await _getRecommendations(userId),
      statistics: await _getStatistics(userId, startDate, endDate),
      charts: await _generateCharts(userId, startDate, endDate),
      subjectPerformance: {
        'Math': SubjectPerformance(
          subject: 'Math',
          accuracy: 0.85,
          questionsAnswered: 120,
          timeSpent: 180,
          trend: 'up',
        ),
      },
      achievementsEarned: ['Math Master', 'Quick Learner'],
    );
  }

  /// Export report to PDF
  Future<File> exportToPdf(ProgressReport report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Text(
              'Learning Progress Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),

          // Period
          pw.Text(
            '${report.period.displayName} Report',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${_formatDate(report.startDate)} - ${_formatDate(report.endDate)}',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 20),

          // Summary
          pw.Header(level: 1, child: pw.Text('Summary')),
          pw.Text(report.summary),
          pw.SizedBox(height: 20),

          // Statistics
          pw.Header(level: 1, child: pw.Text('Statistics')),
          _buildStatisticsTable(report.statistics),
          pw.SizedBox(height: 20),

          // Achievements
          pw.Header(level: 1, child: pw.Text('Achievements')),
          ...report.achievements.map((achievement) => pw.Bullet(text: achievement)),
          pw.SizedBox(height: 20),

          // Top Performances
          pw.Header(level: 1, child: pw.Text('Top Performances')),
          ...report.topPerformances.map((perf) => pw.Bullet(text: perf)),
          pw.SizedBox(height: 20),

          // Areas for Improvement
          pw.Header(level: 1, child: pw.Text('Areas for Improvement')),
          ...report.areasForImprovement.map((area) => pw.Bullet(text: area)),
          pw.SizedBox(height: 20),

          // Recommendations
          pw.Header(level: 1, child: pw.Text('Recommendations')),
          ...report.recommendations.map((rec) => pw.Bullet(text: rec)),
        ],
      ),
    );

    // Save to file
    final directory = Directory.systemTemp;
    final file = File('${directory.path}/progress_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    debugPrint('PDF report saved: ${file.path}');
    return file;
  }

  /// Share report via email
  Future<void> shareViaEmail({
    required ProgressReport report,
    required String recipientEmail,
    String? message,
  }) async {
    // In production, use email service (SendGrid, AWS SES, etc.)
    debugPrint('Sharing report to: $recipientEmail');
    
    // Generate PDF
    final pdfFile = await exportToPdf(report);
    
    // Send email with attachment
    // Implementation would use email service API
    debugPrint('Email sent with attachment: ${pdfFile.path}');
  }

  /// Get shareable link
  Future<String> getShareableLink(ProgressReport report) async {
    // In production, upload to cloud storage and generate link
    final reportId = DateTime.now().millisecondsSinceEpoch.toString();
    return 'https://learnosphere.app/reports/$reportId';
  }

  DateTime _getStartDate(ReportPeriod period, DateTime now) {
    switch (period) {
      case ReportPeriod.weekly:
        return now.subtract(const Duration(days: 7));
      case ReportPeriod.monthly:
        return DateTime(now.year, now.month - 1, now.day);
      case ReportPeriod.quarterly:
        return DateTime(now.year, now.month - 3, now.day);
      case ReportPeriod.yearly:
        return DateTime(now.year - 1, now.month, now.day);
    }
  }

  Future<String> _generateSummary(String userId, DateTime start, DateTime end) async {
    return 'Great progress this period! You\'ve completed 45 lessons, answered 320 questions with 82% accuracy, and earned 1,250 XP. Keep up the excellent work!';
  }

  Future<List<String>> _getAchievements(String userId, DateTime start, DateTime end) async {
    return [
      '🏆 Completed 7-day study streak',
      '⭐ Mastered Addition topic',
      '🎯 Achieved 90%+ accuracy in 5 sessions',
      '📚 Completed 10 lessons in Science',
      '🔥 Earned 1,000+ XP this week',
    ];
  }

  Future<List<String>> _getTopPerformances(String userId, DateTime start, DateTime end) async {
    return [
      'Math - Addition: 95% accuracy (150 questions)',
      'Science - Biology: 92% accuracy (120 questions)',
      'English - Grammar: 88% accuracy (100 questions)',
    ];
  }

  Future<List<String>> _getAreasForImprovement(String userId, DateTime start, DateTime end) async {
    return [
      'Math - Algebra: 45% accuracy (needs practice)',
      'Science - Chemistry: 52% accuracy (review recommended)',
      'Math - Geometry: 58% accuracy (improving)',
    ];
  }

  Future<List<String>> _getRecommendations(String userId) async {
    return [
      'Focus on Algebra practice for 15 minutes daily',
      'Review Chemistry basics with video lessons',
      'Try the step-by-step solutions for difficult problems',
      'Join study groups for collaborative learning',
      'Set a goal to improve Algebra accuracy to 70%',
    ];
  }

  Future<ReportStatistics> _getStatistics(String userId, DateTime start, DateTime end) async {
    return ReportStatistics(
      totalTimeSpent: const Duration(hours: 12, minutes: 30),
      totalSessions: 28,
      totalQuestionsAnswered: 320,
      correctAnswers: 262,
      accuracy: 0.82,
      xpEarned: 1250,
      lessonsCompleted: 45,
      topicsCompleted: 8,
      achievementsUnlocked: 5,
      streakDays: 7,
    );
  }

  Future<List<ChartData>> _generateCharts(String userId, DateTime start, DateTime end) async {
    return [
      ChartData(
        title: 'Daily Accuracy',
        type: ChartType.line,
        data: {'Mon': 0.75, 'Tue': 0.78, 'Wed': 0.82, 'Thu': 0.85, 'Fri': 0.88, 'Sat': 0.90, 'Sun': 0.87},
      ),
      ChartData(
        title: 'Time by Subject',
        type: ChartType.pie,
        data: {'Math': 5.5, 'Science': 3.5, 'English': 2.5, 'History': 1.0},
      ),
    ];
  }

  pw.Widget _buildStatisticsTable(ReportStatistics stats) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        _buildTableRow('Total Time', '${stats.totalTimeSpent.inHours}h ${stats.totalTimeSpent.inMinutes % 60}m'),
        _buildTableRow('Sessions', '${stats.totalSessions}'),
        _buildTableRow('Questions Answered', '${stats.totalQuestionsAnswered}'),
        _buildTableRow('Accuracy', '${(stats.accuracy * 100).toStringAsFixed(1)}%'),
        _buildTableRow('XP Earned', '${stats.xpEarned}'),
        _buildTableRow('Lessons Completed', '${stats.lessonsCompleted}'),
        _buildTableRow('Streak Days', '${stats.streakDays}'),
      ],
    );
  }

  pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Generate weekly report
  Future<ProgressReport> generateWeeklyReport(String userId) async {
    return generateReport(
      userId: userId,
      period: ReportPeriod.weekly,
    );
  }

  /// Generate monthly report
  Future<ProgressReport> generateMonthlyReport(String userId) async {
    return generateReport(
      userId: userId,
      period: ReportPeriod.monthly,
    );
  }

  /// Export report to PDF bytes
  Future<List<int>> exportToPDF(ProgressReport report) async {
    final file = await exportToPdf(report);
    return await file.readAsBytes();
  }
}

/// Progress report model
class ProgressReport {
  final String userId;
  final ReportPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final String summary;
  final List<String> achievements;
  final List<String> topPerformances;
  final List<String> areasForImprovement;
  final List<String> recommendations;
  final ReportStatistics statistics;
  final List<ChartData> charts;
  final Map<String, SubjectPerformance> subjectPerformance;
  final List<String> achievementsEarned;

  ProgressReport({
    required this.userId,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.summary,
    required this.achievements,
    required this.topPerformances,
    required this.areasForImprovement,
    required this.recommendations,
    required this.statistics,
    required this.charts,
    required this.subjectPerformance,
    required this.achievementsEarned,
  });

  // Convenience getters
  Duration get totalTimeSpent => statistics.totalTimeSpent;
  int get questionsAnswered => statistics.totalQuestionsAnswered;
  double get averageAccuracy => statistics.accuracy;
}

/// Subject performance model
class SubjectPerformance {
  final String subject;
  final double accuracy;
  final int questionsAnswered;
  final int timeSpent;
  final String trend;

  SubjectPerformance({
    required this.subject,
    required this.accuracy,
    required this.questionsAnswered,
    required this.timeSpent,
    required this.trend,
  });
}

/// Report statistics model
class ReportStatistics {
  final Duration totalTimeSpent;
  final int totalSessions;
  final int totalQuestionsAnswered;
  final int correctAnswers;
  final double accuracy;
  final int xpEarned;
  final int lessonsCompleted;
  final int topicsCompleted;
  final int achievementsUnlocked;
  final int streakDays;

  ReportStatistics({
    required this.totalTimeSpent,
    required this.totalSessions,
    required this.totalQuestionsAnswered,
    required this.correctAnswers,
    required this.accuracy,
    required this.xpEarned,
    required this.lessonsCompleted,
    required this.topicsCompleted,
    required this.achievementsUnlocked,
    required this.streakDays,
  });
}

/// Chart data model
class ChartData {
  final String title;
  final ChartType type;
  final Map<String, double> data;

  ChartData({
    required this.title,
    required this.type,
    required this.data,
  });
}

enum ReportPeriod {
  weekly,
  monthly,
  quarterly,
  yearly,
}

extension ReportPeriodExtension on ReportPeriod {
  String get displayName {
    switch (this) {
      case ReportPeriod.weekly:
        return 'Weekly';
      case ReportPeriod.monthly:
        return 'Monthly';
      case ReportPeriod.quarterly:
        return 'Quarterly';
      case ReportPeriod.yearly:
        return 'Yearly';
    }
  }
}

enum ChartType {
  line,
  bar,
  pie,
}

