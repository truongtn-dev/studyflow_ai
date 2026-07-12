import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/notification_repository.dart';
import '../../repositories/study_session_repository.dart';
import '../../repositories/task_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../ai/ai_hub_screen.dart';
import '../course/course_list_screen.dart';
import '../notifications/notification_center_screen.dart';
import 'achievements_screen.dart';
import 'statistics_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _tasks = TaskRepository();
  final _sessions = StudySessionRepository();
  final _notifications = NotificationRepository();

  int _streak = 0;
  int _xp = 0;
  int _todayTasks = 0;
  int _todayMinutes = 0;
  int _unread = 0;
  List<Task> _upcoming = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final userId = auth.userId;
    if (userId == null || user == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    final tasks = await _tasks.getByUserId(userId);
    final minutes = await _sessions.totalMinutesToday(userId);
    final unread = await _notifications.unreadCount(userId);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todayCount = tasks.where((t) {
      final d = DateTime.tryParse(t.deadline);
      if (d == null) return false;
      return !d.isBefore(todayStart) && d.isBefore(todayEnd);
    }).length;

    final upcoming = tasks.where((t) {
      if (t.status == TaskStatus.done) return false;
      final d = DateTime.tryParse(t.deadline);
      if (d == null) return false;
      return d.isAfter(now.subtract(const Duration(days: 1)));
    }).take(5).toList();

    if (!mounted) return;
    setState(() {
      _streak = user.streak;
      _xp = user.xp;
      _todayTasks = todayCount;
      _todayMinutes = minutes;
      _unread = unread;
      _upcoming = upcoming;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyFlow AI'),
        actions: [
          IconButton(
            tooltip: 'Thông báo',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
              );
              _load();
            },
            icon: Badge(
              isLabelVisible: _unread > 0,
              label: Text('$_unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await context.read<AuthProvider>().refreshUser();
                await _load();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SfCard(
                    color: AppColors.primaryContainer,
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: AppColors.accent, size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Streak',
                                style: Theme.of(context).textTheme.labelMedium),
                            Text('$_streak ngày',
                                style: Theme.of(context).textTheme.headlineSmall),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.star_rounded,
                            color: AppColors.secondary, size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('XP',
                                style: Theme.of(context).textTheme.labelMedium),
                            Text('$_xp',
                                style: Theme.of(context).textTheme.headlineSmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SfCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Việc hôm nay',
                                  style: Theme.of(context).textTheme.labelMedium),
                              const SizedBox(height: 4),
                              Text('$_todayTasks',
                                  style: Theme.of(context).textTheme.headlineSmall),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SfCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Đã học',
                                  style: Theme.of(context).textTheme.labelMedium),
                              const SizedBox(height: 4),
                              Text('$_todayMinutes phút',
                                  style: Theme.of(context).textTheme.headlineSmall),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.menu_book_outlined, size: 18),
                        label: const Text('Môn học'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CourseListScreen()),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.bar_chart_rounded, size: 18),
                        label: const Text('Thống kê'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.emoji_events_outlined, size: 18),
                        label: const Text('Huy hiệu'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Sắp đến hạn', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (_upcoming.isEmpty)
                    const SfCard(
                      child: EmptyState(
                        title: 'Chưa có deadline',
                        subtitle: 'Thêm task để theo dõi tiến độ học tập',
                        icon: Icons.task_alt_rounded,
                      ),
                    )
                  else
                    ..._upcoming.map((task) {
                      final deadline = DateTime.tryParse(task.deadline);
                      final label = deadline == null
                          ? task.deadline
                          : DateFormat('dd/MM/yyyy HH:mm').format(deadline);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SfCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.flag_rounded,
                              color: task.priority == TaskPriority.high
                                  ? AppColors.error
                                  : AppColors.accent,
                            ),
                            title: Text(task.title),
                            subtitle: Text(label),
                            trailing: Text(
                              task.status.name,
                              style: TextStyle(
                                color: task.status == TaskStatus.overdue
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  SfButton(
                    label: 'Hỏi AI Coach',
                    icon: Icons.auto_awesome,
                    variant: SfButtonVariant.outlined,
                    expand: true,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiHubScreen()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
