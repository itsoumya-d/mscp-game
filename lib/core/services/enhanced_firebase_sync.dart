import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/models/user.dart' as app_user;
import 'package:sp/core/models/educational_game.dart';

/// Enhanced Firebase integration for real-time progress sync and content distribution
class EnhancedFirebaseSync {
  static final EnhancedFirebaseSync instance = EnhancedFirebaseSync._();
  EnhancedFirebaseSync._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription? _progressSubscription;
  StreamSubscription? _contentSubscription;
  bool _isInitialized = false;

  /// Initialize Firebase sync
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing enhanced Firebase sync...');

      // Setup real-time listeners
      await _setupProgressSync();
      await _setupContentSync();

      _isInitialized = true;
      debugPrint('Enhanced Firebase sync initialized');
    } catch (e) {
      debugPrint('Error initializing Firebase sync: $e');
    }
  }

  /// Setup real-time progress synchronization
  Future<void> _setupProgressSync() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _progressSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('progress')
        .snapshots()
        .listen(
      (snapshot) {
        _handleProgressUpdate(snapshot);
      },
      onError: (error) {
        debugPrint('Progress sync error: $error');
      },
    );

    debugPrint('Progress sync listener setup complete');
  }

  /// Setup real-time content synchronization
  Future<void> _setupContentSync() async {
    _contentSubscription = _firestore
        .collection('generated_content')
        .where('status', isEqualTo: 'ready')
        .snapshots()
        .listen(
      (snapshot) {
        _handleContentUpdate(snapshot);
      },
      onError: (error) {
        debugPrint('Content sync error: $error');
      },
    );

    debugPrint('Content sync listener setup complete');
  }

  /// Handle progress updates from Firebase
  void _handleProgressUpdate(QuerySnapshot snapshot) {
    for (final doc in snapshot.docChanges) {
      if (doc.type == DocumentChangeType.modified ||
          doc.type == DocumentChangeType.added) {
        final data = doc.doc.data() as Map<String, dynamic>;
        debugPrint('Progress updated: ${data['subject']} - ${data['progress']}%');
        
        // Trigger local progress update
        _syncProgressToLocal(data);
      }
    }
  }

  /// Handle content updates from Firebase
  void _handleContentUpdate(QuerySnapshot snapshot) {
    for (final doc in snapshot.docChanges) {
      if (doc.type == DocumentChangeType.added) {
        final data = doc.doc.data() as Map<String, dynamic>;
        debugPrint('New content available: ${data['subject']} - ${data['title']}');
        
        // Download and cache new content
        _downloadNewContent(data);
      }
    }
  }

  /// Sync progress to local storage
  Future<void> _syncProgressToLocal(Map<String, dynamic> data) async {
    // Implementation would update local progress database
    debugPrint('Syncing progress to local: ${data['subject']}');
  }

  /// Download new content from Firebase
  Future<void> _downloadNewContent(Map<String, dynamic> data) async {
    // Implementation would download and cache content
    debugPrint('Downloading new content: ${data['title']}');
  }

  /// Upload user progress to Firebase
  Future<void> uploadProgress({
    required SubjectType subject,
    required String skillId,
    required int correctAnswers,
    required int totalAnswers,
    required int xpEarned,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc('${subject.name}_$skillId')
          .set({
        'subject': subject.name,
        'skillId': skillId,
        'correctAnswers': correctAnswers,
        'totalAnswers': totalAnswers,
        'xpEarned': xpEarned,
        'progress': (correctAnswers / totalAnswers * 100).round(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Progress uploaded for ${subject.name}');
    } catch (e) {
      debugPrint('Error uploading progress: $e');
    }
  }

  /// Upload generated content to Firebase
  Future<void> uploadGeneratedContent({
    required SubjectType subject,
    required GameChapter chapter,
  }) async {
    try {
      await _firestore
          .collection('generated_content')
          .doc(chapter.id)
          .set({
        'subject': subject.name,
        'chapterId': chapter.id,
        'title': chapter.title,
        'description': chapter.description,
        'lessonsCount': chapter.lessons.length,
        'status': 'ready',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Upload lessons
      for (final lesson in chapter.lessons) {
        await _uploadLesson(chapter.id, lesson);
      }

      debugPrint('Content uploaded: ${chapter.title}');
    } catch (e) {
      debugPrint('Error uploading content: $e');
    }
  }

  /// Upload a lesson to Firebase
  Future<void> _uploadLesson(String chapterId, GameLesson lesson) async {
    try {
      await _firestore
          .collection('generated_content')
          .doc(chapterId)
          .collection('lessons')
          .doc(lesson.id)
          .set({
        'lessonId': lesson.id,
        'title': lesson.title,
        'description': lesson.description,
        'gamesCount': lesson.games.length,
        'level': lesson.level,
        'isUnlocked': lesson.isUnlocked,
      });

      debugPrint('Lesson uploaded: ${lesson.title}');
    } catch (e) {
      debugPrint('Error uploading lesson: $e');
    }
  }

  /// Sync user data across devices
  Future<void> syncUserData(app_user.User user) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    try {
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'level': user.level,
        'totalXP': user.totalXP,
        'gems': user.gems,
        'coins': user.coins,
        'lives': user.lives,
        'currentStreak': user.currentStreak,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('User data synced');
    } catch (e) {
      debugPrint('Error syncing user data: $e');
    }
  }

  /// Download user data from Firebase
  Future<Map<String, dynamic>?> downloadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        debugPrint('User data downloaded');
        return doc.data();
      }
    } catch (e) {
      debugPrint('Error downloading user data: $e');
    }

    return null;
  }

  /// Get all progress for a subject
  Future<List<Map<String, dynamic>>> getSubjectProgress(SubjectType subject) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .where('subject', isEqualTo: subject.name)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting subject progress: $e');
      return [];
    }
  }

  /// Get available content for a subject
  Future<List<Map<String, dynamic>>> getAvailableContent(SubjectType subject) async {
    try {
      final snapshot = await _firestore
          .collection('generated_content')
          .where('subject', isEqualTo: subject.name)
          .where('status', isEqualTo: 'ready')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting available content: $e');
      return [];
    }
  }

  /// Check for content updates
  Future<bool> hasContentUpdates(SubjectType subject, DateTime lastCheck) async {
    try {
      final snapshot = await _firestore
          .collection('generated_content')
          .where('subject', isEqualTo: subject.name)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(lastCheck))
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking content updates: $e');
      return false;
    }
  }

  /// Cleanup and dispose
  void dispose() {
    _progressSubscription?.cancel();
    _contentSubscription?.cancel();
    _isInitialized = false;
    debugPrint('Enhanced Firebase sync disposed');
  }

  /// Get sync status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'hasProgressSync': _progressSubscription != null,
      'hasContentSync': _contentSubscription != null,
      'isAuthenticated': _auth.currentUser != null,
    };
  }
}

/// Firebase sync manager for coordinating all sync operations
class FirebaseSyncManager {
  static final FirebaseSyncManager instance = FirebaseSyncManager._();
  FirebaseSyncManager._();

  final EnhancedFirebaseSync _sync = EnhancedFirebaseSync.instance;
  Timer? _periodicSyncTimer;

  /// Initialize sync manager
  Future<void> initialize() async {
    await _sync.initialize();

    // Setup periodic sync every 5 minutes
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performPeriodicSync(),
    );

    debugPrint('Firebase sync manager initialized');
  }

  /// Perform periodic sync
  Future<void> _performPeriodicSync() async {
    debugPrint('Performing periodic sync...');
    
    // Sync operations would go here
    // This is called automatically every 5 minutes
    
    debugPrint('Periodic sync complete');
  }

  /// Trigger immediate sync
  Future<void> syncNow() async {
    debugPrint('Triggering immediate sync...');
    await _performPeriodicSync();
  }

  /// Dispose sync manager
  void dispose() {
    _periodicSyncTimer?.cancel();
    _sync.dispose();
    debugPrint('Firebase sync manager disposed');
  }
}

