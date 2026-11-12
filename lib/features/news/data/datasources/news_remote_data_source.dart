import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/image_multipart.dart';
import 'package:chat_app/features/news/data/models/news_comment_model.dart';
import 'package:chat_app/features/news/data/models/news_models.dart';
import 'package:chat_app/features/news/data/models/news_post_model.dart';
import 'package:chat_app/features/news/domain/entities/news_comment.dart';
import 'package:chat_app/features/news/domain/entities/news_feed_item.dart';
import 'package:chat_app/features/news/domain/entities/news_image.dart';
import 'package:chat_app/features/news/domain/entities/news_post.dart';
import 'package:chat_app/features/news/domain/entities/news_post_input.dart';
import 'package:chat_app/features/news/domain/entities/news_post_page.dart';
import 'package:chat_app/features/news/domain/repositories/news_repository.dart';
import 'package:dio/dio.dart';

class NewsRemoteDataSource {
  const NewsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<NewsPostPage> fetchPublishedPosts({
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.newsPosts,
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return NewsPostPageModel.fromJson(response.data ?? {}).toEntity();
  }

  Future<NewsFeedItem> fetchPost(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.newsPost(id),
    );
    return NewsFeedItemModel.fromJson(response.data ?? {}).toEntity();
  }

  Future<int> fetchUnreadCount() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.newsUnread,
    );
    return (response.data?['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markNewsSeen() async {
    await _dio.post<void>(ApiEndpoints.newsSeen);
  }

  Future<NewsReactionSnapshot> setLike(
    String postId, {
    required bool like,
  }) async {
    final Response<Map<String, dynamic>> response;
    if (like) {
      response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.newsPostReaction(postId),
        data: const {'kind': 'like'},
      );
    } else {
      response = await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.newsPostReaction(postId),
      );
    }
    final data = response.data ?? {};
    final total = (data['total'] as num?)?.toInt() ?? 0;
    final liked = data['mine'] != null;
    return NewsReactionSnapshot(total: total, likedByMe: liked);
  }

  Future<NewsCommentPage> fetchComments(
    String postId, {
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.newsPostComments(postId),
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return NewsCommentPageModel.fromJson(response.data ?? {}).toEntity();
  }

  Future<NewsComment> createComment(String postId, String body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.newsPostComments(postId),
      data: {'body': body},
    );
    return NewsCommentModel.fromJson(response.data ?? {}).toEntity();
  }

  Future<NewsPost> createDraft() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.newsPosts,
    );
    return NewsPostModel.fromJson(response.data ?? {}).toEntity();
  }

  Future<NewsPost> updatePost(String id, NewsPostInput input) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.newsPost(id),
      data: input.toJson(),
    );
    return NewsPostModel.fromJson(response.data ?? {}).toEntity();
  }

  Future<NewsPost> publishPost(String id, String expectedUpdatedAt) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.newsPostPublish(id),
      data: {'expectedUpdatedAt': expectedUpdatedAt},
    );
    return NewsPostModel.fromJson(response.data ?? {}).toEntity();
  }

  Future<NewsImage> uploadImage({
    required String postId,
    required List<int> bytes,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: imageMediaTypeFromFilename(filename),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.newsPostImages(postId),
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: const {'Content-Type': null},
      ),
    );
    return NewsImageModel.fromJson(response.data ?? {}).toEntity();
  }
}
