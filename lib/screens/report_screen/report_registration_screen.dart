import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/core/utils/registration_report_printer.dart';
import 'package:palee_elite_training_center/core/utils/report_export_action_helper.dart';
import 'package:palee_elite_training_center/models/report_models.dart';
import 'package:palee_elite_training_center/providers/academic_year_provider.dart';
import 'package:palee_elite_training_center/providers/level_provider.dart';
import 'package:palee_elite_training_center/providers/report_provider.dart';
import 'package:palee_elite_training_center/providers/subject_provider.dart';
import 'package:palee_elite_training_center/widgets/app_button.dart';
import 'package:palee_elite_training_center/widgets/app_card.dart';
import 'package:palee_elite_training_center/widgets/app_data_table.dart';
import 'package:palee_elite_training_center/widgets/app_dropdown.dart';
import 'package:palee_elite_training_center/widgets/print_preparation_overlay.dart';

class ReportRegistrationScreen extends ConsumerStatefulWidget {
  const ReportRegistrationScreen({super.key});

  @override
  ConsumerState<ReportRegistrationScreen> createState() =>
      _ReportRegistrationScreenState();
}

class _ReportRegistrationScreenState
    extends ConsumerState<ReportRegistrationScreen> {
  String? _selectedAcademicId;
  String? _selectedSubjectId;
  String? _selectedLevelId;
  String? _selectedStatus = 'PAID_PARTIAL';
  String? _selectedScholarship;
  bool _isPreparingPdfPrint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      ref.read(academicYearProvider.notifier).getAcademicYears(),
      ref.read(subjectProvider.notifier).getSubjects(),
      ref.read(levelProvider.notifier).getLevels(),
    ]);
    _applyFilters();
  }

  void _applyFilters() {
    ref
        .read(reportProvider.notifier)
        .getRegistrationReport(
          academicId: _selectedAcademicId,
          subjectId: _selectedSubjectId,
          levelId: _selectedLevelId,
          status: _selectedStatus,
          scholarship: _selectedScholarship,
        );
  }

  void _clearFilters() {
    setState(() {
      _selectedAcademicId = null;
      _selectedSubjectId = null;
      _selectedLevelId = null;
      _selectedStatus = 'PAID_PARTIAL';
      _selectedScholarship = null;
    });
    _applyFilters();
  }

  Future<void> _handleExport() async {
    await ReportExportActionHelper.exportReport(
      context: context,
      reportTitle: 'ລາຍງານການລົງທະບຽນ',
      requestExport: (format) {
        return ref
            .read(reportProvider.notifier)
            .exportRegistrationReport(
              academicId: _selectedAcademicId,
              subjectId: _selectedSubjectId,
              levelId: _selectedLevelId,
              status: _selectedStatus,
              scholarship: _selectedScholarship,
              format: format,
            );
      },
      resolveErrorMessage: () =>
          ref.read(reportProvider).registrationError ?? 'ບໍ່ສາມາດ Export ໄດ້',
    );
  }

  Future<void> _handlePdfPrint(RegistrationReportData data) async {
    if (_isPreparingPdfPrint) {
      return;
    }

    setState(() => _isPreparingPdfPrint = true);

    try {
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        return;
      }

      await showRegistrationReportPrintDialog(
        context: context,
        filters: data.filters,
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
    final reportState = ref.watch(reportProvider);
    final academicYearState = ref.watch(academicYearProvider);
    final subjectState = ref.watch(subjectProvider);
    final levelState = ref.watch(levelProvider);
    final data = reportState.registrationData;
    final hasData = (data?.registrations.isNotEmpty) ?? false;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
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
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _clearFilters,
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
                          width: 200,
                          child: AppDropdown<String>(
                            label: 'ສົກຮຽນ',
                            value: _selectedAcademicId,
                            items: academicYearState.academicYears.map((ay) {
                              return DropdownMenuItem(
                                value: ay.academicId,
                                child: Text(ay.academicYear),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedAcademicId = value);
                              _applyFilters();
                            },
                            hint: 'ທັງໝົດ',
                          ),
                        ),

                        SizedBox(
                          width: 200,
                          child: AppDropdown<String>(
                            label: 'ວິຊາ',
                            value: _selectedSubjectId,
                            items: subjectState.subjects.map((s) {
                              return DropdownMenuItem(
                                value: s.subjectId,
                                child: Text(s.subjectName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedSubjectId = value);
                              _applyFilters();
                            },
                            hint: 'ທັງໝົດ',
                          ),
                        ),

                        SizedBox(
                          width: 200,
                          child: AppDropdown<String>(
                            label: 'ລະດັບ/ຊັ້ນຮຽນ',
                            value: _selectedLevelId,
                            items: levelState.levels.map((l) {
                              return DropdownMenuItem(
                                value: l.levelId,
                                child: Text(l.levelName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedLevelId = value);
                              _applyFilters();
                            },
                            hint: 'ທັງໝົດ',
                          ),
                        ),

                        SizedBox(
                          width: 200,
                          child: AppDropdown<String>(
                            label: 'ສະຖານະການຊຳລະ',
                            value: _selectedStatus,
                            items: const [
                              DropdownMenuItem(
                                value: 'PAID_PARTIAL',
                                child: Text('ຈ່າຍແລ້ວ + ຈ່າຍບາງສ່ວນ'),
                              ),
                              DropdownMenuItem(
                                value: 'PAID',
                                child: Text('ຈ່າຍແລ້ວ'),
                              ),
                              DropdownMenuItem(
                                value: 'PARTIAL',
                                child: Text('ຈ່າຍບາງສ່ວນ'),
                              ),
                              DropdownMenuItem(
                                value: 'UNPAID',
                                child: Text('ຍັງບໍ່ທັນຈ່າຍ'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedStatus = value);
                              _applyFilters();
                            },
                            hint: 'ທັງໝົດ',
                          ),
                        ),

                        SizedBox(
                          width: 200,
                          child: AppDropdown<String>(
                            label: 'ສະຖານະທຶນ',
                            value: _selectedScholarship,
                            items: const [
                              DropdownMenuItem(
                                value: 'SCHOLARSHIP',
                                child: Text('ໄດ້ຮັບທຶນ'),
                              ),
                              DropdownMenuItem(
                                value: 'NO_SCHOLARSHIP',
                                child: Text('ບໍ່ໄດ້ຮັບທຶນ'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedScholarship = value);
                              _applyFilters();
                            },
                            hint: 'ທັງໝົດ',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (data != null)
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
                      if (hasData) ...[
                        AppButton(
                          label: reportState.isRegistrationExporting
                              ? 'ກຳລັງບັນທຶກ...'
                              : 'ສົ່ງອອກເປັນ Excel',
                          icon: Icons.download_rounded,
                          variant: AppButtonVariant.success,
                          onPressed:
                              reportState.isRegistrationExporting ||
                                  _isPreparingPdfPrint
                              ? null
                              : _handleExport,
                        ),
                        const SizedBox(width: 12),
                        AppButton(
                          label: _isPreparingPdfPrint
                              ? 'ກຳລັງ ພິມ...'
                              : 'ພິມ PDF',
                          icon: Icons.print,
                          variant: AppButtonVariant.primary,
                          onPressed:
                              reportState.isRegistrationExporting ||
                                  _isPreparingPdfPrint
                              ? null
                              : () => _handlePdfPrint(data),
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
                      _StatBadge(
                        label: 'ທັງໝົດ',
                        value: data.summary.total,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      _StatBadge(
                        label: 'ຈ່າຍແລ້ວ',
                        value: data.summary.paid,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _StatBadge(
                        label: 'ຍັງບໍ່ຈ່າຍ',
                        value: data.summary.unpaid,
                        color: AppColors.destructive,
                      ),
                      const SizedBox(width: 8),
                      _StatBadge(
                        label: 'ຈ່າຍບາງສ່ວນ',
                        value: data.summary.partial,
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(child: _buildDataTable(reportState)),
            ],
          ),
        ),
        if (_isPreparingPdfPrint)
          const PrintPreparationOverlay(
            icon: Icons.print_rounded,
            title: 'ກຳລັງໂຫຼດ...',
            message:
                'ລະບົບກຳລັງສ້າງ PDF ລາຍງານການລົງທະບຽນ ແລະ ເປີດໜ້າຈໍ preview ສຳລັບການພິມ',
            hintText: 'ຈະເປີດ preview ອັດຕະໂນມັດ',
          ),
      ],
    );
  }

  Widget _buildDataTable(ReportState state) {
    if (state.isRegistrationLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.registrationError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
            const SizedBox(height: 16),
            Text(
              'ເກີດຂໍ້ຜິດພາດ: ${state.registrationError}',
              style: TextStyle(color: AppColors.destructive),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'ລອງໃໝ່',
              icon: Icons.refresh,
              onPressed: _applyFilters,
            ),
          ],
        ),
      );
    }

    final registrations = state.registrationData?.registrations ?? const [];

    final columns = [
      DataColumnDef<RegistrationReportItem>(
        key: 'registrationId',
        label: 'ລະຫັດການລົງທະບຽນ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      DataColumnDef<RegistrationReportItem>(
        key: 'studentId',
        label: 'ລະຫັດນັກຮຽນ',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 13)),
      ),
      DataColumnDef<RegistrationReportItem>(
        key: 'fullName',
        label: 'ຊື່-ນາມສະກຸນ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      DataColumnDef<RegistrationReportItem>(
        key: 'gender',
        label: 'ເພດ',
        flex: 1,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: TextStyle(
            fontSize: 14,
            color: v?.toString() == 'ຊາຍ' ? Colors.blue : Colors.pink,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      DataColumnDef<RegistrationReportItem>(
        key: 'school',
        label: 'ໂຮງຮຽນ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DataColumnDef<RegistrationReportItem>(
        key: 'districtName',
        label: 'ເມືອງ',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 14)),
      ),
      DataColumnDef<RegistrationReportItem>(
        key: 'provinceName',
        label: 'ແຂວງ',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 14)),
      ),
      DataColumnDef<RegistrationReportItem>(
        key: 'scholarshipLabel',
        label: 'ສະຖານະທຶນ',
        flex: 1,
        render: (v, row) =>
            _ScholarshipBadge(scholarship: row.scholarship, label: v?.toString()),
      ),
      DataColumnDef<RegistrationReportItem>(
        key: 'statusLabel',
        label: 'ສະຖານະ',
        flex: 1,
        render: (v, row) => _StatusBadge(status: row.status, label: v?.toString()),
      ),
    ];

    return AppDataTable<RegistrationReportItem>(
      title: '',
      data: registrations,
      columns: columns,
      isLoading: state.isRegistrationLoading,
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ScholarshipBadge extends StatelessWidget {
  const _ScholarshipBadge({required this.scholarship, required this.label});

  final String? scholarship;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (scholarship) {
      'SCHOLARSHIP' => (AppColors.infoLight, AppColors.primaryDark),
      _ => (AppColors.muted, AppColors.mutedForeground),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label ?? '-',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.label});

  final String? status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      'PAID' => (AppColors.successLight, AppColors.success),
      'PARTIAL' => (AppColors.warningLight, AppColors.warning),
      _ => (AppColors.destructiveLight, AppColors.destructive),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label ?? '-',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
