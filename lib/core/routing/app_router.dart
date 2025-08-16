import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../injection/injection.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/pages.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/chat/presentation/bloc/chat_event.dart';
import '../../features/chat/presentation/pages/pages.dart';
import 'route_names.dart';
import 'splash_page.dart';

/// Central router for the application
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Handle deep linking for chat rooms
    final routeName = settings.name ?? '';

    // Check for deep link patterns
    if (routeName.startsWith('/chat/') && routeName != '/chat') {
      return _handleChatDeepLink(routeName);
    }

    switch (settings.name) {
      case RouteNames.splash:
        final args = settings.arguments as Map<String, dynamic>?;
        final deepLink = args?['deepLink'] as String?;

        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => sl<AuthBloc>()..add(const CheckAuthStatus()),
            child: SplashPage(deepLink: deepLink),
          ),
          settings: settings,
        );

      case RouteNames.login:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => sl<AuthBloc>(),
            child: const LoginPage(),
          ),
          settings: settings,
        );

      case RouteNames.register:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => sl<AuthBloc>(),
            child: const RegisterPage(),
          ),
          settings: settings,
        );

      case RouteNames.chatRoomsList:
        return _createAuthenticatedRoute(
          settings,
          const ChatRoomsListPage(),
          additionalProviders: [
            BlocProvider(
              create: (context) => sl<ChatBloc>()..add(const LoadChatRooms()),
            ),
          ],
        );

      case RouteNames.createChatRoom:
        return _createAuthenticatedRoute(
          settings,
          const CreateChatRoomPage(),
          additionalProviders: [
            BlocProvider(
              create: (context) => sl<ChatBloc>(),
            ),
          ],
        );

      case RouteNames.chat:
        final args = settings.arguments as Map<String, dynamic>?;
        final roomId = args?['roomId'] as String?;
        final roomName = args?['roomName'] as String?;

        if (roomId == null) {
          return _errorRoute('Room ID is required');
        }

        return _createChatRoute(settings, roomId, roomName);

      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  /// Handle deep linking for chat rooms
  static Route<dynamic> _handleChatDeepLink(String routeName) {
    final roomId = RouteNames.extractRoomIdFromPath(routeName);

    if (roomId == null) {
      return _errorRoute('Invalid chat room link');
    }

    final settings = RouteSettings(
      name: RouteNames.chat,
      arguments: {
        'roomId': roomId,
        'roomName': 'Chat Room',
      },
    );

    return _createChatRoute(settings, roomId, 'Chat Room');
  }

  /// Create an authenticated route with proper BLoC providers
  static Route<dynamic> _createAuthenticatedRoute(
    RouteSettings settings,
    Widget child, {
    List<BlocProvider> additionalProviders = const [],
  }) {
    return MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => sl<AuthBloc>(),
          ),
          ...additionalProviders,
        ],
        child: child,
      ),
      settings: settings,
    );
  }

  /// Create a chat route with proper initialization
  static Route<dynamic> _createChatRoute(
    RouteSettings settings,
    String roomId,
    String? roomName,
  ) {
    return MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => sl<AuthBloc>(),
          ),
          BlocProvider(
            create: (context) => sl<ChatBloc>()
              ..add(JoinChatRoom(roomId: roomId))
              ..add(LoadMessages(roomId: roomId)),
          ),
        ],
        child: ChatPage(
          roomId: roomId,
          roomName: roomName ?? 'Chat Room',
        ),
      ),
      settings: settings,
    );
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Navigation Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  RouteNames.splash,
                  (route) => false,
                ),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
