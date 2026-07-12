import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ai_note.dart';
import '../../models/course.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/ai_note_repository.dart';
import '../../repositories/course_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/sf_button.dart';

/// Shared save/edit form for AI Notes CRUD.
class AiNoteEditorScreen extends StatefulWidget {
  const AiNoteEditorScreen({
    super.key,
    this.note,
    this.initialTitle,
    this.initialContent,
    this.initialSource = 'manual',
    this.initialCourseId,
  });

  final AiNote? note;
  final String? initialTitle;
  final String? initialContent;
  final String initialSource;
  final int? initialCourseId;

  @override
  State<AiNoteEditorScreen> createState() => _AiNoteEditorScreenState();
}

class _AiNoteEditorScreenState extends State<AiNoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final _repo = AiNoteRepository();
  final _courses = CourseRepository();

  List<Course> _courseList = [];
  int? _courseId;
  bool _pinned = false;
  bool _saving = false;
  bool _loading = true;

  bool get _isEdit => widget.note != null;

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    _titleController.text = n?.title ?? widget.initialTitle ?? '';
    _contentController.text = n?.content ?? widget.initialContent ?? '';
    _tagsController.text = n?.tags ?? '';
    _courseId = n?.courseId ?? widget.initialCourseId;
    _pinned = n?.isPinned ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCourses());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    final list = await _courses.getByUserId(userId);
    if (!mounted) return;
    setState(() {
      _courseList = list;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await _repo.update(
          widget.note!.copyWith(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            tags: _tagsController.text.trim(),
            courseId: _courseId,
            clearCourseId: _courseId == null,
            isPinned: _pinned,
          ),
        );
      } else {
        await _repo.insert(
          AiNote(
            userId: userId,
            courseId: _courseId,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            source: widget.initialSource,
            tags: _tagsController.text.trim(),
            isPinned: _pinned,
          ),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Đã cập nhật ghi chú.' : 'Đã lưu ghi chú AI.'),
        ),
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    return Scaffold(
      backgroundColor: UiHelpers.scaffoldBg(context),
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa ghi chú AI' : 'Lưu ghi chú AI'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nhập tiêu đề ghi chú'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contentController,
                    minLines: 8,
                    maxLines: 16,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nội dung không được trống'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    initialValue: _courseId,
                    decoration: const InputDecoration(
                      labelText: 'Gắn môn học (tuỳ chọn)',
                      prefixIcon: Icon(Icons.menu_book_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Không gắn môn'),
                      ),
                      ..._courseList.map(
                        (c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _courseId = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (cách nhau bởi dấu phẩy)',
                      hintText: 'provider, flutter, exam',
                      prefixIcon: Icon(Icons.sell_outlined),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ghim ghi chú'),
                    subtitle: const Text('Hiện trên đầu danh sách'),
                    value: _pinned,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setState(() => _pinned = v),
                  ),
                  const SizedBox(height: 16),
                  SfButton(
                    label: _isEdit ? 'Cập nhật' : 'Lưu ghi chú',
                    icon: Icons.bookmark_add_outlined,
                    expand: true,
                    isLoading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
    );
  }
}

/// Opens editor prefilled from an AI response.
Future<bool> saveAiResponseAsNote(
  BuildContext context, {
  required String title,
  required String content,
  required String source,
}) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => AiNoteEditorScreen(
        initialTitle: title,
        initialContent: content,
        initialSource: source,
      ),
    ),
  );
  return result == true;
}
