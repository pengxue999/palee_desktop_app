import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/report_service.dart';
import '../../widgets/app_toast.dart';
import 'pdf_print_dialog.dart';

final ReportService _reportService = ReportService();

Future<void> showPopularSubjectReportPrintDialog({
  required BuildContext context,
  String? academicId,
  VoidCallback? onPreviewReady,
}) async {
  try {
    final pdfBytes = await _reportService.createPopularSubjectsReportPdf(
      academicId: academicId,
    );

    if (!context.mounted) {
      return;
    }

    onPreviewReady?.call();

    await showPdfPreviewDialog(
      context: context,
      pdfBytes: pdfBytes,
      documentId: DateFormat('yyyyMMdd_HHmmss').format(DateTime.now()),
      title: 'ພິມລາຍງານວິຊາຍອດນິຍົມ',
      fileNamePrefix: 'popular_subjects_report',
    );
  } catch (e) {
    if (context.mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດສ້າງ PDF ໄດ້: $e');
    }
  }
}

Future<void> showPopularSubjectLevelReportPrintDialog({
  required BuildContext context,
  String? academicId,
  required String subjectName,
  required String subjectCategory,
  required String levelName,
  VoidCallback? onPreviewReady,
}) async {
  try {
    final pdfBytes = await _reportService.createPopularSubjectLevelDetailPdf(
      academicId: academicId,
      subjectName: subjectName,
      subjectCategory: subjectCategory,
      levelName: levelName,
    );

    if (!context.mounted) {
      return;
    }

    onPreviewReady?.call();

    await showPdfPreviewDialog(
      context: context,
      pdfBytes: pdfBytes,
      documentId: DateFormat('yyyyMMdd_HHmmss').format(DateTime.now()),
      title: 'ພິມລາຍຊື່ $subjectName $levelName',
      fileNamePrefix: 'popular_subject_level_report',
    );
  } catch (e) {
    if (context.mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດສ້າງ PDF ໄດ້: $e');
    }
  }
}
