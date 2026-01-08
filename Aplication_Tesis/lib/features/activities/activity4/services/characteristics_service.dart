import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/characteristic_data.dart';

class CharacteristicsService {
  static final CharacteristicsService _instance = CharacteristicsService._internal();
  factory CharacteristicsService() => _instance;
  CharacteristicsService._internal();

  Map<String, CharacteristicData>? _data;
  final Random _random = Random();

  /// Carga los datos del JSON
  Future<void> loadData() async {
    if (_data != null) return; // Ya cargado

    final String jsonString = await rootBundle.loadString(
      'lib/features/activities/activity4/data/characteristics_data.json',
    );
    
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    
    _data = {};
    jsonData.forEach((key, value) {
      _data![key] = CharacteristicData.fromJson(key, value);
    });
  }

  /// Obtiene una imagen aleatoria y sus datos
  Future<Map<String, dynamic>> getRandomImageWithCharacteristics() async {
    await loadData();
    
    if (_data == null || _data!.isEmpty) {
      throw Exception('No hay datos cargados');
    }

    // Seleccionar categoría aleatoria
    final categories = _data!.keys.toList();
    final randomCategory = categories[_random.nextInt(categories.length)];
    final categoryData = _data![randomCategory]!;

    // Seleccionar imagen aleatoria de esa categoría
    final randomImage = categoryData.images[_random.nextInt(categoryData.images.length)];

    // Obtener características correctas (máximo 2)
    final correctCharacteristics = _getRandomCharacteristics(
      categoryData.characteristics,
      min: 2,
      max: 2,
    );

    // Obtener características incorrectas de otras categorías (máximo 2)
    final incorrectCharacteristics = _getIncorrectCharacteristics(
      randomCategory,
      count: 2,
    );

    // Mezclar correctas e incorrectas
    final allOptions = [...correctCharacteristics, ...incorrectCharacteristics];
    allOptions.shuffle(_random);

    return {
      'category': randomCategory,
      'image': randomImage,
      'correctCharacteristics': correctCharacteristics,
      'allOptions': allOptions,
    };
  }

  /// Obtiene características aleatorias de una lista
  List<String> _getRandomCharacteristics(List<String> characteristics, {required int min, required int max}) {
    if (characteristics.length <= max) {
      return List.from(characteristics);
    }

    final shuffled = List<String>.from(characteristics)..shuffle(_random);
    final count = min + _random.nextInt(max - min + 1);
    return shuffled.take(count).toList();
  }

  /// Obtiene características incorrectas de otras categorías
  List<String> _getIncorrectCharacteristics(String currentCategory, {required int count}) {
    final incorrectOptions = <String>[];
    final otherCategories = _data!.keys.where((key) => key != currentCategory).toList();

    while (incorrectOptions.length < count && otherCategories.isNotEmpty) {
      final randomCategory = otherCategories[_random.nextInt(otherCategories.length)];
      final categoryData = _data![randomCategory]!;
      
      if (categoryData.characteristics.isNotEmpty) {
        final randomChar = categoryData.characteristics[
          _random.nextInt(categoryData.characteristics.length)
        ];
        
        if (!incorrectOptions.contains(randomChar)) {
          incorrectOptions.add(randomChar);
        }
      }
    }

    return incorrectOptions;
  }

  /// Verifica si una característica es correcta
  bool isCorrectCharacteristic(String category, String characteristic) {
    if (_data == null || !_data!.containsKey(category)) {
      return false;
    }

    return _data![category]!.characteristics.contains(characteristic);
  }

  /// Obtiene todas las categorías disponibles
  List<String> getCategories() {
    return _data?.keys.toList() ?? [];
  }

  /// Obtiene datos de una categoría específica
  CharacteristicData? getCategoryData(String category) {
    return _data?[category];
  }
}
