import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  Future<File> saveImageToLocal(File originalFile) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'photo_$timestamp.jpg';
      final String newPath = '${appDocDir.path}/$fileName';
      
      return await originalFile.copy(newPath);
    } catch (e) {
      throw FileException('Error al guardar la imagen: ${e.toString()}');
    }
  }

  Future<void> deleteImage(File imageFile) async {
    try {
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      throw FileException('Error al eliminar la imagen: ${e.toString()}');
    }
  }

  Future<List<File>> getAllSavedImages() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = appDocDir.listSync();
      
      return files
          .where((file) => file is File && file.path.endsWith('.jpg'))
          .cast<File>()
          .toList();
    } catch (e) {
      throw FileException('Error al obtener las imágenes: ${e.toString()}');
    }
  }

  Future<void> cleanupOldImages({int maxImages = 10}) async {
    try {
      final images = await getAllSavedImages();
      
      if (images.length > maxImages) {
        // Sort by modification date (oldest first)
        images.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
        
        // Delete oldest images
        for (int i = 0; i < images.length - maxImages; i++) {
          await deleteImage(images[i]);
        }
      }
    } catch (e) {
      // Ignore cleanup errors, not critical
    }
  }
}

class FileException implements Exception {
  final String message;
  
  const FileException(this.message);
  
  @override
  String toString() => message;
}