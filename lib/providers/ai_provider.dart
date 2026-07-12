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

  int? _userId;
  bool _loading = false;
  String? _error;
  final List<ChatMessage> _messages = [];
  String? _studyPlanResult;
  String? _explainResult;
  List<AiCacheEntry> _history = [];
  int _remainingQuota = AppConstants.maxAiRequestsPerDay;

  int? get userId => _userId;
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
    await _loadApiKey(prefs);
    _userId = prefs.getInt(AppConstants.sessionUserIdKey);
    if (_userId != null) {
      await _refreshQuota();
      await loadHistory();
    }
    notifyListeners();
  }

  Future<void> _loadApiKey(SharedPreferences prefs) async {
    const compileTimeKey =
        String.fromEnvironment(AppConstants.groqKeyEnv);
    var key = prefs.getString(AppConstants.groqKeyPrefsKey)?.trim() ?? '';
    if (key.isEmpty && compileTimeKey.isNotEmpty) {
      key = compileTimeKey.trim();
      await prefs.setString(AppConstants.groqKeyPrefsKey, key);
    }
    _groq.updateApiKey(key);
  }

  /// Save Groq key locally so plain `flutter run` works (no --dart-define).
  Future<void> saveApiKey(String key) async {
    final trimmed = key.trim();
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(AppConstants.groqKeyPrefsKey);
    } else {
      await prefs.setString(AppConstants.groqKeyPrefsKey, trimmed);
    }
    _groq.updateApiKey(trimmed);
    _error = null;
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

  Future<void> clearSession() async {
    _userId = null;
    _error = null;
    _messages.clear();
    _studyPlanResult = null;
    _explainResult = null;
    _history = [];
    _remainingQuota = AppConstants.maxAiRequestsPerDay;
    notifyListeners();
  }

  Future<void> _refreshQuota() async {
    if (_userId == null) {
      _remainingQuota = AppConstants.maxAiRequestsPerDay;
      return;
    }
    _remainingQuota = await _quota.getRemaining(_userId!);
  }

  Future<bool> _canUseAi({bool requireStudyData = false}) async {
    if (_userId == null) {
      _error = 'Vui lòng đăng nhập để dùng AI.';
      notifyListeners();
      return false;
    }
    final uid = _userId!;

    if (!_groq.hasApiKey) {
      _error =
          'Chưa cấu hình GROQ_KEY. Vào AI Hub → AI Quota để dán key (console.groq.com/keys).';
      notifyListeners();
      return false;
    }

    if (!await _quota.canRequest(uid)) {
      _error =
          'Đã hết ${AppConstants.maxAiRequestsPerDay} lượt AI hôm nay. Xem lại lịch sử offline.';
      notifyListeners();
      return false;
    }

    if (requireStudyData) {
      final courseCount = (await _courses.getByUserId(uid)).length;
      final taskCount = await _tasks.countByUserId(uid);
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
    final uid = _userId!;

    _error = null;
    _messages.add(ChatMessage(text: trimmed, isUser: true, timestamp: DateTime.now()));
    _loading = true;
    notifyListeners();

    try {
      final hash = AiCacheRepository.hashPrompt(AiPromptType.chat.value, trimmed);
      final cached = await _cache.findByHash(
        userId: uid,
        promptType: AiPromptType.chat.value,
        promptHash: hash,
      );

      String reply;
      if (cached != null) {
        reply = cached.response;
      } else {
        reply = await _groq.chat(_buildChatPrompt(trimmed));
        await _saveCache(uid, AiPromptType.chat.value, hash, reply);
        await _quota.increment(uid);
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
    final uid = _userId!;

    _error = null;
    _loading = true;
    _studyPlanResult = null;
    notifyListeners();

    try {
      final courses = await _courses.getByUserId(uid);
      final tasks = await _tasks.getByUserId(uid);
      final contextKey = '${courses.length}_${tasks.map((t) => t.id).join(',')}';
      final hash = AiCacheRepository.hashPrompt(AiPromptType.studyPlan.value, contextKey);

      final cached = await _cache.findByHash(
        userId: uid,
        promptType: AiPromptType.studyPlan.value,
        promptHash: hash,
      );

      if (cached != null) {
        _studyPlanResult = cached.response;
      } else {
        _studyPlanResult = await _groq.generateStudyPlan(courses: courses, tasks: tasks);
        await _saveCache(uid, AiPromptType.studyPlan.value, hash, _studyPlanResult!);
        await _quota.increment(uid);
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
    final uid = _userId!;

    _error = null;
    _loading = true;
    _explainResult = null;
    notifyListeners();

    try {
      final hash = AiCacheRepository.hashPrompt(AiPromptType.explain.value, trimmed);
      final cached = await _cache.findByHash(
        userId: uid,
        promptType: AiPromptType.explain.value,
        promptHash: hash,
      );

      if (cached != null) {
        _explainResult = cached.response;
      } else {
        _explainResult = await _groq.explainConcept(trimmed);
        await _saveCache(uid, AiPromptType.explain.value, hash, _explainResult!);
        await _quota.increment(uid);
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
    if (_userId == null) {
      _history = [];
      notifyListeners();
      return;
    }
    _history = await _cache.getHistory(_userId!);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    if (_userId == null) return;
    await _cache.clearHistory(_userId!);
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

  Future<void> _saveCache(int uid, String type, String hash, String response) async {
    await _cache.insert(
      AiCacheEntry(
        userId: uid,
        promptType: type,
        promptHash: hash,
        response: response,
      ),
    );
    await loadHistory();
  }
}
