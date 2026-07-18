import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/donation_category_model.dart';
import '../services/donation_category_service.dart';

final donationCategoryServiceProvider = Provider<DonationCategoryService>(
  (_) => DonationCategoryService(),
);

class DonationCategoryState {
  final List<DonationCategoryModel> donationCategories;
  final bool isLoading;
  final String? error;

  const DonationCategoryState({
    this.donationCategories = const [],
    this.isLoading = false,
    this.error,
  });

  DonationCategoryState copyWith({
    List<DonationCategoryModel>? donationCategories,
    bool? isLoading,
    String? error,
  }) {
    return DonationCategoryState(
      donationCategories: donationCategories ?? this.donationCategories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DonationCategoryNotifier extends StateNotifier<DonationCategoryState> {
  final DonationCategoryService _service;

  DonationCategoryNotifier(this._service)
    : super(const DonationCategoryState());

  Future<void> getDonationCategories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getDonationCategories();
      state = state.copyWith(
        donationCategories: response.data,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createDonationCategory(DonationCategoryRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createDonationCategory(request);
      await getDonationCategories();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateDonationCategory(
    int donationCategoryId,
    DonationCategoryRequest request,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateDonationCategory(donationCategoryId, request);
      await getDonationCategories();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteDonationCategory(int donationCategoryId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteDonationCategory(donationCategoryId);
      state = state.copyWith(
        donationCategories: state.donationCategories
            .where((item) => item.donationCategoryId != donationCategoryId)
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

final donationCategoryProvider =
    StateNotifierProvider<DonationCategoryNotifier, DonationCategoryState>(
      (ref) =>
          DonationCategoryNotifier(ref.read(donationCategoryServiceProvider)),
    );
