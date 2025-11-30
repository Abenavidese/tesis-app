import 'package:flutter/material.dart';
import '../providers/home_provider.dart';
import '../../../core/constants/app_strings.dart';

class ActionButtons extends StatelessWidget {
  final HomeProvider? provider;
  
  const ActionButtons({
    super.key,
    this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final homeProvider = provider;
    if (homeProvider == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        // Botón principal de cámara (grande y destacado)
        _buildMainCameraButton(homeProvider),
        const SizedBox(height: 16),
        
        // Botones secundarios en fila
        Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(
                context: context,
                label: 'Galería',
                assetImage: 'assets/imagenes/owl-load-file.png',
                gradientColors: [const Color(0xFF42A5F5), const Color(0xFF1976D2)],
                onPressed: homeProvider.onButton2Pressed,
                provider: homeProvider,
                isCurrentlyLoading: homeProvider.isLoadingGallery,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryButton(
                context: context,
                label: 'Debug',
                icon: Icons.bug_report,
                gradientColors: [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
                onPressed: () => homeProvider.onButton3Pressed(context),
                provider: homeProvider,
                isCurrentlyLoading: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Botón de grabar voz (destacado)
        _buildVoiceButton(homeProvider),
      ],
    );
  }

  Widget _buildMainCameraButton(HomeProvider provider) {
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
          onTap: provider.hasAnyProcessRunning ? null : provider.takePicture,
          borderRadius: BorderRadius.circular(24),
          child: Opacity(
            opacity: provider.hasAnyProcessRunning && !provider.isTakingPhoto ? 0.5 : 1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7CB342),
                    const Color(0xFF558B2F),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (provider.isTakingPhoto)
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
                      letterSpacing: 0.5,
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

  Widget _buildSecondaryButton({
    required BuildContext context,
    required String label,
    IconData? icon,
    String? assetImage,
    required List<Color> gradientColors,
    required VoidCallback onPressed,
    required HomeProvider provider,
    bool isCurrentlyLoading = false,
  }) {
    final isDisabled = provider.hasAnyProcessRunning && !isCurrentlyLoading;
    
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
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  else if (assetImage != null)
                    Image.asset(
                      assetImage,
                      width: 35,
                      height: 35,
                    )
                  else if (icon != null)
                    Icon(icon, color: Colors.white, size: 35),
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

  Widget _buildVoiceButton(HomeProvider provider) {
    final isRecording = provider.isRecording;
    final isDisabled = provider.hasAnyProcessRunning && !provider.isProcessingAudio && !isRecording;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isRecording ? Colors.red : const Color(0xFFFF8A65)).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : provider.onButton4Pressed,
          borderRadius: BorderRadius.circular(20),
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isRecording
                    ? [Colors.red[400]!, Colors.red[700]!]
                    : [const Color(0xFFFF8A65), const Color(0xFFFF7043)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (provider.isProcessingAudio && !isRecording)
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  else
                    Image.asset(
                      'assets/imagenes/owl-recording.gif',
                      width: 38,
                      height: 38,
                    ),
                  const SizedBox(width: 12),
                  Text(
                    isRecording ? '⏹️ DETENER' : '🎤 GRABAR VOZ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
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