import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../models/course.dart';
import '../../repositories/task_repository.dart';
import '../../repositories/course_repository.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;
  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TaskStatus _status;
  late TaskPriority _priority;
  late int _progress;
  late DateTime _deadline;


  List<Course> _courses = [];
  Course? _selectedCourse;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description ?? '');
    _status = widget.task.status;
    _priority = widget.task.priority;
    _progress = widget.task.progress;
    _deadline = DateTime.parse(widget.task.deadline);

    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final courses = await CourseRepository().getByUserId(widget.task.userId);
    setState(() {
      _courses = courses;

      _selectedCourse = courses.firstWhere(
            (c) => c.id == widget.task.courseId,
        orElse: () => courses.first,
      );
      _isLoading = false;
    });
  }

  Future<void> _updateTask() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _selectedCourse == null) return;

    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      status: _status,
      priority: _priority,
      progress: _progress,
      deadline: _deadline.toIso8601String(),
      courseId: _selectedCourse!.id,
    );

    await TaskRepository().update(updatedTask);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final inputBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(12));

    return Scaffold(
      appBar: AppBar(title: const Text("Chỉnh sửa công việc", style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Tiêu đề", border: inputBorder, prefixIcon: const Icon(Icons.title)),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 16),


              DropdownButtonFormField<Course>(
                value: _selectedCourse,
                decoration: InputDecoration(labelText: "Môn học", border: inputBorder, prefixIcon: const Icon(Icons.book)),
                items: _courses.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _selectedCourse = v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(labelText: "Mô tả chi tiết", border: inputBorder),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildDropdownStatus(inputBorder)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdownPriority(inputBorder)),
                ],
              ),
              const SizedBox(height: 16),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text("Tiến độ: $_progress%", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Slider(
                        value: _progress.toDouble(), min: 0, max: 100, divisions: 10,
                        onChanged: (v) => setState(() => _progress = v.toInt()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text("Hạn chót"),
                subtitle: Text(_deadline.toLocal().toString().split(' ')[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  final date = await showDatePicker(context: context, initialDate: _deadline, firstDate: DateTime.now(), lastDate: DateTime(2100));
                  if (date != null) setState(() => _deadline = date);
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _updateTask,
                  child: const Text("LƯU THAY ĐỔI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownStatus(InputBorder border) => DropdownButtonFormField<TaskStatus>(
    value: _status,
    decoration: InputDecoration(labelText: "Trạng thái", border: border),
    items: TaskStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
    onChanged: (v) => setState(() => _status = v!),
  );

  Widget _buildDropdownPriority(InputBorder border) => DropdownButtonFormField<TaskPriority>(
    value: _priority,
    decoration: InputDecoration(labelText: "Độ ưu tiên", border: border),
    items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()))).toList(),
    onChanged: (v) => setState(() => _priority = v!),
  );
}