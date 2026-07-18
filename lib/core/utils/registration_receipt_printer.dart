import 'package:flutter/material.dart';

import '../../services/registration_service.dart';
import '../../widgets/app_toast.dart';
import 'pdf_print_dialog.dart';

final RegistrationService _registrationService = RegistrationService();

Future<void> showRegistrationPrintDialog({
  required BuildContext context,
  required String registrationId,
  VoidCallback? onPreviewReady,
}) async {
  try {
    final pdfBytes = await _registrationService.getRegistrationReceiptPdf(
      registrationId,
    );

    if (!context.mounted) {
      return;
    }

    onPreviewReady?.call();

    await showPdfPreviewDialog(
      context: context,
      pdfBytes: pdfBytes,
      documentId: registrationId,
      title: 'ພິມໃບລົງທະບຽນ',
      fileNamePrefix: 'register',
    );
  } catch (e) {
    if (context.mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດດຶງໃບລົງທະບຽນຈາກ API ໄດ້: $e');
    }
  }
}

Future<void> printRegistrationReceipt({
  required BuildContext context,
  required String registrationId,
  VoidCallback? onPreviewReady,
}) => showRegistrationPrintDialog(
  context: context,
  registrationId: registrationId,
  onPreviewReady: onPreviewReady,
);
