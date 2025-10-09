import 'package:flutter/material.dart';
import 'package:sp/core/services/social/friend_service.dart';

/// Friends Screen - Manage friends and friend requests
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _friendService = FriendService();
  List<Friend>? _friends;
  List<FriendRequest>? _requests;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    
    try {
      final friends = await _friendService.getFriends('current_user');
      final requests = await _friendService.getPendingRequests('current_user');
      
      setState(() {
        _friends = friends;
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddFriendDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_requests != null && _requests!.isNotEmpty) ...[
                  Text(
                    'Friend Requests',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ..._requests!.map((request) => _buildRequestCard(request)),
                  const SizedBox(height: 24),
                ],
                Text(
                  'My Friends (${_friends?.length ?? 0})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (_friends == null || _friends!.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No friends yet', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _showAddFriendDialog,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Friends'),
                        ),
                      ],
                    ),
                  )
                else
                  ..._friends!.map((friend) => _buildFriendCard(friend)),
              ],
            ),
    );
  }

  Widget _buildRequestCard(FriendRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(request.username[0].toUpperCase()),
        ),
        title: Text(request.username),
        subtitle: Text('Wants to be friends'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _acceptRequest(request.userId),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _rejectRequest(request.userId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCard(Friend friend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: Text(friend.username[0].toUpperCase()),
        ),
        title: Text(friend.username),
        subtitle: Text('Level ${friend.level} • ${friend.xp} XP'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'challenge', child: Text('Challenge')),
            const PopupMenuItem(value: 'message', child: Text('Message')),
            const PopupMenuItem(value: 'remove', child: Text('Remove Friend')),
          ],
          onSelected: (value) {
            if (value == 'remove') {
              _removeFriend(friend.userId);
            }
          },
        ),
      ),
    );
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Friend'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Username or Friend Code',
            hintText: 'Enter username',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Friend request sent!')),
              );
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(String requestId) async {
    await _friendService.acceptFriendRequest(requestId);
    _loadFriends();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request accepted!')),
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    await _friendService.rejectFriendRequest(requestId);
    _loadFriends();
  }

  Future<void> _removeFriend(String friendId) async {
    await _friendService.removeFriend(userId: 'current_user', friendId: friendId);
    _loadFriends();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend removed')),
      );
    }
  }
}

