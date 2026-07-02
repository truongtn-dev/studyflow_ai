class Course {
  final int? id;
  final int userId;
  final String name;
  final String? code;
  final String color;
  final String createdAt;

  const Course({
    this.id,
    required this.userId,
    required this.name,
    this.code,
    this.color = '#5B5FEF',
    this.createdAt = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'code': code,
        'color': color,
        'created_at': createdAt,
      };

  factory Course.fromMap(Map<String, dynamic> map) => Course(
        id: map['id'] as int?,
        userId: map['user_id'] as int? ?? 0,
        name: map['name'] as String? ?? '',
        code: map['code'] as String?,
        color: map['color'] as String? ?? '#5B5FEF',
        createdAt: map['created_at'] as String? ?? '',
      );

  Course copyWith({
    int? id,
    int? userId,
    String? name,
    String? code,
    String? color,
    String? createdAt,
  }) =>
      Course(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        code: code ?? this.code,
        color: color ?? this.color,
        createdAt: createdAt ?? this.createdAt,
      );
}
