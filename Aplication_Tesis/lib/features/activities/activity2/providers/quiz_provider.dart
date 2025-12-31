import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/quiz_question.dart';

class QuizProvider with ChangeNotifier {
  QuizQuestion? _currentQuestion;
  int? _selectedAnswerIndex;
  bool _isCorrect = false;
  bool _hasAnswered = false;
  bool _isLoading = false;
  String? _errorMessage;
  int _score = 0;
  int _totalQuestions = 0;
  String? _caption;
  File? _currentImage;

  // Getters
  QuizQuestion? get currentQuestion => _currentQuestion;
  int? get selectedAnswerIndex => _selectedAnswerIndex;
  bool get isCorrect => _isCorrect;
  bool get hasAnswered => _hasAnswered;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get score => _score;
  int get totalQuestions => _totalQuestions;
  String? get caption => _caption;
  File? get currentImage => _currentImage;

  // Generar pregunta desde una imagen
  Future<void> generateQuestionFromImage(File imageFile) async {
    _isLoading = true;
    _errorMessage = null;
    _hasAnswered = false;
    _selectedAnswerIndex = null;
    _currentImage = imageFile;
    notifyListeners();

    try {
      // Paso 1: Predecir la imagen con BLIP
      final predictUrl = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.predictEndpoint}');
      final predictRequest = http.MultipartRequest('POST', predictUrl);
      predictRequest.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final predictStreamedResponse = await predictRequest.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Timeout: El servidor no respondió a tiempo');
        },
      );

      final predictResponse = await http.Response.fromStream(predictStreamedResponse);

      if (predictResponse.statusCode != 200) {
        throw Exception('Error al predecir imagen: ${predictResponse.statusCode}');
      }

      final predictData = json.decode(predictResponse.body);
      final titleCorrect = predictData['title'] ?? '';
      _caption = predictData['caption'] ?? '';

      // Paso 2: Generar quiz con el título y caption
      final quizUrl = Uri.parse('${ApiConstants.baseUrl}/generate-quiz');
      final quizResponse = await http.post(
        quizUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title_correct': titleCorrect,
          'caption': _caption,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: El servidor no respondió a tiempo');
        },
      );

      if (quizResponse.statusCode == 200) {
        final quizData = json.decode(quizResponse.body);
        
        // Crear pregunta con las opciones
        _currentQuestion = QuizQuestion(
          question: quizData['question'] ?? '¿Cuál es el tema correcto de la imagen?',
          options: List<String>.from(quizData['choices'] ?? []),
          correctAnswerIndex: (quizData['choices'] as List).indexOf(quizData['answer']),
        );
        
        _errorMessage = null;
      } else {
        _errorMessage = 'Error al generar quiz: ${quizResponse.statusCode}';
        _currentQuestion = null;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      _currentQuestion = null;
      _currentImage = null;
      if (kDebugMode) {
        print('Error generating question from image: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Seleccionar respuesta
  void selectAnswer(int index) {
    if (!_hasAnswered) {
      _selectedAnswerIndex = index;
      notifyListeners();
    }
  }

  // Validar respuesta
  void validateAnswer() {
    if (_selectedAnswerIndex == null || _currentQuestion == null || _hasAnswered) {
      return;
    }

    _isCorrect = _selectedAnswerIndex == _currentQuestion!.correctAnswerIndex;
    _hasAnswered = true;
    _totalQuestions++;
    
    if (_isCorrect) {
      _score++;
    }
    
    notifyListeners();
  }

  // Reiniciar para nueva pregunta
  void nextQuestion() {
    _currentQuestion = null;
    _selectedAnswerIndex = null;
    _isCorrect = false;
    _hasAnswered = false;
    _errorMessage = null;
    _caption = null;
    _currentImage = null;
    notifyListeners();
  }

  // Reiniciar todo el juego
  void resetGame() {
    _currentQuestion = null;
    _selectedAnswerIndex = null;
    _isCorrect = false;
    _hasAnswered = false;
    _errorMessage = null;
    _score = 0;
    _totalQuestions = 0;
    _caption = null;
    _currentImage = null;
    notifyListeners();
  }

  // Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
