import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../models/flashcard.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/flashcard_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import 'add_flashcard_screen.dart';
import 'edit_flashcard_screen.dart';
import 'review_screen.dart';

class FlashcardListScreen extends StatefulWidget {
  const FlashcardListScreen({super.key});

  @override
  State<FlashcardListScreen> createState() => _FlashcardListScreenState();
}

class _FlashcardListScreenState extends State<FlashcardListScreen> {
  final _cards = FlashcardRepository();
  final _courses = CourseRepository();

  List<Flashcard> _items = [];
  List<Course> _courseList = [];
  int? _filterCourseId;
  bool _loading = true;
  int _dueCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      setState(() {
        _items = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    final courses = await _courses.getByUserId(userId);
    final cards =
        await _cards.getByUserId(userId, courseId: _filterCourseId);
    final due = await _cards.getDue(userId);
    if (!mounted) return;
    setState(() {
      _courseList = courses;
      _items = cards;
      _dueCount = due.length;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddFlashcardScreen(initialCourseId: _filterCourseId),
      ),
    );
    if (changed == true || changed == null) _load();
  }

  Future<void> _edit(Flashcard card) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditFlashcardScreen(card: card)),
    );
    _load();
  }

  Future<void> _delete(Flashcard card) async {
    if (card.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa flashcard?'),
        content: Text('Xóa thẻ "${card.front}"?'),
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
    if (confirm != true) return;
    await _cards.delete(card.id!);
    _load();
  }

  Future<void> _startReview() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    final due = await _cards.getDue(userId);
    if (due.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có thẻ đến hạn ôn tập.')),
      );
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReviewScreen()),
    );
    _load();
  }

  String? _courseName(int? courseId) {
    if (courseId == null) return null;
    for (final c in _courseList) {
      if (c.id == courseId) return c.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;

    return Scaffold(
      backgroundColor: UiHelpers.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          if (userId != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _dueCount > 0 ? _startReview : null,
                icon: const Icon(Icons.school_outlined),
                label: Text('Ôn tập${_dueCount > 0 ? ' ($_dueCount)' : ''}'),
              ),
            ),
        ],
      ),
      floatingActionButton: userId == null
          ? null
          : FloatingActionButton(
              onPressed: _add,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: userId == null
          ? const EmptyState(
              title: 'Vui lòng đăng nhập',
              icon: Icons.lock_outline,
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                        child: Text('Tất cả'),
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
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : _items.isEmpty
                          ? EmptyState(
                              title: 'Chưa có flashcard',
                              subtitle: 'Thêm thẻ để bắt đầu ôn tập.',
                              icon: Icons.style_outlined,
                              actionLabel: 'Thêm thẻ',
                              onAction: _add,
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: AppColors.primary,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _items.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final card = _items[index];
                                  final courseName = _courseName(card.courseId);
                                  return Dismissible(
                                    key: ValueKey(card.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding:
                                          const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                    confirmDismiss: (_) async {
                                      await _delete(card);
                                      return false;
                                    },
                                    child: SfCard(
                                      onTap: () => _edit(card),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  card.front,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  card.back,
                                                  style: const TextStyle(
                                                    color: AppColors
                                                        .textSecondary,
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (courseName != null) ...[
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    courseName,
                                                    style: const TextStyle(
                                                      color: AppColors.primary,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (v) {
                                              if (v == 'edit') _edit(card);
                                              if (v == 'delete') _delete(card);
                                            },
                                            itemBuilder: (_) => const [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Sửa'),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Xóa'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
                if (_dueCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SfButton(
                      label: 'Ôn tập ($_dueCount thẻ đến hạn)',
                      icon: Icons.school_outlined,
                      onPressed: _startReview,
                      expand: true,
                    ),
                  ),
              ],
            ),
    );
  }
}
