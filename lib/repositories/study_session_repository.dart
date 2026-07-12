import '../db/database_helper.dart';
import '../models/study_session.dart';

class StudySessionRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> insert(StudySession session) async {
    final database = await _db.database;
    final map = session.toMap()..remove('id');
    return database.insert('study_sessions', map);
  }

  Future<List<StudySession>> getByUserId(int userId) async {
    final database = await _db.database;
    final maps = await database.query(
      'study_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'started_at DESC',
    );
    return maps.map(StudySession.fromMap).toList();
  }

  Future<int> totalMinutesToday(int userId) async {
    final database = await _db.database;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).toIso8601String();
    final result = await database.rawQuery(
      '''
      SELECT COALESCE(SUM(duration_min), 0) as total
      FROM study_sessions
      WHERE user_id = ? AND started_at >= ?
      ''',
      [userId, start],
    );
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<int> totalMinutesAll(int userId) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      '''
      SELECT COALESCE(SUM(duration_min), 0) as total
      FROM study_sessions
      WHERE user_id = ?
      ''',
      [userId],
    );
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<int> sessionCount(int userId) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM study_sessions WHERE user_id = ?',
      [userId],
    );
    return result.first['count'] as int? ?? 0;
  }

  /// Returns map of day (yyyy-MM-dd) -> minutes for last [days] days.
  Future<Map<String, int>> minutesByDay(int userId, {int days = 30}) async {
    final database = await _db.database;
    final start = DateTime.now()
        .subtract(Duration(days: days - 1))
        .toIso8601String();
    final rows = await database.rawQuery(
      '''
      SELECT substr(started_at, 1, 10) as day,
             SUM(duration_min) as total
      FROM study_sessions
      WHERE user_id = ? AND started_at >= ?
      GROUP BY day
      ORDER BY day ASC
      ''',
      [userId, start],
    );
    return {
      for (final row in rows)
        row['day'] as String: (row['total'] as num?)?.toInt() ?? 0,
    };
  }
}
