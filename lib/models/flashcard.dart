class Flashcard {
  final int? id;
  final int userId;
  final int? courseId;
  final String front;
  final String back;
  final bool mastered;
  final int intervalDays;
  final double easeFactor;
  final int reviewCount;
  final String? nextReview;
  final String createdAt;

  const Flashcard({
    this.id,
    required this.userId,
    this.courseId,
    required this.front,
    required this.back,
    this.mastered = false,
    this.intervalDays = 1,
    this.easeFactor = 2.5,
    this.reviewCount = 0,
    this.nextReview,
    this.createdAt = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'course_id': courseId,
        'front': front,
        'back': back,
        'mastered': mastered ? 1 : 0,
        'interval_days': intervalDays,
        'ease_factor': easeFactor,
        'review_count': reviewCount,
        'next_review': nextReview,
        'created_at': createdAt,
      };

  factory Flashcard.fromMap(Map<String, dynamic> map) => Flashcard(
        id: map['id'] as int?,
        userId: map['user_id'] as int? ?? 0,
        courseId: map['course_id'] as int?,
        front: map['front'] as String? ?? '',
        back: map['back'] as String? ?? '',
        mastered: (map['mastered'] as int? ?? 0) == 1,
        intervalDays: map['interval_days'] as int? ?? 1,
        easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,
        reviewCount: map['review_count'] as int? ?? 0,
        nextReview: map['next_review'] as String?,
        createdAt: map['created_at'] as String? ?? '',
      );

  Flashcard copyWith({
    int? id,
    int? userId,
    int? courseId,
    String? front,
    String? back,
    bool? mastered,
    int? intervalDays,
    double? easeFactor,
    int? reviewCount,
    String? nextReview,
    String? createdAt,
    bool clearCourseId = false,
    bool clearNextReview = false,
  }) =>
      Flashcard(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        courseId: clearCourseId ? null : (courseId ?? this.courseId),
        front: front ?? this.front,
        back: back ?? this.back,
        mastered: mastered ?? this.mastered,
        intervalDays: intervalDays ?? this.intervalDays,
        easeFactor: easeFactor ?? this.easeFactor,
        reviewCount: reviewCount ?? this.reviewCount,
        nextReview: clearNextReview ? null : (nextReview ?? this.nextReview),
        createdAt: createdAt ?? this.createdAt,
      );
}
