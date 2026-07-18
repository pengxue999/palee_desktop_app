import 'package:palee_elite_training_center/core/utils/http_helper.dart';
import '../models/student_model.dart';

class StudentService {
  final HttpHelper _http = HttpHelper();

  Future<StudentListResponse> getStudents() async {
    final response = await _http.get('/students');
    return StudentListResponse.fromJson(_http.handleJson(response));
  }

  Future<StudentSingleResponse> getStudentById(String studentId) async {
    final response = await _http.get('/students/$studentId');
    return StudentSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<StudentSingleResponse> createStudent(StudentRequest request) async {
    final response = await _http.post('/students', body: request.toJson());
    return StudentSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<StudentSingleResponse> updateStudent(
    String studentId,
    StudentRequest request,
  ) async {
    final response = await _http.put(
      '/students/$studentId',
      body: request.toJson(),
    );
    return StudentSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteStudent(String studentId) async {
    final response = await _http.delete('/students/$studentId');
    _http.handleJson(response);
  }
}
