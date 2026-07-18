import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/report_service.dart';
import '../../widgets/app_toast.dart';
import 'pdf_print_dialog.dart';

final ReportService _reportService = ReportService();

Future<void> showDonationReportPrintDialog({
  required BuildContext context,
  String? donorId,
  String? donationCategory,
  int? year,
  VoidCallback? onPreviewReady,
}) async {
  try {
    final pdfBytes = await _reportService.createDonationReportPdf(
      donorId: donorId,
      donationCategory: donationCategory,
      year: year,
    );

    if (!context.mounted) {
      return;
    }

    onPreviewReady?.call();

    await showPdfPreviewDialog(
      context: context,
      pdfBytes: pdfBytes,
      documentId: DateFormat('yyyyMMdd_HHmmss').format(DateTime.now()),
      title: 'ພິມລາຍງານການບໍລິຈາກ',
      fileNamePrefix: 'donation_report',
    );
  } catch (e) {
    if (context.mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດສ້າງ PDF ໄດ້: $e');
    }
  }
}
