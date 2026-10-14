import 'package:image_picker/image_picker.dart';

Future<XFile?> pickProfileImageFile() {
  return ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 85,
  );
}
