import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/empty_state.dart';
import '../flashcard/flashcard_list_screen.dart' as flashcards;
import '../study/pomodoro_screen.dart' as pomodoro;
import '../task/task_list_screen.dart' as task;

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;
    if (userId == null) {
      return const Scaffold(
        body: EmptyState(
          title: 'Vui lòng đăng nhập',
          icon: Icons.lock_outline,
        ),
      );
    }
    return task.TaskListScreen(userId: userId);
  }
}

class FocusTab extends StatelessWidget {
  const FocusTab({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;
    if (userId == null) {
      return const Scaffold(
        body: EmptyState(
          title: 'Vui lòng đăng nhập',
          icon: Icons.lock_outline,
        ),
      );
    }
    return const pomodoro.PomodoroScreen();
  }
}

class CardsTab extends StatelessWidget {
  const CardsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const flashcards.FlashcardListScreen();
  }
}

/// Backward-compatible aliases used by older imports.
typedef TaskListScreen = TasksTab;
typedef PomodoroScreen = FocusTab;
typedef FlashcardListScreen = CardsTab;
