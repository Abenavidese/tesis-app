import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../home/providers/home_provider.dart';
import '../../../home/widgets/image_preview.dart';
import '../../../home/widgets/result_display.dart';
import '../../../home/widgets/voice_result_display.dart';

class Activity1GameScreen extends StatefulWidget {
  const Activity1GameScreen({super.key});

  @override
  State<Activity1GameScreen> createState() => _Activity1GameScreenState();
}

class _Activity1GameScreenState extends State<Activity1GameScreen> {
  late final HomeProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = HomeProvider();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        backgroundColor: const Color(0xFF7CB342),
        child: const Icon(Icons.home, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Decoraciones de fondo
            ..._buildBackgroundDecorations(),
            
            // Contenido principal
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  
                  // Header con botón de salida
                  _buildHeader(),
                  const SizedBox(height: 16),

                  // Image section
                  AnimatedBuilder(
                    animation: _provider,
                    builder: (context, child) {
                      if (_provider.hasImage) {
                        return _buildImageCard();
                      } else {
                        return _buildEmptyStateCard();
                      }
                    },
                  ),
                  
                  // Result section
                  AnimatedBuilder(
                    animation: _provider,
                    builder: (context, child) {
                      return ResultDisplay(
                        analysis: _provider.currentAnalysis,
                        onRetry: _provider.retryAnalysis,
                      );
                    },
                  ),

                  // Voice recognition result section
                  AnimatedBuilder(
                    animation: _provider,
                    builder: (context, child) {
                      return VoiceResultDisplay(
                        recognizedText: _provider.recognizedText,
                        isRecording: _provider.isRecording,
                        isProcessing: _provider.isProcessingAudio && _provider.isRecording == false,
                      );
                    },
                  ),

                  // Evaluate button
                  AnimatedBuilder(
                    animation: _provider,
                    builder: (context, child) {
                      if (!_provider.canEvaluate) {
                        return const SizedBox.shrink();
                      }
                      
                      return _buildEvaluateButton();
                    },
                  ),

                  // Evaluation result
                  AnimatedBuilder(
                    animation: _provider,
                    builder: (context, child) {
                      if (_provider.evaluationMessage == null) {
                        return const SizedBox.shrink();
                      }
                      
                      return _buildEvaluationResult();
                    },
                  ),
                  const SizedBox(height: 32),

                  // Action buttons (solo cámara y voz)
                  AnimatedBuilder(
                    animation: _provider,
                    builder: (context, child) {
                      return _buildActionButtons();
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundDecorations() {
    return [
      Positioned(
        top: -50,
        right: -50,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF7CB342).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: 100,
        left: -70,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB74D).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ];
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7CB342), Color(0xFF558B2F)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7CB342).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/imagenes/owl-take-photo.png',
                width: 40,
                height: 40,
              ),
              const SizedBox(width: 12),
              const Text(
                'ACTIVIDAD 1',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ImagePreview(
          imageFile: _provider.currentAnalysis!.imageFile!,
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '¡Toma una foto para comenzar!',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluateButton() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF42A5F5).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _provider.isProcessing ? null : _provider.evaluateAnswer,
          borderRadius: BorderRadius.circular(20),
          child: Opacity(
            opacity: _provider.isProcessing ? 0.5 : 1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_provider.isProcessing)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  else
                    const Icon(Icons.check_circle, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    '✨ EVALUAR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEvaluationResult() {
    final isCorrect = _provider.isCorrect ?? false;
    final message = _provider.evaluationMessage ?? '';
    
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCorrect
              ? [const Color(0xFF66BB6A), const Color(0xFF43A047)]
              : [const Color(0xFFEF5350), const Color(0xFFE53935)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isCorrect ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isCorrect ? '🎉' : '💪',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _provider.clearEvaluation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: isCorrect ? const Color(0xFF43A047) : const Color(0xFFE53935),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '🔄 INTENTAR OTRA VEZ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botón de tomar foto
        _buildMainCameraButton(),
        const SizedBox(height: 16),
        
        // Botones secundarios en fila
        Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(
                label: 'GALERÍA',
                assetImage: 'assets/imagenes/owl-load-file.png',
                gradientColors: [const Color(0xFF42A5F5), const Color(0xFF1976D2)],
                onPressed: _provider.onButton2Pressed,
                isCurrentlyLoading: _provider.isLoadingGallery,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildVoiceButton(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required String assetImage,
    required List<Color> gradientColors,
    required VoidCallback onPressed,
    bool isCurrentlyLoading = false,
  }) {
    final isDisabled = _provider.hasAnyProcessRunning && !isCurrentlyLoading;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCurrentlyLoading)
                    const SizedBox(
                      width: 25,
                      height: 25,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    Image.asset(
                      assetImage,
                      width: 30,
                      height: 30,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCameraButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7CB342).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _provider.hasAnyProcessRunning ? null : _provider.takePicture,
          borderRadius: BorderRadius.circular(24),
          child: Opacity(
            opacity: _provider.hasAnyProcessRunning && !_provider.isTakingPhoto ? 0.5 : 1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7CB342), Color(0xFF558B2F)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_provider.isTakingPhoto)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  else
                    Image.asset(
                      'assets/imagenes/owl-take-photo.png',
                      width: 45,
                      height: 45,
                    ),
                  const SizedBox(width: 12),
                  const Text(
                    '📸 TOMAR FOTO',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceButton() {
    final isRecording = _provider.isRecording;
    final isDisabled = _provider.hasAnyProcessRunning && !_provider.isProcessingAudio && !isRecording;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isRecording ? Colors.red : const Color(0xFFFF8A65)).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : _provider.onButton4Pressed,
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isRecording
                      ? [Colors.red[400]!, Colors.red[700]!]
                      : [const Color(0xFFFF8A65), const Color(0xFFFF7043)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_provider.isProcessingAudio && !isRecording)
                    const SizedBox(
                      width: 25,
                      height: 25,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    Image.asset(
                      'assets/imagenes/owl-recording.gif',
                      width: 30,
                      height: 30,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    isRecording ? 'DETENER' : 'GRABAR',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
