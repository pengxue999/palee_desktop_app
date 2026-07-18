import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/report_models.dart';
import '../../services/report_service.dart';
import '../../widgets/app_toast.dart';
import 'pdf_print_dialog.dart';

final ReportService _reportService = ReportService();

Future<void> showStudentReportPrintDialog({
  required BuildContext context,
  required List<StudentReportItem> students,
  required ReportFilters filters,
  required int totalCount,
  VoidCallback? onPreviewReady,
}) async {
  try {
    final pdfBytes = await _reportService.createStudentReportPdf(
      academicId: filters.academicId,
      provinceId: filters.provinceId,
      districtId: filters.districtId,
      scholarship: filters.scholarship,
      gender: filters.gender,
    );

    if (!context.mounted) {
      return;
    }

    onPreviewReady?.call();

    await showPdfPreviewDialog(
      context: context,
      pdfBytes: pdfBytes,
      documentId: DateFormat('yyyyMMdd_HHmmss').format(DateTime.now()),
      title: 'ພິມລາຍງານນັກຮຽນ',
      fileNamePrefix: 'student_report',
    );
  } catch (e) {
    if (context.mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດສ້າງ PDF ໄດ້: $e');
    }
  }
}
