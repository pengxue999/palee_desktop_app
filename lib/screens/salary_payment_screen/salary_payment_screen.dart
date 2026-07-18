import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/salary_payment_receipt_printer.dart';
import '../../models/salary_payment_model.dart';
import '../../providers/salary_payment_provider.dart';
import '../../widgets/print_preparation_overlay.dart';
import 'widgets/salary_teacher_list.dart';
import 'widgets/salary_payment_detail.dart';

class SalaryPaymentScreen extends ConsumerStatefulWidget {
  const SalaryPaymentScreen({super.key});

  @override
  ConsumerState<SalaryPaymentScreen> createState() =>
      _SalaryPaymentScreenState();
}

class _SalaryPaymentScreenState extends ConsumerState<SalaryPaymentScreen> {
  final PageStorageBucket _bucket = PageStorageBucket();
  bool _isPreparingPaymentPrint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salaryPaymentProvider.notifier).loadTeachingMonths();
      ref.read(salaryPaymentProvider.notifier).loadPayments();
    });
  }

  Future<void> _handlePaymentPrint(SalaryPaymentModel payment) async {
    await _handlePaymentPrintById(payment.salaryPaymentId);
  }

  Future<void> _handlePaymentPrintById(String paymentId) async {
    if (_isPreparingPaymentPrint) {
      return;
    }

    setState(() => _isPreparingPaymentPrint = true);

    try {
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        return;
      }

      await showSalaryPaymentPrintDialog(
        context: context,
        paymentId: paymentId,
        onPreviewReady: () {
          if (mounted && _isPreparingPaymentPrint) {
            setState(() => _isPreparingPaymentPrint = false);
          }
        },
      );
    } finally {
      if (mounted && _isPreparingPaymentPrint) {
        setState(() => _isPreparingPaymentPrint = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTeacherId = ref.watch(
      salaryPaymentProvider.select((s) => s.selectedTeacherId),
    );

    final isMobile = context.isMobile;

    final leftWidth = context.responsiveValue(
      mobile: double.infinity,
      tablet: 320.0,
      desktop: 500.0,
      wideDesktop: 720.0,
    );

    return Stack(
      children: [
        if (isMobile)
          Column(
            children: [
              Expanded(
                flex: 4,
                child: SalaryTeacherList(
                  onPrintPayment: _handlePaymentPrintById,
                  onSelectTeacher: (id) => ref
                      .read(salaryPaymentProvider.notifier)
                      .selectTeacher(id),
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Expanded(
                flex: 5,
                child: PageStorage(
                  bucket: _bucket,
                  child: SalaryPaymentDetailWrapper(
                    teacherId: selectedTeacherId,
                    onPrint: _handlePaymentPrint,
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: leftWidth,
                child: SalaryTeacherList(
                  onPrintPayment: _handlePaymentPrintById,
                  onSelectTeacher: (id) => ref
                      .read(salaryPaymentProvider.notifier)
                      .selectTeacher(id),
                ),
              ),
              Expanded(
                child: PageStorage(
                  bucket: _bucket,
                  child: SalaryPaymentDetailWrapper(
                    teacherId: selectedTeacherId,
                    onPrint: _handlePaymentPrint,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        if (_isPreparingPaymentPrint)
          const PrintPreparationOverlay(
            icon: Icons.print_rounded,
            title: 'ກຳລັງໂຫຼດ...',
            message: 'ລະບົບກຳລັງສ້າງ PDF ແລະ ເປີດໜ້າຈໍ preview ສຳລັບການພິມ',
            titleFontSize: 18,
            messageFontSize: 13,
            messageHeight: 1.6,
          ),
      ],
    );
  }
}

class SalaryPaymentDetailWrapper extends StatelessWidget {
  final String? teacherId;
  final Future<void> Function(SalaryPaymentModel payment)? onPrint;

  const SalaryPaymentDetailWrapper({super.key, this.teacherId, this.onPrint});

  @override
  Widget build(BuildContext context) {
    return SalaryPaymentDetail(
      key: const ValueKey('salary_payment_detail_fixed'),
      teacherId: teacherId,
      onPrint: onPrint,
    );
  }
}
