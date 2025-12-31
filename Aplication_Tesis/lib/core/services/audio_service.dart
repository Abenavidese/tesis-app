import 'dart:async';
import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart';

class AudioService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _lastRecognizedWords = '';
  bool _speechEnabled = false;
  bool _hasError = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  AudioService();

  bool get isRecording => _isListening;
  String get lastRecognizedWords => _lastRecognizedWords;
  bool get speechEnabled => _speechEnabled;

  /// Inicializa el reconocimiento de voz REAL
  Future<bool> initialize() async {
    try {
      // Si ya está inicializado y disponible, no reinicializar
      if (_speechEnabled && _speech.isAvailable) {
        print('✅ YA ESTÁ INICIALIZADO');
        return true;
      }

      // Cancelar cualquier sesión anterior
      if (_isListening) {
        await _speech.cancel();
        _isListening = false;
        await Future.delayed(const Duration(milliseconds: 200));
      }

      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          print('🎤 Estado: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
        onError: (error) {
          print('❌ Error: $error');
          _hasError = true;
          _isListening = false;
        },
        debugLogging: true, // Para ver más información en logs
      );
      
      print(_speechEnabled ? '✅ RECONOCIMIENTO REAL ACTIVADO' : '❌ No disponible');
      
      // Verificar locales disponibles
      if (_speechEnabled) {
        final locales = await _speech.locales();
        print('📍 Locales disponibles: ${locales.length}');
        final spanish = locales.where((l) => l.localeId.startsWith('es')).toList();
        print('🇪🇸 Español disponible: ${spanish.map((l) => l.localeId).join(", ")}');
      }
      
      _hasError = false;
      _retryCount = 0;
      return _speechEnabled;
    } catch (e) {
      print('❌ Error: $e');
      _speechEnabled = false;
      return false;
    }
  }

  /// Verifica conectividad a Internet
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('✅ Conexión a Internet OK');
        return true;
      }
      print('❌ No hay conexión a Internet');
      return false;
    } catch (e) {
      print('❌ Error verificando Internet: $e');
      return false;
    }
  }

  /// ESCUCHA TU VOZ REAL con lógica de reintentos
  Future<bool> startRecording() async {
    try {
      // Verificar conexión a Internet primero
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        print('❌ Sin Internet: El reconocimiento de voz necesita conexión');
        _hasError = true;
        return false;
      }

      // Verificar que el servicio esté disponible
      if (!_speechEnabled || !_speech.isAvailable) {
        print('⚠️ Servicio no disponible, reinicializando...');
        final initialized = await initialize();
        if (!initialized) {
          print('❌ No se pudo inicializar el servicio');
          return false;
        }
      }

      // Si ya está escuchando, detener primero
      if (_isListening) {
        print('⚠️ Ya está escuchando, deteniendo primero...');
        await _speech.stop();
        await Future.delayed(const Duration(milliseconds: 500));
        _isListening = false;
      }

      _lastRecognizedWords = '';
      _hasError = false;
      _isListening = true;
      
      print('🎤 🔴 ESCUCHANDO TU VOZ REAL... (Intento ${_retryCount + 1})');
      
      // Intentar obtener locales para verificar que funciona
      final locales = await _speech.locales();
      String localeId = 'es_ES';
      
      // Buscar el mejor locale español
      final spanishLocales = locales.where((l) => 
        l.localeId.startsWith('es_') || l.localeId.startsWith('es-')
      ).toList();
      
      if (spanishLocales.isNotEmpty) {
        localeId = spanishLocales.first.localeId;
        print('🇪🇸 Usando locale: $localeId');
      }
      
      await _speech.listen(
        onResult: (result) {
          _lastRecognizedWords = result.recognizedWords;
          if (_lastRecognizedWords.isNotEmpty) {
            print('🗣️ CAPTANDO: $_lastRecognizedWords (final: ${result.finalResult})');
            _hasError = false;
            _retryCount = 0; // Resetear contador si hay éxito
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5), // Aumentar pausa
        partialResults: true,
        localeId: localeId,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
        onDevice: false, // Intentar primero con servicio en línea
        onSoundLevelChange: (level) {
          // Confirmar que está capturando sonido
          if (level > 0.5) {
            print('🔊 Capturando audio: ${level.toStringAsFixed(2)}');
          }
        },
      );
      
      return true;
    } catch (e) {
      print('❌ Error al iniciar escucha: $e');
      _isListening = false;
      _hasError = true;
      
      // Intentar reinicializar si hay error de red
      if (_retryCount < _maxRetries) {
        _retryCount++;
        print('🔄 Reintentando... ($_retryCount/$_maxRetries)');
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Reinicializar el servicio completamente
        _speechEnabled = false;
        return await startRecording();
      }
      
      return false;
    }
  }

  /// CONVIERTE TU VOZ A TEXTO
  Future<String?> stopRecording() async {
    try {
      if (!_isListening) {
        // Si no está escuchando pero hay texto, devolverlo
        if (_lastRecognizedWords.isNotEmpty) {
          print('✅ Texto previo: "$_lastRecognizedWords"');
          return _lastRecognizedWords;
        }
        return null;
      }

      await _speech.stop();
      _isListening = false;
      
      print('🛑 DETENIDO');
      
      // Esperar un momento para que se complete el procesamiento
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (_lastRecognizedWords.isNotEmpty) {
        print('✅ TU VOZ: "$_lastRecognizedWords"');
        _retryCount = 0; // Resetear contador en caso de éxito
        return _lastRecognizedWords;
      } else if (_hasError) {
        // Si hubo error, intentar reiniciar el servicio
        print('⚠️ Hubo error, reinicializando servicio...');
        await initialize();
        return null;
      } else {
        return null;
      }
      
    } catch (e) {
      print('❌ Error: $e');
      _isListening = false;
      return null;
    }
  }

  /// Cancela
  Future<void> cancelRecording() async {
    try {
      if (_isListening) {
        await _speech.cancel();
        _isListening = false;
        _lastRecognizedWords = '';
        _hasError = false;
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
    return text != null && 
           text.isNotEmpty && 
           !text.startsWith('No se') && 
           !text.startsWith('Error') &&
           text.length > 2; // Al menos 3 caracteres
  }

  /// Resetea el contador de reintentos (útil después de un éxito)
  void resetRetryCount() {
    _retryCount = 0;
    _hasError = false;
  }

  /// Obtiene información de diagnóstico
  Future<Map<String, dynamic>> getDiagnostics() async {
    try {
      final isAvailable = _speech.isAvailable;
      final locales = _speechEnabled ? await _speech.locales() : [];
      
      return {
        'speechEnabled': _speechEnabled,
        'isAvailable': isAvailable,
        'isListening': _isListening,
        'hasError': _hasError,
        'retryCount': _retryCount,
        'localesCount': locales.length,
        'spanishLocales': locales
            .where((l) => l.localeId.startsWith('es'))
            .map((l) => l.localeId)
            .toList(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}