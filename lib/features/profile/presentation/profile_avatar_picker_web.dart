import 'dart:async';
import 'dart:js_interop';

import 'package:image_picker/image_picker.dart';
import 'package:web/web.dart' as web;

/// ponytail: web-only — `image_picker` defer `input.click()` qua Future → browser chặn.
Future<XFile?> pickProfileImageFile() {
  final completer = Completer<XFile?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*';

  void finish(XFile? file) {
    if (!completer.isCompleted) {
      completer.complete(file);
    }
    input.remove();
  }

  input.onchange = (web.Event event) {
    final target = event.target as web.HTMLInputElement?;
    final files = target?.files;
    if (files == null || files.length == 0) {
      finish(null);
      return;
    }
    final file = files.item(0)!;
    finish(
      XFile(
        web.URL.createObjectURL(file),
        name: file.name,
        mimeType: file.type,
      ),
    );
  }.toJS;

  input.oncancel = (web.Event _) {
    finish(null);
  }.toJS;

  web.document.body!.append(input);
  input.click();

  return completer.future;
}
