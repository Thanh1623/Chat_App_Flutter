class DiaryAuthor {
  const DiaryAuthor({
    required this.id,
    required this.name,
    this.avatarUrl = '',
  });

  final String id;
  final String name;
  final String avatarUrl;
}

class DiaryComment {
  const DiaryComment({
    required this.id,
    required this.author,
    required this.text,
  });

  final String id;
  final DiaryAuthor author;
  final String text;
}

class DiaryPost {
  const DiaryPost({
    required this.id,
    required this.author,
    required this.caption,
    required this.createdAt,
    this.imageUrls = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
    this.topLikerName,
    this.previewComments = const [],
  });

  final String id;
  final DiaryAuthor author;
  final String caption;
  final DateTime createdAt;
  final List<String> imageUrls;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final String? topLikerName;
  final List<DiaryComment> previewComments;

  DiaryPost copyWith({
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
    List<DiaryComment>? previewComments,
  }) {
    return DiaryPost(
      id: id,
      author: author,
      caption: caption,
      createdAt: createdAt,
      imageUrls: imageUrls,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedByMe: likedByMe ?? this.likedByMe,
      topLikerName: topLikerName,
      previewComments: previewComments ?? this.previewComments,
    );
  }
}
