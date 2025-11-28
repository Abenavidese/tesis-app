import 'package:flutter/material.dart';
import '../providers/home_provider.dart';
import '../../../shared/widgets/custom_button.dart';
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
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        CustomButton(
          label: AppStrings.takePhoto,
          icon: Icons.camera_alt,
          onPressed: homeProvider.takePicture,
          isLoading: homeProvider.isProcessing,
        ),
        CustomButton(
          label: AppStrings.button2,
          icon: Icons.photo_library,
          onPressed: homeProvider.onButton2Pressed,
          isLoading: homeProvider.isProcessing,
        ),
        CustomButton(
          label: AppStrings.button3,
          icon: Icons.bug_report,
          onPressed: () => homeProvider.onButton3Pressed(context),
        ),
        CustomButton(
          label: homeProvider.isRecording ? 'Detener grabación' : 'Grabar voz',
          icon: homeProvider.isRecording ? Icons.stop : Icons.mic,
          onPressed: homeProvider.onButton4Pressed,
          isLoading: homeProvider.isProcessing,
          backgroundColor: homeProvider.isRecording ? Colors.red : null,
        ),
      ],
    );
  }
}