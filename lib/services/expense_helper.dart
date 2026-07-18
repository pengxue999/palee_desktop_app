import '../models/expense_category_model.dart';
import '../models/expense_model.dart';
import '../services/expense_category_service.dart';
import '../services/expense_service.dart';

class ExpenseHelper {
  static const String salaryCategoryName = 'ຄ່າສອນ';

  final ExpenseCategoryService _categoryService = ExpenseCategoryService();
  final ExpenseService _expenseService = ExpenseService();

  Future<int> getOrCreateSalaryCategory() async {
    try {
      final categoriesResponse = await _categoryService.getExpenseCategories();
      final existingCategory = categoriesResponse.data
          .where((cat) => cat.expenseCategory == salaryCategoryName)
          .firstOrNull;

      if (existingCategory != null) {
        return existingCategory.expenseCategoryId;
      }

      final createRequest = ExpenseCategoryRequest(
        expenseCategory: salaryCategoryName,
      );
      final createResponse = await _categoryService.createExpenseCategory(createRequest);
      return createResponse.data.expenseCategoryId;
    } catch (e) {
      throw Exception('Failed to get or create salary expense category: $e');
    }
  }

  Future<bool> createSalaryExpense({
    required String salaryPaymentId,
    required double amount,
    String? description,
    DateTime? expenseDate,
  }) async {
    try {
      final salaryCategoryId = await getOrCreateSalaryCategory();

      final expenseRequest = ExpenseRequest(
        expenseCategoryId: salaryCategoryId,
        salaryPaymentId: salaryPaymentId,
        amount: amount,
        description: description ?? 'ຈ່າຍເງິນສອນ - $salaryPaymentId',
        expenseDate: expenseDate ?? DateTime.now(),
      );

      await _expenseService.createExpense(expenseRequest);
      return true;
    } catch (e) {
      throw Exception('Failed to create salary expense: $e');
    }
  }
}
