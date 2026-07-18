class DonationCategoryModel {
  final int donationCategoryId;
  final String donationCategoryName;

  const DonationCategoryModel({
    required this.donationCategoryId,
    required this.donationCategoryName,
  });

  factory DonationCategoryModel.fromJson(Map<String, dynamic> json) {
    return DonationCategoryModel(
      donationCategoryId: json['donation_category_id'] as int,
      donationCategoryName: json['donation_category_name'] as String? ?? '',
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'donationCategoryId':
        return donationCategoryId;
      case 'donationCategoryName':
        return donationCategoryName;
      default:
        return null;
    }
  }
}

class DonationCategoryRequest {
  final String donationCategoryName;

  const DonationCategoryRequest({required this.donationCategoryName});

  Map<String, dynamic> toJson() => {
    'donation_category_name': donationCategoryName,
  };
}

class DonationCategoryListResponse {
  final String code;
  final String messages;
  final List<DonationCategoryModel> data;

  const DonationCategoryListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory DonationCategoryListResponse.fromJson(Map<String, dynamic> json) {
    return DonationCategoryListResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => DonationCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DonationCategorySingleResponse {
  final String code;
  final String messages;
  final DonationCategoryModel data;

  const DonationCategorySingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory DonationCategorySingleResponse.fromJson(Map<String, dynamic> json) {
    return DonationCategorySingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: DonationCategoryModel.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }
}
