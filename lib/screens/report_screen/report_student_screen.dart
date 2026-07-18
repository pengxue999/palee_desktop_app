import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/core/utils/report_export_action_helper.dart';
import 'package:palee_elite_training_center/core/utils/student_report_printer.dart';
import 'package:palee_elite_training_center/core/utils/enum_localization.dart';
import 'package:palee_elite_training_center/models/report_models.dart';
import 'package:palee_elite_training_center/providers/academic_year_provider.dart';
import 'package:palee_elite_training_center/providers/district_provider.dart';
import 'package:palee_elite_training_center/providers/province_provider.dart';
import 'package:palee_elite_training_center/providers/report_provider.dart';
import 'package:palee_elite_training_center/widgets/app_button.dart';
import 'package:palee_elite_training_center/widgets/app_card.dart';
import 'package:palee_elite_training_center/widgets/app_data_table.dart';
import 'package:palee_elite_training_center/widgets/app_dropdown.dart';
import 'package:palee_elite_training_center/widgets/print_preparation_overlay.dart';

class ReportStudentScreen extends ConsumerStatefulWidget {
  const ReportStudentScreen({super.key});

  @override
  ConsumerState<ReportStudentScreen> createState() =>
      _ReportStudentScreenState();
}

class _ReportStudentScreenState extends ConsumerState<ReportStudentScreen> {
  String? _selectedAcademicId;
  int? _selectedProvinceId;
  int? _selectedDistrictId;
  String? _selectedScholarship;
  String? _selectedGender;
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
      ref.read(provinceProvider.notifier).getProvinces(),
    ]);
    _applyFilters();
  }

  Future<void> _loadDistricts(int provinceId) async {
    await ref
        .read(districtProvider.notifier)
        .getDistrictsByProvince(provinceId);
  }

  void _applyFilters() {
    ref
        .read(reportProvider.notifier)
        .getStudentReport(
          academicId: _selectedAcademicId,
          provinceId: _selectedProvinceId,
          districtId: _selectedDistrictId,
          scholarship: _selectedScholarship,
          gender: _selectedGender,
        );
  }

  void _clearFilters() {
    setState(() {
      _selectedAcademicId = null;
      _selectedProvinceId = null;
      _selectedDistrictId = null;
      _selectedScholarship = null;
      _selectedGender = null;
    });
    ref.read(districtProvider.notifier).clearDistricts();
    _applyFilters();
  }

  Future<void> _handleExport() async {
    await ReportExportActionHelper.exportReport(
      context: context,
      reportTitle: 'ລາຍງານນັກຮຽນ',
      requestExport: (format) {
        return ref
            .read(reportProvider.notifier)
            .exportStudentReport(
              academicId: _selectedAcademicId,
              provinceId: _selectedProvinceId,
              districtId: _selectedDistrictId,
              scholarship: _selectedScholarship,
              gender: _selectedGender,
              format: format,
            );
      },
      resolveErrorMessage: () =>
          ref.read(reportProvider).error ?? 'ບໍ່ສາມາດ Export ໄດ້',
    );
  }

  Future<void> _handlePdfPrint(ReportState reportState) async {
    final filters = reportState.filters;
    if (_isPreparingPdfPrint || filters == null) {
      return;
    }

    setState(() => _isPreparingPdfPrint = true);

    try {
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        return;
      }

      await showStudentReportPrintDialog(
        context: context,
        students: reportState.students,
        filters: filters,
        totalCount: reportState.totalCount,
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
    final provinceState = ref.watch(provinceProvider);
    final districtState = ref.watch(districtProvider);
    final hasStudentData = reportState.students.isNotEmpty;

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
                          width: 180,
                          child: AppDropdown<int>(
                            label: 'ແຂວງ',
                            value: _selectedProvinceId,
                            items: provinceState.provinces.map((p) {
                              return DropdownMenuItem(
                                value: p.provinceId,
                                child: Text(p.provinceName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedProvinceId = value;
                                _selectedDistrictId = null;
                              });
                              if (value != null) {
                                _loadDistricts(value);
                              }
                              _applyFilters();
                            },
                            hint: 'ທັງໝົດ',
                          ),
                        ),

                        SizedBox(
                          width: 180,
                          child: AppDropdown<int>(
                            label: 'ເມືອງ',
                            value: _selectedDistrictId,
                            items: districtState.filteredDistricts.map((d) {
                              return DropdownMenuItem(
                                value: d.districtId,
                                child: Text(d.districtName),
                              );
                            }).toList(),
                            onChanged:
                                _selectedProvinceId == null ||
                                    districtState.filteredDistricts.isEmpty
                                ? null
                                : (value) {
                                    setState(() => _selectedDistrictId = value);
                                    _applyFilters();
                                  },
                            hint: _selectedProvinceId == null
                                ? 'ເລືອກແຂວງກ່ອນ'
                                : 'ທັງໝົດ',
                          ),
                        ),

                        SizedBox(
                          width: 140,
                          child: AppDropdown<String>(
                            label: 'ເພດ',
                            value: _selectedGender,
                            items: const [
                              DropdownMenuItem(
                                value: 'MALE',
                                child: Text('ຊາຍ'),
                              ),
                              DropdownMenuItem(
                                value: 'FEMALE',
                                child: Text('ຍິງ'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedGender = value);
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

              if (reportState.filters != null)
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
                      if (hasStudentData) ...[
                        AppButton(
                          label: reportState.isExporting
                              ? 'ກຳລັງບັນທຶກ...'
                              : 'ສົ່ງອອກເປັນ Excel',
                          icon: Icons.download_rounded,
                          variant: AppButtonVariant.success,
                          onPressed:
                              reportState.isExporting || _isPreparingPdfPrint
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
                              reportState.isExporting || _isPreparingPdfPrint
                              ? null
                              : () => _handlePdfPrint(reportState),
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
                          '${reportState.totalCount} ຄົນ',
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
              SizedBox(height: 16),
              Expanded(child: _buildDataTable(reportState)),
            ],
          ),
        ),
        if (_isPreparingPdfPrint)
          const PrintPreparationOverlay(
            icon: Icons.print_rounded,
            title: 'ກຳລັງໂຫຼດ...',
            message:
                'ລະບົບກຳລັງສ້າງ PDF ລາຍງານນັກຮຽນ ແລະ ເປີດໜ້າຈໍ preview ສຳລັບການພິມ',
            hintText: 'ຈະເປີດ preview ອັດຕະໂນມັດ',
          ),
      ],
    );
  }

  Widget _buildDataTable(ReportState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
            const SizedBox(height: 16),
            Text(
              'ເກີດຂໍ້ຜິດພາດ: ${state.error}',
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

    final columns = [
      DataColumnDef<StudentReportItem>(
        key: 'studentId',
        label: 'ລະຫັດ',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 13)),
      ),
      DataColumnDef<StudentReportItem>(
        key: 'fullName',
        label: 'ຊື່-ນາມສະກຸນ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      DataColumnDef<StudentReportItem>(
        key: 'gender',
        label: 'ເພດ',
        flex: 1,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: TextStyle(
            fontSize: 14,
            color: localizeGender(v?.toString()) == 'ຊາຍ'
                ? Colors.blue
                : Colors.pink,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      DataColumnDef<StudentReportItem>(
        key: 'school',
        label: 'ໂຮງຮຽນ',
        flex: 2,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DataColumnDef<StudentReportItem>(
        key: 'provinceName',
        label: 'ແຂວງ',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 14)),
      ),
      DataColumnDef<StudentReportItem>(
        key: 'districtName',
        label: 'ເມືອງ',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 14)),
      ),
      DataColumnDef<StudentReportItem>(
        key: 'studentContact',
        label: 'ເບີຕິດຕໍ່',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 14)),
      ),
      DataColumnDef<StudentReportItem>(
        key: 'parentsContact',
        label: 'ເບີຕິດຕໍ່ຜູ້ປົກຄອງ',
        flex: 1,
        render: (v, row) =>
            Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 14)),
      ),
    ];

    return AppDataTable<StudentReportItem>(
      title: '',
      data: state.students,
      columns: columns,
      isLoading: state.isLoading,
    );
  }
}
