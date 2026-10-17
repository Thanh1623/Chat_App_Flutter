import 'package:chat_app/features/chat/domain/entities/room_media.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseRoomImages/files/links maps Nest media lists', () {
    final images = parseRoomImages([
      {
        'id': 'img1',
        'url': 'https://cdn.example/a.jpg',
        'filename': 'a.jpg',
        'createdAt': '2026-10-17T08:00:00.000Z',
      },
    ]);
    expect(images.single.id, 'img1');
    expect(images.single.url, 'https://cdn.example/a.jpg');
    expect(images.single.createdAt, isNotNull);

    final files = parseRoomFiles([
      {
        'id': 'f1',
        'url': 'https://cdn.example/doc.pdf',
        'filename': 'doc.pdf',
        'mimeType': 'application/pdf',
        'sizeBytes': 2048,
      },
    ]);
    expect(files.single.filename, 'doc.pdf');
    expect(files.single.sizeBytes, 2048);

    final links = parseRoomLinks([
      {
        'url': 'https://vcb.com.vn',
        'messageId': 'm1',
        'authorName': 'An',
        'createdAt': '2026-10-17T08:00:00.000Z',
      },
    ]);
    expect(links.single.url, 'https://vcb.com.vn');
    expect(links.single.authorName, 'An');
    expect(parseRoomImages(null), isEmpty);
    expect(parseRoomFiles({'data': []}), isEmpty);
  });
}
