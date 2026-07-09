import 'package:flutter/material.dart';
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

    setState(() {
      _courses = courses;

      if (courses.isNotEmpty) {
        _selectedCourse = courses.first;
      }

      _isLoading = false;
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate() || _courses.isEmpty) return;


    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chọn môn học"),
        ),
      );
      return;
    }

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thêm Công Việc Mới", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Tiêu đề",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 15),

              // Mô tả
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Mô tả chi tiết",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Trạng thái & Ưu tiên
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TaskStatus>(
                      value: _status,
                      decoration: InputDecoration(labelText: "Trạng thái", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: TaskStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<TaskPriority>(
                      value: _priority,
                      decoration: InputDecoration(labelText: "Độ ưu tiên", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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
                  prefixIcon: const Icon(Icons.book),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _courses.map((course) {
                  return DropdownMenuItem<Course>(
                    value: course,
                    child: Text(course.name),
                  );
                }).toList(),
                onChanged: (course) {
                  setState(() {
                    _selectedCourse = course;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return "Vui lòng chọn môn học";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),
              // Tiến độ
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text("Tiến độ: $_progress%", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Slider(
                        value: _progress.toDouble(),
                        min: 0, max: 100, divisions: 10,
                        onChanged: (v) => setState(() => _progress = v.toInt()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Deadline
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.grey)),
                leading: const Icon(Icons.calendar_month),
                title: const Text("Hạn chót"),
                subtitle: Text(_selectedDate.toLocal().toString().split(' ')[0]),
                onTap: () async {
                  final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: 30),

              // Nút lưu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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