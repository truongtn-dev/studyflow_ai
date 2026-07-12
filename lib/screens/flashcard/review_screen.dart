import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/flashcard.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/flashcard_repository.dart';
import '../../services/achievement_service.dart';
import '../../services/srs_engine.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _repo = FlashcardRepository();
  final _srs = const SrsEngine();
  final _achievements = AchievementService();

  List<Flashcard> _due = [];
  int _index = 0;
  bool _flipped = false;
  bool _loading = true;
  bool _finished = false;
  int _correctCount = 0;
  int _totalReviewed = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      setState(() {
        _loading = false;
        _finished = true;
      });
      return;
    }

    setState(() => _loading = true);
    final due = await _repo.getDue(userId);
    if (!mounted) return;
    setState(() {
      _due = due;
      _index = 0;
      _flipped = false;
      _finished = due.isEmpty;
      _loading = false;
    });
  }

  Flashcard? get _current =>
      (_index >= 0 && _index < _due.length) ? _due[_index] : null;

  Future<void> _answer(bool correct) async {
    final card = _current;
    if (card == null || card.id == null) return;
    final userId = context.read<AuthProvider>().userId;

    final updated = _srs.applyReview(card, correct: correct);
    await _repo.update(updated);
    await _repo.logReview(flashcardId: card.id!, correct: correct);
    if (!mounted) return;

    final done = _index + 1 >= _due.length;
    setState(() {
      _totalReviewed++;
      if (correct) _correctCount++;
      _flipped = false;
      if (done) {
        _finished = true;
      } else {
        _index++;
      }
    });

    if (done && userId != null) {
      await _achievements.evaluate(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ôn tập')),
        body: const EmptyState(
          title: 'Vui lòng đăng nhập',
          icon: Icons.lock_outline,
        ),
      );
    }

    return Scaffold(
      backgroundColor: UiHelpers.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Ôn tập'),
        actions: [
          if (!_loading && !_finished && _due.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_index + 1}/${_due.length}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _finished
              ? EmptyState(
                  title: _totalReviewed == 0
                      ? 'Không có thẻ đến hạn'
                      : 'Hoàn thành ôn tập!',
                  subtitle: _totalReviewed == 0
                      ? 'Quay lại sau khi có thẻ cần ôn.'
                      : 'Đúng $_correctCount / $_totalReviewed thẻ.',
                  icon: _totalReviewed == 0
                      ? Icons.inbox_outlined
                      : Icons.emoji_events_outlined,
                  actionLabel: 'Đóng',
                  onAction: () => Navigator.of(context).pop(),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _due.isEmpty
                            ? 0
                            : (_index) / _due.length,
                        color: AppColors.primary,
                        backgroundColor: AppColors.primaryContainer,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _flipped = !_flipped),
                          child: SfCard(
                            color: _flipped
                                ? AppColors.primaryContainer
                                : null,
                            child: Center(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _flipped ? 'Mặt sau' : 'Mặt trước',
                                      style: TextStyle(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _flipped
                                          ? (_current?.back ?? '')
                                          : (_current?.front ?? ''),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      _flipped
                                          ? 'Chạm để xem mặt trước'
                                          : 'Chạm để lật thẻ',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!_flipped)
                        SfButton(
                          label: 'Lật thẻ',
                          icon: Icons.flip,
                          onPressed: () => setState(() => _flipped = true),
                          expand: true,
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: SfButton(
                                label: 'Sai',
                                icon: Icons.close,
                                variant: SfButtonVariant.outlined,
                                onPressed: () => _answer(false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SfButton(
                                label: 'Đúng',
                                icon: Icons.check,
                                onPressed: () => _answer(true),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
    );
  }
}
