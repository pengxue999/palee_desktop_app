import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/models/province_model.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/province_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';

class ProvincesScreen extends ConsumerStatefulWidget {
  const ProvincesScreen({super.key});

  @override
  ConsumerState<ProvincesScreen> createState() => _ProvincesScreenState();
}

class _ProvincesScreenState extends ConsumerState<ProvincesScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  ProvinceModel? selectedItem;
  bool isEditing = false;

  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(provinceProvider.notifier).getProvinces();
      if (!mounted) {
        return;
      }
      final error = ref.read(provinceProvider).error;
      if (error != null) {
        ApiErrorHandler.handle(context, error);
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

  void _openEdit(ProvinceModel item) {
    _nameController.text = item.provinceName;
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

    final request = ProvinceRequest(provinceName: _nameController.text.trim());

    final success = isEditing && selectedItem != null
        ? await ref
              .read(provinceProvider.notifier)
              .updateProvince(selectedItem!.provinceId, request)
        : await ref.read(provinceProvider.notifier).createProvince(request);

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
      return;
    }

    final errorMessage = ref.read(provinceProvider).error;
    ApiErrorHandler.handle(
      context,
      errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
    );
  }

  void _confirmDelete(ProvinceModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem == null) {
      return;
    }

    final success = await ref
        .read(provinceProvider.notifier)
        .deleteProvince(selectedItem!.provinceId);

    if (!mounted) {
      return;
    }

    setState(() {
      showDeleteDialog = false;
    });

    if (success) {
      setState(() {
        selectedItem = null;
      });
      return;
    }

    final errorMessage = ref.read(provinceProvider).error;
    ApiErrorHandler.handle(
      context,
      errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(provinceProvider);
    final isLoading = state.isLoading && state.provinces.isEmpty;

    final columns = [
      DataColumnDef<ProvinceModel>(
        key: 'provinceName',
        label: 'ຊື່ແຂວງ',
        flex: 4,
      ),
    ];

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: AppDataTable<ProvinceModel>(
            data: isLoading ? _getMockProvinces() : state.provinces,
            columns: columns,
            onAdd: _openAdd,
            onEdit: _openEdit,
            onDelete: _confirmDelete,
            searchKeys: const ['provinceId', 'provinceName'],
            addLabel: 'ເພີ່ມແຂວງ',
            isLoading: isLoading,
          ),
        ),
        if (showAddEditModal) _buildFormModal(),
        if (showDeleteDialog) _buildDeleteDialog(),
      ],
    );
  }

  List<ProvinceModel> _getMockProvinces() {
    return List.generate(
      5,
      (index) => ProvinceModel(
        provinceId: index + 1,
        provinceName: 'ແຂວງຕົວຢ່າງ ${index + 1}',
      ),
    );
  }

  Widget _buildFormModal() {
    final isLoading = ref.watch(provinceProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂຂໍ້ມູນແຂວງ' : 'ເພີ່ມຂໍ້ມູນແຂວງ',
          size: AppDialogSize.small,
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
                onPressed: (isLoading || _nameController.text.trim().isEmpty)
                    ? null
                    : _save,
              ),
            ],
          ),
          child: AppTextField(
            label: 'ຊື່ແຂວງ',
            hint: 'ເຊັ່ນ: ນະຄອນຫຼວງວຽງຈັນ',
            controller: _nameController,
            required: true,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: 'ຢືນຢັນການລຶບ',
          size: AppDialogSize.small,
          onClose: () => setState(() {
            showDeleteDialog = false;
          }),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'ຍົກເລີກ',
                variant: AppButtonVariant.ghost,
                onPressed: () => setState(() {
                  showDeleteDialog = false;
                }),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'ລຶບ',
                icon: Icons.delete_rounded,
                variant: AppButtonVariant.danger,
                onPressed: _delete,
              ),
            ],
          ),
          child: Text(
            'ທ່ານຕ້ອງການລຶບ ${selectedItem?.provinceName ?? 'ລາຍການນີ້'} ຫຼືບໍ່?',
            style: const TextStyle(fontSize: 14, color: AppColors.foreground),
          ),
        ),
      ),
    );
  }
}
