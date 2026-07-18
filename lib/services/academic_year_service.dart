import 'package:palee_elite_training_center/core/utils/http_helper.dart';
import '../models/academic_year_model.dart';

class AcademicYearService {
  final HttpHelper _http = HttpHelper();

  Future<AcademicYearListResponse> getAcademicYears() async {
    final response = await _http.get('/academic-years');
    return AcademicYearListResponse.fromJson(_http.handleJson(response));
  }

  Future<AcademicYearSingleResponse> getAcademicYearById(String academicId) async {
    final response = await _http.get('/academic-years/$academicId');
    return AcademicYearSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<AcademicYearSingleResponse> createAcademicYear(AcademicYearRequest request) async {
    final response = await _http.post('/academic-years', body: request.toJson());
    return AcademicYearSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<AcademicYearSingleResponse> updateAcademicYear(
    String academicId,
    AcademicYearRequest request,
  ) async {
    final response = await _http.put(
      '/academic-years/$academicId',
      body: request.toJson(),
    );
    return AcademicYearSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteAcademicYear(String academicId) async {
    final response = await _http.delete('/academic-years/$academicId');
    _http.handleJson(response);
  }
}
