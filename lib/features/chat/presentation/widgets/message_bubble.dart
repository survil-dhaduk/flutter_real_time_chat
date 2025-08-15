import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/message.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../../core/theme/chat_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import 'message_visibility_detector.dart';
import 'message_status_indicator.dart';

/// Widget that displays a message in a chat bubble with sender/receiver distinction
class MessageBubble extends StatelessWidget {
  final Message message;
  final User? sender;
  final bool isCurrentUser;
  final bool showTimestamp;
  final bool showSenderName;
  final List<String> roomParticipants;
  final VoidCallback? onTap;
  final VoidCallback? onVisible;

  const MessageBubble({
    super.key,
    required this.message,
    this.sender,
    required this.isCurrentUser,
    this.showTimestamp = true,
    this.showSenderName = true,
    this.roomParticipants = const [],
    this.onTap,
    this.onVisible,
  });

  @override
  Widget build(BuildContext context) {
    final chatTheme = context.chatTheme;
    final theme = Theme.of(context);

    final bubbleWidget = GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          left: isCurrentUser ? AppSpacing.avatarLg : AppSpacing.lg,
          right: isCurrentUser ? AppSpacing.lg : AppSpacing.avatarLg,
          top: AppSpacing.xs,
          bottom: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showSenderName && !isCurrentUser && sender != null)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  bottom: AppSpacing.xs,
                ),
                child: Text(
                  sender!.displayName,
                  style: chatTheme.senderNameStyle,
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? chatTheme.sentMessageBubbleColor
                    : chatTheme.receivedMessageBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(chatTheme.messageBubbleRadius),
                  topRight: Radius.circular(chatTheme.messageBubbleRadius),
                  bottomLeft: Radius.circular(
                    isCurrentUser
                        ? chatTheme.messageBubbleRadius
                        : AppSpacing.radiusXs,
                  ),
                  bottomRight: Radius.circular(
                    isCurrentUser
                        ? AppSpacing.radiusXs
                        : chatTheme.messageBubbleRadius,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: chatTheme.messageBubblePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(context),
                  if (showTimestamp || isCurrentUser) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _buildMessageFooter(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap with visibility detector for read receipts
    if (!isCurrentUser && onVisible != null) {
      return MessageVisibilityDetector(
        messageId: message.id,
        onVisible: onVisible,
        child: bubbleWidget,
      );
    }

    return bubbleWidget;
  }

  Widget _buildMessageContent(BuildContext context) {
    final chatTheme = context.chatTheme;
    final theme = Theme.of(context);

    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: chatTheme.messageTextStyle.copyWith(
            color: isCurrentUser
                ? chatTheme.onSentMessageBubbleColor
                : chatTheme.onReceivedMessageBubbleColor,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Image.network(
                message.content,
                width: 200,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      Icons.broken_image,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: AppSpacing.iconXxl,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attach_file,
              color: isCurrentUser
                  ? chatTheme.onSentMessageBubbleColor
                  : chatTheme.onReceivedMessageBubbleColor,
              size: AppSpacing.iconSm,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                message.content.split('/').last, // Show filename
                style: chatTheme.messageTextStyle.copyWith(
                  color: isCurrentUser
                      ? chatTheme.onSentMessageBubbleColor
                      : chatTheme.onReceivedMessageBubbleColor,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildMessageFooter(BuildContext context) {
    final chatTheme = context.chatTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTimestamp) ...[
          Text(
            _formatTimestamp(message.timestamp),
            style: chatTheme.messageTimestampStyle.copyWith(
              color: isCurrentUser
                  ? chatTheme.onSentMessageBubbleColor.withOpacity(0.7)
                  : chatTheme.messageTimestampColor,
            ),
          ),
          if (isCurrentUser) const SizedBox(width: AppSpacing.xs),
        ],
        if (isCurrentUser)
          MessageStatusIndicator(
            message: message,
            roomParticipants: roomParticipants,
            showDetailedStatus: roomParticipants.length > 2,
          ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return DateFormat('MMM d, HH:mm').format(timestamp);
    } else if (difference.inHours > 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
