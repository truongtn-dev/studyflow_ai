import '../db/database_helper.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> insert(AppNotification notification) async {
    final database = await _db.database;
    final map = notification.toMap()..remove('id');
    if ((map['created_at'] as String?)?.isEmpty ?? true) {
      map.remove('created_at');
    }
    return database.insert('notifications', map);
  }

  Future<List<AppNotification>> getByUserId(int userId) async {
    final database = await _db.database;
    final maps = await database.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map(AppNotification.fromMap).toList();
  }

  Future<int> unreadCount(int userId) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0',
      [userId],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<void> markRead(int id) async {
    final database = await _db.database;
    await database.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllRead(int userId) async {
    final database = await _db.database;
    await database.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> delete(int id) async {
    final database = await _db.database;
    await database.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }
}
