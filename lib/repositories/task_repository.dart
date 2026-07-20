import '../db/database_helper.dart';
import '../models/task.dart';

class TaskRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> countByUserId(int userId) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE user_id = ?',
      [userId],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<List<Task>> getByUserId(int userId) async {
    final database = await _db.database;
    final maps = await database.query(
      'tasks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'deadline ASC',
    );
    return maps.map(Task.fromMap).toList();
  }

  Future<void> seedDemoTasks(int userId) async {
    final count = await countByUserId(userId);
    if (count >= 3) return;

    final database = await _db.database;
    final courses = await database.query(
      'courses',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 3,
    );
    if (courses.isEmpty) return;

    final now = DateTime.now();
    final demos = [
      {
        'user_id': userId,
        'course_id': courses[0]['id'],
        'title': 'Hoàn thành lab SQLite',
        'description': 'CRUD notes app',
        'deadline': now.add(const Duration(days: 3)).toIso8601String(),
        'status': 'doing',
        'priority': 'high',
        'progress': 60,
      },
      {
        'user_id': userId,
        'course_id': courses.length > 1 ? courses[1]['id'] : courses[0]['id'],
        'title': 'Ôn thi Progress Test 2',
        'description': 'Async, Provider, API',
        'deadline': now.add(const Duration(days: 5)).toIso8601String(),
        'status': 'todo',
        'priority': 'medium',
        'progress': 0,
      },
      {
        'user_id': userId,
        'course_id': courses.length > 2 ? courses[2]['id'] : courses[0]['id'],
        'title': 'Nộp project PRM393',
        'description': 'Flutter + SQLite + AI',
        'deadline': now.add(const Duration(days: 14)).toIso8601String(),
        'status': 'todo',
        'priority': 'high',
        'progress': 10,
      },
    ];

    for (final task in demos) {
      await database.insert('tasks', task);
    }
  }
  Future<int> insert(Task task) async {
    final deadline = DateTime.tryParse(task.deadline);
    if (deadline != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final day = DateTime(deadline.year, deadline.month, deadline.day);
      if (day.isBefore(today) && task.status != TaskStatus.overdue) {
        throw StateError('Deadline không được ở quá khứ (BR-02).');
      }
    }
    final database = await _db.database;
    final map = task.toMap()..remove('id');
    if ((map['created_at'] as String?)?.isEmpty ?? true) {
      map.remove('created_at');
    }
    return database.insert('tasks', map);
  }

  Future<int> update(Task task) async {
    final deadline = DateTime.tryParse(task.deadline);
    if (deadline != null &&
        task.status != TaskStatus.overdue &&
        task.status != TaskStatus.done) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final day = DateTime(deadline.year, deadline.month, deadline.day);
      if (day.isBefore(today)) {
        throw StateError('Deadline không được ở quá khứ (BR-02).');
      }
    }
    final database = await _db.database;
    final map = task.toMap()..remove('id');
    return database.update(
      'tasks',
      map,
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> delete(int id) async {
    final database = await _db.database;
    await database.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<Task?> getById(int taskId) async {
    final database = await _db.database;
    final maps = await database.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  /// Mark past-deadline incomplete tasks as overdue (BR-01).
  Future<int> syncOverdue(int userId) async {
    final database = await _db.database;
    final now = DateTime.now().toIso8601String();
    return database.rawUpdate(
      '''
      UPDATE tasks
      SET status = 'overdue'
      WHERE user_id = ?
        AND status IN ('todo', 'doing')
        AND deadline < ?
      ''',
      [userId, now],
    );
  }

  Future<List<Task>> getOverdue(int userId) async {
    await syncOverdue(userId);
    final database = await _db.database;
    final maps = await database.query(
      'tasks',
      where: "user_id = ? AND status = 'overdue'",
      whereArgs: [userId],
      orderBy: 'deadline ASC',
    );
    return maps.map(Task.fromMap).toList();
  }
}
