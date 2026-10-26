import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/features/work/data/datasources/work_remote_data_source.dart';
import 'package:chat_app/features/work/data/repositories/work_repository_impl.dart';
import 'package:chat_app/features/work/domain/repositories/work_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final workRemoteDataSourceProvider = Provider<WorkRemoteDataSource>((ref) {
  return WorkRemoteDataSource(ref.watch(dioProvider));
});

final workRepositoryProvider = Provider<WorkRepository>((ref) {
  return WorkRepositoryImpl(ref.watch(workRemoteDataSourceProvider));
});
