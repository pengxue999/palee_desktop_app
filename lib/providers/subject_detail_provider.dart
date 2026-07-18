import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_detail_model.dart';
import '../services/subject_detail_service.dart';

final subjectDetailServiceProvider =
    Provider<SubjectDetailService>((_) => SubjectDetailService());

class SubjectDetailState {
  final List<SubjectDetailModel> subjectDetails;
  final SubjectDetailModel? selectedSubjectDetail;
  final bool isLoading;
  final String? error;

  const SubjectDetailState({
    this.subjectDetails = const [],
    this.selectedSubjectDetail,
    this.isLoading = false,
    this.error,
  });

  SubjectDetailState copyWith({
    List<SubjectDetailModel>? subjectDetails,
    SubjectDetailModel? selectedSubjectDetail,
    bool? isLoading,
    String? error,
  }) {
    return SubjectDetailState(
      subjectDetails: subjectDetails ?? this.subjectDetails,
      selectedSubjectDetail:
          selectedSubjectDetail ?? this.selectedSubjectDetail,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SubjectDetailNotifier extends StateNotifier<SubjectDetailState> {
  final SubjectDetailService _service;

  SubjectDetailNotifier(this._service) : super(const SubjectDetailState());

  Future<void> getSubjectDetails() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getSubjectDetails();
      state = state.copyWith(
        subjectDetails: response.data,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> getSubjectDetailById(String subjectDetailId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getSubjectDetailById(subjectDetailId);
      state = state.copyWith(
        selectedSubjectDetail: response.data,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createSubjectDetail(SubjectDetailRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.createSubjectDetail(request);
      state = state.copyWith(
        subjectDetails: [...state.subjectDetails, response.data],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateSubjectDetail(
    String subjectDetailId,
    SubjectDetailRequest request,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response =
          await _service.updateSubjectDetail(subjectDetailId, request);
      state = state.copyWith(
        subjectDetails: state.subjectDetails
            .map(
              (sd) => sd.subjectDetailId == subjectDetailId ? response.data : sd,
            )
            .toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteSubjectDetail(String subjectDetailId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteSubjectDetail(subjectDetailId);
      state = state.copyWith(
        subjectDetails: state.subjectDetails
            .where((sd) => sd.subjectDetailId != subjectDetailId)
            .toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final subjectDetailProvider =
    StateNotifierProvider<SubjectDetailNotifier, SubjectDetailState>(
  (ref) => SubjectDetailNotifier(ref.read(subjectDetailServiceProvider)),
);
