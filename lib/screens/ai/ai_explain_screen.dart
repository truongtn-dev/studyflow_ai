import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ai_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ai_markdown_message.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import 'ai_note_editor_screen.dart';

class AiExplainScreen extends StatefulWidget {
  const AiExplainScreen({super.key});

  @override
  State<AiExplainScreen> createState() => _AiExplainScreenState();
}

class _AiExplainScreenState extends State<AiExplainScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AiProvider>(
      builder: (context, ai, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Giải thích concept')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Nhập concept',
                  hintText: 'VD: Provider là gì?',
                ),
              ),
              const SizedBox(height: 12),
              SfButton(
                label: 'Giải thích',
                icon: Icons.lightbulb_outline_rounded,
                expand: true,
                isLoading: ai.isLoading,
                onPressed: ai.isLoading
                    ? null
                    : () => ai.explainConcept(_controller.text),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final sample in ['Provider', 'SQLite', 'FutureBuilder'])
                    ActionChip(
                      label: Text(sample),
                      onPressed: ai.isLoading
                          ? null
                          : () {
                              _controller.text = sample;
                              ai.explainConcept(sample);
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
              else if (ai.explainResult != null) ...[
                SfCard(
                  child: AiMarkdownMessage(text: ai.explainResult!),
                ),
                const SizedBox(height: 12),
                SfButton(
                  label: 'Lưu vào Ghi chú AI',
                  icon: Icons.bookmark_add_outlined,
                  variant: SfButtonVariant.outlined,
                  expand: true,
                  onPressed: () => saveAiResponseAsNote(
                    context,
                    title: _controller.text.trim().isEmpty
                        ? 'Giải thích concept'
                        : 'Giải thích: ${_controller.text.trim()}',
                    content: ai.explainResult!,
                    source: 'explain',
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
