import '../db/database_helper.dart';
import '../models/flashcard.dart';

class FlashcardRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> insert(Flashcard card) async {
    final database = await _db.database;
    final map = card.toMap()..remove('id');
    if ((map['created_at'] as String?)?.isEmpty ?? true) {
      map.remove('created_at');
    }
    if ((map['next_review'] as String?) == null ||
        (map['next_review'] as String).isEmpty) {
      map['next_review'] = DateTime.now().toIso8601String();
    }
    return database.insert('flashcards', map);
  }

  Future<int> update(Flashcard card) async {
    final database = await _db.database;
    return database.update(
      'flashcards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> delete(int id) async {
    final database = await _db.database;
    return database.delete('flashcards', where: 'id = ?', whereArgs: [id]);
  }

  Future<Flashcard?> getById(int id) async {
    final database = await _db.database;
    final maps = await database.query(
      'flashcards',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Flashcard.fromMap(maps.first);
  }

  Future<List<Flashcard>> getByUserId(int userId, {int? courseId}) async {
    final database = await _db.database;
    final maps = await database.query(
      'flashcards',
      where: courseId == null ? 'user_id = ?' : 'user_id = ? AND course_id = ?',
      whereArgs: courseId == null ? [userId] : [userId, courseId],
      orderBy: 'created_at DESC',
    );
    return maps.map(Flashcard.fromMap).toList();
  }

  Future<List<Flashcard>> getDue(int userId) async {
    final database = await _db.database;
    final now = DateTime.now().toIso8601String();
    final maps = await database.query(
      'flashcards',
      where: 'user_id = ? AND (next_review IS NULL OR next_review <= ?)',
      whereArgs: [userId, now],
      orderBy: 'next_review ASC',
    );
    return maps.map(Flashcard.fromMap).toList();
  }

  Future<int> countByUserId(int userId) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM flashcards WHERE user_id = ?',
      [userId],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<int> countByCourseId(int courseId) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM flashcards WHERE course_id = ?',
      [courseId],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<void> logReview({
    required int flashcardId,
    required bool correct,
  }) async {
    final database = await _db.database;
    await database.insert('srs_reviews', {
      'flashcard_id': flashcardId,
      'correct': correct ? 1 : 0,
    });
  }
}
