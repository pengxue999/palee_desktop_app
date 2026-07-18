import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/tuition_payment_receipt_printer.dart';
import '../../../models/registration_model.dart';
import '../../../models/tuition_payment_model.dart';
import '../../../providers/tuition_payment_provider.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/app_button.dart';

class TuitionPaymentDialog extends ConsumerStatefulWidget {
  final RegistrationModel registration;
  final VoidCallback? onPaymentComplete;
  final Future<void> Function(String paymentId)? onPrintPayment;

  const TuitionPaymentDialog({
    super.key,
    required this.registration,
    this.onPaymentComplete,
    this.onPrintPayment,
  });

  @override
  ConsumerState<TuitionPaymentDialog> createState() =>
      _TuitionPaymentDialogState();

  static Future<void> show({
    required BuildContext context,
    required RegistrationModel registration,
    VoidCallback? onPaymentComplete,
    Future<void> Function(String paymentId)? onPrintPayment,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TuitionPaymentDialog(
        registration: registration,
        onPaymentComplete: onPaymentComplete,
        onPrintPayment: onPrintPayment,
      ),
    );
  }
}

class _TuitionPaymentDialogState extends ConsumerState<TuitionPaymentDialog> {
  late TextEditingController _amountController;
  String _paymentMethod = 'ເງິນສົດ';
  bool _isSaving = false;
  String? _error;
  bool _userChangedAmount = false;
  bool _isSettingAmount = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _amountController.addListener(_onAmountChanged);
    Future.microtask(() => _loadPayments());
  }

  void _onAmountChanged() {
    if (!_isSettingAmount && _amountController.text.isNotEmpty) {
      _userChangedAmount = true;
    }
  }

  @override
  void didUpdateWidget(covariant TuitionPaymentDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.registration.registrationId !=
        oldWidget.registration.registrationId) {
      _amountController.removeListener(_onAmountChanged);
      _amountController.dispose();
      _amountController = TextEditingController();
      _amountController.addListener(_onAmountChanged);
      _userChangedAmount = false;
      _isSettingAmount = false;
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    try {
      await ref
          .read(tuitionPaymentProvider.notifier)
          .getPaymentsByRegistration(widget.registration.registrationId)
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> _submitPayment() async {
    final amountStr = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    final payments = ref.read(tuitionPaymentProvider).registrationPayments;
    final paidAmount = payments.fold(0.0, (sum, p) => sum + p.paidAmount);
    final remaining = (widget.registration.finalAmount - paidAmount).clamp(
      0.0,
      double.infinity,
    );

    if (amount == null || amount <= 0) {
      setState(() => _error = 'ກະລຸນາໃສ່ຈຳນວນເງິນທີ່ຖືກຕ້ອງ');
      return;
    }
    if (amount > remaining) {
      setState(
        () => _error =
            'ຈຳນວນເງິນເກີນຍອດທີ່ຍັງຄ້າງ (${FormatUtils.formatKip(remaining.toInt())})',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final dialogNavigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    final request = TuitionPaymentRequest(
      registrationId: widget.registration.registrationId,
      paidAmount: amount,
      paymentMethod: _paymentMethod,
    );

    final createdPayment = await ref
        .read(tuitionPaymentProvider.notifier)
        .createPayment(request);

    if (mounted) {
      setState(() => _isSaving = false);
      if (createdPayment != null) {
        if (!mounted || !rootNavigator.context.mounted) return;

        dialogNavigator.pop();
        widget.onPaymentComplete?.call();
        if (widget.onPrintPayment != null) {
          await widget.onPrintPayment!(createdPayment.tuitionPaymentId);
        } else {
          await showTuitionPaymentPrintDialog(
            context: rootNavigator.context,
            paymentId: createdPayment.tuitionPaymentId,
          );
        }
      } else {
        final err = ref.read(tuitionPaymentProvider).error;
        setState(() => _error = err ?? 'ເກີດຂໍ້ຜິດພາດ');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(
      tuitionPaymentProvider.select((s) => s.registrationPayments),
    );
    final isLoading = ref.watch(
      tuitionPaymentProvider.select((s) => s.isLoadingRegistrationPayments),
    );
    final error = ref.watch(tuitionPaymentProvider.select((s) => s.error));
    final paidAmount = payments.fold(0.0, (sum, p) => sum + p.paidAmount);
    final remaining = (widget.registration.finalAmount - paidAmount).clamp(
      0.0,
      double.infinity,
    );
    final isFullyPaid = remaining <= 0;

    if (!isLoading && error == null) {
      if (!_userChangedAmount || _amountController.text.isEmpty) {
        _isSettingAmount = true;
        final formattedAmount = FormatUtils.formatNumber(remaining.toInt());
        _amountController.text = formattedAmount;
        _isSettingAmount = false;
      }
    }

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
                  'ຈ່າຍຄ່າຮຽນ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

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
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ເລກບິນ: ${widget.registration.registrationId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.foreground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.registration.studentFullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        if (widget.registration.districtName != null ||
                            widget.registration.provinceName != null) ...[
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
                                    widget.registration.districtName,
                                    widget.registration.provinceName,
                                  ].where((e) => e != null && e.isNotEmpty).join(', '),
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

            if (!isLoading && error == null) ...[
              _buildSummaryRow(
                'ຈຳນວນເງິນທີ່ຕ້ອງຈ່າຍ',
                FormatUtils.formatKip(widget.registration.finalAmount.toInt()),
              ),
              _buildSummaryRow(
                'ຈ່າຍແລ້ວ',
                FormatUtils.formatKip(paidAmount.toInt()),
              ),
              const Divider(height: 24),
              _buildSummaryRow(
                'ຍັງເຫຼືອ',
                FormatUtils.formatKip(remaining.toInt()),
                isBold: true,
                color: isFullyPaid ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(height: 20),
            ] else if (error != null) ...[
              _buildErrorBanner('ບໍ່ສາມາດໂຫຼດຂໍ້ມູນການຈ່າຍເງິນ: $error'),
              const SizedBox(height: 16),
              _buildSummaryRow(
                'ຄ່າຮຽນທັງໝົດ',
                FormatUtils.formatKip(widget.registration.finalAmount.toInt()),
              ),
              const Divider(height: 24),
              _buildSummaryRow(
                'ຍັງເຫຼືອ',
                FormatUtils.formatKip(widget.registration.finalAmount.toInt()),
                isBold: true,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
            ],

            if (!isFullyPaid && !isLoading && error == null) ...[
              AppTextField(
                controller: _amountController,
                label: 'ຈຳນວນເງິນທີ່ຈ່າຍ',
                hint: 'ກະລຸນາໃສ່ຈຳນວນເງິນ',
                suffixIcon: IconButton(
                  onPressed: () {
                    _amountController.text = '';
                  },
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.mutedForeground,
                  ),
                ),
                required: true,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                keyboardType: TextInputType.number,
                thousandsSeparator: true,
                maxValue: remaining > 0 ? remaining : null,
                digitOnly: DigitOnly.integer,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildMethodButton('ເງິນສົດ', Icons.money)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMethodButton('ເງິນໂອນ', Icons.account_balance),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_error != null) ...[
                _buildErrorBanner(_error!),
                const SizedBox(height: 16),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    onPressed: _isSaving ? null : _submitPayment,
                    label: _isSaving ? 'ກຳລັງບັນທຶກ...' : 'ຢືນຢັນການຈ່າຍ',
                    variant: AppButtonVariant.success,
                    isLoading: _isSaving,
                  ),
                ],
              ),
            ] else if (!isFullyPaid && error != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'ບໍ່ສາມາດໂຫຼດປະຫວັດການຈ່າຍເງິນ',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      onPressed: _loadPayments,
                      label: 'ລອງໃໝ່',
                      variant: AppButtonVariant.outline,
                    ),
                  ],
                ),
              ),
            ] else if (isFullyPaid) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
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
            ] else ...[
              const Center(child: CircularProgressIndicator()),
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
            value,
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

  Widget _buildMethodButton(String method, IconData icon) {
    final isSelected = _paymentMethod == method;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.mutedForeground,
            ),
            const SizedBox(height: 4),
            Text(
              method,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.mutedForeground,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
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
