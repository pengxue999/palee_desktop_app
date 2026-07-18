import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/teacher_model.dart';
import '../services/teacher_service.dart';

final teacherServiceProvider =
    Provider<TeacherService>((_) => TeacherService());

class TeacherState {
  final List<TeacherModel> teachers;
  final bool isLoading;
  final String? error;

  const TeacherState({
    this.teachers = const [],
    this.isLoading = false,
    this.error,
  });

  TeacherState copyWith({
    List<TeacherModel>? teachers,
    bool? isLoading,
    String? error,
  }) {
    return TeacherState(
      teachers: teachers ?? this.teachers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TeacherNotifier extends StateNotifier<TeacherState> {
  final TeacherService _service;

  TeacherNotifier(this._service) : super(const TeacherState());

  Future<void> getTeachers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getTeachers();
      state = state.copyWith(teachers: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createTeacher(TeacherRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createTeacher(request);
      await getTeachers();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateTeacher(String teacherId, TeacherRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateTeacher(teacherId, request);
      await getTeachers();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteTeacher(String teacherId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteTeacher(teacherId);
      state = state.copyWith(
        teachers: state.teachers
            .where((t) => t.teacherId != teacherId)
            .toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final teacherProvider =
    StateNotifierProvider<TeacherNotifier, TeacherState>(
  (ref) => TeacherNotifier(ref.read(teacherServiceProvider)),
);
