import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/course.dart';
import '../models/task.dart';
import '../utils/constants.dart';

class GroqService {
  GroqService({String? apiKey, http.Client? client})
      : _apiKey = (apiKey ?? const String.fromEnvironment(AppConstants.groqKeyEnv)).trim(),
        _client = client ?? http.Client();

  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  String _apiKey;
  final http.Client _client;

  bool get hasApiKey => _apiKey.isNotEmpty;

  void updateApiKey(String? key) {
    _apiKey = (key ?? '').trim();
  }

  Future<String> chat(String message) async {
    _ensureApiKey();
    return _withRetry(
      () => _chatCompletion(
        systemPrompt: _systemPrompt,
        userPrompt: message,
      ),
    );
  }

  Future<String> generateStudyPlan({
    required List<Course> courses,
    required List<Task> tasks,
  }) async {
    _ensureApiKey();
    final courseText = courses
        .map((c) => '- ${c.name}${c.code != null ? ' (${c.code})' : ''}')
        .join('\n');
    final taskText = tasks
        .map((t) => '- ${t.title} | deadline: ${t.deadline} | status: ${t.status.name}')
        .join('\n');

    final prompt = '''
Dựa trên danh sách môn học:
$courseText

và deadline công việc:
$taskText

Hãy gợi ý lịch học 7 ngày tới, chia theo buổi sáng/chiều/tối.
Trả về dạng bullet tiếng Việt, ngắn gọn, dễ đọc trên mobile.
''';

    return _withRetry(
      () => _chatCompletion(systemPrompt: _systemPrompt, userPrompt: prompt),
    );
  }

  Future<String> explainConcept(String concept) async {
    _ensureApiKey();
    final prompt = '''
Giải thích khái niệm sau cho sinh viên năm nhất, ngắn gọn, tiếng Việt, có ví dụ thực tế:
"$concept"

Nếu là khái niệm lập trình, bắt buộc có ít nhất 1 code block markdown (```dart hoặc ngôn ngữ phù hợp) kèm giải thích từng phần.
''';

    return _withRetry(
      () => _chatCompletion(systemPrompt: _systemPrompt, userPrompt: prompt),
    );
  }

  /// Rút gọn / làm sạch ghi chú AI đã lưu (vẫn thuộc module AI).
  Future<String> summarizeNote({
    required String title,
    required String content,
  }) async {
    _ensureApiKey();
    final prompt = '''
Rút gọn và làm sạch ghi chú học tập sau cho sinh viên FPT.
Giữ ý chính, bullet ngắn, tiếng Việt. Giữ code block nếu có.

Tiêu đề: $title

Nội dung:
$content
''';
    return _withRetry(
      () => _chatCompletion(systemPrompt: _systemPrompt, userPrompt: prompt),
    );
  }

  /// Sinh quiz ôn nhanh từ ghi chú — JSON thuần, không dùng bảng flashcards.
  Future<String> generateNoteQuizRaw({
    required String title,
    required String content,
  }) async {
    _ensureApiKey();
    final prompt = '''
Từ ghi chú học tập dưới đây, tạo đúng 5 câu trắc nghiệm ôn nhanh.
Chỉ trả về JSON hợp lệ (không markdown fence), dạng:
{"questions":[{"question":"...","options":["A","B","C","D"],"correctIndex":0,"explanation":"..."}]}
correctIndex là số 0-3. Tiếng Việt. Bám sát nội dung ghi chú.

Tiêu đề: $title

Nội dung:
$content
''';
    return _withRetry(
      () => _chatCompletion(
        systemPrompt:
            '$_systemPrompt\nChỉ trả JSON hợp lệ, không giải thích thêm.',
        userPrompt: prompt,
      ),
    );
  }

  static const _systemPrompt = '''
Bạn là AI Coach của app StudyFlow AI, hỗ trợ sinh viên FPT University học tập (PRM393, PRO192, MOB1023...).
Trả lời tiếng Việt, ngắn gọn, thực tế.
Khi giải thích lập trình (Dart/Flutter, Java, SQL...), luôn kèm ví dụ code trong markdown với fence đúng ngôn ngữ (dart, java, sql, kotlin...).
''';

  Future<String> _chatCompletion({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': AppConstants.groqModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.7,
        'max_tokens': 2048,
      }),
    );

    if (response.statusCode != 200) {
      throw StateError(_parseError(response));
    }

    return _readTextFromJson(response.body);
  }

  String _parseError(http.Response response) {
    if (response.statusCode == 429) {
      return 'Hết quota Groq (rate limit).\n'
          'Free tier: ~30 request/phút, giới hạn theo ngày tùy model.\n\n'
          'Cách xử lý:\n'
          '1. Đợi 1–2 phút rồi thử lại\n'
          '2. Xem quota tại console.groq.com\n'
          '3. Dùng lịch sử AI offline (ai_cache)';
    }

    if (response.statusCode == 401) {
      return 'Groq API key không hợp lệ. Vào AI Hub → AI Quota để cập nhật key.';
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return 'Groq lỗi (${response.statusCode}): $message';
      }
    } catch (_) {}
    return 'Groq lỗi (${response.statusCode}): ${response.body}';
  }

  String _readTextFromJson(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw StateError('Groq không trả về nội dung. Thử lại sau.');
    }

    final message = (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
    final text = message?['content'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw StateError('Groq không trả về nội dung. Thử lại sau.');
    }
    return text.trim();
  }

  Future<T> _withRetry<T>(Future<T> Function() action, {int maxAttempts = 3}) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await action();
      } catch (e) {
        lastError = e;
        final message = e.toString();
        if (message.contains('429') ||
            message.contains('quota') ||
            message.contains('rate limit')) {
          break;
        }
        if (attempt == maxAttempts) break;
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
    throw StateError(
      lastError is StateError ? lastError.message : 'Groq lỗi sau $maxAttempts lần thử: $lastError',
    );
  }

  void _ensureApiKey() {
    if (_apiKey.isEmpty) {
      throw StateError(
        'Chưa cấu hình GROQ_KEY.\n'
        'Vào AI Hub → AI Quota và dán key từ console.groq.com/keys',
      );
    }
  }
}
