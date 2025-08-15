import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/message.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../../core/constants/app_colors.dart';
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
    final bubbleWidget = GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          left: isCurrentUser ? 64.0 : 16.0,
          right: isCurrentUser ? 16.0 : 64.0,
          top: 4.0,
          bottom: 4.0,
        ),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showSenderName && !isCurrentUser && sender != null)
              Padding(
                padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
                child: Text(
                  sender!.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? AppColors.sentMessage
                    : AppColors.receivedMessage,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16.0),
                  topRight: const Radius.circular(16.0),
                  bottomLeft: Radius.circular(isCurrentUser ? 16.0 : 4.0),
                  bottomRight: Radius.circular(isCurrentUser ? 4.0 : 16.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(context),
                  if (showTimestamp || isCurrentUser) ...[
                    const SizedBox(height: 4.0),
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
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isCurrentUser
                    ? AppColors.textOnPrimary
                    : AppColors.textPrimary,
              ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
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
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 48,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
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
                  ? AppColors.textOnPrimary
                  : AppColors.textPrimary,
              size: 20,
            ),
            const SizedBox(width: 8.0),
            Flexible(
              child: Text(
                message.content.split('/').last, // Show filename
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isCurrentUser
                          ? AppColors.textOnPrimary
                          : AppColors.textPrimary,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTimestamp) ...[
          Text(
            _formatTimestamp(message.timestamp),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isCurrentUser
                      ? AppColors.textOnPrimary.withValues(alpha: 0.7)
                      : AppColors.textSecondary,
                  fontSize: 11,
                ),
          ),
          if (isCurrentUser) const SizedBox(width: 4.0),
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
