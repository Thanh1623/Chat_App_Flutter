import 'package:chat_app/features/news/domain/entities/news_block.dart';
import 'package:chat_app/features/news/domain/entities/news_image.dart';
import 'package:chat_app/features/news/domain/news_compose.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('composeToPost sets cover and image blocks', () {
    final images = [
      const NewsImage(id: 'a', displayUrl: 'https://a'),
      const NewsImage(id: 'b', displayUrl: 'https://b'),
    ];
    final out = composeToPost(
      text: 'Tiêu đề\n\nĐoạn hai',
      images: images,
      previousBlocks: const [],
    );
    expect(out.coverImageId, 'a');
    expect(out.blocks.where((b) => b.imageId == 'b').length, 1);
    expect(out.title, 'Tiêu đề');
  });

  test('postToCompose drops repeated title', () {
    expect(
      postToCompose(
        title: 'Xin chào',
        blocks: [NewsBlock.paragraph('Xin chào')],
      ),
      'Xin chào',
    );
  });

  test('postToCompose keeps distinct title as first line', () {
    expect(
      postToCompose(
        title: 'Tiêu đề',
        blocks: [NewsBlock.paragraph('Đoạn hai')],
      ),
      'Tiêu đề\nĐoạn hai',
    );
  });
}
