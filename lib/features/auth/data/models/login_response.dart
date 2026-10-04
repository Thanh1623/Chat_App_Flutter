import 'package:chat_app/features/auth/domain/entities/user.dart';

class LoginResponse {
  const LoginResponse({required this.accessToken, required this.user});

  final String accessToken;
  final User user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final token = (json['accessToken'] ??
            json['access_token'] ??
            json['token'])
        ?.toString();
    if (token == null || token.isEmpty) {
      throw FormatException('Login response missing access token');
    }

    final userJson = json['user'];
    final user = userJson is Map<String, dynamic>
        ? User.fromJson(userJson)
        : User.fromJson(json);

    return LoginResponse(accessToken: token, user: user);
  }
}
