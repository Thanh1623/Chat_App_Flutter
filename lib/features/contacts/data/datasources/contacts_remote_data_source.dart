import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/features/contacts/data/models/contact_user_model.dart';
import 'package:dio/dio.dart';

class ContactsRemoteDataSource {
  const ContactsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ContactUserModel>> searchUsers(String q) async {
    final response = await _dio.get<List<dynamic>>(
      ApiEndpoints.users,
      queryParameters: q.trim().isEmpty ? null : {'q': q.trim()},
    );
    final list = response.data ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ContactUserModel.fromJson)
        .toList();
  }
}
