import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/popular_subject_report_printer.dart';
import '../../core/utils/report_export_action_helper.dart';
import '../../models/report_models.dart';
import '../../models/academic_year_model.dart';
import '../../providers/report_provider.dart';
import '../../providers/academic_year_provider.dart';
import '../../services/report_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_widget.dart';
import '../../widgets/print_preparation_overlay.dart';

class ReportPopularSubjectScreen extends ConsumerStatefulWidget {
  const ReportPopularSubjectScreen({super.key});

  @override
  ConsumerState<ReportPopularSubjectScreen> createState() =>
      _ReportPopularSubjectScreenState();
}

class _ReportPopularSubjectScreenState
    extends ConsumerState<ReportPopularSubjectScreen> {
  String? _selectedAcademicYear;
  String? _selectedSubjectCategory;
  final ReportService _reportService = ReportService();
  bool _isLoading = false;
  bool _isExporting = false;
  bool _isPreparingPdfPrint = false;
  String? _activeLevelExportKey;
  String? _activeLevelPrintKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      ref.read(academicYearProvider.notifier).getAcademicYears(),
    ]);
    _setDefaultAcademicYear();
    setState(() => _isLoading = false);
  }

  void _setDefaultAcademicYear() {
    final academicYears = ref.read(academicYearProvider).academicYears;
    final activeYear = academicYears.firstWhere(
      (y) => y.academicStatus == 'ດໍາເນີນການ',
      orElse: () => academicYears.isNotEmpty
          ? academicYears.first
          : const AcademicYearModel(
              academicYear: '',
              startDate: '',
              endDate: '',
            ),
    );
    if (activeYear.academicYear.isNotEmpty) {
      setState(() => _selectedAcademicYear = activeYear.academicYear);
      _loadPopularSubjectsReport();
    }
  }

  Future<void> _loadPopularSubjectsReport() async {
    final academicYears = ref.read(academicYearProvider).academicYears;
    final selectedYear = academicYears.firstWhere(
      (y) => y.academicYear == _selectedAcademicYear,
      orElse: () => academicYears.isNotEmpty
          ? academicYears.first
          : const AcademicYearModel(
              academicYear: '',
              startDate: '',
              endDate: '',
            ),
    );

    await ref
        .read(reportProvider.notifier)
        .getPopularSubjectsReport(
          academicId: selectedYear.academicId!.isNotEmpty
              ? selectedYear.academicId
              : null,
        );
  }

  PopularSubjectsReportData? get _reportData {
    return ref.watch(reportProvider).popularSubjectsData;
  }

  List<PopularSubjectItem> get _filteredSubjects {
    final subjects = _reportData?.subjects ?? [];
    if (_selectedSubjectCategory == null) return subjects;
    return subjects
        .where((s) => s.subjectCategory == _selectedSubjectCategory)
        .toList();
  }

  List<LevelStatsItem> get _filteredLevels {
    final levels = _reportData?.levels ?? [];
    if (_selectedSubjectCategory == null) return levels;
    return levels
        .where((l) => l.subjectCategory == _selectedSubjectCategory)
        .toList();
  }

  int get _totalStudents {
    return _reportData?.summary.totalStudents ?? 0;
  }

  String? get _selectedAcademicId {
    final academicYears = ref.read(academicYearProvider).academicYears;
    final selectedYear = academicYears.where(
      (y) => y.academicYear == _selectedAcademicYear,
    );
    if (selectedYear.isEmpty) {
      return null;
    }
    final academicId = selectedYear.first.academicId;
    if (academicId == null || academicId.isEmpty) {
      return null;
    }
    return academicId;
  }

  Future<void> _handleExport() async {
    if (_isExporting || _reportData == null || _filteredSubjects.isEmpty) {
      return;
    }

    setState(() => _isExporting = true);

    try {
      await ReportExportActionHelper.exportReport(
        context: context,
        reportTitle: 'ລາຍງານວິຊາຍອດນິຍົມ',
        requestExport: (format) async {
          final exportResponse = await _reportService
              .exportPopularSubjectsReport(
                academicId: _selectedAcademicId,
                format: format,
              );
          return exportResponse.data;
        },
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Export ບໍ່ສຳເລັດ: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _handlePdfPrint() async {
    if (_isPreparingPdfPrint ||
        _reportData == null ||
        _filteredSubjects.isEmpty) {
      return;
    }

    setState(() => _isPreparingPdfPrint = true);

    try {
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        return;
      }

      await showPopularSubjectReportPrintDialog(
        context: context,
        academicId: _selectedAcademicId,
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

  @override
  Widget build(BuildContext context) {
    final academicYears = ref.watch(academicYearProvider).academicYears;
    final reportState = ref.watch(reportProvider);
    final filteredSubjects = _filteredSubjects;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            onRefresh: () async {
              await _loadInitialData();
              await _loadPopularSubjectsReport();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilters(
                  academicYears,
                  hasData: filteredSubjects.isNotEmpty,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading || reportState.isPopularSubjectsLoading
                      ? const LoadingWidget(message: 'ກຳລັງໂຫຼດຂໍ້ມູນ...')
                      : reportState.popularSubjectsError != null
                      ? _buildErrorWidget(reportState.popularSubjectsError!)
                      : _reportData == null || filteredSubjects.isEmpty
                      ? EmptyWidget(
                          title: 'ບໍ່ມີຂໍ້ມູນ',
                          subtitle: 'ບໍ່ພົບຂໍ້ມູນວິຊາສຳລັບສົກຮຽນທີ່ເລືອກ',
                          icon: Icons.school_outlined,
                        )
                      : _buildOverviewTab(filteredSubjects),
                ),
              ],
            ),
          ),
        ),
        if (_isPreparingPdfPrint)
          const PrintPreparationOverlay(
            icon: Icons.print_rounded,
            title: 'ກຳລັງໂຫຼດ...',
            message:
                'ລະບົບກຳລັງສ້າງ PDF ລາຍງານວິຊາຍອດນິຍົມ ແລະ ເປີດໜ້າຈໍ preview ສຳລັບການພິມ',
            hintText: 'ຈະເປີດ preview ອັດຕະໂນມັດ',
          ),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    return AppCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.destructive, size: 48),
          const SizedBox(height: 16),
          Text(
            'ເກີດຂໍ້ຜິດພາດ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: AppColors.mutedForeground),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(
            onPressed: () {
              ref.read(reportProvider.notifier).clearPopularSubjectsError();
              _loadPopularSubjectsReport();
            },
            label: 'ລອງໃໝ່',
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    List<AcademicYearModel> academicYears, {
    required bool hasData,
  }) {
    return Row(
      spacing: 16,
      children: [
        SizedBox(
          width: 180,
          child: AppDropdown<String>(
            value: _selectedAcademicYear,
            items: academicYears.map((year) {
              return DropdownMenuItem(
                value: year.academicYear,
                child: Text(year.academicYear, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedAcademicYear = value);
              _loadPopularSubjectsReport();
            },
            hint: 'ສົກຮຽນ',
          ),
        ),
        const Spacer(),
        AppButton(
          label: _isExporting ? 'ກຳລັງບັນທຶກ...' : 'ສົ່ງອອກເປັນ Excel',
          icon: Icons.download_rounded,
          variant: AppButtonVariant.success,
          onPressed: _isExporting || _isPreparingPdfPrint || !hasData
              ? null
              : _handleExport,
        ),
        AppButton(
          label: _isPreparingPdfPrint ? 'ກຳລັງ ພິມ...' : 'ພິມ PDF',
          icon: Icons.print_rounded,
          variant: AppButtonVariant.primary,
          onPressed: _isExporting || _isPreparingPdfPrint || !hasData
              ? null
              : _handlePdfPrint,
        ),
      ],
    );
  }

  Widget _buildOverviewTab(List<PopularSubjectItem> subjects) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSubjectPieChart(subjects)),
              const SizedBox(width: 16),
              Expanded(child: _buildCategoryBarChart()),
            ],
          ),
          const SizedBox(height: 16),
          _buildTopSubjectsCard(subjects),
          const SizedBox(height: 16),
          _buildLevelsSection(),
        ],
      ),
    );
  }

  String _levelActionKey(LevelStatsItem level) {
    return '${level.subjectName}|${level.subjectCategory}|${level.levelName}';
  }

  Future<void> _handleLevelExport(LevelStatsItem level) async {
    final actionKey = _levelActionKey(level);
    if (_activeLevelExportKey != null) {
      return;
    }

    setState(() => _activeLevelExportKey = actionKey);
    try {
      await ReportExportActionHelper.exportReport(
        context: context,
        reportTitle: '${level.subjectName} ${level.levelName}',
        requestExport: (format) async {
          final exportResponse = await _reportService
              .exportPopularSubjectLevelDetailReport(
                academicId: _selectedAcademicId,
                subjectName: level.subjectName,
                subjectCategory: level.subjectCategory,
                levelName: level.levelName,
                format: format,
              );
          return exportResponse.data;
        },
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Export ບໍ່ສຳເລັດ: $e');
      }
    } finally {
      if (mounted && _activeLevelExportKey == actionKey) {
        setState(() => _activeLevelExportKey = null);
      }
    }
  }

  Future<void> _handleLevelPdfPrint(LevelStatsItem level) async {
    final actionKey = _levelActionKey(level);
    if (_activeLevelPrintKey != null) {
      return;
    }

    setState(() => _activeLevelPrintKey = actionKey);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }

      await showPopularSubjectLevelReportPrintDialog(
        context: context,
        academicId: _selectedAcademicId,
        subjectName: level.subjectName,
        subjectCategory: level.subjectCategory,
        levelName: level.levelName,
        onPreviewReady: () {
          if (mounted && _activeLevelPrintKey == actionKey) {
            setState(() => _activeLevelPrintKey = null);
          }
        },
      );
    } finally {
      if (mounted && _activeLevelPrintKey == actionKey) {
        setState(() => _activeLevelPrintKey = null);
      }
    }
  }

  Widget _buildSubjectPieChart(List<PopularSubjectItem> subjects) {
    if (subjects.isEmpty) {
      return AppCard(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                color: AppColors.mutedForeground,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'ບໍ່ມີຂໍ້ມູນ',
                style: TextStyle(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
      );
    }

    final colors = [
      AppColors.primary,
      AppColors.success,
      const Color.fromARGB(255, 255, 140, 0),
      const Color.fromARGB(255, 255, 0, 0),
      const Color.fromARGB(255, 245, 1, 123),
    ];

    final totalStudents = _totalStudents;
    final sortedSubjects = List.from(subjects)
      ..sort((a, b) => b.studentCount.compareTo(a.studentCount));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ສັດສ່ວນນັກຮຽນຕາມວິຊາ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: sortedSubjects.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final percentage = totalStudents > 0
                      ? (item.studentCount / totalStudents) * 100
                      : 0;
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: item.studentCount.toDouble(),
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 160,
                    titleStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 1,
                centerSpaceRadius: 2,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: sortedSubjects.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.subjectName} (${item.studentCount} ຄົນ)',
                    style: TextStyle(fontSize: 14, color: AppColors.foreground),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBarChart() {
    final categoryStats = _reportData?.categories ?? {};

    if (categoryStats.isEmpty) {
      return AppCard(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                color: AppColors.mutedForeground,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'ບໍ່ມີຂໍ້ມູນ',
                style: TextStyle(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
      );
    }

    final maxY = categoryStats.values.reduce((a, b) => a > b ? a : b);
    final interval = maxY > 0 ? maxY / 5 : 10;

    final sortedEntries = categoryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ສະຖິຕິຕາມໝວດວິຊາ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY > 0 ? maxY * 1.2 : 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = sortedEntries[groupIndex];
                      return BarTooltipItem(
                        '${item.key}\n',
                        const TextStyle(color: Colors.white, fontSize: 12),
                        children: [
                          TextSpan(
                            text: '${item.value} ຄົນ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '${value.toInt()} ຄົນ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedForeground,
                          ),
                        );
                      },
                      interval: interval > 0 ? interval.toDouble() : 10.0,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedEntries.length) {
                          return const SizedBox.shrink();
                        }
                        return RotatedBox(
                          quarterTurns: 0,
                          child: Text(
                            sortedEntries[index].key.length > 10
                                ? '${sortedEntries[index].key.substring(0, 10)}...'
                                : sortedEntries[index].key,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.foreground,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: interval > 0 ? interval.toDouble() : 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: AppColors.border, strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: sortedEntries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: item.value.toDouble(),
                        color: AppColors.primary,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTopSubjectsCard(List<PopularSubjectItem> subjects) {
    final sortedSubjects = List.from(subjects)
      ..sort((a, b) => b.studentCount.compareTo(a.studentCount));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ວິຊານິຍົມອັນດັບສູງສຸດ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedSubjects.take(5).toList().asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final subject = entry.value;
            final percentage = _totalStudents > 0
                ? (subject.studentCount / _totalStudents) * 100
                : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? AppColors.primary
                          : AppColors.infoLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          color: rank <= 3
                              ? Colors.white
                              : AppColors.foreground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              subject.subjectName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                subject.subjectCategory,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 8,
                          backgroundColor: AppColors.muted,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${subject.studentCount} ຄົນ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLevelsSection() {
    final levelData = List<LevelStatsItem>.from(_filteredLevels)
      ..sort((a, b) => b.studentCount.compareTo(a.studentCount));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ລາຍລະອຽດຕາມລະດັບ/ຊັ້ນ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(0.7),
                1: FlexColumnWidth(2.0),
                2: FlexColumnWidth(1.8),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(1.0),
                5: FlexColumnWidth(1.2),
              },
              border: TableBorder.symmetric(
                inside: BorderSide(color: AppColors.border),
                outside: BorderSide(color: AppColors.border),
              ),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: AppColors.muted),
                  children: [
                    _buildTableHeaderCell('ລຳດັບ'),
                    _buildTableHeaderCell('ວິຊາ'),
                    _buildTableHeaderCell('ໝວດ'),
                    _buildTableHeaderCell('ລະດັບ/ຊັ້ນ'),
                    _buildTableHeaderCell('ນັກຮຽນ'),
                    _buildTableHeaderCell('ຈັດການ'),
                  ],
                ),
                ...levelData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: index.isEven
                          ? AppColors.card
                          : AppColors.muted.withValues(alpha: 0.25),
                    ),
                    children: [
                      _buildTableBodyCell('${index + 1}'),
                      _buildTableBodyCell(
                        row.subjectName,
                        fontWeight: FontWeight.w600,
                      ),
                      _buildTableBodyCell(
                        row.subjectCategory,
                        textColor: AppColors.secondary,
                      ),
                      _buildTableBodyCell(row.levelName),
                      _buildTableBodyCell(
                        '${row.studentCount} ຄົນ',
                        fontWeight: FontWeight.w600,
                        textColor: AppColors.success,
                      ),
                      _buildLevelActionCell(row),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelActionCell(LevelStatsItem level) {
    final actionKey = _levelActionKey(level);
    final isExporting = _activeLevelExportKey == actionKey;
    final isPrinting = _activeLevelPrintKey == actionKey;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message:
                'ສົ່ງອອກ Excel ສະເພາະ ${level.subjectName} ${level.levelName}',
            child: IconButton(
              onPressed: isExporting || isPrinting
                  ? null
                  : () => _handleLevelExport(level),
              icon: isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded, size: 20),
              color: AppColors.success,
              splashRadius: 20,
            ),
          ),
          Tooltip(
            message: 'ພິມ PDF ສະເພາະ ${level.subjectName} ${level.levelName}',
            child: IconButton(
              onPressed: isExporting || isPrinting
                  ? null
                  : () => _handleLevelPdfPrint(level),
              icon: isPrinting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print_rounded, size: 20),
              color: AppColors.primary,
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, {bool isRightAligned = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        textAlign: isRightAligned ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.mutedForeground,
        ),
      ),
    );
  }

  Widget _buildTableBodyCell(
    String text, {
    bool isRightAligned = false,
    FontWeight fontWeight = FontWeight.w400,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        textAlign: isRightAligned ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: 14,
          fontWeight: fontWeight,
          color: textColor ?? AppColors.foreground,
        ),
      ),
    );
  }
}

class SubjectStats {
  final String subjectName;
  final String subjectCategory;
  final int levelCount;
  final int studentCount;
  final double totalFee;
  final double avgFee;
  final List<String> levels;

  SubjectStats({
    required this.subjectName,
    required this.subjectCategory,
    required this.levelCount,
    required this.studentCount,
    required this.totalFee,
    required this.avgFee,
    required this.levels,
  });
}

class LevelStats {
  final String levelName;
  final int studentCount;
  final double fee;

  LevelStats({
    required this.levelName,
    required this.studentCount,
    required this.fee,
  });
}
