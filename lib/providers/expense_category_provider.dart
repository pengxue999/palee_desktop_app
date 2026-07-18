import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_category_model.dart';
import '../services/expense_category_service.dart';

final expenseCategoryServiceProvider =
    Provider<ExpenseCategoryService>((_) => ExpenseCategoryService());

class ExpenseCategoryState {
  final List<ExpenseCategoryModel> expenseCategories;
  final bool isLoading;
  final String? error;

  const ExpenseCategoryState({
    this.expenseCategories = const [],
    this.isLoading = false,
    this.error,
  });

  ExpenseCategoryState copyWith({
    List<ExpenseCategoryModel>? expenseCategories,
    bool? isLoading,
    String? error,
  }) {
    return ExpenseCategoryState(
      expenseCategories: expenseCategories ?? this.expenseCategories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ExpenseCategoryNotifier extends StateNotifier<ExpenseCategoryState> {
  final ExpenseCategoryService _service;

  ExpenseCategoryNotifier(this._service)
      : super(const ExpenseCategoryState());

  Future<void> getExpenseCategories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getExpenseCategories();
      state = state.copyWith(
          expenseCategories: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createExpenseCategory(ExpenseCategoryRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createExpenseCategory(request);
      await getExpenseCategories();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateExpenseCategory(
      int categoryId, ExpenseCategoryRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateExpenseCategory(categoryId, request);
      await getExpenseCategories();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteExpenseCategory(int categoryId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteExpenseCategory(categoryId);
      state = state.copyWith(
        expenseCategories: state.expenseCategories
            .where((c) => c.expenseCategoryId != categoryId)
            .toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final expenseCategoryProvider =
    StateNotifierProvider<ExpenseCategoryNotifier, ExpenseCategoryState>(
  (ref) =>
      ExpenseCategoryNotifier(ref.read(expenseCategoryServiceProvider)),
);
