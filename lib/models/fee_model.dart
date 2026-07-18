class FeeModel {
  final String feeId;
  final String subjectName;
  final String levelName;
  final String subjectCategory;
  final String academicYear;
  final double fee;

  const FeeModel({
    required this.feeId,
    required this.subjectName,
    required this.levelName,
    required this.subjectCategory,
    required this.academicYear,
    required this.fee,
  });

  factory FeeModel.fromJson(Map<String, dynamic> json) {
    return FeeModel(
      feeId: json['fee_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      levelName: json['level_name'] as String? ?? '',
      subjectCategory: json['subject_category'] as String? ?? '',
      academicYear: json['academic_year'] as String? ?? '',
      fee: double.tryParse(json['fee']?.toString() ?? '0') ?? 0,
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'feeId':
        return feeId;
      case 'subjectName':
        return subjectName;
      case 'levelName':
        return levelName;
      case 'subjectCategory':
        return subjectCategory;
      case 'academicYear':
        return academicYear;
      case 'fee':
        return fee;
      default:
        return null;
    }
  }
}

class FeeRequest {
  final String subjectDetailId;
  final String academicId;
  final double fee;

  const FeeRequest({
    required this.subjectDetailId,
    required this.academicId,
    required this.fee,
  });

  Map<String, dynamic> toJson() => {
    'subject_detail_id': subjectDetailId,
    'academic_id': academicId,
    'fee': fee,
  };
}

class FeeListResponse {
  final String code;
  final String messages;
  final List<FeeModel> data;

  const FeeListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory FeeListResponse.fromJson(Map<String, dynamic> json) {
    return FeeListResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => FeeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FeeSingleResponse {
  final String code;
  final String messages;
  final FeeModel data;

  const FeeSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory FeeSingleResponse.fromJson(Map<String, dynamic> json) {
    return FeeSingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: FeeModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
