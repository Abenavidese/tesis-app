import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

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

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIcon(),
                color: _getIconColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getTitle(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getIconColor(),
                  ),
                ),
              ),
              if (isRecording)
                _buildRecordingAnimation(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getContent(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingAnimation() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 1),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        // Restart animation if still recording
      },
    );
  }

  Color _getBorderColor() {
    if (isRecording) return Colors.red.withOpacity(0.5);
    if (isProcessing) return Colors.orange.withOpacity(0.5);
    if (recognizedText?.contains('Error') == true) return Colors.red.withOpacity(0.3);
    return AppColors.primary.withOpacity(0.3);
  }

  Color _getIconColor() {
    if (isRecording) return Colors.red;
    if (isProcessing) return Colors.orange;
    if (recognizedText?.contains('Error') == true) return Colors.red;
    return AppColors.primary;
  }

  IconData _getIcon() {
    if (isRecording) return Icons.mic;
    if (isProcessing) return Icons.hourglass_empty;
    if (recognizedText?.contains('Error') == true) return Icons.error;
    return Icons.record_voice_over;
  }

  String _getTitle() {
    if (isRecording) return 'Grabando...';
    if (isProcessing) return 'Procesando audio...';
    if (recognizedText?.contains('Error') == true) return 'Error en el reconocimiento';
    return 'Texto reconocido';
  }

  String _getContent() {
    if (isRecording) return 'Hable ahora para grabar su mensaje';
    if (isProcessing) return 'Convirtiendo audio a texto...';
    return recognizedText ?? 'Sin texto reconocido';
  }
}