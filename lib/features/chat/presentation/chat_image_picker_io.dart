import 'package:chat_app/features/chat/presentation/chat_image_picker_common.dart';
import 'package:image_picker/image_picker.dart';

Future<List<XFile>> pickChatImageFiles() async {
  final files = await ImagePicker().pickMultiImage(
    limit: kMaxChatImagesPerSend,
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 85,
  );
  if (files.length <= kMaxChatImagesPerSend) return files;
  return files.sublist(0, kMaxChatImagesPerSend);
}
