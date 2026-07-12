import 'dart:convert';

import '../db/database_helper.dart';
import '../models/ai_note.dart';
import '../models/app_notification.dart';
import '../models/course.dart';
import '../models/flashcard.dart';
import '../models/study_session.dart';
import '../models/task.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/ai_note_repository.dart';
import '../repositories/course_repository.dart';
import '../repositories/flashcard_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/study_session_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/user_repository.dart';

class BackupRestoreService {
  final _db = DatabaseHelper.instance;
  final _users = UserRepository();
  final _courses = CourseRepository();
  final _tasks = TaskRepository();
  final _cards = FlashcardRepository();
  final _sessions = StudySessionRepository();
  final _achievements = AchievementRepository();
  final _notifications = NotificationRepository();
  final _aiNotes = AiNoteRepository();

  Future<String> exportJson(int userId) async {
    final user = await _users.findById(userId);
    if (user == null) throw StateError('User not found');

    final courses = await _courses.getByUserId(userId);
    final tasks = await _tasks.getByUserId(userId);
    final cards = await _cards.getByUserId(userId);
    final sessions = await _sessions.getByUserId(userId);
    final achievements = await _achievements.getByUserId(userId);
    final notifications = await _notifications.getByUserId(userId);
    final aiNotes = await _aiNotes.getByUserId(userId);

    final payload = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'user': {
        'email': user.email,
        'name': user.name,
        'streak': user.streak,
        'xp': user.xp,
      },
      'courses': courses.map((c) => c.toMap()).toList(),
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'flashcards': cards.map((c) => c.toMap()).toList(),
      'study_sessions': sessions.map((s) => s.toMap()).toList(),
      'achievements':
          achievements.map((a) => {'badge_code': a.badgeCode}).toList(),
      'notifications': notifications.map((n) => n.toMap()).toList(),
      'ai_notes': aiNotes.map((n) => n.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> importJson(int userId, String json) async {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final database = await _db.database;

    await database.execute('PRAGMA foreign_keys = OFF');
    try {
      await database.transaction((txn) async {
        await txn.rawDelete(
          'DELETE FROM srs_reviews WHERE flashcard_id IN (SELECT id FROM flashcards WHERE user_id = ?)',
          [userId],
        );
        await txn.delete('flashcards', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('tasks', where: 'user_id = ?', whereArgs: [userId]);
        await txn
            .delete('study_sessions', where: 'user_id = ?', whereArgs: [userId]);
        await txn
            .delete('achievements', where: 'user_id = ?', whereArgs: [userId]);
        await txn
            .delete('notifications', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('ai_notes', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('ai_cache', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('courses', where: 'user_id = ?', whereArgs: [userId]);
      });

      final userMap = decoded['user'] as Map<String, dynamic>?;
      if (userMap != null) {
        final current = await _users.findById(userId);
        if (current != null) {
          await _users.update(
            current.copyWith(
              name: userMap['name'] as String? ?? current.name,
              streak: userMap['streak'] as int? ?? current.streak,
              xp: userMap['xp'] as int? ?? current.xp,
            ),
          );
        }
      }

      final oldCourseIdToNew = <int, int>{};
      for (final raw in (decoded['courses'] as List? ?? [])) {
        final map = Map<String, dynamic>.from(raw as Map);
        final oldId = map['id'] as int?;
        map.remove('id');
        map['user_id'] = userId;
        final newId = await _courses.insert(Course.fromMap(map));
        if (oldId != null) oldCourseIdToNew[oldId] = newId;
      }

      for (final raw in (decoded['tasks'] as List? ?? [])) {
        final map = Map<String, dynamic>.from(raw as Map);
        map.remove('id');
        map['user_id'] = userId;
        final oldCourseId = map['course_id'] as int?;
        if (oldCourseId != null) {
          map['course_id'] = oldCourseIdToNew[oldCourseId];
        }
        await _tasks.insert(Task.fromMap(map));
      }

      for (final raw in (decoded['flashcards'] as List? ?? [])) {
        final map = Map<String, dynamic>.from(raw as Map);
        map.remove('id');
        map['user_id'] = userId;
        final oldCourseId = map['course_id'] as int?;
        if (oldCourseId != null) {
          map['course_id'] = oldCourseIdToNew[oldCourseId];
        }
        await _cards.insert(Flashcard.fromMap(map));
      }

      for (final raw in (decoded['study_sessions'] as List? ?? [])) {
        final map = Map<String, dynamic>.from(raw as Map);
        map.remove('id');
        map['user_id'] = userId;
        final oldCourseId = map['course_id'] as int?;
        if (oldCourseId != null) {
          map['course_id'] = oldCourseIdToNew[oldCourseId];
        }
        await _sessions.insert(StudySession.fromMap(map));
      }

      for (final raw in (decoded['achievements'] as List? ?? [])) {
        final code = (raw as Map)['badge_code'] as String?;
        if (code != null) await _achievements.unlock(userId, code);
      }

      for (final raw in (decoded['notifications'] as List? ?? [])) {
        final map = Map<String, dynamic>.from(raw as Map);
        map.remove('id');
        map['user_id'] = userId;
        await _notifications.insert(AppNotification.fromMap(map));
      }

      for (final raw in (decoded['ai_notes'] as List? ?? [])) {
        final map = Map<String, dynamic>.from(raw as Map);
        map.remove('id');
        map['user_id'] = userId;
        final oldCourseId = map['course_id'] as int?;
        if (oldCourseId != null) {
          map['course_id'] = oldCourseIdToNew[oldCourseId];
        }
        await _aiNotes.insert(AiNote.fromMap(map));
      }
    } finally {
      await database.execute('PRAGMA foreign_keys = ON');
    }
  }
}
