class SubjectDetailModel {
  final String subjectDetailId;
  final String subjectId;
  final String levelId;
  final String subjectName;
  final String levelName;

  const SubjectDetailModel({
    required this.subjectDetailId,
    required this.subjectId,
    required this.levelId,
    required this.subjectName,
    required this.levelName,
  });

  String get label => '$subjectName - $levelName';

  factory SubjectDetailModel.fromJson(Map<String, dynamic> json) {
    return SubjectDetailModel(
      subjectDetailId: json['subject_detail_id'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? '',
      levelId: json['level_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      levelName: json['level_name'] as String? ?? '',
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'subjectDetailId':
        return subjectDetailId;
      case 'subjectId':
        return subjectId;
      case 'levelId':
        return levelId;
      case 'subjectName':
        return subjectName;
      case 'levelName':
        return levelName;
      case 'label':
        return label;
      default:
        return null;
    }
  }
}

class SubjectDetailRequest {
  final String subjectId;
  final String levelId;

  const SubjectDetailRequest({
    required this.subjectId,
    required this.levelId,
  });

  Map<String, dynamic> toJson() => {
        'subject_id': subjectId,
        'level_id': levelId,
      };
}

class SubjectDetailListResponse {
  final String code;
  final String messages;
  final List<SubjectDetailModel> data;

  const SubjectDetailListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory SubjectDetailListResponse.fromJson(Map<String, dynamic> json) {
    return SubjectDetailListResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => SubjectDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubjectDetailSingleResponse {
  final String code;
  final String messages;
  final SubjectDetailModel data;

  const SubjectDetailSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory SubjectDetailSingleResponse.fromJson(Map<String, dynamic> json) {
    return SubjectDetailSingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: SubjectDetailModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
