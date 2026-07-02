import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum SfButtonVariant { filled, outlined, text }

class SfButton extends StatelessWidget {
  const SfButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SfButtonVariant.filled,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final SfButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Text(label),
            ],
          );

    Widget button;
    switch (variant) {
      case SfButtonVariant.filled:
        button = FilledButton(onPressed: isLoading ? null : onPressed, child: child);
      case SfButtonVariant.outlined:
        button = OutlinedButton(onPressed: isLoading ? null : onPressed, child: child);
      case SfButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: child,
        );
    }

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
