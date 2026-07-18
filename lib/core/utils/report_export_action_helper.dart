import 'package:flutter/material.dart';

import '../../models/report_models.dart';
import '../../widgets/app_toast.dart';
import 'report_export_file_helper.dart';

enum ReportExportFormat {
  excel(
    apiValue: 'excel',
    extension: 'xlsx',
    label: 'Excel (.xlsx)',
    description: 'ແນະນຳສຳລັບການເປີດໃນ Excel ແລະ ຈັດຮູບແບບລາຍງານ',
  ),
  csv(
    apiValue: 'csv',
    extension: 'csv',
    label: 'CSV (.csv)',
    description: 'ເໝາະສຳລັບນຳໄປ import ຫຼື ໃຊ້ຕໍ່ກັບລະບົບອື່ນ',
  );

  const ReportExportFormat({
    required this.apiValue,
    required this.extension,
    required this.label,
    required this.description,
  });

  final String apiValue;
  final String extension;
  final String label;
  final String description;
}

class ReportExportActionHelper {
  ReportExportActionHelper._();

  static Future<void> exportReport({
    required BuildContext context,
    required String reportTitle,
    required Future<ExportReportData?> Function(String format) requestExport,
    String? Function()? resolveErrorMessage,
  }) async {
    final selectedFormat = await _showFormatPicker(
      context,
      reportTitle: reportTitle,
    );

    if (selectedFormat == null || !context.mounted) {
      return;
    }

    final exportData = await requestExport(selectedFormat.apiValue);
    if (!context.mounted) {
      return;
    }
    if (exportData == null) {
      AppToast.error(
        context,
        resolveErrorMessage?.call() ?? 'ບໍ່ສາມາດ Export ຂໍ້ມູນໄດ້',
      );
      return;
    }

    final savedPath = await ReportExportFileHelper.saveExportFile(exportData);
    if (!context.mounted || savedPath == null) {
      return;
    }

    final fileLabel = savedPath.toLowerCase().endsWith('.csv')
        ? 'CSV'
        : 'Excel';
    AppToast.success(context, 'ບັນທຶກ $fileLabel ສຳເລັດ ຢູ່ທີ: $savedPath');
  }

  static Future<ReportExportFormat?> _showFormatPicker(
    BuildContext context, {
    required String reportTitle,
  }) {
    return showDialog<ReportExportFormat>(
      context: context,
      builder: (dialogContext) {
        var selectedFormat = ReportExportFormat.excel;
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('ເລືອກຮູບແບບໄຟລ໌'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ສົ່ງອອກລາຍງານ: $reportTitle'),
                  const SizedBox(height: 16),
                  _ExportFormatOption(
                    title: ReportExportFormat.excel.label,
                    description: ReportExportFormat.excel.description,
                    recommended: true,
                    isSelected: selectedFormat == ReportExportFormat.excel,
                    onTap: () {
                      setState(() {
                        selectedFormat = ReportExportFormat.excel;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _ExportFormatOption(
                    title: ReportExportFormat.csv.label,
                    description: ReportExportFormat.csv.description,
                    isSelected: selectedFormat == ReportExportFormat.csv,
                    onTap: () {
                      setState(() {
                        selectedFormat = ReportExportFormat.csv;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('ຍົກເລີກ'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(selectedFormat);
                  },
                  child: const Text('ຕົກລົງ'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ExportFormatOption extends StatelessWidget {
  const _ExportFormatOption({
    required this.title,
    required this.description,
    required this.onTap,
    required this.isSelected,
    this.recommended = false,
  });

  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isSelected;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.06)
              : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected || recommended
                ? theme.colorScheme.primary
                : theme.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 18,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.disabledColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (recommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Default',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
