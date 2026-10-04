import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/features/conversations/data/datasources/conversations_remote_data_source.dart';
import 'package:chat_app/features/conversations/data/repositories/conversations_repository_impl.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/domain/repositories/conversations_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final conversationsRemoteDataSourceProvider =
    Provider<ConversationsRemoteDataSource>((ref) {
  return ConversationsRemoteDataSource(ref.watch(dioProvider));
});

final conversationsRepositoryProvider = Provider<ConversationsRepository>((ref) {
  return ConversationsRepositoryImpl(ref.watch(conversationsRemoteDataSourceProvider));
});

final conversationsProvider = FutureProvider<List<Conversation>>((ref) {
  return ref.watch(conversationsRepositoryProvider).fetchConversations();
});
