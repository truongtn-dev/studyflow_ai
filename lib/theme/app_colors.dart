import 'package:flutter/material.dart';

/// Design tokens – StudyFlow AI "Calm Focus"
abstract final class AppColors {
  // Light
  static const primary = Color(0xFF5B5FEF);
  static const primaryContainer = Color(0xFFEEF0FF);
  static const secondary = Color(0xFF0D9488);
  static const secondaryContainer = Color(0xFFCCFBF1);
  static const accent = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F5F9);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const divider = Color(0xFFE2E8F0);

  // Dark
  static const primaryDark = Color(0xFF818CF8);
  static const backgroundDark = Color(0xFF0F172A);
  static const surfaceDark = Color(0xFF1E293B);
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const secondaryDark = Color(0xFF2DD4BF);

  // Task status
  static const statusTodo = Color(0xFF64748B);
  static const statusDoing = primary;
  static const statusDone = secondary;
  static const statusOverdue = error;
}
