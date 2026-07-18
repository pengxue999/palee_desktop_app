import '../core/utils/http_helper.dart';
import '../models/user_model.dart';

class UserService {
  final HttpHelper _http = HttpHelper();

  Future<UserListResponse> getUsers() async {
    final response = await _http.get('/users');
    return UserListResponse.fromJson(_http.handleJson(response));
  }

  Future<UserSingleResponse> getUserById(int userId) async {
    final response = await _http.get('/users/$userId');
    return UserSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<UserSingleResponse> createUser(UserCreateRequest request) async {
    final response = await _http.post('/users', body: request.toJson());
    return UserSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<UserSingleResponse> updateUser(
    int userId,
    UserUpdateRequest request,
  ) async {
    final response = await _http.put('/users/$userId', body: request.toJson());
    return UserSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteUser(int userId) async {
    final response = await _http.delete('/users/$userId');
    _http.handleJson(response);
  }
}
