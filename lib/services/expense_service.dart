import '../core/utils/http_helper.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final HttpHelper _http = HttpHelper();

  Future<ExpenseListResponse> getExpenses() async {
    final response = await _http.get('/expenses');
    return ExpenseListResponse.fromJson(_http.handleJson(response));
  }

  Future<ExpenseSingleResponse> getExpenseById(int expenseId) async {
    final response = await _http.get('/expenses/$expenseId');
    return ExpenseSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<ExpenseSingleResponse> createExpense(ExpenseRequest request) async {
    final response = await _http.post(
      '/expenses',
      body: request.toJson(),
    );
    return ExpenseSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<ExpenseSingleResponse> updateExpense(
    int expenseId,
    ExpenseRequest request,
  ) async {
    final response = await _http.put(
      '/expenses/$expenseId',
      body: request.toJson(),
    );
    return ExpenseSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteExpense(int expenseId) async {
    final response = await _http.delete('/expenses/$expenseId');
    _http.handleJson(response);
  }
}
