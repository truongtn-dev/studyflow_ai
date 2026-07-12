import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'ai_markdown_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.onSaveNote,
  });

  final String text;
  final bool isUser;
  final VoidCallback? onSaveNote;

  @override
  Widget build(BuildContext context) {
    final hasCode = !isUser && text.contains('```');

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.of(context).size.width * (hasCode ? 0.94 : 0.78),
            ),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : AppColors.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: isUser
                ? Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      height: 1.4,
                    ),
                  )
                : AiMarkdownMessage(
                    text: text,
                    textColor: AppColors.textPrimary,
                  ),
          ),
          if (!isUser && onSaveNote != null)
            TextButton.icon(
              onPressed: onSaveNote,
              icon: const Icon(Icons.bookmark_add_outlined, size: 18),
              label: const Text('Lưu ghi chú'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

class AiLoadingBubble extends StatelessWidget {
  const AiLoadingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
