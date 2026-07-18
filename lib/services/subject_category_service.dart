import 'package:palee_elite_training_center/core/utils/http_helper.dart';
import '../models/subject_category_model.dart';

class SubjectCategoryService {
  final HttpHelper _http = HttpHelper();

  Future<SubjectCategoryListResponse> getSubjectCategories() async {
    final response = await _http.get('/subject-categories');
    return SubjectCategoryListResponse.fromJson(_http.handleJson(response));
  }

  Future<SubjectCategorySingleResponse> getSubjectCategoryById(String subjectCategoryId) async {
    final response = await _http.get('/subject-categories/$subjectCategoryId');
    return SubjectCategorySingleResponse.fromJson(_http.handleJson(response));
  }

  Future<SubjectCategorySingleResponse> createSubjectCategory(SubjectCategoryRequest request) async {
    final response = await _http.post('/subject-categories', body: request.toJson());
    return SubjectCategorySingleResponse.fromJson(_http.handleJson(response));
  }

  Future<SubjectCategorySingleResponse> updateSubjectCategory(
    String subjectCategoryId,
    SubjectCategoryRequest request,
  ) async {
    final response = await _http.put(
      '/subject-categories/$subjectCategoryId',
      body: request.toJson(),
    );
    return SubjectCategorySingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteSubjectCategory(String subjectCategoryId) async {
    final response = await _http.delete('/subject-categories/$subjectCategoryId');
    _http.handleJson(response);
  }
}
