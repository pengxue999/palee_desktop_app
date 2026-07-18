import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/widgets/api_error_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../models/donor_model.dart';
import '../../providers/donor_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';

class DonorsScreen extends ConsumerStatefulWidget {
  const DonorsScreen({super.key});

  @override
  ConsumerState<DonorsScreen> createState() => _DonorsScreenState();
}

class _DonorsScreenState extends ConsumerState<DonorsScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  DonorModel? selectedItem;
  bool isEditing = false;

  final _nameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _contactController = TextEditingController();
  final _sectionController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _lastnameFocusNode = FocusNode();
  final _contactFocusNode = FocusNode();
  final _sectionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(donorProvider.notifier).getDonors();
      if (mounted) {
        final error = ref.read(donorProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  void _resetForm() {
    _nameController.clear();
    _lastnameController.clear();
    _contactController.clear();
    _sectionController.clear();
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

  void _openEdit(DonorModel item) {
    _nameController.text = item.donorName;
    _lastnameController.text = item.donorLastname;
    _contactController.text = item.donorContact;
    _sectionController.text = item.section ?? '';
    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _lastnameController.text.trim().isEmpty ||
        _contactController.text.trim().isEmpty) {
      return;
    }
    final request = DonorRequest(
      donorName: _nameController.text.trim(),
      donorLastname: _lastnameController.text.trim(),
      donorContact: _contactController.text.trim(),
      section: _sectionController.text.trim().isNotEmpty
          ? _sectionController.text.trim()
          : null,
    );
    bool success;
    if (isEditing && selectedItem != null) {
      success = await ref
          .read(donorProvider.notifier)
          .updateDonor(selectedItem!.donorId, request);
    } else {
      success = await ref.read(donorProvider.notifier).createDonor(request);
    }
    if (success && mounted) {
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else if (mounted) {
      final errorMessage = ref.read(donorProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(DonorModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem == null) return;
    final success = await ref
        .read(donorProvider.notifier)
        .deleteDonor(selectedItem!.donorId);

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
      final errorMessage = ref.read(donorProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastnameController.dispose();
    _contactController.dispose();
    _sectionController.dispose();
    _nameFocusNode.dispose();
    _lastnameFocusNode.dispose();
    _contactFocusNode.dispose();
    _sectionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(donorProvider);
    final isLoading = state.isLoading && state.donors.isEmpty;

    final columns = [
      DataColumnDef<DonorModel>(key: 'donorId', label: 'ລະຫັດ', flex: 2),
      DataColumnDef<DonorModel>(
        key: 'fullName',
        label: 'ຊື່ ແລະ ນາມສະກຸນ',
        flex: 3,
      ),
      DataColumnDef<DonorModel>(
        key: 'donorContact',
        label: 'ເບີໂທຕິດຕໍ່',
        flex: 2,
      ),
      DataColumnDef<DonorModel>(
        key: 'section',
        label: 'ໜ່ວຍງານ / ອົງກອນ',
        flex: 3,
        render: (context, item) => Text(
          item.section ?? '-',
          style: TextStyle(
            fontSize: 13,
            color: item.section != null
                ? AppColors.foreground
                : AppColors.mutedForeground,
          ),
        ),
      ),
    ];

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: AppDataTable<DonorModel>(
                  data: isLoading ? _getMockDonors() : state.donors,
                  columns: columns,
                  onAdd: _openAdd,
                  onEdit: _openEdit,
                  onDelete: _confirmDelete,
                  searchKeys: const [
                    'donorId',
                    'fullName',
                    'donorContact',
                    'section',
                  ],
                  addLabel: 'ເພີ່ມຜູ້ບໍລິຈາກ',
                  isLoading: isLoading,
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

  List<DonorModel> _getMockDonors() {
    return List.generate(
      5,
      (index) => DonorModel(
        donorId: 'DN00${index + 1}',
        donorName: 'ຜູ້ບໍລິຈາກ ${index + 1}',
        donorLastname: 'ທ້າວ',
        donorContact: '0201234567',
        section: 'ບໍລິສັດ ABC',
      ),
    );
  }

  bool get _isFormValid {
    return _nameController.text.isNotEmpty &&
        _lastnameController.text.isNotEmpty &&
        _contactController.text.isNotEmpty;
  }

  Widget _buildFormModal() {
    final isLoading = ref.watch(donorProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂຂໍ້ມູນຜູ້ບໍລິຈາກ' : 'ເພີ່ມຜູ້ບໍລິຈາກໃໝ່',
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
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'ຊື່',
                      hint: 'ປ້ອນຊື່ຜູ້ບໍລິຈາກ ',
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      textInputAction: TextInputAction.next,
                      required: true,
                      onChanged: (_) => setState(() {}),
                      onFieldSubmitted: (_) =>
                          _lastnameFocusNode.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: 'ນາມສະກຸນ',
                      hint: 'ປ້ອນນາມສະກຸນ',
                      controller: _lastnameController,
                      focusNode: _lastnameFocusNode,
                      textInputAction: TextInputAction.next,
                      required: true,
                      onChanged: (_) => setState(() {}),
                      onFieldSubmitted: (_) => _contactFocusNode.requestFocus(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'ເບີໂທຕິດຕໍ່',
                hint: '020XXXXXXXX',
                controller: _contactController,
                focusNode: _contactFocusNode,
                required: true,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                digitOnly: DigitOnly.integer,
                maxLength: 11,
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _sectionFocusNode.requestFocus(),
              ),

              const SizedBox(height: 16),
              AppTextField(
                label: 'ໜ່ວຍງານ / ອົງກອນ (ຖ້າມີ)',
                hint: 'ຕົວຢ່າງ: ສູນສົ່ງເສີທການຮຽນຮູ້, ບໍລິສັດ UNITEL',
                controller: _sectionController,
                focusNode: _sectionFocusNode,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    if (selectedItem == null) return const SizedBox.shrink();
    final isLoading = ref.watch(donorProvider).isLoading;
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
                'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "${selectedItem!.fullName}"?',
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
