import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/study/pomodoro_screen.dart';
import 'screens/study/pomodoro_settings_screen.dart';
import 'screens/task/add_task_screen.dart';
import 'screens/task/task_detail_screen.dart';
import 'screens/task/task_list_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/empty_state.dart';

class StudyFlowApp extends StatelessWidget {
  const StudyFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, auth, _) {
        final userId = auth.userId;
        return MaterialApp(
          title: 'StudyFlow AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          onGenerateRoute: (settings) {
            if (userId == null) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: EmptyState(
                    title: 'Vui lòng đăng nhập',
                    icon: Icons.lock_outline,
                  ),
                ),
                settings: settings,
              );
            }
            switch (settings.name) {
              case '/add-task':
                final courseId = settings.arguments as int?;
                return MaterialPageRoute(
                  builder: (_) => AddTaskScreen(
                    userId: userId,
                    initialCourseId: courseId,
                  ),
                  settings: settings,
                );
              case '/task-detail':
                return MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(
                    taskId: settings.arguments as int,
                  ),
                  settings: settings,
                );
              case '/task-list':
                return MaterialPageRoute(
                  builder: (_) => TaskListScreen(userId: userId),
                  settings: settings,
                );
              case '/pomodoro':
                return MaterialPageRoute(
                  builder: (_) => const PomodoroScreen(),
                  settings: settings,
                );
              case '/pomodoro-settings':
                return MaterialPageRoute(
                  builder: (_) => const PomodoroSettingsScreen(),
                  settings: settings,
                );
              default:
                return null;
            }
          },
        );
      },
    );
  }
}
