import 'package:flutter/material.dart';

import '../../models/course.dart';
import '../../models/task.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/achievement_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';
import 'edit_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Future<Task?> _taskFuture;
  Course? _course;

  @override
  void initState() {
    super.initState();
    _taskFuture = TaskRepository().getById(widget.taskId);
    _loadCourse();
  }

  Future<void> _reload() async {
    setState(() {
      _taskFuture = TaskRepository().getById(widget.taskId);
    });
    await _loadCourse();
  }

  Future<void> _loadCourse() async {
    final task = await _taskFuture;
    if (task?.courseId == null) {
      if (mounted) setState(() => _course = null);
      return;
    }
    final course = await CourseRepository().getById(task!.courseId!);
    if (mounted) setState(() => _course = course);
  }

  Future<void> _updateStatus(Task task, TaskStatus newStatus) async {
    await TaskRepository().update(task.copyWith(status: newStatus));
    if (newStatus == TaskStatus.done) {
      await AchievementService().evaluate(task.userId);
    }
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật trạng thái!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = UiHelpers.scaffoldBg(context);
    final text = UiHelpers.textPrimary(context);
    final surface = UiHelpers.surface(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        title: const Text(
          'Chi tiết công việc',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final task = await _taskFuture;
              if (!mounted) return;
              if (task == null) return;
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => EditTaskScreen(task: task)),
              );
              if (!mounted) return;
              if (result == true) await _reload();
            },
          ),
        ],
      ),
      body: FutureBuilder<Task?>(
        future: _taskFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final task = snapshot.data;
          if (task == null) {
            return const Center(child: Text('Không tìm thấy thông tin'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: text,
                ),
              ),
              const SizedBox(height: 12),
              if (_course != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(
                      Icons.book,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    label: Text(
                      _course!.name,
                      style: const TextStyle(color: AppColors.secondary),
                    ),
                    backgroundColor: AppColors.secondaryContainer,
                    side: BorderSide.none,
                  ),
                ),
              const SizedBox(height: 20),
              _section(surface, text, 'Mô tả', task.description ?? 'Không có mô tả'),
              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      surface,
                      'Độ ưu tiên',
                      task.priority.name.toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _infoCard(surface, 'Tiến độ', '${task.progress}%'),
                  ),
                ],
              ),
              _infoRow(
                surface,
                text,
                'Hạn chót',
                task.deadline.split('T').first,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<TaskStatus>(
                initialValue: task.status,
                decoration: const InputDecoration(
                  labelText: 'Cập nhật trạng thái',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                items: TaskStatus.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (newStatus) {
                  if (newStatus != null) _updateStatus(task, newStatus);
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: const Icon(Icons.delete),
                label: const Text(
                  'Xóa công việc',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Xác nhận xóa'),
                      content: const Text(
                        'Bạn có chắc chắn muốn xóa công việc này không?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                  if (!mounted) return;
                  await TaskRepository().delete(task.id!);
                  if (!mounted) return;
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section(Color surface, Color text, String title, String content) =>
      Card(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(content, style: TextStyle(color: text)),
            ],
          ),
        ),
      );

  Widget _infoCard(Color surface, String label, String value) => Card(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _infoRow(Color surface, Color text, String label, String value) =>
      Card(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.divider),
        ),
        child: ListTile(
          title: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          trailing: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: text),
          ),
        ),
      );
}
