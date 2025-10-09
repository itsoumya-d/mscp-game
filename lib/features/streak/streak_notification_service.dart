import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sp/core/services/progress_service.dart';

class StreakNotificationService {
  static StreakNotificationService? _instance;
  
  static StreakNotificationService getInstance() {
    _instance ??= StreakNotificationService._internal();
    return _instance!;
  }
  
  @Deprecated('Use getInstance() instead')
  static StreakNotificationService get instance => getInstance();
  
  factory StreakNotificationService() => getInstance();
  StreakNotificationService._internal();

  /// Check if user's streak is at risk and show appropriate notifications
  static void checkStreakStatus(BuildContext context, WidgetRef ref) {
    final user = ref.read(progressProvider).user;
    final now = DateTime.now();
    final lastActive = user.lastActiveDate;

    if (lastActive == null) return;

    final daysSinceActive = now.difference(lastActive).inDays;
    
    // Show warning if user hasn't been active today and it's past 6 PM
    if (daysSinceActive == 0 && now.hour >= 18) {
      _showStreakReminder(context, user.currentStreak);
    }
    
    // Show streak loss warning if user missed yesterday
    else if (daysSinceActive == 1) {
      _showStreakAtRisk(context, user.currentStreak);
    }
  }

  static void _showStreakReminder(BuildContext context, int currentStreak) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.local_fire_department, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Don\'t forget to practice today! Keep your $currentStreak-day streak alive! 🔥',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Practice Now',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to a subject or lesson
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
      ),
    );
  }

  static void _showStreakAtRisk(BuildContext context, int currentStreak) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your $currentStreak-day streak is at risk! Practice now or use a streak freeze.',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Save Streak',
          textColor: Colors.white,
          onPressed: () {
            _showStreakSaveDialog(context);
          },
        ),
      ),
    );
  }

  static void _showStreakSaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.orange),
            SizedBox(width: 8),
            Text('Save Your Streak'),
          ],
        ),
        content: const Text(
          'Your streak is about to break! You can:\n\n'
          '• Practice now to maintain it naturally\n'
          '• Use a Streak Freeze (5 gems) to protect it\n'
          '• Let it reset and start fresh',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Let it Reset'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/gem-store');
            },
            child: const Text('Use Streak Freeze'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: const Text('Practice Now'),
          ),
        ],
      ),
    );
  }

  /// Show celebration for streak milestones
  static void showStreakMilestone(BuildContext context, int streak, int gemsEarned) {
    if (!context.mounted) return;

    String message;
    IconData icon;
    Color color;

    if (streak % 7 == 0) {
      message = 'Amazing! $streak days in a row! 🎉';
      icon = Icons.celebration;
      color = Colors.purple;
    } else if (streak % 3 == 0) {
      message = 'Great job! $streak-day streak! 🔥';
      icon = Icons.local_fire_department;
      color = Colors.orange;
    } else {
      message = 'Day $streak complete! 💪';
      icon = Icons.check_circle;
      color = Colors.green;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '+$gemsEarned gems earned!',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.diamond, color: Colors.white),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}