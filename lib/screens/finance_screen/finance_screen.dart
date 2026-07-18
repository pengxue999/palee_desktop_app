import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:palee_elite_training_center/screens/finance_screen/widgets/tab_content.dart';
import 'package:palee_elite_training_center/widgets/app_button.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../models/income_model.dart';
import '../../models/expense_model.dart';
import '../../models/expense_category_model.dart';
import '../../providers/income_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/expense_category_provider.dart';
import '../../widgets/app_data_table.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_text_field.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  String _activeTab = 'income';
  IncomeModel? _editingIncome;
  ExpenseModel? _editingExpense;
  bool _expenseDataLoaded = false;

  final _formData = <String, dynamic>{};
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    await ref.read(incomeProvider.notifier).loadIncomes();
  }

  Future<void> _loadExpenseData() async {
    if (_expenseDataLoaded) return;
    await Future.wait([
      ref.read(expenseProvider.notifier).loadExpenses(),
      ref.read(expenseCategoryProvider.notifier).getExpenseCategories(),
    ]);
    _expenseDataLoaded = true;
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      ref.read(incomeProvider.notifier).loadIncomes(),
      ref.read(expenseProvider.notifier).loadExpenses(),
      ref.read(expenseCategoryProvider.notifier).getExpenseCategories(),
    ]);
    _expenseDataLoaded = true;
  }

  String _formatAmount(double amount) {
    return FormatUtils.formatKip(amount.toInt());
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return _dateFormat.format(dt);
    } catch (_) {
      return date;
    }
  }

  void _openAddModal() {
    _formData.clear();
    _formData['amount'] = '';
    _editingIncome = null;
    _editingExpense = null;
    _showFormModal();
  }

  void _openEditIncome(IncomeModel income) {
    _editingIncome = income;
    _editingExpense = null;
    _formData['amount'] = income.amount.toStringAsFixed(0);
    _formData['description'] = income.description ?? '';
    _showFormModal();
  }

  void _openEditExpense(ExpenseModel expense) {
    _editingExpense = expense;
    _editingIncome = null;
    _formData['expense_category_id'] = expense.expenseCategoryId;
    _formData['amount'] = expense.amount.toStringAsFixed(0);
    _formData['description'] = expense.description ?? '';
    _showFormModal();
  }

  void _showFormModal() {
    final amountController = TextEditingController(
      text: _formData['amount']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: _formData['description']?.toString() ?? '',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final isIncome = _activeTab == 'income';
            final isEditing = isIncome
                ? _editingIncome != null
                : _editingExpense != null;
            final title = isEditing
                ? (isIncome ? 'ແກ້ໄຂລາຍຮັບ' : 'ແກ້ໄຂລາຍຈ່າຍ')
                : (isIncome ? 'ບັນທຶກລາຍຮັບ' : 'ບັນທຶກລາຍຈ່າຍ');
            final categories = ref
                .watch(expenseCategoryProvider)
                .expenseCategories;

            bool getIsValid() {
              final amountText =
                  _formData['amount']?.toString().replaceAll(',', '') ?? '';
              final amount = double.tryParse(amountText) ?? 0;
              if (amount < 1000) return false;
              if (!isIncome && _formData['expense_category_id'] == null) {
                return false;
              }
              return true;
            }

            return AppDialog(
              title: title,
              onClose: () => Navigator.pop(context),
              size: AppDialogSize.small,
              footer: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    label: 'ຍົກເລີກ',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: isEditing ? 'ຢືນຢັນ' : 'ບັນທຶກ',
                    icon: Icons.save_rounded,
                    onPressed: getIsValid() ? () => _handleSave(context) : null,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isIncome) ...[
                    AppDropdown<int>(
                      label: 'ປະເພດລາຍຈ່າຍ',
                      value: _formData['expense_category_id'] as int?,
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.expenseCategoryId,
                              child: Text(c.expenseCategory),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setStateModal(
                        () => _formData['expense_category_id'] = v,
                      ),
                      hint: 'ເລືອກປະເພດລາຍຈ່າຍ',
                      required: true,
                    ),
                    const SizedBox(height: 16),
                  ],

                  AppTextField(
                    label: 'ຈຳນວນເງິນ',
                    hint: 'ກະລຸນາປ້ອນຈຳນວນເງິນ',
                    controller: amountController,
                    digitOnly: DigitOnly.integer,
                    required: true,
                    fontSize: 22,
                    thousandsSeparator: true,
                    fontWeight: FontWeight.bold,
                    onChanged: (v) {
                      _formData['amount'] = v;
                      setStateModal(() {});
                    },
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    label: 'ລາຍລະອຽດ',
                    hint: 'ກະລຸນາປ້ອນລາຍລະອຽດ(ຖ້າມີ)',
                    controller: descriptionController,
                    maxLines: 3,
                    onChanged: (v) => _formData['description'] = v,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSave(BuildContext dialogContext) async {
    final amountText =
        _formData['amount']?.toString().replaceAll(',', '') ?? '0';
    final amount = double.tryParse(amountText) ?? 0;
    if (amount < 1000) {
      AppToast.error(context, 'ຈຳນວນເງິນຕ້ອງຫຼາຍກວ່າ 1,000 ກີບ');
      return;
    }

    if (_activeTab == 'income') {
      final success = _editingIncome != null
          ? await ref
                .read(incomeProvider.notifier)
                .updateIncome(
                  incomeId: _editingIncome!.incomeId,
                  amount: amount,
                  description: _formData['description']?.toString(),
                )
          : await ref
                .read(incomeProvider.notifier)
                .createManualIncome(
                  amount: amount,
                  description: _formData['description']?.toString(),
                );

      if (success && mounted) {
        AppToast.success(
          context,
          _editingIncome != null ? 'ແກ້ໄຂລາຍຮັບສຳເລັດ' : 'ບັນທຶກລາຍຮັບສຳເລັດ',
        );
        if (dialogContext.mounted) Navigator.pop(dialogContext);
      } else if (mounted) {
        final error = ref.read(incomeProvider).error;
        AppToast.error(context, error ?? 'ເກີດຂໍ້ຜິດພາດ');
      }
    } else {
      final categoryId = _formData['expense_category_id'] as int?;
      if (categoryId == null) {
        AppToast.error(context, 'ກະລຸນາເລືອກປະເພດລາຍຈ່າຍ');
        return;
      }

      final expenseDate = DateTime.now();

      final success = _editingExpense != null
          ? await ref
                .read(expenseProvider.notifier)
                .updateExpense(
                  expenseId: _editingExpense!.expenseId,
                  expenseCategoryId: categoryId,
                  amount: amount,
                  description: _formData['description']?.toString(),
                  expenseDate: expenseDate,
                )
          : await ref
                .read(expenseProvider.notifier)
                .createManualExpense(
                  expenseCategoryId: categoryId,
                  amount: amount,
                  description: _formData['description']?.toString(),
                  expenseDate: expenseDate,
                );

      if (success && mounted) {
        AppToast.success(
          context,
          _editingExpense != null
              ? 'ແກ້ໄຂລາຍຈ່າຍສຳເລັດ'
              : 'ບັນທຶກລາຍຈ່າຍສຳເລັດ',
        );
        if (dialogContext.mounted) Navigator.pop(dialogContext);
      } else if (mounted) {
        final error = ref.read(expenseProvider).error;
        AppToast.error(context, error ?? 'ເກີດຂໍ້ຜິດພາດ');
      }
    }
  }

  Future<void> _handleDeleteIncome(IncomeModel income) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 12),
            const Text('ຢືນຢັນການລຶບ'),
          ],
        ),
        content: Text(
          'ທ່ານຕ້ອງການລຶບລາຍຮັບນີ້ບໍ?\n\n${_formatAmount(income.amount)}\n${income.description ?? ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ຍົກເລີກ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
            ),
            child: const Text('ລຶບ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(incomeProvider.notifier)
          .deleteIncome(income.incomeId);
      if (success && mounted) {
        AppToast.success(context, 'ລຶບລາຍຮັບສຳເລັດ');
      } else if (mounted) {
        final error = ref.read(incomeProvider).error;
        AppToast.error(context, error ?? 'ບໍ່ສາມາດລຶບລາຍຮັບໄດ້');
      }
    }
  }

  Future<void> _handleDeleteExpense(ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 12),
            const Text('ຢືນຢັນການລຶບ'),
          ],
        ),
        content: Text(
          'ທ່ານຕ້ອງການລຶບລາຍຈ່າຍນີ້ບໍ?\n\n${_formatAmount(expense.amount)}\n${expense.description ?? ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ຍົກເລີກ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
            ),
            child: const Text('ລຶບ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(expenseProvider.notifier)
          .deleteExpense(expense.expenseId);
      if (success && mounted) {
        AppToast.success(context, 'ລຶບລາຍຈ່າຍສຳເລັດ');
      } else if (mounted) {
        final error = ref.read(expenseProvider).error;
        AppToast.error(context, error ?? 'ບໍ່ສາມາດລຶບລາຍຈ່າຍໄດ້');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomeState = ref.watch(incomeProvider);
    final expenseState = ref.watch(expenseProvider);
    final expenseCategoryState = ref.watch(expenseCategoryProvider);

    final isLoading = incomeState.isLoading || expenseState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTabSection(
                  isLoading,
                  incomeState.incomes,
                  expenseState.expenses,
                  expenseCategoryState.expenseCategories,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSection(
    bool isLoading,
    List<IncomeModel> incomes,
    List<ExpenseModel> expenses,
    List<ExpenseCategoryModel> categories,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabs(incomes.length, expenses.length),
            const SizedBox(height: 16),
            Text(
              _activeTab == 'income' ? 'ຂໍ້ມູນລາຍຮັບ' : 'ຂໍ້ມູນລາຍຈ່າຍ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _activeTab == 'income'
                    ? AppColors.success
                    : AppColors.destructive,
              ),
            ),

            SizedBox(
              height: constraints.maxHeight - 70 - 36,
              child: _activeTab == 'income'
                  ? _buildIncomeTable(isLoading, incomes)
                  : _buildExpenseTable(isLoading, expenses, categories),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabs(int incomeCount, int expenseCount) {
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _activeTab = 'income'),
          child: TabContent(
            icon: Icons.trending_up_rounded,
            label: 'ລາຍຮັບ',
            isActive: _activeTab == 'income',
            activeColor: AppColors.success,
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() => _activeTab = 'expense');
            _loadExpenseData();
          },
          child: TabContent(
            icon: Icons.trending_down_rounded,
            label: 'ລາຍຈ່າຍ',
            isActive: _activeTab == 'expense',
            activeColor: AppColors.destructive,
          ),
        ),
        Spacer(),
        _buildActionButton(),
      ],
    );
  }

  Widget _buildIncomeTable(bool isLoading, List<IncomeModel> incomes) {
    final columns = [
      DataColumnDef<IncomeModel>(
        key: 'amount',
        label: 'ຈຳນວນເງິນ',
        flex: 2,
        render: (v, row) => Text(
          _formatAmount((v as num).toDouble()),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      ),
      DataColumnDef<IncomeModel>(
        key: 'description',
        label: 'ລາຍລະອຽດ',
        flex: 3,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ),

      DataColumnDef<IncomeModel>(
        key: 'incomeDate',
        label: 'ວັນທີ',
        flex: 2,
        render: (v, row) => Text(
          _formatDate(v.toString()),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ];

    return AppDataTable<IncomeModel>(
      title: '',
      subtitle: 'ທັງໝົດ ${incomes.length} ລາຍການ',
      data: incomes,
      columns: columns,
      onEdit: (income) {
        if (ref
            .read(incomeProvider.notifier)
            .canEditOrDelete(income.incomeId)) {
          _openEditIncome(income);
        } else {
          AppToast.warning(context, 'ລາຍຮັບນີ້ບໍ່ສາມາດແກ້ໄຂໄດ້ (ຈາກລະບົບ)');
        }
      },
      onDelete: (income) {
        if (ref
            .read(incomeProvider.notifier)
            .canEditOrDelete(income.incomeId)) {
          _handleDeleteIncome(income);
        } else {
          AppToast.warning(context, 'ລາຍຮັບນີ້ບໍ່ສາມາດລຶບໄດ້ (ຈາກລະບົບ)');
        }
      },
      isLoading: isLoading,
    );
  }

  Widget _buildExpenseTable(
    bool isLoading,
    List<ExpenseModel> expenses,
    List<ExpenseCategoryModel> categories,
  ) {
    String getCategoryName(int categoryId) {
      final category = categories.firstWhere(
        (c) => c.expenseCategoryId == categoryId,
        orElse: () => const ExpenseCategoryModel(
          expenseCategoryId: 0,
          expenseCategory: '-',
        ),
      );
      return category.expenseCategory;
    }

    final columns = [
      DataColumnDef<ExpenseModel>(
        key: 'amount',
        label: 'ຈຳນວນເງິນ',
        flex: 2,
        render: (v, row) => Text(
          _formatAmount((v as num).toDouble()),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.destructive,
          ),
        ),
      ),
      DataColumnDef<ExpenseModel>(
        key: 'description',
        label: 'ລາຍລະອຽດ',
        flex: 3,
        render: (v, row) => Text(
          v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DataColumnDef<ExpenseModel>(
        key: 'expenseCategoryId',
        label: 'ປະເພດ',
        flex: 2,
        render: (v, row) => Text(
          getCategoryName(v as int),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
      ),
      DataColumnDef<ExpenseModel>(
        key: 'expenseDate',
        label: 'ວັນທີ',
        flex: 2,
        render: (v, row) => Text(
          v is DateTime ? _dateFormat.format(v) : v?.toString() ?? '-',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    ];

    return AppDataTable<ExpenseModel>(
      title: '',
      subtitle: 'ທັງໝົດ ${expenses.length} ລາຍການ',
      data: expenses,
      columns: columns,
      onEdit: (expense) {
        if (ref
            .read(expenseProvider.notifier)
            .canEditOrDelete(expense.expenseId)) {
          _openEditExpense(expense);
        } else {
          AppToast.warning(context, 'ລາຍຈ່າຍນີ້ບໍ່ສາມາດແກ້ໄຂໄດ້ (ຈາກລະບົບ)');
        }
      },
      onDelete: (expense) {
        if (ref
            .read(expenseProvider.notifier)
            .canEditOrDelete(expense.expenseId)) {
          _handleDeleteExpense(expense);
        } else {
          AppToast.warning(context, 'ລາຍຈ່າຍນີ້ບໍ່ສາມາດລຶບໄດ້ (ຈາກລະບົບ)');
        }
      },
      isLoading: isLoading,
    );
  }

  Widget _buildActionButton() {
    return AppButton(
      label: _activeTab == 'income' ? 'ເພີ່ມລາຍຮັບ' : 'ເພີ່ມລາຍຈ່າຍ',
      icon: Icons.add_rounded,
      variant: _activeTab == 'income'
          ? AppButtonVariant.success
          : AppButtonVariant.danger,
      onPressed: _openAddModal,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
