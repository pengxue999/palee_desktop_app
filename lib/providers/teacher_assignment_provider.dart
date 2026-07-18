import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/teacher_assignment_model.dart';
import '../services/teacher_assignment_service.dart';

final teacherAssignmentServiceProvider = Provider<TeacherAssignmentService>(
  (_) => TeacherAssignmentService(),
);

class TeacherAssignmentState {
  final List<TeacherAssignmentModel> assignments;
  final bool isLoading;
  final String? error;

  const TeacherAssignmentState({
    this.assignments = const [],
    this.isLoading = false,
    this.error,
  });

  TeacherAssignmentState copyWith({
    List<TeacherAssignmentModel>? assignments,
    bool? isLoading,
    String? error,
  }) {
    return TeacherAssignmentState(
      assignments: assignments ?? this.assignments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TeacherAssignmentNotifier extends StateNotifier<TeacherAssignmentState> {
  final TeacherAssignmentService _service;

  TeacherAssignmentNotifier(this._service)
    : super(const TeacherAssignmentState());

  Future<void> getAssignments({bool allYears = true}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getAssignments(allYears: allYears);
      state = state.copyWith(assignments: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createAssignment(TeacherAssignmentRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createAssignment(request);
      await getAssignments();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> createAssignmentsBatch(
    TeacherAssignmentBatchRequest request,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createAssignmentsBatch(request);
      await getAssignments();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateAssignment(
    String assignmentId,
    TeacherAssignmentRequest request,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateAssignment(assignmentId, request);
      await getAssignments();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteAssignment(String assignmentId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteAssignment(assignmentId);
      state = state.copyWith(
        assignments: state.assignments
            .where((a) => a.assignmentId != assignmentId)
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

final teacherAssignmentProvider =
    StateNotifierProvider<TeacherAssignmentNotifier, TeacherAssignmentState>(
      (ref) =>
          TeacherAssignmentNotifier(ref.read(teacherAssignmentServiceProvider)),
    );
