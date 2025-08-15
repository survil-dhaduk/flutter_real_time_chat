import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import 'route_names.dart';

/// Route guard that checks authentication before allowing access to protected routes
class RouteGuard {
  /// Check if user is authenticated and redirect if necessary
  static bool checkAuthentication(BuildContext context, String routeName) {
    final authState = context.read<AuthBloc>().state;

    // List of routes that require authentication
    const protectedRoutes = [
      RouteNames.chatRoomsList,
      RouteNames.createChatRoom,
      RouteNames.chat,
    ];

    // List of routes that should redirect authenticated users
    const authRoutes = [
      RouteNames.login,
      RouteNames.register,
    ];

    if (protectedRoutes.contains(routeName)) {
      if (authState is! AuthAuthenticated) {
        // User is not authenticated, redirect to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            RouteNames.login,
            (route) => false,
          );
        });
        return false;
      }
    } else if (authRoutes.contains(routeName)) {
      if (authState is AuthAuthenticated) {
        // User is already authenticated, redirect to chat rooms
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            RouteNames.chatRoomsList,
            (route) => false,
          );
        });
        return false;
      }
    }

    return true;
  }

  /// Navigate to a route with authentication check
  static Future<T?> navigateTo<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    if (checkAuthentication(context, routeName)) {
      return Navigator.of(context)
          .pushNamed<T>(routeName, arguments: arguments);
    }
    return Future.value(null);
  }

  /// Replace current route with authentication check
  static Future<T?> navigateAndReplace<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    if (checkAuthentication(context, routeName)) {
      return Navigator.of(context).pushReplacementNamed<T, TO>(
        routeName,
        arguments: arguments,
        result: result,
      );
    }
    return Future.value(null);
  }

  /// Clear navigation stack and navigate to route
  static Future<T?> navigateAndClearStack<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    if (checkAuthentication(context, routeName)) {
      return Navigator.of(context).pushNamedAndRemoveUntil<T>(
        routeName,
        (route) => false,
        arguments: arguments,
      );
    }
    return Future.value(null);
  }
}
