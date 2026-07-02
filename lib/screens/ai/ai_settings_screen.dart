import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ai_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/sf_card.dart';

class AiSettingsScreen extends StatelessWidget {
  const AiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AiProvider>(
      builder: (context, ai, _) {
        final used = AppConstants.maxAiRequestsPerDay - ai.remainingQuota;
        final progress = used / AppConstants.maxAiRequestsPerDay;

        return Scaffold(
          appBar: AppBar(title: const Text('AI Quota')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SfCard(
                color: AppColors.primaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hôm nay', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Text(
                      '${ai.remainingQuota} / ${AppConstants.maxAiRequestsPerDay} lượt còn lại',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white,
                      color: ai.remainingQuota > 0 ? AppColors.primary : AppColors.error,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SfCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.key_rounded,
                      title: 'API Key',
                      value: ai.hasApiKey ? 'Đã cấu hình' : 'Chưa cấu hình',
                      valueColor: ai.hasApiKey ? AppColors.secondary : AppColors.error,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.smart_toy_outlined,
                      title: 'Model',
                      value: AppConstants.groqModel,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.cloud_off_outlined,
                      title: 'Offline fallback',
                      value: 'Đọc từ ai_cache SQLite',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SfCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hướng dẫn cấu hình', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Lấy API key miễn phí tại console.groq.com/keys\n'
                      '2. Thêm vào secrets.json:\n'
                      '   "GROQ_KEY": "gsk_..."\n'
                      '3. Chạy: flutter run --dart-define-from-file=secrets.json\n'
                      '4. Không commit API key lên GitHub',
                    ),
                  ],
                ),
              ),
              if (ai.remainingQuota == 0) ...[
                const SizedBox(height: 16),
                SfCard(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  child: const Text(
                    'Đã hết quota hôm nay. Bạn vẫn xem được lịch sử AI đã lưu offline.',
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelMedium),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: valueColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
