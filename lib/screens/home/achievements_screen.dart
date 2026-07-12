import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/achievement.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/achievement_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sf_card.dart';

IconData _iconFor(IconDataProxy proxy) {
  switch (proxy) {
    case IconDataProxy.fire:
      return Icons.local_fire_department_rounded;
    case IconDataProxy.star:
      return Icons.star_rounded;
    case IconDataProxy.task:
      return Icons.task_alt_rounded;
    case IconDataProxy.style:
      return Icons.style_rounded;
    case IconDataProxy.timer:
      return Icons.timer_rounded;
    case IconDataProxy.school:
      return Icons.school_rounded;
  }
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _repo = AchievementRepository();
  Set<String> _earned = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final list = await _repo.getByUserId(userId);
    if (!mounted) return;
    setState(() {
      _earned = list.map((a) => a.badgeCode).toSet();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Huy hiệu')),
        body: const EmptyState(
          title: 'Vui lòng đăng nhập',
          icon: Icons.lock_outline,
        ),
      );
    }

    return Scaffold(
      backgroundColor: UiHelpers.scaffoldBg(context),
      appBar: AppBar(title: const Text('Huy hiệu')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: BadgeCatalog.all.length,
                itemBuilder: (context, index) {
                  final badge = BadgeCatalog.all[index];
                  final earned = _earned.contains(badge.code);
                  return SfCard(
                    color: earned
                        ? AppColors.primaryContainer
                        : AppColors.surfaceVariant.withValues(alpha: 0.6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _iconFor(badge.icon),
                          size: 40,
                          color: earned
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          badge.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: earned
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          badge.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: earned
                                ? AppColors.textSecondary
                                : AppColors.textSecondary
                                    .withValues(alpha: 0.7),
                          ),
                        ),
                        if (earned) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Đã mở khóa',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
