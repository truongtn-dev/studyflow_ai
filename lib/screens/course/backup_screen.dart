import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/backup_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _service = BackupRestoreService();
  final _importController = TextEditingController();

  String? _exportJson;
  bool _exporting = false;
  bool _importing = false;

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    setState(() => _exporting = true);
    try {
      final json = await _service.exportJson(userId);
      if (!mounted) return;
      setState(() => _exportJson = json);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xuất thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _copy() async {
    final text = _exportJson;
    if (text == null || text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép JSON vào clipboard.')),
    );
  }

  Future<void> _import() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    final json = _importController.text.trim();
    if (json.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng dán JSON cần khôi phục.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khôi phục dữ liệu?'),
        content: const Text(
          'Dữ liệu hiện tại (môn, task, flashcard, phiên học…) '
          'sẽ bị thay thế bằng bản sao lưu. Tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _importing = true);
    try {
      await _service.importJson(userId, json);
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khôi phục thành công.')),
      );
      _importController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Khôi phục thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sao lưu / Khôi phục')),
        body: const EmptyState(
          title: 'Vui lòng đăng nhập',
          icon: Icons.lock_outline,
        ),
      );
    }

    return Scaffold(
      backgroundColor: UiHelpers.scaffoldBg(context),
      appBar: AppBar(title: const Text('Sao lưu / Khôi phục')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xuất dữ liệu',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tạo bản sao lưu JSON để lưu trữ hoặc chuyển thiết bị.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                SfButton(
                  label: 'Xuất JSON',
                  icon: Icons.upload_outlined,
                  onPressed: _export,
                  isLoading: _exporting,
                  expand: true,
                ),
                if (_exportJson != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Nội dung xuất',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _copy,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Sao chép'),
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 220),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _exportJson!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Khôi phục dữ liệu',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dán nội dung JSON đã xuất để khôi phục.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _importController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'Dán JSON tại đây…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                SfButton(
                  label: 'Khôi phục',
                  icon: Icons.download_outlined,
                  onPressed: _import,
                  isLoading: _importing,
                  expand: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
