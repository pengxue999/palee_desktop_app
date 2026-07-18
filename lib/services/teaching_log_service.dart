import '../core/utils/enum_localization.dart';
import '../core/utils/http_helper.dart';
import '../models/teaching_log_model.dart';

class TeachingLogService {
  final HttpHelper _http = HttpHelper();

  Future<TeachingLogResponse> getAll({
    String? academicYear,
    String? month,
    String? status,
    String? teacherId,
  }) async {
    final params = <String, String>{};
    if (academicYear != null) params['academic_year'] = academicYear;
    if (month != null) params['month'] = month;
    if (status != null) params['status'] = apiTeachingStatus(status);
    if (teacherId != null) params['teacher_id'] = teacherId;
    final query = params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';
    final response = await _http.get('/teaching-logs$query');
    return TeachingLogResponse.fromJson(_http.handleJson(response));
  }

  Future<TeachingLogResponse> getByTeacher(
    String teacherId, {
    String? academicYear,
    String? fromDate,
    String? toDate,
  }) async {
    final params = <String, String>{};
    if (academicYear != null) params['academic_year'] = academicYear;
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    final query = params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';
    final response = await _http.get(
      '/teaching-logs/by-teacher/$teacherId$query',
    );
    return TeachingLogResponse.fromJson(_http.handleJson(response));
  }

  Future<Map<String, dynamic>> getSummary({String? academicYear}) async {
    final query = academicYear != null ? '?academic_year=$academicYear' : '';
    final response = await _http.get('/teaching-logs/summary$query');
    return _http.handleJson(response)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSummaryByTeacher(
    String teacherId, {
    String? academicYear,
  }) async {
    final query = academicYear != null ? '?academic_year=$academicYear' : '';
    final response = await _http.get(
      '/teaching-logs/by-teacher/$teacherId/summary$query',
    );
    return _http.handleJson(response)['data'] as Map<String, dynamic>;
  }

  Future<TeachingLogSingleResponse> createLog(
    TeachingLogRequest request,
  ) async {
    final response = await _http.post('/teaching-logs', body: request.toJson());
    return TeachingLogSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<TeachingLogSingleResponse> updateLog(
    int teachingLogId,
    TeachingLogRequest request,
  ) async {
    final response = await _http.put(
      '/teaching-logs/$teachingLogId',
      body: request.toJson(),
    );
    return TeachingLogSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteLog(int teachingLogId) async {
    final response = await _http.delete('/teaching-logs/$teachingLogId');
    _http.handleJson(response);
  }
}
