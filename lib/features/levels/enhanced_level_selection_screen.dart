import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Enhanced Level Selection UI - Task B2
/// Visual level map with difficulty indicators, completion status, and rewards
class EnhancedLevelSelectionScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const EnhancedLevelSelectionScreen({
    Key? key,
    required this.subjectId,
    required this.subjectName,
  }) : super(key: key);

  @override
  State<EnhancedLevelSelectionScreen> createState() =>
      _EnhancedLevelSelectionScreenState();
}

class _EnhancedLevelSelectionScreenState
    extends State<EnhancedLevelSelectionScreen> {
  String _filterDifficulty = 'all';
  String _filterStatus = 'all';
  final ScrollController _scrollController = ScrollController();

  // Mock data - replace with actual data from your backend
  final List<LevelData> _levels = List.generate(30, (index) {
    final level = index + 1;
    return LevelData(
      id: 'level_$level',
      levelNumber: level,
      name: 'Level $level',
      description: _getLevelDescription(level),
      difficulty: (level / 10).ceil(),
      isLocked: level > 15,
      isCompleted: level <= 10,
      stars: level <= 10 ? (level % 3) + 1 : 0,
      rewardXP: level * 10,
      questionCount: 10,
      estimatedMinutes: 15,
    );
  });

  static String _getLevelDescription(int level) {
    final descriptions = [
      'Introduction to basics',
      'Building foundations',
      'Intermediate concepts',
      'Advanced techniques',
      'Expert challenges',
    ];
    return descriptions[(level ~/ 6) % descriptions.length];
  }

  List<LevelData> get _filteredLevels {
    return _levels.where((level) {
      // Filter by difficulty
      if (_filterDifficulty != 'all') {
        final targetDifficulty = int.parse(_filterDifficulty);
        if (level.difficulty != targetDifficulty) return false;
      }

      // Filter by status
      if (_filterStatus == 'completed' && !level.isCompleted) return false;
      if (_filterStatus == 'unlocked' && (level.isLocked || level.isCompleted))
        return false;
      if (_filterStatus == 'locked' && !level.isLocked) return false;

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress summary
          _buildProgressSummary(),

          // Filter chips
          _buildFilterChips(),

          // Level map
          Expanded(
            child: _buildLevelMap(),
          ),
        ],
      ),
      floatingActionButton: _buildQuickNavFAB(),
    );
  }

  Widget _buildProgressSummary() {
    final completed = _levels.where((l) => l.isCompleted).length;
    final total = _levels.length;
    final progress = completed / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '$completed/$total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'All',
              isSelected: _filterStatus == 'all',
              onTap: () => setState(() => _filterStatus = 'all'),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Completed',
              isSelected: _filterStatus == 'completed',
              onTap: () => setState(() => _filterStatus = 'completed'),
              icon: Icons.check_circle,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Unlocked',
              isSelected: _filterStatus == 'unlocked',
              onTap: () => setState(() => _filterStatus = 'unlocked'),
              icon: Icons.lock_open,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Locked',
              isSelected: _filterStatus == 'locked',
              onTap: () => setState(() => _filterStatus = 'locked'),
              icon: Icons.lock,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelMap() {
    final filteredLevels = _filteredLevels;

    if (filteredLevels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No levels match your filters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _filterDifficulty = 'all';
                  _filterStatus = 'all';
                });
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filteredLevels.length,
      itemBuilder: (context, index) {
        return _buildLevelCard(filteredLevels[index], index);
      },
    );
  }

  Widget _buildLevelCard(LevelData level, int index) {
    final isEven = index % 2 == 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 16,
        left: isEven ? 0 : 40,
        right: isEven ? 40 : 0,
      ),
      child: InkWell(
        onTap: level.isLocked ? null : () => _onLevelTap(level),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: level.isLocked
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getDifficultyColor(level.difficulty),
                      _getDifficultyColor(level.difficulty).withOpacity(0.7),
                    ],
                  ),
            color: level.isLocked ? Colors.grey[300] : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: level.isLocked
                ? null
                : [
                    BoxShadow(
                      color: _getDifficultyColor(level.difficulty)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Level number badge
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${level.levelNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                level.description,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (level.isLocked)
                          const Icon(Icons.lock, color: Colors.grey)
                        else if (level.isCompleted)
                          const Icon(Icons.check_circle, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildLevelStat(
                          Icons.quiz,
                          '${level.questionCount}',
                        ),
                        const SizedBox(width: 16),
                        _buildLevelStat(
                          Icons.timer,
                          '${level.estimatedMinutes}m',
                        ),
                        const SizedBox(width: 16),
                        _buildLevelStat(
                          Icons.stars,
                          '${level.rewardXP} XP',
                        ),
                      ],
                    ),
                    if (level.isCompleted) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(3, (i) {
                          return Icon(
                            i < level.stars
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
              // Difficulty indicator
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getDifficultyLabel(level.difficulty),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickNavFAB() {
    return FloatingActionButton.extended(
      onPressed: _showQuickNav,
      icon: const Icon(Icons.navigation),
      label: const Text('Jump to Level'),
    );
  }

  void _onLevelTap(LevelData level) {
    Navigator.pop(context, level);
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: LevelSearchDelegate(_levels),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Levels',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Text(
                'Difficulty',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _filterDifficulty == 'all',
                    onSelected: (selected) {
                      setModalState(() => _filterDifficulty = 'all');
                      setState(() => _filterDifficulty = 'all');
                    },
                  ),
                  ...List.generate(10, (i) {
                    final diff = i + 1;
                    return ChoiceChip(
                      label: Text('$diff'),
                      selected: _filterDifficulty == '$diff',
                      onSelected: (selected) {
                        setModalState(() => _filterDifficulty = '$diff');
                        setState(() => _filterDifficulty = '$diff');
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQuickNav() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jump to Level'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _levels.length,
            itemBuilder: (context, index) {
              final level = _levels[index];
              return InkWell(
                onTap: level.isLocked
                    ? null
                    : () {
                        Navigator.pop(context);
                        _scrollToLevel(index);
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: level.isLocked
                        ? Colors.grey[300]
                        : level.isCompleted
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${level.levelNumber}',
                      style: TextStyle(
                        color: level.isLocked ? Colors.grey : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _scrollToLevel(int index) {
    final position = index * 120.0; // Approximate card height
    _scrollController.animateTo(
      position,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Color _getDifficultyColor(int difficulty) {
    if (difficulty <= 3) return Colors.green;
    if (difficulty <= 6) return Colors.orange;
    if (difficulty <= 8) return Colors.red;
    return Colors.purple;
  }

  String _getDifficultyLabel(int difficulty) {
    if (difficulty <= 3) return 'Easy';
    if (difficulty <= 6) return 'Medium';
    if (difficulty <= 8) return 'Hard';
    return 'Expert';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

/// Level data model
class LevelData {
  final String id;
  final int levelNumber;
  final String name;
  final String description;
  final int difficulty;
  final bool isLocked;
  final bool isCompleted;
  final int stars;
  final int rewardXP;
  final int questionCount;
  final int estimatedMinutes;

  LevelData({
    required this.id,
    required this.levelNumber,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.isLocked,
    required this.isCompleted,
    required this.stars,
    required this.rewardXP,
    required this.questionCount,
    required this.estimatedMinutes,
  });
}

/// Level search delegate
class LevelSearchDelegate extends SearchDelegate<LevelData?> {
  final List<LevelData> levels;

  LevelSearchDelegate(this.levels);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = levels.where((level) {
      return level.name.toLowerCase().contains(query.toLowerCase()) ||
          level.description.toLowerCase().contains(query.toLowerCase()) ||
          level.levelNumber.toString().contains(query);
    }).toList();

    if (results.isEmpty) {
      return const Center(
        child: Text('No levels found'),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final level = results[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text('${level.levelNumber}'),
          ),
          title: Text(level.name),
          subtitle: Text(level.description),
          trailing: level.isLocked
              ? const Icon(Icons.lock)
              : level.isCompleted
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
          onTap: level.isLocked ? null : () => close(context, level),
        );
      },
    );
  }
}

