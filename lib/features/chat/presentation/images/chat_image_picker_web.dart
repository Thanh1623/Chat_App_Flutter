import 'dart:async';
import 'dart:js_interop';

import 'package:chat_app/features/chat/presentation/images/chat_image_picker_common.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web/web.dart' as web;

Future<List<XFile>> pickChatImageFiles() {
  final completer = Completer<List<XFile>>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*'
    ..multiple = true;

  void finish(List<XFile> files) {
    if (!completer.isCompleted) {
      completer.complete(files);
    }
    input.remove();
  }

  input.onchange = (web.Event event) {
    final target = event.target as web.HTMLInputElement?;
    final files = target?.files;
    if (files == null || files.length == 0) {
      finish([]);
      return;
    }
    final count = files.length.clamp(0, kMaxChatImagesPerSend);
    final picked = <XFile>[];
    for (var i = 0; i < count; i++) {
      final file = files.item(i);
      if (file == null) continue;
      picked.add(
        XFile(
          web.URL.createObjectURL(file),
          name: file.name,
          mimeType: file.type,
        ),
      );
    }
    finish(picked);
  }.toJS;

  input.oncancel = (web.Event _) {
    finish([]);
  }.toJS;

  web.document.body!.append(input);
  input.click();

  return completer.future;
}
