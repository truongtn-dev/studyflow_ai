import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';
import '../../models/course.dart';
import '../../repositories/task_repository.dart';
import '../../repositories/course_repository.dart';
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
    _loadTask();
  }

  Future<void> _loadTask() async {
    final task = await TaskRepository().getById(widget.taskId);
    if (task != null && task.courseId != null) {
      final course = await CourseRepository().getById(task.courseId!);
      if (mounted) {
        setState(() {
          _taskFuture = Future.value(task);
          _course = course;
        });
      }
    } else {
      if (mounted) setState(() => _taskFuture = Future.value(task));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        title: const Text("Chi tiết công việc", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final task = await _taskFuture;
              if (task != null && mounted) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditTaskScreen(task: task)),
                );
                if (result == true) _loadTask();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Task?>(
        future: _taskFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final task = snapshot.data;
          if (task == null) return const Center(child: Text("Không tìm thấy thông tin"));

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(task.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              if (_course != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(Icons.book, size: 16, color: AppColors.secondary),
                    label: Text(_course!.name, style: const TextStyle(color: AppColors.secondary)),
                    backgroundColor: AppColors.secondaryContainer,
                    side: BorderSide.none,
                  ),
                ),
              const SizedBox(height: 20),

              _buildSection("Mô tả", task.description ?? "Không có mô tả"),

              Row(
                children: [
                  Expanded(child: _buildInfoCard("Độ ưu tiên", task.priority.name.toUpperCase())),
                  const SizedBox(width: 10),
                  Expanded(child: _buildInfoCard("Tiến độ", "${task.progress}%")),
                ],
              ),
              _buildInfoRow("Hạn chót", task.deadline.split('T')[0]),

              const SizedBox(height: 20),
              DropdownButtonFormField<TaskStatus>(
                value: task.status,
                decoration: const InputDecoration(
                    labelText: "Cập nhật trạng thái",
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary))
                ),
                items: TaskStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                onChanged: (newStatus) async {
                  if (newStatus != null) {
                    await TaskRepository().update(task.copyWith(status: newStatus));
                    _loadTask();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật trạng thái!")));
                  }
                },
              ),

              const SizedBox(height: 30),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 15)
                ),
                icon: const Icon(Icons.delete),
                label: const Text("Xóa công việc", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Xác nhận xóa"),
                      content: const Text("Bạn có chắc chắn muốn xóa công việc này không?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
                        TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: AppColors.error), child: const Text("Xóa")),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    await TaskRepository().delete(task.id!);
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, String content) => Card(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.divider)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(color: AppColors.textPrimary)),
      ]),
    ),
  );

  Widget _buildInfoCard(String label, String value) => Card(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.divider)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
      ]),
    ),
  );

  Widget _buildInfoRow(String label, String value) => Card(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.divider)),
    child: ListTile(
      title: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    ),
  );
}