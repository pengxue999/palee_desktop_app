import 'package:flutter/material.dart';

import '../../services/report_service.dart';
import '../../widgets/app_toast.dart';
import 'pdf_print_dialog.dart';

final ReportService _reportService = ReportService();

Future<void> showTeacherAttendanceReportPrintDialog({
  required BuildContext context,
  String? academicId,
  String? month,
  String? status,
  String? teacherId,
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

    final pdfBytes = await _reportService.createTeacherAttendanceReportPdf(
      academicId: academicId,
      month: month,
      status: status,
      teacherId: teacherId,
    );

    if (!context.mounted) {
      return;
    }

    onPreviewReady?.call();

    await showPdfPreviewDialog(
      context: context,
      pdfBytes: pdfBytes,
      documentId: '${teacherPart}_$datePart',
      title: 'ພິມລາຍງານການຂື້ນສອນຂອງອາຈານ',
      fileNamePrefix: 'ລາຍງານການເຂົ້າສອນ',
    );
  } catch (e) {
    if (context.mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດສ້າງ PDF ໄດ້: $e');
    }
  }
}
