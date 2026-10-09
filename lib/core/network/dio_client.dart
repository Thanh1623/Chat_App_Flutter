import 'package:chat_app/core/config/env.dart';
import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/auth_interceptor.dart';
import 'package:chat_app/core/storage/session_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final session = ref.watch(sessionStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(AuthInterceptor(session));

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  return dio;
});

final healthClientProvider = Provider<HealthClient>((ref) {
  return HealthClient(ref.watch(dioProvider));
});

class HealthClient {
  const HealthClient(this._dio);
  final Dio _dio;

  Future<bool> ping() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.health);
    return res.data?['ok'] == true;
  }
}
