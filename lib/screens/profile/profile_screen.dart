import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../providers/ai_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../ai/ai_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SfCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryContainer,
                  child: const Text('SF', style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  )),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('StudyFlow User', style: Theme.of(context).textTheme.titleMedium),
                    Text('user@fpt.edu.vn', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SfCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Chế độ tối'),
              subtitle: const Text('Dark mode'),
              value: themeProvider.isDark,
              onChanged: (_) => themeProvider.toggle(),
            ),
          ),
          const SizedBox(height: 16),
          SfCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.auto_awesome, color: AppColors.primary),
              title: const Text('AI Quota & Settings'),
              subtitle: Text('Còn ${context.watch<AiProvider>().remainingQuota} lượt hôm nay'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiSettingsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SfButton(
            label: 'Đăng xuất',
            variant: SfButtonVariant.outlined,
            expand: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
