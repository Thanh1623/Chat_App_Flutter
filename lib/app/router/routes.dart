abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const work = '/work';
  static const contacts = '/contacts';
  static const diary = '/diary';
  static const profile = '/me';
  static const editProfile = '/me/edit';
  static const employeeProfile = '/me/employee-profile';
  static const employeeProfileEdit = '/me/employee-profile/edit';
  static const chat = '/chat/:conversationId';
  static const settings = '/me';
  static const newChat = '/new-chat';
  static const userProfile = '/users/:userId';

  static String chatPath(String conversationId) => '/chat/$conversationId';

  static String userProfilePath(String userId) => '/users/$userId';
}
