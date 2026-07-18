import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/core/utils/assessment_report_printer.dart';
import 'package:palee_elite_training_center/core/utils/format_utils.dart';
import 'package:palee_elite_training_center/core/utils/report_export_action_helper.dart';
import 'package:palee_elite_training_center/models/evaluation_model.dart';
import 'package:palee_elite_training_center/providers/assessment_report_provider.dart';
import 'package:palee_elite_training_center/widgets/api_error_handler.dart';
import 'package:palee_elite_training_center/widgets/app_button.dart';
import 'package:palee_elite_training_center/widgets/app_card.dart';
import 'package:palee_elite_training_center/widgets/app_data_table.dart';
import 'package:palee_elite_training_center/widgets/app_dropdown.dart';
import 'package:palee_elite_training_center/widgets/print_preparation_overlay.dart';

import '../../services/report_service.dart';

class ReportAssessmentScreen extends ConsumerStatefulWidget {
  const ReportAssessmentScreen({super.key});

  @override
  ConsumerState<ReportAssessmentScreen> createState() =>
      _ReportAssessmentScreenState();
}

class _ReportAssessmentScreenState
    extends ConsumerState<ReportAssessmentScreen> {
  static const _semesters = [
    {'value': 'all', 'label': 'ທັງໝົດ'},
    {'value': 'MIDTERM', 'label': 'ກາງພາກ'},
    {'value': 'FINAL', 'label': 'ທ້າຍພາກ'},
  ];
  static const _rankOptions = ['1', '2', '3'];

  final ReportService _reportService = ReportService();

  String? _selectedSemester;
  String? _selectedSubjectId;
  String? _selectedLevelId;
  String? _selectedRanking;
  bool _isPreparingPdfPrint = false;

  int? get _selectedRankingValue => int.tryParse(_selectedRanking ?? '');

  String _semesterLabel(String semester) {
    switch (semester) {
      case 'MIDTERM':
        return 'ກາງພາກ';
      case 'FINAL':
        return 'ທ້າຍພາກ';
      case 'all':
        return 'ທັງໝົດ';
      default:
        return semester;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _resetFiltersAndReload();
    });
  }

  Future<void> _loadReport() async {
    if (_selectedSemester == null) {
      ref.read(assessmentReportProvider.notifier).clear();
      return;
    }

    await ref
        .read(assessmentReportProvider.notifier)
        .loadReport(semester: _selectedSemester!);

    final state = ref.read(assessmentReportProvider);
    if (!mounted) return;
    if (state.error != null) {
      ApiErrorHandler.handle(context, state.error!);
    }
  }

  Future<void> _resetFiltersAndReload() async {
    setState(() {
      _selectedSemester = 'all';
      _selectedSubjectId = null;
      _selectedLevelId = null;
      _selectedRanking = null;
    });

    await _loadReport();
  }

  Future<void> _handleExport() async {
    if (_selectedSemester == null) {
      ApiErrorHandler.handle(context, 'ກະລຸນາເລືອກຮອບປະເມີນ');
      return;
    }

    await ReportExportActionHelper.exportReport(
      context: context,
      reportTitle: 'ລາຍງານຜົນການຮຽນ',
      requestExport: (format) {
        return _reportService
            .exportAssessmentReport(
              semester: _selectedSemester!,
              subjectId: _selectedSubjectId,
              levelId: _selectedLevelId,
              ranking: _selectedRanking,
              format: format,
            )
            .then((response) => response.data);
      },
      resolveErrorMessage: () => 'ບໍ່ສາມາດ Export ລາຍງານໄດ້',
    );
  }

  Future<void> _handlePdfPrint() async {
    if (_selectedSemester == null || _isPreparingPdfPrint) {
      if (_selectedSemester == null) {
        ApiErrorHandler.handle(context, 'ກະລຸນາເລືອກຮອບປະເມີນ');
      }
      return;
    }

    setState(() => _isPreparingPdfPrint = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }

      await showAssessmentReportPrintDialog(
        context: context,
        semester: _selectedSemester!,
        subjectId: _selectedSubjectId,
        levelId: _selectedLevelId,
        ranking: _selectedRanking,
        onPreviewReady: () {
          if (mounted && _isPreparingPdfPrint) {
            setState(() => _isPreparingPdfPrint = false);
          }
        },
      );
    } finally {
      if (mounted && _isPreparingPdfPrint) {
        setState(() => _isPreparingPdfPrint = false);
      }
    }
  }

  List<AssessmentReportItem> _filterItems(List<AssessmentReportItem> items) {
    final filtered = items.where((item) {
      if (_selectedSubjectId != null && item.subjectId != _selectedSubjectId) {
        return false;
      }
      if (_selectedLevelId != null && item.levelId != _selectedLevelId) {
        return false;
      }
      if (_selectedRankingValue != null &&
          item.ranking != _selectedRankingValue) {
        return false;
      }
      return true;
    }).toList();

    // ຈັດລຽງຕາມອັນດັບ 1, 2, 3, ... ໃຫ້ຄືກັນກັບ PDF ແລະ Excel.
    filtered.sort((a, b) => a.ranking.compareTo(b.ranking));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(assessmentReportProvider);
    final filteredItems = _filterItems(reportState.items);
    final canExport = _selectedSemester != null && filteredItems.isNotEmpty;
    final availableSubjects = {
      for (final item in reportState.items) item.subjectId: item.subjectName,
    }.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final availableLevels = {
      for (final item in reportState.items)
        if (_selectedSubjectId == null || item.subjectId == _selectedSubjectId)
          item.levelId: item.levelName,
    }.entries.toList()..sort((a, b) => a.value.compareTo(b.value));

    final columns = [
      DataColumnDef<AssessmentReportItem>(
        key: 'fullName',
        label: 'ນັກຮຽນ',
        flex: 3,
        render: (value, row) => Text(row.fullName),
      ),

      DataColumnDef<AssessmentReportItem>(
        key: 'subjectName',
        label: 'ວິຊາ',
        flex: 2,
        render: (value, row) => Text(row.subjectName),
      ),
      DataColumnDef<AssessmentReportItem>(
        key: 'levelName',
        label: 'ຊັ້ນຮຽນ/ລະດັບ',
        flex: 2,
        render: (value, row) => Text(row.levelName),
      ),
      DataColumnDef<AssessmentReportItem>(
        key: 'semester',
        label: 'ຮອບປະເມີນ',
        flex: 2,
        render: (value, row) => Text(_semesterLabel(row.semester)),
      ),
      DataColumnDef<AssessmentReportItem>(
        key: 'score',
        label: 'ຄະແນນ',
        flex: 1,
        render: (value, row) => Text(row.score.toStringAsFixed(2)),
      ),
      DataColumnDef<AssessmentReportItem>(
        key: 'ranking',
        label: 'ອັນດັບ',
        flex: 1,
        render: (value, row) => Text(row.ranking.toString()),
      ),
      DataColumnDef<AssessmentReportItem>(
        key: 'prize',
        label: 'ລາງວັນ',
        flex: 2,
        render: (value, row) => Text(
          row.prize == null ? '-' : FormatUtils.formatCurrency(row.prize!),
        ),
      ),
      DataColumnDef<AssessmentReportItem>(
        key: 'districtName',
        label: 'ເມືອງ',
        flex: 2,
        render: (value, row) => Text(row.districtName ?? '-'),
      ),
      DataColumnDef<AssessmentReportItem>(
        key: 'provinceName',
        label: 'ແຂວງ',
        flex: 2,
        render: (value, row) => Text(row.provinceName ?? '-'),
      ),
    ];

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.filter_alt_sharp,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ຕົວກອງ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                      Spacer(),
                      TextButton.icon(
                        onPressed: reportState.isLoading
                            ? null
                            : _resetFiltersAndReload,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: 180,
                        child: AppDropdown<String>(
                          label: 'ຮອບປະເມີນ',
                          value: _selectedSemester,
                          items: _semesters.map((item) {
                            return DropdownMenuItem(
                              value: item['value'],
                              child: Text(item['label'] ?? ''),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            setState(() {
                              _selectedSemester = value;
                              _selectedSubjectId = null;
                              _selectedLevelId = null;
                              _selectedRanking = null;
                            });
                            await _loadReport();
                          },
                          hint: 'ເລືອກຮອບປະເມີນ',
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: AppDropdown<String>(
                          label: 'ວິຊາ',
                          value: _selectedSubjectId,
                          items: availableSubjects
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.key,
                                  child: Text(item.value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSubjectId = value;
                              _selectedLevelId = null;
                            });
                          },
                          hint: 'ທັງໝົດ',
                          enabled: _selectedSemester != null,
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: AppDropdown<String>(
                          label: 'ລະດັບ',
                          value: _selectedLevelId,
                          items: availableLevels
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.key,
                                  child: Text(item.value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedLevelId = value);
                          },
                          hint: 'ທັງໝົດ',
                          enabled: _selectedSemester != null,
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: AppDropdown<String>(
                          label: 'ອັນດັບ',
                          value: _selectedRanking,
                          items: _rankOptions
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedRanking = value);
                          },
                          hint: 'ທັງໝົດ',
                          enabled: _selectedSemester != null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedSemester != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    if (canExport) ...[
                      AppButton(
                        label: 'ສົ່ງອອກເປັນ Excel',
                        icon: Icons.download_rounded,
                        variant: AppButtonVariant.success,
                        onPressed: _handleExport,
                      ),
                      const SizedBox(width: 12),
                      AppButton(
                        label: _isPreparingPdfPrint ? 'ກຳລັງພິມ...' : 'ພິມ PDF',
                        icon: Icons.print_rounded,
                        onPressed: _isPreparingPdfPrint
                            ? null
                            : _handlePdfPrint,
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.muted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text(
                          'ບໍ່ມີຂໍ້ມູນ ຈຶ່ງບໍ່ສາມາດ Export ຫຼື ພິມໄດ້',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),

                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${filteredItems.length} ລາຍການ',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: AppDataTable<AssessmentReportItem>(
                data: filteredItems,
                columns: columns,
                searchKeys: const [
                  'fullName',
                  'studentId',
                  'provinceName',
                  'districtName',
                  'subjectName',
                  'levelName',
                  'semester',
                  'ranking',
                ],
                isLoading: reportState.isLoading,
              ),
            ),
          ],
        ),
        if (_isPreparingPdfPrint)
          const PrintPreparationOverlay(
            icon: Icons.print_rounded,
            title: 'ກຳລັງໂຫຼດ...',
            message: 'ກຳລັງຈັດກຽມ PDF ສຳລັບການພິມ',
          ),
      ],
    );
  }
}
