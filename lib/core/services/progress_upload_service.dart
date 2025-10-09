import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/subject.dart';
import 'unified_xp_service.dart';

/// Service to handle progress upload functionality
class ProgressUploadService {
  static ProgressUploadService? _instance;
  static ProgressUploadService getInstance() {
    _instance ??= ProgressUploadService._internal();
    return _instance!;
  }
  ProgressUploadService._internal();

  final UnifiedXPService _xpService = UnifiedXPService.getInstance();
  
  static const String _uploadHistoryKey = 'progress_upload_history';
  static const String _lastUploadKey = 'last_progress_upload';

  /// Generate progress report for upload
  Future<Map<String, dynamic>> generateProgressReport() async {
    final eligibility = await _xpService.getUploadEligibility();
    
    if (!eligibility['canUpload']) {
      throw Exception('Progress upload requirements not met');
    }

    final allStats = await _xpService.getAllXPStats();
    final leaderboard = await _xpService.getLeaderboardData();
    
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'userId': await _getUserId(),
      'deviceInfo': await _getDeviceInfo(),
      'progressSummary': {
        'totalSubjects': SubjectType.values.length,
        'completedSubjects': _getCompletedSubjectsCount(allStats),
        'totalXP': _getTotalXP(allStats),
        'averageLevel': _getAverageLevel(allStats),
        'highestLevel': _getHighestLevel(allStats),
      },
      'subjectDetails': allStats,
      'leaderboard': leaderboard,
      'achievements': await _getAchievements(allStats),
      'uploadEligibility': eligibility,
      'version': '1.0.0',
    };

    return report;
  }

  /// Save progress report to local file
  Future<String> saveProgressReportToFile() async {
    final report = await generateProgressReport();
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'progress_report_$timestamp.json';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(jsonEncode(report));
    
    // Save upload history
    await _saveUploadHistory(fileName, report);
    
    return file.path;
  }

  /// Upload progress to cloud/server (placeholder implementation)
  Future<Map<String, dynamic>> uploadProgress() async {
    final report = await generateProgressReport();
    
    try {
      // Placeholder for actual upload implementation
      // In a real app, this would send data to your backend server
      
      final uploadResult = await _simulateUpload(report);
      
      // Save successful upload record
      await _recordSuccessfulUpload(uploadResult);
      
      return {
        'success': true,
        'uploadId': uploadResult['uploadId'],
        'timestamp': uploadResult['timestamp'],
        'message': 'Progress uploaded successfully!',
        'reportSize': jsonEncode(report).length,
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to upload progress. Please try again.',
      };
    }
  }

  /// Simulate upload process (replace with actual implementation)
  Future<Map<String, dynamic>> _simulateUpload(Map<String, dynamic> report) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulate upload process
    final uploadId = 'upload_${DateTime.now().millisecondsSinceEpoch}';
    
    return {
      'uploadId': uploadId,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'completed',
      'reportHash': report.hashCode.toString(),
    };
  }

  /// Get upload history
  Future<List<Map<String, dynamic>>> getUploadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyData = prefs.getString(_uploadHistoryKey);
    
    if (historyData == null) return [];
    
    final List<dynamic> history = jsonDecode(historyData);
    return history.cast<Map<String, dynamic>>();
  }

  /// Get last upload information
  Future<Map<String, dynamic>?> getLastUpload() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUploadData = prefs.getString(_lastUploadKey);
    
    if (lastUploadData == null) return null;
    
    return jsonDecode(lastUploadData);
  }

  /// Check if user can upload (wrapper for XP service)
  Future<bool> canUploadProgress() async {
    return await _xpService.canUploadProgress();
  }

  /// Get detailed upload eligibility
  Future<Map<String, dynamic>> getUploadEligibility() async {
    return await _xpService.getUploadEligibility();
  }

  /// Private helper methods
  
  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    
    if (userId == null) {
      userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('user_id', userId);
    }
    
    return userId;
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
    };
  }

  int _getCompletedSubjectsCount(Map<String, dynamic> stats) {
    int completed = 0;
    for (final subjectStats in stats.values) {
      final level = subjectStats['currentLevel'] as int;
      if (level >= 3) completed++;
    }
    return completed;
  }

  int _getTotalXP(Map<String, dynamic> stats) {
    int total = 0;
    for (final subjectStats in stats.values) {
      total += subjectStats['currentXP'] as int;
    }
    return total;
  }

  double _getAverageLevel(Map<String, dynamic> stats) {
    if (stats.isEmpty) return 0.0;
    
    int totalLevels = 0;
    for (final subjectStats in stats.values) {
      totalLevels += subjectStats['currentLevel'] as int;
    }
    
    return totalLevels / stats.length;
  }

  int _getHighestLevel(Map<String, dynamic> stats) {
    int highest = 0;
    for (final subjectStats in stats.values) {
      final level = subjectStats['currentLevel'] as int;
      if (level > highest) highest = level;
    }
    return highest;
  }

  Future<List<Map<String, dynamic>>> _getAchievements(Map<String, dynamic> stats) async {
    final achievements = <Map<String, dynamic>>[];
    
    // Level-based achievements
    for (final entry in stats.entries) {
      final subject = entry.key;
      final subjectStats = entry.value;
      final level = subjectStats['currentLevel'] as int;
      
      if (level >= 5) {
        achievements.add({
          'id': 'level_5_$subject',
          'title': 'Expert in $subject',
          'description': 'Reached level 5 in $subject',
          'type': 'level',
          'earnedAt': DateTime.now().toIso8601String(),
        });
      }
      
      if (level >= 10) {
        achievements.add({
          'id': 'master_$subject',
          'title': 'Master of $subject',
          'description': 'Reached maximum level in $subject',
          'type': 'mastery',
          'earnedAt': DateTime.now().toIso8601String(),
        });
      }
    }
    
    // Cross-subject achievements
    final completedSubjects = _getCompletedSubjectsCount(stats);
    if (completedSubjects >= 2) {
      achievements.add({
        'id': 'multi_subject_learner',
        'title': 'Multi-Subject Learner',
        'description': 'Reached level 3 in multiple subjects',
        'type': 'progress',
        'earnedAt': DateTime.now().toIso8601String(),
      });
    }
    
    if (completedSubjects == SubjectType.values.length) {
      achievements.add({
        'id': 'all_subjects_master',
        'title': 'Universal Scholar',
        'description': 'Reached level 3 in all subjects',
        'type': 'mastery',
        'earnedAt': DateTime.now().toIso8601String(),
      });
    }
    
    return achievements;
  }

  Future<void> _saveUploadHistory(String fileName, Map<String, dynamic> report) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getUploadHistory();
    
    history.add({
      'fileName': fileName,
      'timestamp': DateTime.now().toIso8601String(),
      'reportSummary': {
        'totalXP': _getTotalXP(report['subjectDetails']),
        'averageLevel': _getAverageLevel(report['subjectDetails']),
        'completedSubjects': _getCompletedSubjectsCount(report['subjectDetails']),
      },
    });
    
    // Keep only last 10 uploads
    if (history.length > 10) {
      history.removeRange(0, history.length - 10);
    }
    
    await prefs.setString(_uploadHistoryKey, jsonEncode(history));
  }

  Future<void> _recordSuccessfulUpload(Map<String, dynamic> uploadResult) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUploadKey, jsonEncode(uploadResult));
  }

  /// Clear upload history (for testing or privacy)
  Future<void> clearUploadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_uploadHistoryKey);
    await prefs.remove(_lastUploadKey);
  }
}