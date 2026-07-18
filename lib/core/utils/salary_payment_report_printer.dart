import 'package:flutter/material.dart';

import '../../services/report_service.dart';
import '../../widgets/app_toast.dart';
import 'pdf_print_dialog.dart';

final ReportService _reportService = ReportService();

Future<void> showSalaryPaymentReportPrintDialog({
  required BuildContext context,
  int? month,
  String? teacherId,
  String? status,
  VoidCallback? onPreviewReady,
}) async {
  try {
    final datePart = DateTime.now()
        .toIso8601String()
        .split('T')
        .first
        .replaceAll('-', '');
    final teacherPart = (teacherId != null && teacherId.trim().isNotEmpty)
        ? teacherId.trim()
        : 'ທັງໝົດ';
    final monthPart = month?.toString().padLeft(2, '0') ?? 'all';

    final pdfBytes = await _reportService.createSalaryPaymentReportPdf(
      month: month,
      teacherId: teacherId,
      status: status,
    );

    if (!context.mounted) {
      return;
    }

    onPreviewReady?.call();

    await showPdfPreviewDialog(
      context: context,
      pdfBytes: pdfBytes,
      documentId: '${teacherPart}_$monthPart\_$datePart',
      title: 'ພິມລາຍງານເບີກຈ່າຍເງິນສອນ',
      fileNamePrefix: 'ລາຍງານເງິນສອນ',
    );
  } catch (e) {
    if (context.mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດສ້າງ PDF ໄດ້: $e');
    }
  }
}
