import 'package:flutter/material.dart';
import 'core/services/unlock_all_levels_service.dart';

/// Debug screen for unlocking all levels during development and testing
class DebugUnlockScreen extends StatefulWidget {
  const DebugUnlockScreen({Key? key}) : super(key: key);

  @override
  State<DebugUnlockScreen> createState() => _DebugUnlockScreenState();
}

class _DebugUnlockScreenState extends State<DebugUnlockScreen> {
  final UnlockAllLevelsService _unlockService = UnlockAllLevelsService();
  bool _isUnlocking = false;
  Map<String, dynamic>? _unlockStatus;
  String? _message;

  @override
  void initState() {
    super.initState();
    _checkCurrentStatus();
  }

  Future<void> _checkCurrentStatus() async {
    try {
      final status = await _unlockService.getUnlockStatus();
      setState(() {
        _unlockStatus = status;
      });
    } catch (e) {
      setState(() {
        _message = 'Error checking status: $e';
      });
    }
  }

  Future<void> _unlockAllLevels() async {
    setState(() {
      _isUnlocking = true;
      _message = null;
    });

    try {
      await _unlockService.unlockAllLevels();
      setState(() {
        _message = '✅ Successfully unlocked all levels!';
      });
      await _checkCurrentStatus();
    } catch (e) {
      setState(() {
        _message = '❌ Error unlocking levels: $e';
      });
    } finally {
      setState(() {
        _isUnlocking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug: Unlock All Levels'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Unlock Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_unlockStatus != null) ...[
                      _buildStatusRow('Level Unlock Service', '${_unlockStatus!['levelUnlockService_count']} levels'),
                      _buildStatusRow('Unified Level Service', '${_unlockStatus!['unifiedLevelService_count']} levels'),
                      _buildStatusRow('Total XP', '${_unlockStatus!['totalXP']}'),
                      _buildStatusRow('All Levels Unlocked', _unlockStatus!['allLevelsUnlocked'] ? '✅ Yes' : '❌ No'),
                    ] else
                      const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUnlocking ? null : _unlockAllLevels,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isUnlocking
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Unlocking All Levels...'),
                      ],
                    )
                  : const Text(
                      'UNLOCK ALL LEVELS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkCurrentStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Refresh Status'),
            ),
            const SizedBox(height: 20),
            if (_message != null)
              Card(
                color: _message!.startsWith('✅') ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.startsWith('✅') ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            const Spacer(),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Debug Tool',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This tool unlocks all levels by modifying local storage. '
                      'Use only for development and testing purposes.',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}