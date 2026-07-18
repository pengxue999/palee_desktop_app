class IncomeModel {
  final int incomeId;
  final String? tuitionPaymentId;
  final int? donationId;
  final double amount;
  final String? description;
  final String incomeDate;

  IncomeModel({
    required this.incomeId,
    this.tuitionPaymentId,
    this.donationId,
    required this.amount,
    this.description,
    required this.incomeDate,
  });

  factory IncomeModel.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return IncomeModel(
      incomeId: json['income_id'] as int,
      tuitionPaymentId: json['tuition_payment_id'] as String?,
      donationId: json['donation_id'] as int?,
      amount: parseAmount(json['amount']),
      description: json['description'] as String?,
      incomeDate: json['income_date'] as String? ?? '',
    );
  }

  dynamic operator[](String key) {
    switch (key) {
      case 'incomeId':
        return incomeId;
      case 'tuitionPaymentId':
        return tuitionPaymentId;
      case 'donationId':
        return donationId;
      case 'amount':
        return amount;
      case 'description':
        return description;
      case 'incomeDate':
        return incomeDate;
      default:
        return null;
    }
  }
}

class IncomeRequest {
  final String? tuitionPaymentId;
  final int? donationId;
  final double amount;
  final String? description;

  IncomeRequest({
    this.tuitionPaymentId,
    this.donationId,
    required this.amount,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      if (tuitionPaymentId != null) 'tuition_payment_id': tuitionPaymentId,
      if (donationId != null) 'donation_id': donationId,
      'amount': amount,
      if (description != null) 'description': description,
    };
  }
}

class IncomeUpdateRequest {
  final String? tuitionPaymentId;
  final int? donationId;
  final double? amount;
  final String? description;

  IncomeUpdateRequest({
    this.tuitionPaymentId,
    this.donationId,
    this.amount,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      if (tuitionPaymentId != null) 'tuition_payment_id': tuitionPaymentId,
      if (donationId != null) 'donation_id': donationId,
      if (amount != null) 'amount': amount,
      if (description != null) 'description': description,
    };
  }
}
