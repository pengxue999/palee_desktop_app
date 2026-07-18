import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/widgets/api_error_handler.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_category_model.dart';
import '../../providers/donation_category_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';

class DonationCategoryScreen extends ConsumerStatefulWidget {
  const DonationCategoryScreen({super.key});

  @override
  ConsumerState<DonationCategoryScreen> createState() =>
      _DonationCategoryScreenState();
}

class _DonationCategoryScreenState
    extends ConsumerState<DonationCategoryScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  DonationCategoryModel? selectedItem;
  bool isEditing = false;

  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(donationCategoryProvider.notifier).getDonationCategories();
      if (mounted) {
        final error = ref.read(donationCategoryProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  void _resetForm() {
    _nameController.clear();
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

  void _openEdit(DonationCategoryModel item) {
    _nameController.text = item.donationCategoryName;
    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      return;
    }

    final request = DonationCategoryRequest(
      donationCategoryName: _nameController.text.trim(),
    );

    bool success;
    if (isEditing && selectedItem != null) {
      success = await ref
          .read(donationCategoryProvider.notifier)
          .updateDonationCategory(selectedItem!.donationCategoryId, request);
    } else {
      success = await ref
          .read(donationCategoryProvider.notifier)
          .createDonationCategory(request);
    }

    if (success && mounted) {
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else if (mounted) {
      final errorMessage = ref.read(donationCategoryProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(DonationCategoryModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem == null) {
      return;
    }

    final success = await ref
        .read(donationCategoryProvider.notifier)
        .deleteDonationCategory(selectedItem!.donationCategoryId);

    if (mounted) {
      setState(() {
        showDeleteDialog = false;
      });
    }

    if (success && mounted) {
      setState(() {
        selectedItem = null;
      });
    } else if (mounted) {
      final errorMessage = ref.read(donationCategoryProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(donationCategoryProvider);
    final isLoading = state.isLoading && state.donationCategories.isEmpty;

    final columns = [
      DataColumnDef<DonationCategoryModel>(
        key: 'donationCategoryName',
        label: 'ຊື່ປະເພດການບໍລິຈາກ',
        flex: 5,
      ),
    ];

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppDataTable<DonationCategoryModel>(
                  data: isLoading
                      ? _getMockDonationCategories()
                      : state.donationCategories,
                  columns: columns,
                  onAdd: _openAdd,
                  onEdit: _openEdit,
                  onDelete: _confirmDelete,
                  searchKeys: const ['donationCategoryName'],
                  addLabel: 'ເພີ່ມປະເພດການບໍລິຈາກ',
                  isLoading: isLoading,
                ),
              ),
            ),
          ],
        ),
        if (showAddEditModal) _buildFormModal(),
        if (showDeleteDialog) _buildDeleteDialog(),
      ],
    );
  }

  List<DonationCategoryModel> _getMockDonationCategories() {
    return List.generate(
      5,
      (index) => DonationCategoryModel(
        donationCategoryId: index + 1,
        donationCategoryName: 'ປະເພດ ${index + 1}',
      ),
    );
  }

  bool get _isFormValid => _nameController.text.isNotEmpty;

  Widget _buildFormModal() {
    final isLoading = ref.watch(donationCategoryProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂປະເພດການບໍລິຈາກ' : 'ເພີ່ມປະເພດການບໍລິຈາກໃໝ່',
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
          child: AppTextField(
            label: 'ປະເພດການບໍລິຈາກ',
            hint: 'ປ້ອນຊື່ປະເພດການບໍລິຈາກ',
            controller: _nameController,
            required: true,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    if (selectedItem == null) {
      return const SizedBox.shrink();
    }

    final isLoading = ref.watch(donationCategoryProvider).isLoading;
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
                'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "${selectedItem!.donationCategoryName}"?',
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
