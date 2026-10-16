import 'package:chat_app/core/error/exception_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapException reads Nest body message', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/rooms/1/members'),
      type: DioExceptionType.badResponse,
      response: Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/rooms/1/members'),
        statusCode: 400,
        statusMessage: 'Bad Request',
        data: const {
          'statusCode': 400,
          'message': 'Thành viên đã có trong nhóm.',
        },
      ),
    );

    expect(mapException(error).toString(), 'Thành viên đã có trong nhóm.');
  });
}
