import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/core/utils/format_utils.dart';
import 'package:palee_elite_training_center/core/utils/report_export_action_helper.dart';
import 'package:palee_elite_training_center/core/utils/teacher_attendance_report_printer.dart';
import 'package:palee_elite_training_center/models/teaching_log_model.dart';
import 'package:palee_elite_training_center/models/teacher_model.dart';
import 'package:palee_elite_training_center/providers/academic_year_provider.dart';
import 'package:palee_elite_training_center/providers/report_provider.dart';
import 'package:palee_elite_training_center/services/teaching_log_service.dart';
import 'package:palee_elite_training_center/services/teacher_service.dart';
import 'package:palee_elite_training_center/widgets/app_button.dart';
import 'package:palee_elite_training_center/widgets/app_data_table.dart';
import 'package:palee_elite_training_center/widgets/app_dropdown.dart';
import 'package:palee_elite_training_center/widgets/print_preparation_overlay.dart';
import 'package:palee_elite_training_center/widgets/summary_card.dart';

class ReportTeacherAttendanceScreen extends ConsumerStatefulWidget {
  const ReportTeacherAttendanceScreen({super.key});

  @override
  ConsumerState<ReportTeacherAttendanceScreen> createState() =>
      _ReportTeacherAttendanceScreenState();
}

class _ReportTeacherAttendanceScreenState
    extends ConsumerState<ReportTeacherAttendanceScreen> {
  final _logService = TeachingLogService();
  final _teacherService = TeacherService();

  List<TeachingLogModel> _logs = [];
  List<TeacherModel> _teachers = [];
  bool _isLoading = true;
  bool _isPreparingPdfPrint = false;
  String? _errorMessage;

  String _statusFilter = 'ທັງໝົດ';
  String? _selectedTeacherId;
  DateTime? _selectedMonth;

  Map<String, dynamic> _summary = {
    'taught_count': 0,
    'absent_count': 0,
    'total_hours': 0.0,
    'total_amount': 0.0,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  String _getCurrentAcademicYear() {
    final academicYearState = ref.read(academicYearProvider);
    if (academicYearState.selectedAcademicYear != null) {
      return academicYearState.selectedAcademicYear!.academicYear;
    }
    final activeYears = academicYearState.academicYears
        .where((ay) => ay.academicStatus == 'ດໍາເນີນການ')
        .toList();
    if (activeYears.isNotEmpty) {
      return activeYears.first.academicYear;
    }
    if (academicYearState.academicYears.isNotEmpty) {
      return academicYearState.academicYears.first.academicYear;
    }
    return '';
  }

  Future<void> _init() async {
    await ref.read(academicYearProvider.notifier).getAcademicYears();
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final academicYear = _getCurrentAcademicYear();
      final monthStr = _selectedMonth != null
          ? '${_selectedMonth!.year}-${_selectedMonth!.month.toString().padLeft(2, '0')}'
          : null;

      final teachersRes = await _teacherService.getTeachers();

      String? apiStatus;
      if (_statusFilter != 'ທັງໝົດ') {
        apiStatus = _statusFilter;
      }

      final logRes = await _logService.getAll(
        academicYear: academicYear,
        month: monthStr,
        status: apiStatus,
        teacherId: _selectedTeacherId,
      );

      final logs = logRes.data;
      final taughtCount = logs.where((l) => l.status == 'ຂຶ້ນສອນ').length;
      final absentCount = logs.where((l) => l.status == 'ຂາດສອນ').length;
      final totalHours = logs
          .where((l) => l.status == 'ຂຶ້ນສອນ')
          .fold(0.0, (sum, l) => sum + l.hourly);
      final totalAmount = logs
          .where((l) => l.status == 'ຂຶ້ນສອນ')
          .fold(0.0, (sum, l) => sum + l.totalAmount);

      setState(() {
        _teachers = teachersRes.data;
        _logs = logs;
        _summary = {
          'taught_count': taughtCount,
          'absent_count': absentCount,
          'total_hours': totalHours,
          'total_amount': totalAmount,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = 'ທັງໝົດ';
      _selectedTeacherId = null;
      _selectedMonth = null;
    });
    _loadData();
  }

  Future<void> _handleExport() async {
    final academicId = _getCurrentAcademicId();
    final monthStr = _selectedMonth != null
        ? '${_selectedMonth!.year}-${_selectedMonth!.month.toString().padLeft(2, '0')}'
        : null;

    await ReportExportActionHelper.exportReport(
      context: context,
      reportTitle: 'ລາຍງານການຂື້ນສອນຂອງອາຈານ',
      requestExport: (format) {
        return ref
            .read(reportProvider.notifier)
            .exportTeacherAttendanceReport(
              academicId: academicId,
              month: monthStr,
              status: _statusFilter != 'ທັງໝົດ' ? _statusFilter : null,
              teacherId: _selectedTeacherId,
              format: format,
            );
      },
      resolveErrorMessage: () =>
          ref.read(reportProvider).teacherAttendanceError ??
          'ບໍ່ສາມາດ Export ໄດ້',
    );
  }

  List<TeachingLogModel> get _filteredLogs {
    return _logs;
  }

  String? _getCurrentAcademicId() {
    final academicYearState = ref.read(academicYearProvider);
    if (academicYearState.selectedAcademicYear != null) {
      return academicYearState.selectedAcademicYear!.academicId;
    }

    final activeYears = academicYearState.academicYears
        .where((ay) => ay.academicStatus == 'ດໍາເນີນການ')
        .toList();
    if (activeYears.isNotEmpty) {
      return activeYears.first.academicId;
    }
    if (academicYearState.academicYears.isNotEmpty) {
      return academicYearState.academicYears.first.academicId;
    }
    return null;
  }

  Future<void> _handlePdfPrint() async {
    if (_isPreparingPdfPrint || _filteredLogs.isEmpty) {
      return;
    }

    final monthStr = _selectedMonth != null
        ? '${_selectedMonth!.year}-${_selectedMonth!.month.toString().padLeft(2, '0')}'
        : null;

    setState(() => _isPreparingPdfPrint = true);

    try {
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        return;
      }

      await showTeacherAttendanceReportPrintDialog(
        context: context,
        academicId: _getCurrentAcademicId(),
        month: monthStr,
        status: _statusFilter != 'ທັງໝົດ' ? _statusFilter : null,
        teacherId: _selectedTeacherId,
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
    final taught = (_summary['taught_count'] as num).toDouble();
    final absent = (_summary['absent_count'] as num).toDouble();
    final totalHours = (_summary['total_hours'] as num).toDouble();
    final totalAmount = (_summary['total_amount'] as num).toDouble();
    final hasAttendanceData = _filteredLogs.isNotEmpty;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SummaryCard(
                  label: 'ຂຶ້ນສອນ',
                  amount: taught,
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  bgColor: AppColors.success.withValues(alpha: 0.12),
                  formatKip: (v) => '${v.toInt()} ຄັ້ງ',
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  label: 'ຂາດສອນ',
                  amount: absent,
                  icon: Icons.cancel_outlined,
                  color: AppColors.destructive,
                  bgColor: AppColors.destructive.withValues(alpha: 0.12),
                  formatKip: (v) => '${v.toInt()} ຄັ້ງ',
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  label: 'ຈຳນວນຊົ່ວໂມງ (ຂຶ້ນສອນ)',
                  amount: totalHours,
                  icon: Icons.access_time_rounded,
                  color: AppColors.info,
                  bgColor: AppColors.info.withValues(alpha: 0.12),
                  formatKip: (v) => '${v.toStringAsFixed(0)} ຊ.ມ',
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  label: 'ຍອດລວມ (ຂຶ້ນສອນ)',
                  amount: totalAmount,
                  icon: Icons.attach_money_rounded,
                  color: AppColors.warning,
                  bgColor: AppColors.warning.withValues(alpha: 0.12),
                  formatKip: (v) => _formatKip(v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFilterSection(hasAttendanceData),
            const SizedBox(height: 16),
            Expanded(child: _buildDataTable()),
          ],
        ),
        if (_isPreparingPdfPrint)
          const PrintPreparationOverlay(
            icon: Icons.print_rounded,
            title: 'ກຳລັງໂຫຼດ...',
            message:
                'ລະບົບກຳລັງສ້າງ PDF ລາຍງານການຂື້ນສອນຂອງອາຈານ ແລະ ເປີດໜ້າຈໍ preview ສຳລັບການພິມ',
            hintText: 'ຈະເປີດ preview ອັດຕະໂນມັດ',
          ),
      ],
    );
  }

  Widget _buildFilterSection(bool hasAttendanceData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
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
              const Spacer(),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 200,
                child: AppDropdown<String>(
                  value: _selectedTeacherId,
                  hint: 'ທັງໝົດອາຈານ',
                  items: _teachers.map((t) {
                    return DropdownMenuItem(
                      value: t.teacherId,
                      child: Text(t.fullName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedTeacherId = value);
                    _loadData();
                  },
                ),
              ),
              const SizedBox(width: 12),
              _buildCompactMonthPicker(),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildCompactStatusSegment('ທັງໝົດ'),
                    _buildCompactStatusSegment('ຂຶ້ນສອນ'),
                    _buildCompactStatusSegment('ຂາດສອນ'),
                  ],
                ),
              ),
              const Spacer(),
              if (hasAttendanceData) ...[
                AppButton(
                  label: 'ສົ່ງອອກເປັນ Excel',
                  icon: Icons.download_rounded,
                  variant: AppButtonVariant.success,
                  size: AppButtonSize.medium,
                  onPressed: _isPreparingPdfPrint || _isLoading
                      ? null
                      : _handleExport,
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: _isPreparingPdfPrint ? 'ກຳລັງ ພິມ...' : 'ພິມ PDF',
                  icon: Icons.print,
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.medium,
                  onPressed: _isPreparingPdfPrint || _isLoading
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatusSegment(String label) {
    final selected = _statusFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (value) {
          setState(() => _statusFilter = label);
          _loadData();
        },
        labelStyle: TextStyle(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? Colors.white : AppColors.foreground,
          fontFamily: 'NotoSansLao',
        ),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.muted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildCompactMonthPicker() {
    final monthNames = [
      'ມັງກອນ',
      'ກຸມພາ',
      'ມີນາ',
      'ເມສາ',
      'ພຶດສະພາ',
      'ມິຖຸນາ',
      'ກໍລະກົດ',
      'ສິງຫາ',
      'ກັນຍາ',
      'ຕຸລາ',
      'ພະຈິກ',
      'ທັນວາ',
    ];

    final monthItems = <DropdownMenuItem<DateTime>>[];
    final now = DateTime.now();
    for (int month = 1; month <= 12; month++) {
      final date = DateTime(now.year, month, 1);
      monthItems.add(
        DropdownMenuItem(value: date, child: Text(monthNames[month - 1])),
      );
    }

    return SizedBox(
      width: 180,
      child: AppDropdown<DateTime>(
        hint: 'ເລືອກເດືອນ',
        value: _selectedMonth,
        items: monthItems,
        onChanged: (value) {
          setState(() => _selectedMonth = value);
          _loadData();
        },
      ),
    );
  }

  Widget _buildDataTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
            const SizedBox(height: 16),
            Text(
              'ເກີດຂໍ້ຜິດພາດ: $_errorMessage',
              style: TextStyle(color: AppColors.destructive),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'ລອງໃໝ່',
              icon: Icons.refresh,
              onPressed: _loadData,
            ),
          ],
        ),
      );
    }

    final filteredLogs = _filteredLogs;

    final columns = [
      DataColumnDef<TeachingLogModel>(
        key: 'teacherFullName',
        label: 'ອາຈານ',
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      DataColumnDef<TeachingLogModel>(
        key: 'subjectName',
        label: 'ວິຊາ',
        render: (v, row) => Text(
          row.isSubstitute && row.substituteForSubjectName != null
              ? row.substituteForSubjectName!
              : v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14),
        ),
      ),
      DataColumnDef<TeachingLogModel>(
        key: 'levelName',
        label: 'ລະດັບ',
        render: (v, row) => Text(
          row.isSubstitute && row.substituteForLevelName != null
              ? row.substituteForLevelName!
              : v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14),
        ),
      ),
      DataColumnDef<TeachingLogModel>(
        key: 'hourly',
        label: 'ຊ.ມ',
        render: (v, _) => Text(
          (double.tryParse(v?.toString() ?? '0') ?? 0).toStringAsFixed(0),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      DataColumnDef<TeachingLogModel>(
        key: 'hourlyRate',
        label: 'ຄ່າສອນ/ຊມ',
        render: (v, _) => Text(
          '${_formatNum(double.tryParse(v?.toString() ?? '0') ?? 0)} ກີບ',
          style: const TextStyle(fontSize: 14),
        ),
      ),
      DataColumnDef<TeachingLogModel>(
        key: 'totalAmount',
        label: 'ຈຳນວນເງິນ',
        render: (v, _) {
          final amount = double.tryParse(v?.toString() ?? '0') ?? 0;
          return Text(
            _formatCurrency(amount),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          );
        },
      ),
      DataColumnDef<TeachingLogModel>(
        key: 'status',
        label: 'ສະຖານະ',
        render: (v, row) {
          final status = v?.toString() ?? 'ຂຶ້ນສອນ';
          final isPresent = status == 'ຂຶ້ນສອນ';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPresent
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.destructive.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPresent ? AppColors.success : AppColors.destructive,
              ),
            ),
          );
        },
      ),
      DataColumnDef<TeachingLogModel>(
        key: 'teachingDate',
        label: 'ວັນທີ',
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 13)),
      ),
    ];

    return AppDataTable<TeachingLogModel>(
      data: filteredLogs,
      columns: columns,
      isLoading: _isLoading,
    );
  }

  String _formatKip(double value) {
    return FormatUtils.formatKip(value.toInt());
  }

  String _formatNum(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatCurrency(double value) {
    return '${_formatNum(value)} ₭';
  }
}
