import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/quiz_provider.dart';

class Activity2GameScreen extends StatefulWidget {
  const Activity2GameScreen({super.key});

  @override
  State<Activity2GameScreen> createState() => _Activity2GameScreenState();
}

class _Activity2GameScreenState extends State<Activity2GameScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _captureImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        // Generar quiz desde la imagen capturada
        await context.read<QuizProvider>().generateQuestionFromImage(
          File(photo.path),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al capturar imagen: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        // Generar quiz desde la imagen seleccionada
        await context.read<QuizProvider>().generateQuestionFromImage(
          File(photo.path),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: Consumer<QuizProvider>(
          builder: (context, provider, child) {
            return Stack(
              children: [
                Column(
                  children: [
                    // Header con búho y puntuación
                    _buildHeader(provider),
                    
                    // Contenido principal
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            if (provider.isLoading && provider.currentQuestion == null)
                              _buildLoadingState()
                            else if (provider.errorMessage != null)
                              _buildErrorState(provider)
                            else if (provider.currentQuestion != null)
                              _buildQuizContent(provider)
                            else
                              _buildInitialState(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Botón flotante para ir al home
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    backgroundColor: const Color(0xFF42A5F5),
                    child: const Icon(Icons.home, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(QuizProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/imagenes/owl-take-photo.png',
            width: 40,
            height: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quiz Game',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Puntos: ${provider.score} / ${provider.totalQuestions}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              provider.resetGame();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF42A5F5),
          ),
          const SizedBox(height: 16),
          const Text(
            '¡Preparando pregunta!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(QuizProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            '¡Oops! Algo salió mal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.errorMessage ?? 'Error desconocido',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              provider.clearError();
              _captureImage();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Intentar de nuevo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF42A5F5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt,
            size: 100,
            color: Color(0xFF42A5F5),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Elige una imagen!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Captura una imagen o selecciónala\nde tu galería para generar el quiz',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _captureImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('TOMAR FOTO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF42A5F5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('CARGAR DE GALERÍA'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1976D2),
              side: const BorderSide(color: Color(0xFF42A5F5), width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizContent(QuizProvider provider) {
    final question = provider.currentQuestion!;
    
    return Column(
      children: [
        // Imagen capturada
        if (provider.currentImage != null)
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                provider.currentImage!,
                fit: BoxFit.cover,
              ),
            ),
          ),
        
        // Pregunta
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                '❓',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              Text(
                question.question,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Opciones
        ...List.generate(question.options.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOptionButton(
              provider,
              index,
              question.options[index],
            ),
          );
        }),
        
        const SizedBox(height: 24),
        
        // Botón de validar o siguiente
        if (!provider.hasAnswered && provider.selectedAnswerIndex != null)
          _buildValidateButton(provider)
        else if (provider.hasAnswered)
          _buildResultAndNextButton(provider),
      ],
    );
  }

  Widget _buildOptionButton(QuizProvider provider, int index, String option) {
    final isSelected = provider.selectedAnswerIndex == index;
    final hasAnswered = provider.hasAnswered;
    final isCorrectAnswer = provider.currentQuestion!.correctAnswerIndex == index;
    
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    
    if (!hasAnswered) {
      backgroundColor = isSelected ? const Color(0xFF42A5F5).withOpacity(0.2) : Colors.white;
      borderColor = isSelected ? const Color(0xFF42A5F5) : Colors.grey.shade300;
      textColor = const Color(0xFF424242);
    } else {
      if (isCorrectAnswer) {
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green;
        textColor = Colors.green.shade900;
      } else if (isSelected && !provider.isCorrect) {
        backgroundColor = Colors.red.shade50;
        borderColor = Colors.red;
        textColor = Colors.red.shade900;
      } else {
        backgroundColor = Colors.white;
        borderColor = Colors.grey.shade300;
        textColor = Colors.grey;
      }
    }
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasAnswered ? null : () => provider.selectAnswer(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: borderColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              if (hasAnswered && isCorrectAnswer)
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
              if (hasAnswered && isSelected && !provider.isCorrect)
                const Icon(Icons.cancel, color: Colors.red, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidateButton(QuizProvider provider) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF42A5F5).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: provider.isLoading ? null : () => provider.validateAnswer(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: provider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      '✓ VALIDAR RESPUESTA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultAndNextButton(QuizProvider provider) {
    return Column(
      children: [
        // Resultado
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: provider.isCorrect ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: provider.isCorrect ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                provider.isCorrect ? Icons.celebration : Icons.sentiment_dissatisfied,
                size: 64,
                color: provider.isCorrect ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                provider.isCorrect ? '¡CORRECTO! 🎉' : 'No es correcta 😔',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: provider.isCorrect ? Colors.green.shade900 : Colors.red.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.isCorrect
                    ? '¡Muy bien! Sigue así'
                    : 'La respuesta correcta es: ${provider.currentQuestion!.correctAnswer}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: provider.isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Botón siguiente pregunta
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF42A5F5).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                provider.nextQuestion();
                _captureImage();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    '➡️ SIGUIENTE PREGUNTA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
