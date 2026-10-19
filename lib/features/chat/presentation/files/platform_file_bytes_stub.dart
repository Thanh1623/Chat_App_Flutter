import 'package:file_picker/file_picker.dart';

Future<List<int>?> readPlatformFileBytes(PlatformFile file) async {
  if (file.bytes != null && file.bytes!.isNotEmpty) {
    return file.bytes;
  }
  return null;
}
