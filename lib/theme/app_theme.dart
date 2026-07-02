import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(isDark: false);
  static ThemeData dark() => _build(isDark: true);

  static ThemeData _build({required bool isDark}) {
    final scheme = isDark
        ? const ColorScheme.dark(
            primary: AppColors.primaryDark,
            secondary: AppColors.secondaryDark,
            surface: AppColors.surfaceDark,
            error: AppColors.error,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: AppColors.textPrimaryDark,
          )
        : const ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.surface,
            error: AppColors.error,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: AppColors.textPrimary,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      textTheme: AppTextStyles.textTheme(isDark: isDark),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: AppTextStyles.textTheme(isDark: false)
            .titleMedium
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? AppColors.surfaceDark : AppColors.divider,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: AppColors.divider),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider),
    );
  }
}
