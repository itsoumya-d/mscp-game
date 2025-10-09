import 'package:flutter/material.dart';
import 'package:sp/core/services/social/leaderboard_service.dart';

/// Leaderboard Screen - Display rankings and competitions
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _leaderboardService = LeaderboardService();
  
  List<LeaderboardEntry>? _globalLeaderboard;
  List<LeaderboardEntry>? _friendsLeaderboard;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLeaderboards();
  }

  Future<void> _loadLeaderboards() async {
    setState(() => _isLoading = true);
    
    try {
      final global = await _leaderboardService.getGlobalLeaderboard(limit: 50);
      final friends = await _leaderboardService.getFriendsLeaderboard('current_user');
      
      setState(() {
        _globalLeaderboard = global;
        _friendsLeaderboard = friends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leaderboards: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboards'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global', icon: Icon(Icons.public)),
            Tab(text: 'Friends', icon: Icon(Icons.people)),
            Tab(text: 'Leagues', icon: Icon(Icons.emoji_events)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboardList(_globalLeaderboard ?? []),
                _buildLeaderboardList(_friendsLeaderboard ?? []),
                _buildLeaguesView(),
              ],
            ),
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No entries yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildLeaderboardCard(entry, index + 1);
      },
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, int rank) {
    Color? rankColor;
    IconData? rankIcon;

    if (rank == 1) {
      rankColor = Colors.amber;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey.shade400;
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = Colors.brown.shade300;
      rankIcon = Icons.emoji_events;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: rankColor?.withOpacity(0.2) ?? Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: rankIcon != null
                ? Icon(rankIcon, color: rankColor, size: 20)
                : Text(
                    '#$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: rankColor ?? Colors.grey.shade700,
                    ),
                  ),
          ),
        ),
        title: Text(
          entry.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Level ${entry.level}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.xp} XP',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '${entry.streak} day streak',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaguesView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLeagueCard(
          'Diamond League',
          'Top 1% of players',
          Colors.blue.shade400,
          Icons.diamond,
        ),
        const SizedBox(height: 12),
        _buildLeagueCard(
          'Platinum League',
          'Top 5% of players',
          Colors.grey.shade300,
          Icons.workspace_premium,
        ),
        const SizedBox(height: 12),
        _buildLeagueCard(
          'Gold League',
          'Top 15% of players',
          Colors.amber,
          Icons.emoji_events,
        ),
        const SizedBox(height: 12),
        _buildLeagueCard(
          'Silver League',
          'Top 35% of players',
          Colors.grey.shade400,
          Icons.military_tech,
        ),
        const SizedBox(height: 12),
        _buildLeagueCard(
          'Bronze League',
          'All players',
          Colors.brown.shade300,
          Icons.shield,
        ),
      ],
    );
  }

  Widget _buildLeagueCard(
    String name,
    String description,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

