import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/features/contacts/data/datasources/contacts_remote_data_source.dart';
import 'package:chat_app/features/contacts/domain/entities/contact_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contactsRemoteDataSourceProvider = Provider<ContactsRemoteDataSource>(
  (ref) => ContactsRemoteDataSource(ref.watch(dioProvider)),
);

final contactSearchProvider =
    FutureProvider.autoDispose.family<List<ContactUser>, String>((ref, query) {
  return ref
      .watch(contactsRemoteDataSourceProvider)
      .searchUsers(query)
      .then((models) => models.map((m) => m.toEntity()).toList());
});

final userProfileProvider =
    FutureProvider.autoDispose.family<ContactUser, String>((ref, userId) {
  return ref
      .watch(contactsRemoteDataSourceProvider)
      .fetchUser(userId)
      .then((m) => m.toEntity());
});
