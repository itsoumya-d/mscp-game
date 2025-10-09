import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive sound effects manager for educational app
class SoundManagerService {
  static SoundManagerService? _instance;
  static SoundManagerService get instance => _instance ??= SoundManagerService._();
  
  SoundManagerService._();
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _soundVolume = 0.7;
  double _musicVolume = 0.3;
  
  /// Initialize sound manager and load preferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _musicEnabled = prefs.getBool('music_enabled') ?? true;
      _soundVolume = prefs.getDouble('sound_volume') ?? 0.7;
      _musicVolume = prefs.getDouble('music_volume') ?? 0.3;
      
      await _audioPlayer.setVolume(_soundVolume);
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing sound manager: $e');
      }
    }
  }
  
  /// Play button click sound
  Future<void> playButtonClick() async {
    if (!_soundEnabled) return;
    await _playSound('sounds/button_click.mp3', volume: 0.5);
  }
  
  /// Play correct answer sound
  Future<void> playCorrectAnswer() async {
    if (!_soundEnabled) return;
    await _playSound('sounds/correct_answer.mp3', volume: 0.8);
  }
  
  /// Play incorrect answer sound (gentle, non-punitive)
  Future<void> playIncorrectAnswer() async {
    if (!_soundEnabled) return;
    await _playSound('sounds/incorrect_answer.mp3', volume: 0.6);
  }
  
  /// Play level completion sound
  Future<void> playLevelComplete() async {
    if (!_soundEnabled) return;
    await _playSound('sounds/level_complete.mp3', volume: 0.9);
  }
  
  /// Play achievement unlock sound
  Future<void> playAchievementUnlock() async {
    if (!_soundEnabled) return;
    await _playSound('sounds/achievement_unlock.mp3', volume: 1.0);
  }
  
  /// Play coin/gem collection sound
  Future<void> playCoinCollect() async {
    if (!_soundEnabled) return;
    await _playSound('sounds/coin_collect.mp3', volume: 0.7);
  }
  
  /// Play streak milestone sound
  Future<void> playStreakMilestone() async {
    if (!_soundEnabled) return;
    await _playSound('sounds/streak_milestone.mp3', volume: 0.8);
  }
  
  /// Play level up fanfare
  Future<void> playLevelUp() async {
    if (!_soundEnabled) return;
    await _playSound('sounds/level_up.mp3', volume: 1.0);
  }
  
  /// Play page transition sound
  Future<void> playPageTransition() async {
    if (!_soundEnabled) return;
    await _playSound('sounds/page_transition.mp3', volume: 0.4);
  }
  
  /// Play notification sound
  Future<void> playNotification() async {
    if (!_soundEnabled) return;
    await _playSound('sounds/notification.mp3', volume: 0.6);
  }
  
  /// Play typing sound for input fields
  Future<void> playTyping() async {
    if (!_soundEnabled) return;
    await _playSound('sounds/typing.mp3', volume: 0.3);
  }
  
  /// Play drag start sound
  Future<void> playDragStart() async {
    if (!_soundEnabled) return;
    await _playSound('sounds/drag_start.mp3', volume: 0.5);
  }
  
  /// Play drag drop sound
  Future<void> playDragDrop() async {
    if (!_soundEnabled) return;
    await _playSound('sounds/drag_drop.mp3', volume: 0.6);
  }
  
  /// Play background music for lessons
  Future<void> playBackgroundMusic({String? track}) async {
    if (!_musicEnabled) return;
    final musicTrack = track ?? 'music/focus_ambient.mp3';
    await _playSound(musicTrack, volume: _musicVolume, loop: true);
  }
  
  /// Stop background music
  Future<void> stopBackgroundMusic() async {
    await _audioPlayer.stop();
  }
  
  /// Play subject-specific ambient sound
  Future<void> playSubjectAmbient(String subject) async {
    if (!_musicEnabled) return;
    
    String ambientTrack;
    switch (subject.toLowerCase()) {
      case 'math':
        ambientTrack = 'music/math_ambient.mp3';
        break;
      case 'physics':
        ambientTrack = 'music/physics_ambient.mp3';
        break;
      case 'chemistry':
        ambientTrack = 'music/chemistry_ambient.mp3';
        break;
      case 'biology':
        ambientTrack = 'music/biology_ambient.mp3';
        break;
      default:
        ambientTrack = 'music/general_ambient.mp3';
    }
    
    await _playSound(ambientTrack, volume: _musicVolume * 0.5, loop: true);
  }
  
  /// Internal method to play sound
  Future<void> _playSound(String assetPath, {double? volume, bool loop = false}) async {
    try {
      // Check if asset exists, if not use fallback
      final soundExists = await _checkSoundAssetExists(assetPath);
      
      if (soundExists) {
        await _audioPlayer.play(AssetSource(assetPath));
        if (volume != null) {
          await _audioPlayer.setVolume(volume);
        }
        if (loop) {
          await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        }
      } else {
        // Use system sound as fallback
        await _playSystemSound(assetPath);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing sound $assetPath: $e');
      }
      // Fallback to system sound
      await _playSystemSound(assetPath);
    }
  }
  
  /// Check if sound asset exists
  Future<bool> _checkSoundAssetExists(String assetPath) async {
    // In a real implementation, this would check if the asset exists
    // For now, return false to use system sounds as fallback
    return false;
  }
  
  /// Play system sound as fallback
  Future<void> _playSystemSound(String originalPath) async {
    // Generate simple tones based on sound type
    if (originalPath.contains('correct')) {
      // High pleasant tone for correct answers
      await _generateTone(frequency: 800, duration: 200);
    } else if (originalPath.contains('incorrect')) {
      // Low gentle tone for incorrect answers
      await _generateTone(frequency: 300, duration: 150);
    } else if (originalPath.contains('button')) {
      // Quick click sound
      await _generateTone(frequency: 600, duration: 50);
    } else if (originalPath.contains('achievement') || originalPath.contains('level_up')) {
      // Celebration sequence
      await _generateCelebrationSequence();
    } else if (originalPath.contains('coin')) {
      // Coin collection sound
      await _generateTone(frequency: 1000, duration: 100);
    }
  }
  
  /// Generate simple tone (placeholder for actual implementation)
  Future<void> _generateTone({required double frequency, required int duration}) async {
    // This is a placeholder - in a real implementation, you would generate actual tones
    // For now, we'll just add a small delay to simulate sound playback
    await Future.delayed(Duration(milliseconds: duration));
  }
  
  /// Generate celebration sound sequence
  Future<void> _generateCelebrationSequence() async {
    await _generateTone(frequency: 600, duration: 100);
    await Future.delayed(const Duration(milliseconds: 50));
    await _generateTone(frequency: 800, duration: 100);
    await Future.delayed(const Duration(milliseconds: 50));
    await _generateTone(frequency: 1000, duration: 150);
  }
  
  /// Enable/disable sound effects
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
  }
  
  /// Enable/disable background music
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    if (!enabled) {
      await stopBackgroundMusic();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', enabled);
  }
  
  /// Set sound effects volume
  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_volume', _soundVolume);
  }
  
  /// Set background music volume
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_musicVolume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume', _musicVolume);
  }
  
  /// Get current sound settings
  Map<String, dynamic> getSoundSettings() {
    return {
      'soundEnabled': _soundEnabled,
      'musicEnabled': _musicEnabled,
      'soundVolume': _soundVolume,
      'musicVolume': _musicVolume,
    };
  }
  
  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}

/// Extension for easy sound integration in widgets
extension SoundEffects on SoundManagerService {
  /// Play sound with haptic feedback
  Future<void> playWithHaptic(Future<void> Function() soundFunction) async {
    await soundFunction();
    // Add haptic feedback here if needed
  }
}

/// Sound effect types for easy reference
enum SoundEffect {
  buttonClick,
  correctAnswer,
  incorrectAnswer,
  levelComplete,
  achievementUnlock,
  coinCollect,
  streakMilestone,
  levelUp,
  pageTransition,
  notification,
  typing,
  dragStart,
  dragDrop,
}

/// Extension to play sound effects by type
extension SoundEffectPlayer on SoundManagerService {
  Future<void> play(SoundEffect effect) async {
    switch (effect) {
      case SoundEffect.buttonClick:
        await playButtonClick();
        break;
      case SoundEffect.correctAnswer:
        await playCorrectAnswer();
        break;
      case SoundEffect.incorrectAnswer:
        await playIncorrectAnswer();
        break;
      case SoundEffect.levelComplete:
        await playLevelComplete();
        break;
      case SoundEffect.achievementUnlock:
        await playAchievementUnlock();
        break;
      case SoundEffect.coinCollect:
        await playCoinCollect();
        break;
      case SoundEffect.streakMilestone:
        await playStreakMilestone();
        break;
      case SoundEffect.levelUp:
        await playLevelUp();
        break;
      case SoundEffect.pageTransition:
        await playPageTransition();
        break;
      case SoundEffect.notification:
        await playNotification();
        break;
      case SoundEffect.typing:
        await playTyping();
        break;
      case SoundEffect.dragStart:
        await playDragStart();
        break;
      case SoundEffect.dragDrop:
        await playDragDrop();
        break;
    }
  }
}
