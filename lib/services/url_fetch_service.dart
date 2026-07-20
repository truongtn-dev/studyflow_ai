import 'package:http/http.dart' as http;

/// Fetches a public web page and extracts plain text for AI summarization.
class UrlFetchService {
  UrlFetchService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const maxChars = 12000;
  static const _timeout = Duration(seconds: 20);

  Future<FetchedPage> fetchText(String rawUrl) async {
    final uri = _normalizeUri(rawUrl);
    late http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'User-Agent':
                  'StudyFlowAI/1.0 (Flutter student app; educational use)',
              'Accept': 'text/html,application/xhtml+xml,text/plain;q=0.9,*/*;q=0.8',
            },
          )
          .timeout(_timeout);
    } catch (e) {
      throw StateError(
        'Không tải được link. Kiểm tra mạng hoặc thử URL khác.\n$e',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Trang trả về lỗi HTTP ${response.statusCode}. Thử link công khai khác.',
      );
    }

    final contentType = response.headers['content-type'] ?? '';
    var body = response.body;
    if (contentType.contains('html') ||
        body.contains('<html') ||
        body.contains('<HTML') ||
        body.contains('<!DOCTYPE')) {
      body = _htmlToText(body);
    }

    body = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (body.length < 80) {
      throw StateError(
        'Không đọc được nội dung hữu ích từ link '
        '(trang trống, chặn bot, hoặc cần đăng nhập).',
      );
    }

    final truncated = body.length > maxChars;
    final text = truncated ? body.substring(0, maxChars) : body;
    return FetchedPage(
      url: uri.toString(),
      text: text,
      truncated: truncated,
      charCount: body.length,
    );
  }

  Uri _normalizeUri(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      throw StateError('Vui lòng nhập URL.');
    }
    var candidate = trimmed;
    if (!candidate.contains('://')) {
      candidate = 'https://$candidate';
    }
    final uri = Uri.tryParse(candidate);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('URL không hợp lệ.');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw StateError('Chỉ hỗ trợ http/https.');
    }
    return uri;
  }

  String _htmlToText(String html) {
    var s = html;
    s = s.replaceAll(
      RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false),
      ' ',
    );
    s = s.replaceAll(
      RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false),
      ' ',
    );
    s = s.replaceAll(
      RegExp(r'<noscript[^>]*>[\s\S]*?</noscript>', caseSensitive: false),
      ' ',
    );
    s = s.replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ');
    s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'<[^>]+>'), ' ');
    s = s
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    s = s.replaceAll(RegExp(r'&#(\d+);'), ' ');
    return s;
  }
}

class FetchedPage {
  const FetchedPage({
    required this.url,
    required this.text,
    required this.truncated,
    required this.charCount,
  });

  final String url;
  final String text;
  final bool truncated;
  final int charCount;
}
