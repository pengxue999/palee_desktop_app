import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/teacher_model.dart';
import '../../models/district_model.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/province_provider.dart';
import '../../providers/district_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';

class TeachersScreen extends ConsumerStatefulWidget {
  const TeachersScreen({super.key});

  @override
  ConsumerState<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends ConsumerState<TeachersScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  TeacherModel? selectedItem;
  bool isEditing = false;

  final _nameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _lastnameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  String _selectedGender = 'ຊາຍ';
  int? _selectedProvinceId;
  int? _selectedDistrictId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(teacherProvider.notifier).getTeachers();
      ref.read(provinceProvider.notifier).getProvinces();
      ref.read(districtProvider.notifier).getDistricts();
      if (mounted) {
        final error = ref.read(teacherProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  String _normalizeGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
      case 'm':
        return 'ຊາຍ';
      case 'female':
      case 'f':
        return 'ຍິງ';
      case 'ຊາຍ':
      case 'ຍິງ':
        return gender;
      default:
        return 'ຊາຍ';
    }
  }

  List<DistrictModel> get _filteredDistricts {
    if (_selectedProvinceId == null) return [];
    final allDistricts = ref.read(districtProvider).districts;
    final allProvinces = ref.read(provinceProvider).provinces;
    final province = allProvinces
        .where((p) => p.provinceId == _selectedProvinceId)
        .firstOrNull;
    if (province == null) return [];
    return allDistricts
        .where((d) => d.provinceName == province.provinceName)
        .toList();
  }

  void _resetForm() {
    _nameController.clear();
    _lastnameController.clear();
    _phoneController.clear();
    _selectedGender = 'ຊາຍ';
    _selectedProvinceId = null;
    _selectedDistrictId = null;
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

  void _openEdit(TeacherModel item) {
    _nameController.text = item.teacherName;
    _lastnameController.text = item.teacherLastname;
    _phoneController.text = item.teacherContact;
    _selectedGender = item.gender;

    final allDistricts = ref.read(districtProvider).districts;
    final district = allDistricts
        .where((d) => d.districtName == item.districtName)
        .firstOrNull;
    if (district != null) {
      _selectedDistrictId = district.districtId;
      final allProvinces = ref.read(provinceProvider).provinces;
      final province = allProvinces
          .where((p) => p.provinceName == item.provinceName)
          .firstOrNull;
      _selectedProvinceId = province?.provinceId;
    }

    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _lastnameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _selectedDistrictId == null) {
      return;
    }

    final request = TeacherRequest(
      teacherName: _nameController.text.trim(),
      teacherLastname: _lastnameController.text.trim(),
      gender: _selectedGender,
      teacherContact: _phoneController.text.trim(),
      districtId: _selectedDistrictId!,
    );

    bool success;
    if (isEditing && selectedItem != null) {
      success = await ref
          .read(teacherProvider.notifier)
          .updateTeacher(selectedItem!.teacherId, request);
    } else {
      success = await ref.read(teacherProvider.notifier).createTeacher(request);
    }

    if (success && mounted) {
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else if (mounted) {
      final errorMessage = ref.read(teacherProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(TeacherModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem == null) return;
    final success = await ref
        .read(teacherProvider.notifier)
        .deleteTeacher(selectedItem!.teacherId);

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
      final errorMessage = ref.read(teacherProvider).error;
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
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _lastnameFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teacherState = ref.watch(teacherProvider);
    final isLoading = teacherState.isLoading && teacherState.teachers.isEmpty;

    final columns = [
      DataColumnDef<TeacherModel>(key: 'teacherId', label: 'ລະຫັດ', flex: 2),
      DataColumnDef<TeacherModel>(
        key: 'teacherName',
        label: 'ຊື່ ແລະ ນາມສະກຸນ',
        flex: 3,
        render: (v, row) => Text(row.fullName),
      ),
      DataColumnDef<TeacherModel>(
        key: 'gender',
        label: 'ເພດ',
        flex: 1,
        render: (context, item) => Text(_normalizeGender(item.gender)),
      ),
      DataColumnDef<TeacherModel>(
        key: 'teacherContact',
        label: 'ເບີໂທ',
        flex: 2,
      ),
      DataColumnDef<TeacherModel>(key: 'districtName', label: 'ເມືອງ', flex: 2),
      DataColumnDef<TeacherModel>(key: 'provinceName', label: 'ແຂວງ', flex: 2),
    ];

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: AppDataTable<TeacherModel>(
            data: isLoading ? _getMockTeachers() : teacherState.teachers,
            columns: columns,
            onAdd: _openAdd,
            onEdit: _openEdit,
            onDelete: _confirmDelete,
            searchKeys: const [
              'teacherId',
              'teacherName',
              'teacherLastname',
              'teacherContact',
            ],
            addLabel: 'ເພີ່ມອາຈານ',
            isLoading: isLoading,
          ),
        ),
        if (showAddEditModal) _buildFormModal(),
        if (showDeleteDialog) _buildDeleteDialog(),
      ],
    );
  }

  List<TeacherModel> _getMockTeachers() {
    return List.generate(
      5,
      (index) => TeacherModel(
        teacherId: 'TC00${index + 1}',
        teacherName: 'ອາຈານ ${index + 1}',
        teacherLastname: 'ທ້າວ',
        gender: 'ຊາຍ',
        teacherContact: '0201234567',
        districtName: 'ເມືອງຕົວຢ່າງ',
        provinceName: 'ແຂວງຕົວຢ່າງ',
      ),
    );
  }

  bool get _isFormValid {
    return _nameController.text.isNotEmpty &&
        _lastnameController.text.isNotEmpty &&
        _selectedGender.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _selectedProvinceId != null &&
        _selectedDistrictId != null;
  }

  Widget _buildFormModal() {
    final teacherState = ref.watch(teacherProvider);
    final provinces = ref.watch(provinceProvider).provinces;

    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂຂໍ້ມູນອາຈານ' : 'ເພີ່ມອາຈານໃໝ່',
          size: AppDialogSize.large,
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
                isLoading: teacherState.isLoading,
                onPressed: (teacherState.isLoading || !_isFormValid)
                    ? null
                    : _save,
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
                      hint: 'ປ້ອນຊື່ອາຈານ',
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          _lastnameFocusNode.requestFocus(),
                      required: true,
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
                      onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppDropdown<String>(
                      label: 'ເພດ',
                      value: _selectedGender,
                      required: true,
                      items: ['ຊາຍ', 'ຍິງ']
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedGender = v ?? 'ຊາຍ'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: 'ເບີໂທຕິດຕໍ່',
                      hint: '020XXXXXXXX',
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      required: true,
                      digitOnly: DigitOnly.integer,
                      maxLength: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppDropdown<int>(
                label: 'ແຂວງ',
                hint: 'ເລືອກແຂວງກ່ອນ',
                value: provinces.any((p) => p.provinceId == _selectedProvinceId)
                    ? _selectedProvinceId
                    : null,
                required: true,
                items: provinces
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.provinceId,
                        child: Text(p.provinceName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedProvinceId = v;
                  _selectedDistrictId = null;
                }),
              ),
              const SizedBox(height: 16),
              AppDropdown<int>(
                label: 'ເມືອງ',
                hint: _selectedProvinceId == null
                    ? 'ກະລຸນາເລືອກແຂວງກ່ອນ'
                    : 'ເລືອກເມືອງ',
                value:
                    _filteredDistricts.any(
                      (d) => d.districtId == _selectedDistrictId,
                    )
                    ? _selectedDistrictId
                    : null,
                required: true,
                items: _filteredDistricts
                    .map(
                      (d) => DropdownMenuItem(
                        value: d.districtId,
                        child: Text(d.districtName),
                      ),
                    )
                    .toList(),
                onChanged: _selectedProvinceId == null
                    ? null
                    : (v) => setState(() => _selectedDistrictId = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    if (selectedItem == null) return const SizedBox.shrink();
    final teacherState = ref.watch(teacherProvider);
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
                isLoading: teacherState.isLoading,
                onPressed: teacherState.isLoading ? null : _delete,
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
            ],
          ),
        ),
      ),
    );
  }
}
