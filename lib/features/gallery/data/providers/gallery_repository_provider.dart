import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/features/gallery/data/datasources/gallery_remote_data_source.dart';
import 'package:chat_app/features/gallery/data/repositories/gallery_repository_impl.dart';
import 'package:chat_app/features/gallery/domain/repositories/gallery_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final galleryRemoteDataSourceProvider = Provider<GalleryRemoteDataSource>((ref) {
  return GalleryRemoteDataSource(ref.watch(dioProvider));
});

final galleryRepositoryProvider = Provider<GalleryRepository>((ref) {
  return GalleryRepositoryImpl(ref.watch(galleryRemoteDataSourceProvider));
});
