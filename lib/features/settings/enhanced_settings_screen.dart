import 'package:flutter/material.dart';

/// Enhanced Settings Screen - Task B8
/// Modern settings with search, categories, and quick actions
class EnhancedSettingsScreen extends StatefulWidget {
  const EnhancedSettingsScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedSettingsScreen> createState() => _EnhancedSettingsScreenState();
}

class _EnhancedSettingsScreenState extends State<EnhancedSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoPlayVideos = true;
  double _textSize = 1.0;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // Profile section
          _buildProfileSection(),
          
          const Divider(height: 1),
          
          // Settings categories
          _buildCategory(
            title: 'Account',
            icon: Icons.person,
            children: [
              _buildListTile(
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                icon: Icons.edit,
                onTap: () {},
              ),
              _buildListTile(
                title: 'Change Password',
                subtitle: 'Update your password',
                icon: Icons.lock,
                onTap: () {},
              ),
              _buildListTile(
                title: 'Privacy',
                subtitle: 'Manage your privacy settings',
                icon: Icons.privacy_tip,
                onTap: () {},
              ),
            ],
          ),
          
          _buildCategory(
            title: 'Preferences',
            icon: Icons.tune,
            children: [
              _buildSwitchTile(
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                icon: Icons.dark_mode,
                value: _darkModeEnabled,
                onChanged: (value) {
                  setState(() => _darkModeEnabled = value);
                },
              ),
              _buildListTile(
                title: 'Language',
                subtitle: _language,
                icon: Icons.language,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showLanguageDialog();
                },
              ),
              _buildSliderTile(
                title: 'Text Size',
                subtitle: 'Adjust reading comfort',
                icon: Icons.text_fields,
                value: _textSize,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                onChanged: (value) {
                  setState(() => _textSize = value);
                },
              ),
            ],
          ),
          
          _buildCategory(
            title: 'Notifications',
            icon: Icons.notifications,
            children: [
              _buildSwitchTile(
                title: 'Push Notifications',
                subtitle: 'Receive notifications',
                icon: Icons.notifications_active,
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
              _buildListTile(
                title: 'Notification Preferences',
                subtitle: 'Customize what you receive',
                icon: Icons.tune,
                onTap: () {},
              ),
            ],
          ),
          
          _buildCategory(
            title: 'Learning',
            icon: Icons.school,
            children: [
              _buildListTile(
                title: 'Daily Goal',
                subtitle: 'Set your daily XP target',
                icon: Icons.flag,
                onTap: () {},
              ),
              _buildSwitchTile(
                title: 'Auto-play Videos',
                subtitle: 'Automatically play lesson videos',
                icon: Icons.play_circle,
                value: _autoPlayVideos,
                onChanged: (value) {
                  setState(() => _autoPlayVideos = value);
                },
              ),
              _buildListTile(
                title: 'Learning Reminders',
                subtitle: 'Set study reminders',
                icon: Icons.alarm,
                onTap: () {},
              ),
            ],
          ),
          
          _buildCategory(
            title: 'Audio & Sound',
            icon: Icons.volume_up,
            children: [
              _buildSwitchTile(
                title: 'Sound Effects',
                subtitle: 'Play sounds for actions',
                icon: Icons.music_note,
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() => _soundEnabled = value);
                },
              ),
            ],
          ),
          
          _buildCategory(
            title: 'Data & Storage',
            icon: Icons.storage,
            children: [
              _buildListTile(
                title: 'Download Quality',
                subtitle: 'High quality',
                icon: Icons.high_quality,
                onTap: () {},
              ),
              _buildListTile(
                title: 'Clear Cache',
                subtitle: '125 MB',
                icon: Icons.delete_outline,
                onTap: () {
                  _showClearCacheDialog();
                },
              ),
            ],
          ),
          
          _buildCategory(
            title: 'About',
            icon: Icons.info,
            children: [
              _buildListTile(
                title: 'Help & Support',
                subtitle: 'Get help with the app',
                icon: Icons.help,
                onTap: () {},
              ),
              _buildListTile(
                title: 'Terms of Service',
                subtitle: 'Read our terms',
                icon: Icons.description,
                onTap: () {},
              ),
              _buildListTile(
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                icon: Icons.policy,
                onTap: () {},
              ),
              _buildListTile(
                title: 'App Version',
                subtitle: '1.0.0 (Build 100)',
                icon: Icons.info_outline,
                onTap: null,
              ),
            ],
          ),
          
          // Logout button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                _showLogoutDialog();
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'John Doe',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'john.doe@example.com',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCategory({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildSliderTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null) Text(subtitle),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Spanish', 'French', 'German'].map((lang) {
            return RadioListTile<String>(
              title: Text(lang),
              value: lang,
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will free up 125 MB of storage. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Perform logout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

