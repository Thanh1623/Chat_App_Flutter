import 'package:chat_app/features/diary/domain/entities/diary_post.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final diaryFeedProvider = ChangeNotifierProvider<DiaryFeedController>((ref) {
  return DiaryFeedController();
});

class DiaryFeedController extends ChangeNotifier {
  DiaryFeedController({DateTime? now, List<DiaryPost>? seed})
    : _posts = List.of(seed ?? mockDiaryPosts(now ?? DateTime.now()));

  List<DiaryPost> _posts;
  List<DiaryPost> get posts => List.unmodifiable(_posts);

  void toggleLike(String postId) {
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index < 0) return;
    final post = _posts[index];
    final liked = !post.likedByMe;
    _posts = List.of(_posts);
    _posts[index] = post.copyWith(
      likedByMe: liked,
      likeCount: post.likeCount + (liked ? 1 : -1),
    );
    notifyListeners();
  }
}

List<DiaryPost> mockDiaryPosts(DateTime now) {
  const phuc = DiaryAuthor(
    id: 'phuc',
    name: 'Lê Hoàng Phúc',
    avatarUrl: 'https://i.pravatar.cc/150?u=le-hoang-phuc',
  );
  const thao = DiaryAuthor(
    id: 'thao',
    name: 'Phương Thảo',
    avatarUrl: 'https://i.pravatar.cc/150?u=phuong-thao',
  );
  const huy = DiaryAuthor(
    id: 'huy',
    name: 'Đặng Quang Huy',
    avatarUrl: 'https://i.pravatar.cc/150?u=dang-quang-huy',
  );
  const trang = DiaryAuthor(
    id: 'trang',
    name: 'Trần Thu Trang',
    avatarUrl: 'https://i.pravatar.cc/150?u=tran-thu-trang',
  );

  return [
    DiaryPost(
      id: 'p1',
      author: phuc,
      caption:
          'Cuối tuần hoàn thành xong bản demo ứng dụng chat thế hệ mới. Mời mọi người trải nghiệm thử và cho mình góp ý nhé!',
      createdAt: now.subtract(const Duration(hours: 2)),
      imageUrls: const [
        'https://picsum.photos/seed/diary-chat-left/720/1280',
        'https://picsum.photos/seed/diary-chat-right/720/1280',
      ],
      likeCount: 44,
      commentCount: 18,
      topLikerName: 'Lê Nam',
      previewComments: const [
        DiaryComment(
          id: 'c1',
          author: huy,
          text:
              'Giao diện nhìn mượt quá anh Phúc ơi! Màu xanh sáng rõ nét và icon rất hiện đại.',
        ),
        DiaryComment(
          id: 'c2',
          author: trang,
          text: 'Cho mình xin link test bản Beta với nhé bạn!',
        ),
      ],
    ),
    DiaryPost(
      id: 'p2',
      author: thao,
      caption:
          'Chào đón một ngày mới tràn đầy năng lượng tại văn phòng mới 🌿✨',
      createdAt: now.subtract(const Duration(hours: 5)),
      imageUrls: const [
        'https://picsum.photos/seed/diary-office/1600/1000',
      ],
      likeCount: 81,
      commentCount: 12,
      topLikerName: 'Nguyễn An',
    ),
  ];
}
