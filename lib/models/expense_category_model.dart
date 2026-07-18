class ExpenseCategoryModel {
  final int expenseCategoryId;
  final String expenseCategory;

  const ExpenseCategoryModel({
    required this.expenseCategoryId,
    required this.expenseCategory,
  });

  factory ExpenseCategoryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryModel(
      expenseCategoryId: json['expense_category_id'] as int,
      expenseCategory: json['expense_category'] as String? ?? '',
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'expenseCategoryId':
        return expenseCategoryId;
      case 'expenseCategory':
        return expenseCategory;
      default:
        return null;
    }
  }
}

class ExpenseCategoryRequest {
  final String expenseCategory;

  const ExpenseCategoryRequest({required this.expenseCategory});

  Map<String, dynamic> toJson() => {'expense_category': expenseCategory};
}

class ExpenseCategoryListResponse {
  final String code;
  final String messages;
  final List<ExpenseCategoryModel> data;

  const ExpenseCategoryListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory ExpenseCategoryListResponse.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryListResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map(
              (e) => ExpenseCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExpenseCategorySingleResponse {
  final String code;
  final String messages;
  final ExpenseCategoryModel data;

  const ExpenseCategorySingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory ExpenseCategorySingleResponse.fromJson(Map<String, dynamic> json) {
    return ExpenseCategorySingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: ExpenseCategoryModel.fromJson(
          json['data'] as Map<String, dynamic>),
    );
  }
}
