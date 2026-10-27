import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/storage/session_storage.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SessionStorage session,
    required Dio refreshDio,
    required Dio Function() client,
  }) : _session = session,
       _refreshDio = refreshDio,
       _client = client;

  final SessionStorage _session;
  final Dio _refreshDio;
  final Dio Function() _client;
  Future<void>? _ongoing;

  static const _skip = {
    ApiEndpoints.authLogin,
    ApiEndpoints.authRefresh,
    ApiEndpoints.authLogout,
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _session.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
    if (status != 401 || _skip.any(path.contains)) {
      handler.next(err);
      return;
    }
    if (err.requestOptions.extra['retried'] == true) {
      handler.next(err);
      return;
    }
    try {
      await (_ongoing ??= _refresh());
      _ongoing = null;
      final token = _session.accessToken;
      if (token == null) {
        handler.next(err);
        return;
      }
      final req = err.requestOptions;
      req.headers['Authorization'] = 'Bearer $token';
      req.extra['retried'] = true;
      final res = await _client().fetch(req);
      handler.resolve(res);
    } catch (_) {
      _ongoing = null;
      await _session.clear();
      handler.next(err);
    }
  }

  Future<void> _refresh() async {
    final refresh = _session.refreshToken;
    final user = _session.user;
    if (refresh == null || refresh.isEmpty || user == null) {
      throw StateError('no refresh');
    }
    final res = await _refreshDio.post<Map<String, dynamic>>(
      ApiEndpoints.authRefresh,
      data: {'refreshToken': refresh},
    );
    final parsed = LoginResponseLite.fromJson(res.data ?? {});
    await _session.save(
      accessToken: parsed.accessToken,
      refreshToken: parsed.refreshToken,
      user: user,
    );
  }
}

class LoginResponseLite {
  LoginResponseLite({required this.accessToken, required this.refreshToken});
  final String accessToken;
  final String refreshToken;

  factory LoginResponseLite.fromJson(Map<String, dynamic> json) {
    final token = (json['token'] ?? json['accessToken'])?.toString() ?? '';
    final refresh = json['refreshToken']?.toString() ?? '';
    if (token.isEmpty || refresh.isEmpty) {
      throw StateError('bad refresh');
    }
    return LoginResponseLite(accessToken: token, refreshToken: refresh);
  }
}
