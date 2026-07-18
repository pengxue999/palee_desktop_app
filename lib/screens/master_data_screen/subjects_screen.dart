import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/subject_model.dart';
import '../../models/subject_category_model.dart';
import '../../providers/subject_provider.dart';
import '../../providers/subject_category_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_button.dart';

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  SubjectModel? selectedItem;
  bool isEditing = false;

  final _nameController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(subjectProvider.notifier).getSubjects();
      ref.read(subjectCategoryProvider.notifier).getSubjectCategories();
      if (mounted) {
        final error = ref.read(subjectProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  void _resetForm() {
    _nameController.clear();
    _selectedCategoryId = null;
    _selectedCategoryName = null;
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

  void _openEdit(SubjectModel item) {
    _nameController.text = item.subjectName;
    _selectedCategoryId = item.subjectCategoryId;
    _selectedCategoryName = item.subjectCategoryName;
    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  void _save() async {
    if (_nameController.text.trim().isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ກະລຸນາປ້ອນຊື່ວິຊາ ແລະ ເລືອກໝວດວິຊາ'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    final request = SubjectRequest(
      subjectName: _nameController.text.trim(),
      subjectCategoryId: _selectedCategoryId!,
    );

    final notifier = ref.read(subjectProvider.notifier);
    bool success;

    if (isEditing && selectedItem != null) {
      success = await notifier.updateSubject(selectedItem!.subjectId, request);
    } else {
      success = await notifier.createSubject(request);
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
      final errorMessage = ref.read(subjectProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(SubjectModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  void _delete() async {
    if (selectedItem != null) {
      final notifier = ref.read(subjectProvider.notifier);
      final success = await notifier.deleteSubject(selectedItem!.subjectId);

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
        final errorMessage = ref.read(subjectProvider).error;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectState = ref.watch(subjectProvider);
    final categoryState = ref.watch(subjectCategoryProvider);
    final items = subjectState.subjects;
    final categories = categoryState.subjectCategories;
    final isLoading = subjectState.isLoading && items.isEmpty;

    final columns = [
      DataColumnDef<SubjectModel>(
        key: 'subjectId',
        label: 'ລະຫັດວິຊາ',
        flex: 2,
      ),
      DataColumnDef<SubjectModel>(
        key: 'subjectName',
        label: 'ຊື່ວິຊາ',
        flex: 3,
      ),
      DataColumnDef<SubjectModel>(
        key: 'subjectCategoryName',
        label: 'ໝວດວິຊາ',
        flex: 2,
        render: (v, row) => Text(
          v.toString(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    ];

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppDataTable<SubjectModel>(
                  data: items,
                  columns: columns,
                  onAdd: _openAdd,
                  onEdit: _openEdit,
                  onDelete: _confirmDelete,
                  searchKeys: const [
                    'subjectId',
                    'subjectName',
                    'subjectCategoryName',
                  ],
                  addLabel: 'ເພີ່ມວິຊາ',
                  isLoading: isLoading,
                ),
              ),
            ),
          ],
        ),
        if (showAddEditModal) _buildFormModal(categories),
        if (showDeleteDialog) _buildDeleteDialog(),
      ],
    );
  }

  bool get _isFormValid {
    return _nameController.text.isNotEmpty && _selectedCategoryId != null;
  }

  Widget _buildFormModal(List<SubjectCategoryModel> categories) {
    final isLoading = ref.watch(subjectProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂວິຊາ' : 'ເພີ່ມວິຊາໃໝ່',
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
              AppTextField(
                label: 'ຊື່ວິຊາ',
                hint: 'ປ້ອນຊື່ວິຊາ',
                controller: _nameController,
                required: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              AppDropdown<String>(
                label: 'ໝວດວິຊາ',
                hint: 'ເລືອກໝວດວິຊາ',
                value: _selectedCategoryId,
                required: true,
                items: [
                  ...categories.map(
                    (c) => DropdownMenuItem(
                      value: c.subjectCategoryId,
                      child: Text(c.subjectCategoryName),
                    ),
                  ),
                  if (_selectedCategoryId != null &&
                      !categories.any(
                        (c) => c.subjectCategoryId == _selectedCategoryId,
                      ))
                    DropdownMenuItem(
                      value: _selectedCategoryId,
                      child: Text(_selectedCategoryName ?? ''),
                    ),
                ].toList(),
                onChanged: (v) {
                  final selected = categories
                      .where((c) => c.subjectCategoryId == v)
                      .firstOrNull;
                  setState(() {
                    _selectedCategoryId = v;
                    _selectedCategoryName = selected?.subjectCategoryName;
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
    if (selectedItem == null) return const SizedBox.shrink();
    final isLoading = ref.watch(subjectProvider).isLoading;
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
                'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "${selectedItem!.subjectName}"?',
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
