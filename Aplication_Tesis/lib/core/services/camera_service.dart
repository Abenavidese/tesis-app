import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  final ImagePicker _picker = ImagePicker();

  Future<File?> takePicture() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Optimize image quality
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile == null) return null;
      
      return File(pickedFile.path);
    } catch (e) {
      throw CameraException('Error al acceder a la cámara: ${e.toString()}');
    }
  }

  Future<File?> pickFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile == null) return null;
      
      return File(pickedFile.path);
    } catch (e) {
      throw CameraException('Error al acceder a la galería: ${e.toString()}');
    }
  }
}

class CameraException implements Exception {
  final String message;
  
  const CameraException(this.message);
  
  @override
  String toString() => message;
}