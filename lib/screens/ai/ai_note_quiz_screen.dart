import 'package:flutter/material.dart';

import '../../models/note_quiz_question.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/sf_card.dart';

/// Quick review quiz generated from an AI note (separate from Flashcard SRS).
class AiNoteQuizScreen extends StatefulWidget {
  const AiNoteQuizScreen({
    super.key,
    required this.noteTitle,
    required this.questions,
  });

  final String noteTitle;
  final List<NoteQuizQuestion> questions;

  @override
  State<AiNoteQuizScreen> createState() => _AiNoteQuizScreenState();
}

class _AiNoteQuizScreenState extends State<AiNoteQuizScreen> {
  int _index = 0;
  int? _selected;
  int _score = 0;
  bool _answered = false;
  bool _finished = false;

  NoteQuizQuestion get _current => widget.questions[_index];

  void _pick(int optionIndex) {
    if (_answered) return;
    setState(() {
      _selected = optionIndex;
      _answered = true;
      if (optionIndex == _current.correctIndex) _score++;
    });
  }

  void _next() {
    if (_index >= widget.questions.length - 1) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _answered = false;
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _selected = null;
      _answered = false;
      _score = 0;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UiHelpers.scaffoldBg(context),
      appBar: AppBar(
        title: Text(
          widget.noteTitle.isEmpty ? 'Quiz ghi chú AI' : widget.noteTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _finished ? _buildResult() : _buildQuestion(),
    );
  }

  Widget _buildQuestion() {
    final q = _current;
    final total = widget.questions.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Câu ${_index + 1}/$total',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_index + 1) / total,
          minHeight: 6,
          borderRadius: BorderRadius.circular(8),
          color: AppColors.primary,
          backgroundColor: AppColors.primaryContainer,
        ),
        const SizedBox(height: 16),
        SfCard(
          child: Text(
            q.question,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(q.options.length, (i) {
          final selected = _selected == i;
          final correct = i == q.correctIndex;
          Color? bg;
          Color? border;
          if (_answered) {
            if (correct) {
              bg = AppColors.secondary.withValues(alpha: 0.12);
              border = AppColors.secondary;
            } else if (selected) {
              bg = AppColors.error.withValues(alpha: 0.1);
              border = AppColors.error;
            }
          } else if (selected) {
            border = AppColors.primary;
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: bg ??
                  (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.surfaceDark
                      : AppColors.surface),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: border ?? AppColors.divider),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _pick(i),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primaryContainer,
                        child: Text(
                          String.fromCharCode(65 + i),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(q.options[i])),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        if (_answered && q.explanation.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          SfCard(
            color: AppColors.primaryContainer.withValues(alpha: 0.5),
            child: Text('Giải thích: ${q.explanation}'),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _answered ? _next : null,
          child: Text(
            _index >= widget.questions.length - 1 ? 'Xem kết quả' : 'Câu tiếp',
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final total = widget.questions.length;
    final pct = total == 0 ? 0 : ((_score / total) * 100).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SfCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                pct >= 60 ? Icons.emoji_events_outlined : Icons.school_outlined,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                '$_score / $total đúng ($pct%)',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                pct >= 60
                    ? 'Ổn rồi — ghi chú này bạn nắm khá tốt.'
                    : 'Ôn lại ghi chú rồi quiz lần nữa nhé.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.refresh),
                label: const Text('Làm lại'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
