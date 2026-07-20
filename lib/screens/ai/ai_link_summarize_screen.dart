import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ai_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/ai_markdown_message.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import 'ai_note_editor_screen.dart';

/// Dán URL công khai → REST fetch → Groq tóm tắt → lưu Ghi chú AI.
class AiLinkSummarizeScreen extends StatefulWidget {
  const AiLinkSummarizeScreen({super.key});

  @override
  State<AiLinkSummarizeScreen> createState() => _AiLinkSummarizeScreenState();
}

class _AiLinkSummarizeScreenState extends State<AiLinkSummarizeScreen> {
  final _controller = TextEditingController();

  static const _samples = [
    (
      'Flutter (Wikipedia)',
      'https://en.wikipedia.org/wiki/Flutter_(software)',
    ),
    (
      'SQLite (Wikipedia)',
      'https://en.wikipedia.org/wiki/SQLite',
    ),
    (
      'Provider pattern',
      'https://en.wikipedia.org/wiki/Provider_model',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run(AiProvider ai) async {
    FocusScope.of(context).unfocus();
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng dán URL cần tóm tắt.')),
      );
      return;
    }
    final uri = Uri.tryParse(raw.startsWith('http') ? raw : 'https://$raw');
    if (uri == null || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL không hợp lệ.')),
      );
      return;
    }
    await ai.summarizeLink(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AiProvider>(
      builder: (context, ai, _) {
        return Scaffold(
          backgroundColor: UiHelpers.scaffoldBg(context),
          appBar: AppBar(title: const Text('Tóm tắt link')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SfCard(
                color: AppColors.primaryContainer.withValues(alpha: 0.45),
                child: const Text(
                  'Dán URL bài học / Wikipedia / docs công khai. '
                  'App gọi REST lấy nội dung rồi Groq tóm tắt — '
                  'có thể lưu vào Ghi chú AI.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://en.wikipedia.org/wiki/...',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
                onSubmitted: ai.isLoading ? null : (_) => _run(ai),
              ),
              const SizedBox(height: 12),
              SfButton(
                label: 'Tóm tắt link',
                icon: Icons.auto_awesome_outlined,
                expand: true,
                isLoading: ai.isLoading,
                onPressed: ai.isLoading ? null : () => _run(ai),
              ),
              const SizedBox(height: 12),
              Text('Thử nhanh', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sample in _samples)
                    ActionChip(
                      label: Text(sample.$1),
                      onPressed: ai.isLoading
                          ? null
                          : () {
                              _controller.text = sample.$2;
                              _run(ai);
                            },
                    ),
                ],
              ),
              if (ai.error != null) ...[
                const SizedBox(height: 12),
                Text(ai.error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 16),
              if (ai.isLoading)
                const LoadingShimmer(itemCount: 3)
              else if (ai.linkSummaryResult != null) ...[
                if (ai.lastSummarizedUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Nguồn: ${ai.lastSummarizedUrl}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                SfCard(
                  child: AiMarkdownMessage(text: ai.linkSummaryResult!),
                ),
                const SizedBox(height: 12),
                SfButton(
                  label: 'Lưu vào Ghi chú AI',
                  icon: Icons.bookmark_add_outlined,
                  variant: SfButtonVariant.outlined,
                  expand: true,
                  onPressed: () => saveAiResponseAsNote(
                    context,
                    title: 'Tóm tắt: ${ai.lastSummarizedUrl ?? 'link'}',
                    content:
                        '${ai.linkSummaryResult!}\n\n---\nNguồn: ${ai.lastSummarizedUrl ?? ''}',
                    source: 'link',
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
