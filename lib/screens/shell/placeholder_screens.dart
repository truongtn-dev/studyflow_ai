import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';

class PlaceholderTabScreen extends StatelessWidget {
  const PlaceholderTabScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.assignee,
  });

  final String title;
  final IconData icon;
  final String assignee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(
        title: '$title – đang phát triển',
        subtitle: 'Phụ trách: $assignee',
        icon: icon,
      ),
    );
  }
}

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderTabScreen(
      title: 'Công việc',
      icon: Icons.task_alt_rounded,
      assignee: 'Tuấn Huy',
    );
  }
}

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Focus')),
      backgroundColor: AppColors.primaryContainer,
      body: Center(
        child: Text(
          '25:00',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: 48,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}

class FlashcardListScreen extends StatelessWidget {
  const FlashcardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderTabScreen(
      title: 'Flashcards',
      icon: Icons.style_rounded,
      assignee: 'Nhất Thiện',
    );
  }
}
