import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/ai_note.dart';
import '../../models/course.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/ai_note_repository.dart';
import '../../repositories/course_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/ai_markdown_message.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sf_card.dart';
import 'ai_note_editor_screen.dart';

class AiNotesScreen extends StatefulWidget {
  const AiNotesScreen({super.key});

  @override
  State<AiNotesScreen> createState() => _AiNotesScreenState();
}

class _AiNotesScreenState extends State<AiNotesScreen> {
  final _repo = AiNoteRepository();
  final _courses = CourseRepository();
  final _searchController = TextEditingController();

  List<AiNote> _notes = [];
  List<Course> _courseList = [];
  int? _filterCourseId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final courses = await _courses.getByUserId(userId);
    final notes = await _repo.getByUserId(
      userId,
      courseId: _filterCourseId,
      query: _searchController.text,
    );
    if (!mounted) return;
    setState(() {
      _courseList = courses;
      _notes = notes;
      _loading = false;
    });
  }

  String _courseName(int? id) {
    if (id == null) return '';
    for (final c in _courseList) {
      if (c.id == id) return c.name;
    }
    return '';
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'chat':
        return 'Chat';
      case 'explain':
        return 'Explain';
      case 'study_plan':
        return 'Study plan';
      case 'history':
        return 'History';
      default:
        return 'Thủ công';
    }
  }

  Future<void> _openCreate() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AiNoteEditorScreen()),
    );
    if (ok == true) _load();
  }

  Future<void> _openDetail(AiNote note) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AiNoteDetailScreen(noteId: note.id!)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ghi chú AI')),
        body: const EmptyState(
          title: 'Vui lòng đăng nhập',
          icon: Icons.lock_outline,
        ),
      );
    }

    return Scaffold(
      backgroundColor: UiHelpers.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Ghi chú AI'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Thêm ghi chú'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tiêu đề, nội dung, tag…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                      ),
              ),
              onChanged: (_) => _load(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DropdownButtonFormField<int?>(
              key: ValueKey(_filterCourseId),
              initialValue: _filterCourseId,
              decoration: const InputDecoration(
                labelText: 'Lọc theo môn',
                prefixIcon: Icon(Icons.filter_list),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Tất cả môn'),
                ),
                ..._courseList.map(
                  (c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(c.name),
                  ),
                ),
              ],
              onChanged: (v) {
                setState(() => _filterCourseId = v);
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? EmptyState(
                        title: 'Chưa có ghi chú AI',
                        subtitle:
                            'Lưu câu trả lời từ Chat/Explain, hoặc tạo ghi chú thủ công.',
                        icon: Icons.bookmark_border_rounded,
                        actionLabel: 'Tạo ghi chú',
                        onAction: _openCreate,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                          itemCount: _notes.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            final course = _courseName(note.courseId);
                            final updated = DateTime.tryParse(note.updatedAt);
                            final time = updated == null
                                ? ''
                                : DateFormat('dd/MM/yyyy HH:mm').format(updated);
                            return SfCard(
                              onTap: () => _openDetail(note),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (note.isPinned) ...[
                                        const Icon(
                                          Icons.push_pin,
                                          size: 16,
                                          color: AppColors.accent,
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Expanded(
                                        child: Text(
                                          note.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          _sourceLabel(note.source),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor:
                                            AppColors.primaryContainer,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    note.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (course.isNotEmpty) ...[
                                        const Icon(
                                          Icons.menu_book_outlined,
                                          size: 14,
                                          color: AppColors.secondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          course,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      Text(
                                        time,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class AiNoteDetailScreen extends StatefulWidget {
  const AiNoteDetailScreen({super.key, required this.noteId});

  final int noteId;

  @override
  State<AiNoteDetailScreen> createState() => _AiNoteDetailScreenState();
}

class _AiNoteDetailScreenState extends State<AiNoteDetailScreen> {
  final _repo = AiNoteRepository();
  AiNote? _note;
  String? _courseName;
  bool _loading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final note = await _repo.getById(widget.noteId);
    String? courseName;
    if (note?.courseId != null) {
      final course = await CourseRepository().getById(note!.courseId!);
      courseName = course?.name;
    }
    if (!mounted) return;
    setState(() {
      _note = note;
      _courseName = courseName;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    if (_note == null) return;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AiNoteEditorScreen(note: _note)),
    );
    if (ok == true) {
      _changed = true;
      await _load();
    }
  }

  Future<void> _togglePin() async {
    if (_note == null) return;
    await _repo.togglePin(_note!);
    _changed = true;
    await _load();
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa ghi chú?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true || _note?.id == null) return;
    await _repo.delete(_note!.id!);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: UiHelpers.scaffoldBg(context),
        appBar: AppBar(
          title: const Text('Chi tiết ghi chú'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          actions: [
            IconButton(
              tooltip: _note?.isPinned == true ? 'Bỏ ghim' : 'Ghim',
              onPressed: _note == null ? null : _togglePin,
              icon: Icon(
                _note?.isPinned == true
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
              ),
            ),
            IconButton(
              onPressed: _note == null ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: _note == null ? null : _delete,
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _note == null
                ? const EmptyState(
                    title: 'Không tìm thấy ghi chú',
                    icon: Icons.search_off,
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        _note!.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text('Nguồn: ${_note!.source}')),
                          if (_courseName != null && _courseName!.isNotEmpty)
                            Chip(label: Text('Môn: $_courseName')),
                          if (_note!.tags.trim().isNotEmpty)
                            ..._note!.tags.split(',').map(
                                  (t) => Chip(
                                    label: Text(t.trim()),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SfCard(
                        child: AiMarkdownMessage(text: _note!.content),
                      ),
                    ],
                  ),
      ),
    );
  }
}
