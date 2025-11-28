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