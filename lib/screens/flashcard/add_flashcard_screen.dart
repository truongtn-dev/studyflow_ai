import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../models/flashcard.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/flashcard_repository.dart';
import '../../services/achievement_service.dart';
import '../../services/srs_engine.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sf_button.dart';

class AddFlashcardScreen extends StatefulWidget {
  const AddFlashcardScreen({
    super.key,
    this.card,
    this.initialCourseId,
  });

  final Flashcard? card;
  final int? initialCourseId;

  @override
  State<AddFlashcardScreen> createState() => _AddFlashcardScreenState();
}

class _AddFlashcardScreenState extends State<AddFlashcardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _repo = FlashcardRepository();
  final _courseRepo = CourseRepository();

  List<Course> _courses = [];
  int? _courseId;
  bool _resetSrs = false;
  bool _loading = true;
  bool _saving = false;

  bool get _isEdit => widget.card != null;

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    _frontController.text = card?.front ?? '';
    _backController.text = card?.back ?? '';
    _courseId = card?.courseId ?? widget.initialCourseId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCourses());
  }

  Future<void> _loadCourses() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    final courses = await _courseRepo.getByUserId(userId);
    if (!mounted) return;
    setState(() {
      _courses = courses;
      if (_courseId != null &&
          !courses.any((c) => c.id == _courseId)) {
        _courseId = null;
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        var updated = widget.card!.copyWith(
          front: _frontController.text.trim(),
          back: _backController.text.trim(),
          courseId: _courseId,
          clearCourseId: _courseId == null,
        );
        if (_resetSrs) {
          updated = const SrsEngine().reset(updated);
        }
        await _repo.update(updated);
      } else {
        await _repo.insert(
          Flashcard(
            userId: userId,
            courseId: _courseId,
            front: _frontController.text.trim(),
            back: _backController.text.trim(),
          ),
        );
        await AchievementService().evaluate(userId);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Sửa flashcard' : 'Thêm flashcard'),
        ),
        body: const EmptyState(
          title: 'Vui lòng đăng nhập',
          icon: Icons.lock_outline,
        ),
      );
    }

    return Scaffold(
      backgroundColor: UiHelpers.scaffoldBg(context),
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa flashcard' : 'Thêm flashcard'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _frontController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Mặt trước',
                        hintText: 'Câu hỏi / thuật ngữ',
                        prefixIcon: Icon(Icons.flip_to_front_outlined),
                      ),
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Vui lòng nhập mặt trước.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _backController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Mặt sau',
                        hintText: 'Đáp án / giải thích',
                        prefixIcon: Icon(Icons.flip_to_back_outlined),
                      ),
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Vui lòng nhập mặt sau.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int?>(
                      initialValue: _courseId,
                      decoration: const InputDecoration(
                        labelText: 'Môn học',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Không gắn môn'),
                        ),
                        ..._courses.map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _courseId = v),
                    ),
                    if (_isEdit) ...[
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Đặt lại tiến độ SRS'),
                        subtitle: const Text(
                          'Reset interval, ease và lịch ôn tập.',
                        ),
                        value: _resetSrs,
                        activeThumbColor: AppColors.primary,
                        onChanged: (v) => setState(() => _resetSrs = v),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SfButton(
                      label: _isEdit ? 'Lưu thay đổi' : 'Thêm thẻ',
                      icon: Icons.save_outlined,
                      onPressed: _save,
                      isLoading: _saving,
                      expand: true,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
