class CharacteristicData {
  final String category;
  final List<String> images;
  final List<String> characteristics;

  CharacteristicData({
    required this.category,
    required this.images,
    required this.characteristics,
  });

  factory CharacteristicData.fromJson(String category, Map<String, dynamic> json) {
    return CharacteristicData(
      category: category,
      images: List<String>.from(json['images']),
      characteristics: List<String>.from(json['characteristics']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'images': images,
      'characteristics': characteristics,
    };
  }
}
