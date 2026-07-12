class Achievement {
  final int? id;
  final int userId;
  final String badgeCode;
  final String earnedAt;

  const Achievement({
    this.id,
    required this.userId,
    required this.badgeCode,
    this.earnedAt = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'badge_code': badgeCode,
        'earned_at': earnedAt,
      };

  factory Achievement.fromMap(Map<String, dynamic> map) => Achievement(
        id: map['id'] as int?,
        userId: map['user_id'] as int? ?? 0,
        badgeCode: map['badge_code'] as String? ?? '',
        earnedAt: map['earned_at'] as String? ?? '',
      );
}

class BadgeDef {
  final String code;
  final String title;
  final String description;
  final IconDataProxy icon;

  const BadgeDef({
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Avoid importing Flutter in model layer for icon codes.
enum IconDataProxy {
  fire,
  star,
  task,
  style,
  timer,
  school,
}

abstract final class BadgeCatalog {
  static const all = <BadgeDef>[
    BadgeDef(
      code: 'first_login',
      title: 'Bắt đầu hành trình',
      description: 'Đăng nhập lần đầu',
      icon: IconDataProxy.school,
    ),
    BadgeDef(
      code: 'first_task',
      title: 'Task đầu tiên',
      description: 'Hoàn thành 1 task',
      icon: IconDataProxy.task,
    ),
    BadgeDef(
      code: 'tasks_10',
      title: 'Task hunter',
      description: 'Hoàn thành 10 task',
      icon: IconDataProxy.task,
    ),
    BadgeDef(
      code: 'streak_3',
      title: 'Streak 3 ngày',
      description: 'Duy trì học 3 ngày liên tiếp',
      icon: IconDataProxy.fire,
    ),
    BadgeDef(
      code: 'streak_7',
      title: 'Streak 7 ngày',
      description: 'Duy trì học 7 ngày liên tiếp',
      icon: IconDataProxy.fire,
    ),
    BadgeDef(
      code: 'cards_10',
      title: 'Flashcard starter',
      description: 'Tạo 10 flashcard',
      icon: IconDataProxy.style,
    ),
    BadgeDef(
      code: 'first_pomodoro',
      title: 'Focus đầu tiên',
      description: 'Hoàn thành 1 phiên Pomodoro',
      icon: IconDataProxy.timer,
    ),
    BadgeDef(
      code: 'study_60',
      title: 'Học 60 phút',
      description: 'Tổng thời gian học ≥ 60 phút',
      icon: IconDataProxy.star,
    ),
  ];

  static BadgeDef? byCode(String code) {
    for (final b in all) {
      if (b.code == code) return b;
    }
    return null;
  }
}
