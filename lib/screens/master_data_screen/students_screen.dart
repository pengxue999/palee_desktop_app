import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/constants/app_colors.dart';
import '../../models/province_model.dart';
import '../../models/district_model.dart';
import '../../models/student_model.dart';
import '../../providers/province_provider.dart';
import '../../providers/district_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  StudentModel? selectedItem;
  bool isEditing = false;

  final _nameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentsContactController = TextEditingController();
  final _schoolController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _lastnameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _parentsContactFocusNode = FocusNode();
  final _schoolFocusNode = FocusNode();
  String _selectedGender = 'ຊາຍ';
  int? _selectedProvinceId;
  int? _selectedDistrictId;

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _lastnameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _parentsContactController.text.trim().isNotEmpty &&
        _schoolController.text.trim().isNotEmpty &&
        _selectedProvinceId != null &&
        _selectedDistrictId != null;
  }

  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(studentProvider.notifier).getStudents();
      ref.read(provinceProvider.notifier).getProvinces();
      if (mounted) {
        final error = ref.read(studentProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  List<StudentModel> get _students => ref.watch(studentProvider).students;
  List<ProvinceModel> get _provinces => ref.watch(provinceProvider).provinces;
  List<DistrictModel> get _filteredDistricts =>
      ref.watch(districtProvider).filteredDistricts;

  void _resetForm() {
    _nameController.clear();
    _lastnameController.clear();
    _phoneController.clear();
    _parentsContactController.clear();
    _schoolController.clear();
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

  void _openEdit(StudentModel item) async {
    _nameController.text = item.studentName;
    _lastnameController.text = item.studentLastname;
    _phoneController.text = item.studentContact;
    _parentsContactController.text = item.parentsContact;
    _schoolController.text = item.school;
    _selectedGender = _normalizeGender(item.gender);

    await ref.read(districtProvider.notifier).getDistricts();

    final districts = ref.read(districtProvider).districts;
    final district = districts
        .where((d) => d.districtName == item.districtName)
        .firstOrNull;

    if (district != null) {
      _selectedDistrictId = district.districtId;
      _selectedProvinceId = _findProvinceIdByName(district.provinceName);
      if (_selectedProvinceId != null) {
        await ref
            .read(districtProvider.notifier)
            .getDistrictsByProvince(_selectedProvinceId!);
      }
    } else {
      _selectedDistrictId = null;
      _selectedProvinceId = null;
    }

    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  int? _findProvinceIdByName(String provinceName) {
    final province = _provinces
        .where((p) => p.provinceName == provinceName)
        .firstOrNull;
    return province?.provinceId;
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

  Future<void> _save() async {
    setState(() {
      _autoValidate = true;
    });

    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedProvinceId == null || _selectedDistrictId == null) {
      return;
    }

    final request = StudentRequest(
      studentName: _nameController.text.trim(),
      studentLastname: _lastnameController.text.trim(),
      gender: _selectedGender,
      studentContact: _phoneController.text.trim(),
      parentsContact: _parentsContactController.text.trim(),
      school: _schoolController.text.trim(),
      districtId: _selectedDistrictId!,
    );

    bool success;
    if (isEditing && selectedItem != null && selectedItem!.studentId != null) {
      success = await ref
          .read(studentProvider.notifier)
          .updateStudent(selectedItem!.studentId!, request);
    } else {
      success = await ref.read(studentProvider.notifier).createStudent(request);
    }

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else {
      final errorMessage = ref.read(studentProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(StudentModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem != null && selectedItem!.studentId != null) {
      final success = await ref
          .read(studentProvider.notifier)
          .deleteStudent(selectedItem!.studentId!);

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
        final errorMessage = ref.read(studentProvider).error;
        ApiErrorHandler.handle(
          context,
          errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການລຶບຂໍ້ມູນ',
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastnameController.dispose();
    _phoneController.dispose();
    _parentsContactController.dispose();
    _schoolController.dispose();
    _nameFocusNode.dispose();
    _lastnameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _parentsContactFocusNode.dispose();
    _schoolFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columns = [
      DataColumnDef<StudentModel>(
        key: 'studentId',
        label: 'ລະຫັດ',
        flex: 2,
        render: (context, item) => Text(item.studentId ?? 'N/A'),
      ),
      DataColumnDef<StudentModel>(
        key: 'studentName',
        label: 'ຊື່ ແລະ ນາມສະກຸນ',
        flex: 3,
        render: (context, item) =>
            Text('${item.studentName} ${item.studentLastname}'),
      ),
      DataColumnDef<StudentModel>(
        key: 'gender',
        label: 'ເພດ',
        flex: 1,
        render: (context, item) => Text(_normalizeGender(item.gender)),
      ),
      DataColumnDef<StudentModel>(
        key: 'studentContact',
        label: 'ເບີໂທ',
        flex: 2,
      ),
      DataColumnDef<StudentModel>(
        key: 'parentsContact',
        label: 'ເບີຜູ້ປົກຄອງ',
        flex: 2,
      ),
      DataColumnDef<StudentModel>(key: 'school', label: 'ໂຮງຮຽນ', flex: 3),
      DataColumnDef<StudentModel>(key: 'districtName', label: 'ເມືອງ', flex: 2),
      DataColumnDef<StudentModel>(key: 'provinceName', label: 'ແຂວງ', flex: 2),
    ];

    final studentState = ref.watch(studentProvider);
    final isLoading = studentState.isLoading && _students.isEmpty;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Skeletonizer(
            enabled: isLoading,
            child: AppDataTable<StudentModel>(
              data: _students,
              columns: columns,
              onAdd: _openAdd,
              onEdit: _openEdit,
              onDelete: _confirmDelete,
              searchKeys: const [
                'studentId',
                'studentName',
                'studentLastname',
                'studentContact',
                'school',
              ],
              addLabel: 'ເພີ່ມນັກຮຽນ',
              isLoading: isLoading,
            ),
          ),
        ),
        if (showAddEditModal) _buildFormModal(),
        if (showDeleteDialog) _buildDeleteDialog(),
      ],
    );
  }

  Widget _buildFormModal() {
    final isLoading = ref.watch(studentProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂຂໍ້ມູນນັກຮຽນ' : 'ເພີ່ມນັກຮຽນໃໝ່',
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
                isLoading: isLoading,
                onPressed: (isLoading || !_isFormValid) ? null : _save,
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidate
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'ຊື່',
                        hint: 'ປ້ອນຊື່ນັກຮຽນ',
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        textInputAction: TextInputAction.next,
                        required: true,
                        validator: (v) => v?.isNotEmpty == true
                            ? null
                            : 'ກະລຸນາປ້ອນຊື່ນັກຮຽນ',
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
                        validator: (v) =>
                            v?.isNotEmpty == true ? null : 'ກະລຸນາປ້ອນນາມສະກຸນ',
                        onChanged: (_) => setState(() {}),
                        onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppDropdown<String>(
                  label: 'ເພດ',
                  value: _selectedGender,
                  items: ['ຊາຍ', 'ຍິງ']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    if (v != null) _selectedGender = v;
                  }),
                  required: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'ເບີໂທນັກຮຽນ',
                        hint: '020XXXXXXXX',
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        required: true,
                        digitOnly: DigitOnly.integer,
                        maxLength: _phoneController.text.startsWith('020')
                            ? 11
                            : 10,
                        onChanged: (_) => setState(() {}),
                        onFieldSubmitted: (_) =>
                            _parentsContactFocusNode.requestFocus(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppTextField(
                        label: 'ເບີໂທຜູ້ປົກຄອງ',
                        hint: '020XXXXXXXX ຫຼື 030XXXXXXX',
                        controller: _parentsContactController,
                        focusNode: _parentsContactFocusNode,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        required: true,
                        digitOnly: DigitOnly.integer,
                        maxLength:
                            _parentsContactController.text.startsWith('020')
                            ? 11
                            : 10,
                        onChanged: (_) => setState(() {}),
                        onFieldSubmitted: (_) =>
                            _schoolFocusNode.requestFocus(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'ໂຮງຮຽນ',
                  hint: 'ປ້ອນຊື່ໂຮງຮຽນ(ຕົວຢ່າງ: ມສ ວຽງຈັນ, ມສ ຈອມເພັດ)',
                  controller: _schoolController,
                  focusNode: _schoolFocusNode,
                  textInputAction: TextInputAction.next,
                  required: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppDropdown<int>(
                        label: 'ແຂວງ',
                        hint: 'ເລືອກແຂວງກ່ອນ',
                        value:
                            _provinces.any(
                              (p) => p.provinceId == _selectedProvinceId,
                            )
                            ? _selectedProvinceId
                            : null,
                        required: true,
                        items: _provinces
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.provinceId,
                                child: Text(p.provinceName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedProvinceId = v;
                            _selectedDistrictId = null;
                          });
                          if (v != null) {
                            ref
                                .read(districtProvider.notifier)
                                .getDistrictsByProvince(v);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppDropdown<int>(
                        label: 'ເມືອງ',
                        hint: _selectedProvinceId == null
                            ? 'ເລືອກແຂວງກ່ອນ'
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    if (selectedItem == null) return const SizedBox.shrink();
    final isLoading = ref.watch(studentProvider).isLoading;
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: AppColors.warning,
              ),
              const SizedBox(height: 16),
              Text(
                'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "${selectedItem!.studentName} ${selectedItem!.studentLastname}"?',
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
