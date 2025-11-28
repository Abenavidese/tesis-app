import 'package:flutter/material.dart';
import '../models/image_analysis.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_message.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class ResultDisplay extends StatelessWidget {
  final ImageAnalysis? analysis;
  final VoidCallback? onRetry;

  const ResultDisplay({
    super.key,
    this.analysis,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (analysis == null) {
      return const SizedBox.shrink();
    }

    if (analysis!.isLoading) {
      return const LoadingIndicator(
        message: AppStrings.consultingModel,
      );
    }

    if (analysis!.hasError) {
      return ErrorMessage(
        message: analysis!.error!,
        onRetry: onRetry,
      );
    }

    if (analysis!.hasCaption) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.generatedDescription,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              analysis!.caption,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generado: ${_formatTimestamp(analysis!.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'hace unos segundos';
    } else if (difference.inHours < 1) {
      return 'hace ${difference.inMinutes} minuto${difference.inMinutes != 1 ? 's' : ''}';
    } else {
      return 'hace ${difference.inHours} hora${difference.inHours != 1 ? 's' : ''}';
    }
  }
}