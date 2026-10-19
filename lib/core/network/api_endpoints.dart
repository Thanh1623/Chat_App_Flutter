/// Path Nest API — chỉnh cho khớp repo BE của bạn.
abstract final class ApiEndpoints {
  static const authLogin = '/auth/login';
  static const authLogout = '/auth/logout';
  static const authMe = '/auth/me';
  static const authMeAvatar = '/auth/me/avatar';

  static const conversations = '/rooms';
  static const inboxSearch = '/rooms/search';
  static String conversationMessages(String id) => '/rooms/$id/messages';
  static String roomImages(String roomId) => '/rooms/$roomId/images';
  static String roomFiles(String roomId) => '/rooms/$roomId/files';
  static String roomLinks(String roomId) => '/rooms/$roomId/links';
  static String markRoomRead(String roomId) => '/rooms/$roomId/read';
  static String roomReads(String roomId) => '/rooms/$roomId/reads';

  static const health = '/health';

  static const users = '/users';
  static String user(String id) => '/users/$id';
  static String roomMembers(String roomId) => '/rooms/$roomId/members';
  static String roomMember(String roomId, String userId) =>
      '/rooms/$roomId/members/$userId';
  static const roomsDirect = '/rooms/direct';
  static const createRoom = '/rooms'; // POST
  static String deleteRoom(String id) => '/rooms/$id';
  static String roomSettings(String roomId) => '/rooms/$roomId/settings';
  static String roomAvatar(String roomId) => '/rooms/$roomId/avatar';

  /// đây là API để pin một tin nhắn trong phòng chat
  static String pinMessage(String roomId, String messageId) =>
      '/rooms/$roomId/messages/$messageId/pin';

  /// đây là API để lấy danh sách các tin nhắn đã được pin trong phòng chat
  static String roomPins(String roomId) => '/rooms/$roomId/pins';
  static String messageReactions(String roomId, String messageId) =>
      '/rooms/$roomId/messages/$messageId/reactions';
  static String recallMessage(String roomId, String messageId) =>
      '/rooms/$roomId/messages/$messageId/recall';
  static String hideMessage(String roomId, String messageId) =>
      '/rooms/$roomId/messages/$messageId';
}
