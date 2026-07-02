enum TaskStatus { todo, doing, done, overdue }

enum TaskPriority { low, medium, high }

class Task {
  final int? id;
  final int userId;
  final int? courseId;
  final String title;
  final String? description;
  final String deadline;
  final TaskStatus status;
  final TaskPriority priority;
  final int progress;
  final String createdAt;

  const Task({
    this.id,
    required this.userId,
    this.courseId,
    required this.title,
    this.description,
    required this.deadline,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.progress = 0,
    this.createdAt = '',
  });

  static TaskStatus statusFromString(String? value) => TaskStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => TaskStatus.todo,
      );

  static TaskPriority priorityFromString(String? value) =>
      TaskPriority.values.firstWhere(
        (e) => e.name == value,
        orElse: () => TaskPriority.medium,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'course_id': courseId,
        'title': title,
        'description': description,
        'deadline': deadline,
        'status': status.name,
        'priority': priority.name,
        'progress': progress,
        'created_at': createdAt,
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'] as int?,
        userId: map['user_id'] as int? ?? 0,
        courseId: map['course_id'] as int?,
        title: map['title'] as String? ?? '',
        description: map['description'] as String?,
        deadline: map['deadline'] as String? ?? '',
        status: statusFromString(map['status'] as String?),
        priority: priorityFromString(map['priority'] as String?),
        progress: map['progress'] as int? ?? 0,
        createdAt: map['created_at'] as String? ?? '',
      );
}
