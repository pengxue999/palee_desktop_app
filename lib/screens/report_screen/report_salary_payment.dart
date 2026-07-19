import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';
import 'package:palee_elite_training_center/core/utils/format_utils.dart';
import 'package:palee_elite_training_center/core/utils/report_export_action_helper.dart';
import 'package:palee_elite_training_center/core/utils/salary_payment_report_printer.dart';
import 'package:palee_elite_training_center/core/utils/salary_payment_receipt_printer.dart';
import 'package:palee_elite_training_center/models/salary_payment_model.dart';
import 'package:palee_elite_training_center/providers/salary_payment_provider.dart';
import 'package:palee_elite_training_center/providers/teacher_provider.dart';
import 'package:palee_elite_training_center/services/report_service.dart';
import 'package:palee_elite_training_center/widgets/app_button.dart';
import 'package:palee_elite_training_center/widgets/app_data_table.dart';
import 'package:palee_elite_training_center/widgets/app_dropdown.dart';
import 'package:palee_elite_training_center/widgets/app_searchable_dropdown.dart';
import 'package:palee_elite_training_center/widgets/empty_widget.dart';
import 'package:palee_elite_training_center/widgets/print_preparation_overlay.dart';
import 'package:palee_elite_training_center/widgets/summary_card.dart';

class ReportSalaryPaymentScreen extends ConsumerStatefulWidget {
  const ReportSalaryPaymentScreen({super.key});

  @override
  ConsumerState<ReportSalaryPaymentScreen> createState() =>
      _ReportSalaryPaymentScreenState();
}

class _ReportSalaryPaymentScreenState
    extends ConsumerState<ReportSalaryPaymentScreen> {
  final ReportService _reportService = ReportService();

  int? _selectedMonth;
  String? _selectedTeacherId;
  String? _selectedStatus;
  bool _isPreparingReceiptPrint = false;
  bool _isPreparingReportPrint = false;
  bool _isExporting = false;

  static const List<String> _statusOptions = ['ຈ່າຍແລ້ວ', 'ຄ້າງຈ່າຍ'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        ref.read(teacherProvider.notifier).getTeachers(),
        ref.read(salaryPaymentProvider.notifier).loadPayments(),
      ]);
    });
  }

  Future<void> _refresh() async {
    await ref.read(salaryPaymentProvider.notifier).loadPayments();
  }

  void _clearFilters() {
    setState(() {
      _selectedMonth = null;
      _selectedTeacherId = null;
      _selectedStatus = null;
    });
    _refresh();
  }

  Future<void> _printPayment(String paymentId) async {
    if (_isPreparingReceiptPrint) {
      return;
    }

    setState(() => _isPreparingReceiptPrint = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }

      await showSalaryPaymentPrintDialog(
        context: context,
        paymentId: paymentId,
        onPreviewReady: () {
          if (mounted && _isPreparingReceiptPrint) {
            setState(() => _isPreparingReceiptPrint = false);
          }
        },
      );
    } finally {
      if (mounted && _isPreparingReceiptPrint) {
        setState(() => _isPreparingReceiptPrint = false);
      }
    }
  }

  Future<void> _handleExport() async {
    if (_isExporting) {
      return;
    }

    setState(() => _isExporting = true);
    try {
      await ReportExportActionHelper.exportReport(
        context: context,
        reportTitle: 'ລາຍງານເບີກຈ່າຍເງິນສອນ',
        requestExport: (format) {
          return _reportService
              .exportSalaryPaymentReport(
                month: _selectedMonth,
                teacherId: _selectedTeacherId,
                status: _selectedStatus,
                format: format,
              )
              .then((response) => response.data);
        },
        resolveErrorMessage: () => 'ບໍ່ສາມາດ Export ລາຍງານໄດ້',
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _handlePdfPrint() async {
    if (_isPreparingReportPrint) {
      return;
    }

    setState(() => _isPreparingReportPrint = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }

      await showSalaryPaymentReportPrintDialog(
        context: context,
        month: _selectedMonth,
        teacherId: _selectedTeacherId,
        status: _selectedStatus,
        onPreviewReady: () {
          if (mounted && _isPreparingReportPrint) {
            setState(() => _isPreparingReportPrint = false);
          }
        },
      );
    } finally {
      if (mounted && _isPreparingReportPrint) {
        setState(() => _isPreparingReportPrint = false);
      }
    }
  }

  List<SalaryPaymentModel> _filterPayments(List<SalaryPaymentModel> payments) {
    return payments.where((payment) {
      if (_selectedMonth != null && payment.month != _selectedMonth) {
        return false;
      }
      if (_selectedTeacherId != null &&
          payment.teacherId != _selectedTeacherId) {
        return false;
      }
      if (_selectedStatus != null && payment.status != _selectedStatus) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) {
      final yearCompare = b.year.compareTo(a.year);
      if (yearCompare != 0) {
        return yearCompare;
      }

      final monthCompare = b.month.compareTo(a.month);
      if (monthCompare != 0) {
        return monthCompare;
      }

      return b.paymentDate.compareTo(a.paymentDate);
    });
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    return DateFormat('dd-MM-yyyy').format(parsed);
  }

  Widget _buildCompactMonthPicker() {
    return SizedBox(
      width: 180,
      child: AppDropdown<int>(
        value: _selectedMonth,
        hint: 'ເລືອກເດືອນ',
        items: List.generate(
          12,
          (index) => DropdownMenuItem(
            value: index + 1,
            child: Text(FormatUtils.getMonthNameLao(index + 1)),
          ),
        ),
        onChanged: (value) {
          setState(() => _selectedMonth = value);
        },
      ),
    );
  }

  Widget _buildFilterSection({
    required bool hasData,
    required bool isLoading,
    required List<AppSearchableItem<String?>> teacherItems,
  }) {
    final isActionBusy = _isExporting || _isPreparingReportPrint || isLoading;

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
                onPressed: isLoading ? null : _clearFilters,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCompactMonthPicker(),
              const SizedBox(width: 12),
              SizedBox(
                width: 240,
                child: AppSearchableDropdown<String?>(
                  value: teacherItems.any((t) => t.value == _selectedTeacherId)
                      ? _selectedTeacherId
                      : null,
                  hint: 'ທັງໝົດອາຈານ',
                  searchHint: 'ຄົ້ນຫາຊື່ອາຈານ...',
                  emptyText: 'ບໍ່ພົບອາຈານ',
                  items: teacherItems,
                  onChanged: (value) {
                    setState(() => _selectedTeacherId = value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 180,
                child: AppDropdown<String>(
                  value: _selectedStatus,
                  hint: 'ທັງໝົດ',
                  items: _statusOptions
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                  },
                ),
              ),
              const Spacer(),
              if (hasData) ...[
                AppButton(
                  label: 'ສົ່ງອອກເປັນ Excel',
                  icon: Icons.download_rounded,
                  variant: AppButtonVariant.success,
                  size: AppButtonSize.medium,
                  isLoading: _isExporting,
                  onPressed: isActionBusy ? null : _handleExport,
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: _isPreparingReportPrint ? 'ກຳລັງ ພິມ...' : 'ພິມ PDF',
                  icon: Icons.print,
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.medium,
                  isLoading: _isPreparingReportPrint,
                  onPressed: isActionBusy ? null : _handlePdfPrint,
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

  Widget _buildDataTable({
    required List<SalaryPaymentModel> payments,
    required List<DataColumnDef<SalaryPaymentModel>> columns,
    required String? error,
    required bool isLoading,
  }) {
    if (error != null) {
      return Center(
        child: Text(error, style: const TextStyle(color: Colors.red)),
      );
    }

    if (payments.isEmpty && !isLoading) {
      return const EmptyWidget(
        title: 'ບໍ່ພົບຂໍ້ມູນລາຍງານ',
        subtitle: 'ລອງປ່ຽນເງື່ອນໄຂຕົວກອງ ຫຼື refresh ຂໍ້ມູນອີກຄັ້ງ',
      );
    }

    return AppDataTable<SalaryPaymentModel>(
      title: 'ລາຍການເບີກຈ່າຍເງິນສອນ',
      data: payments,
      columns: columns,
      showActions: true,
      isLoading: isLoading,
      onPrint: (payment) => _printPayment(payment.salaryPaymentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salaryState = ref.watch(salaryPaymentProvider);
    final teacherState = ref.watch(teacherProvider);
    final payments = _filterPayments(salaryState.payments);
    final totalAmount = payments.fold<double>(
      0,
      (sum, item) => sum + item.totalAmount,
    );
    final paidCount = payments
        .where((item) => item.status == 'ຈ່າຍແລ້ວ')
        .length;
    final pendingCount = payments
        .where((item) => item.status != 'ຈ່າຍແລ້ວ')
        .length;
    final hasData = payments.isNotEmpty;
    final teacherItems = <AppSearchableItem<String?>>[
      AppSearchableItem<String?>(value: null, label: 'ທັງໝົດອາຈານ'),
      ...teacherState.teachers.map(
        (teacher) => AppSearchableItem<String?>(
          value: teacher.teacherId,
          label: '${teacher.teacherName} ${teacher.teacherLastname}',
        ),
      ),
    ];

    final columns = [
      DataColumnDef<SalaryPaymentModel>(
        key: 'salaryPaymentId',
        label: 'ລະຫັດ',
        flex: 2,
        render: (value, row) => Text(row.salaryPaymentId),
      ),
      DataColumnDef<SalaryPaymentModel>(
        key: 'teacherFullName',
        label: 'ອາຈານ',
        flex: 3,
        render: (value, row) => Text(row.teacherFullName),
      ),
      DataColumnDef<SalaryPaymentModel>(
        key: 'month',
        label: 'ເດືອນ',
        flex: 2,
        render: (value, row) => Text(FormatUtils.getMonthNameLao(row.month)),
      ),

      DataColumnDef<SalaryPaymentModel>(
        key: 'totalAmount',
        label: 'ຈຳນວນເງິນ',
        flex: 2,
        render: (value, row) =>
            Text(FormatUtils.formatKip(row.totalAmount.toInt())),
      ),
      DataColumnDef<SalaryPaymentModel>(
        key: 'paymentDate',
        label: 'ວັນທີຈ່າຍ',
        flex: 2,
        render: (value, row) => Text(_formatDate(row.paymentDate)),
      ),
      DataColumnDef<SalaryPaymentModel>(
        key: 'status',
        label: 'ສະຖານະ',
        flex: 2,
        render: (value, row) => _StatusChip(status: row.status),
      ),
      DataColumnDef<SalaryPaymentModel>(
        key: 'userName',
        label: 'ຜູ້ອະນຸມັດ',
        flex: 2,
        render: (value, row) => Text(row.userName),
      ),
    ];

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SummaryCard(
                  label: 'ລາຍການທັງໝົດ',
                  amount: payments.length.toDouble(),
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  bgColor: AppColors.primary.withValues(alpha: 0.12),
                  formatKip: (v) => '${v.toInt()} ລາຍການ',
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  label: 'ຈ່າຍແລ້ວ',
                  amount: paidCount.toDouble(),
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  bgColor: AppColors.success.withValues(alpha: 0.12),
                  formatKip: (v) => '${v.toInt()} ລາຍການ',
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  label: 'ຄ້າງຈ່າຍ',
                  amount: pendingCount.toDouble(),
                  icon: Icons.pending_actions_rounded,
                  color: AppColors.warning,
                  bgColor: AppColors.warning.withValues(alpha: 0.12),
                  formatKip: (v) => '${v.toInt()} ລາຍການ',
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  label: 'ມູນຄ່າລວມ',
                  amount: totalAmount,
                  icon: Icons.attach_money_rounded,
                  color: AppColors.info,
                  bgColor: AppColors.info.withValues(alpha: 0.12),
                  formatKip: (v) => FormatUtils.formatKip(v.toInt()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFilterSection(
              hasData: hasData,
              isLoading: salaryState.isLoading,
              teacherItems: teacherItems,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildDataTable(
                payments: payments,
                columns: columns,
                error: salaryState.error,
                isLoading: salaryState.isLoading,
              ),
            ),
          ],
        ),
        if (_isPreparingReceiptPrint)
          const PrintPreparationOverlay(
            icon: Icons.print_rounded,
            title: 'ກຳລັງກະກຽມໃບຮັບເງິນ',
            message:
                'ລະບົບກຳລັງສ້າງ PDF ເພື່ອ preview ແລະ ພິມໃບຮັບເງິນການຈ່າຍເງິນສອນ',
            titleFontSize: 18,
            messageFontSize: 13,
            messageHeight: 1.6,
          ),
        if (_isPreparingReportPrint)
          const PrintPreparationOverlay(
            icon: Icons.picture_as_pdf_rounded,
            title: 'ກຳລັງກະກຽມ PDF ລາຍງານ',
            message:
                'ລະບົບກຳລັງສ້າງ PDF ຂອງລາຍງານເບີກຈ່າຍເງິນສອນ ເພື່ອ preview ແລະ ພິມ',
            titleFontSize: 18,
            messageFontSize: 13,
            messageHeight: 1.6,
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'ຈ່າຍແລ້ວ';
    final color = isPaid ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
