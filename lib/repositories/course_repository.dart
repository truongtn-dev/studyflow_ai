import '../db/database_helper.dart';
import '../models/course.dart';

class CourseRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> insert(Course course) async {
    final database = await _db.database;
    return database.insert('courses', course.toMap());
  }

  Future<int> update(Course course) async {
    final database = await _db.database;
    return database.update(
      'courses',
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  Future<int> delete(int id) async {
    final database = await _db.database;
    final activeTasks = await database.rawQuery(
      '''
      SELECT COUNT(*) as count FROM tasks
      WHERE course_id = ? AND status NOT IN ('done')
      ''',
      [id],
    );
    final count = activeTasks.first['count'] as int? ?? 0;
    if (count > 0) {
      throw StateError('Không thể xóa môn đang có task chưa hoàn thành');
    }
    return database.delete('courses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Course>> getByUserId(int userId) async {
    final database = await _db.database;
    final maps = await database.query(
      'courses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return maps.map(Course.fromMap).toList();
  }

  Future<Course?> getById(int id) async {
    final database = await _db.database;
    final maps = await database.query(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Course.fromMap(maps.first);
  }

  Future<void> seedDemoCourses(int userId) async {
    final existing = await getByUserId(userId);
    if (existing.isNotEmpty) return;

    final demos = [
      Course(userId: userId, name: 'Mobile Programming', code: 'PRM393', color: '#5B5FEF'),
      Course(userId: userId, name: 'Programming Fundamentals', code: 'PRO192', color: '#0D9488'),
      Course(userId: userId, name: 'Math for Engineering', code: 'MAE101', color: '#F59E0B'),
    ];
    for (final course in demos) {
      await insert(course);
    }
  }
}
