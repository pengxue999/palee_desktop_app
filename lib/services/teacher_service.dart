import '../core/utils/http_helper.dart';
import '../models/teacher_model.dart';

class TeacherService {
  final HttpHelper _http = HttpHelper();

  Future<TeacherResponse> getTeachers() async {
    final response = await _http.get('/teachers');
    return TeacherResponse.fromJson(_http.handleJson(response));
  }

  Future<TeacherSingleResponse> createTeacher(TeacherRequest request) async {
    final response = await _http.post('/teachers', body: request.toJson());
    return TeacherSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<TeacherSingleResponse> updateTeacher(
    String teacherId,
    TeacherRequest request,
  ) async {
    final response = await _http.put(
      '/teachers/$teacherId',
      body: request.toJson(),
    );
    return TeacherSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteTeacher(String teacherId) async {
    final response = await _http.delete('/teachers/$teacherId');
    _http.handleJson(response);
  }
}
