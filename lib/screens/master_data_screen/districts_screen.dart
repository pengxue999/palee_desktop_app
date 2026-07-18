import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/models/district_model.dart';
import 'package:palee_elite_training_center/models/province_model.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/district_provider.dart';
import '../../providers/province_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_text_field.dart';

class DistrictsScreen extends ConsumerStatefulWidget {
  const DistrictsScreen({super.key});

  @override
  ConsumerState<DistrictsScreen> createState() => _DistrictsScreenState();
}

class _DistrictsScreenState extends ConsumerState<DistrictsScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  DistrictModel? selectedItem;
  bool isEditing = false;

  final _nameController = TextEditingController();
  int? _selectedProvinceId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        ref.read(districtProvider.notifier).getDistricts(),
        ref.read(provinceProvider.notifier).getProvinces(),
      ]);
      if (!mounted) {
        return;
      }
      final districtError = ref.read(districtProvider).error;
      final provinceError = ref.read(provinceProvider).error;
      if (districtError != null) {
        ApiErrorHandler.handle(context, districtError);
      } else if (provinceError != null) {
        ApiErrorHandler.handle(context, provinceError);
      }
    });
  }

  List<ProvinceModel> get _provinces => ref.watch(provinceProvider).provinces;

  void _resetForm() {
    _nameController.clear();
    _selectedProvinceId = null;
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

  void _openEdit(DistrictModel item) {
    _nameController.text = item.districtName;
    _selectedProvinceId = _provinces
        .where((province) => province.provinceName == item.provinceName)
        .firstOrNull
        ?.provinceId;
    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _selectedProvinceId == null) {
      return;
    }

    final request = DistrictRequest(
      districtName: _nameController.text.trim(),
      provinceId: _selectedProvinceId!,
    );

    final success = isEditing && selectedItem != null
        ? await ref
              .read(districtProvider.notifier)
              .updateDistrict(selectedItem!.districtId, request)
        : await ref.read(districtProvider.notifier).createDistrict(request);

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

    final errorMessage = ref.read(districtProvider).error;
    ApiErrorHandler.handle(
      context,
      errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
    );
  }

  void _confirmDelete(DistrictModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem == null) {
      return;
    }

    final success = await ref
        .read(districtProvider.notifier)
        .deleteDistrict(selectedItem!.districtId);

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

    final errorMessage = ref.read(districtProvider).error;
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
    final state = ref.watch(districtProvider);
    final isLoading = state.isLoading && state.districts.isEmpty;

    final columns = [
      DataColumnDef<DistrictModel>(
        key: 'districtName',
        label: 'ຊື່ເມືອງ',
        flex: 3,
        render: (value, row) => Text(
          value.toString(),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      DataColumnDef<DistrictModel>(
        key: 'provinceName',
        label: 'ຂຶ້ນກັບແຂວງ',
        flex: 3,
        render: (value, row) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF7DD3FC)),
          ),
          child: Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0C4A6E),
            ),
          ),
        ),
      ),
    ];

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: AppDataTable<DistrictModel>(
            data: isLoading ? _getMockDistricts() : state.districts,
            columns: columns,
            onAdd: _openAdd,
            onEdit: _openEdit,
            onDelete: _confirmDelete,
            searchKeys: const ['districtId', 'districtName', 'provinceName'],
            addLabel: 'ເພີ່ມເມືອງ',
            isLoading: isLoading,
          ),
        ),
        if (showAddEditModal) _buildFormModal(),
        if (showDeleteDialog) _buildDeleteDialog(),
      ],
    );
  }

  List<DistrictModel> _getMockDistricts() {
    return List.generate(
      5,
      (index) => DistrictModel(
        districtId: index + 1,
        districtName: 'ເມືອງຕົວຢ່າງ ${index + 1}',
        provinceName: 'ແຂວງຕົວຢ່າງ',
      ),
    );
  }

  Widget _buildFormModal() {
    final isLoading = ref.watch(districtProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂຂໍ້ມູນເມືອງ' : 'ເພີ່ມຂໍ້ມູນເມືອງ',
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
                onPressed:
                    (isLoading ||
                        _nameController.text.trim().isEmpty ||
                        _selectedProvinceId == null)
                    ? null
                    : _save,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'ຊື່ເມືອງ',
                hint: 'ເຊັ່ນ: ໄຊເສດຖາ',
                controller: _nameController,
                required: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              AppDropdown<int>(
                label: 'ແຂວງ',
                hint: 'ເລືອກແຂວງ',
                value: _selectedProvinceId,
                required: true,
                items: _provinces
                    .map(
                      (province) => DropdownMenuItem<int>(
                        value: province.provinceId,
                        child: Text(province.provinceName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProvinceId = value;
                  });
                },
              ),
            ],
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
            'ທ່ານຕ້ອງການລຶບ ${selectedItem?.districtName ?? 'ລາຍການນີ້'} ຫຼືບໍ່?',
            style: const TextStyle(fontSize: 14, color: AppColors.foreground),
          ),
        ),
      ),
    );
  }
}
