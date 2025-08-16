import 'package:flutter/material.dart';

import 'route_names.dart';

/// Route observer to track navigation events and handle app state
class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  static final AppRouteObserver _instance = AppRouteObserver._internal();

  factory AppRouteObserver() => _instance;

  AppRouteObserver._internal();

  /// Current route name
  String? _currentRouteName;

  /// Get current route name
  String? get currentRouteName => _currentRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateCurrentRoute(route);
    _logNavigation('PUSH', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _updateCurrentRoute(previousRoute);
    _logNavigation('POP', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateCurrentRoute(newRoute);
    _logNavigation('REPLACE', newRoute, oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _updateCurrentRoute(previousRoute);
    _logNavigation('REMOVE', route, previousRoute);
  }

  /// Update current route tracking
  void _updateCurrentRoute(Route<dynamic>? route) {
    if (route?.settings.name != null) {
      _currentRouteName = route!.settings.name;
    }
  }

  /// Log navigation events for debugging
  void _logNavigation(
      String action, Route<dynamic>? route, Route<dynamic>? previousRoute) {
    debugPrint(
        'Navigation $action: ${route?.settings.name} (from: ${previousRoute?.settings.name})');
  }

  /// Check if current route requires authentication
  bool get currentRouteRequiresAuth {
    if (_currentRouteName == null) return false;
    return RouteNames.requiresAuthentication(_currentRouteName!);
  }

  /// Check if current route should redirect authenticated users
  bool get currentRouteShouldRedirectAuth {
    if (_currentRouteName == null) return false;
    return RouteNames.shouldRedirectAuthenticated(_currentRouteName!);
  }

  /// Get route history for debugging
  List<String> getRouteHistory() {
    // This would require maintaining a history list
    // For now, return current route
    return _currentRouteName != null ? [_currentRouteName!] : [];
  }
}
