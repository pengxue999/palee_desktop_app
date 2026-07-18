import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/http_helper.dart';
import '../models/registration_model.dart';
import '../services/registration_service.dart';

final registrationServiceProvider =
    Provider<RegistrationService>((_) => RegistrationService());

class RegistrationState {
  final List<RegistrationModel> registrations;
  final bool isLoading;
  final String? error;
  final bool isCreating;

  RegistrationState({
    this.registrations = const [],
    this.isLoading = false,
    this.error,
    this.isCreating = false,
  });

  RegistrationState copyWith({
    List<RegistrationModel>? registrations,
    bool? isLoading,
    String? error,
    bool? isCreating,
  }) {
    return RegistrationState(
      registrations: registrations ?? this.registrations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isCreating: isCreating ?? this.isCreating,
    );
  }
}

class RegistrationNotifier extends StateNotifier<RegistrationState> {
  final RegistrationService _service;

  RegistrationNotifier(this._service) : super(RegistrationState());

  Future<void> getRegistrations({
    String? academicId,
    bool allYears = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getRegistrations(
        academicId: academicId,
        allYears: allYears,
      );
      state = state.copyWith(
        registrations: response.data,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createRegistration(RegistrationRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createRegistration(request);
      await getRegistrations();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> createRegistrationWithDetails(
    RegistrationRequest request,
    List<Map<String, dynamic>> details,
  ) async {
    state = state.copyWith(isCreating: true, error: null);
    try {
      final response = await _service.createRegistrationBulk(request, details);
      state = state.copyWith(
        registrations: [...state.registrations, response.data],
        isCreating: false,
      );
      return true;
    } on ValidationException catch (e) {
      final errorDetails = e.errors?.map((err) => err['msg'] as String? ?? '').join('\n');
      state = state.copyWith(error: errorDetails ?? e.message, isCreating: false);
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isCreating: false);
      return false;
    }
  }

  Future<bool> createRegistrationAndDetails(
    RegistrationRequest request,
    List<Map<String, dynamic>> details,
  ) async {
    state = state.copyWith(isCreating: true, error: null);
    try {
      final response = await _service.createRegistrationBulk(request, details);

      state = state.copyWith(
        registrations: [...state.registrations, response.data],
        isCreating: false,
      );
      return true;
    } on ValidationException catch (e) {
      final errorDetails = e.errors?.map((err) => err['msg'] as String? ?? '').join('\n');
      state = state.copyWith(error: errorDetails ?? e.message, isCreating: false);
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isCreating: false);
      return false;
    }
  }

  Future<bool> updateRegistration(
      String registrationId, RegistrationRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateRegistration(registrationId, request);
      await getRegistrations();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteRegistration(String registrationId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteRegistration(registrationId);
      state = state.copyWith(
        registrations: state.registrations
            .where((r) => r.registrationId != registrationId)
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

final registrationProvider =
    StateNotifierProvider<RegistrationNotifier, RegistrationState>(
  (ref) => RegistrationNotifier(
    ref.read(registrationServiceProvider),
  ),
);
