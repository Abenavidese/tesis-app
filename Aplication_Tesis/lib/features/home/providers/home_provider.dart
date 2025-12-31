import 'dart:io';
import 'package:flutter/material.dart';
import '../models/image_analysis.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/file_service.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/debug/api_debug_screen.dart';

class HomeProvider extends ChangeNotifier {
  final CameraService _cameraService = CameraService();
  final ApiService _apiService = ApiService();
  final FileService _fileService = FileService();
  final AudioService _audioService = AudioService();

  ImageAnalysis? _currentAnalysis;
  bool _isProcessing = false;
  bool _isTakingPhoto = false;
  bool _isLoadingGallery = false;
  bool _isEvaluating = false;
  bool _isRecording = false;
  bool _isProcessingAudio = false;
  String? _recognizedText;
  bool _audioInitialized = false;
  String? _evaluationMessage;
  bool? _isCorrect;

  ImageAnalysis? get currentAnalysis => _currentAnalysis;
  bool get isProcessing => _isProcessing;
  bool get isTakingPhoto => _isTakingPhoto;
  bool get isLoadingGallery => _isLoadingGallery;
  bool get isEvaluating => _isEvaluating;
  bool get isProcessingAudio => _isProcessingAudio;
  bool get hasImage => _currentAnalysis?.imageFile != null;
  bool get isRecording => _isRecording;
  String? get recognizedText => _recognizedText;
  String? get evaluationMessage => _evaluationMessage;
  bool? get isCorrect => _isCorrect;
  
  // Indica si hay algún proceso en curso que debe deshabilitar otros botones
  bool get hasAnyProcessRunning => _isTakingPhoto || _isLoadingGallery || _isEvaluating || _isProcessingAudio;
  
  bool get canEvaluate => 
      _currentAnalysis?.caption != null && 
      _recognizedText != null && 
      _recognizedText!.isNotEmpty &&
      !_recognizedText!.startsWith('No se') &&
      !_recognizedText!.startsWith('Error');

  Future<void> takePicture() async {
    try {
      _isTakingPhoto = true;
      _setProcessing(true);
      clearEvaluation(); // Limpiar evaluación anterior
      
      final File? imageFile = await _cameraService.takePicture();
      if (imageFile == null) {
        _isTakingPhoto = false;
        _setProcessing(false);
        return;
      }

      // Save image locally and cleanup old ones
      final File savedImage = await _fileService.saveImageToLocal(imageFile);
      await _fileService.cleanupOldImages();

      // Set loading state
      _currentAnalysis = ImageAnalysis.loading(savedImage);
      notifyListeners();

      // Generate caption
      await _generateCaption(savedImage);
      
    } catch (e) {
      _handleError('Error al tomar la foto: ${e.toString()}');
    } finally {
      _isTakingPhoto = false;
      _setProcessing(false);
    }
  }

  Future<void> _generateCaption(File imageFile) async {
    try {
      final String caption = await _apiService.predictImageCaption(imageFile);
      
      _currentAnalysis = ImageAnalysis(
        imageFile: imageFile,
        caption: caption,
        timestamp: DateTime.now(),
      );
      
      notifyListeners();
    } catch (e) {
      _currentAnalysis = ImageAnalysis.error(imageFile, e.toString());
      notifyListeners();
    }
  }

  void _handleError(String error) {
    if (_currentAnalysis != null) {
      _currentAnalysis = ImageAnalysis.error(_currentAnalysis!.imageFile, error);
    }
    notifyListeners();
  }

  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  Future<void> retryAnalysis() async {
    if (_currentAnalysis?.imageFile != null) {
      await _generateCaption(_currentAnalysis!.imageFile);
    }
  }

  void clearCurrentAnalysis() {
    _currentAnalysis = null;
    notifyListeners();
  }

  // Button actions - Load image from gallery
  Future<void> onButton2Pressed() async {
    try {
      _isLoadingGallery = true;
      _setProcessing(true);
      
      final File? imageFile = await _cameraService.pickFromGallery();
      if (imageFile == null) {
        _isLoadingGallery = false;
        _setProcessing(false);
        return;
      }

      // Save image locally and cleanup old ones
      final File savedImage = await _fileService.saveImageToLocal(imageFile);
      await _fileService.cleanupOldImages();

      // Set loading state
      _currentAnalysis = ImageAnalysis.loading(savedImage);
      notifyListeners();

      // Generate caption
      await _generateCaption(savedImage);
      
    } catch (e) {
      _handleError('Error al cargar imagen: ${e.toString()}');
    } finally {
      _isLoadingGallery = false;
      _setProcessing(false);
    }
  }

  Future<void> onButton3Pressed(BuildContext context) async {
    // Navegar a pantalla de debug API
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApiDebugScreen(),
      ),
    );
  }

  Future<void> onButton4Pressed() async {
    if (_isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  Future<void> startRecording() async {
    try {
      clearEvaluation(); // Limpiar evaluación anterior
      
      // Inicializar solo si no está inicializado
      if (!_audioInitialized) {
        _isProcessingAudio = true;
        _setProcessing(true);
        
        final initialized = await _audioService.initialize();
        _audioInitialized = initialized;
        
        _isProcessingAudio = false;
        _setProcessing(false);
        
        if (!initialized) {
          debugPrint('❌ No se pudo inicializar el servicio de audio');
          _recognizedText = 'Error: No se pudo inicializar el micrófono. Verifica permisos y conexión a internet.';
          notifyListeners();
          return;
        }
      }
      
      _isRecording = true;
      _recognizedText = null;
      notifyListeners();
      
      final success = await _audioService.startRecording();
      if (!success) {
        _isRecording = false;
        
        // Obtener diagnóstico para determinar causa del fallo
        final diagnostics = await _audioService.getDiagnostics();
        final hasError = diagnostics['hasError'] == true;
        
        if (hasError) {
          _recognizedText = 
            '❌ ERROR: Sin conexión a Internet\n\n'
            'El reconocimiento de voz de Google NECESITA:\n\n'
            '📡 Conexión a Internet activa (WiFi o datos)\n'
            '🔧 Google Play Services funcionando\n'
            '🎤 Permisos de micrófono concedidos\n\n'
            '💡 Soluciones:\n'
            '1. Activa WiFi o datos móviles\n'
            '2. Verifica que puedas abrir una página web\n'
            '3. Reinicia la app y vuelve a intentar';
        } else {
          _recognizedText = 'No se pudo iniciar la grabación. Verifica permisos de micrófono.';
        }
        
        notifyListeners();
        debugPrint('❌ No se pudo iniciar la grabación');
      }
    } catch (e) {
      _isRecording = false;
      _recognizedText = 'Error: ${e.toString()}';
      notifyListeners();
      debugPrint('❌ Error iniciando grabación: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      _isProcessingAudio = true;
      _setProcessing(true);
      
      final recognizedText = await _audioService.stopRecording();
      _isRecording = false;
      
      if (recognizedText != null && _audioService.hasValidText(recognizedText)) {
        _recognizedText = recognizedText;
        _audioService.resetRetryCount(); // Resetear contador en caso de éxito
        debugPrint('🎤 Texto reconocido directamente: $recognizedText');
      } else {
        if (recognizedText == null) {
          // Obtener diagnóstico para ayudar a depurar
          final diagnostics = await _audioService.getDiagnostics();
          debugPrint('📊 Diagnóstico: $diagnostics');
          
          _recognizedText = 
            'Error: No se capturó audio.\n\n'
            '💡 Soluciones:\n'
            '1. Verifica que tengas CONEXIÓN A INTERNET (WiFi o datos móviles)\n'
            '2. Verifica permisos de micrófono en Configuración\n'
            '3. Habla más cerca del micrófono\n'
            '4. Mantén presionado el botón mientras hablas\n'
            '5. Reinicia la app si persiste';
        } else {
          _recognizedText = recognizedText;
        }
        debugPrint('❌ No se reconoció texto válido: $recognizedText');
      }
      
      notifyListeners();
    } catch (e) {
      _isRecording = false;
      _recognizedText = 'Error procesando voz: ${e.toString()}';
      notifyListeners();
      debugPrint('❌ Error deteniendo grabación: $e');
    } finally {
      _isProcessingAudio = false;
      _setProcessing(false);
    }
  }

  Future<void> evaluateAnswer() async {
    if (!canEvaluate) {
      debugPrint('❌ No se puede evaluar: falta caption o texto reconocido');
      return;
    }

    try {
      _isEvaluating = true;
      _setProcessing(true);
      _evaluationMessage = null;
      _isCorrect = null;
      
      final textoModelo = _currentAnalysis!.caption!;
      final textoNino = _recognizedText!;
      
      debugPrint('🔍 Evaluando...');
      debugPrint('📝 Modelo: $textoModelo');
      debugPrint('🎤 Niño: $textoNino');
      
      final result = await _apiService.evaluateResponse(
        textoModelo: textoModelo,
        textoNino: textoNino,
        umbral: 0.6,
      );
      
      _evaluationMessage = result.mensaje;
      _isCorrect = result.esCorrecta;
      
      debugPrint('✅ Resultado: ${result.mensaje}');
      debugPrint('📊 Es correcta: ${result.esCorrecta}');
      debugPrint('📈 Similitud: ${result.detalles['similitud']}');
      
      notifyListeners();
    } catch (e) {
      _evaluationMessage = 'Error al evaluar: ${e.toString()}';
      _isCorrect = null;
      notifyListeners();
      debugPrint('❌ Error evaluando: $e');
    } finally {
      _isEvaluating = false;
      _setProcessing(false);
    }
  }

  void clearEvaluation() {
    _evaluationMessage = null;
    _isCorrect = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}