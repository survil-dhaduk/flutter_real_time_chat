/// Centralized route names for the application
class RouteNames {
  // Authentication routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Chat routes
  static const String chatRoomsList = '/chat-rooms';
  static const String createChatRoom = '/create-chat-room';
  static const String chat = '/chat';

  // Deep linking patterns
  static const String chatDeepLink = '/chat/:roomId';

  /// Generate chat room route with parameters
  static String chatRoom(String roomId) => '/chat?roomId=$roomId';

  /// Extract room ID from deep link
  static String? extractRoomIdFromPath(String path) {
    final uri = Uri.parse(path);
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'chat') {
      return uri.pathSegments[1];
    }
    return uri.queryParameters['roomId'];
  }
}
