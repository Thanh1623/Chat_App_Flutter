import 'package:chat_app/core/error/failure.dart';
import 'package:chat_app/features/news/data/providers/news_repository_provider.dart';
import 'package:chat_app/features/news/domain/entities/news_image.dart';
import 'package:chat_app/features/news/domain/entities/news_post.dart';
import 'package:chat_app/features/news/domain/entities/news_post_input.dart';
import 'package:chat_app/features/news/domain/news_compose.dart';
import 'package:chat_app/features/news/domain/news_feed_images.dart';
import 'package:chat_app/features/news/domain/repositories/news_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiaryComposeState {
  const DiaryComposeState({
    this.post,
    this.images = const [],
    this.busy = false,
    this.uploading = 0,
    this.error,
  });

  final NewsPost? post;
  final List<NewsImage> images;
  final bool busy;
  final int uploading;
  final String? error;

  bool get canSubmit =>
      post != null && !busy && uploading == 0 && (images.isNotEmpty || post != null);
}

class DiaryComposeNotifier extends Notifier<DiaryComposeState> {
  NewsRepository get _repo => ref.read(newsRepositoryProvider);

  @override
  DiaryComposeState build() => const DiaryComposeState();

  Future<bool> startDraft() async {
    state = const DiaryComposeState(busy: true);
    try {
      final post = await _repo.createDraft();
      state = DiaryComposeState(post: post);
      return true;
    } catch (e) {
      final message = e is Failure ? e.message : e.toString();
      state = DiaryComposeState(error: message, busy: false);
      return false;
    }
  }

  Future<bool> loadExisting(String id) async {
    state = const DiaryComposeState(busy: true);
    try {
      final post = await _repo.fetchPostForEdit(id);
      state = DiaryComposeState(
        post: post,
        images: newsFeedImages(
          cover: post.cover,
          blocks: post.blocks,
          images: post.images,
        ),
      );
      return true;
    } catch (e) {
      final message = e is Failure ? e.message : e.toString();
      state = DiaryComposeState(error: message, busy: false);
      return false;
    }
  }

  Future<void> uploadBytes(List<int> bytes, String filename) async {
    final post = state.post;
    if (post == null) return;
    if (state.images.length >= NewsLimits.images) {
      state = DiaryComposeState(
        post: post,
        images: state.images,
        error: 'Mỗi bài tối đa ${NewsLimits.images} ảnh.',
      );
      return;
    }
    state = DiaryComposeState(
      post: post,
      images: state.images,
      uploading: state.uploading + 1,
    );
    try {
      final image = await _repo.uploadImage(
        postId: post.id,
        bytes: bytes,
        filename: filename,
      );
      state = DiaryComposeState(
        post: post,
        images: [...state.images, image],
        uploading: state.uploading > 0 ? state.uploading - 1 : 0,
      );
    } catch (e) {
      state = DiaryComposeState(
        post: post,
        images: state.images,
        error: e.toString(),
        uploading: state.uploading > 0 ? state.uploading - 1 : 0,
      );
    }
  }

  void removeImage(String id) {
    final post = state.post;
    if (post == null) return;
    state = DiaryComposeState(
      post: post,
      images: state.images.where((i) => i.id != id).toList(),
    );
  }

  Future<NewsPost?> _save(String text) async {
    final post = state.post;
    if (post == null) return null;

    late final ComposedPost composed;
    try {
      composed = composeToPost(
        text: text,
        images: state.images,
        previousBlocks: post.blocks,
      );
    } catch (e) {
      state = DiaryComposeState(
        post: post,
        images: state.images,
        error: e.toString(),
      );
      return null;
    }

    if (composed.blocks.isEmpty) {
      state = DiaryComposeState(
        post: post,
        images: state.images,
        error: 'Nhập nội dung hoặc thêm ảnh.',
      );
      return null;
    }

    state = DiaryComposeState(
      post: post,
      images: state.images,
      busy: true,
    );
    try {
      final saved = await _repo.updatePost(
        post.id,
        NewsPostInput(
          title: composed.title,
          blocks: composed.blocks,
          coverImageId: composed.coverImageId,
          expectedUpdatedAt: post.updatedAtIso,
        ),
      );
      state = DiaryComposeState(post: saved, images: state.images);
      return saved;
    } catch (e) {
      state = DiaryComposeState(
        post: post,
        images: state.images,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Bài đã đăng: chỉ PATCH, không publish lại (khớp web).
  Future<bool> saveEdits(String text) async {
    final saved = await _save(text);
    return saved != null;
  }

  Future<bool> publish(String text) async {
    final saved = await _save(text);
    if (saved == null) return false;

    state = DiaryComposeState(
      post: saved,
      images: state.images,
      busy: true,
    );
    try {
      await _repo.publishPost(saved.id, saved.updatedAtIso);
      return true;
    } catch (e) {
      state = DiaryComposeState(
        post: saved,
        images: state.images,
        error: e.toString(),
      );
      return false;
    }
  }

  void clearError() {
    state = DiaryComposeState(
      post: state.post,
      images: state.images,
      uploading: state.uploading,
    );
  }

  void reset() {
    state = const DiaryComposeState();
  }
}

final diaryComposeProvider =
    NotifierProvider<DiaryComposeNotifier, DiaryComposeState>(
  DiaryComposeNotifier.new,
);
