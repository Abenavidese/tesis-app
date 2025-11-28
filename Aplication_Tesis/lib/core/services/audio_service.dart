import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';

class AudioService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _lastRecognizedWords = '';
  bool _speechEnabled = false;

  AudioService();

  bool get isRecording => _isListening;
  String get lastRecognizedWords => _lastRecognizedWords;
  bool get speechEnabled => _speechEnabled;

  /// Inicializa el reconocimiento de voz REAL
  Future<bool> initialize() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) => print('🎤 Estado: $status'),
        onError: (error) => print('❌ Error: $error'),
      );
      
      print(_speechEnabled ? '✅ RECONOCIMIENTO REAL ACTIVADO' : '❌ No disponible');
      return _speechEnabled;
    } catch (e) {
      print('❌ Error: $e');
      return false;
    }
  }

  /// ESCUCHA TU VOZ REAL
  Future<bool> startRecording() async {
    try {
      if (_isListening || !_speechEnabled) return false;

      _lastRecognizedWords = '';
      _isListening = true;
      
      print('🎤 🔴 ESCUCHANDO TU VOZ REAL...');
      
      await _speech.listen(
        onResult: (result) {
          _lastRecognizedWords = result.recognizedWords;
          print('🗣️ CAPTANDO: $_lastRecognizedWords');
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'es_ES',
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      );
      
      return true;
    } catch (e) {
      print('❌ Error: $e');
      _isListening = false;
      return false;
    }
  }

  /// CONVIERTE TU VOZ A TEXTO
  Future<String?> stopRecording() async {
    try {
      if (!_isListening) return _lastRecognizedWords.isNotEmpty ? _lastRecognizedWords : null;

      await _speech.stop();
      _isListening = false;
      
      print('🛑 DETENIDO');
      
      if (_lastRecognizedWords.isNotEmpty) {
        print('✅ TU VOZ: "$_lastRecognizedWords"');
        return _lastRecognizedWords;
      } else {
        return 'No se escuchó nada. Habla más fuerte.';
      }
      
    } catch (e) {
      print('❌ Error: $e');
      _isListening = false;
      return 'Error: ${e.toString()}';
    }
  }

  /// Cancela
  Future<void> cancelRecording() async {
    try {
      if (_isListening) {
        await _speech.cancel();
        _isListening = false;
        _lastRecognizedWords = '';
        print('🗑️ Cancelado');
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  /// Limpia recursos
  Future<void> dispose() async {
    if (_isListening) {
      await cancelRecording();
    }
  }

  /// Verifica si hay texto válido
  bool hasValidText(String? text) {
    return text != null && text.isNotEmpty && !text.startsWith('No se') && !text.startsWith('Error');
  }
}