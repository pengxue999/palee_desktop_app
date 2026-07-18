import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../models/salary_payment_model.dart';
import '../../../providers/salary_payment_provider.dart';
import '../../../widgets/app_data_table.dart';

class SalaryPaymentDetail extends ConsumerStatefulWidget {
  final String? teacherId;
  final Future<void> Function(SalaryPaymentModel payment)? onPrint;

  const SalaryPaymentDetail({super.key, this.teacherId, this.onPrint});

  @override
  ConsumerState<SalaryPaymentDetail> createState() =>
      _SalaryPaymentDetailState();

  static Widget withPreservedState({required String teacherId}) {
    return SalaryPaymentDetail(
      key: ValueKey('salary_payment_detail_$teacherId'),
      teacherId: teacherId,
    );
  }
}

class _SalaryPaymentDetailState extends ConsumerState<SalaryPaymentDetail>
    with AutomaticKeepAliveClientMixin {
  String? _queuedTeacherId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.teacherId != null) {
      _scheduleLoadTeacherData();
    }
  }

  @override
  void didUpdateWidget(SalaryPaymentDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teacherId != widget.teacherId && widget.teacherId != null) {
      _scheduleLoadTeacherData();
    }
  }

  void _scheduleLoadTeacherData() {
    final teacherId = widget.teacherId;
    if (teacherId == null) return;
    _queuedTeacherId = teacherId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _queuedTeacherId != teacherId) {
        return;
      }
      _queuedTeacherId = null;
      _loadTeacherData();
    });
  }

  void _loadTeacherData() {
    final teacherId = widget.teacherId;
    if (teacherId == null) return;

    ref.read(salaryPaymentProvider.notifier).loadTeacherPayments(teacherId);

    final month = ref.read(salaryPaymentProvider).selectedMonth;
    if (month != null) {
      ref
          .read(salaryPaymentProvider.notifier)
          .calculateTeacherSalary(teacherId, month.month, month.year);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return _PaymentHistorySection(onPrint: widget.onPrint);
  }
}

class _PaymentHistorySection extends ConsumerWidget {
  final Future<void> Function(SalaryPaymentModel payment)? onPrint;

  const _PaymentHistorySection({this.onPrint});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPayments = ref.watch(
      salaryPaymentProvider.select((s) => s.payments),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            const Text(
              'ປະຫວັດການເບີກຈ່າຍເງິນ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const Spacer(),
            if (allPayments.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${allPayments.length} ລາຍການ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: AppDataTable<SalaryPaymentModel>(
            data: allPayments,
            columns: [
              DataColumnDef<SalaryPaymentModel>(
                key: 'salaryPaymentId',
                label: 'ລະຫັດ',
                flex: 2,
                render: (value, row) => Text(
                  value?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              DataColumnDef<SalaryPaymentModel>(
                key: 'teacherFullName',
                label: 'ອາຈານ',
                flex: 3,
                render: (value, row) => Text(
                  value?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataColumnDef<SalaryPaymentModel>(
                key: 'totalAmount',
                label: 'ຈຳນວນເງິນ',
                flex: 2,
                render: (value, row) => Text(
                  FormatUtils.formatKip(
                    double.tryParse(value?.toString() ?? '0')?.toInt() ?? 0,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              DataColumnDef<SalaryPaymentModel>(
                key: 'month',
                label: 'ເດືອນ',
                flex: 2,
                render: (value, row) => Text(
                  value?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              DataColumnDef<SalaryPaymentModel>(
                key: 'paymentDate',
                label: 'ວັນທີ່',
                flex: 2,
                render: (value, row) => Text(
                  value?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.foreground,
                  ),
                ),
              ),
            ],
            onPrint: onPrint,
            onDelete: (row) => _showDeleteConfirmation(context, ref, row),
            showActions: true,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    SalaryPaymentModel row,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ຢືນຢັນການລຶບ'),
        content: Text('ຕ້ອງການລຶບການຈ່າຍເງິນ ${row.salaryPaymentId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ຍົກເລີກ'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await ref
                  .read(salaryPaymentProvider.notifier)
                  .deletePayment(row.salaryPaymentId);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ລຶບການຈ່າຍເງິນສຳເລັດ'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text(
              'ລຶບ',
              style: TextStyle(color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );
  }
}
