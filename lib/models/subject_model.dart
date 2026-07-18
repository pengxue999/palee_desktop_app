
class SubjectModel {
  final String subjectId;
  final String subjectName;
  final String subjectCategoryId;
  final String? subjectCategoryName;

  const SubjectModel({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCategoryId,
    this.subjectCategoryName,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      subjectCategoryId: json['subject_category_id'] as String? ?? '',
      subjectCategoryName: json['subject_category_name'] as String?,
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'id':
      case 'subjectId':
        return subjectId;
      case 'name':
      case 'subjectName':
        return subjectName;
      case 'subjectCategoryId':
        return subjectCategoryId;
      case 'subjectCategoryName':
        return subjectCategoryName;
      default:
        return null;
    }
  }
}

class SubjectRequest {
  final String subjectName;
  final String subjectCategoryId;

  const SubjectRequest({
    required this.subjectName,
    required this.subjectCategoryId,
  });

  Map<String, dynamic> toJson() => {
        'subject_name': subjectName,
        'subject_category_id': subjectCategoryId,
      };
}

class SubjectListResponse {
  final String code;
  final String messages;
  final List<SubjectModel> data;

  const SubjectListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory SubjectListResponse.fromJson(Map<String, dynamic> json) {
    return SubjectListResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => SubjectModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubjectSingleResponse {
  final String code;
  final String messages;
  final SubjectModel data;

  const SubjectSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory SubjectSingleResponse.fromJson(Map<String, dynamic> json) {
    return SubjectSingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: SubjectModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
