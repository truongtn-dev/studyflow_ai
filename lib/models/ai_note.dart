class AiNote {
  final int? id;
  final int userId;
  final int? courseId;
  final String title;
  final String content;
  final String source;
  final String tags;
  final bool isPinned;
  final String createdAt;
  final String updatedAt;

  const AiNote({
    this.id,
    required this.userId,
    this.courseId,
    required this.title,
    required this.content,
    this.source = 'manual',
    this.tags = '',
    this.isPinned = false,
    this.createdAt = '',
    this.updatedAt = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'course_id': courseId,
        'title': title,
        'content': content,
        'source': source,
        'tags': tags,
        'is_pinned': isPinned ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory AiNote.fromMap(Map<String, dynamic> map) => AiNote(
        id: map['id'] as int?,
        userId: map['user_id'] as int? ?? 0,
        courseId: map['course_id'] as int?,
        title: map['title'] as String? ?? '',
        content: map['content'] as String? ?? '',
        source: map['source'] as String? ?? 'manual',
        tags: map['tags'] as String? ?? '',
        isPinned: (map['is_pinned'] as int? ?? 0) == 1,
        createdAt: map['created_at'] as String? ?? '',
        updatedAt: map['updated_at'] as String? ?? '',
      );

  AiNote copyWith({
    int? id,
    int? userId,
    int? courseId,
    String? title,
    String? content,
    String? source,
    String? tags,
    bool? isPinned,
    String? createdAt,
    String? updatedAt,
    bool clearCourseId = false,
  }) =>
      AiNote(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        courseId: clearCourseId ? null : (courseId ?? this.courseId),
        title: title ?? this.title,
        content: content ?? this.content,
        source: source ?? this.source,
        tags: tags ?? this.tags,
        isPinned: isPinned ?? this.isPinned,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
