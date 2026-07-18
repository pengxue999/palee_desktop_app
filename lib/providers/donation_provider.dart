import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/donation_model.dart';
import '../services/donation_service.dart';

final donationServiceProvider = Provider<DonationService>((_) => DonationService());

class DonationState {
  final List<DonationModel> donations;
  final List<DonationModel> donorDonations;
  final bool isLoading;
  final bool isLoadingDonorDonations;
  final bool isCreating;
  final String? selectedDonorId;
  final String? error;

  const DonationState({
    this.donations = const [],
    this.donorDonations = const [],
    this.isLoading = false,
    this.isLoadingDonorDonations = false,
    this.isCreating = false,
    this.selectedDonorId,
    this.error,
  });

  DonationState copyWith({
    List<DonationModel>? donations,
    List<DonationModel>? donorDonations,
    bool? isLoading,
    bool? isLoadingDonorDonations,
    bool? isCreating,
    String? selectedDonorId,
    String? error,
    bool clearSelectedDonor = false,
  }) {
    return DonationState(
      donations: donations ?? this.donations,
      donorDonations: donorDonations ?? this.donorDonations,
      isLoading: isLoading ?? this.isLoading,
      isLoadingDonorDonations: isLoadingDonorDonations ?? this.isLoadingDonorDonations,
      isCreating: isCreating ?? this.isCreating,
      selectedDonorId: clearSelectedDonor ? null : (selectedDonorId ?? this.selectedDonorId),
      error: error,
    );
  }

  double get totalDonations {
    return donations.fold(0.0, (sum, d) => sum + d.amount);
  }

  List<DonationModel> get selectedDonorDonations {
    if (selectedDonorId == null) return [];
    return donations.where((d) => d.donorId == selectedDonorId).toList();
  }
}

class DonationNotifier extends StateNotifier<DonationState> {
  final DonationService _service;

  DonationNotifier(this._service) : super(const DonationState());

  Future<void> getDonations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getDonations();
      state = state.copyWith(donations: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> getDonationsByDonor(String donorId) async {
    state = state.copyWith(isLoadingDonorDonations: true, error: null);
    try {
      final response = await _service.getDonationsByDonor(donorId);
      state = state.copyWith(
        donorDonations: response.data,
        isLoadingDonorDonations: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoadingDonorDonations: false);
    }
  }

  void selectDonor(String donorId) {
    state = state.copyWith(selectedDonorId: donorId);
  }

  void clearSelectedDonor() {
    state = state.copyWith(clearSelectedDonor: true);
  }

  Future<bool> createDonation(DonationRequest request) async {
    state = state.copyWith(isCreating: true, error: null);
    try {
      final response = await _service.createDonation(request);
      state = state.copyWith(
        donations: [...state.donations, response.data],
        donorDonations: request.donorId == state.selectedDonorId
            ? [...state.donorDonations, response.data]
            : state.donorDonations,
        isCreating: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isCreating: false);
      return false;
    }
  }

  Future<bool> updateDonation(int donationId, DonationUpdateRequest request) async {
    state = state.copyWith(isCreating: true, error: null);
    try {
      final response = await _service.updateDonation(donationId, request);
      state = state.copyWith(
        donations: state.donations.map((d) =>
          d.donationId == donationId ? response.data : d
        ).toList(),
        donorDonations: state.donorDonations.map((d) =>
          d.donationId == donationId ? response.data : d
        ).toList(),
        isCreating: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isCreating: false);
      return false;
    }
  }

  Future<bool> deleteDonation(int donationId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteDonation(donationId);
      state = state.copyWith(
        donations: state.donations.where((d) => d.donationId != donationId).toList(),
        donorDonations: state.donorDonations.where((d) => d.donationId != donationId).toList(),
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

final donationProvider = StateNotifierProvider<DonationNotifier, DonationState>(
  (ref) => DonationNotifier(ref.read(donationServiceProvider)),
);
