import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/chat_theme.dart';
import '../../domain/entities/chat_room.dart';

/// Widget that displays a chat room in a card format with participant info
class ChatRoomCard extends StatelessWidget {
  final ChatRoom chatRoom;
  final VoidCallback onTap;

  const ChatRoomCard({
    super.key,
    required this.chatRoom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppSpacing.elevationLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.chatRoomItemPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              if (chatRoom.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildDescription(context),
              ],
              const SizedBox(height: AppSpacing.md),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final chatTheme = context.chatTheme;
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: AppSpacing.avatarMd,
          height: AppSpacing.avatarMd,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.avatarMd / 2),
          ),
          child: Icon(
            Icons.chat_bubble,
            color: theme.colorScheme.primary,
            size: AppSpacing.iconSm,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chatRoom.name,
                style: chatTheme.chatRoomTitleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatCreatedDate(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (chatRoom.hasRecentActivity)
          Container(
            width: AppSpacing.sm,
            height: AppSpacing.sm,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    final chatTheme = context.chatTheme;

    return Text(
      chatRoom.description,
      style: chatTheme.chatRoomSubtitleStyle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _buildParticipantInfo(context),
        const Spacer(),
        if (chatRoom.lastMessageTime != null) ...[
          _buildLastMessageTime(context),
          const SizedBox(width: AppSpacing.sm),
        ],
        Icon(
          Icons.arrow_forward_ios,
          size: AppSpacing.iconXs,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildParticipantInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.people_outline,
          size: AppSpacing.iconXs,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '${chatRoom.participantCount} ${chatRoom.participantCount == 1 ? 'participant' : 'participants'}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLastMessageTime(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: AppSpacing.iconXs,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          _formatLastMessageTime(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatCreatedDate() {
    final now = DateTime.now();
    final difference = now.difference(chatRoom.createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatLastMessageTime() {
    if (chatRoom.lastMessageTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(chatRoom.lastMessageTime!);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
