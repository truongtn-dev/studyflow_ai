import 'package:flutter/material.dart';

import '../../models/course.dart';
import '../../models/task.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/task_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';
import '../course/add_course_screen.dart';

class AddTaskScreen extends StatefulWidget {
  final int userId;
  final int? initialCourseId;

  const AddTaskScreen({
    super.key,
    required this.userId,
    this.initialCourseId,
  });

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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final courses = await CourseRepository().getByUserId(widget.userId);
    if (!mounted) return;
    Course? selected;
    if (courses.isNotEmpty) {
      selected = courses.cast<Course?>().firstWhere(
            (c) => c!.id == widget.initialCourseId,
            orElse: () => courses.first,
          );
    }
    setState(() {
      _courses = courses;
      _selectedCourse = selected;
      _isLoading = false;
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_courses.isEmpty || _selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy tạo ít nhất một môn học trước khi thêm task.'),
        ),
      );
      return;
    }

    final newTask = Task(
      userId: widget.userId,
      courseId: _selectedCourse!.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      deadline: _selectedDate.toIso8601String(),
      status: _status,
      priority: _priority,
      progress: _progress,
    );

    await TaskRepository().insert(newTask);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final bg = UiHelpers.scaffoldBg(context);
    final surface = UiHelpers.surface(context);
    final text = UiHelpers.textPrimary(context);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.divider),
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Thêm Công Việc Mới',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề',
                  border: inputBorder,
                  prefixIcon: const Icon(Icons.title, color: AppColors.primary),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  border: inputBorder,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TaskStatus>(
                      initialValue: _status,
                      decoration: InputDecoration(
                        labelText: 'Trạng thái',
                        border: inputBorder,
                      ),
                      items: TaskStatus.values
                          .where((s) => s != TaskStatus.overdue)
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<TaskPriority>(
                      initialValue: _priority,
                      decoration: InputDecoration(
                        labelText: 'Độ ưu tiên',
                        border: inputBorder,
                      ),
                      items: TaskPriority.values
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _priority = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_courses.isEmpty)
                SfEmptyCourseHint(
                  onCreate: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddCourseScreen()),
                    );
                    await _loadData();
                  },
                )
              else
                DropdownButtonFormField<Course>(
                  initialValue: _selectedCourse,
                  decoration: InputDecoration(
                    labelText: 'Môn học',
                    prefixIcon: const Icon(Icons.book, color: AppColors.primary),
                    border: inputBorder,
                  ),
                  items: _courses
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCourse = v),
                ),
              const SizedBox(height: 20),
              Card(
                color: surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.divider),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        'Tiến độ: $_progress%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: text,
                        ),
                      ),
                      Slider(
                        value: _progress.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 10,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _progress = v.toInt()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                tileColor: surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.divider),
                ),
                leading:
                    const Icon(Icons.calendar_month, color: AppColors.primary),
                title: const Text('Hạn chót'),
                subtitle: Text(
                  _selectedDate.toLocal().toString().split(' ').first,
                  style: TextStyle(fontWeight: FontWeight.bold, color: text),
                ),
                onTap: () async {
                  final now = DateTime.now();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
                    firstDate: now,
                    lastDate: DateTime(2100),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveTask,
                  child: const Text(
                    'LƯU CÔNG VIỆC',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SfEmptyCourseHint extends StatelessWidget {
  const SfEmptyCourseHint({super.key, required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primaryContainer,
      child: ListTile(
        leading: const Icon(Icons.info_outline, color: AppColors.primary),
        title: const Text('Chưa có môn học'),
        subtitle: const Text('Tạo môn trước khi thêm task'),
        trailing: TextButton(onPressed: onCreate, child: const Text('Tạo môn')),
      ),
    );
  }
}
