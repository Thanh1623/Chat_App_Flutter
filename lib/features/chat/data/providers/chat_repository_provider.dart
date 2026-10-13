import 'package:chat_app/core/network/chat_socket_client.dart';
import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chat_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource(ref.watch(dioProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    ref.watch(
      chatRemoteDataSourceProvider,
    ), // chatRemoteDataSourceProvider là provider của chatRemoteDataSource
    ref.watch(
      chatSocketClientProvider,
    ), // chatSocketClientProvider là provider của chatSocketClient
  );
});
