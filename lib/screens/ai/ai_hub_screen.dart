import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/sf_card.dart';
import 'ai_coach_screen.dart';
import 'ai_explain_screen.dart';
import 'ai_history_screen.dart';
import 'ai_link_summarize_screen.dart';
import 'ai_notes_screen.dart';
import 'ai_settings_screen.dart';
import 'ai_study_plan_screen.dart';

class AiHubScreen extends StatelessWidget {
  const AiHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _AiMenuItem(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'AI Coach Chat',
        subtitle: 'Hỏi đáp với Groq AI',
        screen: const AiCoachScreen(),
      ),
      _AiMenuItem(
        icon: Icons.calendar_month_rounded,
        title: 'Gợi ý lịch 7 ngày',
        subtitle: 'Phân tích deadline & môn học',
        screen: const AiStudyPlanScreen(),
      ),
      _AiMenuItem(
        icon: Icons.lightbulb_outline_rounded,
        title: 'Giải thích concept',
        subtitle: 'Provider, SQLite, async...',
        screen: const AiExplainScreen(),
      ),
      _AiMenuItem(
        icon: Icons.link_rounded,
        title: 'Tóm tắt link',
        subtitle: 'REST fetch URL + Groq tóm tắt',
        screen: const AiLinkSummarizeScreen(),
      ),
      _AiMenuItem(
        icon: Icons.bookmark_outline_rounded,
        title: 'Ghi chú AI',
        subtitle: 'CRUD · rút gọn AI · quiz ôn nhanh',
        screen: const AiNotesScreen(),
      ),
      _AiMenuItem(
        icon: Icons.history_rounded,
        title: 'Lịch sử AI',
        subtitle: 'Đọc từ ai_cache SQLite',
        screen: const AiHistoryScreen(),
      ),
      _AiMenuItem(
        icon: Icons.tune_rounded,
        title: 'AI Quota Settings',
        subtitle: '15 request/ngày',
        screen: const AiSettingsScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return SfCard(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => item.screen),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(item.icon, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AiMenuItem {
  const _AiMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.screen,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;
}
