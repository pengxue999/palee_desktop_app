import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/province_model.dart';
import '../services/province_service.dart';

final provinceServiceProvider = Provider<ProvinceService>(
  (_) => ProvinceService(),
);

class ProvinceState {
  final List<ProvinceModel> provinces;
  final ProvinceModel? selectedProvince;
  final bool isLoading;
  final String? error;

  const ProvinceState({
    this.provinces = const [],
    this.selectedProvince,
    this.isLoading = false,
    this.error,
  });

  ProvinceState copyWith({
    List<ProvinceModel>? provinces,
    ProvinceModel? selectedProvince,
    bool? isLoading,
    String? error,
  }) {
    return ProvinceState(
      provinces: provinces ?? this.provinces,
      selectedProvince: selectedProvince ?? this.selectedProvince,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProvinceNotifier extends StateNotifier<ProvinceState> {
  final ProvinceService _service;

  ProvinceNotifier(this._service) : super(const ProvinceState());

  Future<void> getProvinces() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getProvinces();
      state = state.copyWith(provinces: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> getProvinceById(int provinceId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getProvinceById(provinceId);
      state = state.copyWith(selectedProvince: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createProvince(ProvinceRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.createProvince(request);
      state = state.copyWith(
        provinces: [...state.provinces, response.data],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateProvince(int provinceId, ProvinceRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.updateProvince(provinceId, request);
      state = state.copyWith(
        provinces: state.provinces
            .map(
              (province) =>
                  province.provinceId == provinceId ? response.data : province,
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

  Future<bool> deleteProvince(int provinceId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteProvince(provinceId);
      state = state.copyWith(
        provinces: state.provinces
            .where((province) => province.provinceId != provinceId)
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

final provinceProvider = StateNotifierProvider<ProvinceNotifier, ProvinceState>(
  (ref) => ProvinceNotifier(ref.read(provinceServiceProvider)),
);
