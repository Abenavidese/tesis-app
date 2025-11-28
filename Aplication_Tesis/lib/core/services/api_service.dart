import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<String> predictImageCaption(File imageFile) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.predictEndpoint}');
      
      final request = http.MultipartRequest('POST', uri);
      
      // Agregar headers importantes
      request.headers['Accept'] = 'application/json';
      
      // Crear multipart file con content type explícito
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: imageFile.path.split('/').last,
      );
      
      print('📤 Enviando imagen: ${multipartFile.filename}');
      print('📋 Content-Type: ${multipartFile.contentType}');
      
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(
        const Duration(milliseconds: ApiConstants.receiveTimeout),
      );
      
      final responseBody = await streamedResponse.stream.bytesToString();

      print('📥 Respuesta del servidor: ${streamedResponse.statusCode}');
      print('📄 Cuerpo de la respuesta: $responseBody');
      
      if (streamedResponse.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['caption'] as String? ?? 'No se pudo generar descripción';
      } else {
        // Intentar parsear el error JSON para mejor información
        String errorMessage;
        try {
          final errorData = jsonDecode(responseBody);
          errorMessage = errorData['detail'] ?? responseBody;
        } catch (e) {
          errorMessage = responseBody;
        }
        
        throw ApiException(
          'Error del servidor (${streamedResponse.statusCode}): $errorMessage',
          streamedResponse.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException('El modelo está tardando mucho en responder. La primera vez puede tardar hasta 3 minutos cargando.', 408);
    } on http.ClientException {
      throw ApiException('Error de conexión. Verifica que el servidor esté ejecutándose en http://127.0.0.1:8000', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error inesperado: ${e.toString()}', -1);
    }
  }

  Future<String> speechToText(File audioFile) async {
    try {
      // Para archivos simulados, devolver texto simulado
      if (audioFile.path.contains('simulated_')) {
        await Future.delayed(const Duration(seconds: 2)); // Simular procesamiento
        
        final sampleTexts = [
          'Hola, esta es una prueba de reconocimiento de voz',
          'El reconocimiento de voz funciona correctamente',
          'Esta aplicación puede transcribir audio a texto',
          'Funciona muy bien la transcripción de voz',
          'El micrófono está funcionando perfectamente'
        ];
        
        final random = Random();
        final simulatedText = sampleTexts[random.nextInt(sampleTexts.length)];
        print('🎤 Texto simulado generado: $simulatedText');
        return simulatedText;
      }
      
      // Para archivos reales, usar la API del servidor
      final uri = Uri.parse('${ApiConstants.baseUrl}/speech-to-text');
      
      final request = http.MultipartRequest('POST', uri);
      
      // Agregar headers importantes
      request.headers['Accept'] = 'application/json';
      
      // Crear multipart file con content type explícito
      final multipartFile = await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
        filename: audioFile.path.split('/').last,
      );
      
      print('🎤 Enviando audio: ${multipartFile.filename}');
      print('📋 Content-Type: ${multipartFile.contentType}');
      
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(
        const Duration(milliseconds: ApiConstants.receiveTimeout),
      );
      
      final responseBody = await streamedResponse.stream.bytesToString();

      print('📥 Respuesta del servidor (audio): ${streamedResponse.statusCode}');
      print('📄 Cuerpo de la respuesta (audio): $responseBody');
      
      if (streamedResponse.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['text'] as String? ?? 'No se pudo reconocer el audio';
      } else {
        // Intentar parsear el error JSON para mejor información
        String errorMessage;
        try {
          final errorData = jsonDecode(responseBody);
          errorMessage = errorData['detail'] ?? responseBody;
        } catch (e) {
          errorMessage = responseBody;
        }
        
        throw ApiException(
          'Error del servidor procesando audio (${streamedResponse.statusCode}): $errorMessage',
          streamedResponse.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException('El reconocimiento de voz tardó demasiado. Intenta con un audio más corto.', 408);
    } on http.ClientException {
      throw ApiException('Error de conexión. Verifica que el servidor esté ejecutándose.', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error procesando audio: ${e.toString()}', -1);
    }
  }

  Future<EvaluationResult> evaluateResponse({
    required String textoModelo,
    required String textoNino,
    double umbral = 0.6,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/evaluate');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'texto_modelo': textoModelo,
          'texto_nino': textoNino,
          'umbral': umbral,
        }),
      ).timeout(
        const Duration(seconds: 30),
      );

      print('📥 Respuesta evaluación: ${response.statusCode}');
      print('📄 Cuerpo: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EvaluationResult.fromJson(data);
      } else {
        String errorMessage;
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? response.body;
        } catch (e) {
          errorMessage = response.body;
        }
        
        throw ApiException(
          'Error evaluando respuesta (${response.statusCode}): $errorMessage',
          response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException('La evaluación tardó demasiado. Intenta de nuevo.', 408);
    } on http.ClientException {
      throw ApiException('Error de conexión. Verifica que el servidor esté ejecutándose.', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error evaluando respuesta: ${e.toString()}', -1);
    }
  }
}

class EvaluationResult {
  final String mensaje;
  final bool esCorrecta;
  final Map<String, dynamic> detalles;

  EvaluationResult({
    required this.mensaje,
    required this.esCorrecta,
    required this.detalles,
  });

  factory EvaluationResult.fromJson(Map<String, dynamic> json) {
    return EvaluationResult(
      mensaje: json['mensaje'] as String,
      esCorrecta: json['es_correcta'] as bool,
      detalles: json['detalles'] as Map<String, dynamic>,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  
  const ApiException(this.message, this.statusCode);
  
  @override
  String toString() => message;
}