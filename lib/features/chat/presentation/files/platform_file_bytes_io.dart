import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<List<int>?> readPlatformFileBytes(PlatformFile file) async {
  if (file.bytes != null && file.bytes!.isNotEmpty) {
    return file.bytes!;
  }
  final path = file.path;
  if (path == null || path.isEmpty) return null;
  return File(path).readAsBytes();
}
