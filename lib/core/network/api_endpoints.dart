/// Path Nest API — chỉnh cho khớp repo BE của bạn.
abstract final class ApiEndpoints {
  static const authLogin = '/auth/login';
  static const authLogout = '/auth/logout';
  static const authMe = '/auth/me';

  static const conversations = '/rooms';
  static String conversationMessages(String id) => '/rooms/$id/messages';

  static const health = '/health';
}
