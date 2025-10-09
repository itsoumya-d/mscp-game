import 'package:cloud_firestore/cloud_firestore.dart';

/// League tiers
enum League {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

/// Leaderboard types
enum LeaderboardType {
  global,
  friends,
  classRoom,
}

/// Leaderboard Service - Task D1 Implementation
/// Global, friends, and class leaderboards with league system
class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user's current league
  Future<League> getUserLeague(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final xp = (doc.data()?['totalXP'] ?? 0) as int;
      
      return _calculateLeague(xp);
    } catch (e) {
      print('Error getting user league: $e');
      return League.bronze;
    }
  }

  /// Calculate league based on XP
  League _calculateLeague(int xp) {
    if (xp >= 10000) return League.diamond;
    if (xp >= 5000) return League.platinum;
    if (xp >= 2000) return League.gold;
    if (xp >= 500) return League.silver;
    return League.bronze;
  }

  /// Get leaderboard entries
  Future<List<LeaderboardEntry>> getLeaderboard({
    required LeaderboardType type,
    required String userId,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection('users');

      switch (type) {
        case LeaderboardType.global:
          // Get top users globally
          query = query.orderBy('totalXP', descending: true).limit(limit);
          break;
          
        case LeaderboardType.friends:
          // Get user's friends
          final friendIds = await _getUserFriendIds(userId);
          if (friendIds.isEmpty) return [];
          
          query = query
              .where(FieldPath.documentId, whereIn: friendIds)
              .orderBy('totalXP', descending: true);
          break;
          
        case LeaderboardType.classRoom:
          // Get users in same class
          final userDoc = await _firestore.collection('users').doc(userId).get();
          final classId = userDoc.data()?['classId'];
          
          if (classId == null) return [];
          
          query = query
              .where('classId', isEqualTo: classId)
              .orderBy('totalXP', descending: true)
              .limit(limit);
          break;
      }

      final snapshot = await query.get();
      final entries = <LeaderboardEntry>[];
      
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data() as Map<String, dynamic>;
        
        entries.add(LeaderboardEntry(
          userId: doc.id,
          username: data['username'] ?? 'User',
          avatarUrl: data['avatarUrl'],
          totalXP: data['totalXP'] ?? 0,
          rank: i + 1,
          league: _calculateLeague(data['totalXP'] ?? 0),
          isCurrentUser: doc.id == userId,
          level: data['level'] ?? 1,
          xp: data['totalXP'] ?? 0,
          streak: data['currentStreak'] ?? 0,
        ));
      }

      return entries;
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }

  /// Get user's rank
  Future<int> getUserRank(String userId, LeaderboardType type) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userXP = (userDoc.data()?['totalXP'] ?? 0) as int;

      Query query = _firestore.collection('users');

      switch (type) {
        case LeaderboardType.global:
          query = query.where('totalXP', isGreaterThan: userXP);
          break;
          
        case LeaderboardType.friends:
          final friendIds = await _getUserFriendIds(userId);
          if (friendIds.isEmpty) return 1;
          
          query = query
              .where(FieldPath.documentId, whereIn: friendIds)
              .where('totalXP', isGreaterThan: userXP);
          break;
          
        case LeaderboardType.classRoom:
          final classId = userDoc.data()?['classId'];
          if (classId == null) return 1;
          
          query = query
              .where('classId', isEqualTo: classId)
              .where('totalXP', isGreaterThan: userXP);
          break;
      }

      final snapshot = await query.get();
      return snapshot.docs.length + 1;
    } catch (e) {
      print('Error getting user rank: $e');
      return 1;
    }
  }

  /// Get league leaderboard (users in same league)
  Future<List<LeaderboardEntry>> getLeagueLeaderboard({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final userLeague = await getUserLeague(userId);
      final (minXP, maxXP) = _getLeagueXPRange(userLeague);

      final snapshot = await _firestore
          .collection('users')
          .where('totalXP', isGreaterThanOrEqualTo: minXP)
          .where('totalXP', isLessThan: maxXP)
          .orderBy('totalXP', descending: true)
          .limit(limit)
          .get();

      final entries = <LeaderboardEntry>[];
      
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        
        entries.add(LeaderboardEntry(
          userId: doc.id,
          username: data['username'] ?? 'User',
          avatarUrl: data['avatarUrl'],
          totalXP: data['totalXP'] ?? 0,
          rank: i + 1,
          league: userLeague,
          isCurrentUser: doc.id == userId,
          level: data['level'] ?? 1,
          xp: data['totalXP'] ?? 0,
          streak: data['currentStreak'] ?? 0,
        ));
      }

      return entries;
    } catch (e) {
      print('Error getting league leaderboard: $e');
      return [];
    }
  }

  /// Get XP range for league
  (int, int) _getLeagueXPRange(League league) {
    switch (league) {
      case League.bronze:
        return (0, 500);
      case League.silver:
        return (500, 2000);
      case League.gold:
        return (2000, 5000);
      case League.platinum:
        return (5000, 10000);
      case League.diamond:
        return (10000, 999999999);
    }
  }

  /// Check for league promotion/relegation
  Future<LeagueChange?> checkLeagueChange(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data()!;
      
      final currentXP = (data['totalXP'] ?? 0) as int;
      final previousLeague = data['league'] != null
          ? League.values.firstWhere((l) => l.toString() == data['league'])
          : League.bronze;
      
      final newLeague = _calculateLeague(currentXP);

      if (newLeague != previousLeague) {
        // Update user's league
        await _firestore.collection('users').doc(userId).update({
          'league': newLeague.toString(),
        });

        return LeagueChange(
          previousLeague: previousLeague,
          newLeague: newLeague,
          isPromotion: newLeague.index > previousLeague.index,
        );
      }

      return null;
    } catch (e) {
      print('Error checking league change: $e');
      return null;
    }
  }

  /// Get user's friend IDs
  Future<List<String>> _getUserFriendIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting friend IDs: $e');
      return [];
    }
  }

  /// Update user XP and check for league changes
  Future<LeagueChange?> updateUserXP(String userId, int xpToAdd) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'totalXP': FieldValue.increment(xpToAdd),
      });

      return await checkLeagueChange(userId);
    } catch (e) {
      print('Error updating user XP: $e');
      return null;
    }
  }

  /// Get league icon
  String getLeagueIcon(League league) {
    switch (league) {
      case League.bronze:
        return '🥉';
      case League.silver:
        return '🥈';
      case League.gold:
        return '🥇';
      case League.platinum:
        return '💎';
      case League.diamond:
        return '👑';
    }
  }

  /// Get league color
  String getLeagueColor(League league) {
    switch (league) {
      case League.bronze:
        return '#CD7F32';
      case League.silver:
        return '#C0C0C0';
      case League.gold:
        return '#FFD700';
      case League.platinum:
        return '#E5E4E2';
      case League.diamond:
        return '#B9F2FF';
    }
  }
}

/// Leaderboard entry model
class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int totalXP;
  final int rank;
  final League league;
  final bool isCurrentUser;
  final int level;
  final int xp;
  final int streak;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.totalXP,
    required this.rank,
    required this.league,
    required this.isCurrentUser,
    required this.level,
    required this.xp,
    required this.streak,
  });
}

/// League change model
class LeagueChange {
  final League previousLeague;
  final League newLeague;
  final bool isPromotion;

  LeagueChange({
    required this.previousLeague,
    required this.newLeague,
    required this.isPromotion,
  });
}

extension LeaderboardServiceExtension on LeaderboardService {
  /// Get global leaderboard with limit
  Future<List<LeaderboardEntry>> getGlobalLeaderboard({int limit = 50}) async {
    return await getLeaderboard(
      type: LeaderboardType.global,
      userId: 'current_user',
      limit: limit,
    );
  }

  /// Get friends leaderboard
  Future<List<LeaderboardEntry>> getFriendsLeaderboard(String userId) async {
    return await getLeaderboard(
      type: LeaderboardType.friends,
      userId: userId,
      limit: 50,
    );
  }
}

