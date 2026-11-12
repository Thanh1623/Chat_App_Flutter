import 'package:chat_app/features/news/domain/entities/news_block.dart';
import 'package:chat_app/features/news/domain/entities/news_image.dart';

class NewsLimits {
  static const blocks = 100;
  static const images = 30;
  static const paragraph = 10000;
  static const titleCut = 150; // khớp web compose, không phải 200 của DTO
}

const composeTooLong = 'Bài quá dài, hãy rút gọn bớt.';

class ComposedPost {
  const ComposedPost({
    required this.title,
    required this.blocks,
    required this.coverImageId,
  });

  final String title;
  final List<NewsBlock> blocks;
  final String? coverImageId;
}

({String title, bool complete}) _cutTitle(String line) {
  if (line.length <= NewsLimits.titleCut) {
    return (title: line, complete: true);
  }
  final head = line.substring(0, NewsLimits.titleCut);
  final space = head.lastIndexOf(' ');
  final cutAt = space > NewsLimits.titleCut * 0.6 ? space : NewsLimits.titleCut;
  return (title: '${head.substring(0, cutAt).trimRight()}…', complete: false);
}

List<String> _paragraphsOf(String text) {
  final parts = <String>[];
  for (final raw in text.split(RegExp(r'\n\s*\n'))) {
    final part = raw.trim();
    for (var at = 0; at < part.length; at += NewsLimits.paragraph) {
      parts.add(
        part.substring(at, (at + NewsLimits.paragraph).clamp(0, part.length)),
      );
    }
  }
  return parts;
}

ComposedPost composeToPost({
  required String text,
  required List<NewsImage> images,
  required List<NewsBlock> previousBlocks,
}) {
  final normalized = text.replaceAll('\r\n', '\n').trim();
  var title = '';
  var paragraphs = <String>[];

  if (normalized.isNotEmpty) {
    final lines = normalized.split('\n');
    final firstLine = lines.first.trim();
    final cut = _cutTitle(firstLine);
    title = cut.title;
    final rest = lines.length > 1 ? lines.sublist(1).join('\n') : '';
    paragraphs = _paragraphsOf(cut.complete ? rest : normalized);
    if (paragraphs.isEmpty) {
      paragraphs = _paragraphsOf(firstLine);
    }
  }

  final captions = <String, String>{};
  for (final block in previousBlocks) {
    if (block.type == NewsBlockType.image && block.imageId != null) {
      captions.putIfAbsent(block.imageId!, () => block.caption);
    }
  }

  final blocks = <NewsBlock>[
    ...paragraphs.map((p) => NewsBlock.paragraph(p)),
    ...images
        .skip(1)
        .map(
          (img) =>
              NewsBlock.image(imageId: img.id, caption: captions[img.id] ?? ''),
        ),
  ];

  if (blocks.length > NewsLimits.blocks) {
    throw StateError(composeTooLong);
  }

  return ComposedPost(
    title: title,
    blocks: blocks,
    coverImageId: images.isNotEmpty ? images.first.id : null,
  );
}

bool titleRepeats(String title, List<NewsBlock> blocks) {
  final head = title.trim();
  String? first;
  for (final block in blocks) {
    if (block.type != NewsBlockType.image) {
      first = block.text?.trim();
      break;
    }
  }
  if (head.isEmpty || first == null) return false;
  if (first == head) return true;
  return head.endsWith('…') &&
      head.length > 1 &&
      first.startsWith(head.substring(0, head.length - 1));
}

/// Ngược composeToPost: title phụ của bài cũ thành một dòng thường.
String postToCompose({
  required String title,
  required List<NewsBlock> blocks,
}) {
  final body = blocks
      .where((b) => b.type != NewsBlockType.image)
      .map((b) => b.text?.trim() ?? '')
      .where((t) => t.isNotEmpty)
      .join('\n\n');
  if (title.trim().isEmpty || titleRepeats(title, blocks)) return body;
  return body.isEmpty ? title : '$title\n$body';
}
