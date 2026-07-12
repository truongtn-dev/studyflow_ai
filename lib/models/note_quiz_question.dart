/// In-memory quiz item generated from an AI note (not flashcard / SRS).
class NoteQuizQuestion {
  const NoteQuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation = '',
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  factory NoteQuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List?) ?? const [];
    final options = rawOptions.map((e) => e.toString()).toList();
    while (options.length < 4) {
      options.add('—');
    }
    final idx = (json['correctIndex'] as num?)?.toInt() ?? 0;
    return NoteQuizQuestion(
      question: json['question']?.toString() ?? '',
      options: options.take(4).toList(),
      correctIndex: idx.clamp(0, 3),
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}
