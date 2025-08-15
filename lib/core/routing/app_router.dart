import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../injection/injection.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/pages.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/chat/presentation/pages/pages.dart';
import 'route_names.dart';
import 'splash_page.dart';

/// Central router for the application
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => sl<AuthBloc>()..add(const CheckAuthStatus()),
            child: const SplashPage(),
          ),
        );

      case RouteNames.login:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => sl<AuthBloc>(),
            child: const LoginPage(),
          ),
        );

      case RouteNames.register:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => sl<AuthBloc>(),
            child: const RegisterPage(),
          ),
        );

      case RouteNames.chatRoomsList:
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => sl<AuthBloc>(),
              ),
              BlocProvider(
                create: (context) => sl<ChatBloc>()..add(LoadChatRooms()),
              ),
            ],
            child: const ChatRoomsListPage(),
          ),
        );

      case RouteNames.createChatRoom:
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => sl<AuthBloc>(),
              ),
              BlocProvider(
                create: (context) => sl<ChatBloc>(),
              ),
            ],
            child: const CreateChatRoomPage(),
          ),
        );

      case RouteNames.chat:
        final args = settings.arguments as Map<String, dynamic>?;
        final roomId = args?['roomId'] as String?;
        final roomName = args?['roomName'] as String?;

        if (roomId == null) {
          return _errorRoute('Room ID is required');
        }

        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => sl<AuthBloc>(),
              ),
              BlocProvider(
                create: (context) => sl<ChatBloc>()
                  ..add(JoinChatRoom(roomId))
                  ..add(LoadMessages(roomId)),
              ),
            ],
            child: ChatPage(
              roomId: roomId,
              roomName: roomName ?? 'Chat Room',
            ),
          ),
        );

      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
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
