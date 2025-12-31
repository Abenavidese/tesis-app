class Challenge {
  final int number;
  final String title;
  final String description;
  final String targetSubject;
  final ChallengeType type;

  Challenge({
    required this.number,
    required this.title,
    required this.description,
    required this.targetSubject,
    required this.type,
  });
}

enum ChallengeType {
  selection,  // Reto 1: Selección con foto propia
  quickCapture,  // Reto 2: Captura rápida con timer
  imageSelection,  // Reto 3: Selección desde imágenes precargadas
  completeSentence,  // Reto 4: Completar frases con opciones
}
