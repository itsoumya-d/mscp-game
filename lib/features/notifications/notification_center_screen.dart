import 'package:flutter/material.dart';

/// Notification Center - Task B10
/// Categorized notifications with mark as read, actions, and settings
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';

  // Mock data - replace with actual data from backend
  final List<AppNotification> _notifications = [
    AppNotification(
      id: '1',
      type: NotificationType.achievement,
      title: 'New Achievement Unlocked!',
      message: 'You earned the "Math Master" badge',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
      actionLabel: 'View',
    ),
    AppNotification(
      id: '2',
      type: NotificationType.reminder,
      title: 'Daily Goal Reminder',
      message: 'You\'re 50 XP away from your daily goal!',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
      actionLabel: 'Practice Now',
    ),
    AppNotification(
      id: '3',
      type: NotificationType.social,
      title: 'New Friend Request',
      message: 'Sarah Johnson wants to be your friend',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
      actionLabel: 'Accept',
    ),
    AppNotification(
      id: '4',
      type: NotificationType.update,
      title: 'New Content Available',
      message: 'Check out the new Algebra lessons!',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      actionLabel: 'Explore',
    ),
    AppNotification(
      id: '5',
      type: NotificationType.achievement,
      title: 'Streak Milestone!',
      message: 'You\'ve maintained a 30-day streak!',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      actionLabel: 'View',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<AppNotification> get _filteredNotifications {
    if (_selectedFilter == 'all') return _notifications;
    if (_selectedFilter == 'unread') {
      return _notifications.where((n) => !n.isRead).toList();
    }
    final type = NotificationType.values.firstWhere(
      (t) => t.toString().split('.').last == _selectedFilter,
    );
    return _notifications.where((n) => n.type == type).toList();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all),
              label: const Text('Mark all read'),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openNotificationSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          if (_unreadCount > 0) _buildUnreadBanner(),
          Expanded(
            child: _buildNotificationList(),
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
            _buildFilterChip('All', 'all', Icons.notifications),
            const SizedBox(width: 8),
            _buildFilterChip('Unread', 'unread', Icons.mark_email_unread),
            const SizedBox(width: 8),
            _buildFilterChip('Achievements', 'achievement', Icons.emoji_events),
            const SizedBox(width: 8),
            _buildFilterChip('Reminders', 'reminder', Icons.alarm),
            const SizedBox(width: 8),
            _buildFilterChip('Social', 'social', Icons.people),
            const SizedBox(width: 8),
            _buildFilterChip('Updates', 'update', Icons.new_releases),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
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
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
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

  Widget _buildUnreadBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You have $_unreadCount unread notification${_unreadCount > 1 ? 's' : ''}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    final notifications = _filteredNotifications;

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationCard(notifications[index]);
      },
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          _notifications.remove(notification);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _notifications.add(notification);
                });
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: notification.isRead
            ? null
            : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification.type),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTimestamp(notification.timestamp),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          if (notification.actionLabel != null)
                            TextButton(
                              onPressed: () => _handleAction(notification),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(notification.actionLabel!),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.achievement:
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case NotificationType.reminder:
        icon = Icons.alarm;
        color = Colors.orange;
        break;
      case NotificationType.social:
        icon = Icons.people;
        color = Colors.blue;
        break;
      case NotificationType.update:
        icon = Icons.new_releases;
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    if (!notification.isRead) {
      setState(() {
        notification.isRead = true;
      });
    }
  }

  void _handleAction(AppNotification notification) {
    // Handle notification action
    print('Action: ${notification.actionLabel}');
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
  }

  void _openNotificationSettings() {
    // Navigate to notification settings
  }
}

/// Notification types
enum NotificationType {
  achievement,
  reminder,
  social,
  update,
}

/// Notification data model
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final String? actionLabel;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.actionLabel,
  });
}

