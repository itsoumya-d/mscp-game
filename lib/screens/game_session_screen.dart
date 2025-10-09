import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/controllers/game_controller.dart';
import '../core/providers/game_provider.dart';
import '../features/lessons/widgets/question_widget.dart';
import '../shared/widgets/game_feedback_widget.dart';
import '../features/personalized_paths/widgets/learning_path_indicator.dart';
import '../widgets/game_progress_bar.dart';
import '../shared/widgets/enhanced_loading_indicator.dart';
import '../features/levels/widgets/difficulty_indicator.dart';
import '../features/adaptive_difficulty/widgets/adaptive_difficulty_indicator.dart';
import '../core/services/adaptive_difficulty_calculator.dart';
import '../core/services/progressive_unlock_integration_service.dart';
import '../core/services/personalized_path_generator.dart';
import '../core/services/user_service.dart';
import '../core/models/learning_path.dart';
import '../core/models/difficulty_level.dart';
import '../core/models/subject.dart';
import '../features/help/how_to_play_screen.dart';
import 'game_results_screen.dart';
// Design System Imports
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_animations.dart';

class GameSessionScreen extends ConsumerStatefulWidget {
  final SubjectType subject;
  final int level;
  final String? skillId;

  const GameSessionScreen({
    Key? key,
    required this.subject,
    required this.level,
    this.skillId,
  }) : super(key: key);

  @override
  ConsumerState<GameSessionScreen> createState() => _GameSessionScreenState();
}

class _GameSessionScreenState extends ConsumerState<GameSessionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Progressive unlock system services
  late ProgressiveUnlockIntegrationService _progressiveService;
  late AdaptiveDifficultyCalculator _difficultyCalculator;
  late PersonalizedPathGenerator _pathGenerator;
  
  // Current session state
  String? _currentUserId;
  LearningPath? _currentLearningPath;
  DifficultyLevel? _adaptiveDifficulty;
  bool _isAdaptiveDifficultyActive = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Initialize progressive unlock services
    _initializeProgressiveServices();

    // Start the game
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGame();
    });
  }

  Future<void> _initializeProgressiveServices() async {
    try {
      _progressiveService = ProgressiveUnlockIntegrationService.instance;
      _difficultyCalculator = AdaptiveDifficultyCalculator.instance;
      _pathGenerator = PersonalizedPathGenerator.instance;
      
      // Initialize services
      await _progressiveService.initialize();
      await _difficultyCalculator.initialize();
      await _pathGenerator.initialize();
      
      // Get current user ID from UserService
      _currentUserId = await UserService.instance.getCurrentUserId();
      
      // Load current learning path
      _currentLearningPath = await _pathGenerator.generatePersonalizedPath(
        _currentUserId!,
        'general', // Default subject
      );
      
      // Get adaptive difficulty recommendation
      final recommendation = await _difficultyCalculator.calculateOptimalDifficulty(
        _currentUserId!,
        widget.level,
        'general', // Default subject
      );
      _adaptiveDifficulty = DifficultyLevel.values[recommendation.recommendedDifficulty.round().clamp(0, DifficultyLevel.values.length - 1)];
      
      _isAdaptiveDifficultyActive = _adaptiveDifficulty != null;
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing progressive services: $e');
      // Continue with default behavior if services fail
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    final gameController = ref.read(gameControllerProvider);
    await gameController.startNewGame(
      subject: widget.subject,
      level: widget.level,
      skillId: widget.skillId,
    );
    
    if (mounted) {
      _fadeController.forward();
      _slideController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.getSubjectColor(_getSubjectName(widget.subject)),
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_getSubjectName(widget.subject)} - Level ${widget.level}',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  if (_isAdaptiveDifficultyActive && _adaptiveDifficulty != null)
                    Text(
                      'Adaptive: ${_getDifficultyName(_adaptiveDifficulty!)}',
                      style: AppTextStyles.captionText.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                ],
              ),
            ),
            if (_isAdaptiveDifficultyActive && _adaptiveDifficulty != null)
              Container(
                margin: AppSpacing.horizontalSM,
                child: DifficultyBadge(
                  difficulty: _getDifficultyLevel(_adaptiveDifficulty!),
                  size: 16,
                ),
              )
            else
              DifficultyBadge(
                difficulty: widget.level,
                size: 16,
              ),
          ],
        ),
        actions: [
          // Adaptive Difficulty Indicator
          if (_isAdaptiveDifficultyActive && _adaptiveDifficulty != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: AdaptiveDifficultyIndicator(
                currentDifficulty: _adaptiveDifficulty!,
                isAdaptive: true,
                onTap: () => _showAdaptiveDifficultyInfo(context),
              ),
            ),
          // Help button
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HowToPlayScreen(),
                ),
              );
            },
            tooltip: 'How to Play',
          ),
          // Pause button
          Consumer(
            builder: (context, ref, child) {
              final controller = ref.watch(gameControllerProvider);
              if (controller.isGameActive) {
                return IconButton(
                  icon: const Icon(Icons.pause),
                  onPressed: () => _showPauseDialog(context, controller),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final controller = ref.watch(gameControllerProvider);
          if (controller.isLoading && controller.currentSession == null) {
            return _buildLoadingScreen();
          }

          if (controller.error != null) {
            return _buildErrorScreen(controller.error!, controller);
          }

          if (controller.isGameCompleted) {
            // Navigate to results screen instead of embedding it
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => GameResultsScreen(
                      session: controller.currentSession!,
                      onPlayAgain: () {
                        Navigator.of(context).pop(); // Go back to game session
                        _startGame();
                      },
                      onBackToMenu: () {
                        Navigator.of(context).pop(); // Go back to level selection
                        Navigator.of(context).pop(true); // Exit game session with completion status
                      },
                    ),
                  ),
                );
              }
            });
            // Show loading while navigating
            return _buildLoadingScreen();
          }

          if (controller.currentSession == null) {
            return _buildEmptyScreen();
          }

          return _buildGameContent(controller);
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: AppDecorations.gameBackground,
      child: EnhancedLoadingIndicator(
        title: 'Preparing Your Lesson',
        subtitle: 'Creating 7 unique questions for Level ${widget.level}',
        color: AppColors.getSubjectColor(_getSubjectName(widget.subject)),
        loadingMessages: const [
          'Crafting engaging questions...',
          'Selecting the perfect difficulty...',
          'Adding helpful hints and explanations...',
          'Almost ready to start learning!',
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String error, GameController controller) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06), // 6% of screen width
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: screenWidth * 0.16, // Responsive icon size
              color: Colors.red[400],
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.015),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
            ElevatedButton.icon(
              onPressed: () => _startGame(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getSubjectColor(widget.subject),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenHeight * 0.015,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return const Center(
      child: Text(
        'No game session available',
        style: TextStyle(
          fontSize: 18,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildGameContent(GameController controller) {
    return Container(
      decoration: AppDecorations.gameBackground,
      child: SafeArea(
        child: AppAnimations.fadeInWidget(
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: AppSpacing.responsiveHorizontalPadding(context),
                child: Container(
                  margin: AppSpacing.verticalSM,
                  child: GameProgressBar(
                    progress: controller.progress,
                    currentQuestion: controller.currentQuestionIndex + 1,
                    totalQuestions: 7,
                    color: AppColors.getSubjectColor(_getSubjectName(widget.subject)),
                  ),
                ),
              ),

              // Score display
              Container(
                margin: AppSpacing.responsiveHorizontalPadding(context),
                padding: AppSpacing.allMD,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Score: ${controller.score}',
                        style: AppTextStyles.scoreText.copyWith(
                          color: AppColors.getSubjectColor(_getSubjectName(widget.subject)),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isAdaptiveDifficultyActive && _adaptiveDifficulty != null)
                      Flexible(
                        child: AdaptiveDifficultyIndicator(
                          currentDifficulty: _adaptiveDifficulty!,
                          isAdaptive: true,
                          onTap: () => _showAdaptiveDifficultyInfo(context),
                        ),
                      ),
                    Flexible(
                      child: Text(
                        'Questions: ${controller.currentQuestionIndex + 1}/7',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.verticalSpaceLG,

              // Learning Path Indicator
              if (_currentLearningPath != null)
                LearningPathIndicator(
                  currentPath: _currentLearningPath,
                  progress: _calculateLearningPathProgress(),
                  nextRecommendation: _getNextRecommendation(),
                  onTap: () => _showLearningPathInfo(context),
                ),

              // Question content
              Expanded(
                child: AppAnimations.slideWidget(
                  begin: const Offset(1, 0),
                  child: Padding(
                    padding: AppSpacing.responsiveHorizontalPadding(context),
                    child: Column(
                      children: [
                        // Question widget
                        Expanded(
                          child: Container(
                            decoration: AppDecorations.questionCard,
                            margin: AppSpacing.verticalMD,
                            child: QuestionWidget(
                              question: controller.currentQuestion!,
                              selectedAnswer: controller.currentAnswer,
                              onAnswerSubmitted: (answer) async {
                                // Store the selected answer in the controller
                                controller.setCurrentAnswer(answer);

                                await controller.submitAnswer();

                                // Update adaptive difficulty based on performance
                                if (_isAdaptiveDifficultyActive && _currentUserId != null) {
                                  await _updateAdaptiveDifficulty(
                                    controller.lastAnswerCorrect ?? false,
                                    controller.currentQuestionIndex,
                                  );
                                }

                                // CRITICAL FIX: Add delay for feedback, then advance to next question
                                await Future.delayed(const Duration(milliseconds: 1500)); // Show feedback for 1.5 seconds

                                // Advance to next question - use actual question count instead of hardcoded limit
                                final totalQuestions = controller.currentSession?.questions.length ?? 0;
                                if (controller.currentQuestionIndex < totalQuestions - 1 && 
                                    !controller.isGameCompleted) {
                                  await controller.nextQuestion();

                                  // Animate to next question
                                  _slideController.reset();
                                  _slideController.forward();
                                }
                              },
                            ),
                          ),
                        ),

                        // Feedback widget
                        if (controller.currentFeedback != null)
                          Container(
                            margin: AppSpacing.verticalMD,
                            padding: AppSpacing.allLG,
                            decoration: AppDecorations.standardCard,
                            child: GameFeedbackWidget(
                              feedback: controller.currentFeedback!,
                              isCorrect: controller.lastAnswerCorrect ?? false,
                              correctAnswer: controller.currentQuestion?.correctAnswer,
                              explanation: controller.currentQuestion?.explanation,
                            ),
                          ),
                      ],
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

  Future<void> _updateAdaptiveDifficulty(bool isCorrect, int questionIndex) async {
    try {
      // Record performance data for adaptive difficulty calculation
      final performanceData = LevelPerformanceData(
        levelId: widget.level,
        subject: widget.subject.toString(),
        accuracy: isCorrect ? 1.0 : 0.0,
        timeSpentSeconds: 30, // You may want to track actual time spent
        attempts: 1,
        difficulty: _adaptiveDifficulty?.index.toDouble() ?? 1.0,
        completedAt: DateTime.now(),
      );
      
      _difficultyCalculator.updatePerformanceData(
        _currentUserId!,
        widget.subject.toString(),
        performanceData,
      );
      
      // Get updated difficulty recommendation if needed
      if (questionIndex > 0 && questionIndex % 3 == 0) { // Check every 3 questions
        final recommendation = await _difficultyCalculator.calculateOptimalDifficulty(
          _currentUserId!,
          widget.level,
          widget.subject.toString(),
          currentDifficulty: widget.level.toDouble(),
        );
        
        final newDifficultyLevel = _getDifficultyLevelFromDouble(recommendation.recommendedDifficulty);
        
        if (newDifficultyLevel != _adaptiveDifficulty) {
          setState(() {
            _adaptiveDifficulty = newDifficultyLevel;
          });
        }
      }
    } catch (e) {
      print('Error updating adaptive difficulty: $e');
    }
  }

  DifficultyLevel _getDifficultyLevelFromDouble(double difficulty) {
    if (difficulty <= 2) return DifficultyLevel.beginner;
    if (difficulty <= 4) return DifficultyLevel.easy;
    if (difficulty <= 6) return DifficultyLevel.medium;
    if (difficulty <= 8) return DifficultyLevel.hard;
    return DifficultyLevel.expert;
  }

  String _getDifficultyName(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 'Beginner';
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
      case DifficultyLevel.expert:
        return 'Expert';
    }
  }

  int _getDifficultyLevel(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 1;
      case DifficultyLevel.easy:
        return 3;
      case DifficultyLevel.medium:
        return 5;
      case DifficultyLevel.hard:
        return 7;
      case DifficultyLevel.expert:
        return 10;
    }
  }

  double _calculateLearningPathProgress() {
    if (_currentLearningPath == null) return 0.0;
    
    // Calculate progress based on completed segments
    final completedSegments = _currentLearningPath!.segments
        .where((segment) => segment.status == SegmentStatus.completed)
        .length;
    
    if (_currentLearningPath!.segments.isEmpty) return 0.0;
    
    return completedSegments / _currentLearningPath!.segments.length;
  }

  String? _getNextRecommendation() {
    if (_currentLearningPath == null) return null;
    
    // Find the next pending segment
    final nextSegment = _currentLearningPath!.segments
        .where((segment) => segment.status == SegmentStatus.pending)
        .firstOrNull;
    
    return nextSegment?.name;
  }

  void _showLearningPathInfo(BuildContext context) {
    if (_currentLearningPath == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getPathIcon(_currentLearningPath!.type),
              color: _getPathColor(_currentLearningPath!.type),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_getPathName(_currentLearningPath!.type)} Learning Path',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress: ${(_calculateLearningPathProgress() * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _currentLearningPath!.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Segments:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(_currentLearningPath!.segments.take(3).map((segment) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      segment.status == SegmentStatus.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 16,
                      color: segment.status == SegmentStatus.completed ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        segment.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: segment.status == SegmentStatus.completed ? Colors.green : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
            if (_currentLearningPath!.segments.length > 3)
              Text(
                '... and ${_currentLearningPath!.segments.length - 3} more',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Color _getPathColor(LearningPathType? pathType) {
    if (pathType == null) return Colors.grey;
    
    switch (pathType) {
      case LearningPathType.adaptive:
        return Colors.purple;
      case LearningPathType.structured:
        return Colors.blue;
      case LearningPathType.exploratory:
        return Colors.green;
      case LearningPathType.remedial:
        return Colors.orange;
      case LearningPathType.accelerated:
        return Colors.red;
      case LearningPathType.collaborative:
        return Colors.teal;
      case LearningPathType.projectBased:
        return Colors.indigo;
      case LearningPathType.gamified:
        return Colors.pink;
    }
  }

  String _getPathName(LearningPathType? pathType) {
    if (pathType == null) return 'Standard';
    
    switch (pathType) {
      case LearningPathType.adaptive:
        return 'Adaptive';
      case LearningPathType.structured:
        return 'Structured';
      case LearningPathType.exploratory:
        return 'Exploratory';
      case LearningPathType.remedial:
        return 'Remedial';
      case LearningPathType.accelerated:
        return 'Accelerated';
      case LearningPathType.collaborative:
        return 'Collaborative';
      case LearningPathType.projectBased:
        return 'Project-Based';
      case LearningPathType.gamified:
        return 'Gamified';
    }
  }

  IconData _getPathIcon(LearningPathType? pathType) {
    if (pathType == null) return Icons.school;
    
    switch (pathType) {
      case LearningPathType.adaptive:
        return Icons.auto_awesome;
      case LearningPathType.structured:
        return Icons.list_alt;
      case LearningPathType.exploratory:
        return Icons.explore;
      case LearningPathType.remedial:
        return Icons.healing;
      case LearningPathType.accelerated:
        return Icons.speed;
      case LearningPathType.collaborative:
        return Icons.group;
      case LearningPathType.projectBased:
        return Icons.build;
      case LearningPathType.gamified:
        return Icons.games;
    }
  }

  void _showAdaptiveDifficultyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: _getDifficultyColor(_adaptiveDifficulty!),
            ),
            const SizedBox(width: 8),
            const Text('Adaptive Difficulty'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Level: ${_getDifficultyName(_adaptiveDifficulty!)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'The system is automatically adjusting the difficulty based on your performance to provide the optimal learning experience.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Keep answering questions to help the system find your perfect difficulty level!',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return Colors.green;
      case DifficultyLevel.easy:
        return Colors.lightGreen;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
      case DifficultyLevel.expert:
        return Colors.purple;
    }
  }

  void _showPauseDialog(BuildContext context, GameController controller) {
    controller.pauseGame();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Paused'),
        content: const Text('Your progress has been saved. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Exit game session
            },
            child: const Text('Quit Game'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog only
              controller.resumeGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getSubjectColor(widget.subject),
              foregroundColor: Colors.white,
            ),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  Color _getSubjectColor(SubjectType subject) {
    switch (subject) {
      case SubjectType.math:
        return Colors.blue;
      case SubjectType.physics:
        return Colors.purple;
      case SubjectType.chemistry:
        return Colors.green;
      case SubjectType.biology:
        return Colors.orange;
      case SubjectType.science:
        return Colors.indigo;
      case SubjectType.english:
        return Colors.pink;
      case SubjectType.history:
        return Colors.red;
      case SubjectType.geography:
        return Colors.brown;
      case SubjectType.art:
        return Colors.deepPurple;
      case SubjectType.music:
        return Colors.amber;
      case SubjectType.physicalEducation:
        return Colors.lightGreen;
      case SubjectType.computerScience:
        return Colors.teal;
    }
  }

  String _getSubjectName(SubjectType subject) {
    switch (subject) {
      case SubjectType.math:
        return 'Mathematics';
      case SubjectType.physics:
        return 'Physics';
      case SubjectType.chemistry:
        return 'Chemistry';
      case SubjectType.biology:
        return 'Biology';
      case SubjectType.science:
        return 'Science';
      case SubjectType.english:
        return 'English';
      case SubjectType.history:
        return 'History';
      case SubjectType.geography:
        return 'Geography';
      case SubjectType.art:
        return 'Art';
      case SubjectType.music:
        return 'Music';
      case SubjectType.physicalEducation:
        return 'Physical Education';
      case SubjectType.computerScience:
        return 'Computer Science';
    }
  }
}