import 'package:flutter/material.dart';

/// Empty State Widget - Task B4
/// Beautiful empty states with illustrations and CTAs
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyStateWidget({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: (iconColor ?? Theme.of(context).colorScheme.primary)
                          .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 60,
                      color: iconColor ?? Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            
            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Predefined empty states for common scenarios
class EmptyStates {
  static Widget noResults({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'No Results Found',
      message: 'Try adjusting your search or filters',
      actionLabel: onRetry != null ? 'Clear Filters' : null,
      onAction: onRetry,
      iconColor: Colors.orange,
    );
  }

  static Widget noFriends({VoidCallback? onAddFriends}) {
    return EmptyStateWidget(
      icon: Icons.people_outline,
      title: 'No Friends Yet',
      message: 'Add friends to compete and learn together!',
      actionLabel: 'Find Friends',
      onAction: onAddFriends,
      iconColor: Colors.blue,
    );
  }

  static Widget noAchievements() {
    return EmptyStateWidget(
      icon: Icons.emoji_events_outlined,
      title: 'No Achievements Yet',
      message: 'Complete challenges to earn your first achievement!',
      iconColor: Colors.amber,
    );
  }

  static Widget noNotifications() {
    return EmptyStateWidget(
      icon: Icons.notifications_none,
      title: 'All Caught Up!',
      message: 'You have no new notifications',
      iconColor: Colors.green,
    );
  }

  static Widget noHistory() {
    return EmptyStateWidget(
      icon: Icons.history,
      title: 'No History',
      message: 'Your learning history will appear here',
      iconColor: Colors.purple,
    );
  }

  static Widget noBookmarks({VoidCallback? onExplore}) {
    return EmptyStateWidget(
      icon: Icons.bookmark_border,
      title: 'No Bookmarks',
      message: 'Save your favorite lessons for quick access',
      actionLabel: 'Explore Lessons',
      onAction: onExplore,
      iconColor: Colors.red,
    );
  }

  static Widget noProgress() {
    return EmptyStateWidget(
      icon: Icons.trending_up,
      title: 'Start Your Journey',
      message: 'Complete your first lesson to see your progress',
      iconColor: Colors.teal,
    );
  }

  static Widget offline({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.cloud_off,
      title: 'You\'re Offline',
      message: 'Check your internet connection and try again',
      actionLabel: 'Retry',
      onAction: onRetry,
      iconColor: Colors.grey,
    );
  }

  static Widget error({
    required String message,
    VoidCallback? onRetry,
  }) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: 'Oops! Something Went Wrong',
      message: message,
      actionLabel: onRetry != null ? 'Try Again' : null,
      onAction: onRetry,
      iconColor: Colors.red,
    );
  }

  static Widget comingSoon() {
    return EmptyStateWidget(
      icon: Icons.rocket_launch,
      title: 'Coming Soon!',
      message: 'This feature is under development',
      iconColor: Colors.deepPurple,
    );
  }
}

/// Error State Widget with more details
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? errorDetails;
  final VoidCallback? onRetry;
  final VoidCallback? onReport;

  const ErrorStateWidget({
    Key? key,
    required this.title,
    required this.message,
    this.errorDetails,
    this.onRetry,
    this.onReport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            
            // Error details (expandable)
            if (errorDetails != null) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Technical Details'),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorDetails!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                if (onRetry != null && onReport != null)
                  const SizedBox(width: 12),
                if (onReport != null)
                  OutlinedButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Report Issue'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading State with message
class LoadingStateWidget extends StatelessWidget {
  final String? message;

  const LoadingStateWidget({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

