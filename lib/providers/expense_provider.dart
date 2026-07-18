import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';

final expenseServiceProvider = Provider<ExpenseService>((_) => ExpenseService());

class ExpenseState {
  final List<ExpenseModel> expenses;
  final bool isLoading;
  final String? error;

  const ExpenseState({
    this.expenses = const [],
    this.isLoading = false,
    this.error,
  });

  ExpenseState copyWith({
    List<ExpenseModel>? expenses,
    bool? isLoading,
    String? error,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  double get totalExpense {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  List<ExpenseModel> get manualExpenses {
    return expenses.where((e) => e.salaryPaymentId == null).toList();
  }

  List<ExpenseModel> get salaryExpenses {
    return expenses.where((e) => e.salaryPaymentId != null).toList();
  }
}

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final ExpenseService _service;

  ExpenseNotifier(this._service) : super(const ExpenseState());

  Future<void> loadExpenses() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getExpenses();
      state = state.copyWith(expenses: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createManualExpense({
    required int expenseCategoryId,
    required double amount,
    String? description,
    DateTime? expenseDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final request = ExpenseRequest(
        expenseCategoryId: expenseCategoryId,
        salaryPaymentId: null,
        amount: amount,
        description: description,
        expenseDate: expenseDate ?? DateTime.now(),
      );
      await _service.createExpense(request);
      await loadExpenses();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> createSalaryExpense({
    required int expenseCategoryId,
    required String salaryPaymentId,
    required double amount,
    String? description,
    DateTime? expenseDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final request = ExpenseRequest(
        expenseCategoryId: expenseCategoryId,
        salaryPaymentId: salaryPaymentId,
        amount: amount,
        description: description,
        expenseDate: expenseDate ?? DateTime.now(),
      );
      await _service.createExpense(request);
      await loadExpenses();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateExpense({
    required int expenseId,
    required int expenseCategoryId,
    required double amount,
    String? description,
    DateTime? expenseDate,
  }) async {
    final expense = state.expenses.firstWhere((e) => e.expenseId == expenseId);
    if (expense.salaryPaymentId != null) {
      state = state.copyWith(
        error: 'ບໍ່ສາມາດແກ້ໄຂລາຍຈ່າຍນີ້ໄດ້ (ເປັນລາຍຈ່າຍເງິນເດືອນຈາກລະບົບ)',
        isLoading: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final request = ExpenseRequest(
        expenseCategoryId: expenseCategoryId,
        salaryPaymentId: null,
        amount: amount,
        description: description,
        expenseDate: expenseDate ?? DateTime.now(),
      );
      await _service.updateExpense(expenseId, request);
      await loadExpenses();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteExpense(int expenseId) async {
    final expense = state.expenses.firstWhere((e) => e.expenseId == expenseId);
    if (expense.salaryPaymentId != null) {
      state = state.copyWith(
        error: 'ບໍ່ສາມາດລຶບລາຍຈ່າຍນີ້ໄດ້ (ເປັນລາຍຈ່າຍເງິນເດືອນຈາກລະບົບ)',
        isLoading: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteExpense(expenseId);
      state = state.copyWith(
        expenses: state.expenses.where((e) => e.expenseId != expenseId).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  bool canEditOrDelete(int expenseId) {
    final expense = state.expenses.firstWhere((e) => e.expenseId == expenseId);
    return expense.salaryPaymentId == null;
  }

  void clearError() => state = state.copyWith(error: null);
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>(
  (ref) => ExpenseNotifier(ref.read(expenseServiceProvider)),
);
