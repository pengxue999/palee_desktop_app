import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

final userServiceProvider =
    Provider<UserService>((_) => UserService());

class UserState {
  final List<UserModel> users;
  final bool isLoading;
  final String? error;

  const UserState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    List<UserModel>? users,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final UserService _service;

  UserNotifier(this._service) : super(const UserState());

  Future<void> getUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getUsers();
      state = state.copyWith(users: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createUser(UserCreateRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createUser(request);
      await getUsers();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateUser(int userId, UserUpdateRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateUser(userId, request);
      await getUsers();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteUser(userId);
      state = state.copyWith(
        users: state.users.where((u) => u.userId != userId).toList(),
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

final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(ref.read(userServiceProvider)),
);
