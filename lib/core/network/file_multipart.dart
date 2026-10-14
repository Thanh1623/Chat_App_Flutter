import 'package:dio/dio.dart';

DioMediaType? fileMediaTypeFromFilename(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.pdf')) return DioMediaType('application', 'pdf');
  if (lower.endsWith('.doc')) return DioMediaType('application', 'msword');
  if (lower.endsWith('.docx')) {
    return DioMediaType(
      'application',
      'vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
  }
  if (lower.endsWith('.xls')) return DioMediaType('application', 'vnd.ms-excel');
  if (lower.endsWith('.xlsx')) {
    return DioMediaType(
      'application',
      'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }
  if (lower.endsWith('.ppt')) {
    return DioMediaType('application', 'vnd.ms-powerpoint');
  }
  if (lower.endsWith('.pptx')) {
    return DioMediaType(
      'application',
      'vnd.openxmlformats-officedocument.presentationml.presentation',
    );
  }
  if (lower.endsWith('.txt')) return DioMediaType('text', 'plain');
  if (lower.endsWith('.csv')) return DioMediaType('text', 'csv');
  if (lower.endsWith('.zip')) return DioMediaType('application', 'zip');
  return DioMediaType('application', 'octet-stream');
}
