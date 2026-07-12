import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/course_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sf_card.dart';
import 'add_course_screen.dart';
import 'backup_screen.dart';
import 'course_detail_screen.dart';

Color _parseHex(String hex) => UiHelpers.parseHex(hex);

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final _courses = CourseRepository();
  List<Course> _items = [];
  final Map<int, int> _taskCounts = {};
  bool _loading = true;

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
    final list = await _courses.getByUserId(userId);
    final counts = <int, int>{};
    for (final c in list) {
      if (c.id != null) {
        counts[c.id!] = await _courses.countTasks(c.id!);
      }
    }
    if (!mounted) return;
    setState(() {
      _items = list;
      _taskCounts
        ..clear()
        ..addAll(counts);
      _loading = false;
    });
  }

  Future<void> _openAdd() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddCourseScreen()),
    );
    if (changed == true) _load();
  }

  Future<void> _openDetail(Course course) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;

    return Scaffold(
      backgroundColor: UiHelpers.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Môn học'),
        actions: [
          IconButton(
            tooltip: 'Sao lưu / Khôi phục',
            onPressed: userId == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BackupScreen()),
                    ),
            icon: const Icon(Icons.backup_outlined),
          ),
        ],
      ),
      floatingActionButton: userId == null
          ? null
          : FloatingActionButton(
              heroTag: 'fab_courses',
              onPressed: _openAdd,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: userId == null
          ? const EmptyState(
              title: 'Vui lòng đăng nhập',
              subtitle: 'Đăng nhập để xem danh sách môn học.',
              icon: Icons.lock_outline,
            )
          : _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _items.isEmpty
                  ? EmptyState(
                      title: 'Chưa có môn học',
                      subtitle: 'Thêm môn học đầu tiên để bắt đầu.',
                      icon: Icons.school_outlined,
                      actionLabel: 'Thêm môn',
                      onAction: _openAdd,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final course = _items[index];
                          final count = _taskCounts[course.id] ?? 0;
                          final color = _parseHex(course.color);
                          return SfCard(
                            onTap: () => _openDetail(course),
                            padding: EdgeInsets.zero,
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          course.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (course.code != null &&
                                            course.code!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            course.code!,
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Text(
                                          '$count task',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
