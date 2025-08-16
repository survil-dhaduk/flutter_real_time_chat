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
  static const String chatWithRoomId = '/chat/room';

  /// Generate chat room route with parameters
  static String chatRoom(String roomId) => '/chat?roomId=$roomId';

  /// Generate deep link for chat room
  static String chatRoomDeepLink(String roomId) => '/chat/$roomId';

  /// Extract room ID from deep link
  static String? extractRoomIdFromPath(String path) {
    final uri = Uri.parse(path);

    // Handle /chat/roomId pattern
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'chat') {
      return uri.pathSegments[1];
    }

    // Handle /chat?roomId=roomId pattern
    if (uri.path == '/chat' && uri.queryParameters.containsKey('roomId')) {
      return uri.queryParameters['roomId'];
    }

    return null;
  }

  /// Check if route requires authentication
  static bool requiresAuthentication(String routeName) {
    const protectedRoutes = [
      chatRoomsList,
      createChatRoom,
      chat,
      chatWithRoomId,
    ];
    return protectedRoutes.contains(routeName);
  }

  /// Check if route should redirect authenticated users
  static bool shouldRedirectAuthenticated(String routeName) {
    const authRoutes = [login, register];
    return authRoutes.contains(routeName);
  }
}
