import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/salary_payment_receipt_printer.dart';
import '../../../models/salary_payment_model.dart';
import '../../../providers/salary_payment_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/app_button.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final String teacherId;
  final TeachingMonth month;
  final VoidCallback? onPaymentComplete;
  final Future<void> Function(String paymentId)? onPrintPayment;

  const PaymentDialog({
    super.key,
    required this.teacherId,
    required this.month,
    this.onPaymentComplete,
    this.onPrintPayment,
  });

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();

  static Future<void> show({
    required BuildContext context,
    required String teacherId,
    required TeachingMonth month,
    VoidCallback? onPaymentComplete,
    Future<void> Function(String paymentId)? onPrintPayment,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        teacherId: teacherId,
        month: month,
        onPaymentComplete: onPaymentComplete,
        onPrintPayment: onPrintPayment,
      ),
    );
  }
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  final _amountController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _syncAmountFromCalc();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _syncAmountFromCalc() {
    final calc = ref.read(salaryPaymentProvider).calculation;
    if (calc != null) {
      final amount = calc.remainingBalance;
      _amountController.text = amount > 0
          ? FormatUtils.formatNumber(amount.toInt())
          : '';
    }
  }

  Future<void> _submitPayment() async {
    final calc = ref.read(salaryPaymentProvider).calculation;
    if (calc == null) return;

    final amountStr = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountStr);

    if (amount == null || amount <= 0) {
      setState(() => _error = 'ກະລຸນາໃສ່ຈຳນວນເງິນທີ່ຖືກຕ້ອງ');
      return;
    }

    final teacherId = widget.teacherId;
    final month = widget.month;

    if (amount > calc.remainingBalance) {
      setState(() => _error = 'ຈຳນວນເງິນຫຼາຍກວ່າຍອດຄ້າງຈ່າຍ');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final authState = ref.read(authProvider);
    final userId = authState.userId ?? 1;

    final now = DateTime.now();

    final netAfter =
        calc.totalAmount + calc.priorDebt - calc.totalPaid - amount;
    final status = netAfter <= 0 ? 'ຈ່າຍແລ້ວ' : 'ຈ່າຍບາງສ່ວນ';

    final request = SalaryPaymentRequest(
      teacherId: teacherId,
      userId: userId,
      month: month.month,
      totalAmount: amount,
      paymentDate: now.toIso8601String(),
      status: status,
    );

    final paymentId = await ref
        .read(salaryPaymentProvider.notifier)
        .createPayment(request);

    if (mounted) {
      setState(() => _isSaving = false);
      if (paymentId != null) {
        final dialogNavigator = Navigator.of(context);
        final rootNavigator = Navigator.of(context, rootNavigator: true);

        if (!mounted || !rootNavigator.context.mounted) {
          return;
        }

        dialogNavigator.pop();
        widget.onPaymentComplete?.call();
        if (widget.onPrintPayment != null) {
          await widget.onPrintPayment!(paymentId);
        } else {
          await showSalaryPaymentPrintDialog(
            context: rootNavigator.context,
            paymentId: paymentId,
          );
        }
      } else {
        final err = ref.read(salaryPaymentProvider).error;
        setState(() => _error = err ?? 'ເກີດຂໍ້ຜິດພາດ');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final calc = ref.watch(salaryPaymentProvider.select((s) => s.calculation));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ເບີກຈ່າຍເງິນສອນ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (calc != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ລະຫັດ: ${calc.teacherId}',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.foreground,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${calc.teacherName} ${calc.teacherLastname}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          if (calc.districtName != null ||
                              calc.provinceName != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: AppColors.mutedForeground,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    [
                                      calc.districtName,
                                      calc.provinceName,
                                    ]
                                        .where(
                                          (e) => e != null && e.isNotEmpty,
                                        )
                                        .join(', '),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildSummaryRow(
                'ເງິນສອນທັງໝົດ',
                FormatUtils.formatKip(calc.totalAmount.toInt()),
              ),
              _buildSummaryRow(
                'ຈ່າຍໄປແລ້ວ',
                FormatUtils.formatKip(calc.totalPaid.toInt()),
              ),
              if (calc.priorDebt != 0)
                _buildSummaryRow(
                  calc.priorDebt > 0 ? 'ຍອດຄ້າງຈ່າຍຈາກເດືອນກ່ອນ' : 'ຍອດຄ້າງຮັບ',
                  FormatUtils.formatKip(calc.priorDebt.abs().toInt()),
                  isNegative: calc.priorDebt < 0,
                ),
              const Divider(height: 24),
              _buildSummaryRow(
                'ຍອດຄ້າງຈ່າຍ',
                FormatUtils.formatKip(calc.remainingBalance.toInt()),
                isBold: true,
                color: calc.remainingBalance > 0
                    ? AppColors.primary
                    : AppColors.success,
              ),
              const SizedBox(height: 20),
            ],

            if (calc != null && calc.remainingBalance > 0) ...[
              _AmountField(
                controller: _amountController,
                maxAmount: calc.remainingBalance,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _buildErrorBanner(_error!),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    onPressed: _isSaving ? null : _submitPayment,
                    label: _isSaving ? 'ກຳລັງບັນທຶກ...' : 'ຢືນຢັນການຈ່າຍເງິນ',
                    variant: AppButtonVariant.success,
                    isLoading: _isSaving,
                  ),
                ],
              ),
            ] else if (calc != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 12),
                    const Text(
                      'ຈ່າຍຄົບແລ້ວ',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    bool isNegative = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: AppColors.mutedForeground),
          ),
          Text(
            isNegative ? '-$value' : value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.destructiveLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.destructive.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.destructive.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppColors.destructive,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: AppColors.destructive,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final double maxAmount;

  const _AmountField({required this.controller, required this.maxAmount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: controller,
          label: 'ຈຳນວນເງິນທີ',
          hint: 'ກະລຸນາໃສ່ຈຳນວນເງິນ',
          required: true,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          keyboardType: TextInputType.number,
          thousandsSeparator: true,
          maxValue: maxAmount > 0 ? maxAmount : null,
          digitOnly: DigitOnly.integer,
        ),
      ],
    );
  }
}
