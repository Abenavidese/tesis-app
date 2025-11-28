import 'dart:io';

class ImageAnalysis {
  final File imageFile;
  final String caption;
  final DateTime timestamp;
  final String? error;
  final bool isLoading;

  const ImageAnalysis({
    required this.imageFile,
    required this.caption,
    required this.timestamp,
    this.error,
    this.isLoading = false,
  });

  ImageAnalysis.loading(this.imageFile)
      : caption = '',
        timestamp = DateTime.now(),
        error = null,
        isLoading = true;

  ImageAnalysis.error(this.imageFile, this.error)
      : caption = '',
        timestamp = DateTime.now(),
        isLoading = false;

  ImageAnalysis copyWith({
    File? imageFile,
    String? caption,
    DateTime? timestamp,
    String? error,
    bool? isLoading,
  }) {
    return ImageAnalysis(
      imageFile: imageFile ?? this.imageFile,
      caption: caption ?? this.caption,
      timestamp: timestamp ?? this.timestamp,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get hasError => error != null;
  bool get hasCaption => caption.isNotEmpty && !isLoading && !hasError;
}