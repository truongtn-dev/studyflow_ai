import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_cache_entry.dart';
import '../models/chat_message.dart';
import '../repositories/ai_cache_repository.dart';
import '../repositories/course_repository.dart';
import '../repositories/task_repository.dart';
import '../services/ai_quota_service.dart';
import '../services/groq_service.dart';
import '../utils/constants.dart';

class AiProvider extends ChangeNotifier {
  AiProvider({
    GroqService? groqService,
    AiCacheRepository? cacheRepository,
    AiQuotaService? quotaService,
    CourseRepository? courseRepository,
    TaskRepository? taskRepository,
  })  : _groq = groqService ?? GroqService(),
        _cache = cacheRepository ?? AiCacheRepository(),
        _quota = quotaService ?? AiQuotaService(),
        _courses = courseRepository ?? CourseRepository(),
        _tasks = taskRepository ?? TaskRepository();

  final GroqService _groq;
  final AiCacheRepository _cache;
  final AiQuotaService _quota;
  final CourseRepository _courses;
  final TaskRepository _tasks;

  int _userId = 1;
  bool _loading = false;
  String? _error;
  final List<ChatMessage> _messages = [];
  String? _studyPlanResult;
  String? _explainResult;
  List<AiCacheEntry> _history = [];
  int _remainingQuota = AppConstants.maxAiRequestsPerDay;

  int get userId => _userId;
  bool get isLoading => _loading;
  String? get error => _error;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String? get studyPlanResult => _studyPlanResult;
  String? get explainResult => _explainResult;
  List<AiCacheEntry> get history => List.unmodifiable(_history);
  int get remainingQuota => _remainingQuota;
  bool get hasApiKey => _groq.hasApiKey;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt(AppConstants.sessionUserIdKey) ?? 1;
    await _refreshQuota();
    await loadHistory();
    notifyListeners();
  }

  Future<void> setUserSession(int userId) async {
    _userId = userId;
    _error = null;
    _messages.clear();
    _studyPlanResult = null;
    _explainResult = null;
    await _refreshQuota();
    await loadHistory();
    notifyListeners();
  }

  Future<void> _refreshQuota() async {
    _remainingQuota = await _quota.getRemaining(_userId);
  }

  Future<bool> _canUseAi({bool requireStudyData = false}) async {
    if (!_groq.hasApiKey) {
      _error =
          'Chưa cấu hình GROQ_KEY. Lấy key miễn phí tại console.groq.com/keys';
      notifyListeners();
      return false;
    }

    if (!await _quota.canRequest(_userId)) {
      _error =
          'Đã hết ${AppConstants.maxAiRequestsPerDay} lượt AI hôm nay. Xem lại lịch sử offline.';
      notifyListeners();
      return false;
    }

    if (requireStudyData) {
      final courseCount = (await _courses.getByUserId(_userId)).length;
      final taskCount = await _tasks.countByUserId(_userId);
      if (courseCount < AppConstants.minCoursesForAi ||
          taskCount < AppConstants.minTasksForStudyPlan) {
        _error =
            'Cần ít nhất ${AppConstants.minCoursesForAi} môn và ${AppConstants.minTasksForStudyPlan} task để gợi ý lịch học.';
        notifyListeners();
        return false;
      }
    }

    return true;
  }

  Future<void> sendChat(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) return;
    if (!await _canUseAi()) return;

    _error = null;
    _messages.add(ChatMessage(text: trimmed, isUser: true, timestamp: DateTime.now()));
    _loading = true;
    notifyListeners();

    try {
      final hash = AiCacheRepository.hashPrompt(AiPromptType.chat.value, trimmed);
      final cached = await _cache.findByHash(
        userId: _userId,
        promptType: AiPromptType.chat.value,
        promptHash: hash,
      );

      String reply;
      if (cached != null) {
        reply = cached.response;
      } else {
        reply = await _groq.chat(_buildChatPrompt(trimmed));
        await _saveCache(AiPromptType.chat.value, hash, reply);
        await _quota.increment(_userId);
        await _refreshQuota();
      }

      _messages.add(ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()));
    } catch (e) {
      _error = e.toString().replaceFirst('StateError: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> generateStudyPlan() async {
    if (_loading) return;
    if (!await _canUseAi(requireStudyData: true)) return;

    _error = null;
    _loading = true;
    _studyPlanResult = null;
    notifyListeners();

    try {
      final courses = await _courses.getByUserId(_userId);
      final tasks = await _tasks.getByUserId(_userId);
      final contextKey = '${courses.length}_${tasks.map((t) => t.id).join(',')}';
      final hash = AiCacheRepository.hashPrompt(AiPromptType.studyPlan.value, contextKey);

      final cached = await _cache.findByHash(
        userId: _userId,
        promptType: AiPromptType.studyPlan.value,
        promptHash: hash,
      );

      if (cached != null) {
        _studyPlanResult = cached.response;
      } else {
        _studyPlanResult = await _groq.generateStudyPlan(courses: courses, tasks: tasks);
        await _saveCache(AiPromptType.studyPlan.value, hash, _studyPlanResult!);
        await _quota.increment(_userId);
        await _refreshQuota();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('StateError: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> explainConcept(String concept) async {
    final trimmed = concept.trim();
    if (trimmed.isEmpty || _loading) return;
    if (!await _canUseAi()) return;

    _error = null;
    _loading = true;
    _explainResult = null;
    notifyListeners();

    try {
      final hash = AiCacheRepository.hashPrompt(AiPromptType.explain.value, trimmed);
      final cached = await _cache.findByHash(
        userId: _userId,
        promptType: AiPromptType.explain.value,
        promptHash: hash,
      );

      if (cached != null) {
        _explainResult = cached.response;
      } else {
        _explainResult = await _groq.explainConcept(trimmed);
        await _saveCache(AiPromptType.explain.value, hash, _explainResult!);
        await _quota.increment(_userId);
        await _refreshQuota();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('StateError: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    _history = await _cache.getHistory(_userId);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _cache.clearHistory(_userId);
    _history = [];
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  String _buildChatPrompt(String userMessage) {
    return '''
Bạn là AI Coach của app StudyFlow AI, hỗ trợ sinh viên FPT học tập (PRM393, PRO192, MOB1023...).
Trả lời tiếng Việt, ngắn gọn, thực tế.
Khi giải thích lập trình (Dart/Flutter, Java, SQL...), luôn kèm ví dụ code trong markdown:
```dart
// ví dụ ngắn
```
Dùng đúng ngôn ngữ trong fence (dart, java, sql, kotlin...). Giải thích trước/sau code.
Câu hỏi: $userMessage
''';
  }

  Future<void> _saveCache(String type, String hash, String response) async {
    await _cache.insert(
      AiCacheEntry(
        userId: _userId,
        promptType: type,
        promptHash: hash,
        response: response,
      ),
    );
    await loadHistory();
  }
}
