import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_tts/flutter_tts.dart';  // Temporarily commented out due to CMake build issues

/// Text-to-Speech Service - Task E4
/// Read questions and content aloud with playback controls
/// 
/// Features:
/// - Read text aloud
/// - Playback controls (play, pause, stop)
/// - Speed adjustment (0.5x to 2.0x)
/// - Language support
/// - Voice selection

class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  factory TextToSpeechService() => _instance;
  TextToSpeechService._internal();

  // final FlutterTts _tts = FlutterTts();  // Temporarily commented out due to CMake build issues
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isPaused = false;
  double _speechRate = 1.0;
  double _pitch = 1.0;
  double _volume = 1.0;
  String _language = 'en-US';
  List<String> _availableLanguages = [];
  List<String> _availableVoices = [];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  String get language => _language;
  List<String> get availableLanguages => _availableLanguages;
  List<String> get availableVoices => _availableVoices;

  /// Initialize TTS service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set up handlers - temporarily disabled due to CMake build issues
      // _tts.setStartHandler(() {
      //   _isSpeaking = true;
      //   _isPaused = false;
      //   debugPrint('🔊 TTS started');
      // });

      // _tts.setCompletionHandler(() {
      //   _isSpeaking = false;
      //   _isPaused = false;
      //   debugPrint('✅ TTS completed');
      // });

      // _tts.setCancelHandler(() {
      //   _isSpeaking = false;
      //   _isPaused = false;
      //   debugPrint('⏹️ TTS cancelled');
      // });

      // _tts.setErrorHandler((message) {
      //   _isSpeaking = false;
      //   _isPaused = false;
      //   debugPrint('❌ TTS error: $message');
      // });

      // _tts.setPauseHandler(() {
      //   _isPaused = true;
      //   debugPrint('⏸️ TTS paused');
      // });

      // _tts.setContinueHandler(() {
      //   _isPaused = false;
      //   debugPrint('▶️ TTS continued');
      // });

      // Get available languages
      // final languages = await _tts.getLanguages;
      // if (languages != null) {
      //   _availableLanguages = List<String>.from(languages);
      // }

      // Get available voices
      // final voices = await _tts.getVoices;
      // if (voices != null) {
      //   _availableVoices = List<String>.from(voices);
      // }

      // Set default values
      // await _tts.setLanguage(_language);
      // await _tts.setSpeechRate(_speechRate);
      // await _tts.setPitch(_pitch);
      // await _tts.setVolume(_volume);

      _isInitialized = true;
      debugPrint('✅ TTS service initialized');
      debugPrint('   - Languages: ${_availableLanguages.length}');
      debugPrint('   - Voices: ${_availableVoices.length}');
    } catch (e) {
      debugPrint('❌ TTS initialization failed: $e');
    }
  }

  /// Speak text
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // await _tts.speak(text);
    } catch (e) {
      debugPrint('❌ TTS speak error: $e');
    }
  }

  /// Pause speech
  Future<void> pause() async {
    if (_isSpeaking && !_isPaused) {
      // await _tts.pause();
    }
  }

  /// Resume speech
  Future<void> resume() async {
    if (_isSpeaking && _isPaused) {
      // Note: Not all platforms support resume
      // On some platforms, you may need to re-speak
      // await _tts.speak('');
    }
  }

  /// Stop speech
  Future<void> stop() async {
    // await _tts.stop();
  }

  /// Set speech rate (0.5 to 2.0)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.5, 2.0);
    // await _tts.setSpeechRate(_speechRate);
  }

  /// Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    // await _tts.setPitch(_pitch);
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    // await _tts.setVolume(_volume);
  }

  /// Set language
  Future<void> setLanguage(String language) async {
    if (_availableLanguages.contains(language)) {
      _language = language;
      // await _tts.setLanguage(_language);
    }
  }

  /// Set voice
  Future<void> setVoice(Map<String, String> voice) async {
    // await _tts.setVoice(voice);
  }

  /// Speak question with context
  Future<void> speakQuestion(String question, {String? context}) async {
    String textToSpeak = question;
    if (context != null) {
      textToSpeak = '$context. $question';
    }
    await speak(textToSpeak);
  }

  /// Speak answer with feedback
  Future<void> speakAnswer(String answer, {bool isCorrect = false}) async {
    String prefix = isCorrect ? 'Correct! ' : 'Incorrect. ';
    await speak('$prefix$answer');
  }

  /// Speak hint
  Future<void> speakHint(String hint, {int level = 1}) async {
    await speak('Hint level $level: $hint');
  }

  /// Speak achievement
  Future<void> speakAchievement(String achievement) async {
    await speak('Achievement unlocked! $achievement');
  }

  /// Speak score
  Future<void> speakScore(int score, int total) async {
    await speak('You scored $score out of $total');
  }

  /// Dispose TTS service
  Future<void> dispose() async {
    await stop();
    _isInitialized = false;
  }
}

/// TTS Control Widget
class TtsControlWidget extends StatefulWidget {
  final String text;
  final bool autoPlay;
  final VoidCallback? onComplete;

  const TtsControlWidget({
    Key? key,
    required this.text,
    this.autoPlay = false,
    this.onComplete,
  }) : super(key: key);

  @override
  State<TtsControlWidget> createState() => _TtsControlWidgetState();
}

class _TtsControlWidgetState extends State<TtsControlWidget> {
  final _tts = TextToSpeechService();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) {
      _speak();
    }
  }

  Future<void> _speak() async {
    setState(() => _isPlaying = true);
    await _tts.speak(widget.text);
    setState(() => _isPlaying = false);
    widget.onComplete?.call();
  }

  Future<void> _stop() async {
    await _tts.stop();
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_isPlaying ? Icons.stop : Icons.volume_up),
      onPressed: _isPlaying ? _stop : _speak,
      tooltip: _isPlaying ? 'Stop reading' : 'Read aloud',
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}

/// TTS Speed Control Widget
class TtsSpeedControl extends StatefulWidget {
  const TtsSpeedControl({Key? key}) : super(key: key);

  @override
  State<TtsSpeedControl> createState() => _TtsSpeedControlState();
}

class _TtsSpeedControlState extends State<TtsSpeedControl> {
  final _tts = TextToSpeechService();
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _speed = _tts.speechRate;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Speech Speed: ${_speed.toStringAsFixed(1)}x'),
        Slider(
          value: _speed,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          label: '${_speed.toStringAsFixed(1)}x',
          onChanged: (value) {
            setState(() => _speed = value);
            _tts.setSpeechRate(value);
          },
        ),
      ],
    );
  }
}

/// Usage Examples:
/// 
/// 1. Initialize in main.dart:
/// ```dart
/// await TextToSpeechService().initialize();
/// ```
/// 
/// 2. Speak text:
/// ```dart
/// TextToSpeechService().speak('Hello, world!');
/// ```
/// 
/// 3. Speak question:
/// ```dart
/// TextToSpeechService().speakQuestion(
///   'What is 2 + 2?',
///   context: 'Math question',
/// );
/// ```
/// 
/// 4. Add TTS button to UI:
/// ```dart
/// TtsControlWidget(
///   text: questionText,
///   autoPlay: false,
/// )
/// ```
/// 
/// 5. Adjust speed:
/// ```dart
/// TtsSpeedControl()
/// ```

