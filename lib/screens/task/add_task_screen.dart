import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';
import '../../models/course.dart';
import '../../repositories/task_repository.dart';
import '../../repositories/course_repository.dart';

class AddTaskScreen extends StatefulWidget {
  final int userId;
  const AddTaskScreen({super.key, required this.userId});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Course> _courses = [];
  Course? _selectedCourse;
  DateTime _selectedDate = DateTime.now();
  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.todo;
  int _progress = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final courses = await CourseRepository().getByUserId(widget.userId);
    if (mounted) {
      setState(() {
        _courses = courses;
        if (courses.isNotEmpty) _selectedCourse = courses.first;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate() || _selectedCourse == null) return;

    final newTask = Task(
      userId: widget.userId,
      courseId: _selectedCourse!.id!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      deadline: _selectedDate.toIso8601String(),
      status: _status,
      priority: _priority,
      progress: _progress,
      createdAt: DateTime.now().toIso8601String(),
    );

    await TaskRepository().insert(newTask);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }


    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.divider),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Thêm Công Việc Mới", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Tiêu đề",
                  border: inputBorder,
                  prefixIcon: const Icon(Icons.title, color: AppColors.primary),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(labelText: "Mô tả chi tiết", border: inputBorder),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TaskStatus>(
                      value: _status,
                      decoration: InputDecoration(labelText: "Trạng thái", border: inputBorder),
                      items: TaskStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<TaskPriority>(
                      value: _priority,
                      decoration: InputDecoration(labelText: "Độ ưu tiên", border: inputBorder),
                      items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()))).toList(),
                      onChanged: (v) => setState(() => _priority = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<Course>(
                value: _selectedCourse,
                decoration: InputDecoration(
                  labelText: "Môn học",
                  prefixIcon: const Icon(Icons.book, color: AppColors.primary),
                  border: inputBorder,
                ),
                items: _courses.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _selectedCourse = v),
              ),

              const SizedBox(height: 20),
              // Card tiến độ
              Card(
                color: AppColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.divider)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text("Tiến độ: $_progress%", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Slider(
                        value: _progress.toDouble(),
                        min: 0, max: 100, divisions: 10,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _progress = v.toInt()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Deadline
              ListTile(
                tileColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.divider)),
                leading: const Icon(Icons.calendar_month, color: AppColors.primary),
                title: const Text("Hạn chót"),
                subtitle: Text(_selectedDate.toLocal().toString().split(' ')[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2100),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
                      child: child!,
                    ),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveTask,
                  child: const Text("LƯU CÔNG VIỆC", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}