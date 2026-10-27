import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/image_multipart.dart';
import 'package:chat_app/features/auth/data/models/login_response.dart';
import 'package:chat_app/features/auth/domain/entities/user.dart';
import 'package:dio/dio.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.authLogin,
      data: {'email': email, 'password': password},
    );
    return LoginResponse.fromJson(response.data ?? {});
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post<void>(
        ApiEndpoints.authLogout,
        data: {'refreshToken': refreshToken},
      );
    } on DioException {
      // ponytail: logout local vẫn chạy nếu BE fail
    }
  }

  Future<User> fetchMe() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.authMe);
    return User.fromJson(response.data ?? {});
  }

  Future<({User user, LoginResponse? tokens})> updateProfile({
    String? name,
    String? email,
    String? password,
    String? currentPassword,
  }) async {
    final data = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) {
      data['name'] = name.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      data['email'] = email.trim();
    }
    if (password != null && password.isNotEmpty) {
      data['password'] = password;
      if (currentPassword != null) {
        data['currentPassword'] = currentPassword;
      }
    }
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.authMe,
      data: data,
    );
    return _sessionBody(response.data ?? {});
  }

  Future<User> uploadAvatar({
    required List<int> bytes,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: imageMediaTypeFromFilename(filename),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.authMeAvatar,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: const {'Content-Type': null},
      ),
    );
    return _userFromSessionBody(response.data ?? {});
  }

  ({User user, LoginResponse? tokens}) _sessionBody(Map<String, dynamic> json) {
    final user = _userFromSessionBody(json);
    final refresh = json['refreshToken']?.toString() ?? '';
    return (
      user: user,
      tokens: refresh.isNotEmpty ? LoginResponse.fromJson(json) : null,
    );
  }

  User _userFromSessionBody(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson is Map<String, dynamic>) {
      return User.fromJson(userJson);
    }
    return User.fromJson(json);
  }
}
