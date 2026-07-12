import 'package:flutter/material.dart';

import '../../models/course.dart';
import '../../models/task.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/achievement_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';

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
    _descController =
        TextEditingController(text: widget.task.description ?? '');
    _status = widget.task.status;
    _priority = widget.task.priority;
    _progress = widget.task.progress;
    _deadline = DateTime.tryParse(widget.task.deadline) ?? DateTime.now();
    _loadCourses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    final courses = await CourseRepository().getByUserId(widget.task.userId);
    if (!mounted) return;
    Course? selected;
    if (courses.isNotEmpty) {
      selected = courses.cast<Course?>().firstWhere(
            (c) => c!.id == widget.task.courseId,
            orElse: () => courses.first,
          );
    }
    setState(() {
      _courses = courses;
      _selectedCourse = selected;
      _isLoading = false;
    });
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay =
        DateTime(_deadline.year, _deadline.month, _deadline.day);
    final firstDate = deadlineDay.isBefore(today) ? deadlineDay : today;
    var initial = deadlineDay;
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(DateTime(2100))) initial = DateTime(2100);

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _deadline = date);
  }

  Future<void> _updateTask() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_courses.isNotEmpty && _selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn môn học')),
      );
      return;
    }

    // Auto-correct overdue if deadline moved to future
    var status = _status;
    if (status == TaskStatus.overdue &&
        _deadline.isAfter(DateTime.now().subtract(const Duration(days: 0)))) {
      final endOfDeadline = DateTime(
        _deadline.year,
        _deadline.month,
        _deadline.day,
        23,
        59,
      );
      if (endOfDeadline.isAfter(DateTime.now()) && status != TaskStatus.done) {
        status = TaskStatus.todo;
      }
    }

    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      status: status,
      priority: _priority,
      progress: _progress,
      deadline: _deadline.toIso8601String(),
      courseId: _selectedCourse?.id,
    );

    await TaskRepository().update(updatedTask);
    if (status == TaskStatus.done) {
      await AchievementService().evaluate(widget.task.userId);
    }
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
          'Chỉnh sửa công việc',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
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
              const SizedBox(height: 16),
              if (_courses.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Chưa có môn học — task sẽ không gắn môn.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                DropdownButtonFormField<Course>(
                  initialValue: _selectedCourse,
                  decoration: InputDecoration(
                    labelText: 'Môn học',
                    border: inputBorder,
                    prefixIcon:
                        const Icon(Icons.book, color: AppColors.primary),
                  ),
                  items: _courses
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCourse = v),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  border: inputBorder,
                ),
              ),
              const SizedBox(height: 16),
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
                  const SizedBox(width: 16),
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              ListTile(
                tileColor: surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.divider),
                ),
                leading:
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                title: const Text('Hạn chót'),
                subtitle: Text(
                  _deadline.toLocal().toString().split(' ').first,
                  style: TextStyle(fontWeight: FontWeight.bold, color: text),
                ),
                onTap: _pickDeadline,
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
                  onPressed: _updateTask,
                  child: const Text(
                    'LƯU THAY ĐỔI',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
