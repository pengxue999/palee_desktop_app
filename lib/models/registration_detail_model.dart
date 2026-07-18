import '../core/utils/enum_localization.dart';

class RegistrationDetailModel {
  final int regisDetailId;
  final String registrationId;
  final String feeId;
  final String scholarship;

  RegistrationDetailModel({
    required this.regisDetailId,
    required this.registrationId,
    required this.feeId,
    required this.scholarship,
  });

  factory RegistrationDetailModel.fromJson(Map<String, dynamic> json) {
    return RegistrationDetailModel(
      regisDetailId: json['regis_detail_id'] as int? ?? 0,
      registrationId: json['registration_id'] as String? ?? '',
      feeId: json['fee_id'] as String? ?? '',
      scholarship: localizeScholarship(json['scholarship'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'regis_detail_id': regisDetailId,
    'registration_id': registrationId,
    'fee_id': feeId,
    'scholarship': apiScholarship(scholarship),
  };
}

class RegistrationDetailCreateRequest {
  final String registrationId;
  final String feeId;
  final String scholarship;

  RegistrationDetailCreateRequest({
    required this.registrationId,
    required this.feeId,
    required this.scholarship,
  });

  Map<String, dynamic> toJson() => {
    'registration_id': registrationId,
    'fee_id': feeId,
    'scholarship': apiScholarship(scholarship),
  };
}

class RegistrationDetailResponse {
  final String code;
  final String messages;
  final RegistrationDetailModel data;

  RegistrationDetailResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory RegistrationDetailResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationDetailResponse(
      code: json['code'] as String? ?? '',
      messages: json['messages'] as String? ?? '',
      data: RegistrationDetailModel.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }
}
