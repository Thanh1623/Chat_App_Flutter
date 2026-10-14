/// Giới hạn tệp mỗi lần gửi.
const kMaxChatFilesPerSend = 5;
const kMaxChatFileBytes = 10 * 1024 * 1024;

const kChatFileExtensions = [
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'ppt',
  'pptx',
  'txt',
  'csv',
  'zip',
];

bool isAllowedChatFileName(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0) return false;
  final ext = name.substring(dot + 1).toLowerCase();
  return kChatFileExtensions.contains(ext);
}
