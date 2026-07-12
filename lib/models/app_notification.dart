class AppNotification {
  final int? id;
  final int userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String createdAt;

  const AppNotification({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = 'info',
    this.isRead = false,
    this.createdAt = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'is_read': isRead ? 1 : 0,
        'created_at': createdAt,
      };

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id: map['id'] as int?,
        userId: map['user_id'] as int? ?? 0,
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        type: map['type'] as String? ?? 'info',
        isRead: (map['is_read'] as int? ?? 0) == 1,
        createdAt: map['created_at'] as String? ?? '',
      );
}
