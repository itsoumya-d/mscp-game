import 'package:flutter/material.dart';
import 'package:sp/core/services/accessibility/accessibility_service.dart';
import 'package:sp/core/services/accessibility/text_to_speech_service.dart';

/// Accessibility Settings Screen - Category E Complete
/// Comprehensive accessibility controls for all users
class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({Key? key}) : super(key: key);

  @override
  State<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState
    extends State<AccessibilitySettingsScreen> {
  final _accessibilityService = AccessibilityService();
  final _ttsService = TextToSpeechService();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _accessibilityService.initialize();
    await _ttsService.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _accessibilityService.resetAll();
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Accessibility settings reset'),
                  ),
                );
              }
            },
            tooltip: 'Reset all settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Screen Reader Section
          _buildSectionHeader(
            'Screen Reader',
            Icons.accessibility_new,
            'Optimize for TalkBack and VoiceOver',
          ),
          _buildScreenReaderStatus(),
          const Divider(height: 32),

          // Visual Section
          _buildSectionHeader(
            'Visual',
            Icons.visibility,
            'Adjust colors and contrast',
          ),
          _buildHighContrastToggle(),
          _buildColorblindModeSelector(),
          const Divider(height: 32),

          // Text Section
          _buildSectionHeader(
            'Text',
            Icons.text_fields,
            'Adjust text size and readability',
          ),
          _buildTextSizeSlider(),
          _buildLineSpacingSlider(),
          _buildDyslexiaFontToggle(),
          const Divider(height: 32),

          // Audio Section
          _buildSectionHeader(
            'Audio',
            Icons.volume_up,
            'Text-to-speech settings',
          ),
          _buildTtsToggle(),
          _buildTtsSpeedSlider(),
          _buildTtsTestButton(),
          const Divider(height: 32),

          // Motion Section
          _buildSectionHeader(
            'Motion',
            Icons.animation,
            'Reduce animations',
          ),
          _buildReduceMotionToggle(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenReaderStatus() {
    final isEnabled = _accessibilityService.isScreenReaderEnabled;
    return Card(
      child: ListTile(
        leading: Icon(
          isEnabled ? Icons.check_circle : Icons.info_outline,
          color: isEnabled ? Colors.green : Colors.grey,
        ),
        title: Text(isEnabled
            ? 'Screen Reader Active'
            : 'Screen Reader Not Detected'),
        subtitle: Text(isEnabled
            ? 'App is optimized for screen readers'
            : 'Enable TalkBack (Android) or VoiceOver (iOS) in system settings'),
      ),
    );
  }

  Widget _buildHighContrastToggle() {
    return SwitchListTile(
      title: const Text('High Contrast Mode'),
      subtitle: const Text('Increase contrast for better visibility'),
      value: _accessibilityService.highContrastEnabled,
      onChanged: (value) async {
        await _accessibilityService.setHighContrast(value);
        setState(() {});
      },
    );
  }

  Widget _buildColorblindModeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Colorblind Mode',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _accessibilityService.colorblindMode.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SegmentedButton<ColorblindMode>(
              segments: ColorblindMode.values.map((mode) {
                return ButtonSegment(
                  value: mode,
                  label: Text(mode.displayName.split(' ')[0]),
                );
              }).toList(),
              selected: {_accessibilityService.colorblindMode},
              onSelectionChanged: (Set<ColorblindMode> newSelection) async {
                await _accessibilityService
                    .setColorblindMode(newSelection.first);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSizeSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text Size: ${(_accessibilityService.textSizeMultiplier * 100).toInt()}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _accessibilityService.textSizeMultiplier,
              min: 0.8,
              max: 2.0,
              divisions: 12,
              label:
                  '${(_accessibilityService.textSizeMultiplier * 100).toInt()}%',
              onChanged: (value) async {
                await _accessibilityService.setTextSize(value);
                setState(() {});
              },
            ),
            Text(
              'Preview: This is how text will look',
              style: TextStyle(
                fontSize: 16 * _accessibilityService.textSizeMultiplier,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineSpacingSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Line Spacing: ${(_accessibilityService.lineSpacingMultiplier * 100).toInt()}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _accessibilityService.lineSpacingMultiplier,
              min: 1.0,
              max: 2.0,
              divisions: 10,
              label:
                  '${(_accessibilityService.lineSpacingMultiplier * 100).toInt()}%',
              onChanged: (value) async {
                await _accessibilityService.setLineSpacing(value);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDyslexiaFontToggle() {
    return SwitchListTile(
      title: const Text('Dyslexia-Friendly Font'),
      subtitle: const Text('Use OpenDyslexic font for easier reading'),
      value: _accessibilityService.dyslexiaFontEnabled,
      onChanged: (value) async {
        await _accessibilityService.setDyslexiaFont(value);
        setState(() {});
      },
    );
  }

  Widget _buildTtsToggle() {
    return SwitchListTile(
      title: const Text('Text-to-Speech'),
      subtitle: const Text('Read questions and content aloud'),
      value: _accessibilityService.ttsEnabled,
      onChanged: (value) async {
        await _accessibilityService.setTtsEnabled(value);
        setState(() {});
      },
    );
  }

  Widget _buildTtsSpeedSlider() {
    if (!_accessibilityService.ttsEnabled) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Speech Speed: ${_accessibilityService.ttsSpeed.toStringAsFixed(1)}x',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _accessibilityService.ttsSpeed,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: '${_accessibilityService.ttsSpeed.toStringAsFixed(1)}x',
              onChanged: (value) async {
                await _accessibilityService.setTtsSpeed(value);
                await _ttsService.setSpeechRate(value);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTtsTestButton() {
    if (!_accessibilityService.ttsEnabled) {
      return const SizedBox.shrink();
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.play_arrow),
        title: const Text('Test Text-to-Speech'),
        subtitle: const Text('Tap to hear a sample'),
        onTap: () {
          _ttsService.speak(
            'This is a test of the text to speech system. You can adjust the speed using the slider above.',
          );
        },
      ),
    );
  }

  Widget _buildReduceMotionToggle() {
    return SwitchListTile(
      title: const Text('Reduce Motion'),
      subtitle: const Text('Minimize animations and transitions'),
      value: _accessibilityService.reduceMotionEnabled,
      onChanged: (value) async {
        await _accessibilityService.setReduceMotion(value);
        setState(() {});
      },
    );
  }
}

