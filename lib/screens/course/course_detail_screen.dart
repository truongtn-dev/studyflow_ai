import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../models/task.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/flashcard_repository.dart';
import '../../repositories/task_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../flashcard/add_flashcard_screen.dart';
import '../task/add_task_screen.dart';
import '../task/task_detail_screen.dart';
import 'add_course_screen.dart';

Color _parseHex(String hex) => UiHelpers.parseHex(hex);

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.course});

  final Course course;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _courses = CourseRepository();
  final _tasks = TaskRepository();
  final _cards = FlashcardRepository();

  late Course _course;
  List<Task> _taskList = [];
  int _flashcardCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null || _course.id == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    final refreshed = await _courses.getById(_course.id!);
    final allTasks = await _tasks.getByUserId(userId);
    final count = await _cards.countByCourseId(_course.id!);
    if (!mounted) return;
    setState(() {
      if (refreshed != null) _course = refreshed;
      _taskList = allTasks.where((t) => t.courseId == _course.id).toList();
      _flashcardCount = count;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddCourseScreen(course: _course)),
    );
    if (changed == true) _load();
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa môn học?'),
        content: Text(
          'Bạn có chắc muốn xóa "${_course.name}"? '
          'Không thể xóa nếu còn task chưa hoàn thành.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true || _course.id == null) return;

    try {
      await _courses.delete(_course.id!);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is StateError ? e.message : 'Không thể xóa môn học.',
          ),
        ),
      );
    }
  }

  Future<void> _addTask() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(
          userId: userId,
          initialCourseId: _course.id,
        ),
      ),
    );
    _load();
  }

  Future<void> _addFlashcard() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddFlashcardScreen(initialCourseId: _course.id),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết môn')),
        body: const EmptyState(
          title: 'Vui lòng đăng nhập',
          icon: Icons.lock_outline,
        ),
      );
    }

    final color = _parseHex(_course.color);

    return Scaffold(
      backgroundColor: UiHelpers.scaffoldBg(context),
      appBar: AppBar(
        title: Text(_course.name),
        actions: [
          IconButton(
            tooltip: 'Sửa',
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Xóa',
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SfCard(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.school_rounded, color: color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _course.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              if (_course.code != null &&
                                  _course.code!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _course.code!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                '${_taskList.length} task · $_flashcardCount flashcard',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SfButton(
                          label: 'Thêm task',
                          icon: Icons.add_task,
                          onPressed: _addTask,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SfButton(
                          label: 'Thêm thẻ',
                          icon: Icons.style_outlined,
                          variant: SfButtonVariant.outlined,
                          onPressed: _addFlashcard,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Công việc',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (_taskList.isEmpty)
                    const EmptyState(
                      title: 'Chưa có task',
                      subtitle: 'Thêm task cho môn này.',
                      icon: Icons.checklist_outlined,
                    )
                  else
                    ..._taskList.map((task) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SfCard(
                          onTap: task.id == null
                              ? null
                              : () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TaskDetailScreen(taskId: task.id!),
                                    ),
                                  );
                                  _load();
                                },
                          child: Row(
                            children: [
                              Icon(
                                task.status == TaskStatus.done
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: task.status == TaskStatus.done
                                    ? AppColors.statusDone
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${task.status.name} · ${task.priority.name}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${task.progress}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
