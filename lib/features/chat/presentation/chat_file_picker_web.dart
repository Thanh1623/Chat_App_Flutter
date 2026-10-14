import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:chat_app/features/chat/presentation/chat_file_picker_common.dart';
import 'package:file_picker/file_picker.dart';
import 'package:web/web.dart' as web;

Future<List<PlatformFile>> pickChatFiles() {
  final completer = Completer<List<PlatformFile>>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..multiple = true
    ..accept = kChatFileExtensions.map((e) => '.$e').join(',');

  void finish(List<PlatformFile> files) {
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
    _readWebFiles(files).then(finish).catchError((Object e, StackTrace _) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      input.remove();
    });
  }.toJS;

  input.oncancel = (web.Event _) {
    finish([]);
  }.toJS;

  web.document.body!.append(input);
  input.click();

  return completer.future;
}

Future<List<PlatformFile>> _readWebFiles(web.FileList files) async {
  final picked = <PlatformFile>[];
  final count = files.length;
  for (var i = 0; i < count && picked.length < kMaxChatFilesPerSend; i++) {
    final file = files.item(i);
    if (file == null) continue;
    if (!isAllowedChatFileName(file.name)) continue;
    if (file.size > kMaxChatFileBytes) continue;
    final buffer = await _readFileBytes(file);
    picked.add(
      PlatformFile(
        name: file.name,
        size: file.size,
        bytes: buffer,
      ),
    );
  }
  return picked;
}

Future<Uint8List> _readFileBytes(web.File file) {
  final completer = Completer<Uint8List>();
  final reader = web.FileReader();
  reader.onload = (web.Event _) {
    final byteBuffer = (reader.result as JSArrayBuffer?)?.toDart;
    if (byteBuffer == null) {
      completer.completeError(StateError('Không đọc được tệp'));
      return;
    }
    completer.complete(byteBuffer.asUint8List());
  }.toJS;
  reader.onerror = (web.Event _) {
    completer.completeError(StateError('Không đọc được tệp'));
  }.toJS;
  reader.readAsArrayBuffer(file);
  return completer.future;
}
