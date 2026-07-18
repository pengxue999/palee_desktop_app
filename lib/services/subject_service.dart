import 'package:palee_elite_training_center/core/utils/http_helper.dart';
import '../models/subject_model.dart';

class SubjectService {
  final HttpHelper _http = HttpHelper();

  Future<SubjectListResponse> getSubjects() async {
    final response = await _http.get('/subjects');
    return SubjectListResponse.fromJson(_http.handleJson(response));
  }

  Future<SubjectSingleResponse> getSubjectById(String subjectId) async {
    final response = await _http.get('/subjects/$subjectId');
    return SubjectSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<SubjectSingleResponse> createSubject(SubjectRequest request) async {
    final response = await _http.post('/subjects', body: request.toJson());
    return SubjectSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<SubjectSingleResponse> updateSubject(
    String subjectId,
    SubjectRequest request,
  ) async {
    final response = await _http.put(
      '/subjects/$subjectId',
      body: request.toJson(),
    );
    return SubjectSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteSubject(String subjectId) async {
    final response = await _http.delete('/subjects/$subjectId');
    _http.handleJson(response);
  }
}
