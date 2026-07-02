import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SfCard extends StatelessWidget {
  const SfCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (isDark ? AppColors.surfaceDark : AppColors.surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.surfaceDark : AppColors.divider,
        ),
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}
