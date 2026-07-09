import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';
import '../../repositories/task_repository.dart';

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

  void _refreshTasks() {
    setState(() {
      _tasksFuture = TaskRepository().getByUserId(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        title: const Text("Công việc của tôi", style: TextStyle(fontWeight: FontWeight.bold)),
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
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Chưa có công việc nào!"));
                }

                final filteredTasks = _applyFilter(snapshot.data!);

                if (filteredTasks.isEmpty) {
                  return const Center(child: Text("Không có công việc nào trong mục này"));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _buildTaskCard(filteredTasks[index]),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        onPressed: () async {
          await Navigator.pushNamed(context, '/add-task');
          _refreshTasks();
        },
        label: const Text("Thêm mới"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<TaskStatus?>(
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.primary,
            selectedForegroundColor: AppColors.surface,
          ),
          segments: [
            const ButtonSegment(value: null, label: Text("ALL")),
            ...TaskStatus.values.map((s) => ButtonSegment(
                value: s,
                label: Text(s.name.toUpperCase(), style: const TextStyle(fontSize: 10))
            )),
          ],
          selected: {_filter},
          onSelectionChanged: (newSelection) => setState(() => _filter = newSelection.first),
        ),
      ),
    );
  }

  List<Task> _applyFilter(List<Task> tasks) {
    if (_filter == null) return tasks;
    return tasks.where((t) => t.status == _filter).toList();
  }

  Widget _buildTaskCard(Task task) {

    bool isOverdue = task.status != TaskStatus.done &&
        DateTime.parse(task.deadline).isBefore(DateTime.now());

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
            color: isOverdue ? AppColors.error : AppColors.divider,
            width: isOverdue ? 1.5 : 1
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isOverdue ? AppColors.error.withOpacity(0.1) : _getPriorityColor(task.priority).withOpacity(0.1),
          child: Icon(
              isOverdue ? Icons.warning_amber_rounded : Icons.assignment,
              color: isOverdue ? AppColors.error : _getPriorityColor(task.priority)
          ),
        ),
        title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        subtitle: Text(
          isOverdue ? "QUÁ HẠN: ${task.deadline.split('T')[0]}" : "Deadline: ${task.deadline.split('T')[0]}",
          style: TextStyle(
              color: isOverdue ? AppColors.error : AppColors.textSecondary,
              fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
        onTap: () async {
          await Navigator.pushNamed(context, '/task-detail', arguments: task.id);
          _refreshTasks();
        },
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return AppColors.error;
      case TaskPriority.medium: return AppColors.accent;
      case TaskPriority.low: return AppColors.secondary;
    }
  }
}