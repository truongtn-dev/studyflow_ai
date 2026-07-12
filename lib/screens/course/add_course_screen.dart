import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/course_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sf_button.dart';

Color _parseHex(String hex) => UiHelpers.parseHex(hex);

const _colorOptions = [
  '#5B5FEF',
  '#0D9488',
  '#F59E0B',
  '#EF4444',
  '#8B5CF6',
  '#EC4899',
];

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key, this.course});

  final Course? course;

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _repo = CourseRepository();

  late String _selectedColor;
  bool _saving = false;

  bool get _isEdit => widget.course != null;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _nameController.text = c?.name ?? '';
    _codeController.text = c?.code ?? '';
    _selectedColor = c?.color ?? _colorOptions.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    setState(() => _saving = true);
    try {
      final code = _codeController.text.trim();
      if (_isEdit) {
        await _repo.update(
          Course(
            id: widget.course!.id,
            userId: widget.course!.userId,
            name: _nameController.text.trim(),
            code: code.isEmpty ? null : code,
            color: _selectedColor,
            createdAt: widget.course!.createdAt,
          ),
        );
      } else {
        await _repo.insert(
          Course(
            userId: userId,
            name: _nameController.text.trim(),
            code: code.isEmpty ? null : code,
            color: _selectedColor,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
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
        appBar: AppBar(title: Text(_isEdit ? 'Sửa môn học' : 'Thêm môn học')),
        body: const EmptyState(
          title: 'Vui lòng đăng nhập',
          icon: Icons.lock_outline,
        ),
      );
    }

    return Scaffold(
      backgroundColor: UiHelpers.scaffoldBg(context),
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa môn học' : 'Thêm môn học'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên môn học',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Vui lòng nhập tên môn.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã môn (tuỳ chọn)',
                  hintText: 'VD: PRM393',
                  prefixIcon: Icon(Icons.tag_outlined),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Màu sắc',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colorOptions.map((hex) {
                  final selected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _parseHex(hex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppColors.textPrimary
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: _parseHex(hex).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SfButton(
                label: _isEdit ? 'Lưu thay đổi' : 'Thêm môn học',
                onPressed: _save,
                isLoading: _saving,
                expand: true,
                icon: Icons.save_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
