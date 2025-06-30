import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  void Function()? _onComplete;
  Function(String)? _onError;

  // Initialize TTS
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage('tr-TR'); // Turkish
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      // Set up completion and error handlers
      _flutterTts.setCompletionHandler(() {
        _onComplete?.call();
      });

      _flutterTts.setErrorHandler((message) {
        _onError?.call(message);
      });
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }

  // Speak text
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (text.isNotEmpty) {
        print('TTS: Speaking text: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
        await _flutterTts.speak(text);
      } else {
        print('TTS: No text to speak');
      }
    } catch (e) {
      print('Error speaking text: $e');
      _onError?.call(e.toString());
    }
  }

  // Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('Error stopping TTS: $e');
    }
  }

  // Pause speaking
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      print('Error pausing TTS: $e');
    }
  }

  // Set language
  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
    } catch (e) {
      print('Error setting language: $e');
    }
  }

  // Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      print('Error setting speech rate: $e');
    }
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  // Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
    } catch (e) {
      print('Error setting pitch: $e');
    }
  }

  // Get available languages
  Future<List<dynamic>> getLanguages() async {
    try {
      return await _flutterTts.getLanguages;
    } catch (e) {
      print('Error getting languages: $e');
      return [];
    }
  }

  // Get available voices
  Future<List<dynamic>> getVoices() async {
    try {
      return await _flutterTts.getVoices;
    } catch (e) {
      print('Error getting voices: $e');
      return [];
    }
  }

  // Check if TTS is speaking
  Future<bool> isSpeaking() async {
    try {
      // FlutterTts doesn't have a direct isSpeaking method
      // We can track this state manually if needed
      return false;
    } catch (e) {
      print('Error checking speaking status: $e');
      return false;
    }
  }

  // Set completion handler
  void setCompletionHandler(void Function() onComplete) {
    _onComplete = onComplete;
  }

  // Set error handler
  void setErrorHandler(Function(String) onError) {
    _onError = onError;
  }

  // Dispose TTS
  void dispose() {
    _flutterTts.stop();
  }
} 