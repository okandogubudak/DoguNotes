import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechToTextService {
  late stt.SpeechToText _speech;
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  Future<bool> initialize() async {
    try {
      _speech = stt.SpeechToText();
      
      // Request microphone permission
      var permissionStatus = await Permission.microphone.request();
      if (permissionStatus != PermissionStatus.granted) {
        return false;
      }

      _isInitialized = await _speech.initialize(
        onError: (error) {
          print('Speech to text error: $error');
          _isListening = false;
        },
        onStatus: (status) {
          print('Speech to text status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      return _isInitialized;
    } catch (e) {
      print('Error initializing speech to text: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'tr_TR',
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isInitialized && !_isListening) {
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: localeId,
        listenMode: stt.ListenMode.search,
        cancelOnError: false,
        partialResults: false,
        listenFor: const Duration(minutes: 60), // Sürekli dinleme için uzun süre
        pauseFor: const Duration(seconds: 5), // Kısa aralıklarla devam et
      );
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      _isListening = false;
      await _speech.stop();
    }
  }

  Future<void> cancelListening() async {
    if (_isListening) {
      _isListening = false;
      await _speech.cancel();
    }
  }

  bool hasError() {
    return !_isInitialized;
  }

  void dispose() {
    _speech.cancel();
  }
} 