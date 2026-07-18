import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'app_button.dart';

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmLabel;
  final String? cancelLabel;
  final IconData? icon;
  final Color? iconColor;
  final AppButtonVariant confirmVariant;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'ຢືນຢັນ',
    this.cancelLabel = 'ຍົກເລີກ',
    this.icon,
    this.iconColor,
    this.confirmVariant = AppButtonVariant.primary,
    this.onConfirm,
    this.onCancel,
  });

  factory AppConfirmDialog.delete({
    Key? key,
    required String itemName,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return AppConfirmDialog(
      key: key,
      title: 'ຢືນຢັນການລຶບ',
      message: 'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "$itemName"?\n\nການກະທຳນີ້ບໍ່ສາມາດຍົກເລີກໄດ້.',
      confirmLabel: 'ລຶບ',
      cancelLabel: 'ຍົກເລີກ',
      icon: Icons.delete_forever_rounded,
      iconColor: AppColors.destructive,
      confirmVariant: AppButtonVariant.danger,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  factory AppConfirmDialog.warning({
    Key? key,
    required String title,
    required String message,
    String? confirmLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return AppConfirmDialog(
      key: key,
      title: title,
      message: message,
      confirmLabel: confirmLabel ?? 'ຢືນຢັນ',
      cancelLabel: 'ຍົກເລີກ',
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.warning,
      confirmVariant: AppButtonVariant.primary,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  factory AppConfirmDialog.info({
    Key? key,
    required String title,
    required String message,
    String? confirmLabel,
    VoidCallback? onConfirm,
  }) {
    return AppConfirmDialog(
      key: key,
      title: title,
      message: message,
      confirmLabel: confirmLabel ?? 'ເຂົ້າໃຈ',
      icon: Icons.info_rounded,
      iconColor: AppColors.primary,
      confirmVariant: AppButtonVariant.primary,
      onConfirm: onConfirm,
      onCancel: () {},
    );
  }

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    IconData? icon,
    Color? iconColor,
    AppButtonVariant confirmVariant = AppButtonVariant.primary,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        iconColor: iconColor,
        confirmVariant: confirmVariant,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  static Future<bool?> showDelete({
    required BuildContext context,
    required String itemName,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppConfirmDialog.delete(
        itemName: itemName,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: iconColor ?? AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
            ],

            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: cancelLabel!,
                    variant: AppButtonVariant.ghost,
                    onPressed: onCancel ?? () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: confirmLabel!,
                    variant: confirmVariant,
                    onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
