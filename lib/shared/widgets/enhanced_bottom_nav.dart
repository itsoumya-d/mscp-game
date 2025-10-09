import 'package:flutter/material.dart';

/// Enhanced Bottom Navigation - Task B6
/// Animated bottom nav with badges and haptic feedback
class EnhancedBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;

  const EnhancedBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  State<EnhancedBottomNav> createState() => _EnhancedBottomNavState();
}

class _EnhancedBottomNavState extends State<EnhancedBottomNav>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
    
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
    
    _controllers[widget.currentIndex].forward();
  }

  @override
  void didUpdateWidget(EnhancedBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controllers[oldWidget.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(widget.items.length, (index) {
              return _buildNavItem(index);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = widget.items[index];
    final isSelected = index == widget.currentIndex;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          widget.onTap(index);
          // Add haptic feedback
          // HapticFeedback.lightImpact();
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Animated background
                      if (isSelected)
                        Transform.scale(
                          scale: _animations[index].value,
                          child: Container(
                            width: 56,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      
                      // Icon
                      Container(
                        width: 56,
                        height: 32,
                        alignment: Alignment.center,
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                      
                      // Badge
                      if (item.badge != null && item.badge! > 0)
                        Positioned(
                          right: 8,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              item.badge! > 99 ? '99+' : '${item.badge}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Label
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: isSelected ? 12 : 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[600],
                    ),
                    child: Text(item.label),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Bottom navigation item model
class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badge;

  BottomNavItem({
    required this.icon,
    IconData? activeIcon,
    required this.label,
    this.badge,
  }) : activeIcon = activeIcon ?? icon;
}

/// Floating Action Button for bottom nav
class FloatingNavButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;

  const FloatingNavButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      elevation: 4,
      child: Icon(icon),
    );
  }
}

/// Bottom nav with FAB
class EnhancedBottomNavWithFAB extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  final VoidCallback? onFABPressed;
  final IconData? fabIcon;
  final String? fabTooltip;

  const EnhancedBottomNavWithFAB({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.onFABPressed,
    this.fabIcon,
    this.fabTooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        EnhancedBottomNav(
          currentIndex: currentIndex,
          onTap: onTap,
          items: items,
        ),
        if (onFABPressed != null)
          Positioned(
            bottom: 32,
            child: FloatingNavButton(
              onPressed: onFABPressed!,
              icon: fabIcon ?? Icons.add,
              tooltip: fabTooltip,
            ),
          ),
      ],
    );
  }
}

/// Example usage
class BottomNavExample extends StatefulWidget {
  const BottomNavExample({Key? key}) : super(key: key);

  @override
  State<BottomNavExample> createState() => _BottomNavExampleState();
}

class _BottomNavExampleState extends State<BottomNavExample> {
  int _currentIndex = 0;

  final List<BottomNavItem> _items = [
    BottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    BottomNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Explore',
    ),
    BottomNavItem(
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events,
      label: 'Challenges',
      badge: 3,
    ),
    BottomNavItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Chat',
      badge: 5,
    ),
    BottomNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Page $_currentIndex'),
      ),
      bottomNavigationBar: EnhancedBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: _items,
      ),
    );
  }
}

