import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/http_helper.dart';
import '../models/student_model.dart';
import '../services/student_service.dart';

final studentServiceProvider =
    Provider<StudentService>((_) => StudentService());

class StudentState {
  final List<StudentModel> students;
  final StudentModel? selectedStudent;
  final bool isLoading;
  final String? error;

  const StudentState({
    this.students = const [],
    this.selectedStudent,
    this.isLoading = false,
    this.error,
  });

  StudentState copyWith({
    List<StudentModel>? students,
    StudentModel? selectedStudent,
    bool? isLoading,
    String? error,
  }) {
    return StudentState(
      students: students ?? this.students,
      selectedStudent: selectedStudent ?? this.selectedStudent,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class StudentNotifier extends StateNotifier<StudentState> {
  final StudentService _service;

  StudentNotifier(this._service) : super(const StudentState());

  Future<void> getStudents() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getStudents();
      state = state.copyWith(students: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> getStudentById(String studentId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getStudentById(studentId);
      state = state.copyWith(selectedStudent: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createStudent(StudentRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.createStudent(request);
      state = state.copyWith(
        students: [...state.students, response.data],
        selectedStudent: response.data,
        isLoading: false,
      );
      return true;
    } on ValidationException catch (e) {
      final errorDetails = e.errors?.map((err) => err['msg'] as String? ?? '').join('\n');
      state = state.copyWith(error: errorDetails ?? e.message, isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateStudent(String studentId, StudentRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.updateStudent(studentId, request);
      state = state.copyWith(
        students: state.students
            .map((s) => s.studentId == studentId ? response.data : s)
            .toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteStudent(String studentId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteStudent(studentId);
      state = state.copyWith(
        students: state.students
            .where((s) => s.studentId != studentId)
            .toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }
}

final studentProvider =
    StateNotifierProvider<StudentNotifier, StudentState>(
  (ref) => StudentNotifier(ref.read(studentServiceProvider)),
);
