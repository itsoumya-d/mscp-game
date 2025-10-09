import 'package:cloud_firestore/cloud_firestore.dart';

/// Challenge types
enum ChallengeType {
  oneVsOne,
  tournament,
  daily,
  weekly,
}

/// Challenge status
enum ChallengeStatus {
  pending,
  active,
  completed,
  expired,
}

/// Challenge Service - Task D3 Implementation
/// 1v1 challenges, tournaments, and daily challenges
class ChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create 1v1 challenge
  Future<String?> createOneVsOneChallenge({
    required String challengerId,
    required String opponentId,
    required String topicId,
    required int questionCount,
    required int difficulty,
  }) async {
    try {
      final docRef = await _firestore.collection('challenges').add({
        'type': ChallengeType.oneVsOne.toString(),
        'challengerId': challengerId,
        'opponentId': opponentId,
        'topicId': topicId,
        'questionCount': questionCount,
        'difficulty': difficulty,
        'status': ChallengeStatus.pending.toString(),
        'challengerScore': null,
        'opponentScore': null,
        'winnerId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 3)),
        ),
      });

      // Send notification to opponent
      await _firestore.collection('notifications').add({
        'userId': opponentId,
        'type': 'challenge_received',
        'message': 'You have been challenged!',
        'data': {'challengeId': docRef.id},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error creating challenge: $e');
      return null;
    }
  }

  /// Accept challenge
  Future<bool> acceptChallenge(String challengeId) async {
    try {
      await _firestore.collection('challenges').doc(challengeId).update({
        'status': ChallengeStatus.active.toString(),
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error accepting challenge: $e');
      return false;
    }
  }

  /// Submit challenge score
  Future<bool> submitChallengeScore({
    required String challengeId,
    required String userId,
    required int score,
    required int timeSpent,
  }) async {
    try {
      final challengeDoc = await _firestore
          .collection('challenges')
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) return false;

      final data = challengeDoc.data()!;
      final challengerId = data['challengerId'] as String;
      final opponentId = data['opponentId'] as String;

      // Determine which score to update
      final isChallenger = userId == challengerId;
      final scoreField = isChallenger ? 'challengerScore' : 'opponentScore';
      final timeField = isChallenger ? 'challengerTime' : 'opponentTime';

      await _firestore.collection('challenges').doc(challengeId).update({
        scoreField: score,
        timeField: timeSpent,
        '${scoreField}SubmittedAt': FieldValue.serverTimestamp(),
      });

      // Check if both scores are submitted
      final updatedDoc = await _firestore
          .collection('challenges')
          .doc(challengeId)
          .get();
      final updatedData = updatedDoc.data()!;

      if (updatedData['challengerScore'] != null &&
          updatedData['opponentScore'] != null) {
        // Determine winner
        final challengerScore = updatedData['challengerScore'] as int;
        final opponentScore = updatedData['opponentScore'] as int;
        final challengerTime = updatedData['challengerTime'] as int;
        final opponentTime = updatedData['opponentTime'] as int;

        String? winnerId;
        if (challengerScore > opponentScore) {
          winnerId = challengerId;
        } else if (opponentScore > challengerScore) {
          winnerId = opponentId;
        } else {
          // Tie - winner is who finished faster
          winnerId = challengerTime < opponentTime ? challengerId : opponentId;
        }

        // Update challenge with winner
        await _firestore.collection('challenges').doc(challengeId).update({
          'status': ChallengeStatus.completed.toString(),
          'winnerId': winnerId,
          'completedAt': FieldValue.serverTimestamp(),
        });

        // Award XP to winner
        await _awardChallengeXP(winnerId, 100);

        // Send notifications
        await _sendChallengeResultNotifications(
          challengeId: challengeId,
          challengerId: challengerId,
          opponentId: opponentId,
          winnerId: winnerId,
        );
      }

      return true;
    } catch (e) {
      print('Error submitting challenge score: $e');
      return false;
    }
  }

  /// Get user's challenges
  Future<List<Challenge>> getUserChallenges(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('challenges')
          .where('type', isEqualTo: ChallengeType.oneVsOne.toString())
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final challenges = <Challenge>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final challengerId = data['challengerId'] as String;
        final opponentId = data['opponentId'] as String;

        // Only include challenges where user is involved
        if (challengerId == userId || opponentId == userId) {
          challenges.add(Challenge(
            id: doc.id,
            type: ChallengeType.oneVsOne,
            challengerId: challengerId,
            opponentId: opponentId,
            topicId: data['topicId'] as String,
            questionCount: data['questionCount'] as int,
            difficulty: data['difficulty'] as int,
            status: ChallengeStatus.values.firstWhere(
              (s) => s.toString() == data['status'],
            ),
            challengerScore: data['challengerScore'] as int?,
            opponentScore: data['opponentScore'] as int?,
            winnerId: data['winnerId'] as String?,
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
            currentProgress: data['currentProgress'] as int? ?? 0,
            targetValue: data['targetValue'] as int? ?? 10,
            title: data['title'] as String? ?? 'Challenge',
            description: data['description'] as String? ?? '',
            rewardXp: data['rewardXp'] as int? ?? 100,
          ));
        }
      }

      return challenges;
    } catch (e) {
      print('Error getting user challenges: $e');
      return [];
    }
  }

  /// Create daily challenge
  Future<String?> createDailyChallenge({
    required String topicId,
    required int questionCount,
    required int difficulty,
    required int rewardXP,
  }) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final docRef = await _firestore.collection('daily_challenges').add({
        'type': ChallengeType.daily.toString(),
        'topicId': topicId,
        'questionCount': questionCount,
        'difficulty': difficulty,
        'rewardXP': rewardXP,
        'startDate': Timestamp.fromDate(startOfDay),
        'endDate': Timestamp.fromDate(endOfDay),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error creating daily challenge: $e');
      return null;
    }
  }

  /// Get today's daily challenge
  Future<DailyChallenge?> getTodaysDailyChallenge() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final snapshot = await _firestore
          .collection('daily_challenges')
          .where('startDate', isEqualTo: Timestamp.fromDate(startOfDay))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();

      return DailyChallenge(
        id: doc.id,
        topicId: data['topicId'] as String,
        questionCount: data['questionCount'] as int,
        difficulty: data['difficulty'] as int,
        rewardXP: data['rewardXP'] as int,
        startDate: (data['startDate'] as Timestamp).toDate(),
        endDate: (data['endDate'] as Timestamp).toDate(),
      );
    } catch (e) {
      print('Error getting daily challenge: $e');
      return null;
    }
  }

  /// Complete daily challenge
  Future<bool> completeDailyChallenge({
    required String userId,
    required String challengeId,
    required int score,
  }) async {
    try {
      // Check if already completed today
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final existingCompletion = await _firestore
          .collection('daily_challenge_completions')
          .where('userId', isEqualTo: userId)
          .where('challengeId', isEqualTo: challengeId)
          .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      if (existingCompletion.docs.isNotEmpty) {
        return false; // Already completed today
      }

      // Get challenge details
      final challengeDoc = await _firestore
          .collection('daily_challenges')
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) return false;

      final rewardXP = challengeDoc.data()!['rewardXP'] as int;

      // Record completion
      await _firestore.collection('daily_challenge_completions').add({
        'userId': userId,
        'challengeId': challengeId,
        'score': score,
        'rewardXP': rewardXP,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Award XP
      await _awardChallengeXP(userId, rewardXP);

      return true;
    } catch (e) {
      print('Error completing daily challenge: $e');
      return false;
    }
  }

  /// Award XP for challenge
  Future<void> _awardChallengeXP(String userId, int xp) async {
    await _firestore.collection('users').doc(userId).update({
      'totalXP': FieldValue.increment(xp),
    });
  }

  /// Send challenge result notifications
  Future<void> _sendChallengeResultNotifications({
    required String challengeId,
    required String challengerId,
    required String opponentId,
    required String winnerId,
  }) async {
    final batch = _firestore.batch();

    // Notification to winner
    batch.set(
      _firestore.collection('notifications').doc(),
      {
        'userId': winnerId,
        'type': 'challenge_won',
        'message': 'You won the challenge! 🎉',
        'data': {'challengeId': challengeId},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    // Notification to loser
    final loserId = winnerId == challengerId ? opponentId : challengerId;
    batch.set(
      _firestore.collection('notifications').doc(),
      {
        'userId': loserId,
        'type': 'challenge_lost',
        'message': 'Challenge completed. Better luck next time!',
        'data': {'challengeId': challengeId},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }
}

/// Challenge model
class Challenge {
  final String id;
  final ChallengeType type;
  final String challengerId;
  final String opponentId;
  final String topicId;
  final int questionCount;
  final int difficulty;
  final ChallengeStatus status;
  final int? challengerScore;
  final int? opponentScore;
  final String? winnerId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int currentProgress;
  final int targetValue;
  final String title;
  final String description;
  final int rewardXp;

  Challenge({
    required this.id,
    required this.type,
    required this.challengerId,
    required this.opponentId,
    required this.topicId,
    required this.questionCount,
    required this.difficulty,
    required this.status,
    this.challengerScore,
    this.opponentScore,
    this.winnerId,
    required this.createdAt,
    this.expiresAt,
    required this.currentProgress,
    required this.targetValue,
    required this.title,
    required this.description,
    required this.rewardXp,
  });
}

extension ChallengeServiceExtension on ChallengeService {
  /// Get daily challenge
  Future<Challenge?> getDailyChallenge() async {
    // Mock daily challenge
    return Challenge(
      id: 'daily_${DateTime.now().day}',
      type: ChallengeType.daily,
      challengerId: 'system',
      opponentId: '',
      topicId: 'algebra',
      questionCount: 10,
      difficulty: 2,
      status: ChallengeStatus.active,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      currentProgress: 3,
      targetValue: 10,
      title: 'Daily Math Challenge',
      description: 'Complete 10 algebra questions',
      rewardXp: 100,
    );
  }

  /// Get active challenges for user
  Future<List<Challenge>> getActiveChallenges(String userId) async {
    // Mock active challenges
    return [
      Challenge(
        id: 'challenge_1',
        type: ChallengeType.oneVsOne,
        challengerId: userId,
        opponentId: 'opponent_1',
        topicId: 'geometry',
        questionCount: 5,
        difficulty: 2,
        status: ChallengeStatus.active,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        currentProgress: 2,
        targetValue: 5,
        title: 'Geometry Duel',
        description: 'First to answer 5 questions correctly wins',
        rewardXp: 150,
      ),
    ];
  }
}

/// Daily challenge model
class DailyChallenge {
  final String id;
  final String topicId;
  final int questionCount;
  final int difficulty;
  final int rewardXP;
  final DateTime startDate;
  final DateTime endDate;

  DailyChallenge({
    required this.id,
    required this.topicId,
    required this.questionCount,
    required this.difficulty,
    required this.rewardXP,
    required this.startDate,
    required this.endDate,
  });
}

