import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/features/auth/data/models/login_response.dart';
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
}
