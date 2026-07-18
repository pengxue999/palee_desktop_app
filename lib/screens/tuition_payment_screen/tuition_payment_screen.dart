import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/widgets/app_text_field.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/tuition_payment_history_printer.dart';
import '../../core/utils/tuition_payment_receipt_printer.dart';
import '../../models/tuition_payment_model.dart';
import '../../providers/registration_provider.dart';
import '../../providers/tuition_payment_provider.dart';
import '../../screens/registration_screen/widgets/status_badge.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/print_preparation_overlay.dart';
import 'widgets/modern_reg_table.dart';
import 'widgets/tuition_payment_dialog.dart';

class TuitionPaymentScreen extends ConsumerStatefulWidget {
  const TuitionPaymentScreen({super.key});

  @override
  ConsumerState<TuitionPaymentScreen> createState() =>
      _TuitionPaymentScreenState();
}

class _TuitionPaymentScreenState extends ConsumerState<TuitionPaymentScreen> {
  String _searchText = '';
  final _searchController = TextEditingController();
  String? _selectedRegId;
  bool _isPreparingPaymentPrint = false;
  String? _printOverlayMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registrationProvider.notifier).getRegistrations();
      ref.read(tuitionPaymentProvider.notifier).getPayments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatKip(double value) => FormatUtils.formatKip(value.toInt());

  Future<void> _handlePaymentPrintById(String paymentId) async {
    if (_isPreparingPaymentPrint) {
      return;
    }

    setState(() {
      _isPreparingPaymentPrint = true;
      _printOverlayMessage =
          'ລະບົບກຳລັງດຶງຂໍ້ມູນການຈ່າຍຄ່າຮຽນ ແລະ ສ້າງ preview ໃຫ້ພ້ອມສຳລັບການພິມ';
    });

    try {
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        return;
      }

      await showTuitionPaymentPrintDialog(
        context: context,
        paymentId: paymentId,
        onPreviewReady: () {
          if (mounted && _isPreparingPaymentPrint) {
            setState(() {
              _isPreparingPaymentPrint = false;
              _printOverlayMessage = null;
            });
          }
        },
      );
    } finally {
      if (mounted && _isPreparingPaymentPrint) {
        setState(() {
          _isPreparingPaymentPrint = false;
          _printOverlayMessage = null;
        });
      }
    }
  }

  Future<void> _handlePaymentHistoryPrintByRegistration(
    String registrationId,
  ) async {
    if (_isPreparingPaymentPrint) {
      return;
    }

    setState(() {
      _isPreparingPaymentPrint = true;
      _printOverlayMessage = 'ລະບົບກຳລັງສ້າງສະຫຼຸບການຈ່າຍຄ່າຮຽນຂອງນັກຮຽນຄົນນີ້';
    });

    try {
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        return;
      }

      await showTuitionPaymentHistoryPrintDialog(
        context: context,
        registrationId: registrationId,
        onPreviewReady: () {
          if (mounted && _isPreparingPaymentPrint) {
            setState(() {
              _isPreparingPaymentPrint = false;
              _printOverlayMessage = null;
            });
          }
        },
      );
    } finally {
      if (mounted && _isPreparingPaymentPrint) {
        setState(() {
          _isPreparingPaymentPrint = false;
          _printOverlayMessage = null;
        });
      }
    }
  }

  Future<void> _handlePaymentPrint(TuitionPaymentModel payment) async {
    await _handlePaymentHistoryPrintByRegistration(payment.registrationId);
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationProvider);

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final shouldStackLayout = availableWidth < Breakpoints.desktop;
            final stackedTopHeight = availableWidth < Breakpoints.tablet
                ? 300.0
                : 360.0;
            final leftWidth = availableWidth >= Breakpoints.wideDesktop
                ? 720.0
                : availableWidth >= Breakpoints.desktop
                ? 550.0
                : availableWidth >= Breakpoints.tablet
                ? 360.0
                : double.infinity;

            if (shouldStackLayout) {
              return Column(
                children: [
                  SizedBox(
                    height: stackedTopHeight,
                    child: _buildStudentList(regState),
                  ),
                  Expanded(
                    child: _buildAllPaymentHistory(
                      onPrint: _handlePaymentPrint,
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                SizedBox(width: leftWidth, child: _buildStudentList(regState)),
                Expanded(
                  child: _buildAllPaymentHistory(onPrint: _handlePaymentPrint),
                ),
              ],
            );
          },
        ),
        if (_isPreparingPaymentPrint)
          PrintPreparationOverlay(
            icon: Icons.receipt_long_rounded,
            title: 'ກຳລັງໂຫຼດ...',
            message:
                _printOverlayMessage ?? 'ລະບົບກຳລັງກຽມ preview ສຳລັບການພິມ',
            hintText: 'ຈະເປີດ preview ອັດຕະໂນມັດ',
          ),
      ],
    );
  }

  Widget _buildStudentList(regState) {
    final regs = regState.registrations;
    final filtered = _searchText.isEmpty
        ? regs
        : regs.where((r) {
            final q = _searchText.toLowerCase();
            return r.registrationId.toLowerCase().contains(q) ||
                r.studentFullName.toLowerCase().contains(q);
          }).toList();
    if (_selectedRegId != null) {
      for (final registration in regs) {
        if (registration.registrationId == _selectedRegId) {
          break;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ກວດສອບການລົງທະບຽນ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
            ],
          ),
          AppTextField(
            controller: _searchController,
            label: '',
            hint: 'ຄົ້ນຫາການລົງທະບຽນ...',
            prefixIcon: const Icon(Icons.search, size: 18),
            onChanged: (value) => setState(() => _searchText = value),
            fontSize: 16,
            suffixIcon: _searchText.isNotEmpty
                ? MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchText = '');
                      },
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ModernRegTable(
              data: filtered,
              formatKip: _formatKip,
              selectedId: _selectedRegId,
              onSelectionChanged: (id) {
                setState(() {
                  _selectedRegId = id;
                });
              },
              onRowTap: (reg) async {
                await TuitionPaymentDialog.show(
                  context: context,
                  registration: reg,
                  onPaymentComplete: () {
                    ref.read(registrationProvider.notifier).getRegistrations();
                    ref.read(tuitionPaymentProvider.notifier).getPayments();
                  },
                  onPrintPayment: _handlePaymentPrintById,
                );
              },
              isLoading: regState.isLoading && regs.isEmpty,
              showRadio: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllPaymentHistory({
    required Future<void> Function(TuitionPaymentModel payment) onPrint,
  }) {
    return _AllPaymentHistorySection(formatKip: _formatKip, onPrint: onPrint);
  }
}

class _AllPaymentHistorySection extends ConsumerWidget {
  final String Function(double) formatKip;
  final Future<void> Function(TuitionPaymentModel payment) onPrint;

  const _AllPaymentHistorySection({
    required this.formatKip,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPayments = ref.watch(
      tuitionPaymentProvider.select((s) => s.payments),
    );
    final isLoading = ref.watch(
      tuitionPaymentProvider.select((s) => s.isLoading),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'ປະຫວັດການຈ່າຍຄ່າຮຽນທັງໝົດ',
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
          SizedBox(height: 12),
          Expanded(
            child: AppDataTable<TuitionPaymentModel>(
              data: allPayments,
              columns: [
                DataColumnDef<TuitionPaymentModel>(
                  key: 'tuitionPaymentId',
                  label: 'ລະຫັດ',
                  flex: 1,
                  render: (value, row) => Text(
                    value?.toString() ?? '-',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                DataColumnDef<TuitionPaymentModel>(
                  key: 'studentName',
                  label: 'ຊື່ນັກຮຽນ',
                  flex: 2,
                  render: (value, row) => Text(
                    value?.toString() ?? '-',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                DataColumnDef<TuitionPaymentModel>(
                  key: 'paidAmount',
                  label: 'ຈ່າຍແລ້ວ',
                  flex: 2,
                  render: (value, row) => Text(
                    formatKip(value as double),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
                DataColumnDef<TuitionPaymentModel>(
                  key: 'paymentMethod',
                  label: 'ຈ່າຍດ້ວຍ',
                  flex: 1,
                  render: (value, row) => StatusBadge(status: value.toString()),
                ),
                DataColumnDef<TuitionPaymentModel>(
                  key: 'payDate',
                  label: 'ວັນທີຈ່າຍ',
                  flex: 3,
                ),
              ],
              onDelete: (row) => _showDeleteConfirmation(context, ref, row),
              onPrint: onPrint,
              isLoading: isLoading,
              showActions: true,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    TuitionPaymentModel row,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ຢືນຢັນການລຶບ'),
        content: Text(
          'ທ່ານຕ້ອງການລຶບການຈ່າຍເງິນ ${row.tuitionPaymentId} ຫຼືບໍ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ຍົກເລີກ'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await ref
                  .read(tuitionPaymentProvider.notifier)
                  .deletePayment(row.tuitionPaymentId);
              ref.read(registrationProvider.notifier).getRegistrations();
              ref.read(tuitionPaymentProvider.notifier).getPayments();
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
