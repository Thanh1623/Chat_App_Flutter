import 'package:chat_app/core/error/exception_mapper.dart';
import 'package:chat_app/features/news/data/datasources/news_remote_data_source.dart';
import 'package:chat_app/features/news/domain/entities/news_comment.dart';
import 'package:chat_app/features/news/domain/entities/news_feed_item.dart';
import 'package:chat_app/features/news/domain/entities/news_image.dart';
import 'package:chat_app/features/news/domain/entities/news_post.dart';
import 'package:chat_app/features/news/domain/entities/news_post_input.dart';
import 'package:chat_app/features/news/domain/entities/news_post_page.dart';
import 'package:chat_app/features/news/domain/repositories/news_repository.dart';

class NewsRepositoryImpl implements NewsRepository {
  const NewsRepositoryImpl(this._remote);

  final NewsRemoteDataSource _remote;

  @override
  Future<NewsPostPage> fetchPublishedPosts({
    int limit = 20,
    String? cursor,
  }) async {
    try {
      return await _remote.fetchPublishedPosts(limit: limit, cursor: cursor);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<NewsFeedItem> fetchPost(String id) async {
    try {
      return await _remote.fetchPost(id);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<int> fetchUnreadCount() async {
    try {
      return await _remote.fetchUnreadCount();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> markNewsSeen() async {
    try {
      await _remote.markNewsSeen();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<NewsReactionSnapshot> setLike(
    String postId, {
    required bool like,
  }) async {
    try {
      return await _remote.setLike(postId, like: like);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<NewsCommentPage> fetchComments(
    String postId, {
    String? cursor,
    int limit = 20,
  }) async {
    try {
      return await _remote.fetchComments(postId, cursor: cursor, limit: limit);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<NewsComment> createComment(String postId, String body) async {
    try {
      return await _remote.createComment(postId, body);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<NewsPost> createDraft() async {
    try {
      return await _remote.createDraft();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<NewsPost> fetchPostForEdit(String id) async {
    try {
      return await _remote.fetchPostForEdit(id);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<NewsPost> updatePost(String id, NewsPostInput input) async {
    try {
      return await _remote.updatePost(id, input);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<NewsPost> publishPost(String id, String expectedUpdatedAt) async {
    try {
      return await _remote.publishPost(id, expectedUpdatedAt);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<NewsImage> uploadImage({
    required String postId,
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      return await _remote.uploadImage(
        postId: postId,
        bytes: bytes,
        filename: filename,
      );
    } catch (e) {
      throw mapException(e);
    }
  }
}
