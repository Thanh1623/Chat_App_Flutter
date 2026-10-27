import 'package:chat_app/core/config/env.dart';
import 'package:chat_app/core/network/auth_interceptor.dart';
import 'package:chat_app/core/storage/session_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final session = ref.watch(sessionStorageProvider);
  final options = BaseOptions(
    baseUrl: Env.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
  );
  final refreshDio = Dio(options);
  late final Dio dio;
  dio = Dio(options);
  dio.interceptors.add(
    AuthInterceptor(
      session: session,
      refreshDio: refreshDio,
      client: () => dio,
    ),
  );
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
  return dio;
});
