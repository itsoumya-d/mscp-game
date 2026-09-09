import 'package:flutter/material.dart';
import '../../core/models/subject.dart';
import '../../core/services/level_generation_service.dart';
import '../../core/services/progressive_unlock_service.dart';
import '../../core/services/level_flashcard_integration_service.dart';
import '../flashcards/flashcard_study_screen.dart';
import '../lessons/lesson_screen.dart';

class SubjectDetailScreen extends StatefulWidget {
  final SubjectType subjectType;

  const SubjectDetailScreen({
    Key? key,
    required this.subjectType,
  }) : super(key: key);

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen>
    with SingleTickerProviderStateMixin {
  final LevelGenerationService _levelService = LevelGenerationService();
  final ProgressiveUnlockService _unlockService = ProgressiveUnlockService();
  final LevelFlashcardIntegrationService _integrationService = 
      LevelFlashcardIntegrationService();

  late TabController _tabController;
  Subject? _subject;
  bool _isLoading = true;
  Map<String, dynamic> _progressData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSubjectData();
  }

  Future<void> _loadSubjectData() async {
    try {
      setState(() => _isLoading = true);
      
      // Generate subject with all content
      _subject = _levelService.generateSubject(widget.subjectType);
      
      // Load progress data
      final subjectProgress = _unlockService.getSubjectProgress(widget.subjectType.name);
      final totalSkills = _subject?.totalSkills ?? 0;
      _progressData = {
        'completedSkills': (subjectProgress * totalSkills).round(),
        'totalXp': 0,
        'streakDays': 0,
        'studyTimeHours': 0,
      };
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to load subject data: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading ${widget.subjectType.name}...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_subject == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.subjectType.name),
        ),
        body: const Center(
          child: Text('Subject not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverFillRemaining(
            child: Column(
              children: [
                _buildProgressOverview(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLevelsTab(),
                      _buildFlashcardsTab(),
                      _buildProgressTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: _getSubjectColor(),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _subject!.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getSubjectColor(),
                _getSubjectColor().withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: 60,
                child: Icon(
                  _getSubjectIcon(),
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressOverview() {
    final totalSkills = _subject!.totalSkills;
    final completedSkills = _progressData['completedSkills'] ?? 0;
    final progressPercentage = totalSkills > 0 ? completedSkills / totalSkills : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${(progressPercentage * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getSubjectColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progressPercentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_getSubjectColor()),
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('Skills', '$completedSkills/$totalSkills'),
              const SizedBox(width: 24),
              _buildStatItem('XP', '${_progressData['totalXp'] ?? 0}'),
              const SizedBox(width: 24),
              _buildStatItem('Streak', '${_progressData['streakDays'] ?? 0} days'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _getSubjectColor(),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Levels'),
          Tab(text: 'Flashcards'),
          Tab(text: 'Progress'),
        ],
      ),
    );
  }

  Widget _buildLevelsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subject!.units.length,
      itemBuilder: (context, index) {
        final unit = _subject!.units[index];
        return _buildUnitCard(unit, index);
      },
    );
  }

  Widget _buildUnitCard(Unit unit, int index) {
    final isUnlocked = unit.isUnlocked || index == 0;
    final completedSkills = unit.skills.where((s) => s.crowns > 0).length;
    final totalSkills = unit.skills.length;
    final progress = totalSkills > 0 ? completedSkills / totalSkills : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isUnlocked ? () => _navigateToUnit(unit) : null,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isUnlocked 
                            ? _getSubjectColor().withOpacity(0.1)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isUnlocked ? Icons.school : Icons.lock,
                        color: isUnlocked ? _getSubjectColor() : Colors.grey,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? Colors.black87 : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            unit.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: isUnlocked ? Colors.grey[600] : Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isUnlocked) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completedSkills/$totalSkills skills',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getSubjectColor(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(_getSubjectColor()),
                    minHeight: 6,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlashcardsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Study with Flashcards',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reinforce your learning with spaced repetition',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildFlashcardOption(
                  'Quick Review',
                  'Review recent lessons',
                  Icons.flash_on,
                  Colors.orange,
                  () => _startFlashcardSession('quick'),
                ),
                _buildFlashcardOption(
                  'Weak Areas',
                  'Focus on difficult topics',
                  Icons.trending_up,
                  Colors.red,
                  () => _startFlashcardSession('weak'),
                ),
                _buildFlashcardOption(
                  'Mastery',
                  'Advanced challenges',
                  Icons.star,
                  Colors.purple,
                  () => _startFlashcardSession('mastery'),
                ),
                _buildFlashcardOption(
                  'Adaptive',
                  'Personalized study',
                  Icons.psychology,
                  Colors.blue,
                  () => _startFlashcardSession('adaptive'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardOption(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Progress',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _buildProgressCard(
                  'Learning Streak',
                  '${_progressData['streakDays'] ?? 0} days',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
                _buildProgressCard(
                  'Total XP Earned',
                  '${_progressData['totalXp'] ?? 0} XP',
                  Icons.stars,
                  Colors.purple,
                ),
                _buildProgressCard(
                  'Skills Mastered',
                  '${_progressData['completedSkills'] ?? 0}/${_subject!.totalSkills}',
                  Icons.emoji_events,
                  Colors.amber,
                ),
                _buildProgressCard(
                  'Study Time',
                  '${_progressData['studyTimeHours'] ?? 0}h',
                  Icons.schedule,
                  Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSubjectColor() {
    switch (widget.subjectType) {
      case SubjectType.math:
        return const Color(0xFF4ECDC4);
      case SubjectType.physics:
        return const Color(0xFF45B7D1);
      case SubjectType.chemistry:
        return const Color(0xFF96CEB4);
      case SubjectType.biology:
        return const Color(0xFFFECEA8);
      case SubjectType.computerScience:
        return const Color(0xFFD63384);
      default:
        return const Color(0xFF6C757D);
    }
  }

  IconData _getSubjectIcon() {
    switch (widget.subjectType) {
      case SubjectType.math:
        return Icons.calculate;
      case SubjectType.physics:
        return Icons.science;
      case SubjectType.chemistry:
        return Icons.biotech;
      case SubjectType.biology:
        return Icons.eco;
      case SubjectType.computerScience:
        return Icons.computer;
      default:
        return Icons.school;
    }
  }

  void _navigateToUnit(Unit unit) {
    // Navigate to unit detail screen (would be implemented)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${unit.name}...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _startFlashcardSession(String type) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generate flashcards based on type
      List<dynamic> flashcards;
      switch (type) {
        case 'quick':
          flashcards = await _integrationService.generateFlashcardsFromLessons(
            subjectId: widget.subjectType.name,
            maxCards: 20,
          );
          break;
        case 'weak':
          flashcards = await _integrationService.generateWeakAreaReviewCards(
            subjectId: widget.subjectType.name,
            count: 25,
          );
          break;
        case 'mastery':
          flashcards = await _integrationService.generateMasteryCards(
            subjectId: widget.subjectType.name,
            count: 15,
          );
          break;
        case 'adaptive':
          flashcards = await _integrationService.generateAdaptiveFlashcards(
            subjectId: widget.subjectType.name,
            count: 20,
          );
          break;
        default:
          flashcards = await _integrationService.generateFlashcardsFromLessons(
            subjectId: widget.subjectType.name,
            maxCards: 20,
          );
      }

      // Close loading dialog
      Navigator.of(context).pop();

      if (flashcards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No flashcards available. Complete some lessons first!'),
          ),
        );
        return;
      }

      // Navigate to flashcard study screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FlashcardStudyScreen(
            subjectId: widget.subjectType.name,
            targetCount: flashcards.length,
          ),
        ),
      );

    } catch (e) {
      // Close loading dialog if still open
      Navigator.of(context).pop();
      _showErrorDialog('Failed to start flashcard session: $e');
    }
  }
}