import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/report_models.dart';
import '../../services/report_service.dart';
import '../../widgets/app_toast.dart';
import 'pdf_print_dialog.dart';

final ReportService _reportService = ReportService();

Future<void> showRegistrationReportPrintDialog({
  required BuildContext context,
  required RegistrationReportFilters filters,
  VoidCallback? onPreviewReady,
}) async {
  try {
    final pdfBytes = await _reportService.createRegistrationReportPdf(
      academicId: filters.academicId,
      subjectId: filters.subjectId,
      levelId: filters.levelId,
      status: filters.status,
      scholarship: filters.scholarship,
    );

    if (!context.mounted) {
      return;
    }

    onPreviewReady?.call();

    await showPdfPreviewDialog(
      context: context,
      pdfBytes: pdfBytes,
      documentId: DateFormat('yyyyMMdd_HHmmss').format(DateTime.now()),
      title: 'ພິມລາຍງານການລົງທະບຽນ',
      fileNamePrefix: 'registration_report',
    );
  } catch (e) {
    if (context.mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດສ້າງ PDF ໄດ້: $e');
    }
  }
}
