import 'package:flutter/material.dart';

/// Reusable difficulty badge widget with color coding
class DifficultyBadge extends StatelessWidget {
  final int level;
  final bool showLabel;
  final double size;

  const DifficultyBadge({
    Key? key,
    required this.level,
    this.showLabel = true,
    this.size = 14,
  }) : super(key: key);

  String get difficulty {
    if (level <= 3) return 'Easy';
    if (level <= 7) return 'Medium';
    return 'Hard';
  }

  Color get color {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (difficulty) {
      case 'Easy':
        return Icons.signal_cellular_alt_1_bar;
      case 'Medium':
        return Icons.signal_cellular_alt;
      case 'Hard':
        return Icons.signal_cellular_alt;
      default:
        return Icons.signal_cellular_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 12 : 8,
        vertical: showLabel ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: size,
            color: color,
          ),
          if (showLabel) ...[
            SizedBox(width: size * 0.3),
            Text(
              difficulty,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.85,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Large difficulty badge for headers
class LargeDifficultyBadge extends StatelessWidget {
  final int level;

  const LargeDifficultyBadge({
    Key? key,
    required this.level,
  }) : super(key: key);

  String get difficulty {
    if (level <= 3) return 'Easy';
    if (level <= 7) return 'Medium';
    return 'Hard';
  }

  Color get color {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.signal_cellular_alt,
            color: color,
            size: 32,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Difficulty',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                difficulty,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

