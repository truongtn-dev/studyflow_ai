class StudySession {
  final int? id;
  final int userId;
  final int? courseId;
  final int durationMin;
  final String type;
  final String startedAt;
  final String endedAt;

  const StudySession({
    this.id,
    required this.userId,
    this.courseId,
    required this.durationMin,
    this.type = 'pomodoro',
    required this.startedAt,
    required this.endedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'course_id': courseId,
        'duration_min': durationMin,
        'type': type,
        'started_at': startedAt,
        'ended_at': endedAt,
      };

  factory StudySession.fromMap(Map<String, dynamic> map) => StudySession(
        id: map['id'] as int?,
        userId: map['user_id'] as int? ?? 0,
        courseId: map['course_id'] as int?,
        durationMin: map['duration_min'] as int? ?? 0,
        type: map['type'] as String? ?? 'pomodoro',
        startedAt: map['started_at'] as String? ?? '',
        endedAt: map['ended_at'] as String? ?? '',
      );
}
