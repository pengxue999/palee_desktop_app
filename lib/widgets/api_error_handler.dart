import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'app_toast.dart';
import 'app_confirm_dialog.dart';
import 'success_overlay.dart';

class ApiErrorHandler {
  static void handle(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
  }) {
    final errorString = error.toString();

    if (errorString.contains('SocketException') ||
        errorString.contains('Connection refused') ||
        errorString.contains('network')) {
      _handleNetworkError(context, onRetry);
      return;
    }

    final message = _extractMessage(errorString);

    final type = _determineToastType(errorString);

    switch (type) {
      case ToastType.success:
        SuccessOverlay.show(context, message: message);
        break;
      case ToastType.warning:
        AppToast.warning(context, message);
        break;
      case ToastType.error:
        AppToast.error(context, message);
        break;
      case ToastType.info:
        AppToast.info(context, message);
        break;
    }
  }

  static String _extractMessage(String error) {
    final jsonStart = error.indexOf('{');
    final jsonEnd = error.lastIndexOf('}');

    if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
      return error;
    }

    try {
      final jsonString = error.substring(jsonStart, jsonEnd + 1);
      final Map<String, dynamic> body = jsonDecode(jsonString);

      final msg = body['messages'] ?? body['message'];
      if (msg is String && msg.isNotEmpty) return msg;

      final code = body['code'];
      if (code is String) return _codeToMessage(code);
    } catch (_) {
    }

    return error;
  }

  static String _codeToMessage(String code) {
    switch (code) {
      case 'NOT_FOUND':
        return 'ບໍ່ພົບຂໍ້ມູນ';
      case 'CONFLICT':
        return 'ຂໍ້ມູນຊ້ຳກັນ';
      case 'FOREIGN_KEY_CONSTRAINT':
        return 'ບໍ່ສາມາດລຶບຂໍ້ມູນໄດ້ ເນື່ອງຈາກມີຂໍ້ມູນອື່ນອ້າງອິງ';
      case 'VALIDATION_ERROR':
        return 'ຂໍ້ມູນບໍ່ຖືກຕ້ອງ';
      case 'UNAUTHORIZED':
        return 'ບໍ່ມີສິດເຂົ້າໃຊ້';
      default:
        return 'ເກີດຂໍ້ຜິດພາດ: $code';
    }
  }

  static ToastType _determineToastType(String error) {
    final lower = error.toLowerCase();

    if (lower.contains('success')) {
      return ToastType.success;
    }
    if (lower.contains('foreign_key') ||
        lower.contains('constraint') ||
        lower.contains('ບໍ່ສາມາດລຶບ')) {
      return ToastType.warning;
    }
    return ToastType.error;
  }

  static void _handleNetworkError(BuildContext context, VoidCallback? onRetry) {
    AppConfirmDialog.show(
      context: context,
      title: 'ບໍ່ສາມາດເຊື່ອມຕໍ່ເຄື່ອງແມ່ຂ່າຍ',
      message: 'ກະລຸນາກວດສອບການເຊື່ອມຕໍ່ອິນເຕີເນັດ ຫຼື ລອງໃໝ່ອີກຄັ້ງ',
      confirmLabel: 'ລອງໃໝ່',
      cancelLabel: 'ຍົກເລີກ',
      icon: Icons.wifi_off_rounded,
      iconColor: AppColors.warning,
    ).then((confirmed) {
      if (confirmed == true && onRetry != null) {
        onRetry();
      }
    });
  }
}

class AppAlert {
  static void success(BuildContext context, String message) =>
      SuccessOverlay.show(context, message: message);
  static void error(BuildContext context, String message) =>
      AppToast.error(context, message);
  static void warning(BuildContext context, String message) =>
      AppToast.warning(context, message);
  static void info(BuildContext context, String message) =>
      AppToast.info(context, message);

  static Future<bool?> confirmDelete(BuildContext context, String itemName) {
    return AppConfirmDialog.showDelete(context: context, itemName: itemName);
  }
}
