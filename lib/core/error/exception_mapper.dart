import 'package:chat_app/core/error/failure.dart';
import 'package:dio/dio.dart';

Failure mapException(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkFailure(error.message ?? 'Connection failed');
      case DioExceptionType.badResponse:
        return ServerFailure(
          error.response?.statusMessage ?? 'HTTP ${error.response?.statusCode}',
        );
      default:
        return NetworkFailure(error.message ?? 'Request failed');
    }
  }
  return UnknownFailure(error.toString());
}
