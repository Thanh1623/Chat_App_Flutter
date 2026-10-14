abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const contacts = '/contacts';
  static const profile = '/me';
  static const editProfile = '/me/edit';
  static const chat = '/chat/:conversationId';
  static const settings = '/me';
  static const newChat = '/new-chat';

  static String chatPath(String conversationId) => '/chat/$conversationId';
}
