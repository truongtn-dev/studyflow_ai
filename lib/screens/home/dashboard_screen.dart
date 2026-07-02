import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../ai/ai_hub_screen.dart';

/// Dashboard – Hữu Duy (placeholder có UI sẵn để team mở rộng)
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StudyFlow AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SfCard(
            color: AppColors.primaryContainer,
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: AppColors.accent, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Streak', style: Theme.of(context).textTheme.labelMedium),
                    Text('0 ngày', style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.star_rounded, color: AppColors.secondary, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('XP', style: Theme.of(context).textTheme.labelMedium),
                    Text('0', style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SfCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Việc hôm nay', style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Text('0', style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SfCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Đã học', style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Text('0 phút', style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Sắp đến hạn', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const SfCard(
            child: EmptyState(
              title: 'Chưa có deadline',
              subtitle: 'Thêm task để theo dõi tiến độ học tập',
              icon: Icons.task_alt_rounded,
            ),
          ),
          const SizedBox(height: 16),
          SfButton(
            label: 'Hỏi AI Coach',
            icon: Icons.auto_awesome,
            variant: SfButtonVariant.outlined,
            expand: true,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiHubScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
