import 'package:chat_app/features/news/data/providers/news_repository_provider.dart';
import 'package:chat_app/features/news/domain/entities/news_reaction_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final newsPostReactionUsersProvider = FutureProvider.autoDispose
    .family<List<NewsReactionUser>, String>((ref, postId) {
      return ref.watch(newsRepositoryProvider).fetchReactionUsers(postId);
    });
