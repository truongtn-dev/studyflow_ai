class AiCacheEntry {
  final int? id;
  final int userId;
  final String promptType;
  final String promptHash;
  final String prompt;
  final String response;
  final String createdAt;

  const AiCacheEntry({
    this.id,
    required this.userId,
    required this.promptType,
    required this.promptHash,
    this.prompt = '',
    required this.response,
    this.createdAt = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'prompt_type': promptType,
        'prompt_hash': promptHash,
        'response': response,
        'created_at': createdAt,
      };

  factory AiCacheEntry.fromMap(Map<String, dynamic> map) => AiCacheEntry(
        id: map['id'] as int?,
        userId: map['user_id'] as int? ?? 0,
        promptType: map['prompt_type'] as String? ?? '',
        promptHash: map['prompt_hash'] as String? ?? '',
        response: map['response'] as String? ?? '',
        createdAt: map['created_at'] as String? ?? '',
      );
}
