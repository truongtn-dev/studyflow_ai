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

  /// Reset streak if user missed yesterday (and has no session today yet).
  Future<User?> applyStreakDecay(int userId) async {
    final user = await _users.findById(userId);
    if (user == null || user.streak == 0) return user;

    final sessions = await _sessions.getByUserId(userId);
    if (sessions.isEmpty) {
      if (user.streak > 0) {
        final cleared = user.copyWith(streak: 0);
        await _users.update(cleared);
        return cleared;
      }
      return user;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    bool hasDay(DateTime day) {
      final key =
          '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      return sessions.any((s) => s.startedAt.startsWith(key));
    }

    final studiedToday = hasDay(today);
    final studiedYesterday = hasDay(yesterday);

    if (!studiedToday && !studiedYesterday && user.streak > 0) {
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
    final today = DateTime.now();
    final todayKey =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final sessionsToday =
        sessions.where((s) => s.startedAt.startsWith(todayKey)).length;

    // First session of the day: streak = previous+1 (or 1 if was 0 after decay).
    final streakBump = sessionsToday <= 1 ? 1 : 0;
    final updated = user.copyWith(
      xp: user.xp + xpGain,
      streak: user.streak + streakBump,
    );
    await _users.update(updated);
    await evaluate(userId);
    return updated;
  }
}
