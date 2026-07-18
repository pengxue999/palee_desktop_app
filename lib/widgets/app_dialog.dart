import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? footer;
  final VoidCallback onClose;
  final AppDialogSize size;

  const AppDialog({
    super.key,
    required this.title,
    required this.child,
    required this.onClose,
    this.footer,
    this.size = AppDialogSize.medium,
  });

  double _getWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    switch (size) {
      case AppDialogSize.small:
        return 400;
      case AppDialogSize.medium:
        return 600;
      case AppDialogSize.large:
        return 800;
      case AppDialogSize.extraLarge:
        return 1000;
      case AppDialogSize.full:
        return screenWidth * 0.9;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: _getWidth(context),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.mutedForeground,
                    ),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: child,
              ),
            ),
            if (footer != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                  color: AppColors.muted,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [footer!],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum AppDialogSize { small, medium, large, extraLarge, full }

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final ConfirmDialogType type;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    required this.onCancel,
    this.type = ConfirmDialogType.danger,
  });

  Color _getColor() {
    switch (type) {
      case ConfirmDialogType.danger:
        return AppColors.destructive;
      case ConfirmDialogType.warning:
        return AppColors.warning;
      case ConfirmDialogType.info:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      content: Text(
        message,
        style: const TextStyle(color: AppColors.mutedForeground),
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('ຍົກເລີກ')),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
          child: const Text('ຢືນຢັນ'),
        ),
      ],
    );
  }
}

enum ConfirmDialogType { danger, warning, info }
