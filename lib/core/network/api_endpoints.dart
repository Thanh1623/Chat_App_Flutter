/// Path Nest API — chỉnh cho khớp repo BE của bạn.
abstract final class ApiEndpoints {
  static const authLogin = '/auth/login';
  static const authLogout = '/auth/logout';
  static const authMe = '/auth/me';
  static const authMeAvatar = '/auth/me/avatar';

  static const conversations = '/rooms';
  static String conversationMessages(String id) => '/rooms/$id/messages';
  static String roomImages(String roomId) => '/rooms/$roomId/images';
  static String roomFiles(String roomId) => '/rooms/$roomId/files';
  static String markRoomRead(String roomId) => '/rooms/$roomId/read';

  static const health = '/health';

  static const users = '/users';
  static const roomsDirect = '/rooms/direct';
  static const createRoom = '/rooms'; // POST
  static String deleteRoom(String id) => '/rooms/$id';
}
