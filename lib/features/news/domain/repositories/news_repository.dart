import 'package:chat_app/features/news/domain/entities/news_comment.dart';
import 'package:chat_app/features/news/domain/entities/news_feed_item.dart';
import 'package:chat_app/features/news/domain/entities/news_image.dart';
import 'package:chat_app/features/news/domain/entities/news_post.dart';
import 'package:chat_app/features/news/domain/entities/news_post_input.dart';
import 'package:chat_app/features/news/domain/entities/news_post_page.dart';

class NewsReactionSnapshot {
  const NewsReactionSnapshot({required this.total, required this.likedByMe});

  final int total;
  final bool likedByMe;
}

abstract interface class NewsRepository {
  Future<NewsPostPage> fetchPublishedPosts({int limit = 20, String? cursor});

  Future<NewsFeedItem> fetchPost(String id);

  Future<int> fetchUnreadCount();

  Future<void> markNewsSeen();

  Future<NewsReactionSnapshot> setLike(String postId, {required bool like});

  Future<NewsCommentPage> fetchComments(
    String postId, {
    String? cursor,
    int limit = 20,
  });

  Future<NewsComment> createComment(String postId, String body);

  Future<NewsPost> createDraft();

  Future<NewsPost> updatePost(String id, NewsPostInput input);

  Future<NewsPost> publishPost(String id, String expectedUpdatedAt);

  Future<NewsImage> uploadImage({
    required String postId,
    required List<int> bytes,
    required String filename,
  });
}
