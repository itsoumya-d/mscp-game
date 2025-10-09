import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp/shared/widgets/interactive_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _handle() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Local mode: skip auth, go to home
      if (!mounted) return;
      // After "sign-in", if onboarding not complete, go there first
      final prefs = await SharedPreferences.getInstance();
      final onboarded = prefs.getBool('onboarding_complete_v1') ?? false;
      if (!mounted) return;
      if (!onboarded) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      } else {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in to continue',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Use a social account to save your progress across devices',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_error != null) ...[
                Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                const SizedBox(height: 12),
              ],
              _SocialButton(
                color: theme.colorScheme.primary,
                textColor: theme.colorScheme.onPrimary,
                label: 'Continue Locally',
                icon: Icons.arrow_forward,
                onTap: _busy ? null : () => _handle(),
              ),
              const SizedBox(height: 24),
              if (_busy) const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              InteractiveButton(
                text: 'Skip for now',
                onPressed: _busy
                    ? null
                    : () {
                        Navigator.of(context).pushReplacementNamed('/');
                      },
                style: InteractiveButtonStyle.ghost,
                enableSoundEffects: true,
                enableHapticFeedback: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Color color;
  final Color textColor;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.color,
    required this.textColor,
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
