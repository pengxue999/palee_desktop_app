import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/report_service.dart';
import '../../widgets/app_toast.dart';
import 'pdf_print_dialog.dart';

final ReportService _reportService = ReportService();

Future<void> showFinanceReportPrintDialog({
  required BuildContext context,
  String? academicId,
  int? year,
  required String tab,
  VoidCallback? onPreviewReady,
}) async {
  try {
    final pdfBytes = await _reportService.createFinanceReportPdf(
      academicId: academicId,
      year: year,
      tab: tab,
    );

    if (!context.mounted) {
      return;
    }

    onPreviewReady?.call();

    final normalizedTab = switch (tab) {
      'income' => 'income',
      'expense' => 'expense',
      _ => 'overview',
    };

    await showPdfPreviewDialog(
      context: context,
      pdfBytes: pdfBytes,
      documentId: DateFormat('yyyyMMdd_HHmmss').format(DateTime.now()),
      title: 'ພິມລາຍງານການເງິນ',
      fileNamePrefix: 'finance_report_$normalizedTab',
    );
  } catch (e) {
    if (context.mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດສ້າງ PDF ໄດ້: $e');
    }
  }
}
