class ProvinceModel {
  final int provinceId;
  final String provinceName;

  const ProvinceModel({required this.provinceId, required this.provinceName});

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(
      provinceId: json['province_id'] as int,
      provinceName: json['province_name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'province_id': provinceId,
    'province_name': provinceName,
  };

  dynamic operator [](String key) {
    switch (key) {
      case 'provinceId':
      case 'province_id':
        return provinceId;
      case 'provinceName':
      case 'province_name':
        return provinceName;
      default:
        return null;
    }
  }
}

class ProvinceRequest {
  final String provinceName;

  const ProvinceRequest({required this.provinceName});

  Map<String, dynamic> toJson() => {'province_name': provinceName};
}

class ProvinceResponse {
  final String code;
  final String messages;
  final List<ProvinceModel> data;

  const ProvinceResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory ProvinceResponse.fromJson(Map<String, dynamic> json) {
    return ProvinceResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => ProvinceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProvinceSingleResponse {
  final String code;
  final String messages;
  final ProvinceModel data;

  const ProvinceSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory ProvinceSingleResponse.fromJson(Map<String, dynamic> json) {
    return ProvinceSingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: ProvinceModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
