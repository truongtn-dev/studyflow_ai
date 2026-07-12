import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../services/achievement_service.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import 'auth/login_screen.dart';
import 'auth/onboarding_screen.dart';
import 'shell/main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding =
        prefs.getBool(AppConstants.hasSeenOnboardingKey) ?? false;
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoading && auth.user == null) {
      await auth.loadSession();
    }
    if (auth.userId != null) {
      await AchievementService().applyStreakDecay(auth.userId!);
      await auth.refreshUser();
    }
    if (!mounted) return;
    _goNext(hasSeenOnboarding, auth.isLoggedIn);
  }

  void _goNext(bool hasSeenOnboarding, bool hasSession) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) {
          if (!hasSeenOnboarding) return const OnboardingScreen();
          if (!hasSession) return const LoginScreen();
          return const MainShell();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'StudyFlow AI',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Học thông minh. Deadline trong tầm kiểm soát.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
