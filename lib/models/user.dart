class User {
  final int? id;
  final String email;
  final String password;
  final String name;
  final int streak;
  final int xp;
  final String createdAt;

  const User({
    this.id,
    required this.email,
    required this.password,
    required this.name,
    this.streak = 0,
    this.xp = 0,
    this.createdAt = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'password': password,
        'name': name,
        'streak': streak,
        'xp': xp,
        'created_at': createdAt,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] as int?,
        email: map['email'] as String? ?? '',
        password: map['password'] as String? ?? '',
        name: map['name'] as String? ?? '',
        streak: map['streak'] as int? ?? 0,
        xp: map['xp'] as int? ?? 0,
        createdAt: map['created_at'] as String? ?? '',
      );

  User copyWith({
    int? id,
    String? email,
    String? password,
    String? name,
    int? streak,
    int? xp,
    String? createdAt,
  }) =>
      User(
        id: id ?? this.id,
        email: email ?? this.email,
        password: password ?? this.password,
        name: name ?? this.name,
        streak: streak ?? this.streak,
        xp: xp ?? this.xp,
        createdAt: createdAt ?? this.createdAt,
      );
}
