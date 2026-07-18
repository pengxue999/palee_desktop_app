import '../core/utils/http_helper.dart';
import '../models/expense_category_model.dart';

class ExpenseCategoryService {
  final HttpHelper _http = HttpHelper();

  Future<ExpenseCategoryListResponse> getExpenseCategories() async {
    final response = await _http.get('/expense-categories');
    return ExpenseCategoryListResponse.fromJson(_http.handleJson(response));
  }

  Future<ExpenseCategorySingleResponse> getExpenseCategoryById(
    int categoryId,
  ) async {
    final response = await _http.get('/expense-categories/$categoryId');
    return ExpenseCategorySingleResponse.fromJson(_http.handleJson(response));
  }

  Future<ExpenseCategorySingleResponse> createExpenseCategory(
    ExpenseCategoryRequest request,
  ) async {
    final response = await _http.post(
      '/expense-categories',
      body: request.toJson(),
    );
    return ExpenseCategorySingleResponse.fromJson(_http.handleJson(response));
  }

  Future<ExpenseCategorySingleResponse> updateExpenseCategory(
    int categoryId,
    ExpenseCategoryRequest request,
  ) async {
    final response = await _http.put(
      '/expense-categories/$categoryId',
      body: request.toJson(),
    );
    return ExpenseCategorySingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteExpenseCategory(int categoryId) async {
    final response = await _http.delete('/expense-categories/$categoryId');
    _http.handleJson(response);
  }
}
