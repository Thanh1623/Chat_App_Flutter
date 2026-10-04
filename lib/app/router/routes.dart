abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const chat = '/chat/:conversationId';
  static const settings = '/settings';

  static String chatPath(String conversationId) => '/chat/$conversationId';
}
