import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/tuition_payment_service.dart';
import '../../widgets/app_toast.dart';
import 'pdf_print_dialog.dart';

final TuitionPaymentService _tuitionPaymentHistoryService =
    TuitionPaymentService();

Future<void> showTuitionPaymentHistoryPrintDialog({
  required BuildContext context,
  required String registrationId,
  VoidCallback? onPreviewReady,
}) async {
  try {
    final pdfBytes = await _tuitionPaymentHistoryService
        .createTuitionPaymentHistoryPdf(registrationId);

    if (!context.mounted) {
      return;
    }

    onPreviewReady?.call();

    await showPdfPreviewDialog(
      context: context,
      pdfBytes: Uint8List.fromList(pdfBytes),
      documentId: registrationId,
      title: 'ພິມສະຫຼຸບການຈ່າຍຄ່າຮຽນ',
      fileNamePrefix: 'tuition_payment_history',
    );
  } catch (e) {
    if (context.mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດສ້າງສະຫຼຸບການຈ່າຍໄດ້: $e');
    }
  }
}
