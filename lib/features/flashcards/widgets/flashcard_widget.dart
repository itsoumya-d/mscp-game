import 'package:flutter/material.dart';
import '../../../core/models/flashcard.dart';
import 'multimedia_widget.dart';

/// Animated flashcard widget with flip animation and multimedia support
class FlashcardWidget extends StatelessWidget {
  final Flashcard flashcard;
  final bool showBack;
  final VoidCallback? onTap;
  final double elevation;

  const FlashcardWidget({
    Key? key,
    required this.flashcard,
    this.showBack = false,
    this.onTap,
    this.elevation = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 400,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Card(
          elevation: elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: _getSubjectGradient(),
            ),
            child: showBack ? _buildBackSide() : _buildFrontSide(),
           ),
         ),
       ),
     );
   }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTypeChip(),
        _buildDifficultyIndicator(),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showBack) _buildAccuracyIndicator() else _buildTagsRow(),
        if (showBack) _buildStreakIndicator() else _buildNextReviewInfo(),
      ],
    );
  }

  Widget _buildFrontSide() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Multimedia content
                if (flashcard.multimedia != null)
                  Expanded(
                    flex: 2,
                    child: MultimediaWidget(
                      content: [flashcard.multimedia!],
                      maxHeight: 180,
                      onInteraction: () {
                        // Handle multimedia interaction
                      },
                    ),
                  ),
                
                if (flashcard.multimedia != null)
                  const SizedBox(height: 16),
                
                // Question text
                Expanded(
                  flex: flashcard.multimedia == null ? 3 : 1,
                  child: Center(
                    child: Text(
                      flashcard.front,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildBackSide() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Answer with multimedia support
                if (flashcard.multimedia != null)
                  Expanded(
                    flex: 2,
                    child: MultimediaWidget(
                      content: [flashcard.multimedia!],
                      maxHeight: 160,
                      onInteraction: () {
                        // Handle multimedia interaction
                      },
                    ),
                  ),
                
                if (flashcard.multimedia != null)
                  const SizedBox(height: 16),
                
                // Answer text
                Expanded(
                  flex: flashcard.multimedia == null ? 3 : 2,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          flashcard.back,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  LinearGradient _getSubjectGradient() {
    switch (flashcard.subjectId.toLowerCase()) {
      case 'math':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        );
      case 'physics':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
        );
      case 'chemistry':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFfc466b), Color(0xFF3f5efb)],
        );
      case 'biology':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
        );
      case 'computer science':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        );
    }
  }

  Widget _buildTypeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        flashcard.type.name.toUpperCase().replaceAll('_', ' '),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDifficultyIndicator() {
    return Row(
      children: List.generate(5, (index) {
        return Container(
          margin: const EdgeInsets.only(left: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: index < flashcard.difficulty 
                ? Colors.white 
                : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildAccuracyIndicator() {
    final accuracy = flashcard.accuracy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getAccuracyColor(accuracy).withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up,
            color: _getAccuracyColor(accuracy),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${(accuracy * 100).toInt()}%',
            style: TextStyle(
              color: _getAccuracyColor(accuracy),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${flashcard.repetitions}',
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsRow() {
    return Wrap(
      spacing: 8,
      children: flashcard.tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextReviewInfo() {
    final nextReview = flashcard.nextReviewDate;
    final now = DateTime.now();
    final difference = nextReview.difference(now);
    
    String timeText;
    if (difference.inDays > 0) {
      timeText = '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      timeText = '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      timeText = '${difference.inMinutes}m';
    } else {
      timeText = 'Now';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule,
            color: Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'Next: $timeText',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

class CardPatternPainter extends CustomPainter {
  final Color color;
  final bool isBack;

  const CardPatternPainter({required this.color, this.isBack = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    if (isBack) {
      // Draw grid pattern for back
      const spacing = 30.0;
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else {
      // Draw geometric pattern for front
      const spacing = 40.0;
      for (double x = 0; x < size.width; x += spacing) {
        for (double y = 0; y < size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), 2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}