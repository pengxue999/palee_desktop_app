import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palee_elite_training_center/widgets/api_error_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../core/utils/registration_receipt_printer.dart';
import '../../models/registration_model.dart';
import '../../providers/academic_year_provider.dart';
import '../../providers/registration_provider.dart';
import '../../services/fee_service.dart';
import '../../services/registration_detail_service.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/success_overlay.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/print_preparation_overlay.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  static const String _allAcademicYearsValue = '__all_academic_years__';

  bool showWizard = false;
  bool showDeleteDialog = false;
  bool _isPreparingPrint = false;
  String _selectedAcademicYearId = _allAcademicYearsValue;
  RegistrationModel? selectedReg;
  final RegistrationDetailService _registrationDetailService =
      RegistrationDetailService();
  final FeeService _feeService = FeeService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(registrationProvider.notifier).getRegistrations(allYears: true);
      ref.read(academicYearProvider.notifier).getAcademicYears();
      if (mounted) {
        final error = ref.read(registrationProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  String _formatKip(double value) {
    return FormatUtils.formatKip(value.toInt());
  }

  Future<void> _printRegistration(RegistrationModel registration) async {
    if (_isPreparingPrint) {
      return;
    }

    setState(() => _isPreparingPrint = true);

    try {
      await WidgetsBinding.instance.endOfFrame;

      final detailsFuture = _registrationDetailService.getRegistrationDetails();
      final feesFuture = _feeService.getFees();

      await detailsFuture;
      await feesFuture;

      if (!mounted) {
        return;
      }

      await showRegistrationPrintDialog(
        context: context,
        registrationId: registration.registrationId,
        onPreviewReady: () {
          if (mounted && _isPreparingPrint) {
            setState(() => _isPreparingPrint = false);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ApiErrorHandler.handle(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isPreparingPrint = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationProvider);
    final academicYearState = ref.watch(academicYearProvider);
    final registrations = state.registrations;
    final academicYears = academicYearState.academicYears;
    final filteredRegistrations =
        _selectedAcademicYearId == _allAcademicYearsValue
        ? registrations
        : registrations
              .where(
                (registration) =>
                    registration.academicId == _selectedAcademicYearId,
              )
              .toList();
    final isLoading = state.isLoading && state.registrations.isEmpty;

    final columns = [
      DataColumnDef<RegistrationModel>(
        key: 'registrationId',
        label: 'ລະຫັດ',
        flex: 1,
      ),
      DataColumnDef<RegistrationModel>(
        key: 'studentName',
        label: 'ຊື່ ແລະ ນາມສະກຸນ',
        flex: 3,
      ),
      DataColumnDef<RegistrationModel>(
        key: 'academicYear',
        label: 'ສົກຮຽນ',
        flex: 2,
        render: (v, row) => Text((v as String?)?.isNotEmpty == true ? v! : '-'),
      ),
      DataColumnDef<RegistrationModel>(
        key: 'totalAmount',
        label: 'ລາຄາລວມ',
        flex: 2,
        render: (v, row) => Text(_formatKip(v as double)),
      ),
      DataColumnDef<RegistrationModel>(
        key: 'discountDescription',
        label: 'ສ່ວນຫຼຸດ',
        flex: 2,
        render: (v, row) => Text(
          v != null ? _formatKip(row.totalAmount - row.finalAmount) : '-',
        ),
      ),
      DataColumnDef<RegistrationModel>(
        key: 'finalAmount',
        label: 'ຈຳນວນທີ່ຕ້ອງຈ່າຍ',
        flex: 2,
        render: (v, row) => Text(
          _formatKip(v as double),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      DataColumnDef<RegistrationModel>(
        key: 'registrationDate',
        label: 'ວັນທີລົງທະບຽນ',
        flex: 2,
      ),
    ];

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.background,
                      AppColors.background.withValues(alpha: 0.95),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppDataTable<RegistrationModel>(
                    data: filteredRegistrations,
                    columns: columns,
                    onAdd: () => context.push('/registration/new'),
                    onPrint: (r) => _printRegistration(r),
                    onDelete: (r) => setState(() {
                      selectedReg = r;
                      showDeleteDialog = true;
                    }),
                    searchKeys: const ['studentName', 'registrationId'],
                    headerTrailing: SizedBox(
                      width: 220,
                      child: AppDropdown<String>(
                        value: _selectedAcademicYearId,
                        items: [
                          const DropdownMenuItem<String>(
                            value: _allAcademicYearsValue,
                            child: Text('ທຸກສົກຮຽນ'),
                          ),
                          ...academicYears.map(
                            (year) => DropdownMenuItem<String>(
                              value: year.academicId ?? '',
                              child: Text(year.academicYear),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _selectedAcademicYearId = value);
                        },
                        hint: 'filter ສົກຮຽນ',
                      ),
                    ),
                    addLabel: 'ລົງທະບຽນໃໝ່',
                    isLoading: isLoading,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showWizard) _buildWizard(),
        if (showDeleteDialog) _buildDeleteDialog(),
        if (_isPreparingPrint)
          const PrintPreparationOverlay(
            icon: Icons.print_rounded,
            title: 'ກຳລັງໂຫຼດ....',
            message:
                'ລະບົບກຳລັງດຶງຂໍ້ມູນການລົງທະບຽນ ແລະ ສ້າງ preview ໃຫ້ພ້ອມສຳລັບການພິມ',
            hintText: 'ຈະເປີດ preview ອັດຕະໂນມັດ',
          ),
      ],
    );
  }

  Widget _buildWizard() {
    return const SizedBox.shrink();
  }

  Widget _buildDeleteDialog() {
    if (selectedReg == null) return const SizedBox.shrink();
    final isLoading = ref.watch(registrationProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: 'ຢືນຢັນການລຶບ',
          size: AppDialogSize.small,
          onClose: () => setState(() {
            showDeleteDialog = false;
            selectedReg = null;
          }),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'ຍົກເລີກ',
                variant: AppButtonVariant.ghost,
                onPressed: () => setState(() {
                  showDeleteDialog = false;
                  selectedReg = null;
                }),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'ລຶບ',
                icon: Icons.delete,
                variant: AppButtonVariant.danger,
                onPressed: isLoading ? null : _delete,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.warning, size: 38, color: AppColors.warning),
              const SizedBox(height: 20),
              Text(
                'ທ່ານແນ່ໃຈບໍ່?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ຕ້ອງການລຶບການລົງທະບຽນຂອງ "${selectedReg!.studentFullName}" ແທ້ບໍ່?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    if (selectedReg == null) return;
    final success = await ref
        .read(registrationProvider.notifier)
        .deleteRegistration(selectedReg!.registrationId);

    if (mounted) {
      setState(() {
        showDeleteDialog = false;
      });
    }

    if (success && mounted) {
      SuccessOverlay.show(context, message: 'ລຶບການລົງທະບຽນສຳເລັດ');
      setState(() {
        selectedReg = null;
      });
    } else if (mounted) {
      final errorMessage = ref.read(registrationProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
      );
    }
  }
}
