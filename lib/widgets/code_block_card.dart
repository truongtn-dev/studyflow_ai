import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:highlight/highlight.dart' show highlight;
import 'package:highlight/languages/dart.dart' as dart_lang;
import 'package:highlight/languages/java.dart' as java_lang;
import 'package:highlight/languages/javascript.dart' as js_lang;
import 'package:highlight/languages/kotlin.dart' as kotlin_lang;
import 'package:highlight/languages/python.dart' as python_lang;
import 'package:highlight/languages/sql.dart' as sql_lang;

import '../theme/app_colors.dart';

class CodeBlockCard extends StatelessWidget {
  const CodeBlockCard({
    super.key,
    required this.code,
    this.language,
  });

  final String code;
  final String? language;

  static const _codeBackground = Color(0xFF282C34);
  static const _headerBackground = Color(0xFF1E293B);

  static bool _languagesRegistered = false;

  static void _ensureLanguagesRegistered() {
    if (_languagesRegistered) return;
    highlight.registerLanguage('dart', dart_lang.dart);
    highlight.registerLanguage('java', java_lang.java);
    highlight.registerLanguage('javascript', js_lang.javascript);
    highlight.registerLanguage('js', js_lang.javascript);
    highlight.registerLanguage('kotlin', kotlin_lang.kotlin);
    highlight.registerLanguage('python', python_lang.python);
    highlight.registerLanguage('py', python_lang.python);
    highlight.registerLanguage('sql', sql_lang.sql);
    _languagesRegistered = true;
  }

  String get _languageLabel {
    final lang = language?.trim().toLowerCase();
    if (lang == null || lang.isEmpty) return 'code';
    return lang;
  }

  bool get _hasHighlight => _languageLabel != 'code';

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã copy mã nguồn'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureLanguagesRegistered();

    final mono = GoogleFonts.jetBrainsMono(
      fontSize: 13,
      height: 1.5,
      color: const Color(0xFFABB2BF),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _codeBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: _headerBackground,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _languageLabel,
                    style: mono.copyWith(
                      color: const Color(0xFF93C5FD),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _copy(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_rounded, size: 16, color: Color(0xFFCBD5E1)),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: mono.copyWith(color: const Color(0xFFCBD5E1), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _hasHighlight
                ? HighlightView(
                    code.trimRight(),
                    language: _languageLabel,
                    theme: atomOneDarkTheme,
                    textStyle: mono,
                    padding: const EdgeInsets.all(14),
                  )
                : Padding(
                    padding: const EdgeInsets.all(14),
                    child: SelectableText(
                      code.trimRight(),
                      style: mono,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
