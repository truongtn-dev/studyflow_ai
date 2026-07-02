import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ai_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ai_markdown_message.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';

class AiStudyPlanScreen extends StatelessWidget {
  const AiStudyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AiProvider>(
      builder: (context, ai, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Gợi ý lịch học')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SfCard(
                color: AppColors.primaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Study Plan', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text(
                      'Groq AI sẽ phân tích môn học và deadline để gợi ý lịch 7 ngày tới.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SfButton(
                label: 'Gợi ý lịch 7 ngày',
                icon: Icons.auto_awesome,
                expand: true,
                isLoading: ai.isLoading,
                onPressed: ai.isLoading ? null : ai.generateStudyPlan,
              ),
              if (ai.error != null) ...[
                const SizedBox(height: 12),
                Text(ai.error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 16),
              if (ai.isLoading)
                const LoadingShimmer(itemCount: 4)
              else if (ai.studyPlanResult != null)
                SfCard(
                  child: AiMarkdownMessage(text: ai.studyPlanResult!),
                ),
            ],
          ),
        );
      },
    );
  }
}
