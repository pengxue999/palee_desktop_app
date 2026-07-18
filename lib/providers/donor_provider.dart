import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/donor_model.dart';
import '../services/donor_service.dart';

final donorServiceProvider =
    Provider<DonorService>((_) => DonorService());

class DonorState {
  final List<DonorModel> donors;
  final bool isLoading;
  final String? error;

  const DonorState({
    this.donors = const [],
    this.isLoading = false,
    this.error,
  });

  DonorState copyWith({
    List<DonorModel>? donors,
    bool? isLoading,
    String? error,
  }) {
    return DonorState(
      donors: donors ?? this.donors,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DonorNotifier extends StateNotifier<DonorState> {
  final DonorService _service;

  DonorNotifier(this._service) : super(const DonorState());

  Future<void> getDonors() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getDonors();
      state = state.copyWith(donors: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createDonor(DonorRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createDonor(request);
      await getDonors();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateDonor(String donorId, DonorRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateDonor(donorId, request);
      await getDonors();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteDonor(String donorId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteDonor(donorId);
      state = state.copyWith(
        donors:
            state.donors.where((d) => d.donorId != donorId).toList(),
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

final donorProvider = StateNotifierProvider<DonorNotifier, DonorState>(
  (ref) => DonorNotifier(ref.read(donorServiceProvider)),
);
