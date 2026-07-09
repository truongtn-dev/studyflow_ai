import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'screens/task/add_task_screen.dart';
import 'screens/task/task_detail_screen.dart';
import 'screens/task/task_list_screen.dart';
import 'screens/task/edit_task_screen.dart';
import 'screens/study/pomodoro_screen.dart';
import 'screens/study/pomodoro_settings_screen.dart';
class StudyFlowApp extends StatelessWidget {
  const StudyFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'StudyFlow AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          routes: {
            '/add-task': (context) => AddTaskScreen(userId: 1),
            '/task-detail': (context) => TaskDetailScreen(taskId: ModalRoute.of(context)!.settings.arguments as int),
            '/task-list': (context) => TaskListScreen(userId: 1),
            '/pomodoro': (context) => const PomodoroScreen(),
            '/pomodoro-settings': (context) => const PomodoroSettingsScreen(),
          },
        );
      },
    );
  }
}
