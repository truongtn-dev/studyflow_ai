import '../db/database_helper.dart';
import '../models/ai_cache_entry.dart';

class AiCacheRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  static String hashPrompt(String promptType, String content) {
    return '$promptType::${content.hashCode}';
  }

  Future<int> insert(AiCacheEntry entry) async {
    final database = await _db.database;
    return database.insert('ai_cache', entry.toMap());
  }

  Future<AiCacheEntry?> findByHash({
    required int userId,
    required String promptType,
    required String promptHash,
  }) async {
    final database = await _db.database;
    final maps = await database.query(
      'ai_cache',
      where: 'user_id = ? AND prompt_type = ? AND prompt_hash = ?',
      whereArgs: [userId, promptType, promptHash],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AiCacheEntry.fromMap(maps.first);
  }

  Future<List<AiCacheEntry>> getHistory(int userId) async {
    final database = await _db.database;
    final maps = await database.query(
      'ai_cache',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map(AiCacheEntry.fromMap).toList();
  }

  Future<void> clearHistory(int userId) async {
    final database = await _db.database;
    await database.delete('ai_cache', where: 'user_id = ?', whereArgs: [userId]);
  }
}
