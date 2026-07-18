import '../core/utils/enum_localization.dart';

class TuitionPaymentModel {
  final String tuitionPaymentId;
  final String registrationId;
  final String studentName;
  final String studentLastname;
  final double paidAmount;
  final String paymentMethod;
  final String payDate;

  TuitionPaymentModel({
    required this.tuitionPaymentId,
    required this.registrationId,
    required this.studentName,
    required this.studentLastname,
    required this.paidAmount,
    required this.paymentMethod,
    required this.payDate,
  });

  String get studentFullName => '$studentName $studentLastname';

  factory TuitionPaymentModel.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return TuitionPaymentModel(
      tuitionPaymentId: json['tuition_payment_id'] as String? ?? '',
      registrationId: json['registration_id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? '',
      studentLastname: json['student_lastname'] as String? ?? '',
      paidAmount: parseAmount(json['paid_amount']),
      paymentMethod: localizePaymentMethod(json['payment_method'] as String?),
      payDate: json['pay_date'] as String? ?? '',
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'tuitionPaymentId':
        return tuitionPaymentId;
      case 'registrationId':
        return registrationId;
      case 'studentName':
        return studentFullName;
      case 'paidAmount':
        return paidAmount;
      case 'paymentMethod':
        return paymentMethod;
      case 'payDate':
        return payDate;
      default:
        return null;
    }
  }
}

class TuitionPaymentRequest {
  final String registrationId;
  final double paidAmount;
  final String paymentMethod;
  final String? payDate;

  TuitionPaymentRequest({
    required this.registrationId,
    required this.paidAmount,
    required this.paymentMethod,
    this.payDate,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'registration_id': registrationId,
      'paid_amount': paidAmount,
      'payment_method': apiPaymentMethod(paymentMethod),
    };
    if (payDate != null) json['pay_date'] = payDate;
    return json;
  }
}

class TuitionPaymentListResponse {
  final List<TuitionPaymentModel> data;
  final String message;

  TuitionPaymentListResponse({required this.data, required this.message});

  factory TuitionPaymentListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as List<dynamic>? ?? [];
    return TuitionPaymentListResponse(
      data: rawData
          .map((e) => TuitionPaymentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['messages'] as String? ?? '',
    );
  }
}

class TuitionPaymentSingleResponse {
  final TuitionPaymentModel data;
  final String message;

  TuitionPaymentSingleResponse({required this.data, required this.message});

  factory TuitionPaymentSingleResponse.fromJson(Map<String, dynamic> json) {
    return TuitionPaymentSingleResponse(
      data: TuitionPaymentModel.fromJson(json['data'] as Map<String, dynamic>),
      message: json['messages'] as String? ?? '',
    );
  }
}
