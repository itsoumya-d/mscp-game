import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_save_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Connectivity _connectivity = Connectivity();

  // User management
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // Authentication
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print('Anonymous sign-in failed: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Email sign-in failed: $e');
      return null;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('User creation failed: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // User profile management
  Future<void> createUserProfile({
    required String displayName,
    String? photoURL,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!isLoggedIn) return;

    final userData = {
      'uid': currentUser!.uid,
      'displayName': displayName,
      'email': currentUser!.email,
      'photoURL': photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
      'totalXP': 0,
      'currentLevel': 1,
      'streak': 0,
      'achievements': [],
      'preferences': {
        'notifications': true,
        'soundEnabled': true,
        'darkMode': true,
      },
      ...?additionalData,
    };

    await _firestore.collection('users').doc(currentUser!.uid).set(userData);
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isLoggedIn) return null;

    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Failed to get user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (!isLoggedIn) return;

    data['lastActive'] = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(currentUser!.uid).update(data);
  }

  // Game progress and sessions
  Future<void> saveGameSession(GameSession session) async {
    if (!isLoggedIn) return;

    final sessionData = {
      'id': session.id,
      'subject': session.subject.name,
      'skillId': session.skillId,
      'questions': session.questions.map((q) => q.toJson()).toList(),
      'userAnswers': session.userAnswers,
      'score': session.score,
      'currentQuestionIndex': session.currentQuestionIndex,
      'startTime': session.startTime.toIso8601String(),
      'lives': session.lives,
      'completedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('gameSessions')
        .doc(session.id)
        .set(sessionData);

    // Update user stats
    await _updateUserStats(session);
  }

  Future<void> _updateUserStats(GameSession session) async {
    if (!isLoggedIn) return;

    final userRef = _firestore.collection('users').doc(currentUser!.uid);

    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      final userData = userDoc.data() ?? {};

      final currentXP = userData['totalXP'] ?? 0;
      final newXP = currentXP + session.score; // Use score as XP
      final newLevel = _calculateLevel(newXP);

      transaction.update(userRef, {
        'totalXP': newXP,
        'currentLevel': newLevel,
        'lastActive': FieldValue.serverTimestamp(),
        'gamesPlayed': FieldValue.increment(1),
        'totalScore': FieldValue.increment(session.score),
      });
    });
  }

  int _calculateLevel(int xp) {
    // Level calculation: Level = floor(sqrt(XP / 100)) + 1
    return ((xp / 100).toDouble()).floor() + 1;
  }

  // Level unlocking system
  Future<void> unlockLevel(String subjectId, String skillId) async {
    if (!isLoggedIn) return;

    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('unlockedLevels')
        .doc('${subjectId}_$skillId')
        .set({
      'subjectId': subjectId,
      'skillId': skillId,
      'unlockedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<String>> getUnlockedLevels(String subjectId) async {
    if (!isLoggedIn) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('unlockedLevels')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()['skillId'] as String).toList();
    } catch (e) {
      print('Failed to get unlocked levels: $e');
      return [];
    }
  }

  // Achievements
  Future<void> unlockAchievement(String achievementId, Map<String, dynamic> achievementData) async {
    if (!isLoggedIn) return;

    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('achievements')
        .doc(achievementId)
        .set({
      'achievementId': achievementId,
      'unlockedAt': FieldValue.serverTimestamp(),
      ...achievementData,
    });

    // Add to user's achievement list
    await _firestore.collection('users').doc(currentUser!.uid).update({
      'achievements': FieldValue.arrayUnion([achievementId]),
    });
  }

  Future<List<Map<String, dynamic>>> getUserAchievements() async {
    if (!isLoggedIn) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('achievements')
          .orderBy('unlockedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Failed to get achievements: $e');
      return [];
    }
  }

  // Leaderboards
  Future<List<Map<String, dynamic>>> getLeaderboard({
    String orderBy = 'totalXP',
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy(orderBy, descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'displayName': data['displayName'] ?? 'Anonymous',
          'totalXP': data['totalXP'] ?? 0,
          'currentLevel': data['currentLevel'] ?? 1,
          'photoURL': data['photoURL'],
        };
      }).toList();
    } catch (e) {
      print('Failed to get leaderboard: $e');
      return [];
    }
  }

  // Offline sync
  Future<void> syncOfflineData() async {
    if (!isLoggedIn) return;

    final prefs = await SharedPreferences.getInstance();
    final offlineSessionsJson = prefs.getString('offline_game_sessions');
    
    if (offlineSessionsJson != null) {
      try {
        final List<dynamic> offlineSessions = jsonDecode(offlineSessionsJson);
        
        for (final sessionData in offlineSessions) {
          final session = GameSession.fromJson(sessionData);
          await saveGameSession(session);
        }
        
        // Clear offline data after successful sync
        await prefs.remove('offline_game_sessions');
        print('Synced ${offlineSessions.length} offline sessions');
      } catch (e) {
        print('Failed to sync offline data: $e');
      }
    }
  }

  Future<void> saveOfflineGameSession(GameSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString('offline_game_sessions') ?? '[]';
    final List<dynamic> sessions = jsonDecode(existingJson);
    
    sessions.add(session.toJson());
    await prefs.setString('offline_game_sessions', jsonEncode(sessions));
  }

  // Connectivity monitoring
  Future<bool> isConnected() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    return connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
  }

  Stream<List<ConnectivityResult>> get connectivityStream => _connectivity.onConnectivityChanged;

  // Real-time listeners
  Stream<DocumentSnapshot> getUserProfileStream() {
    if (!isLoggedIn) throw Exception('User not logged in');
    return _firestore.collection('users').doc(currentUser!.uid).snapshots();
  }

  Stream<QuerySnapshot> getGameSessionsStream() {
    if (!isLoggedIn) throw Exception('User not logged in');
    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('gameSessions')
        .orderBy('completedAt', descending: true)
        .snapshots();
  }

  // Cloud storage for assets
  Future<String?> uploadFile(String path, List<int> data) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.putData(Uint8List.fromList(data));
      return await ref.getDownloadURL();
    } catch (e) {
      print('File upload failed: $e');
      return null;
    }
  }

  Future<List<int>?> downloadFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getData();
    } catch (e) {
      print('File download failed: $e');
      return null;
    }
  }
}