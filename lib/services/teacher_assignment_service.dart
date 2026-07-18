import '../core/utils/http_helper.dart';
import '../models/teacher_assignment_model.dart';

class TeacherAssignmentService {
  final HttpHelper _http = HttpHelper();

  /// ດຶງລາຍການມອບໝາຍອາຈານທັງໝົດ.
  /// - [allYears] = true ດຶງທຸກສົກຮຽນ (ບໍ່ filter).
  /// - ບໍ່ລະບຸ: backend ຈະສົ່ງສະເພາະສົກຮຽນທີ່ ACTIVE ມາໃຫ້.
  Future<TeacherAssignmentResponse> getAssignments({
    String? academicId,
    bool allYears = false,
  }) async {
    final query = <String, String>{
      if (academicId != null) 'academic_id': academicId,
      if (allYears) 'all_years': 'true',
    };
    final endpoint = query.isEmpty
        ? '/teacher-assignments'
        : '/teacher-assignments?${Uri(queryParameters: query).query}';
    final response = await _http.get(endpoint);
    return TeacherAssignmentResponse.fromJson(_http.handleJson(response));
  }

  Future<TeacherAssignmentResponse> getAssignmentsByTeacher(
    String teacherId, {
    String? academicId,
    bool allYears = false,
  }) async {
    final query = <String, String>{
      if (academicId != null) 'academic_id': academicId,
      if (allYears) 'all_years': 'true',
    };
    final endpoint = query.isEmpty
        ? '/teacher-assignments/by-teacher/$teacherId'
        : '/teacher-assignments/by-teacher/$teacherId?${Uri(queryParameters: query).query}';
    final response = await _http.get(endpoint);
    return TeacherAssignmentResponse.fromJson(_http.handleJson(response));
  }

  Future<TeacherAssignmentSingleResponse> createAssignment(
    TeacherAssignmentRequest request,
  ) async {
    final response = await _http.post(
      '/teacher-assignments',
      body: request.toJson(),
    );
    return TeacherAssignmentSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<TeacherAssignmentResponse> createAssignmentsBatch(
    TeacherAssignmentBatchRequest request,
  ) async {
    final response = await _http.post(
      '/teacher-assignments/batch',
      body: request.toJson(),
    );
    return TeacherAssignmentResponse.fromJson(_http.handleJson(response));
  }

  Future<TeacherAssignmentSingleResponse> updateAssignment(
    String assignmentId,
    TeacherAssignmentRequest request,
  ) async {
    final response = await _http.put(
      '/teacher-assignments/$assignmentId',
      body: request.toJson(),
    );
    return TeacherAssignmentSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteAssignment(String assignmentId) async {
    final response = await _http.delete('/teacher-assignments/$assignmentId');
    _http.handleJson(response);
  }
}
