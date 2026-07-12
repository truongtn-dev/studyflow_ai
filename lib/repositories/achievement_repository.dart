import '../db/database_helper.dart';
import '../models/achievement.dart';

class AchievementRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<Achievement>> getByUserId(int userId) async {
    final database = await _db.database;
    final maps = await database.query(
      'achievements',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'earned_at DESC',
    );
    return maps.map(Achievement.fromMap).toList();
  }

  Future<bool> hasBadge(int userId, String badgeCode) async {
    final database = await _db.database;
    final maps = await database.query(
      'achievements',
      where: 'user_id = ? AND badge_code = ?',
      whereArgs: [userId, badgeCode],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<bool> unlock(int userId, String badgeCode) async {
    if (await hasBadge(userId, badgeCode)) return false;
    final database = await _db.database;
    await database.insert('achievements', {
      'user_id': userId,
      'badge_code': badgeCode,
    });
    return true;
  }
}
