import 'package:chat_app/features/chat/presentation/chat_file_picker_common.dart';
import 'package:file_picker/file_picker.dart';

Future<List<PlatformFile>> pickChatFiles() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: kChatFileExtensions,
    allowMultiple: true,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return [];

  final picked = <PlatformFile>[];
  for (final file in result.files) {
    if (picked.length >= kMaxChatFilesPerSend) break;
    if (file.size > kMaxChatFileBytes) continue;
    if (!isAllowedChatFileName(file.name)) continue;
    if (file.bytes == null && file.path == null) continue;
    picked.add(file);
  }
  return picked;
}
