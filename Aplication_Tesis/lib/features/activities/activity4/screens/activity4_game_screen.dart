import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/characteristics_service.dart';
import '../../../../core/constants/api_constants.dart';

class Activity4GameScreen extends StatefulWidget {
  const Activity4GameScreen({super.key});

  @override
  State<Activity4GameScreen> createState() => _Activity4GameScreenState();
}

class _Activity4GameScreenState extends State<Activity4GameScreen> {
  final CharacteristicsService _service = CharacteristicsService();
  
  String? selectedImage;
  String? currentCategory;
  List<String> correctCharacteristics = [];
  List<String> allOptions = [];
  List<String> selectedCharacteristics = [];
  bool isLoading = false;
  bool isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadNewQuestion();
  }

  Future<void> _loadNewQuestion() async {
    setState(() {
      isLoadingData = true;
    });

    try {
      final data = await _service.getRandomImageWithCharacteristics();
      
      setState(() {
        currentCategory = data['category'];
        selectedImage = data['image'];
        correctCharacteristics = data['correctCharacteristics'];
        allOptions = data['allOptions'];
        selectedCharacteristics.clear();
        isLoadingData = false;
      });
    } catch (e) {
      print('Error cargando pregunta: $e');
      setState(() {
        isLoadingData = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleCharacteristic(String characteristic) {
    setState(() {
      if (selectedCharacteristics.contains(characteristic)) {
        selectedCharacteristics.remove(characteristic);
      } else {
        selectedCharacteristics.add(characteristic);
      }
    });
  }

  Future<void> _submitAnswer() async {
    if (selectedCharacteristics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos una característica'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Cargar la imagen desde assets
      final imagePath = 'lib/features/activities/activity3/images/$selectedImage';
      final ByteData imageData = await rootBundle.load(imagePath);
      final List<int> imageBytes = imageData.buffer.asUint8List();

      // Crear el request multipart
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/validar-caracteristicas'),
      );

      // Agregar la imagen como bytes
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: selectedImage,
        ),
      );

      // Agregar las características seleccionadas (separadas por comas)
      request.fields['caracteristicas_seleccionadas'] = selectedCharacteristics.join(', ');

      // Enviar request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parsear respuesta
        final result = jsonDecode(response.body);
        final isCorrect = result['es_correcto'] ?? false;
        final message = result['mensaje'] ?? 'Respuesta recibida';
        final totalCorrect = result['total_correctas'] ?? 0;
        final totalSelected = result['total_seleccionadas'] ?? 0;

        setState(() {
          isLoading = false;
        });

        // Mostrar resultado
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isCorrect ? '¡Correcto!' : '¡Inténtalo de nuevo!',
                      style: TextStyle(
                        color: isCorrect ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  const SizedBox(height: 12),
                  Text(
                    'Correctas: $totalCorrect/$totalSelected',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Cargar nueva pregunta
                    _loadNewQuestion();
                  },
                  child: const Text('SIGUIENTE'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error enviando respuesta: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Contenido principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Título
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFAB47BC), Color(0xFF8E24AA)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFAB47BC).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '✨ Elige las características correctas de:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Indicador de carga
                    if (isLoadingData)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFFAB47BC),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Cargando pregunta...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    
                    // Imagen
                    else if (selectedImage != null)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'lib/features/activities/activity3/images/$selectedImage',
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    
                    
                    const SizedBox(height: 24),
                    
                    // Características
                    if (!isLoadingData && allOptions.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.checklist,
                                color: Color(0xFFAB47BC),
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Selecciona las características:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...allOptions.map((characteristic) {
                            final isSelected = selectedCharacteristics.contains(characteristic);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _toggleCharacteristic(characteristic),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFAB47BC).withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFAB47BC)
                                            : Colors.grey.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          color: isSelected
                                              ? const Color(0xFFAB47BC)
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            characteristic,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? const Color(0xFF424242)
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botón de enviar
                    if (!isLoadingData && allOptions.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFAB47BC).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isLoading ? null : _submitAnswer,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isLoading
                                    ? [Colors.grey, Colors.grey[600]!]
                                    : [const Color(0xFFAB47BC), const Color(0xFF8E24AA)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isLoading)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                else
                                  const Text(
                                    '✅ VERIFICAR RESPUESTA',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/imagenes/owl-take-photo.png',
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 12),
                const Text(
                  'ACTIVIDAD 4',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48), // Para centrar el título
        ],
      ),
    );
  }
}
