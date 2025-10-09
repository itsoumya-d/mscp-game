import 'package:flutter/material.dart' hide CircularProgressIndicator;
import 'package:flutter/services.dart';
import '../../core/models/flashcard.dart';
import '../../core/models/study_session.dart';
import '../../core/services/flashcard_service.dart';
import 'widgets/flashcard_widget.dart';
import 'widgets/rating_buttons.dart';
import 'widgets/progress_indicator.dart';
import 'widgets/achievement_popup.dart';

class FlashcardStudyScreen extends StatefulWidget {
  final String subjectId;
  final String? skillId;
  final int? targetCount;

  const FlashcardStudyScreen({
    Key? key,
    required this.subjectId,
    this.skillId,
    this.targetCount = 20,
  }) : super(key: key);

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen>
    with TickerProviderStateMixin {
  final FlashcardService _flashcardService = FlashcardService.getInstance();
  
  // Animation controllers
  late AnimationController _flipController;
  late AnimationController _slideController;
  late AnimationController _shakeController;
  
  // Animations
  late Animation<double> _flipAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _shakeAnimation;
  
  // Study session data
  StudySession? _currentSession;
  List<Flashcard> _flashcards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isLoading = true;
  bool _showRatingButtons = false;
  
  // Performance tracking
  int _correctCount = 0;
  int _totalReviewed = 0;
  int _xpEarned = 0;
  DateTime _sessionStartTime = DateTime.now();
  
  // Achievement tracking
  List<Achievement> _pendingAchievements = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFlashcards();
  }

  void _initializeAnimations() {
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  Future<void> _loadFlashcards() async {
    try {
      setState(() => _isLoading = true);
      
      _flashcards = await _flashcardService.generateFlashcardsForSkill(
        subjectId: widget.subjectId ?? 'math',
        skillId: widget.skillId ?? 'basic',
        difficultyLevel: 1,
        count: widget.targetCount ?? 20,
      );
      
      if (_flashcards.isNotEmpty) {
        _currentSession = await _flashcardService.startStudySession(
          subjectId: widget.subjectId,
          targetCards: _flashcards.length,
        );
        _sessionStartTime = DateTime.now();
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to load flashcards: $e');
    }
  }

  Future<void> _flipCard() async {
    if (_isFlipped || _showRatingButtons) return;
    
    HapticFeedback.lightImpact();
    await _flipController.forward();
    
    setState(() {
      _isFlipped = true;
      _showRatingButtons = true;
    });
  }

  Future<void> _handleRating(ReviewRating rating) async {
    if (!_isFlipped || _currentIndex >= _flashcards.length) return;
    
    try {
      final flashcard = _flashcards[_currentIndex];
      final reviewResult = await _flashcardService.reviewFlashcard(
        flashcardId: flashcard.id,
        rating: rating,
      );
      
      // Update performance tracking
      _totalReviewed++;
      _xpEarned += reviewResult.xpEarned;
      
      if (rating == ReviewRating.good || rating == ReviewRating.easy) {
        _correctCount++;
      }
      
      // Check for achievements - commented out as method doesn't exist
      // final achievements = await _flashcardService.checkAchievements(
      //   _currentSession!.id,
      // );
      
      // if (achievements.isNotEmpty) {
      //   _pendingAchievements.addAll(achievements);
      // }
      
      // Move to next card
      await _nextCard();
      
    } catch (e) {
      _showErrorDialog('Failed to save review: $e');
    }
  }

  Future<void> _nextCard() async {
    if (_currentIndex >= _flashcards.length - 1) {
      await _completeSession();
      return;
    }
    
    // Slide out current card
    await _slideController.forward();
    
    // Reset for next card
    setState(() {
      _currentIndex++;
      _isFlipped = false;
      _showRatingButtons = false;
    });
    
    // Reset animations
    _flipController.reset();
    _slideController.reset();
    
    // Show achievements if any
    if (_pendingAchievements.isNotEmpty) {
      _showAchievementPopup(_pendingAchievements.removeAt(0));
    }
  }

  Future<void> _completeSession() async {
    if (_currentSession == null) return;
    
    try {
      final sessionResult = await _flashcardService.completeStudySession(
        _currentSession!,
      );
      
      // Show session summary
      _showSessionSummary(sessionResult);
      
    } catch (e) {
      _showErrorDialog('Failed to complete session: $e');
    }
  }

  void _showAchievementPopup(Achievement achievement) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AchievementPopup(
        achievement: achievement,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showSessionSummary(SessionResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildSessionSummaryDialog(context, result),
    );
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
    _flipController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
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
            const CircularProgressIndicator(progress: 0.0),
            const SizedBox(height: 16),
              Text(
              'Loading flashcards...',
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
    
    if (_flashcards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Study Session'),
        ),
        body: const Center(
          child: Text(
            'No flashcards available for study.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }
    
    return RatingButtonsKeyboardHandler(
      onRatingSelected: _handleRating,
      isEnabled: _showRatingButtons,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              StudyProgressIndicator(
                currentCard: _currentIndex + 1,
                totalCards: _flashcards.length,
                accuracy: _totalReviewed > 0 ? _correctCount / _totalReviewed : 0.0,
                xpEarned: _xpEarned,
                studyTime: DateTime.now().difference(_sessionStartTime),
              ),
              
              // Flashcard area
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: _flipCard,
                    child: AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            _slideAnimation.value.dx * MediaQuery.of(context).size.width,
                            0,
                          ),
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            child: FlashcardWidget(
                              flashcard: _flashcards[_currentIndex],
                              showBack: _isFlipped,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              // Rating buttons
              if (_showRatingButtons)
                RatingButtons(
                  onRatingSelected: _handleRating,
                  isEnabled: true,
                ),
              
              // Tap to flip hint
              if (!_isFlipped && !_showRatingButtons)
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tap card to reveal answer',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionSummaryDialog(BuildContext context, SessionResult result) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF4ECDC4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'Session Complete!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
            ),
            
            const SizedBox(height: 16),
            
            // Stats
            _buildStatRow('Cards Reviewed', '${result.session.results.length}'),
            _buildStatRow('Accuracy', '${(result.accuracy * 100).toInt()}%'),
            _buildStatRow('XP Earned', '+${result.totalXp}'),
            _buildStatRow('Study Time', _formatDuration(result.studyTime)),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _loadFlashcards(); // Start new session
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ECDC4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Study Again'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}