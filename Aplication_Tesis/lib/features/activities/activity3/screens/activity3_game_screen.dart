import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/challenge_provider.dart';
import '../models/challenge.dart';

class Activity3GameScreen extends StatefulWidget {
  const Activity3GameScreen({super.key});

  @override
  State<Activity3GameScreen> createState() => _Activity3GameScreenState();
}

class _Activity3GameScreenState extends State<Activity3GameScreen> {
  final ImagePicker _picker = ImagePicker();
  Timer? _timer;
  final TextEditingController _sentenceController = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    _sentenceController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        _stopTimer(); // Detener cronómetro solo al empezar a procesar
        await context.read<ChallengeProvider>().validateChallenge(
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
        _stopTimer(); // Detener cronómetro solo al empezar a procesar
        await context.read<ChallengeProvider>().validateChallenge(
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

  void _startTimer() {
    final provider = context.read<ChallengeProvider>();
    provider.resetTimer();
    
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      provider.decrementTimer();
      
      if (provider.timeRemaining <= 0) {
        timer.cancel();
        // Mostrar mensaje de tiempo agotado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏰ ¡Tiempo agotado! Intenta de nuevo'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() {}); // Forzar reconstrucción para actualizar el botón
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: Consumer<ChallengeProvider>(
          builder: (context, provider, child) {
            return Stack(
              children: [
                Column(
                  children: [
                    // Header
                    _buildHeader(provider),
                    
                    // Contenido principal
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            if (provider.errorMessage != null)
                              _buildErrorState(provider)
                            else if (provider.challengeCompleted)
                              _buildSuccessState(provider)
                            else ...[
                              if (provider.isLoading)
                                _buildLoadingState(),
                              _buildChallengeContent(provider),
                            ],
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
                      _timer?.cancel();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    backgroundColor: const Color(0xFFFF8A65),
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

  Widget _buildHeader(ChallengeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
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
                  'Retos Divertidos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Reto ${provider.currentChallengeIndex + 1}/${provider.totalChallenges} | Puntos: ${provider.score}',
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
              _timer?.cancel();
              provider.resetGame();
              _sentenceController.clear();
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
            color: Color(0xFFFF8A65),
          ),
          const SizedBox(height: 16),
          const Text(
            '¡Validando tu respuesta!',
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

  Widget _buildErrorState(ChallengeProvider provider) {
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
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Intentar de nuevo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A65),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(ChallengeProvider provider) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: Column(
            children: [
              const Icon(Icons.celebration, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                '¡RETO COMPLETADO! 🎉',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              if (provider.detectedSubject != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Detectado: ${provider.detectedSubject}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Botón siguiente reto
        if (!provider.isLastChallenge)
          ElevatedButton.icon(
            onPressed: () {
              _timer?.cancel();
              provider.nextChallenge();
              _sentenceController.clear();
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('SIGUIENTE RETO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A65),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: () {
              _timer?.cancel();
              _showFinalScore(provider);
            },
            icon: const Icon(Icons.emoji_events),
            label: const Text('VER PUNTUACIÓN FINAL'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A65),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildChallengeContent(ChallengeProvider provider) {
    switch (provider.currentChallenge.type) {
      case ChallengeType.selection:
        return _buildChallenge1(provider);
      case ChallengeType.quickCapture:
        return _buildChallenge2(provider);
      case ChallengeType.imageSelection:
        return _buildChallenge3(provider);
      case ChallengeType.completeSentence:
        return _buildChallenge4(provider);
    }
  }

  // Reto 1: Selección de imagen
  Widget _buildChallenge1(ChallengeProvider provider) {
    return Column(
      children: [
        Container(
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
                '🎯',
                style: TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 12),
              Text(
                provider.currentChallenge.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Elige la imagen correcta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: provider.timeRemaining > 5 
                      ? const Color(0xFFFF8A65).withOpacity(0.2)
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${provider.timeRemaining}s',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: provider.timeRemaining > 5 
                        ? const Color(0xFFFF7043)
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (provider.timeRemaining > 0 && !provider.isLoading) 
                    ? () {
                        if (_timer == null || !_timer!.isActive) {
                          _startTimer();
                        }
                        _captureImage();
                      }
                    : null,
                icon: const Icon(Icons.camera_alt),
                label: Text(_timer == null || !_timer!.isActive 
                    ? 'INICIAR' 
                    : 'CÁMARA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A65),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (provider.timeRemaining > 0 && !provider.isLoading) 
                    ? () {
                        if (_timer == null || !_timer!.isActive) {
                          _startTimer();
                        }
                        _pickFromGallery();
                      }
                    : null,
                icon: const Icon(Icons.photo_library),
                label: const Text('GALERÍA'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF7043),
                  side: const BorderSide(color: Color(0xFFFF8A65), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
        
        if (_timer != null && _timer!.isActive) ...[
          const SizedBox(height: 16),
          const Text(
            '¡Rápido! El tiempo corre',
            style: TextStyle(
              fontSize: 16,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  // Reto 2: Captura rápida con timer
  Widget _buildChallenge2(ChallengeProvider provider) {
    return Column(
      children: [
        Container(
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
                '⏱️',
                style: TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 12),
              Text(
                provider.currentChallenge.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: provider.timeRemaining > 5 
                      ? const Color(0xFFFF8A65).withOpacity(0.2)
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${provider.timeRemaining}s',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: provider.timeRemaining > 5 
                        ? const Color(0xFFFF7043)
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (provider.timeRemaining > 0 && !provider.isLoading) 
                    ? () {
                        if (_timer == null || !_timer!.isActive) {
                          _startTimer();
                        }
                        _captureImage();
                      }
                    : null,
                icon: const Icon(Icons.camera_alt),
                label: Text(_timer == null || !_timer!.isActive 
                    ? 'INICIAR' 
                    : 'CÁMARA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A65),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (provider.timeRemaining > 0 && !provider.isLoading) 
                    ? () {
                        if (_timer == null || !_timer!.isActive) {
                          _startTimer();
                        }
                        _pickFromGallery();
                      }
                    : null,
                icon: const Icon(Icons.photo_library),
                label: const Text('GALERÍA'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF7043),
                  side: const BorderSide(color: Color(0xFFFF8A65), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
        
        if (_timer != null && _timer!.isActive) ...[
          const SizedBox(height: 16),
          const Text(
            '¡Rápido! El tiempo corre',
            style: TextStyle(
              fontSize: 16,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  // Reto 3: Selección de imagen desde assets
  Widget _buildChallenge3(ChallengeProvider provider) {
    // Cargar las imágenes si no están cargadas
    if (provider.imageOptions.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.loadImageOptions();
      });
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(color: Color(0xFFFF8A65)),
            SizedBox(height: 16),
            Text(
              'Cargando imágenes...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        Container(
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
                '🖼️',
                style: TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 12),
              Text(
                provider.currentChallenge.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona la imagen correcta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Grid de imágenes
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: provider.imageOptions.length,
          itemBuilder: (context, index) {
            final isSelected = provider.selectedImageIndex == index;
            
            return GestureDetector(
              onTap: () => provider.selectImage(index),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF8A65) : Colors.grey.shade300,
                    width: isSelected ? 4 : 2,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: const Color(0xFFFF8A65).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ] : [],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        provider.imageOptions[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.error, size: 40, color: Colors.grey),
                          );
                        },
                      ),
                      if (isSelected)
                        Container(
                          color: const Color(0xFFFF8A65).withOpacity(0.3),
                          child: const Center(
                            child: Icon(Icons.check_circle, size: 48, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        ElevatedButton.icon(
          onPressed: provider.selectedImageIndex != null
              ? () => provider.validateSelectedImage()
              : null,
          icon: const Icon(Icons.check),
          label: const Text('VALIDAR SELECCIÓN'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8A65),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // Reto 4: Completar frases con opciones
  Widget _buildChallenge4(ChallengeProvider provider) {
    // Generar opciones si no están generadas
    if (provider.wordOptions.isEmpty && provider.fullDescription != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.generateWordOptions(provider.fullDescription!);
      });
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(color: Color(0xFFFF8A65)),
            SizedBox(height: 16),
            Text(
              'Preparando opciones...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    
    // Si no hay descripción del reto 2
    if (provider.fullDescription == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.info_outline, size: 80, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Completa el Reto 2 primero',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Necesitas completar el reto anterior\npara desbloquear este',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    final description = provider.fullDescription!;
    
    // Crear frase con palabra faltante
    final sentenceWithBlank = description.replaceFirst(
      provider.correctWord, 
      '_____',
    );
    
    return Column(
      children: [
        Container(
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
                '✍️',
                style: TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 12),
              const Text(
                'Completa la Frase',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 16),
              if (provider.capturedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    provider.capturedImage!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                sentenceWithBlank,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Selecciona la palabra correcta:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF424242),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Opciones de palabras
        ...List.generate(provider.wordOptions.length, (index) {
          final isSelected = provider.selectedWordIndex == index;
          final word = provider.wordOptions[index];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => provider.selectWord(index),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFFFF8A65).withOpacity(0.2) 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFFFF8A65) 
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFFFF8A65).withOpacity(0.3)
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C, D
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected 
                                  ? const Color(0xFFFF7043)
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          word,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isSelected 
                                ? const Color(0xFF424242)
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Color(0xFFFF8A65), size: 28),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        
        const SizedBox(height: 16),
        
        ElevatedButton.icon(
          onPressed: provider.selectedWordIndex != null
              ? () => provider.validateSelectedWord()
              : null,
          icon: const Icon(Icons.check),
          label: const Text('VALIDAR'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8A65),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  String _buildSentenceWithBlanks(List<String> words, int hiddenIndex) {
    return words.asMap().entries.map((entry) {
      if (entry.key == hiddenIndex) {
        return '_____';
      }
      return entry.value;
    }).join(' ');
  }

  void _showFinalScore(ChallengeProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🏆 ¡JUEGO COMPLETADO!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'Puntuación Final',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${provider.score} / ${provider.totalChallenges}',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFFFF8A65)),
            ),
            const SizedBox(height: 16),
            Text(
              provider.score == provider.totalChallenges
                  ? '¡Perfecto! Eres increíble'
                  : provider.score >= provider.totalChallenges / 2
                      ? '¡Muy bien! Sigue practicando'
                      : '¡Buen intento! Inténtalo de nuevo',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.resetGame();
              _sentenceController.clear();
            },
            child: const Text('JUGAR DE NUEVO'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A65),
              foregroundColor: Colors.white,
            ),
            child: const Text('VOLVER AL MENÚ'),
          ),
        ],
      ),
    );
  }
}
