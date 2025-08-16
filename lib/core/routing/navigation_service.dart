import 'package:flutter/material.dart';

import 'route_names.dart';
import 'route_guard.dart';

/// Service for handling navigation throughout the app
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Get the current context
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Navigate to a named route
  static Future<T?> navigateTo<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    final context = currentContext;
    if (context == null) return Future.value(null);

    return RouteGuard.navigateTo<T>(context, routeName, arguments: arguments);
  }

  /// Replace current route
  static Future<T?> navigateAndReplace<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    final context = currentContext;
    if (context == null) return Future.value(null);

    return RouteGuard.navigateAndReplace<T, TO>(
      context,
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  /// Clear navigation stack and navigate
  static Future<T?> navigateAndClearStack<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    final context = currentContext;
    if (context == null) return Future.value(null);

    return RouteGuard.navigateAndClearStack<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Go back
  static void goBack<T extends Object?>([T? result]) {
    final context = currentContext;
    if (context == null) return;

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }

  /// Navigate to chat room
  static Future<void> navigateToChatRoom(String roomId, String roomName) {
    return navigateTo(
      RouteNames.chat,
      arguments: {
        'roomId': roomId,
        'roomName': roomName,
      },
    );
  }

  /// Navigate to login
  static Future<void> navigateToLogin() {
    return navigateAndClearStack(RouteNames.login);
  }

  /// Navigate to chat rooms list
  static Future<void> navigateToChatRoomsList() {
    return navigateAndClearStack(RouteNames.chatRoomsList);
  }

  /// Navigate to register
  static Future<void> navigateToRegister() {
    return navigateTo(RouteNames.register);
  }

  /// Navigate to create chat room
  static Future<void> navigateToCreateChatRoom() {
    return navigateTo(RouteNames.createChatRoom);
  }

  /// Handle deep link
  static Future<void> handleDeepLink(String link) {
    final uri = Uri.parse(link);
    final path = uri.path;

    // Handle chat room deep links
    if (path.startsWith('/chat')) {
      final roomId = RouteNames.extractRoomIdFromPath(link);
      if (roomId != null) {
        return navigateToChatRoom(roomId, 'Chat Room');
      }
    }

    // Handle other deep links
    switch (path) {
      case RouteNames.login:
        return navigateToLogin();
      case RouteNames.register:
        return navigateToRegister();
      case RouteNames.chatRoomsList:
        return navigateToChatRoomsList();
      case RouteNames.createChatRoom:
        return navigateToCreateChatRoom();
      default:
        // Default to splash if deep link is not recognized
        return navigateAndClearStack(RouteNames.splash);
    }
  }

  /// Handle initial route based on authentication state
  static Future<void> handleInitialRoute(bool isAuthenticated,
      {String? deepLink}) {
    if (deepLink != null && deepLink.isNotEmpty) {
      // Handle deep link if provided
      return handleDeepLink(deepLink);
    }

    // Default routing based on authentication state
    if (isAuthenticated) {
      return navigateToChatRoomsList();
    } else {
      return navigateToLogin();
    }
  }
}
