import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/notification_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sf_card.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final _repo = NotificationRepository();
  List<AppNotification> _items = [];
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
    final list = await _repo.getByUserId(userId);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.id == null || n.isRead) return;
    await _repo.markRead(n.id!);
    _load();
  }

  Future<void> _markAllRead() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    await _repo.markAllRead(userId);
    _load();
  }

  Future<void> _delete(AppNotification n) async {
    if (n.id == null) return;
    await _repo.delete(n.id!);
    _load();
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'achievement':
        return Icons.emoji_events_outlined;
      case 'reminder':
        return Icons.alarm_outlined;
      case 'warning':
        return Icons.warning_amber_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;
    final hasUnread = _items.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: UiHelpers.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (userId != null && hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Đọc tất cả'),
            ),
        ],
      ),
      body: userId == null
          ? const EmptyState(
              title: 'Vui lòng đăng nhập',
              icon: Icons.lock_outline,
            )
          : _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _items.isEmpty
                  ? const EmptyState(
                      title: 'Chưa có thông báo',
                      subtitle: 'Thông báo mới sẽ xuất hiện tại đây.',
                      icon: Icons.notifications_none,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final n = _items[index];
                          return Dismissible(
                            key: ValueKey(n.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) => _delete(n),
                            child: SfCard(
                              color: n.isRead
                                  ? null
                                  : AppColors.primaryContainer
                                      .withValues(alpha: 0.45),
                              onTap: () => _markRead(n),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    _iconFor(n.type),
                                    color: n.isRead
                                        ? AppColors.textSecondary
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n.title,
                                                style: TextStyle(
                                                  fontWeight: n.isRead
                                                      ? FontWeight.w600
                                                      : FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            if (!n.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          n.body,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (n.createdAt.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            n.createdAt.length >= 16
                                                ? n.createdAt.substring(0, 16)
                                                    .replaceFirst('T', ' ')
                                                : n.createdAt,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Xóa',
                                    onPressed: () => _delete(n),
                                    icon: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
