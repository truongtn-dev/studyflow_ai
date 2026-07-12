import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../models/task.dart';
import '../../repositories/notification_repository.dart';
import '../../repositories/task_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';

class TaskListScreen extends StatefulWidget {
  final int userId;
  const TaskListScreen({super.key, required this.userId});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  TaskStatus? _filter;
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  @override
  void didUpdateWidget(covariant TaskListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _refreshTasks();
    }
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = _load();
    });
  }

  Future<List<Task>> _load() async {
    final repo = TaskRepository();
    final updated = await repo.syncOverdue(widget.userId);
    if (updated > 0) {
      await NotificationRepository().insert(
        AppNotification(
          userId: widget.userId,
          title: 'Task quá hạn',
          body: 'Có $updated task vừa chuyển sang quá hạn.',
          type: 'deadline',
        ),
      );
    }
    return repo.getByUserId(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final bg = UiHelpers.scaffoldBg(context);
    final surface = UiHelpers.surface(context);
    final text = UiHelpers.textPrimary(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        title: const Text(
          'Công việc của tôi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: FutureBuilder<List<Task>>(
              future: _tasksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Chưa có công việc nào!'));
                }

                final filteredTasks = _applyFilter(snapshot.data!);
                if (filteredTasks.isEmpty) {
                  return const Center(
                    child: Text('Không có công việc nào trong mục này'),
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredTasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildTaskCard(filteredTasks[index], surface, text),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_tasks',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        onPressed: () async {
          await Navigator.pushNamed(context, '/add-task');
          _refreshTasks();
        },
        label: const Text('Thêm mới'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<TaskStatus?>(
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.primary,
            selectedForegroundColor: AppColors.surface,
          ),
          segments: [
            const ButtonSegment(value: null, label: Text('ALL')),
            ...TaskStatus.values.map(
              (s) => ButtonSegment(
                value: s,
                label: Text(
                  s.name.toUpperCase(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ],
          selected: {_filter},
          onSelectionChanged: (newSelection) =>
              setState(() => _filter = newSelection.first),
        ),
      ),
    );
  }

  List<Task> _applyFilter(List<Task> tasks) {
    if (_filter == null) return tasks;
    return tasks.where((t) => t.status == _filter).toList();
  }

  Widget _buildTaskCard(Task task, Color surface, Color text) {
    final deadline = DateTime.tryParse(task.deadline);
    final isOverdue = task.status == TaskStatus.overdue ||
        (task.status != TaskStatus.done &&
            deadline != null &&
            deadline.isBefore(DateTime.now()));

    return Card(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: isOverdue ? AppColors.error : AppColors.divider,
          width: isOverdue ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isOverdue
              ? AppColors.error.withValues(alpha: 0.1)
              : _getPriorityColor(task.priority).withValues(alpha: 0.1),
          child: Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.assignment,
            color: isOverdue
                ? AppColors.error
                : _getPriorityColor(task.priority),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(fontWeight: FontWeight.bold, color: text),
        ),
        subtitle: Text(
          isOverdue
              ? 'QUÁ HẠN: ${task.deadline.split('T').first}'
              : 'Deadline: ${task.deadline.split('T').first}',
          style: TextStyle(
            color: isOverdue ? AppColors.error : AppColors.textSecondary,
            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.primary,
        ),
        onTap: () async {
          await Navigator.pushNamed(
            context,
            '/task-detail',
            arguments: task.id,
          );
          _refreshTasks();
        },
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.error;
      case TaskPriority.medium:
        return AppColors.accent;
      case TaskPriority.low:
        return AppColors.secondary;
    }
  }
}
