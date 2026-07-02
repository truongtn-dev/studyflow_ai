import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

class AiQuotaService {
  static String _key(int userId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return 'ai_quota_${userId}_$today';
  }

  Future<int> getRemaining(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt(_key(userId)) ?? 0;
    return (AppConstants.maxAiRequestsPerDay - used).clamp(0, AppConstants.maxAiRequestsPerDay);
  }

  Future<int> getUsed(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(userId)) ?? 0;
  }

  Future<bool> canRequest(int userId) async {
    return (await getRemaining(userId)) > 0;
  }

  Future<void> increment(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt(_key(userId)) ?? 0;
    await prefs.setInt(_key(userId), used + 1);
  }
}
