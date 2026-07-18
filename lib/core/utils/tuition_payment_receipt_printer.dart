import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/tuition_payment_service.dart';
import '../../widgets/app_toast.dart';
import 'pdf_print_dialog.dart';

final TuitionPaymentService _tuitionPaymentService = TuitionPaymentService();

Future<void> showTuitionPaymentPrintDialog({
  required BuildContext context,
  required String paymentId,
  VoidCallback? onPreviewReady,
}) async {
  try {
    final pdfBytes = await _tuitionPaymentService
        .createTuitionPaymentReceiptPdf(paymentId);

    if (!context.mounted) {
      return;
    }

    onPreviewReady?.call();

    await showPdfPreviewDialog(
      context: context,
      pdfBytes: Uint8List.fromList(pdfBytes),
      documentId: paymentId,
      title: 'ພິມໃບບິນຄ່າຮຽນ',
      fileNamePrefix: 'tuition_payment',
    );
  } catch (e) {
    if (context.mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດສ້າງໃບບິນໄດ້: $e');
    }
  }
}
