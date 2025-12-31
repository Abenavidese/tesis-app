import 'package:flutter/material.dart';
import 'dart:math' as math;
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
      backgroundColor: const Color(0xFFFFF8E1), // Fondo cálido amarillo claro
      body: SafeArea(
        child: Stack(
          children: [
            // Decoraciones de fondo
            ..._buildBackgroundDecorations(),
            
            // Contenido principal
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  
                  // Header con búho
                  _buildHeader(),
                  const SizedBox(height: 16),

                  // Image section
                  AnimatedBuilder(
                    animation: _provider,
                    builder: (context, child) {
                      if (_provider.hasImage) {
                        return _buildImageCard();
                      } else {
                        return _buildEmptyStateCard();
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
                      
                      return _buildEvaluateButton();
                    },
                  ),

                  // Evaluation result
                  AnimatedBuilder(
                    animation: _provider,
                    builder: (context, child) {
                      if (_provider.evaluationMessage == null) {
                        return const SizedBox.shrink();
                      }
                      
                      return _buildEvaluationResult();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  AnimatedBuilder(
                    animation: _provider,
                    builder: (context, child) {
                      return ActionButtons(provider: _provider);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Decoraciones de fondo con círculos y elementos naturales
  List<Widget> _buildBackgroundDecorations() {
    return [
      Positioned(
        top: -50,
        right: -50,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF7CB342).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: 100,
        left: -70,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB74D).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        top: 200,
        left: 20,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF558B2F).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: 300,
        right: 30,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFFF8A65).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ];
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7CB342),
            const Color(0xFF558B2F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7CB342).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/imagenes/owl-load-file.png',
            width: 50,
            height: 50,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🦉 ¡Aprende con el Búho Sabio!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Toma fotos y descubre el mundo',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFB74D),
                  const Color(0xFFFF8A65),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_camera, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '📸 Tu Foto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ImagePreview(
                imageFile: _provider.currentAnalysis!.imageFile,
                height: 220,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7CB342).withOpacity(0.3),
          width: 3,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/imagenes/owl-take-photo.png',
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 16),
          const Text(
            '¡Aún no hay fotos!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF558B2F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Presiona el botón de la cámara\npara comenzar a explorar 🌿',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluateButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _provider.hasAnyProcessRunning ? null : () => _provider.evaluateAnswer(),
            borderRadius: BorderRadius.circular(20),
            child: Opacity(
              opacity: _provider.hasAnyProcessRunning && !_provider.isEvaluating ? 0.5 : 1.0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple[400]!,
                      Colors.purple[600]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_provider.isEvaluating)
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    else
                      Image.asset(
                        'assets/imagenes/owl-evaluate.gif',
                        width: 40,
                        height: 40,
                      ),
                    const SizedBox(width: 12),
                    const Text(
                      '✨ EVALUAR RESPUESTA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEvaluationResult() {
    final isCorrect = _provider.isCorrect ?? false;
    
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCorrect 
              ? [const Color(0xFF66BB6A), const Color(0xFF43A047)]
              : [const Color(0xFFFFB74D), const Color(0xFFFF8A65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isCorrect ? Colors.green : Colors.orange).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Image.asset(
              isCorrect 
                ? 'assets/imagenes/owl-correct-ans.gif'
                : 'assets/imagenes/ow-wrong-ans.gif',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 16),
            Text(
              _provider.evaluationMessage!,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isCorrect ? '¡Sigue así! 🌟' : '¡Intenta otra vez! 💪',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}