import 'package:flutter/material.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/services/unified_xp_service.dart';
import 'package:sp/core/services/unified_level_service.dart';
import 'package:sp/core/services/user_service.dart';
import 'package:sp/features/levels/models/enhanced_level_data.dart';
import 'package:sp/features/levels/level_preview_screen.dart';
import 'package:sp/features/levels/widgets/level_node.dart';
import 'package:sp/features/levels/widgets/level_path.dart';
import 'package:sp/shared/widgets/animated_background.dart';
import 'package:sp/shared/widgets/enhanced_loading_indicator.dart';
import 'dart:math' as math;
// Design System Imports
import 'package:sp/core/theme/app_colors.dart';
import 'package:sp/core/theme/app_text_styles.dart';
import 'package:sp/core/theme/app_decorations.dart';
import 'package:sp/core/theme/app_spacing.dart';
import 'package:sp/core/theme/app_animations.dart';

/// Screen for selecting specific levels (1-10) within a skill
/// Features Candy Crush-style winding path layout with animated nodes
class LevelSelectionScreen extends StatefulWidget {
  final SubjectType subject;
  final String skillId;
  final String skillName;

  const LevelSelectionScreen({
    super.key,
    required this.subject,
    required this.skillId,
    required this.skillName,
  });

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen>
    with SingleTickerProviderStateMixin {
  final UnifiedXPService _progressionService = UnifiedXPService.getInstance();
  final UnifiedLevelService _levelService = UnifiedLevelService.getInstance();
  final ScrollController _scrollController = ScrollController();

  Map<int, EnhancedLevelData> _levelDataMap = {};
  bool _isLoading = true;
  int _currentLevel = 1;
  String? _currentUserId; // Will be loaded from UserService
  late AnimationController _pathAnimationController;
  late Animation<double> _pathAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize path animation controller
    _pathAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pathAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pathAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _initializeProgressiveServices();
    _loadLevelData();
  }

  /// Initialize services and load user data
  Future<void> _initializeProgressiveServices() async {
    try {
      // Load user ID first
      _currentUserId = await UserService.instance.getCurrentUserId();

      // Ensure level 1 is always unlocked
      await _ensureLevel1Unlocked();
    } catch (e) {
      debugPrint('Error loading user ID: $e');
      _currentUserId = 'default'; // Fallback to default user

      // Still ensure level 1 is unlocked even with default user
      await _ensureLevel1Unlocked();
    }
  }

  /// Ensure level 1 is always unlocked for the current skill
  Future<void> _ensureLevel1Unlocked() async {
    final isLevel1Unlocked = await _progressionService.isLevelUnlocked(
      subject: widget.subject,
      level: 1,
      skillId: widget.skillId,
    );

    if (!isLevel1Unlocked) {
      await _progressionService.unlockLevel(
        subject: widget.subject,
        level: 1,
        skillId: widget.skillId,
      );
    }
  }

  /// Check if a level is unlocked using simplified sequential logic
  Future<bool> _isLevelUnlocked(int level) async {
    // Level 1 is always unlocked
    if (level == 1) return true;

    // Check if this level is already unlocked
    final isAlreadyUnlocked = await _progressionService.isLevelUnlocked(
      subject: widget.subject,
      level: level,
      skillId: widget.skillId,
    );

    if (isAlreadyUnlocked) return true;

    // Check if previous level is completed
    final previousLevelId = '${widget.skillId}_${level - 1}';
    final userProgress = await _progressionService.getUserProgress(_currentUserId ?? 'default');
    final previousLevelProgress = userProgress.levelProgress[previousLevelId];

    return previousLevelProgress?.isCompleted == true;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pathAnimationController.dispose();
    super.dispose();
  }

  /// Load level data with progressive unlock integration
  Future<void> _loadLevelData() async {
    try {
      setState(() => _isLoading = true);

      // Ensure user ID is loaded
      if (_currentUserId == null) {
        _currentUserId = await UserService.instance.getCurrentUserId();
      }

      // Skip learning path generation - using simplified level system

      // Load levels for this skill (using a fixed range for now)
      final Map<int, EnhancedLevelData> levelDataMap = {};

      for (int level = 1; level <= 10; level++) {
        final levelId = '${widget.skillId}_$level';

        // Check unlock status using unified system
        final isUnlocked = await _isLevelUnlocked(level);

        // Set default difficulty (can be enhanced later)
        final difficulty = 0.5 + (level - 1) * 0.1; // Progressive difficulty from 0.5 to 1.4

        // Get user progress for this level
        final userProgress = await _progressionService.getUserProgress(_currentUserId!);
        final levelProgress = userProgress.levelProgress[levelId];

        // Determine level state
        LevelNodeState state;
        if (!isUnlocked) {
          state = LevelNodeState.locked;
        } else if (levelProgress?.isCompleted == true) {
          state = LevelNodeState.completed;
        } else if (level == _currentLevel) {
          state = LevelNodeState.current;
        } else {
          state = LevelNodeState.unlocked;
        }

        // Calculate stars based on accuracy
        int stars = 0;
        double accuracy = 0.0;
        if (levelProgress != null) {
          accuracy = levelProgress.accuracy;
          stars = _calculateStars(accuracy);
        }

        levelDataMap[level] = EnhancedLevelData(
          level: level,
          state: state,
          stars: stars,
          bestScore: levelProgress?.bestScore ?? 0,
          accuracy: accuracy,
          difficultyColor: _getDifficultyColor(difficulty),
          difficulty: difficulty,
          unlockReason: isUnlocked ? 'Unlocked' : 'Complete previous level',
          skillProgress: 0.0, // Simplified for now
          isRecommended: false, // Simplified for now
          isUnlocked: isUnlocked,
          attempts: levelProgress?.gamesPlayed ?? 0,
          bestAccuracy: accuracy,
        );
      }

      setState(() {
        _levelDataMap = levelDataMap;
        _currentLevel = _determineCurrentLevel();
        _isLoading = false;
      });

      // Start path animation
      _pathAnimationController.forward();

      // Auto-scroll to current level
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentLevel();
      });
    } catch (e) {
      debugPrint('Error loading level data: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Get difficulty color based on difficulty level
  Color _getDifficultyColor(double difficulty) {
    if (difficulty <= 0.6) {
      return Colors.green; // Easy
    } else if (difficulty <= 0.8) {
      return Colors.orange; // Medium
    } else if (difficulty <= 1.0) {
      return Colors.red; // Hard
    } else {
      return Colors.purple; // Expert
    }
  }

  /// Get skill progress for a specific level
  Future<double> _getSkillProgressForLevel(String levelId) async {
    try {
      _currentUserId ??= await UserService.instance.getCurrentUserId();
      final userProgress = await _progressionService.getUserProgress(_currentUserId!);
      final levelProgress = userProgress.levelProgress[levelId];
      
      if (levelProgress == null) return 0.0;
      
      // Calculate skill progress based on completion and accuracy
      if (levelProgress.isCompleted) {
        return levelProgress.accuracy / 100.0; // Convert percentage to 0-1 range
      } else {
        return levelProgress.gamesPlayed > 0 ? 0.3 : 0.0; // Partial progress if attempted
      }
    } catch (e) {
      debugPrint('Error getting skill progress for $levelId: $e');
      return 0.0;
    }
  }

  /// Determine the current level (first incomplete or highest unlocked)
  int _determineCurrentLevel() {
    for (int level = 1; level <= 10; level++) {
      final data = _levelDataMap[level];
      if (data != null && data.isUnlocked && data.attempts == 0) {
        return level; // First unlocked but not attempted
      }
    }

    // If all levels are attempted, return the highest unlocked level
    for (int level = 10; level >= 1; level--) {
      final data = _levelDataMap[level];
      if (data != null && data.isUnlocked) {
        return level;
      }
    }

    return 1; // Default to level 1
  }

  /// Auto-scroll to center the current level in viewport
  void _scrollToCurrentLevel() {
    if (!_scrollController.hasClients) return;

    final screenHeight = MediaQuery.of(context).size.height;
    final nodePositions = _calculateNodePositions(MediaQuery.of(context).size.width);

    if (_currentLevel > 0 && _currentLevel <= nodePositions.length) {
      final targetY = nodePositions[_currentLevel - 1].dy;
      final scrollOffset = (targetY - screenHeight / 2 + 100).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );

      _scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  int _calculateStars(double accuracy) {
    if (accuracy >= 0.95) return 3;
    if (accuracy >= 0.80) return 2;
    if (accuracy >= 0.70) return 1;
    return 0;
  }



  /// Calculate positions for nodes in a winding S-curve path
  List<Offset> _calculateNodePositions(double screenWidth) {
    final positions = <Offset>[];
    const verticalSpacing = 140.0;
    const startY = 100.0;

    // Define horizontal positions as percentages
    final leftX = screenWidth * 0.25;
    final centerX = screenWidth * 0.5;
    final rightX = screenWidth * 0.75;

    // Create winding path pattern
    final pattern = [
      leftX,    // Level 1 - Start left
      rightX,   // Level 2 - Move right
      leftX,    // Level 3 - Move left
      rightX,   // Level 4 - Move right
      centerX,  // Level 5 - Center
      leftX,    // Level 6 - Move left
      rightX,   // Level 7 - Move right
      leftX,    // Level 8 - Move left
      rightX,   // Level 9 - Move right
      centerX,  // Level 10 - End center
    ];

    for (int i = 0; i < 10; i++) {
      positions.add(Offset(
        pattern[i],
        startY + (i * verticalSpacing),
      ));
    }

    return positions;
  }

  /// Get node state based on level data

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.skillName,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          backgroundColor: AppColors.getSubjectColor(widget.subject.toString()),
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
        ),
        body: _isLoading
            ? Container(
                decoration: AppDecorations.gameBackground,
                child: const Center(
                  child: EnhancedLoadingIndicator(title: 'Loading Levels...'),
                ),
              )
            : _buildWindingPathLayout(screenSize),
      ),
    );
  }

  /// Build the Candy Crush-style winding path layout
  Widget _buildWindingPathLayout(Size screenSize) {
    final nodePositions = _calculateNodePositions(screenSize.width);
    final highestUnlocked = _levelDataMap.values
        .where((data) => data.isUnlocked)
        .map((data) => data.level)
        .fold(0, math.max);

    return Container(
      decoration: AppDecorations.gameBackground,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header section
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.allLG,
              child: AppAnimations.fadeInWidget(
                duration: AppAnimations.slow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select a Level',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Follow the path and complete each level',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Winding path with nodes
          SliverToBoxAdapter(
            child: SizedBox(
              height: 1400, // Total height for 10 nodes with spacing
              child: Stack(
                children: [
                  // Draw connecting path
                  AnimatedBuilder(
                    animation: _pathAnimation,
                    builder: (context, child) {
                      return LevelPath(
                        nodePositions: nodePositions,
                        highestUnlockedLevel: highestUnlocked,
                        unlockedColor: AppColors.primaryBlue.withOpacity(0.6),
                        lockedColor: AppColors.textSecondary.withOpacity(0.3),
                        strokeWidth: 5.0,
                        animationProgress: _pathAnimation.value,
                      );
                    },
                  ),

                  // Draw level nodes
                  ...List.generate(10, (index) {
                    final level = index + 1;
                    final levelData = _levelDataMap[level];
                    if (levelData == null) return const SizedBox.shrink();

                    final position = nodePositions[index];

                    return Positioned(
                      left: position.dx - 45, // Center the 90px node
                      top: position.dy - 45,
                      child: TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 400 + (index * 80)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.scale(
                              scale: 0.5 + (0.5 * value),
                              child: child,
                            ),
                          );
                        },
                        child: LevelNode(
                          data: levelData.toLevelNodeData(),
                          position: position,
                          onTap: levelData.isUnlocked
                              ? () => _onLevelTap(level)
                              : null, // Disable tap for locked levels
                          isRecommended: levelData.isRecommended,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }



  void _onLevelTap(int level) async {
    // Navigate to Level Preview Screen and listen for result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelPreviewScreen(
          subject: widget.subject,
          level: level,
          skillId: widget.skillId,
          skillName: widget.skillName,
        ),
      ),
    );

    // Reload level data if level was completed
    if (result != null && result is bool && result) {
      await _loadLevelData();

      // Play unlock animation if new level was unlocked
      final newHighestUnlocked = await _levelService.getHighestUnlockedLevel(
        subject: widget.subject,
        skillId: widget.skillId,
      );

      if (newHighestUnlocked > level) {
        _pathAnimationController.forward(from: 0.0);
      }
    }
  }
}

/// Data class for level information
class LevelData {
  final int level;
  final bool isUnlocked;
  final int bestScore;
  final double bestAccuracy;
  final int attempts;
  final int stars;

  LevelData({
    required this.level,
    required this.isUnlocked,
    required this.bestScore,
    required this.bestAccuracy,
    required this.attempts,
    required this.stars,
  });
}

