import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/challenge.dart';

class ChallengeProvider with ChangeNotifier {
  int _currentChallengeIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  bool _challengeCompleted = false;
  String? _detectedSubject;
  String? _fullDescription;
  File? _capturedImage;
  int _score = 0;
  int _timeRemaining = 10; // Para reto 2
  List<String> _imageOptions = []; // Para reto 3: rutas de imágenes
  int? _selectedImageIndex; // Índice de imagen seleccionada
  int _correctImageIndex = 0; // Índice de la imagen correcta
  List<String> _wordOptions = []; // Para reto 4: opciones de palabras
  int? _selectedWordIndex; // Índice de palabra seleccionada
  String _correctWord = ''; // Palabra correcta

  // Lista de retos
  final List<Challenge> _challenges = [
    Challenge(
      number: 1,
      title: 'Reto 1: Selección',
      description: '¡Encuentra al caballo!',
      targetSubject: 'caballo',
      type: ChallengeType.selection,
    ),
    Challenge(
      number: 2,
      title: 'Reto 2: Captura Rápida',
      description: '¡Tómale foto a un burro!',
      targetSubject: 'burro',
      type: ChallengeType.quickCapture,
    ),
    Challenge(
      number: 3,
      title: 'Reto 3: Selección de Imagen',
      description: '¡Encuentra al gato!',
      targetSubject: 'gato',
      type: ChallengeType.imageSelection,
    ),
    Challenge(
      number: 4,
      title: 'Reto 4: Completa la Frase',
      description: 'Completa la descripción',
      targetSubject: '',
      type: ChallengeType.completeSentence,
    ),
  ];

  // Getters
  Challenge get currentChallenge => _challenges[_currentChallengeIndex];
  int get currentChallengeIndex => _currentChallengeIndex;
  int get totalChallenges => _challenges.length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get challengeCompleted => _challengeCompleted;
  String? get detectedSubject => _detectedSubject;
  String? get fullDescription => _fullDescription;
  File? get capturedImage => _capturedImage;
  int get score => _score;
  int get timeRemaining => _timeRemaining;
  bool get isLastChallenge => _currentChallengeIndex >= _challenges.length - 1;
  List<String> get imageOptions => _imageOptions;
  int? get selectedImageIndex => _selectedImageIndex;
  int get correctImageIndex => _correctImageIndex;
  List<String> get wordOptions => _wordOptions;
  int? get selectedWordIndex => _selectedWordIndex;
  String get correctWord => _correctWord;

  // Validar imagen capturada contra el sujeto solicitado
  Future<void> validateChallenge(File imageFile) async {
    _isLoading = true;
    _errorMessage = null;
    _capturedImage = imageFile;
    notifyListeners();

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/validar-reto');
      final request = http.MultipartRequest('POST', url);
      
      // Agregar imagen (DEBE IR PRIMERO)
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      
      // Agregar parámetros como form-data
      request.fields['sujeto_solicitado'] = currentChallenge.targetSubject;
      request.fields['umbral'] = '0.7';

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Timeout: El servidor no respondió a tiempo');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        _challengeCompleted = data['es_correcto'] ?? false;
        _detectedSubject = data['sujeto_detectado'] ?? '';
        _fullDescription = data['descripcion_completa'] ?? '';
        
        if (_challengeCompleted) {
          _score++;
        }
        
        _errorMessage = null;
      } else {
        _errorMessage = 'Error al validar reto: ${response.statusCode}';
        _challengeCompleted = false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      _challengeCompleted = false;
      if (kDebugMode) {
        print('Error validating challenge: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Avanzar al siguiente reto
  void nextChallenge() {
    if (_currentChallengeIndex < _challenges.length - 1) {
      _currentChallengeIndex++;
      _challengeCompleted = false;
      _detectedSubject = null;
      _errorMessage = null;
      _capturedImage = null;
      _timeRemaining = 10;
      _selectedImageIndex = null;
      _selectedWordIndex = null;
      _imageOptions = [];
      _wordOptions = [];
      notifyListeners();
    }
  }

  // Reiniciar el juego completo
  void resetGame() {
    _currentChallengeIndex = 0;
    _challengeCompleted = false;
    _detectedSubject = null;
    _fullDescription = null;
    _errorMessage = null;
    _capturedImage = null;
    _score = 0;
    _timeRemaining = 10;
    _selectedImageIndex = null;
    _selectedWordIndex = null;
    _imageOptions = [];
    _wordOptions = [];
    notifyListeners();
  }

  // Timer para reto 2
  void decrementTimer() {
    if (_timeRemaining > 0) {
      _timeRemaining--;
      notifyListeners();
    }
  }

  void resetTimer() {
    _timeRemaining = 10;
    notifyListeners();
  }

  // Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Completar reto manualmente (para Reto 4)
  void completeChallenge(bool isCorrect) {
    _challengeCompleted = isCorrect;
    if (isCorrect) {
      _score++;
    }
    notifyListeners();
  }

  // ============ RETO 3: SELECCIÓN DE IMAGEN ============
  
  // Cargar 4 imágenes aleatorias (1 correcta + 3 distractores de temas diferentes)
  Future<void> loadImageOptions() async {
    try {
      final targetSubject = currentChallenge.targetSubject;
      final random = Random();
      
      // Mapeo completo de imágenes disponibles por tema
      final Map<String, List<String>> imageMap = {
        // Animales
        'gato': List.generate(3, (i) => 'lib/features/activities/activity3/images/gato_${i + 1}.jpg'),
        'perro': List.generate(3, (i) => 'lib/features/activities/activity3/images/perro_${i + 1}.jpg'),
        'burro': List.generate(3, (i) => 'lib/features/activities/activity3/images/burro_${i + 1}.jpg'),
        'caballo': List.generate(3, (i) => 'lib/features/activities/activity3/images/caballo_${i + 1}.jpg'),
        'cebra': List.generate(3, (i) => 'lib/features/activities/activity3/images/cebra_${i + 1}.jpg'),
        'leon': List.generate(3, (i) => 'lib/features/activities/activity3/images/leon_${i + 1}.jpg'),
        'tigre': List.generate(3, (i) => 'lib/features/activities/activity3/images/tigre_${i + 1}.jpg'),
        'elefante': List.generate(3, (i) => 'lib/features/activities/activity3/images/elefante_${i + 1}.jpg'),
        'jirafa': List.generate(3, (i) => 'lib/features/activities/activity3/images/jirafa_${i + 1}.jpg'),
        'mono': List.generate(3, (i) => 'lib/features/activities/activity3/images/mono_${i + 1}.jpg'),
        'oso': List.generate(3, (i) => 'lib/features/activities/activity3/images/oso_${i + 1}.jpg'),
        'lobo': List.generate(3, (i) => 'lib/features/activities/activity3/images/lobo_${i + 1}.jpg'),
        'cocodrilo': List.generate(3, (i) => 'lib/features/activities/activity3/images/cocodrilo_${i + 1}.jpg'),
        'conejo': List.generate(3, (i) => 'lib/features/activities/activity3/images/conejo_${i + 1}.jpg'),
        'vaca': List.generate(3, (i) => 'lib/features/activities/activity3/images/vaca_${i + 1}.jpg'),
        'oveja': List.generate(3, (i) => 'lib/features/activities/activity3/images/oveja_${i + 1}.jpg'),
        'gallina': List.generate(3, (i) => 'lib/features/activities/activity3/images/gallina_${i + 1}.jpg'),
        'rana': List.generate(3, (i) => 'lib/features/activities/activity3/images/rana_${i + 1}.png'),
        'mariposa': List.generate(3, (i) => 'lib/features/activities/activity3/images/mariposa_${i + 1}.png'),
        
        // Accidentes geográficos
        'montana': List.generate(3, (i) => 'lib/features/activities/activity3/images/montana_${i + 1}.jpg'),
        'glaciar': List.generate(3, (i) => 'lib/features/activities/activity3/images/glaciar_${i + 1}.jpg'),
        'desierto': List.generate(3, (i) => 'lib/features/activities/activity3/images/desierto_${i + 1}.jpg'),
        'isla': List.generate(3, (i) => 'lib/features/activities/activity3/images/isla_${i + 1}.jpg'),
        'volcan': ['lib/features/activities/activity3/images/volcan_1.png', 'lib/features/activities/activity3/images/volcan_2.jpg', 'lib/features/activities/activity3/images/volcan_3.jpg'],
        
        // Sistemas del cuerpo humano
        'circulatorio': List.generate(3, (i) => 'lib/features/activities/activity3/images/circulatorio_${i + 1}.png'),
        'digestivo': List.generate(3, (i) => 'lib/features/activities/activity3/images/digestivo_${i + 1}.png'),
        'respiratorio': List.generate(3, (i) => 'lib/features/activities/activity3/images/respiratorio_${i + 1}.png'),
        'locomotor': List.generate(3, (i) => 'lib/features/activities/activity3/images/locomotor_${i + 1}.png'),
        
        // Hábitos de higiene
        'cepillandose': List.generate(3, (i) => 'lib/features/activities/activity3/images/cepillandose_${i + 1}.png'),
        'lavandose_manos': List.generate(3, (i) => 'lib/features/activities/activity3/images/lavandose_manos_${i + 1}.png'),
        'peinandose': List.generate(3, (i) => 'lib/features/activities/activity3/images/peinandose_${i + 1}.png'),
        
        // Responsabilidades/Actividades diarias
        'cuidar_mascota': List.generate(3, (i) => 'lib/features/activities/activity3/images/cuidar_mascota_${i + 1}.png'),
        'regar_plantas': List.generate(3, (i) => 'lib/features/activities/activity3/images/regar_plantas_${i + 1}.png'),
        'sacar_basura': List.generate(3, (i) => 'lib/features/activities/activity3/images/sacar_basura_${i + 1}.png'),
        
        // Temas diversos
        'alimentacion': List.generate(3, (i) => 'lib/features/activities/activity3/images/alimentacion_${i + 1}.png'),
        'salud': List.generate(3, (i) => 'lib/features/activities/activity3/images/salud_${i + 1}.png'),
        'descanso': List.generate(3, (i) => 'lib/features/activities/activity3/images/descanso_${i + 1}.png'),
        'educacion': List.generate(3, (i) => 'lib/features/activities/activity3/images/educacion_${i + 1}.png'),
        'vivienda': List.generate(3, (i) => 'lib/features/activities/activity3/images/vivienda_${i + 1}.png'),
        'basilica': List.generate(3, (i) => 'lib/features/activities/activity3/images/basilica_${i + 1}.jpeg'),
        'cumple': List.generate(3, (i) => 'lib/features/activities/activity3/images/cumple_${i + 1}.png'),
        'navidad': List.generate(3, (i) => 'lib/features/activities/activity3/images/navidad_${i + 1}.png'),
      };
      
      // Obtener todas las categorías disponibles
      final availableSubjects = imageMap.keys.toList();
      
      // Seleccionar una imagen correcta aleatoria
      final correctImages = imageMap[targetSubject] ?? [];
      if (correctImages.isEmpty) {
        _errorMessage = 'No hay imágenes disponibles para: $targetSubject';
        notifyListeners();
        return;
      }
      
      final correctImage = correctImages[random.nextInt(correctImages.length)];
      
      // Seleccionar 3 temas diferentes para los distractores (sin repetir el tema correcto)
      final otherSubjects = availableSubjects.where((s) => s != targetSubject).toList();
      otherSubjects.shuffle(random);
      
      final distractorImages = <String>[];
      final usedSubjects = <String>{}; // Para asegurar que no se repitan temas
      
      // Seleccionar 3 distractores de 3 temas diferentes
      for (var subject in otherSubjects) {
        if (distractorImages.length >= 3) break;
        if (usedSubjects.contains(subject)) continue;
        
        final subjectImages = imageMap[subject] ?? [];
        if (subjectImages.isNotEmpty) {
          distractorImages.add(subjectImages[random.nextInt(subjectImages.length)]);
          usedSubjects.add(subject);
        }
      }
      
      // Si por alguna razón no tenemos suficientes distractores, completar con los disponibles
      if (distractorImages.length < 3) {
        _errorMessage = 'No hay suficientes imágenes diferentes para crear el reto';
        notifyListeners();
        return;
      }
      
      // Mezclar las 4 imágenes (1 correcta + 3 distractores de temas diferentes)
      _imageOptions = [correctImage, ...distractorImages]..shuffle(random);
      _correctImageIndex = _imageOptions.indexOf(correctImage);
      _selectedImageIndex = null;
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar imágenes: $e';
      if (kDebugMode) {
        print('Error loading images: $e');
      }
      notifyListeners();
    }
  }
  
  // Seleccionar imagen
  void selectImage(int index) {
    _selectedImageIndex = index;
    notifyListeners();
  }
  
  // Validar imagen seleccionada (convertir asset a File temporal)
  Future<void> validateSelectedImage() async {
    if (_selectedImageIndex == null) {
      _errorMessage = 'Por favor selecciona una imagen';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Cargar la imagen desde assets y convertirla a File temporal
      final selectedImagePath = _imageOptions[_selectedImageIndex!];
      
      // Leer bytes del asset
      final byteData = await rootBundle.load(selectedImagePath);
      
      // Crear archivo temporal
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());
      
      // Validar con el backend
      await validateChallenge(tempFile);
      
      // Limpiar archivo temporal
      await tempFile.delete();
    } catch (e) {
      _errorMessage = 'Error al validar imagen: $e';
      _challengeCompleted = false;
      if (kDebugMode) {
        print('Error validating selected image: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ RETO 4: COMPLETAR FRASE CON OPCIONES ============
  
  // Generar opciones de palabras (1 correcta + 3 distractores)
  void generateWordOptions(String description) {
    try {
      // Extraer una palabra significativa de la descripción
      final words = description.split(' ');
      final significantWords = words.where((w) => 
        w.length > 4 && 
        !['tiene', 'está', 'están', 'sobre', 'entre', 'junto', 'cerca'].contains(w.toLowerCase())
      ).toList();
      
      if (significantWords.isEmpty) {
        _errorMessage = 'No se pudo generar opciones de palabras';
        notifyListeners();
        return;
      }
      
      // Seleccionar una palabra aleatoria como correcta
      final random = Random();
      _correctWord = significantWords[random.nextInt(significantWords.length)].toLowerCase();
      
      // Lista de distractores comunes
      final distractors = [
        'perro', 'casa', 'árbol', 'mesa', 'silla', 'puerta', 'ventana',
        'coche', 'libro', 'teléfono', 'computadora', 'jardín', 'parque',
        'calle', 'ciudad', 'montaña', 'río', 'bosque', 'playa', 'cielo',
        'comida', 'agua', 'persona', 'niño', 'familia', 'amigo', 'escuela'
      ];
      
      // Seleccionar 3 distractores que no sean la palabra correcta
      final selectedDistractors = <String>[];
      final availableDistractors = distractors.where((d) => d != _correctWord).toList();
      
      while (selectedDistractors.length < 3 && availableDistractors.isNotEmpty) {
        final distractor = availableDistractors[random.nextInt(availableDistractors.length)];
        if (!selectedDistractors.contains(distractor)) {
          selectedDistractors.add(distractor);
        }
        availableDistractors.remove(distractor);
      }
      
      // Mezclar opciones
      _wordOptions = [_correctWord, ...selectedDistractors]..shuffle(random);
      _selectedWordIndex = null;
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al generar opciones: $e';
      if (kDebugMode) {
        print('Error generating word options: $e');
      }
      notifyListeners();
    }
  }
  
  // Seleccionar palabra
  void selectWord(int index) {
    _selectedWordIndex = index;
    notifyListeners();
  }
  
  // Validar palabra seleccionada
  void validateSelectedWord() {
    if (_selectedWordIndex == null) {
      _errorMessage = 'Por favor selecciona una palabra';
      notifyListeners();
      return;
    }
    
    final selectedWord = _wordOptions[_selectedWordIndex!];
    final isCorrect = selectedWord.toLowerCase() == _correctWord.toLowerCase();
    
    _challengeCompleted = isCorrect;
    if (isCorrect) {
      _score++;
    }
    
    notifyListeners();
  }
}
