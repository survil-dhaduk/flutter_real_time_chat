import 'package:flutter/material.dart';

import 'navigation_service.dart';
import 'route_names.dart';

/// Service for handling deep links and app state restoration
class DeepLinkHandler {
  static String? _pendingDeepLink;

  /// Initialize deep link handling
  static void initialize() {
    // Listen for incoming links when app is already running
    _listenForIncomingLinks();

    // Handle initial link when app is launched from a deep link
    _handleInitialLink();
  }

  /// Handle initial deep link when app is launched
  static Future<void> _handleInitialLink() async {
    try {
      final initialLink = await _getInitialLink();
      if (initialLink != null && initialLink.isNotEmpty) {
        _pendingDeepLink = initialLink;
      }
    } catch (e) {
      debugPrint('Error handling initial link: $e');
    }
  }

  /// Listen for incoming deep links while app is running
  static void _listenForIncomingLinks() {
    // This would typically use a package like uni_links or app_links
    // For now, we'll implement a basic structure
    debugPrint('Deep link listener initialized');
  }

  /// Get the initial deep link (mock implementation)
  static Future<String?> _getInitialLink() async {
    // This would typically use platform channels or a deep linking package
    // For now, return null as we don't have actual deep linking setup
    return null;
  }

  /// Process a deep link
  static Future<void> processDeepLink(String link) async {
    final uri = Uri.parse(link);

    debugPrint('Processing deep link: $link');

    // Validate the deep link format
    if (!_isValidDeepLink(uri)) {
      debugPrint('Invalid deep link format: $link');
      return;
    }

    // Store the deep link for later processing if needed
    _pendingDeepLink = link;

    // Handle the deep link based on current app state
    await NavigationService.handleDeepLink(link);
  }

  /// Check if a deep link is valid
  static bool _isValidDeepLink(Uri uri) {
    // Check if the scheme and host are valid for our app
    // For now, we'll accept any path-based routing
    return uri.path.isNotEmpty;
  }

  /// Get pending deep link and clear it
  static String? getPendingDeepLink() {
    final link = _pendingDeepLink;
    _pendingDeepLink = null;
    return link;
  }

  /// Check if there's a pending deep link
  static bool hasPendingDeepLink() {
    return _pendingDeepLink != null && _pendingDeepLink!.isNotEmpty;
  }

  /// Clear pending deep link
  static void clearPendingDeepLink() {
    _pendingDeepLink = null;
  }

  /// Generate shareable deep link for a chat room
  static String generateChatRoomLink(String roomId) {
    // In a real app, this would generate a proper deep link URL
    // For now, return the internal route format
    return RouteNames.chatRoomDeepLink(roomId);
  }

  /// Extract room information from a chat deep link
  static Map<String, String>? extractChatRoomInfo(String link) {
    final roomId = RouteNames.extractRoomIdFromPath(link);
    if (roomId != null) {
      return {
        'roomId': roomId,
        'roomName': 'Chat Room', // Default name, could be enhanced
      };
    }
    return null;
  }

  /// Handle app state restoration
  static Future<void> restoreAppState() async {
    if (hasPendingDeepLink()) {
      final link = getPendingDeepLink();
      if (link != null) {
        await processDeepLink(link);
      }
    }
  }
}
