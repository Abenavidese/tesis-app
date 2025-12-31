class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['pregunta'] ?? '',
      options: List<String>.from(json['opciones'] ?? []),
      correctAnswerIndex: json['respuesta_correcta'] ?? 0,
    );
  }

  String get correctAnswer => options[correctAnswerIndex];
}
