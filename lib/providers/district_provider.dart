import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/services/district_serivice.dart';
import '../models/district_model.dart';

final districtServiceProvider = Provider<DistrictService>(
  (_) => DistrictService(),
);

class DistrictState {
  final List<DistrictModel> districts;
  final List<DistrictModel> filteredDistricts;
  final DistrictModel? selectedDistrict;
  final bool isLoading;
  final String? error;

  const DistrictState({
    this.districts = const [],
    this.filteredDistricts = const [],
    this.selectedDistrict,
    this.isLoading = false,
    this.error,
  });

  DistrictState copyWith({
    List<DistrictModel>? districts,
    List<DistrictModel>? filteredDistricts,
    DistrictModel? selectedDistrict,
    bool? isLoading,
    String? error,
  }) {
    return DistrictState(
      districts: districts ?? this.districts,
      filteredDistricts: filteredDistricts ?? this.filteredDistricts,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DistrictNotifier extends StateNotifier<DistrictState> {
  final DistrictService _service;

  DistrictNotifier(this._service) : super(const DistrictState());

  Future<void> getDistricts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getDistricts();
      state = state.copyWith(
        districts: response.data,
        filteredDistricts: response.data,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> getDistrictById(int districtId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getDistrictById(districtId);
      state = state.copyWith(selectedDistrict: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> getDistrictsByProvince(int provinceId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getDistrictsByProvince(provinceId);
      state = state.copyWith(
        filteredDistricts: response.data,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void clearDistricts() {
    state = state.copyWith(filteredDistricts: []);
  }

  Future<bool> createDistrict(DistrictRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.createDistrict(request);
      state = state.copyWith(
        districts: [...state.districts, response.data],
        filteredDistricts: [...state.districts, response.data],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateDistrict(int districtId, DistrictRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.updateDistrict(districtId, request);
      final updatedDistricts = state.districts
          .map(
            (district) =>
                district.districtId == districtId ? response.data : district,
          )
          .toList();
      state = state.copyWith(
        districts: updatedDistricts,
        filteredDistricts: updatedDistricts,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteDistrict(int districtId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteDistrict(districtId);
      final remainingDistricts = state.districts
          .where((district) => district.districtId != districtId)
          .toList();
      state = state.copyWith(
        districts: remainingDistricts,
        filteredDistricts: remainingDistricts,
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

final districtProvider = StateNotifierProvider<DistrictNotifier, DistrictState>(
  (ref) => DistrictNotifier(ref.read(districtServiceProvider)),
);
