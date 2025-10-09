import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp/shared/widgets/interactive_button.dart';
import 'package:sp/features/question_types/question_type_demo_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _premium = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _premium = prefs.getBool('premium_v1') ?? false;
    setState(() {});
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('premium_v1', _premium);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            value: _premium,
            onChanged: (v) => setState(() => _premium = v),
            title: const Text('Premium (unlimited lives, no ads)'),
            subtitle: const Text('For real purchases, connect a store later.'),
          ),
          const SizedBox(height: 20),
          InteractiveButton(
            text: 'Save Settings',
            onPressed: _save,
            style: InteractiveButtonStyle.primary,
            enableSoundEffects: true,
            enableHapticFeedback: true,
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          Text('Help & Tutorials', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('Question Types Guide'),
            subtitle: const Text('Learn about all 7 question types'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuestionTypeDemoScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Tip: To enable real sign-in and cloud sync, open the Firebase or Supabase panel in Dreamflow and complete setup. We\'ll wire the login screen to it.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
