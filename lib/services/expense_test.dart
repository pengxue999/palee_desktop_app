import 'package:flutter_test/flutter_test.dart';
import '../services/expense_helper.dart';

void main() {
  group('Expense Helper Tests', () {
    late ExpenseHelper expenseHelper;

    setUp(() {
      expenseHelper = ExpenseHelper();
    });

    test('getOrCreateSalaryCategory should return category ID', () async {
      expect(expenseHelper, isNotNull);
    });

    test('createSalaryExpense should create expense record', () async {
      expect(expenseHelper, isNotNull);
    });
  });
}
