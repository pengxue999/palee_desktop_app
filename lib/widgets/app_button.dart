import 'package:flutter/material.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    final (bgColor, fgColor) = _getColors(isDisabled);
    final (padding, textStyle) = _getSize();

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (icon != null && !isLoading) ...[
          Icon(icon, size: 16, color: fgColor),
          const SizedBox(width: 6),
        ],
        Text(label, style: textStyle.copyWith(color: fgColor)),
      ],
    );

    final button = Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: padding,
          alignment: Alignment.center,
          child: buttonContent,
        ),
      ),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  (Color, Color) _getColors(bool isDisabled) {
    if (isDisabled) {
      return (AppColors.muted, AppColors.mutedForeground);
    }
    switch (variant) {
      case AppButtonVariant.primary:
        return (AppColors.primary, AppColors.primaryForeground);
      case AppButtonVariant.secondary:
        return (AppColors.accent, AppColors.accentForeground);
      case AppButtonVariant.outline:
        return (Colors.transparent, AppColors.foreground);
      case AppButtonVariant.ghost:
        return (Colors.transparent, AppColors.mutedForeground);
      case AppButtonVariant.danger:
        return (AppColors.destructive, AppColors.destructiveForeground);
      case AppButtonVariant.success:
        return (AppColors.success, AppColors.successForeground);
    }
  }

  (EdgeInsets, TextStyle) _getSize() {
    switch (size) {
      case AppButtonSize.small:
        return (
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        );
      case AppButtonSize.medium:
        return (
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        );
      case AppButtonSize.large:
        return (
          const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        );
    }
  }
}

enum AppButtonVariant { primary, secondary, outline, ghost, danger, success }

enum AppButtonSize { small, medium, large }
