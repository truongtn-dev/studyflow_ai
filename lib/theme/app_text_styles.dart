import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextTheme textTheme({required bool isDark}) {
    final color = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondary = isDark ? AppColors.textSecondary : AppColors.textSecondary;
    final base = GoogleFonts.plusJakartaSansTextTheme();

    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
    );
  }

  static TextStyle timerStyle({required bool isDark}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.primaryDark : AppColors.primary,
    );
  }
}
