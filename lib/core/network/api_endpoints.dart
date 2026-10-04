/// Path Nest API — chỉnh cho khớp repo BE của bạn.
abstract final class ApiEndpoints {
  static const authLogin = '/auth/login';
  static const authLogout = '/auth/logout';
  static const authMe = '/auth/me';

  static const conversations = '/conversations';
  static String conversationMessages(String id) => '/conversations/$id/messages';
}
