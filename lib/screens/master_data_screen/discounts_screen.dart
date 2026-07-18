import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/enum_localization.dart';
import '../../models/discount_model.dart';
import '../../providers/discount_provider.dart';
import '../../providers/academic_year_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dropdown.dart';

const _discountDescriptionLabels = ['ຮຽນຫຼາຍວິຊາ', 'ລົງທະບຽນຮຽນຊ້າ'];
const _multiSubjectLabel = 'ຮຽນຫຼາຍວິຊາ';

// ປ້າຍ/ຄຳໃບ້ ຂອງຊ່ອງ threshold ປ່ຽນຕາມເງື່ອນໄຂສ່ວນຫຼຸດທີ່ເລືອກ.
({String label, String hint}) _thresholdFieldMeta(String? description) {
  if (description == _multiSubjectLabel) {
    return (label: 'ຈຳນວນວິຊາ', hint: 'ເຊັ່ນ: 3 (ວິຊາ)');
  }
  return (label: 'ຈຳນວນມື້', hint: 'ເຊັ່ນ: 60 (ມື້)');
}

class DiscountsScreen extends ConsumerStatefulWidget {
  const DiscountsScreen({super.key});

  @override
  ConsumerState<DiscountsScreen> createState() => _DiscountsScreenState();
}

class _DiscountsScreenState extends ConsumerState<DiscountsScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  DiscountModel? selectedItem;
  bool isEditing = false;

  final _amountController = TextEditingController();
  final _thresholdController = TextEditingController();
  String? _selectedDescription;
  String? _selectedAcademicId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(discountProvider.notifier).getDiscounts();
      ref.read(academicYearProvider.notifier).getAcademicYears();
      if (mounted) {
        final error = ref.read(discountProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  void _resetForm() {
    _amountController.clear();
    _thresholdController.clear();
    _selectedDescription = null;
    _selectedAcademicId = null;
    selectedItem = null;
    isEditing = false;
  }

  void _openAdd() {
    _resetForm();
    setState(() {
      showAddEditModal = true;
      isEditing = false;
    });
  }

  void _openEdit(DiscountModel item) {
    _amountController.text = item.discountAmount.toStringAsFixed(0);
    _thresholdController.text = item.thresholdValue.toString();
    _selectedDescription =
        _discountDescriptionLabels.contains(item.discountDescription)
        ? item.discountDescription
        : null;
    final academicYears = ref.read(academicYearProvider).academicYears;
    _selectedAcademicId = academicYears
        .where((a) => a.academicYear == item.academicYear)
        .map((a) => a.academicId)
        .firstOrNull;
    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    final threshold = int.tryParse(_thresholdController.text.trim());
    if (amount == null ||
        amount <= 0 ||
        threshold == null ||
        threshold <= 0 ||
        _selectedDescription == null ||
        _selectedAcademicId == null) {
      return;
    }
    final request = DiscountRequest(
      academicId: _selectedAcademicId!,
      discountAmount: amount,
      discountDescription: _selectedDescription!,
      thresholdValue: threshold,
    );
    bool success;
    if (isEditing && selectedItem != null) {
      success = await ref
          .read(discountProvider.notifier)
          .updateDiscount(selectedItem!.discountId, request);
    } else {
      success = await ref
          .read(discountProvider.notifier)
          .createDiscount(request);
    }
    if (success && mounted) {
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else if (mounted) {
      final errorMessage = ref.read(discountProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(DiscountModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem == null) return;
    final success = await ref
        .read(discountProvider.notifier)
        .deleteDiscount(selectedItem!.discountId);
    if (success && mounted) {
      setState(() {
        showDeleteDialog = false;
        selectedItem = null;
      });
    } else if (mounted) {
      final errorMessage = ref.read(discountProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discountProvider);
    final isLoading = state.isLoading && state.discounts.isEmpty;
    final academicYearsList = ref.watch(academicYearProvider).academicYears;
    final endedAcademicYears = <String>{
      for (final a in academicYearsList)
        if (!isActiveAcademicStatus(a.academicStatus)) a.academicYear,
    };

    final columns = [
      DataColumnDef<DiscountModel>(key: 'discountId', label: 'ລະຫັດ', flex: 2),
      DataColumnDef<DiscountModel>(
        key: 'discountDescription',
        label: 'ເງື່ອນໄຂສ່ວນຫຼຸດ',
        flex: 4,
      ),
      DataColumnDef<DiscountModel>(
        key: 'thresholdValue',
        label: 'ຄ່າເງື່ອນໄຂ',
        flex: 2,
        render: (context, item) => Text(
          item.discountDescription == _multiSubjectLabel
              ? '${item.thresholdValue} ວິຊາ'
              : '${item.thresholdValue} ມື້',
          style: const TextStyle(fontSize: 13, color: AppColors.foreground),
        ),
      ),
      DataColumnDef<DiscountModel>(
        key: 'discountAmount',
        label: 'ຈຳນວນສ່ວນຫຼຸດ (%)',
        flex: 2,
        render: (context, item) => Text(
          '${item.discountAmount.toStringAsFixed(0)} %',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      DataColumnDef<DiscountModel>(
        key: 'academicYear',
        label: 'ສົກຮຽນ',
        flex: 2,
      ),
    ];

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: AppDataTable<DiscountModel>(
                  data: isLoading ? _getMockDiscounts() : state.discounts,
                  columns: columns,
                  onAdd: _openAdd,
                  onEdit: _openEdit,
                  onDelete: _confirmDelete,
                  searchKeys: const ['discountId', 'discountDescription'],
                  addLabel: 'ເພີ່ມສ່ວນຫຼຸດ',
                  isLoading: isLoading,
                  isRowMuted: (row) =>
                      endedAcademicYears.contains(row.academicYear),
                ),
              ),
            ],
          ),
        ),
        if (showAddEditModal) _buildFormModal(),
        if (showDeleteDialog) _buildDeleteDialog(),
      ],
    );
  }

  List<DiscountModel> _getMockDiscounts() {
    return List.generate(
      5,
      (index) => DiscountModel(
        discountId: (1000 + index + 1).toString(),
        discountDescription: localizeDiscountDescription('MULTI_SUBJECT'),
        discountAmount: 10.0 + index * 5,
        thresholdValue: 3,
        academicYear: '2024-2025',
      ),
    );
  }

  bool get _isFormValid {
    return _selectedAcademicId != null &&
        _selectedDescription != null &&
        _amountController.text.isNotEmpty &&
        _thresholdController.text.isNotEmpty;
  }

  Widget _buildFormModal() {
    final isLoading = ref.watch(discountProvider).isLoading;
    final academicYears = ref.watch(academicYearProvider).academicYears;

    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂສ່ວນຫຼຸດ' : 'ເພີ່ມສ່ວນຫຼຸດໃໝ່',
          size: AppDialogSize.medium,
          onClose: () => setState(() {
            showAddEditModal = false;
            _resetForm();
          }),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'ຍົກເລີກ',
                variant: AppButtonVariant.ghost,
                onPressed: () => setState(() {
                  showAddEditModal = false;
                  _resetForm();
                }),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: isEditing ? 'ຢືນຢັນ' : 'ບັນທຶກ',
                icon: Icons.save_rounded,
                isLoading: isLoading,
                onPressed: (isLoading || !_isFormValid) ? null : _save,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppDropdown<String>(
                label: 'ສົກຮຽນ',
                value: _selectedAcademicId,
                required: true,
                hint: 'ເລືອກສົກຮຽນ',
                items: academicYears
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.academicId,
                        child: Text(a.academicYear),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedAcademicId = v),
              ),
              const SizedBox(height: 16),
              AppDropdown<String>(
                label: 'ເງື່ອນໄຂສ່ວນຫຼຸດ',
                value: _selectedDescription,
                required: true,
                hint: 'ເລືອກເງື່ອນໄຂ',
                items: _discountDescriptionLabels
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDescription = v),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: _thresholdFieldMeta(_selectedDescription).label,
                hint: _thresholdFieldMeta(_selectedDescription).hint,
                controller: _thresholdController,
                required: true,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                digitOnly: DigitOnly.integer,
                noLeadingZero: true,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'ຈຳນວນສ່ວນຫຼຸດ (%)',
                hint: 'ປ້ອນຈຳນວນເປີເຊັນສ່ວນຫຼຸດ(ເຊັ່ນ: 10)',
                controller: _amountController,
                required: true,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                digitOnly: DigitOnly.integer,
                noLeadingZero: true,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    if (selectedItem == null) return const SizedBox.shrink();
    final isLoading = ref.watch(discountProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: 'ຢືນຢັນການລຶບ',
          size: AppDialogSize.small,
          onClose: () => setState(() {
            showDeleteDialog = false;
            selectedItem = null;
          }),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'ຍົກເລີກ',
                variant: AppButtonVariant.ghost,
                onPressed: () => setState(() {
                  showDeleteDialog = false;
                  selectedItem = null;
                }),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'ລຶບ',
                icon: Icons.delete_rounded,
                variant: AppButtonVariant.danger,
                isLoading: isLoading,
                onPressed: isLoading ? null : _delete,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: AppColors.warning,
              ),
              const SizedBox(height: 16),
              Text(
                'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "${selectedItem!.discountDescription}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
