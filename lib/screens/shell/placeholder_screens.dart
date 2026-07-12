import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import 'package:studyflow_ai/screens/task/task_list_screen.dart' as task;
import 'package:studyflow_ai/screens/study/pomodoro_screen.dart' as pomodoro;

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
    return const task.TaskListScreen(
      userId: 1,
    );
  }
}

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const pomodoro.PomodoroScreen();
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
