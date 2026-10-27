import 'package:chat_app/features/auth/domain/entities/user.dart';

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final User user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final token =
        (json['token'] ?? json['accessToken'] ?? json['access_token'])
            ?.toString() ??
        '';
    final refresh = json['refreshToken']?.toString() ?? '';
    if (token.isEmpty) {
      throw const FormatException('Login response missing access token');
    }
    final userJson = json['user'];
    final user = userJson is Map<String, dynamic>
        ? User.fromJson(userJson)
        : User.fromJson(json);
    return LoginResponse(accessToken: token, refreshToken: refresh, user: user);
  }
}
