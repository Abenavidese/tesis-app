import 'package:flutter/material.dart';
import '../providers/home_provider.dart';
import '../widgets/image_preview.dart';
import '../widgets/action_buttons.dart';
import '../widgets/result_display.dart';
import '../widgets/voice_result_display.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Welcome section
              const Text(
                AppStrings.welcome,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.homeDescription,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Image section
              AnimatedBuilder(
                animation: _provider,
                builder: (context, child) {
                  if (_provider.hasImage) {
                    return Column(
                      children: [
                        const Text(
                          AppStrings.lastPhotoTaken,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ImagePreview(
                          imageFile: _provider.currentAnalysis!.imageFile,
                          height: 250,
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  } else {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textHint.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 48,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            AppStrings.noPhotoTaken,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textHint,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
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
                    isProcessing: _provider.isProcessing && _provider.isRecording == false,
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
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _provider.isProcessing ? null : () => _provider.evaluateAnswer(),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text(
                          'EVALUAR RESPUESTA',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Evaluation result
              AnimatedBuilder(
                animation: _provider,
                builder: (context, child) {
                  if (_provider.evaluationMessage == null) {
                    return const SizedBox.shrink();
                  }
                  
                  final isCorrect = _provider.isCorrect ?? false;
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isCorrect ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCorrect ? Colors.green : Colors.orange,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isCorrect ? Icons.celebration : Icons.refresh,
                            size: 48,
                            color: isCorrect ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _provider.evaluationMessage!,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isCorrect ? Colors.green : Colors.orange,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Action buttons
              AnimatedBuilder(
                animation: _provider,
                builder: (context, child) {
                  return ActionButtons(provider: _provider);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}