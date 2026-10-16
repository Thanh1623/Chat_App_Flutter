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
        return ServerFailure(_responseMessage(error));
      default:
        return NetworkFailure(error.message ?? 'Request failed');
    }
  }
  return UnknownFailure(error.toString());
}

String _responseMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message;
    if (message is List && message.isNotEmpty) {
      return message.first.toString();
    }
  }
  return error.response?.statusMessage ?? 'HTTP ${error.response?.statusCode}';
}
