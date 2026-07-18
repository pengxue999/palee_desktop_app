import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/widgets/api_error_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../models/expense_category_model.dart';
import '../../providers/expense_category_provider.dart';
import '../../widgets/app_alerts.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';

class ExpenseTypesScreen extends ConsumerStatefulWidget {
  const ExpenseTypesScreen({super.key});

  @override
  ConsumerState<ExpenseTypesScreen> createState() => _ExpenseTypesScreenState();
}

class _ExpenseTypesScreenState extends ConsumerState<ExpenseTypesScreen> {
  bool showAddEditModal = false;
  bool showDeleteDialog = false;
  ExpenseCategoryModel? selectedItem;
  bool isEditing = false;

  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(expenseCategoryProvider.notifier).getExpenseCategories();
      if (mounted) {
        final error = ref.read(expenseCategoryProvider).error;
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

  void _openEdit(ExpenseCategoryModel item) {
    _nameController.text = item.expenseCategory;
    setState(() {
      selectedItem = item;
      showAddEditModal = true;
      isEditing = true;
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    final request = ExpenseCategoryRequest(
      expenseCategory: _nameController.text.trim(),
    );
    bool success;
    if (isEditing && selectedItem != null) {
      success = await ref
          .read(expenseCategoryProvider.notifier)
          .updateExpenseCategory(selectedItem!.expenseCategoryId, request);
    } else {
      success = await ref
          .read(expenseCategoryProvider.notifier)
          .createExpenseCategory(request);
    }
    if (success && mounted) {
      setState(() {
        showAddEditModal = false;
        _resetForm();
      });
    } else if (mounted) {
      final errorMessage = ref.read(expenseCategoryProvider).error;
      ApiErrorHandler.handle(
        context,
        errorMessage ?? 'ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ',
      );
    }
  }

  void _confirmDelete(ExpenseCategoryModel item) => setState(() {
    selectedItem = item;
    showDeleteDialog = true;
  });

  Future<void> _delete() async {
    if (selectedItem == null) return;
    final success = await ref
        .read(expenseCategoryProvider.notifier)
        .deleteExpenseCategory(selectedItem!.expenseCategoryId);

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
      final errorMessage = ref.read(expenseCategoryProvider).error;
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
    final state = ref.watch(expenseCategoryProvider);
    final isLoading = state.isLoading && state.expenseCategories.isEmpty;

    final columns = [
      DataColumnDef<ExpenseCategoryModel>(
        key: 'expenseCategory',
        label: 'ຊື່ປະເພດ',
        flex: 5,
      ),
    ];

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: AppDataTable<ExpenseCategoryModel>(
                  data: isLoading
                      ? _getMockExpenseCategories()
                      : state.expenseCategories,
                  columns: columns,
                  onAdd: _openAdd,
                  onEdit: _openEdit,
                  onDelete: _confirmDelete,
                  searchKeys: const ['expenseCategory'],
                  addLabel: 'ເພີ່ມປະເພດ',
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

  List<ExpenseCategoryModel> _getMockExpenseCategories() {
    return List.generate(
      5,
      (index) => ExpenseCategoryModel(
        expenseCategoryId: index + 1,
        expenseCategory: 'ປະເພດລາຍຈ່າຍ ${index + 1}',
      ),
    );
  }

  Widget _buildFormModal() {
    final isLoading = ref.watch(expenseCategoryProvider).isLoading;
    return Material(
      color: Colors.black54,
      child: Center(
        child: AppDialog(
          title: isEditing ? 'ແກ້ໄຂປະເພດລາຍຈ່າຍ' : 'ເພີ່ມປະເພດລາຍຈ່າຍ',
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
                onPressed: (isLoading) ? null : _save,
              ),
            ],
          ),
          child: AppTextField(
            label: 'ປະເພດລາຍຈ່າຍ',
            hint: 'ປ້ອນຊື່ປະເພດລາຍຈ່າຍ(ເຊັ່ນ:ຄ່າໄຟຟ້າ,ຄ່ານ້ຳ,ຄ່າສອນ,...)',
            controller: _nameController,
            required: true,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    if (selectedItem == null) return const SizedBox.shrink();
    final isLoading = ref.watch(expenseCategoryProvider).isLoading;
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
                'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລຶບ "${selectedItem!.expenseCategory}"?',
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
