import 'package:flutter/material.dart';

class VoiceResultDisplay extends StatelessWidget {
  final String? recognizedText;
  final bool isRecording;
  final bool isProcessing;

  const VoiceResultDisplay({
    super.key,
    this.recognizedText,
    this.isRecording = false,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRecording && !isProcessing && recognizedText == null) {
      return const SizedBox.shrink();
    }

    // Estado grabando
    if (isRecording) {
      return _buildRecordingCard();
    }

    // Estado procesando
    if (isProcessing) {
      return _buildProcessingCard();
    }

    // Resultado exitoso o error
    final hasError = recognizedText?.contains('Error') == true;
    if (hasError) {
      return _buildErrorCard();
    }

    return _buildSuccessCard();
  }

  Widget _buildRecordingCard() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red[300]!.withOpacity(0.3),
            Colors.red[500]!.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withOpacity(0.6),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Animación de pulso
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.8, end: 1.2),
                builder: (context, value, child) {
                  return Container(
                    width: 100 * value,
                    height: 100 * value,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2 / value),
                      shape: BoxShape.circle,
                    ),
                  );
                },
                onEnd: () {},
              ),
              // GIF del búho grabando
              Image.asset(
                'assets/imagenes/owl-recording.gif',
                width: 80,
                height: 80,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'GRABANDO...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '🎤 Habla ahora, el búho está escuchando',
            style: TextStyle(
              fontSize: 15,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingCard() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFB74D).withOpacity(0.3),
            const Color(0xFFFF8A65).withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFB74D).withOpacity(0.6),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/imagenes/owl-predicting.gif',
            width: 80,
            height: 80,
          ),
          const SizedBox(height: 16),
          const Text(
            '⏳ Procesando audio...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE65100),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Convirtiendo tu voz en texto',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red[300]!.withOpacity(0.2),
            Colors.red[600]!.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            '¡Error en el reconocimiento!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recognizedText ?? 'Error desconocido',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8A65).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF8A65),
                  const Color(0xFFFF7043),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.record_voice_over,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '🎙️ Tu respuesta:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                recognizedText ?? 'Sin texto reconocido',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFE65100),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}