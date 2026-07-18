class ExpenseModel {
  final int expenseId;
  final int expenseCategoryId;
  final String? salaryPaymentId;
  final double amount;
  final String? description;
  final DateTime expenseDate;

  const ExpenseModel({
    required this.expenseId,
    required this.expenseCategoryId,
    this.salaryPaymentId,
    required this.amount,
    this.description,
    required this.expenseDate,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          try {
            final parts = value.split('-');
            if (parts.length == 3) {
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              return DateTime(year, month, day);
            }
          } catch (_) {}
        }
      }
      return DateTime.now();
    }

    return ExpenseModel(
      expenseId: json['expense_id'] as int,
      expenseCategoryId: json['expense_category_id'] as int,
      salaryPaymentId: json['salary_payment_id'] as String?,
      amount: parseAmount(json['amount']),
      description: json['description'] as String?,
      expenseDate: parseDate(json['expense_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expense_id': expenseId,
      'expense_category_id': expenseCategoryId,
      'salary_payment_id': salaryPaymentId,
      'amount': amount,
      'description': description,
      'expense_date': expenseDate.toIso8601String(),
    };
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'expenseId':
        return expenseId;
      case 'expenseCategoryId':
        return expenseCategoryId;
      case 'salaryPaymentId':
        return salaryPaymentId;
      case 'amount':
        return amount;
      case 'description':
        return description;
      case 'expenseDate':
        return expenseDate;
      default:
        return null;
    }
  }
}

class ExpenseRequest {
  final int expenseCategoryId;
  final String? salaryPaymentId;
  final double amount;
  final String? description;
  final DateTime expenseDate;

  const ExpenseRequest({
    required this.expenseCategoryId,
    this.salaryPaymentId,
    required this.amount,
    this.description,
    required this.expenseDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'expense_category_id': expenseCategoryId,
      'salary_payment_id': salaryPaymentId,
      'amount': amount,
      'description': description,
      'expense_date': expenseDate.toIso8601String(),
    };
  }
}

class ExpenseListResponse {
  final String code;
  final String messages;
  final List<ExpenseModel> data;

  const ExpenseListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory ExpenseListResponse.fromJson(Map<String, dynamic> json) {
    return ExpenseListResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExpenseSingleResponse {
  final String code;
  final String messages;
  final ExpenseModel data;

  const ExpenseSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory ExpenseSingleResponse.fromJson(Map<String, dynamic> json) {
    return ExpenseSingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: ExpenseModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
