class DonationModel {
  final int donationId;
  final String? donorId;
  final String donorName;
  final String? donorLastname;
  final int? donationCategoryId;
  final String donationCategory;
  final String donationName;
  final double amount;
  final String unit;
  final String donationDate;
  final String? createdAt;

  DonationModel({
    required this.donationId,
    this.donorId,
    required this.donorName,
    this.donorLastname,
    this.donationCategoryId,
    required this.donationCategory,
    required this.donationName,
    required this.amount,
    required this.unit,
    required this.donationDate,
    this.createdAt,
  });

  String get donorFullName => '$donorName ${donorLastname ?? ''}';

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return DonationModel(
      donationId: json['donation_id'] as int,
      donorId: json['donor_id'] as String?,
      donorName: json['donor_name'] as String? ?? '',
      donorLastname: json['donor_lastname'] as String?,
      donationCategoryId: json['donation_category_id'] as int?,
      donationCategory:
          json['donation_category_name'] as String? ??
          json['donation_category'] as String? ??
          '',
      donationName: json['donation_name'] as String? ?? '',
      amount: parseAmount(json['amount']),
      unit: json['unit'] as String? ?? json['unit_name'] as String? ?? '',
      donationDate: json['donation_date'] as String? ?? '',
      createdAt: json['created_at'] as String?,
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'donationId':
        return donationId;
      case 'donorId':
        return donorId;
      case 'donorName':
        return donorName;
      case 'donorLastname':
        return donorLastname;
      case 'donorFullName':
        return donorFullName;
      case 'donationCategoryId':
        return donationCategoryId;
      case 'donationCategory':
        return donationCategory;
      case 'donationName':
        return donationName;
      case 'amount':
        return amount;
      case 'unit':
        return unit;
      case 'donationDate':
        return donationDate;
      case 'createdAt':
        return createdAt;
      default:
        return null;
    }
  }
}

class DonationRequest {
  final String donorId;
  final int donationCategoryId;
  final String donationName;
  final double amount;
  final String unit;
  final String donationDate;

  DonationRequest({
    required this.donorId,
    required this.donationCategoryId,
    required this.donationName,
    required this.amount,
    required this.unit,
    required this.donationDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'donor_id': donorId,
      'donation_category_id': donationCategoryId,
      'donation_name': donationName,
      'amount': amount,
      'unit': unit,
      'donation_date': donationDate,
    };
  }
}

class DonationUpdateRequest {
  final String? donorId;
  final int? donationCategoryId;
  final String? donationName;
  final double? amount;
  final String? unit;
  final String? donationDate;

  DonationUpdateRequest({
    this.donorId,
    this.donationCategoryId,
    this.donationName,
    this.amount,
    this.unit,
    this.donationDate,
  });

  Map<String, dynamic> toJson() {
    return {
      if (donorId != null) 'donor_id': donorId,
      if (donationCategoryId != null)
        'donation_category_id': donationCategoryId,
      if (donationName != null) 'donation_name': donationName,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (donationDate != null) 'donation_date': donationDate,
    };
  }
}

class DonationListResponse {
  final List<DonationModel> data;
  final String message;

  DonationListResponse({required this.data, required this.message});

  factory DonationListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as List<dynamic>? ?? [];
    return DonationListResponse(
      data: rawData
          .map((e) => DonationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['messages'] as String? ?? '',
    );
  }
}

class DonationSingleResponse {
  final DonationModel data;
  final String message;

  DonationSingleResponse({required this.data, required this.message});

  factory DonationSingleResponse.fromJson(Map<String, dynamic> json) {
    return DonationSingleResponse(
      data: DonationModel.fromJson(json['data'] as Map<String, dynamic>),
      message: json['messages'] as String? ?? '',
    );
  }
}
