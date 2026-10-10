import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, accent, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading ? const SizedBox.shrink() : Icon(icon ?? Icons.arrow_forward),
          label: child,
          style: _buttonStyle(),
        ),
      AppButtonVariant.accent => FilledButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading ? const SizedBox.shrink() : Icon(icon ?? Icons.arrow_forward),
          label: child,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.terracotta,
            foregroundColor: AppColors.forest,
            minimumSize: const Size(0, 52),
            shape: _shape,
          ),
        ),
      AppButtonVariant.secondary => OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading ? const SizedBox.shrink() : Icon(icon ?? Icons.arrow_forward),
          label: child,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            shape: _shape,
          ),
        ),
      AppButtonVariant.text => TextButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading ? const SizedBox.shrink() : Icon(icon ?? Icons.arrow_forward),
          label: child,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 52),
            shape: _shape,
          ),
        ),
    };

    return SizedBox(width: expand ? double.infinity : 240, child: button);
  }

  static const _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  static ButtonStyle _buttonStyle() => FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: _shape,
      );
}
