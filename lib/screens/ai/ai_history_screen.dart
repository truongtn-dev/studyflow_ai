import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/ai_cache_entry.dart';
import '../../providers/ai_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ai_markdown_message.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sf_card.dart';

class AiHistoryScreen extends StatelessWidget {
  const AiHistoryScreen({super.key});

  String _typeLabel(String type) {
    return switch (type) {
      'chat' => 'Chat',
      'study_plan' => 'Study Plan',
      'explain' => 'Explain',
      _ => type,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AiProvider>(
      builder: (context, ai, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Lịch sử AI'),
            actions: [
              if (ai.history.isNotEmpty)
                IconButton(
                  onPressed: () async {
                    await ai.clearHistory();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã xóa lịch sử AI')),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
            ],
          ),
          body: ai.history.isEmpty
              ? const EmptyState(
                  title: 'Chưa có lịch sử',
                  subtitle: 'Các câu hỏi AI sẽ được lưu vào SQLite ai_cache',
                  icon: Icons.history_rounded,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: ai.history.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = ai.history[index];
                    return _HistoryTile(
                      entry: item,
                      typeLabel: _typeLabel(item.promptType),
                      onTap: () => _showDetail(context, item),
                    );
                  },
                ),
        );
      },
    );
  }

  void _showDetail(BuildContext context, AiCacheEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Text('Chi tiết', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(entry.createdAt, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 16),
              AiMarkdownMessage(text: entry.response),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.typeLabel,
    required this.onTap,
  });

  final AiCacheEntry entry;
  final String typeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = entry.response.length > 100
        ? '${entry.response.substring(0, 100)}...'
        : entry.response;
    final time = entry.createdAt.isNotEmpty
        ? entry.createdAt
        : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    return SfCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(typeLabel, style: const TextStyle(color: AppColors.primary)),
              ),
              const Spacer(),
              Text(time, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(preview),
        ],
      ),
    );
  }
}
