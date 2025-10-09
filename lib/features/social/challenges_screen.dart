import 'package:flutter/material.dart';
import 'package:sp/core/services/social/challenge_service.dart';

/// Challenges Screen - Daily and friend challenges
class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({Key? key}) : super(key: key);

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _challengeService = ChallengeService();
  
  Challenge? _dailyChallenge;
  List<Challenge>? _activeChallenges;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    
    try {
      final daily = await _challengeService.getDailyChallenge();
      final active = await _challengeService.getActiveChallenges('current_user');
      
      setState(() {
        _dailyChallenge = daily;
        _activeChallenges = active;
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
        title: const Text('Challenges'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily', icon: Icon(Icons.today)),
            Tab(text: 'Active', icon: Icon(Icons.emoji_events)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDailyChallengeView(),
                _buildActiveChallengesView(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateChallengeDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Challenge'),
      ),
    );
  }

  Widget _buildDailyChallengeView() {
    if (_dailyChallenge == null) {
      return const Center(child: Text('No daily challenge available'));
    }

    final challenge = _dailyChallenge!;
    final progress = challenge.currentProgress / challenge.targetValue;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.today, color: Colors.orange, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            challenge.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                const SizedBox(height: 8),
                Text(
                  '${challenge.currentProgress}/${challenge.targetValue} ${challenge.type.name}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Reward: ${challenge.rewardXp} XP',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (challenge.status == ChallengeStatus.active)
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to practice or relevant screen
                    },
                    child: const Text('Start Challenge'),
                  )
                else if (challenge.status == ChallengeStatus.completed)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Completed!', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveChallengesView() {
    if (_activeChallenges == null || _activeChallenges!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No active challenges', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showCreateChallengeDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Challenge'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeChallenges!.length,
      itemBuilder: (context, index) {
        final challenge = _activeChallenges![index];
        return _buildChallengeCard(challenge);
      },
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    final progress = challenge.currentProgress / challenge.targetValue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        challenge.description,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${challenge.rewardXp} XP',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 4),
            Text(
              '${challenge.currentProgress}/${challenge.targetValue}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateChallengeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Challenge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Challenge Title',
                hintText: 'e.g., Math Marathon',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Target (number of questions)',
                hintText: 'e.g., 50',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
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
                const SnackBar(content: Text('Challenge created!')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

