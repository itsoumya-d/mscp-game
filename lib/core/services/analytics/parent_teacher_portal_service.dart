import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Parent/Teacher Portal Service - Task G5
/// Separate portal for parents and teachers to monitor progress
/// 
/// Features:
/// - Student management
/// - Progress tracking
/// - Assignment creation
/// - Performance reports
/// - Communication tools

class ParentTeacherPortalService {
  static final ParentTeacherPortalService _instance =
      ParentTeacherPortalService._internal();
  factory ParentTeacherPortalService() => _instance;
  ParentTeacherPortalService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Link parent/teacher to student
  Future<void> linkToStudent({
    required String parentTeacherId,
    required String studentId,
    required String relationshipType, // 'parent' or 'teacher'
    String? accessCode,
  }) async {
    try {
      await _firestore.collection('student_links').add({
        'parentTeacherId': parentTeacherId,
        'studentId': studentId,
        'relationshipType': relationshipType,
        'linkedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      debugPrint('Linked $relationshipType to student: $studentId');
    } catch (e) {
      debugPrint('Error linking to student: $e');
      rethrow;
    }
  }

  /// Get all linked students
  Future<List<StudentProfile>> getLinkedStudents(String parentTeacherId) async {
    // In production, fetch from Firestore
    return [
      StudentProfile(
        studentId: 'student_1',
        name: 'John Doe',
        gradeLevel: 8,
        avatarUrl: 'https://via.placeholder.com/150',
        currentStreak: 12,
        totalXp: 15600,
        overallAccuracy: 0.82,
        lastActive: DateTime.now().subtract(const Duration(hours: 2)),
        subjects: ['Math', 'Science', 'English', 'History'],
      ),
      StudentProfile(
        studentId: 'student_2',
        name: 'Jane Smith',
        gradeLevel: 7,
        avatarUrl: 'https://via.placeholder.com/150',
        currentStreak: 8,
        totalXp: 12400,
        overallAccuracy: 0.78,
        lastActive: DateTime.now().subtract(const Duration(hours: 5)),
        subjects: ['Math', 'Science', 'English'],
      ),
    ];
  }

  /// Get student progress summary
  Future<StudentProgressSummary> getStudentProgress(String studentId) async {
    return StudentProgressSummary(
      studentId: studentId,
      weeklyProgress: WeeklyProgress(
        timeSpent: const Duration(hours: 8, minutes: 30),
        questionsAnswered: 156,
        accuracy: 0.82,
        xpEarned: 780,
        lessonsCompleted: 12,
        streakMaintained: true,
      ),
      monthlyProgress: MonthlyProgress(
        timeSpent: const Duration(hours: 32, minutes: 15),
        questionsAnswered: 624,
        accuracy: 0.80,
        xpEarned: 3120,
        lessonsCompleted: 48,
        topicsCompleted: 8,
        achievementsUnlocked: 5,
      ),
      subjectProgress: {
        'Math': DetailedSubjectProgress(
          subject: 'Math',
          accuracy: 0.85,
          timeSpent: const Duration(hours: 12),
          topicsCompleted: 5,
          currentTopic: 'Algebra',
          nextMilestone: 'Complete Algebra basics',
        ),
        'Science': DetailedSubjectProgress(
          subject: 'Science',
          accuracy: 0.78,
          timeSpent: const Duration(hours: 10),
          topicsCompleted: 4,
          currentTopic: 'Chemistry',
          nextMilestone: 'Master periodic table',
        ),
      },
      recentAchievements: [
        '🏆 7-day streak',
        '⭐ Mastered Addition',
        '🎯 90%+ accuracy in 5 sessions',
      ],
      areasOfConcern: [
        'Algebra accuracy below 50%',
        'Chemistry needs review',
      ],
      recommendations: [
        'Encourage daily Algebra practice',
        'Review Chemistry basics together',
        'Celebrate the 7-day streak!',
      ],
    );
  }

  /// Create assignment for student
  Future<String> createAssignment({
    required String teacherId,
    required String studentId,
    required Assignment assignment,
  }) async {
    try {
      final doc = await _firestore.collection('assignments').add({
        'teacherId': teacherId,
        'studentId': studentId,
        'title': assignment.title,
        'description': assignment.description,
        'subject': assignment.subject,
        'topics': assignment.topics,
        'dueDate': Timestamp.fromDate(assignment.dueDate),
        'estimatedTime': assignment.estimatedTime.inMinutes,
        'difficulty': assignment.difficulty.name,
        'status': 'assigned',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Assignment created: ${doc.id}');
      return doc.id;
    } catch (e) {
      debugPrint('Error creating assignment: $e');
      rethrow;
    }
  }

  /// Get student assignments
  Future<List<Assignment>> getStudentAssignments(String studentId) async {
    // In production, fetch from Firestore
    return [
      Assignment(
        id: 'assign_1',
        title: 'Algebra Practice',
        description: 'Complete 20 algebra problems',
        subject: 'Math',
        topics: ['Algebra', 'Equations'],
        dueDate: DateTime.now().add(const Duration(days: 3)),
        estimatedTime: const Duration(minutes: 30),
        difficulty: AssignmentDifficulty.medium,
        status: AssignmentStatus.inProgress,
        progress: 0.6,
      ),
      Assignment(
        id: 'assign_2',
        title: 'Chemistry Review',
        description: 'Review periodic table and elements',
        subject: 'Science',
        topics: ['Chemistry', 'Periodic Table'],
        dueDate: DateTime.now().add(const Duration(days: 5)),
        estimatedTime: const Duration(minutes: 45),
        difficulty: AssignmentDifficulty.easy,
        status: AssignmentStatus.notStarted,
        progress: 0.0,
      ),
    ];
  }

  /// Send message to student
  Future<void> sendMessage({
    required String senderId,
    required String studentId,
    required String message,
    MessageType type = MessageType.general,
  }) async {
    try {
      await _firestore.collection('messages').add({
        'senderId': senderId,
        'recipientId': studentId,
        'message': message,
        'type': type.name,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      debugPrint('Message sent to student: $studentId');
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  /// Get activity feed for student
  Future<List<ActivityItem>> getStudentActivity(String studentId, {int limit = 20}) async {
    // In production, fetch from Firestore
    return [
      ActivityItem(
        type: ActivityType.lessonCompleted,
        title: 'Completed Math Lesson',
        description: 'Algebra - Linear Equations',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        icon: '📚',
      ),
      ActivityItem(
        type: ActivityType.achievementUnlocked,
        title: 'Achievement Unlocked',
        description: '7-day streak!',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        icon: '🏆',
      ),
      ActivityItem(
        type: ActivityType.practiceSession,
        title: 'Practice Session',
        description: '25 questions, 88% accuracy',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        icon: '🎯',
      ),
    ];
  }

  /// Generate parent/teacher report
  Future<ParentTeacherReport> generateReport({
    required String studentId,
    required ReportPeriod period,
  }) async {
    return ParentTeacherReport(
      studentId: studentId,
      period: period,
      generatedAt: DateTime.now(),
      summary: 'Excellent progress this week! John has maintained a 7-day streak and improved accuracy by 5%.',
      highlights: [
        'Maintained 7-day study streak',
        'Improved Math accuracy to 85%',
        'Completed 12 lessons',
        'Earned 780 XP',
      ],
      concerns: [
        'Algebra accuracy needs improvement (45%)',
        'Chemistry review recommended',
      ],
      recommendations: [
        'Encourage 15 minutes of daily Algebra practice',
        'Review Chemistry basics together',
        'Celebrate achievements to maintain motivation',
      ],
      nextSteps: [
        'Complete Algebra assignment by Friday',
        'Watch Chemistry video lessons',
        'Maintain daily study routine',
      ],
    );
  }
}

/// Student profile model
class StudentProfile {
  final String studentId;
  final String name;
  final int gradeLevel;
  final String avatarUrl;
  final int currentStreak;
  final int totalXp;
  final double overallAccuracy;
  final DateTime lastActive;
  final List<String> subjects;

  StudentProfile({
    required this.studentId,
    required this.name,
    required this.gradeLevel,
    required this.avatarUrl,
    required this.currentStreak,
    required this.totalXp,
    required this.overallAccuracy,
    required this.lastActive,
    required this.subjects,
  });
}

/// Student progress summary model
class StudentProgressSummary {
  final String studentId;
  final WeeklyProgress weeklyProgress;
  final MonthlyProgress monthlyProgress;
  final Map<String, DetailedSubjectProgress> subjectProgress;
  final List<String> recentAchievements;
  final List<String> areasOfConcern;
  final List<String> recommendations;

  StudentProgressSummary({
    required this.studentId,
    required this.weeklyProgress,
    required this.monthlyProgress,
    required this.subjectProgress,
    required this.recentAchievements,
    required this.areasOfConcern,
    required this.recommendations,
  });
}

class WeeklyProgress {
  final Duration timeSpent;
  final int questionsAnswered;
  final double accuracy;
  final int xpEarned;
  final int lessonsCompleted;
  final bool streakMaintained;

  WeeklyProgress({
    required this.timeSpent,
    required this.questionsAnswered,
    required this.accuracy,
    required this.xpEarned,
    required this.lessonsCompleted,
    required this.streakMaintained,
  });
}

class MonthlyProgress {
  final Duration timeSpent;
  final int questionsAnswered;
  final double accuracy;
  final int xpEarned;
  final int lessonsCompleted;
  final int topicsCompleted;
  final int achievementsUnlocked;

  MonthlyProgress({
    required this.timeSpent,
    required this.questionsAnswered,
    required this.accuracy,
    required this.xpEarned,
    required this.lessonsCompleted,
    required this.topicsCompleted,
    required this.achievementsUnlocked,
  });
}

class DetailedSubjectProgress {
  final String subject;
  final double accuracy;
  final Duration timeSpent;
  final int topicsCompleted;
  final String currentTopic;
  final String nextMilestone;

  DetailedSubjectProgress({
    required this.subject,
    required this.accuracy,
    required this.timeSpent,
    required this.topicsCompleted,
    required this.currentTopic,
    required this.nextMilestone,
  });
}

class Assignment {
  final String? id;
  final String title;
  final String description;
  final String subject;
  final List<String> topics;
  final DateTime dueDate;
  final Duration estimatedTime;
  final AssignmentDifficulty difficulty;
  final AssignmentStatus status;
  final double progress;

  Assignment({
    this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.topics,
    required this.dueDate,
    required this.estimatedTime,
    required this.difficulty,
    required this.status,
    this.progress = 0.0,
  });
}

class ActivityItem {
  final ActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String icon;

  ActivityItem({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
  });
}

class ParentTeacherReport {
  final String studentId;
  final ReportPeriod period;
  final DateTime generatedAt;
  final String summary;
  final List<String> highlights;
  final List<String> concerns;
  final List<String> recommendations;
  final List<String> nextSteps;

  ParentTeacherReport({
    required this.studentId,
    required this.period,
    required this.generatedAt,
    required this.summary,
    required this.highlights,
    required this.concerns,
    required this.recommendations,
    required this.nextSteps,
  });
}

enum AssignmentDifficulty { easy, medium, hard }
enum AssignmentStatus { notStarted, inProgress, completed, overdue }
enum MessageType { general, encouragement, concern, reminder }
enum ActivityType { lessonCompleted, achievementUnlocked, practiceSession, assignmentCompleted }
enum ReportPeriod { weekly, monthly }

/// Student Progress model for screen display
class StudentProgress {
  final String studentId;
  final String studentName;
  final String avatarUrl;
  final int totalStudyTime;
  final double overallAccuracy;
  final int currentStreak;
  final List<RecentActivity> recentActivities;
  final Map<String, SubjectProgress> subjectProgress;
  final List<String> strengths;
  final List<String> weaknesses;
  final Map<String, String> studyHabits;
  final List<String> recommendations;
  final List<Alert> alerts;

  StudentProgress({
    required this.studentId,
    required this.studentName,
    required this.avatarUrl,
    required this.totalStudyTime,
    required this.overallAccuracy,
    required this.currentStreak,
    required this.recentActivities,
    required this.subjectProgress,
    required this.strengths,
    required this.weaknesses,
    required this.studyHabits,
    required this.recommendations,
    required this.alerts,
  });

  // Convenience getters
  int get gradeLevel => 10;
  int get currentLevel => 5;
  DateTime get lastActive => DateTime.now().subtract(const Duration(hours: 2));
  Map<String, SubjectProgress> get subjectPerformance => subjectProgress;
}

class RecentActivity {
  final String type;
  final String description;
  final DateTime timestamp;

  RecentActivity({
    required this.type,
    required this.description,
    required this.timestamp,
  });
}

class SubjectProgress {
  final String subject;
  final double accuracy;
  final int questionsAnswered;

  SubjectProgress({
    required this.subject,
    required this.accuracy,
    required this.questionsAnswered,
  });
}

class Alert {
  final String type;
  final String message;

  Alert({
    required this.type,
    required this.message,
  });
}

extension ParentTeacherPortalServiceExtension on ParentTeacherPortalService {
  /// Get student progress for screen display
  Future<StudentProgress> getStudentProgressForScreen(String studentId) async {
    final summary = await getStudentProgress(studentId);
    final students = await getLinkedStudents('parent_1');
    final student = students.firstWhere((s) => s.studentId == studentId,
      orElse: () => students.first);

    return StudentProgress(
      studentId: studentId,
      studentName: student.name,
      avatarUrl: student.avatarUrl ?? '',
      totalStudyTime: summary.weeklyProgress.timeSpent.inMinutes,
      overallAccuracy: summary.weeklyProgress.accuracy,
      currentStreak: 7,
      recentActivities: [
        RecentActivity(
          type: 'lesson',
          description: 'Completed Algebra lesson',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        RecentActivity(
          type: 'achievement',
          description: 'Earned Math Master badge',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ],
      subjectProgress: summary.subjectProgress.map((k, v) => MapEntry(
        k,
        SubjectProgress(
          subject: v.subject,
          accuracy: v.accuracy,
          questionsAnswered: 50,
        ),
      )),
      strengths: ['Algebra', 'Geometry'],
      weaknesses: ['Fractions', 'Word Problems'],
      studyHabits: {
        'Consistency': 'Excellent',
        'Focus Time': 'Good',
        'Practice Frequency': 'Very Good',
      },
      recommendations: [
        'Focus more on fraction problems',
        'Try word problem practice sessions',
        'Maintain current study schedule',
      ],
      alerts: [
        Alert(type: 'warning', message: 'Accuracy dropped in fractions'),
        Alert(type: 'success', message: 'Excellent progress in geometry'),
      ],
    );
  }
}
