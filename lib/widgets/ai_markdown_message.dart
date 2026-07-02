import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../theme/app_colors.dart';
import 'code_block_card.dart';

class MessageSegment {
  const MessageSegment.text(this.content) : isCode = false, language = null;
  const MessageSegment.code(this.content, this.language) : isCode = true;

  final bool isCode;
  final String content;
  final String? language;
}

List<MessageSegment> parseMessageSegments(String text) {
  final segments = <MessageSegment>[];
  final pattern = RegExp(r'```(\w+)?\r?\n([\s\S]*?)```');
  var start = 0;

  for (final match in pattern.allMatches(text)) {
    if (match.start > start) {
      final chunk = text.substring(start, match.start).trim();
      if (chunk.isNotEmpty) segments.add(MessageSegment.text(chunk));
    }

    final language = match.group(1);
    final code = match.group(2) ?? '';
    if (code.trim().isNotEmpty) {
      segments.add(MessageSegment.code(code, language));
    }
    start = match.end;
  }

  if (start < text.length) {
    final tail = text.substring(start).trim();
    if (tail.isNotEmpty) segments.add(MessageSegment.text(tail));
  }

  if (segments.isEmpty) segments.add(MessageSegment.text(text));
  return segments;
}

class AiMarkdownMessage extends StatelessWidget {
  const AiMarkdownMessage({
    super.key,
    required this.text,
    this.textColor,
    this.isDarkBubble = false,
  });

  final String text;
  final Color? textColor;
  final bool isDarkBubble;

  @override
  Widget build(BuildContext context) {
    final segments = parseMessageSegments(text);
    final color = textColor ?? AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final segment in segments)
          if (segment.isCode)
            CodeBlockCard(code: segment.content, language: segment.language)
          else
            MarkdownBody(
              data: segment.content,
              shrinkWrap: true,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: color, height: 1.45, fontSize: 15),
                strong: TextStyle(color: color, fontWeight: FontWeight.w700),
                em: TextStyle(color: color, fontStyle: FontStyle.italic),
                h1: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
                h2: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
                h3: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600),
                listBullet: TextStyle(color: color),
                code: TextStyle(
                  color: isDarkBubble ? Colors.white : AppColors.primary,
                  backgroundColor: isDarkBubble
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppColors.primaryContainer,
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
                blockquote: TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                blockquoteDecoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 3),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
