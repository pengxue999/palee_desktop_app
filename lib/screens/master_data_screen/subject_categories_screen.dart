import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/subject_category_model.dart';
import '../../providers/subject_category_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';

class SubjectCategoriesScreen extends ConsumerStatefulWidget {
  const SubjectCategoriesScreen({super.key});

  @override
  ConsumerState<SubjectCategoriesScreen> createState() =>
      _SubjectCategoriesScreenState();
}

class _SubjectCategoriesScreenState
    extends ConsumerState<SubjectCategoriesScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  SubjectCategoryModel? selectedItem;
  bool isEditing = false;

  final _nameController = TextEditingController();

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

  void _openEdit(SubjectCategoryModel item) {
    _nameController.text = item.subjectCategoryName;
    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  void _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ກະລຸນາປ້ອນຊື່ໝວດ'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    final request = SubjectCategoryRequest(
      subjectCategoryName: _nameController.text,
    );

    final notifier = ref.read(subjectCategoryProvider.notifier);
    bool success;

    if (isEditing && selectedItem != null) {
      success = await notifier.updateSubjectCategory(
        selectedItem!.subjectCategoryId,
        request,
      );
    } else {
      success = await notifier.createSubjectCategory(request);
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
      final errorMessage = ref.read(subjectCategoryProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(SubjectCategoryModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  void _delete() async {
    if (selectedItem != null) {
      final notifier = ref.read(subjectCategoryProvider.notifier);
      final success = await notifier.deleteSubjectCategory(
        selectedItem!.subjectCategoryId,
      );

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
      } else {
        final errorMessage = ref.read(subjectCategoryProvider).error;
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(subjectCategoryProvider.notifier).getSubjectCategories();
      if (mounted) {
        final error = ref.read(subjectCategoryProvider).error;
        if (error != null) {
          ApiErrorHandler.handle(context, error);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subjectCategoryProvider);
    final items = state.subjectCategories;
    final isLoading = state.isLoading && items.isEmpty;

    final columns = [
      DataColumnDef<SubjectCategoryModel>(
        key: 'subjectCategoryId',
        label: 'ລະຫັດ',
        flex: 1,
      ),
      DataColumnDef<SubjectCategoryModel>(
        key: 'subjectCategoryName',
        label: 'ໝວດ',
        flex: 3,
      ),
    ];

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: AppDataTable<SubjectCategoryModel>(
            data: isLoading ? _getMockCategories() : items,
            columns: columns,
            onAdd: _openAdd,
            onEdit: _openEdit,
            onDelete: _confirmDelete,
            searchKeys: const ['subjectCategoryName'],
            addLabel: 'ເພີ່ມໝວດ',
            isLoading: isLoading,
          ),
        ),
        if (showAddEditModal) _buildFormModal(),
        if (showDeleteDialog) _buildDeleteDialog(),
      ],
    );
  }

  List<SubjectCategoryModel> _getMockCategories() {
    return List.generate(
      5,
      (index) => SubjectCategoryModel(
        subjectCategoryId: 'CAT00${index + 1}',
        subjectCategoryName: 'ໝວດ ${index + 1}',
      ),
    );
  }

  Widget _buildFormModal() {
    final isLoading = ref.watch(subjectCategoryProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂໝວດວິຊາ' : 'ເພີ່ມໝວດໃໝ່',
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
                icon: Icons.save,
                isLoading: isLoading,
                onPressed: (isLoading || _nameController.text.trim().isEmpty)
                    ? null
                    : _save,
              ),
            ],
          ),
          child: Column(
            children: [
              AppTextField(
                label: 'ຊື່ໝວດວິຊາ',
                hint: 'ສາຍຄິດໄລ່, ພາສາ, ອື່ນໆ',
                controller: _nameController,
                required: true,
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
    final isLoading = ref.watch(subjectCategoryProvider).isLoading;
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
                icon: Icons.delete,
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
                'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "${selectedItem!.subjectCategoryName}"?',
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
