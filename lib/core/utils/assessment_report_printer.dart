import 'package:flutter/material.dart';

import '../../services/report_service.dart';
import '../../widgets/app_toast.dart';
import 'pdf_print_dialog.dart';

final ReportService _reportService = ReportService();

Future<void> showAssessmentReportPrintDialog({
  required BuildContext context,
  String? academicId,
  required String semester,
  String? subjectId,
  String? levelId,
  String? ranking,
  VoidCallback? onPreviewReady,
}) async {
  try {
    final datePart = DateTime.now()
        .toIso8601String()
        .split('T')
        .first
        .replaceAll('-', '');

    final pdfBytes = await _reportService.createAssessmentReportPdf(
      academicId: academicId,
      semester: semester,
      subjectId: subjectId,
      levelId: levelId,
      ranking: ranking,
    );

    if (!context.mounted) {
      return;
    }

    onPreviewReady?.call();

    await showPdfPreviewDialog(
      context: context,
      pdfBytes: pdfBytes,
      documentId: 'assessment_$datePart',
      title: 'ພິມລາຍງານຜົນການຮຽນ',
      fileNamePrefix: 'ລາຍງານຜົນການຮຽນ',
    );
  } catch (e) {
    if (context.mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດສ້າງ PDF ໄດ້: $e');
    }
  }
}
