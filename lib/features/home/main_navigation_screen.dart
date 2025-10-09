import 'package:flutter/material.dart';
import 'package:sp/features/home/home_screen.dart';
import 'package:sp/features/analytics/learning_analytics_dashboard.dart';
import 'package:sp/features/profile/enhanced_profile_screen.dart';
import 'package:sp/features/social/social_hub_screen.dart';
import 'package:sp/features/content/learning_hub_screen.dart';
import 'package:sp/shared/widgets/enhanced_bottom_nav.dart';

/// Main Navigation Screen with Bottom Navigation
/// Integrates all major features of the app
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const LearningHubScreen(),
    const SocialHubScreen(),
    const LearningAnalyticsDashboard(userId: 'current_user'), // TODO: Get actual user ID
    const EnhancedProfileScreen(userId: 'current_user'), // TODO: Get actual user ID
  ];

  final List<BottomNavItem> _navItems = [
    BottomNavItem(
      icon: Icons.home_rounded,
      label: 'Home',
    ),
    BottomNavItem(
      icon: Icons.school_rounded,
      label: 'Learn',
    ),
    BottomNavItem(
      icon: Icons.people_rounded,
      label: 'Social',
    ),
    BottomNavItem(
      icon: Icons.analytics_rounded,
      label: 'Analytics',
    ),
    BottomNavItem(
      icon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: EnhancedBottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}