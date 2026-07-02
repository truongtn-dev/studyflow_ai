import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ai_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chat_bubble.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(AiProvider ai) async {
    final text = _controller.text;
    _controller.clear();
    await ai.sendChat(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AiProvider>(
      builder: (context, ai, _) {
        if (ai.messages.isEmpty && !ai.isLoading) {
          _scrollToBottom();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Coach'),
            actions: [
              IconButton(
                onPressed: ai.messages.isEmpty ? null : ai.clearChat,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Xóa chat',
              ),
            ],
          ),
          body: Column(
            children: [
              if (ai.error != null)
                Container(
                  width: double.infinity,
                  color: AppColors.error.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(12),
                  child: Text(ai.error!, style: const TextStyle(color: AppColors.error)),
                ),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (ai.messages.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: Column(
                            children: [
                              Icon(Icons.auto_awesome, size: 48, color: AppColors.primary),
                              SizedBox(height: 12),
                              Text('Hỏi AI Coach bất cứ điều gì về học tập'),
                            ],
                          ),
                        ),
                      ),
                    ...ai.messages.map(
                      (m) => ChatBubble(text: m.text, isUser: m.isUser),
                    ),
                    if (ai.isLoading) const AiLoadingBubble(),
                  ],
                ),
              ),
              _QuickChips(onTap: (text) {
                _controller.text = text;
                _send(ai);
              }),
              _InputBar(
                controller: _controller,
                isLoading: ai.isLoading,
                onSend: () => _send(ai),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickChips extends StatelessWidget {
  const _QuickChips({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const chips = [
      'Lịch học tuần này',
      'Provider là gì?',
      'Ví dụ code FutureBuilder',
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ActionChip(
          label: Text(chips[i]),
          onPressed: () => onTap(chips[i]),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: isLoading ? null : (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Nhập câu hỏi...',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isLoading ? null : onSend,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
