import '../models/achievement.dart';
import '../models/app_notification.dart';
import '../models/user.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/flashcard_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/study_session_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/user_repository.dart';

class AchievementService {
  final _achievements = AchievementRepository();
  final _tasks = TaskRepository();
  final _cards = FlashcardRepository();
  final _sessions = StudySessionRepository();
  final _users = UserRepository();
  final _notifications = NotificationRepository();

  Future<List<String>> evaluate(int userId) async {
    await applyStreakDecay(userId);

    final unlocked = <String>[];

    Future<void> tryUnlock(String code) async {
      if (await _achievements.unlock(userId, code)) {
        unlocked.add(code);
        final badge = BadgeCatalog.byCode(code);
        await _notifications.insert(
          AppNotification(
            userId: userId,
            title: 'Huy hiệu mới!',
            body: badge == null
                ? 'Bạn vừa mở khóa badge: $code'
                : 'Mở khóa: ${badge.title} — ${badge.description}',
            type: 'achievement',
          ),
        );
      }
    }

    await tryUnlock('first_login');

    final tasks = await _tasks.getByUserId(userId);
    final doneCount = tasks.where((t) => t.status.name == 'done').length;
    if (doneCount >= 1) await tryUnlock('first_task');
    if (doneCount >= 10) await tryUnlock('tasks_10');

    final cardCount = await _cards.countByUserId(userId);
    if (cardCount >= 10) await tryUnlock('cards_10');

    final sessionCount = await _sessions.sessionCount(userId);
    if (sessionCount >= 1) await tryUnlock('first_pomodoro');

    final totalMin = await _sessions.totalMinutesAll(userId);
    if (totalMin >= 60) await tryUnlock('study_60');

    final user = await _users.findById(userId);
    if (user != null) {
      if (user.streak >= 3) await tryUnlock('streak_3');
      if (user.streak >= 7) await tryUnlock('streak_7');
    }

    return unlocked;
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// BR-05: reset streak if last study day is before yesterday.
  Future<User?> applyStreakDecay(int userId) async {
    final user = await _users.findById(userId);
    if (user == null || user.streak == 0) return user;

    final sessions = await _sessions.getByUserId(userId);
    if (sessions.isEmpty) {
      final cleared = user.copyWith(streak: 0);
      await _users.update(cleared);
      return cleared;
    }

    DateTime? lastStudy;
    for (final s in sessions) {
      final parsed = DateTime.tryParse(s.startedAt);
      if (parsed == null) continue;
      final day = _dayOnly(parsed);
      if (lastStudy == null || day.isAfter(lastStudy)) lastStudy = day;
    }

    final today = _dayOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    if (lastStudy == null || lastStudy.isBefore(yesterday)) {
      final cleared = user.copyWith(streak: 0);
      await _users.update(cleared);
      return cleared;
    }
    return user;
  }

  Future<User?> recordStudyDay(int userId, {int xpGain = 25}) async {
    var user = await applyStreakDecay(userId);
    user ??= await _users.findById(userId);
    if (user == null) return null;

    final sessions = await _sessions.getByUserId(userId);
    final today = _dayOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final todayKey = _dayKey(today);
    final yesterdayKey = _dayKey(yesterday);

    final sessionsToday =
        sessions.where((s) => s.startedAt.startsWith(todayKey)).length;
    final studiedYesterday =
        sessions.any((s) => s.startedAt.startsWith(yesterdayKey));

    // First session today: continue streak if studied yesterday, else start at 1.
    var nextStreak = user.streak;
    if (sessionsToday <= 1) {
      nextStreak = studiedYesterday ? user.streak + 1 : 1;
      if (nextStreak < 1) nextStreak = 1;
    }

    final updated = user.copyWith(
      xp: user.xp + xpGain,
      streak: nextStreak,
    );
    await _users.update(updated);
    await evaluate(userId);
    return updated;
  }
}
