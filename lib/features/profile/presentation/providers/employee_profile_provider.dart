import 'package:chat_app/core/error/exception_mapper.dart';
import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/core/network/image_multipart.dart';
import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/profile/domain/entities/employee_profile.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hồ sơ nhân sự của chính mình — `GET /employees/me`.
final employeeProfileProvider = FutureProvider.autoDispose<EmployeeProfile>((
  ref,
) async {
  final userId = ref.watch(authControllerProvider).user?.id;
  if (userId == null) {
    throw StateError('Chưa đăng nhập');
  }
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get<Map<String, dynamic>>(
      ApiEndpoints.employeeMe,
    );
    return EmployeeProfile.fromJson(response.data ?? {});
  } catch (e) {
    throw mapException(e);
  }
});

/// Ghi hồ sơ của chính mình — `PATCH /employees/me`, `POST /employees/me/citizen-id/:side`.
final employeeProfileWriterProvider = Provider<EmployeeProfileWriter>(
  (ref) => EmployeeProfileWriter(ref.watch(dioProvider)),
);

class EmployeeProfileWriter {
  const EmployeeProfileWriter(this._dio);

  final Dio _dio;

  Future<EmployeeProfile> update(Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.employeeMe,
        data: body,
      );
      return EmployeeProfile.fromJson(response.data ?? {});
    } catch (e) {
      throw mapException(e);
    }
  }

  /// [side]: `front` hoặc `back`. Trả về URL ảnh mới.
  Future<String> uploadCitizenId({
    required String side,
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: imageMediaTypeFromFilename(filename),
        ),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.employeeMeCitizenId(side),
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: const {'Content-Type': null},
        ),
      );
      return response.data?['url']?.toString() ?? '';
    } catch (e) {
      throw mapException(e);
    }
  }
}
