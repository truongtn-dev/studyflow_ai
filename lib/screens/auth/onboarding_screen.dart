import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentIndex = 0;

  final _items = const [
    _OnboardingItem(
      title: 'Học thông minh\ncùng AI',
      highlightedWord: 'AI',
      description:
          'StudyFlow AI là trợ lý học tập thông minh, hiểu bạn và đồng hành cùng bạn trên mọi hành trình.',
      imagePath: 'assets/images/onboarding/onboarding_illustration_1.png',
    ),
    _OnboardingItem(
      title: 'Kế hoạch rõ ràng\nnăng suất vượt trội',
      highlightedWord: 'năng suất',
      description:
          'Lập kế hoạch học tập, quản lý nhiệm vụ và tập trung với Pomodoro để đạt hiệu quả tối đa.',
      imagePath: 'assets/images/onboarding/onboarding_illustration_2.png',
    ),
    _OnboardingItem(
      title: 'Theo dõi tiến bộ\ntạo động lực mỗi ngày',
      highlightedWord: 'tiến bộ',
      description:
          'Thống kê chi tiết, thành tích và hệ thống nhắc nhở giúp bạn duy trì thói quen học tập bền vững.',
      imagePath: 'assets/images/onboarding/onboarding_illustration_3.png',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentIndex == _items.length - 1;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.hasSeenOnboardingKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _nextPage() {
    if (_isLastPage) {
      _completeOnboarding();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
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
              const Color(0xFFF4F5FF),
              AppColors.primary.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: PageView.builder(
            controller: _controller,
            itemCount: _items.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final item = _items[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.04),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 34,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _IllustrationStage(imagePath: item.imagePath),
                        const SizedBox(height: 18),
                        _Headline(
                          title: item.title,
                          highlightedWord: item.highlightedWord,
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  height: 1.7,
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              TextButton(
                                onPressed: _completeOnboarding,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: Text(
                                  'Bỏ qua',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                              const Spacer(),
                              _DotsIndicator(
                                count: _items.length,
                                currentIndex: _currentIndex,
                              ),
                              const Spacer(),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: _isLastPage
                                    ? SizedBox(
                                        key: const ValueKey('start'),
                                        height: 56,
                                        child: FilledButton(
                                          onPressed: _completeOnboarding,
                                          style: FilledButton.styleFrom(
                                            elevation: 0,
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 34,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                          ),
                                          child: const Text(
                                            'Bắt đầu',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      )
                                    : SizedBox(
                                        key: const ValueKey('next'),
                                        width: 60,
                                        height: 60,
                                        child: FilledButton(
                                          onPressed: _nextPage,
                                          style: FilledButton.styleFrom(
                                            elevation: 0,
                                            padding: EdgeInsets.zero,
                                            shape: const CircleBorder(),
                                          ),
                                          child: const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 25,
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IllustrationStage extends StatelessWidget {
  const _IllustrationStage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.92),
                    const Color(0xFFF8F8FF),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 18,
            left: 14,
            right: 14,
            bottom: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: RadialGradient(
                  center: const Alignment(0, -0.12),
                  radius: 0.9,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primary.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 8,
            right: 8,
            bottom: 0,
            child: Column(
              children: [
                Expanded(
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Container(
                  width: 220,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        blurRadius: 34,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({
    required this.title,
    required this.highlightedWord,
  });

  final String title;
  final String highlightedWord;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
          fontSize: 27,
          height: 1.28,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        );
    final highlightStyle = baseStyle?.copyWith(color: AppColors.primary);

    final parts = title.split(highlightedWord);
    final spans = <TextSpan>[];

    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i], style: baseStyle));
      }
      if (i < parts.length - 1) {
        spans.add(TextSpan(text: highlightedWord, style: highlightStyle));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: index == currentIndex
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.highlightedWord,
    required this.description,
    required this.imagePath,
  });

  final String title;
  final String highlightedWord;
  final String description;
  final String imagePath;
}
