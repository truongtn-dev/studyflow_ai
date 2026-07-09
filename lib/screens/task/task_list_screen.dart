import 'package:flutter/material.dart';
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

  // tải lại dữ liệu
  void _refreshTasks() {
    setState(() {
      _tasksFuture = TaskRepository().getByUserId(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Công việc của tôi", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<TaskStatus?>(
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
          ),
          Expanded(
            child: FutureBuilder<List<Task>>(
              future: _tasksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Chưa có công việc nào!"));
                }

                // Lọc
                final allTasks = snapshot.data!;
                final filteredTasks = _filter == null
                    ? allTasks
                    : allTasks.where((t) => t.status == _filter).toList();

                if (filteredTasks.isEmpty) {
                  return const Center(child: Text("Không có công việc nào trong mục này"));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: _getPriorityColor(task.priority).withOpacity(0.2),
                          child: Icon(Icons.assignment, color: _getPriorityColor(task.priority)),
                        ),
                        title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Deadline: ${task.deadline.split('T')[0]}", style: TextStyle(color: Colors.grey[600])),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          // Chờ kết quả quay về để refresh
                          await Navigator.pushNamed(context, '/task-detail', arguments: task.id);
                          _refreshTasks();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // chờ kết quả vể để refresh
          await Navigator.pushNamed(context, '/add-task');
          _refreshTasks();
        },
        label: const Text("Thêm mới"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return Colors.red;
      case TaskPriority.medium: return Colors.orange;
      case TaskPriority.low: return Colors.green;
      default: return Colors.blue;
    }
  }
}