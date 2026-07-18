import '../core/utils/enum_localization.dart';

class DiscountModel {
  final String discountId;
  final double discountAmount;
  final String discountDescription;
  final String academicYear;

  const DiscountModel({
    required this.discountId,
    required this.discountAmount,
    required this.discountDescription,
    required this.academicYear,
  });

  factory DiscountModel.fromJson(Map<String, dynamic> json) {
    return DiscountModel(
      discountId: json['discount_id'] as String? ?? '',
      discountAmount:
          double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0,
      discountDescription: localizeDiscountDescription(
        json['discount_description'] as String?,
      ),
      academicYear: json['academic_year']?.toString() ?? '',
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'discountId':
        return discountId;
      case 'discountAmount':
        return discountAmount;
      case 'discountDescription':
        return discountDescription;
      case 'academicYear':
        return academicYear;
      default:
        return null;
    }
  }
}

class DiscountRequest {
  final String academicId;
  final double discountAmount;
  final String discountDescription;

  const DiscountRequest({
    required this.academicId,
    required this.discountAmount,
    required this.discountDescription,
  });

  Map<String, dynamic> toJson() => {
    'academic_id': academicId,
    'discount_amount': discountAmount,
    'discount_description': apiDiscountDescription(discountDescription),
  };
}

class DiscountListResponse {
  final String code;
  final String messages;
  final List<DiscountModel> data;

  const DiscountListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory DiscountListResponse.fromJson(Map<String, dynamic> json) {
    return DiscountListResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => DiscountModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DiscountSingleResponse {
  final String code;
  final String messages;
  final DiscountModel data;

  const DiscountSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory DiscountSingleResponse.fromJson(Map<String, dynamic> json) {
    return DiscountSingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: DiscountModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
