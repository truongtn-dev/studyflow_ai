import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ai_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/sf_card.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final _keyController = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.read<AiProvider>().saveApiKey(_keyController.text);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _keyController.text.trim().isEmpty
              ? 'Đã xóa API key'
              : 'Đã lưu API key — chạy flutter run bình thường là được',
        ),
      ),
    );
  }

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
                    Text('Groq API Key', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      ai.hasApiKey
                          ? 'Đã cấu hình — có thể chạy app bình thường, không cần --dart-define.'
                          : 'Dán key một lần. App lưu trên máy, lần sau flutter run là dùng được.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _keyController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: 'gsk_...',
                        labelText: 'API Key',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Lưu key'),
                          ),
                        ),
                        if (ai.hasApiKey) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () async {
                                    _keyController.clear();
                                    await context.read<AiProvider>().saveApiKey('');
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã xóa API key')),
                                    );
                                  },
                            child: const Text('Xóa'),
                          ),
                        ],
                      ],
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
                      title: 'Trạng thái',
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
                    Text('Hướng dẫn', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Lấy key miễn phí tại console.groq.com/keys\n'
                      '2. Dán vào ô phía trên → Lưu key\n'
                      '3. Chạy bình thường: flutter run (không cần secrets.json)\n'
                      '4. Key lưu trên máy, không commit lên GitHub',
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
