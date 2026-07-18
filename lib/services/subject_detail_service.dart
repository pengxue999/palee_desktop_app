import 'package:palee_elite_training_center/core/utils/http_helper.dart';
import '../models/subject_detail_model.dart';

class SubjectDetailService {
  final HttpHelper _http = HttpHelper();

  Future<SubjectDetailListResponse> getSubjectDetails() async {
    final response = await _http.get('/subject-details');
    return SubjectDetailListResponse.fromJson(_http.handleJson(response));
  }

  Future<SubjectDetailSingleResponse> getSubjectDetailById(
    String subjectDetailId,
  ) async {
    final response = await _http.get('/subject-details/$subjectDetailId');
    return SubjectDetailSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<SubjectDetailSingleResponse> createSubjectDetail(
    SubjectDetailRequest request,
  ) async {
    final response = await _http.post(
      '/subject-details',
      body: request.toJson(),
    );
    return SubjectDetailSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<SubjectDetailSingleResponse> updateSubjectDetail(
    String subjectDetailId,
    SubjectDetailRequest request,
  ) async {
    final response = await _http.put(
      '/subject-details/$subjectDetailId',
      body: request.toJson(),
    );
    return SubjectDetailSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteSubjectDetail(String subjectDetailId) async {
    final response = await _http.delete('/subject-details/$subjectDetailId');
    _http.handleJson(response);
  }
}
