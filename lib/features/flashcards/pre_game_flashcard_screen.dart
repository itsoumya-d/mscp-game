import 'package:flutter/material.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/models/flashcard.dart';
import 'package:sp/core/models/difficulty_level.dart';
import 'package:sp/core/services/flashcard_service.dart';
import 'package:sp/core/services/level_flashcard_integration_service.dart';

/// Pre-game flashcard screen that shows 5 flashcards before starting a level
class PreGameFlashcardScreen extends StatefulWidget {
  final SubjectType subject;
  final int level;
  final String skillId;
  final String skillName;
  final VoidCallback onComplete;

  const PreGameFlashcardScreen({
    Key? key,
    required this.subject,
    required this.level,
    required this.skillId,
    required this.skillName,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<PreGameFlashcardScreen> createState() => _PreGameFlashcardScreenState();
}

class _PreGameFlashcardScreenState extends State<PreGameFlashcardScreen>
    with TickerProviderStateMixin {
  final FlashcardService _flashcardService = FlashcardService.getInstance();
  final LevelFlashcardIntegrationService _integrationService = LevelFlashcardIntegrationService();
  
  List<Flashcard> _flashcards = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isFlipped = false;
  
  late AnimationController _flipController;
  late AnimationController _progressController;
  late Animation<double> _flipAnimation;
  late Animation<double> _progressAnimation;

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
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _loadFlashcards() async {
    setState(() => _isLoading = true);
    
    try {
      // Try to get flashcards from the integration service
      final flashcards = await _integrationService.generateSkillReinforcementCards(
        subjectId: widget.subject.name,
        skillId: widget.skillId,
        count: 5,
      );
      
      if (flashcards.isNotEmpty) {
        setState(() {
          _flashcards = flashcards.take(5).toList();
          _isLoading = false;
        });
      } else {
        // Fallback: create sample flashcards
        _createFallbackFlashcards();
      }
      
      // Start progress animation
      _progressController.forward();
    } catch (e) {
      debugPrint('Error loading flashcards: $e');
      _createFallbackFlashcards();
    }
  }

  void _createFallbackFlashcards() {
    final fallbackCards = <Flashcard>[];
    
    for (int i = 0; i < 5; i++) {
      fallbackCards.add(Flashcard(
        id: 'fallback_${widget.skillId}_$i',
        front: _getFallbackQuestion(i),
        back: _getFallbackAnswer(i),
        subjectId: widget.subject.name,
        skillId: widget.skillId,
        type: FlashcardType.basic,
        difficulty: DifficultyLevel.easy.numericLevel,
        tags: [widget.skillName, 'level_${widget.level}'],
        createdAt: DateTime.now(),
        lastReviewDate: null,
        nextReviewDate: DateTime.now(),
        easeFactor: 2.5,
        interval: 1,
        repetitions: 0,
        totalReviews: 0,
        correctReviews: 0,
        averageResponseTime: 0,
        recentRatings: [],
      ));
    }
    
    setState(() {
      _flashcards = fallbackCards;
      _isLoading = false;
    });
    
    _progressController.forward();
  }

  String _getFallbackQuestion(int index) {
    switch (widget.subject) {
      case SubjectType.math:
        return 'What is ${(index + 1) * 2} + ${(index + 1) * 3}?';
      case SubjectType.physics:
        return 'What is the unit of force?';
      case SubjectType.chemistry:
        return 'What is the chemical symbol for water?';
      case SubjectType.biology:
        return 'What is the powerhouse of the cell?';
      default:
        return 'Sample question ${index + 1} for ${widget.skillName}';
    }
  }

  String _getFallbackAnswer(int index) {
    switch (widget.subject) {
      case SubjectType.math:
        return '${(index + 1) * 5}';
      case SubjectType.physics:
        return 'Newton (N)';
      case SubjectType.chemistry:
        return 'H₂O';
      case SubjectType.biology:
        return 'Mitochondria';
      default:
        return 'Sample answer ${index + 1}';
    }
  }

  void _flipCard() {
    if (_flipController.isCompleted) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _nextCard() {
    if (_currentIndex < _flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
      _flipController.reset();
      _progressController.forward();
    } else {
      _completeFlashcards();
    }
  }

  void _skipToGame() {
    widget.onComplete();
  }

  void _completeFlashcards() {
    widget.onComplete();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: _getSubjectColor(widget.subject).withValues(alpha: 0.1),
      appBar: AppBar(
        title: Text('${widget.skillName} - Review'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _skipToGame,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProgressIndicator(theme),
                const SizedBox(height: 20),
                _buildCardCounter(theme),
                const SizedBox(height: 20),
                Expanded(
                  child: _buildFlashcard(theme),
                ),
                _buildActionButtons(theme),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_currentIndex + 1} / ${_flashcards.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _getSubjectColor(widget.subject),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: (_currentIndex + _progressAnimation.value) / _flashcards.length,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getSubjectColor(widget.subject),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardCounter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getSubjectColor(widget.subject).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Card ${_currentIndex + 1} of ${_flashcards.length}',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: _getSubjectColor(widget.subject),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFlashcard(ThemeData theme) {
    if (_flashcards.isEmpty) return const SizedBox();
    
    final currentCard = _flashcards[_currentIndex];
    
    return Container(
      margin: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: _flipCard,
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            final isShowingFront = _flipAnimation.value < 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_flipAnimation.value * 3.14159),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getSubjectColor(widget.subject).withValues(alpha: 0.1),
                        _getSubjectColor(widget.subject).withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: isShowingFront
                      ? _buildCardFront(currentCard, theme)
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(3.14159),
                          child: _buildCardBack(currentCard, theme),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFront(Flashcard card, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.quiz,
          size: 48,
          color: _getSubjectColor(widget.subject),
        ),
        const SizedBox(height: 20),
        Text(
          card.front,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getSubjectColor(widget.subject).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Tap to reveal answer',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _getSubjectColor(widget.subject),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardBack(Flashcard card, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lightbulb,
          size: 48,
          color: _getSubjectColor(widget.subject),
        ),
        const SizedBox(height: 20),
        Text(
          card.back,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.subject.name.toUpperCase(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getDifficultyColor(card.difficulty).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getDifficultyText(card.difficulty),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getDifficultyColor(card.difficulty),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (!_isFlipped) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _flipCard,
                icon: const Icon(Icons.flip_to_back),
                label: const Text('Reveal Answer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _getSubjectColor(widget.subject),
                  side: BorderSide(color: _getSubjectColor(widget.subject)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _nextCard,
                icon: Icon(_currentIndex < _flashcards.length - 1 
                    ? Icons.arrow_forward 
                    : Icons.play_arrow),
                label: Text(_currentIndex < _flashcards.length - 1 
                    ? 'Next Card' 
                    : 'Start Game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getSubjectColor(widget.subject),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getSubjectColor(SubjectType subject) {
    switch (subject) {
      case SubjectType.math:
        return const Color(0xFF2196F3);
      case SubjectType.physics:
        return const Color(0xFF9C27B0);
      case SubjectType.chemistry:
        return const Color(0xFF4CAF50);
      case SubjectType.biology:
        return const Color(0xFFFF9800);
      case SubjectType.science:
        return const Color(0xFFF44336);
      case SubjectType.computerScience:
        return const Color(0xFF607D8B);
      case SubjectType.geography:
        return const Color(0xFF795548);
      case SubjectType.history:
        return const Color(0xFF9E9E9E);
      case SubjectType.english:
        return const Color(0xFFE91E63);
      case SubjectType.art:
        return const Color(0xFFFF5722);
      case SubjectType.music:
        return const Color(0xFF673AB7);
      case SubjectType.physicalEducation:
        return const Color(0xFF8BC34A);
    }
  }

  Color _getDifficultyColor(int difficulty) {
    if (difficulty <= 2) {
      return Colors.green; // Beginner/Easy
    } else if (difficulty <= 4) {
      return Colors.lightGreen; // Easy
    } else if (difficulty <= 6) {
      return Colors.orange; // Medium
    } else if (difficulty <= 8) {
      return Colors.red; // Hard
    } else {
      return Colors.purple; // Expert
    }
  }

  String _getDifficultyText(int difficulty) {
    if (difficulty <= 2) {
      return 'Beginner';
    } else if (difficulty <= 4) {
      return 'Easy';
    } else if (difficulty <= 6) {
      return 'Medium';
    } else if (difficulty <= 8) {
      return 'Hard';
    } else {
      return 'Expert';
    }
  }
}