import '../db/database_helper.dart';
import '../models/ai_note.dart';

class AiNoteRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> insert(AiNote note) async {
    final database = await _db.database;
    final map = note.toMap()..remove('id');
    final now = DateTime.now().toIso8601String();
    if ((map['created_at'] as String?)?.isEmpty ?? true) {
      map['created_at'] = now;
    }
    if ((map['updated_at'] as String?)?.isEmpty ?? true) {
      map['updated_at'] = now;
    }
    return database.insert('ai_notes', map);
  }

  Future<int> update(AiNote note) async {
    final database = await _db.database;
    final map = note.toMap()..remove('id');
    map['updated_at'] = DateTime.now().toIso8601String();
    return database.update(
      'ai_notes',
      map,
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> delete(int id) async {
    final database = await _db.database;
    return database.delete('ai_notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<AiNote?> getById(int id) async {
    final database = await _db.database;
    final maps = await database.query(
      'ai_notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AiNote.fromMap(maps.first);
  }

  Future<List<AiNote>> getByUserId(
    int userId, {
    int? courseId,
    String? query,
  }) async {
    final database = await _db.database;
    final where = StringBuffer('user_id = ?');
    final args = <Object?>[userId];

    if (courseId != null) {
      where.write(' AND course_id = ?');
      args.add(courseId);
    }
    if (query != null && query.trim().isNotEmpty) {
      where.write(' AND (title LIKE ? OR content LIKE ? OR tags LIKE ?)');
      final q = '%${query.trim()}%';
      args.addAll([q, q, q]);
    }

    final maps = await database.query(
      'ai_notes',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    return maps.map(AiNote.fromMap).toList();
  }

  Future<int> countByUserId(int userId) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM ai_notes WHERE user_id = ?',
      [userId],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<void> togglePin(AiNote note) async {
    await update(note.copyWith(isPinned: !note.isPinned));
  }
}
