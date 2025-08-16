import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import 'app_route_observer.dart';
import 'deep_link_handler.dart';
import 'navigation_service.dart';
import 'route_names.dart';

/// Middleware for handling navigation based on authentication state changes
class NavigationMiddleware {
  static bool _isInitialized = false;
  static late BuildContext _context;

  /// Initialize the navigation middleware
  static void initialize(BuildContext context) {
    if (_isInitialized) return;

    _context = context;
    _isInitialized = true;

    // Listen to authentication state changes
    _listenToAuthChanges();
  }

  /// Listen to authentication state changes and handle navigation
  static void _listenToAuthChanges() {
    final authBloc = _context.read<AuthBloc>();

    authBloc.stream.listen((authState) {
      _handleAuthStateChange(authState);
    });
  }

  /// Handle authentication state changes
  static void _handleAuthStateChange(AuthState authState) {
    final routeObserver = AppRouteObserver();
    final currentRoute = routeObserver.currentRouteName;

    if (currentRoute == null) return;

    switch (authState) {
      case AuthAuthenticated():
        _handleAuthenticatedState(currentRoute);
        break;
      case AuthUnauthenticated():
        _handleUnauthenticatedState(currentRoute);
        break;
      case AuthError():
        _handleAuthErrorState(currentRoute);
        break;
      default:
        // Do nothing for loading or initial states
        break;
    }
  }

  /// Handle navigation when user becomes authenticated
  static void _handleAuthenticatedState(String currentRoute) {
    // If user is on auth routes, redirect to main app
    if (RouteNames.shouldRedirectAuthenticated(currentRoute)) {
      // Check if there's a pending deep link
      if (DeepLinkHandler.hasPendingDeepLink()) {
        final deepLink = DeepLinkHandler.getPendingDeepLink();
        if (deepLink != null) {
          NavigationService.handleDeepLink(deepLink);
          return;
        }
      }

      // Default to chat rooms list
      NavigationService.navigateToChatRoomsList();
    }
  }

  /// Handle navigation when user becomes unauthenticated
  static void _handleUnauthenticatedState(String currentRoute) {
    // If user is on protected routes, redirect to login
    if (RouteNames.requiresAuthentication(currentRoute)) {
      NavigationService.navigateToLogin();
    }
  }

  /// Handle navigation when authentication error occurs
  static void _handleAuthErrorState(String currentRoute) {
    // For auth errors, redirect to login unless already there
    if (currentRoute != RouteNames.login && currentRoute != RouteNames.splash) {
      NavigationService.navigateToLogin();
    }
  }

  /// Handle app resume with potential deep link
  static Future<void> handleAppResume({String? deepLink}) async {
    if (deepLink != null && deepLink.isNotEmpty) {
      await DeepLinkHandler.processDeepLink(deepLink);
    } else {
      // Restore any pending deep links
      await DeepLinkHandler.restoreAppState();
    }
  }

  /// Handle app launch with potential deep link
  static Future<void> handleAppLaunch({String? deepLink}) async {
    if (deepLink != null && deepLink.isNotEmpty) {
      await DeepLinkHandler.processDeepLink(deepLink);
    }
  }

  /// Check if navigation is allowed for the given route
  static bool canNavigateToRoute(String routeName) {
    final authBloc = _context.read<AuthBloc>();
    final authState = authBloc.state;

    // Always allow navigation to splash and error routes
    if (routeName == RouteNames.splash || routeName.startsWith('/error')) {
      return true;
    }

    // Check authentication requirements
    if (RouteNames.requiresAuthentication(routeName)) {
      return authState is AuthAuthenticated;
    }

    // Check if authenticated users should be redirected
    if (RouteNames.shouldRedirectAuthenticated(routeName)) {
      return authState is! AuthAuthenticated;
    }

    // Allow navigation to other routes
    return true;
  }

  /// Get appropriate route based on authentication state
  static String getAppropriateRoute() {
    final authBloc = _context.read<AuthBloc>();
    final authState = authBloc.state;

    switch (authState) {
      case AuthAuthenticated():
        return RouteNames.chatRoomsList;
      case AuthUnauthenticated():
      case AuthError():
        return RouteNames.login;
      default:
        return RouteNames.splash;
    }
  }
}
