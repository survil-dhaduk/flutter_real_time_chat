import 'package:flutter/material.dart';
import '../../domain/entities/message.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget that displays message status indicators with detailed information
class MessageStatusIndicator extends StatelessWidget {
  final Message message;
  final List<String> roomParticipants;
  final bool showDetailedStatus;

  const MessageStatusIndicator({
    super.key,
    required this.message,
    required this.roomParticipants,
    this.showDetailedStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showDetailedStatus) {
      return _buildDetailedStatus(context);
    } else {
      return _buildSimpleStatus();
    }
  }

  Widget _buildSimpleStatus() {
    IconData iconData;
    Color iconColor;

    switch (message.status) {
      case MessageStatus.sent:
        iconData = Icons.check;
        iconColor = AppColors.textOnPrimary.withValues(alpha: 0.7);
        break;
      case MessageStatus.delivered:
        iconData = Icons.done_all;
        iconColor = AppColors.textOnPrimary.withValues(alpha: 0.7);
        break;
      case MessageStatus.read:
        iconData = Icons.done_all;
        iconColor = AppColors.success;
        break;
    }

    return Icon(
      iconData,
      size: 16,
      color: iconColor,
    );
  }

  Widget _buildDetailedStatus(BuildContext context) {
    final readCount = message.readBy.length;
    final totalParticipants = roomParticipants.length - 1; // Exclude sender

    return GestureDetector(
      onTap: () => _showStatusDetails(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSimpleStatus(),
          if (totalParticipants > 1 && readCount > 0) ...[
            const SizedBox(width: 2),
            Text(
              '$readCount',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showStatusDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _MessageStatusDetails(
        message: message,
        roomParticipants: roomParticipants,
      ),
    );
  }
}

/// Widget that shows detailed message status information
class _MessageStatusDetails extends StatelessWidget {
  final Message message;
  final List<String> roomParticipants;

  const _MessageStatusDetails({
    required this.message,
    required this.roomParticipants,
  });

  @override
  Widget build(BuildContext context) {
    final readParticipants = <String>[];
    final unreadParticipants = <String>[];

    // Separate participants into read and unread
    for (final participantId in roomParticipants) {
      if (participantId != message.senderId) {
        if (message.readBy.containsKey(participantId)) {
          readParticipants.add(participantId);
        } else {
          unreadParticipants.add(participantId);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Message Status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),

          // Message info
          _buildStatusRow(
            icon: Icons.schedule,
            label: 'Sent',
            value: _formatTimestamp(message.timestamp),
            color: AppColors.textSecondary,
          ),

          if (message.status == MessageStatus.delivered ||
              message.status == MessageStatus.read) ...[
            const SizedBox(height: 8),
            _buildStatusRow(
              icon: Icons.done_all,
              label: 'Delivered',
              value: 'To all participants',
              color: AppColors.textSecondary,
            ),
          ],

          if (readParticipants.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Read by ${readParticipants.length} participant${readParticipants.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            ...readParticipants.map((participantId) {
              final readTime = message.readBy[participantId];
              return _buildParticipantRow(
                participantId: participantId,
                timestamp: readTime,
                isRead: true,
              );
            }),
          ],

          if (unreadParticipants.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Not read by ${unreadParticipants.length} participant${unreadParticipants.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            ...unreadParticipants.map((participantId) {
              return _buildParticipantRow(
                participantId: participantId,
                timestamp: null,
                isRead: false,
              );
            }),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(color: color),
        ),
      ],
    );
  }

  Widget _buildParticipantRow({
    required String participantId,
    required DateTime? timestamp,
    required bool isRead,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              participantId.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User $participantId', // TODO: Get actual user name
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isRead && timestamp != null)
                  Text(
                    'Read ${_formatTimestamp(timestamp)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            isRead ? Icons.done_all : Icons.schedule,
            size: 16,
            color: isRead ? AppColors.success : AppColors.textHint,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
