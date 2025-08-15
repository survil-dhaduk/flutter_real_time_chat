import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_spacing.dart';

/// Chat-specific theme extensions
class ChatTheme extends ThemeExtension<ChatTheme> {
  const ChatTheme({
    required this.sentMessageBubbleColor,
    required this.onSentMessageBubbleColor,
    required this.receivedMessageBubbleColor,
    required this.onReceivedMessageBubbleColor,
    required this.messageTimestampColor,
    required this.senderNameColor,
    required this.onlineStatusColor,
    required this.offlineStatusColor,
    required this.typingIndicatorColor,
    required this.messageSentStatusColor,
    required this.messageDeliveredStatusColor,
    required this.messageReadStatusColor,
    required this.chatInputBackgroundColor,
    required this.chatInputBorderColor,
    required this.chatRoomItemBackgroundColor,
    required this.chatRoomItemSelectedColor,
    required this.messageBubbleRadius,
    required this.messageBubblePadding,
    required this.messageBubbleMargin,
    required this.messageSpacing,
    required this.avatarSize,
    required this.messageTextStyle,
    required this.messageTimestampStyle,
    required this.senderNameStyle,
    required this.chatRoomTitleStyle,
    required this.chatRoomSubtitleStyle,
  });

  final Color sentMessageBubbleColor;
  final Color onSentMessageBubbleColor;
  final Color receivedMessageBubbleColor;
  final Color onReceivedMessageBubbleColor;
  final Color messageTimestampColor;
  final Color senderNameColor;
  final Color onlineStatusColor;
  final Color offlineStatusColor;
  final Color typingIndicatorColor;
  final Color messageSentStatusColor;
  final Color messageDeliveredStatusColor;
  final Color messageReadStatusColor;
  final Color chatInputBackgroundColor;
  final Color chatInputBorderColor;
  final Color chatRoomItemBackgroundColor;
  final Color chatRoomItemSelectedColor;
  final double messageBubbleRadius;
  final EdgeInsets messageBubblePadding;
  final EdgeInsets messageBubbleMargin;
  final double messageSpacing;
  final double avatarSize;
  final TextStyle messageTextStyle;
  final TextStyle messageTimestampStyle;
  final TextStyle senderNameStyle;
  final TextStyle chatRoomTitleStyle;
  final TextStyle chatRoomSubtitleStyle;

  /// Light theme configuration
  static ChatTheme light(ColorScheme colorScheme) {
    return ChatTheme(
      sentMessageBubbleColor: AppColors.sentMessageBubble,
      onSentMessageBubbleColor: AppColors.onSentMessageBubble,
      receivedMessageBubbleColor: AppColors.receivedMessageBubble,
      onReceivedMessageBubbleColor: AppColors.onReceivedMessageBubble,
      messageTimestampColor: colorScheme.onSurfaceVariant,
      senderNameColor: colorScheme.primary,
      onlineStatusColor: AppColors.onlineStatus,
      offlineStatusColor: AppColors.offlineStatus,
      typingIndicatorColor: AppColors.typingIndicator,
      messageSentStatusColor: AppColors.messageSent,
      messageDeliveredStatusColor: AppColors.messageDelivered,
      messageReadStatusColor: AppColors.messageRead,
      chatInputBackgroundColor: colorScheme.surface,
      chatInputBorderColor: colorScheme.outline,
      chatRoomItemBackgroundColor: colorScheme.surface,
      chatRoomItemSelectedColor: colorScheme.primaryContainer,
      messageBubbleRadius: AppSpacing.messageBubbleRadius,
      messageBubblePadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      messageBubbleMargin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      messageSpacing: AppSpacing.messageSpacing,
      avatarSize: AppSpacing.avatarMd,
      messageTextStyle: AppTypography.messageText.copyWith(
        color: AppColors.onSentMessageBubble,
      ),
      messageTimestampStyle: AppTypography.messageTimestamp.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      senderNameStyle: AppTypography.senderName.copyWith(
        color: colorScheme.primary,
      ),
      chatRoomTitleStyle: AppTypography.chatRoomTitle.copyWith(
        color: colorScheme.onSurface,
      ),
      chatRoomSubtitleStyle: AppTypography.chatRoomSubtitle.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Dark theme configuration
  static ChatTheme dark(ColorScheme colorScheme) {
    return ChatTheme(
      sentMessageBubbleColor: AppColors.sentMessageBubbleDark,
      onSentMessageBubbleColor: AppColors.onSentMessageBubbleDark,
      receivedMessageBubbleColor: AppColors.receivedMessageBubbleDark,
      onReceivedMessageBubbleColor: AppColors.onReceivedMessageBubbleDark,
      messageTimestampColor: colorScheme.onSurfaceVariant,
      senderNameColor: colorScheme.primary,
      onlineStatusColor: AppColors.onlineStatus,
      offlineStatusColor: AppColors.offlineStatus,
      typingIndicatorColor: AppColors.typingIndicator,
      messageSentStatusColor: AppColors.messageSent,
      messageDeliveredStatusColor: AppColors.messageDelivered,
      messageReadStatusColor: AppColors.messageRead,
      chatInputBackgroundColor: colorScheme.surface,
      chatInputBorderColor: colorScheme.outline,
      chatRoomItemBackgroundColor: colorScheme.surface,
      chatRoomItemSelectedColor: colorScheme.primaryContainer,
      messageBubbleRadius: AppSpacing.messageBubbleRadius,
      messageBubblePadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      messageBubbleMargin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      messageSpacing: AppSpacing.messageSpacing,
      avatarSize: AppSpacing.avatarMd,
      messageTextStyle: AppTypography.messageText.copyWith(
        color: AppColors.onSentMessageBubbleDark,
      ),
      messageTimestampStyle: AppTypography.messageTimestamp.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      senderNameStyle: AppTypography.senderName.copyWith(
        color: colorScheme.primary,
      ),
      chatRoomTitleStyle: AppTypography.chatRoomTitle.copyWith(
        color: colorScheme.onSurface,
      ),
      chatRoomSubtitleStyle: AppTypography.chatRoomSubtitle.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  @override
  ChatTheme copyWith({
    Color? sentMessageBubbleColor,
    Color? onSentMessageBubbleColor,
    Color? receivedMessageBubbleColor,
    Color? onReceivedMessageBubbleColor,
    Color? messageTimestampColor,
    Color? senderNameColor,
    Color? onlineStatusColor,
    Color? offlineStatusColor,
    Color? typingIndicatorColor,
    Color? messageSentStatusColor,
    Color? messageDeliveredStatusColor,
    Color? messageReadStatusColor,
    Color? chatInputBackgroundColor,
    Color? chatInputBorderColor,
    Color? chatRoomItemBackgroundColor,
    Color? chatRoomItemSelectedColor,
    double? messageBubbleRadius,
    EdgeInsets? messageBubblePadding,
    EdgeInsets? messageBubbleMargin,
    double? messageSpacing,
    double? avatarSize,
    TextStyle? messageTextStyle,
    TextStyle? messageTimestampStyle,
    TextStyle? senderNameStyle,
    TextStyle? chatRoomTitleStyle,
    TextStyle? chatRoomSubtitleStyle,
  }) {
    return ChatTheme(
      sentMessageBubbleColor:
          sentMessageBubbleColor ?? this.sentMessageBubbleColor,
      onSentMessageBubbleColor:
          onSentMessageBubbleColor ?? this.onSentMessageBubbleColor,
      receivedMessageBubbleColor:
          receivedMessageBubbleColor ?? this.receivedMessageBubbleColor,
      onReceivedMessageBubbleColor:
          onReceivedMessageBubbleColor ?? this.onReceivedMessageBubbleColor,
      messageTimestampColor:
          messageTimestampColor ?? this.messageTimestampColor,
      senderNameColor: senderNameColor ?? this.senderNameColor,
      onlineStatusColor: onlineStatusColor ?? this.onlineStatusColor,
      offlineStatusColor: offlineStatusColor ?? this.offlineStatusColor,
      typingIndicatorColor: typingIndicatorColor ?? this.typingIndicatorColor,
      messageSentStatusColor:
          messageSentStatusColor ?? this.messageSentStatusColor,
      messageDeliveredStatusColor:
          messageDeliveredStatusColor ?? this.messageDeliveredStatusColor,
      messageReadStatusColor:
          messageReadStatusColor ?? this.messageReadStatusColor,
      chatInputBackgroundColor:
          chatInputBackgroundColor ?? this.chatInputBackgroundColor,
      chatInputBorderColor: chatInputBorderColor ?? this.chatInputBorderColor,
      chatRoomItemBackgroundColor:
          chatRoomItemBackgroundColor ?? this.chatRoomItemBackgroundColor,
      chatRoomItemSelectedColor:
          chatRoomItemSelectedColor ?? this.chatRoomItemSelectedColor,
      messageBubbleRadius: messageBubbleRadius ?? this.messageBubbleRadius,
      messageBubblePadding: messageBubblePadding ?? this.messageBubblePadding,
      messageBubbleMargin: messageBubbleMargin ?? this.messageBubbleMargin,
      messageSpacing: messageSpacing ?? this.messageSpacing,
      avatarSize: avatarSize ?? this.avatarSize,
      messageTextStyle: messageTextStyle ?? this.messageTextStyle,
      messageTimestampStyle:
          messageTimestampStyle ?? this.messageTimestampStyle,
      senderNameStyle: senderNameStyle ?? this.senderNameStyle,
      chatRoomTitleStyle: chatRoomTitleStyle ?? this.chatRoomTitleStyle,
      chatRoomSubtitleStyle:
          chatRoomSubtitleStyle ?? this.chatRoomSubtitleStyle,
    );
  }

  @override
  ChatTheme lerp(ThemeExtension<ChatTheme>? other, double t) {
    if (other is! ChatTheme) {
      return this;
    }

    return ChatTheme(
      sentMessageBubbleColor:
          Color.lerp(sentMessageBubbleColor, other.sentMessageBubbleColor, t)!,
      onSentMessageBubbleColor: Color.lerp(
          onSentMessageBubbleColor, other.onSentMessageBubbleColor, t)!,
      receivedMessageBubbleColor: Color.lerp(
          receivedMessageBubbleColor, other.receivedMessageBubbleColor, t)!,
      onReceivedMessageBubbleColor: Color.lerp(
          onReceivedMessageBubbleColor, other.onReceivedMessageBubbleColor, t)!,
      messageTimestampColor:
          Color.lerp(messageTimestampColor, other.messageTimestampColor, t)!,
      senderNameColor: Color.lerp(senderNameColor, other.senderNameColor, t)!,
      onlineStatusColor:
          Color.lerp(onlineStatusColor, other.onlineStatusColor, t)!,
      offlineStatusColor:
          Color.lerp(offlineStatusColor, other.offlineStatusColor, t)!,
      typingIndicatorColor:
          Color.lerp(typingIndicatorColor, other.typingIndicatorColor, t)!,
      messageSentStatusColor:
          Color.lerp(messageSentStatusColor, other.messageSentStatusColor, t)!,
      messageDeliveredStatusColor: Color.lerp(
          messageDeliveredStatusColor, other.messageDeliveredStatusColor, t)!,
      messageReadStatusColor:
          Color.lerp(messageReadStatusColor, other.messageReadStatusColor, t)!,
      chatInputBackgroundColor: Color.lerp(
          chatInputBackgroundColor, other.chatInputBackgroundColor, t)!,
      chatInputBorderColor:
          Color.lerp(chatInputBorderColor, other.chatInputBorderColor, t)!,
      chatRoomItemBackgroundColor: Color.lerp(
          chatRoomItemBackgroundColor, other.chatRoomItemBackgroundColor, t)!,
      chatRoomItemSelectedColor: Color.lerp(
          chatRoomItemSelectedColor, other.chatRoomItemSelectedColor, t)!,
      messageBubbleRadius:
          t < 0.5 ? messageBubbleRadius : other.messageBubbleRadius,
      messageBubblePadding:
          EdgeInsets.lerp(messageBubblePadding, other.messageBubblePadding, t)!,
      messageBubbleMargin:
          EdgeInsets.lerp(messageBubbleMargin, other.messageBubbleMargin, t)!,
      messageSpacing: t < 0.5 ? messageSpacing : other.messageSpacing,
      avatarSize: t < 0.5 ? avatarSize : other.avatarSize,
      messageTextStyle:
          TextStyle.lerp(messageTextStyle, other.messageTextStyle, t)!,
      messageTimestampStyle: TextStyle.lerp(
          messageTimestampStyle, other.messageTimestampStyle, t)!,
      senderNameStyle:
          TextStyle.lerp(senderNameStyle, other.senderNameStyle, t)!,
      chatRoomTitleStyle:
          TextStyle.lerp(chatRoomTitleStyle, other.chatRoomTitleStyle, t)!,
      chatRoomSubtitleStyle: TextStyle.lerp(
          chatRoomSubtitleStyle, other.chatRoomSubtitleStyle, t)!,
    );
  }
}

/// Extension to easily access ChatTheme from BuildContext
extension ChatThemeExtension on BuildContext {
  ChatTheme get chatTheme => Theme.of(this).extension<ChatTheme>()!;
}
