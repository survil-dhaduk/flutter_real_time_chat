import 'package:flutter/material.dart';

/// Application color constants following Material Design 3 guidelines
class AppColors {
  // Prevent instantiation
  AppColors._();

  // Material Design 3 Primary Colors
  static const Color primary = Color(0xFF1976D2);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD3E3FD);
  static const Color onPrimaryContainer = Color(0xFF001C38);

  // Material Design 3 Secondary Colors
  static const Color secondary = Color(0xFF545F70);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD7E3F7);
  static const Color onSecondaryContainer = Color(0xFF111C2B);

  // Material Design 3 Tertiary Colors
  static const Color tertiary = Color(0xFF6F5675);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFF8D8FD);
  static const Color onTertiaryContainer = Color(0xFF28132E);

  // Material Design 3 Error Colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  // Material Design 3 Surface Colors (Light Theme)
  static const Color surface = Color(0xFFFEFBFF);
  static const Color onSurface = Color(0xFF1B1B1F);
  static const Color surfaceVariant = Color(0xFFE1E2EC);
  static const Color onSurfaceVariant = Color(0xFF44474F);
  static const Color surfaceContainerHighest = Color(0xFFE6E1E5);
  static const Color surfaceContainerHigh = Color(0xFFECE6EA);
  static const Color surfaceContainer = Color(0xFFF2ECF0);
  static const Color surfaceContainerLow = Color(0xFFF7F2F6);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  // Material Design 3 Surface Colors (Dark Theme)
  static const Color surfaceDark = Color(0xFF131316);
  static const Color onSurfaceDark = Color(0xFFE4E1E6);
  static const Color surfaceVariantDark = Color(0xFF44474F);
  static const Color onSurfaceVariantDark = Color(0xFFC4C6D0);
  static const Color surfaceContainerHighestDark = Color(0xFF36343B);
  static const Color surfaceContainerHighDark = Color(0xFF2B2930);
  static const Color surfaceContainerDark = Color(0xFF211F26);
  static const Color surfaceContainerLowDark = Color(0xFF1B1B1F);
  static const Color surfaceContainerLowestDark = Color(0xFF0E0E11);

  // Material Design 3 Outline Colors
  static const Color outline = Color(0xFF74777F);
  static const Color outlineVariant = Color(0xFFC4C6D0);
  static const Color outlineDark = Color(0xFF8E9099);
  static const Color outlineVariantDark = Color(0xFF44474F);

  // Chat-specific Colors
  static const Color sentMessageBubble = Color(0xFF1976D2);
  static const Color onSentMessageBubble = Color(0xFFFFFFFF);
  static const Color receivedMessageBubble = Color(0xFFE1E2EC);
  static const Color onReceivedMessageBubble = Color(0xFF1B1B1F);

  static const Color sentMessageBubbleDark = Color(0xFF4285F4);
  static const Color onSentMessageBubbleDark = Color(0xFFFFFFFF);
  static const Color receivedMessageBubbleDark = Color(0xFF2B2930);
  static const Color onReceivedMessageBubbleDark = Color(0xFFE4E1E6);

  // Status Colors
  static const Color onlineStatus = Color(0xFF4CAF50);
  static const Color offlineStatus = Color(0xFF9E9E9E);
  static const Color typingIndicator = Color(0xFFFF9800);

  // Message Status Colors
  static const Color messageSent = Color(0xFF9E9E9E);
  static const Color messageDelivered = Color(0xFF2196F3);
  static const Color messageRead = Color(0xFF4CAF50);

  // Utility Colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF36343B);
  static const Color shadow = Color(0x1F000000);
  static const Color shadowDark = Color(0x3F000000);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Legacy colors for backward compatibility
  @Deprecated('Use primary instead')
  static const Color primaryDark = Color(0xFF1976D2);
  @Deprecated('Use primaryContainer instead')
  static const Color primaryLight = Color(0xFFBBDEFB);
  @Deprecated('Use secondary instead')
  static const Color secondaryDark = Color(0xFF018786);
  @Deprecated('Use surface instead')
  static const Color background = Color(0xFFF5F5F5);
  @Deprecated('Use onSurface instead')
  static const Color textPrimary = Color(0xFF212121);
  @Deprecated('Use onSurfaceVariant instead')
  static const Color textSecondary = Color(0xFF757575);
  @Deprecated('Use onSurfaceVariant instead')
  static const Color textHint = Color(0xFF9E9E9E);
  @Deprecated('Use onPrimary instead')
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  @Deprecated('Use sentMessageBubble instead')
  static const Color sentMessage = Color(0xFF2196F3);
  @Deprecated('Use receivedMessageBubble instead')
  static const Color receivedMessage = Color(0xFFE0E0E0);
}
