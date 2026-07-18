class UserModel {
  final int userId;
  final String userName;
  final String role;

  const UserModel({
    required this.userId,
    required this.userName,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as int,
      userName: json['user_name'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'userId':
        return userId;
      case 'userName':
        return userName;
      case 'role':
        return role;
      default:
        return null;
    }
  }
}

class UserCreateRequest {
  final String userName;
  final String userPassword;
  final String role;

  const UserCreateRequest({
    required this.userName,
    required this.userPassword,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'user_name': userName,
        'user_password': userPassword,
        'role': role,
      };
}

class UserUpdateRequest {
  final String? userName;
  final String? userPassword;
  final String? role;

  const UserUpdateRequest({this.userName, this.userPassword, this.role});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (userName != null) map['user_name'] = userName;
    if (userPassword != null && userPassword!.isNotEmpty) {
      map['user_password'] = userPassword;
    }
    if (role != null) map['role'] = role;
    return map;
  }
}

class UserListResponse {
  final String code;
  final String messages;
  final List<UserModel> data;

  const UserListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory UserListResponse.fromJson(Map<String, dynamic> json) {
    return UserListResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UserSingleResponse {
  final String code;
  final String messages;
  final UserModel data;

  const UserSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory UserSingleResponse.fromJson(Map<String, dynamic> json) {
    return UserSingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: UserModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
