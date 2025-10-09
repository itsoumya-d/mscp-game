import 'package:cloud_firestore/cloud_firestore.dart';

/// Friend request status
enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
}

/// Friend Service - Task D2 Implementation
/// Friend system with requests, suggestions, and activity feed
class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send friend request
  Future<bool> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      // Check if already friends or request exists
      final existingRequest = await _firestore
          .collection('friend_requests')
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        return false; // Request already exists
      }

      // Create friend request
      await _firestore.collection('friend_requests').add({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'status': FriendRequestStatus.pending.toString(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send notification
      await _sendNotification(
        userId: toUserId,
        type: 'friend_request',
        message: 'You have a new friend request',
        data: {'fromUserId': fromUserId},
      );

      return true;
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  }

  /// Accept friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      final requestDoc = await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) return false;

      final data = requestDoc.data()!;
      final fromUserId = data['fromUserId'] as String;
      final toUserId = data['toUserId'] as String;

      // Update request status
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': FriendRequestStatus.accepted.toString(),
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Add to friends collection (bidirectional)
      final batch = _firestore.batch();

      batch.set(
        _firestore.collection('users').doc(fromUserId).collection('friends').doc(toUserId),
        {
          'userId': toUserId,
          'addedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        _firestore.collection('users').doc(toUserId).collection('friends').doc(fromUserId),
        {
          'userId': fromUserId,
          'addedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      // Send notification
      await _sendNotification(
        userId: fromUserId,
        type: 'friend_accepted',
        message: 'Your friend request was accepted',
        data: {'userId': toUserId},
      );

      return true;
    } catch (e) {
      print('Error accepting friend request: $e');
      return false;
    }
  }

  /// Reject friend request
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': FriendRequestStatus.rejected.toString(),
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error rejecting friend request: $e');
      return false;
    }
  }

  /// Remove friend
  Future<bool> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    try {
      final batch = _firestore.batch();

      batch.delete(
        _firestore.collection('users').doc(userId).collection('friends').doc(friendId),
      );

      batch.delete(
        _firestore.collection('users').doc(friendId).collection('friends').doc(userId),
      );

      await batch.commit();
      return true;
    } catch (e) {
      print('Error removing friend: $e');
      return false;
    }
  }

  /// Get friends list
  Future<List<Friend>> getFriends(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .orderBy('addedAt', descending: true)
          .get();

      final friends = <Friend>[];

      for (var doc in snapshot.docs) {
        final friendId = doc.data()['userId'] as String;
        final friendDoc = await _firestore.collection('users').doc(friendId).get();

        if (friendDoc.exists) {
          final friendData = friendDoc.data()!;
          friends.add(Friend(
            userId: friendId,
            username: friendData['username'] ?? 'User',
            avatarUrl: friendData['avatarUrl'],
            totalXP: friendData['totalXP'] ?? 0,
            currentStreak: friendData['currentStreak'] ?? 0,
            addedAt: (doc.data()['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ));
        }
      }

      return friends;
    } catch (e) {
      print('Error getting friends: $e');
      return [];
    }
  }

  /// Get pending friend requests
  Future<List<FriendRequest>> getPendingRequests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('friend_requests')
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: FriendRequestStatus.pending.toString())
          .orderBy('createdAt', descending: true)
          .get();

      final requests = <FriendRequest>[];

      for (var doc in snapshot.docs) {
        final fromUserId = doc.data()['fromUserId'] as String;
        final userDoc = await _firestore.collection('users').doc(fromUserId).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          requests.add(FriendRequest(
            id: doc.id,
            fromUserId: fromUserId,
            fromUsername: userData['username'] ?? 'User',
            fromAvatarUrl: userData['avatarUrl'],
            createdAt: (doc.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ));
        }
      }

      return requests;
    } catch (e) {
      print('Error getting pending requests: $e');
      return [];
    }
  }

  /// Get friend suggestions (users with similar interests)
  Future<List<UserSuggestion>> getFriendSuggestions(String userId) async {
    try {
      // Get user's interests and friends
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data()!;
      final userInterests = List<String>.from(userData['interests'] ?? []);
      
      final friendIds = await _getFriendIds(userId);

      // Find users with similar interests
      final suggestions = <UserSuggestion>[];

      if (userInterests.isNotEmpty) {
        final snapshot = await _firestore
            .collection('users')
            .where('interests', arrayContainsAny: userInterests.take(10).toList())
            .limit(20)
            .get();

        for (var doc in snapshot.docs) {
          if (doc.id == userId || friendIds.contains(doc.id)) continue;

          final data = doc.data();
          final theirInterests = List<String>.from(data['interests'] ?? []);
          final commonInterests = userInterests.where((i) => theirInterests.contains(i)).toList();

          if (commonInterests.isNotEmpty) {
            suggestions.add(UserSuggestion(
              userId: doc.id,
              username: data['username'] ?? 'User',
              avatarUrl: data['avatarUrl'],
              totalXP: data['totalXP'] ?? 0,
              commonInterests: commonInterests,
              mutualFriends: 0, // TODO: Calculate mutual friends
            ));
          }
        }
      }

      // Sort by number of common interests
      suggestions.sort((a, b) => b.commonInterests.length.compareTo(a.commonInterests.length));

      return suggestions.take(10).toList();
    } catch (e) {
      print('Error getting friend suggestions: $e');
      return [];
    }
  }

  /// Search users
  Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserSearchResult(
          userId: doc.id,
          username: data['username'] ?? 'User',
          avatarUrl: data['avatarUrl'],
          totalXP: data['totalXP'] ?? 0,
        );
      }).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Get friend IDs
  Future<List<String>> _getFriendIds(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .get();

    return snapshot.docs.map((doc) => doc.data()['userId'] as String).toList();
  }

  /// Send notification
  Future<void> _sendNotification({
    required String userId,
    required String type,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'type': type,
      'message': message,
      'data': data,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Friend model
class Friend {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int totalXP;
  final int currentStreak;
  final DateTime addedAt;

  Friend({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.totalXP,
    required this.currentStreak,
    required this.addedAt,
  });

  // Convenience getters
  int get level => (totalXP / 100).floor();
  int get xp => totalXP;
}

/// Friend request model
class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromUsername;
  final String? fromAvatarUrl;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUsername,
    this.fromAvatarUrl,
    required this.createdAt,
  });

  // Convenience getters
  String get username => fromUsername;
  String get userId => fromUserId;
}

/// User suggestion model
class UserSuggestion {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int totalXP;
  final List<String> commonInterests;
  final int mutualFriends;

  UserSuggestion({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.totalXP,
    required this.commonInterests,
    required this.mutualFriends,
  });
}

/// User search result model
class UserSearchResult {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int totalXP;

  UserSearchResult({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.totalXP,
  });
}

