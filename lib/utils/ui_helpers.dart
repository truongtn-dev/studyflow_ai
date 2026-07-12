import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared UI helpers for consistent light/dark screens.
abstract final class UiHelpers {
  static Color scaffoldBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.backgroundDark : AppColors.background;
  }

  static Color surface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.surfaceDark : AppColors.surface;
  }

  static Color textPrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  }

  static Color parseHex(String? hex, {Color fallback = AppColors.primary}) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    try {
      final cleaned = hex.trim().replaceFirst('#', '');
      if (cleaned.length == 6) {
        return Color(int.parse('FF$cleaned', radix: 16));
      }
      if (cleaned.length == 8) {
        return Color(int.parse(cleaned, radix: 16));
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  static Map<String, dynamic> prepareInsert(Map<String, dynamic> map) {
    final result = Map<String, dynamic>.from(map)..remove('id');
    final created = result['created_at'];
    if (created == null || (created is String && created.isEmpty)) {
      result.remove('created_at');
    }
    return result;
  }
}
