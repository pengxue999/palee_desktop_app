import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../core/utils/http_helper.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isInitializing;
  final String? error;
  final int? userId;
  final String? userName;
  final String? role;
  final String? token;
  final String? teacherId;
  final bool hasTeacherInfo;
  final bool hasTeachingInfo;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isInitializing = true,
    this.error,
    this.userId,
    this.userName,
    this.role,
    this.token,
    this.teacherId,
    this.hasTeacherInfo = false,
    this.hasTeachingInfo = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isInitializing,
    String? error,
    int? userId,
    String? userName,
    String? role,
    String? token,
    String? teacherId,
    bool? hasTeacherInfo,
    bool? hasTeachingInfo,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      token: token ?? this.token,
      teacherId: teacherId ?? this.teacherId,
      hasTeacherInfo: hasTeacherInfo ?? this.hasTeacherInfo,
      hasTeachingInfo: hasTeachingInfo ?? this.hasTeachingInfo,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthState()) {
    HttpHelper().onUnauthorized = _onUnauthorized;
    // token ເກັບໃນ memory ເທົ່ານັ້ນ — ບໍ່ກູ້ session ຄືນ, ເປີດແອັບໃໝ່ຕ້ອງ login ໃໝ່ສະເໝີ.
    state = state.copyWith(isInitializing: false);
  }

  /// ຖືກເອີ້ນເມື່ອ API ຕອບ 401 (token ໝົດອາຍຸ): ລ້າງ session ແລ້ວໃຫ້ router ພາກັບໄປ login.
  void _onUnauthorized() {
    if (!state.isAuthenticated) return;
    logout();
  }

  Future<bool> login(String userName, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.login(
        AuthLoginRequest(userName: userName, userPassword: password),
      );

      HttpHelper().setDefaultHeaders({
        'Authorization': 'Bearer ${response.accessToken}',
      });

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        token: response.accessToken,
        userId: response.userId,
        userName: response.userName,
        role: response.role,
        teacherId: response.teacherId,
        hasTeacherInfo: response.hasTeacherInfo,
        hasTeachingInfo: response.hasTeachingInfo,
      );

      developer.log(
        'login ສຳເລັດ — '
        'user_id=${response.userId}, '
        'user_name=${response.userName}, '
        'role=${response.role}, '
        'teacher_id=${response.teacherId}, '
        'has_teacher_info=${response.hasTeacherInfo}, '
        'has_teaching_info=${response.hasTeachingInfo}\n'
        'token=${response.accessToken}',
        name: 'auth',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void logout() {
    HttpHelper().removeDefaultHeader('Authorization');
    state = const AuthState(isInitializing: false);
  }
}

final authServiceProvider = Provider<AuthService>((_) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);
