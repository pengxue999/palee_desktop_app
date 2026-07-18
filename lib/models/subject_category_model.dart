class SubjectCategoryModel {
  final String subjectCategoryId;
  final String subjectCategoryName;

  const SubjectCategoryModel({
    required this.subjectCategoryId,
    required this.subjectCategoryName,
  });

  factory SubjectCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubjectCategoryModel(
      subjectCategoryId: json['subject_category_id'] as String? ?? '',
      subjectCategoryName: json['subject_category_name'] as String? ?? '',
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'id':
      case 'subjectCategoryId':
        return subjectCategoryId;
      case 'name':
      case 'subjectCategoryName':
        return subjectCategoryName;
      default:
        return null;
    }
  }
}

class SubjectCategoryRequest {
  final String subjectCategoryName;

  const SubjectCategoryRequest({
    required this.subjectCategoryName,
  });

  Map<String, dynamic> toJson() => {
        'subject_category_name': subjectCategoryName,
      };
}

class SubjectCategoryListResponse {
  final String code;
  final String messages;
  final List<SubjectCategoryModel> data;

  const SubjectCategoryListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory SubjectCategoryListResponse.fromJson(Map<String, dynamic> json) {
    return SubjectCategoryListResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => SubjectCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubjectCategorySingleResponse {
  final String code;
  final String messages;
  final SubjectCategoryModel data;

  const SubjectCategorySingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory SubjectCategorySingleResponse.fromJson(Map<String, dynamic> json) {
    return SubjectCategorySingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: SubjectCategoryModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
