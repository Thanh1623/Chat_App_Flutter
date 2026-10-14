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

  Future<void> logout() async {
    try {
      await _dio.post<void>(ApiEndpoints.authLogout);
    } on DioException {
      // ponytail: BE có thể không có logout — vẫn xóa token local
    }
  }

  Future<User> fetchMe() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.authMe);
    return User.fromJson(response.data ?? {});
  }

  Future<LoginResponse> updateProfile({
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
    return LoginResponse.fromJson(response.data ?? {});
  }

  Future<LoginResponse> uploadAvatar({
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
    return LoginResponse.fromJson(response.data ?? {});
  }
}
