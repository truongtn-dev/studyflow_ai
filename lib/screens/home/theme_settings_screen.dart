import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Giao diện')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SfCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Chế độ tối'),
              subtitle: Text(themeProvider.isDark ? 'Dark mode đang bật' : 'Light mode đang bật'),
              value: themeProvider.isDark,
              onChanged: (_) => themeProvider.toggle(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Xem trước', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SfCard(
            color: AppColors.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'StudyFlow AI',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Calm Focus — primary #5B5FEF',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                SfButton(
                  label: 'Nút mẫu',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
