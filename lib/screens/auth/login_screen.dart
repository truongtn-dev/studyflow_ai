import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/notification_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/achievement_service.dart';
import '../../theme/app_colors.dart';
import '../shell/main_shell.dart';
import 'onboarding_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final user = await context.read<AuthProvider>().login(
            email: _emailController.text,
            password: _passwordController.text,
          );

      if (user == null) {
        setState(() {
          _error = 'Email hoặc mật khẩu chưa đúng.';
          _submitting = false;
        });
        return;
      }

      if (!mounted) return;
      await context.read<AiProvider>().setUserSession(user.id!);
      final overdue = await TaskRepository().syncOverdue(user.id!);
      if (overdue > 0) {
        await NotificationRepository().insert(
          AppNotification(
            userId: user.id!,
            title: 'Task quá hạn',
            body: 'Có $overdue task vừa chuyển sang quá hạn.',
            type: 'deadline',
          ),
        );
      }
      await AchievementService().evaluate(user.id!);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showComingSoon(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _backToOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF6F7FF),
              AppColors.primary.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: -90,
                bottom: -120,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.22),
                        AppColors.primary.withValues(alpha: 0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -110,
                bottom: -150,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: _backToOnboarding,
                      icon: const Icon(Icons.arrow_back_rounded, size: 34),
                      color: AppColors.textPrimary,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _LoginHero(),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đăng nhập',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chào mừng trở lại! Đăng nhập để tiếp tục học tập.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 15,
                                  height: 1.6,
                                ),
                          ),
                          const SizedBox(height: 28),
                          _FieldLabel(text: 'Email'),
                          const SizedBox(height: 10),
                          _AuthField(
                            controller: _emailController,
                            hintText: 'Nhập email của bạn',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: Icons.mail_outline_rounded,
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return 'Vui lòng nhập email.';
                              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                              if (!emailRegex.hasMatch(text)) {
                                return 'Email chưa đúng định dạng.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          _FieldLabel(text: 'Mật khẩu'),
                          const SizedBox(height: 10),
                          _AuthField(
                            controller: _passwordController,
                            hintText: 'Nhập mật khẩu',
                            textInputAction: TextInputAction.done,
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            onSubmitted: (_) => _login(),
                            suffix: IconButton(
                              onPressed: () => setState(() {
                                _obscurePassword = !_obscurePassword;
                              }),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').isEmpty) {
                                return 'Vui lòng nhập mật khẩu.';
                              }
                              return null;
                            },
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _showComingSoon(
                                'Tính năng quên mật khẩu sẽ được bổ sung sau.',
                              ),
                              child: const Text('Quên mật khẩu?'),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 62,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6A63FF), AppColors.primary],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.24),
                                    blurRadius: 22,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: FilledButton(
                                onPressed: _submitting ? null : _login,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Đăng nhập',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(width: 14),
                                          Icon(Icons.arrow_forward_rounded, size: 26),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          const _DividerLabel(text: 'hoặc đăng nhập với'),
                          const SizedBox(height: 22),
                          _SocialButton(
                            label: 'Đăng nhập với Google',
                            icon: 'G',
                            onTap: () => _showComingSoon(
                              'Đăng nhập Google chưa được tích hợp trong bản này.',
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SocialButton(
                            label: 'Đăng nhập với Apple',
                            icon: '',
                            onTap: () => _showComingSoon(
                              'Đăng nhập Apple chưa được tích hợp trong bản này.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Chưa có tài khoản?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Đăng ký ngay',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.primary.withValues(alpha: 0.02),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(painter: _HeroRingPainter()),
              ),
              Positioned(
                top: 44,
                left: 58,
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary.withValues(alpha: 0.7),
                  size: 12,
                ),
              ),
              Positioned(
                top: 88,
                right: 70,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Image.asset(
                'assets/images/onboarding/onboarding_illustration_1.png',
                height: 210,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        Text.rich(
          TextSpan(
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
            children: const [
              TextSpan(text: 'StudyFlow '),
              TextSpan(
                text: 'AI',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Học thông minh. Deadline trong tầm kiểm soát.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _HeroRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 2);
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 86),
      3.65,
      2.35,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 106),
      3.45,
      2.15,
      false,
      paint..color = AppColors.primary.withValues(alpha: 0.05),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: AppColors.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.18),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.22)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
          ),
        ),
        Expanded(
          child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.22)),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.14)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: TextStyle(
              fontSize: icon == 'G' ? 28 : 30,
              fontWeight: FontWeight.w700,
              color: icon == 'G' ? Colors.red : Colors.black,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
