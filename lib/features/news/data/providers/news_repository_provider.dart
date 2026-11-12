import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/features/news/data/datasources/news_remote_data_source.dart';
import 'package:chat_app/features/news/data/repositories/news_repository_impl.dart';
import 'package:chat_app/features/news/domain/repositories/news_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final newsRemoteDataSourceProvider = Provider<NewsRemoteDataSource>((ref) {
  return NewsRemoteDataSource(ref.watch(dioProvider));
});

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepositoryImpl(ref.watch(newsRemoteDataSourceProvider));
});
