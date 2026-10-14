import 'package:dio/dio.dart';

DioMediaType? imageMediaTypeFromFilename(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return DioMediaType('image', 'png');
  if (lower.endsWith('.gif')) return DioMediaType('image', 'gif');
  if (lower.endsWith('.webp')) return DioMediaType('image', 'webp');
  if (lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      !lower.contains('.')) {
    return DioMediaType('image', 'jpeg');
  }
  return null;
}
