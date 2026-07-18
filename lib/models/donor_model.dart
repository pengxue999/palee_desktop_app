class DonorModel {
  final String donorId;
  final String donorName;
  final String donorLastname;
  final String donorContact;
  final String? section;

  const DonorModel({
    required this.donorId,
    required this.donorName,
    required this.donorLastname,
    required this.donorContact,
    this.section,
  });

  String get fullName => '$donorName $donorLastname';

  factory DonorModel.fromJson(Map<String, dynamic> json) {
    return DonorModel(
      donorId: json['donor_id'] as String? ?? '',
      donorName: json['donor_name'] as String? ?? '',
      donorLastname: json['donor_lastname'] as String? ?? '',
      donorContact: json['donor_contact'] as String? ?? '',
      section: json['section'] as String?,
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'donorId':
        return donorId;
      case 'donorName':
        return donorName;
      case 'donorLastname':
        return donorLastname;
      case 'fullName':
        return fullName;
      case 'donorContact':
        return donorContact;
      case 'section':
        return section;
      default:
        return null;
    }
  }
}

class DonorRequest {
  final String donorName;
  final String donorLastname;
  final String donorContact;
  final String? section;

  const DonorRequest({
    required this.donorName,
    required this.donorLastname,
    required this.donorContact,
    this.section,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'donor_name': donorName,
      'donor_lastname': donorLastname,
      'donor_contact': donorContact,
    };
    if (section != null && section!.isNotEmpty) {
      map['section'] = section;
    }
    return map;
  }
}

class DonorListResponse {
  final String code;
  final String messages;
  final List<DonorModel> data;

  const DonorListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory DonorListResponse.fromJson(Map<String, dynamic> json) {
    return DonorListResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => DonorModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DonorSingleResponse {
  final String code;
  final String messages;
  final DonorModel data;

  const DonorSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory DonorSingleResponse.fromJson(Map<String, dynamic> json) {
    return DonorSingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: DonorModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
