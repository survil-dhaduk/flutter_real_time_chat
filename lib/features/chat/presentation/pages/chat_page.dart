import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../../auth/domain/entities/user.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/message_bubble.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_widgets.dart';
import '../../../../core/utils/error_handler.dart';

/// Chat page that displays messages and allows sending new messages
class ChatPage extends StatefulWidget {
  final String roomId;
  final String roomName;

  const ChatPage({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;

  User? _currentUser;
  List<Message> _messages = [];
  ChatRoom? _chatRoom;

  @override
  void initState() {
    super.initState();
    _initializePage();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Load more messages when scrolling near the top
      if (_scrollController.position.pixels <= 100 &&
          !_isLoadingMore &&
          _hasMoreMessages) {
        _loadMoreMessages();
      }
    });
  }

  void _initializePage() {
    // Get current user from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _currentUser = authState.user;
    }

    // Join the chat room and start listening to messages
    context.read<ChatBloc>().add(JoinChatRoom(roomId: widget.roomId));
    context
        .read<ChatBloc>()
        .add(StartListeningToMessages(roomId: widget.roomId));

    // Mark all messages as read when entering the room
    context.read<ChatBloc>().add(MarkAllMessagesAsRead(roomId: widget.roomId));
  }

  @override
  void dispose() {
    // Stop listening to messages when leaving the page
    context
        .read<ChatBloc>()
        .add(StopListeningToMessages(roomId: widget.roomId));
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _loadMoreMessages() {
    if (_isLoadingMore || !_hasMoreMessages) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Get the oldest message ID for pagination
    final lastMessageId = _messages.isNotEmpty ? _messages.first.id : null;

    context.read<ChatBloc>().add(LoadMessages(
          roomId: widget.roomId,
          limit: 20,
          lastMessageId: lastMessageId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.roomName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${_chatRoom?.participants.length ?? 0} participants',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            _showRoomOptions(context);
          },
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatError) {
          ErrorHandler.showErrorSnackBar(
            context,
            state.message,
            onRetry:
                state.operation == 'send_message' ? () => _sendMessage() : null,
            showRetry: state.operation == 'send_message',
          );
        } else if (state is MessageSent) {
          _messageController.clear();
          _scrollToBottom();
        } else if (state is ChatCombinedState) {
          if (state.currentMessages.isNotEmpty) {
            _messages = state.currentMessages;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
          // Update chat room if available
          if (state.currentRoom != null) {
            _chatRoom = state.currentRoom;
          }
        } else if (state is MessagesLoaded) {
          setState(() {
            _hasMoreMessages = state.hasMoreMessages ?? true;
            _isLoadingMore = false;
          });

          _messages = state.messages;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        } else if (state is ChatRoomJoined) {
          _chatRoom = state.chatRoom;
        }
      },
      builder: (context, state) {
        if (state is ChatLoading && _messages.isEmpty) {
          return ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) => MessageSkeletonLoader(
              isOwnMessage: index % 2 == 0,
            ),
          );
        }

        if (_messages.isEmpty) {
          return _buildEmptyState();
        }

        return _buildMessagesListView();
      },
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateDisplay(
      title: 'No messages yet',
      subtitle: 'Start the conversation by sending a message',
      icon: Icons.chat_bubble_outline,
    );
  }

  Widget _buildMessagesListView() {
    // Add 1 to item count for loading indicator at the top
    final itemCount = _messages.length + (_isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Show loading indicator at the top when loading more messages
        if (index == 0 && _isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        // Adjust index for messages when loading indicator is present
        final messageIndex = _isLoadingMore ? index - 1 : index;
        final message = _messages[messageIndex];
        final isCurrentUser = message.senderId == _currentUser?.id;
        final showTimestamp = _shouldShowTimestamp(messageIndex);
        final showSenderName = _shouldShowSenderName(messageIndex);

        return MessageBubble(
          message: message,
          sender: null, // TODO: Get sender info from user repository
          isCurrentUser: isCurrentUser,
          showTimestamp: showTimestamp,
          showSenderName: showSenderName,
          roomParticipants: _chatRoom?.participants ?? [],
          onTap: () {
            if (!isCurrentUser && message.status != MessageStatus.read) {
              context.read<ChatBloc>().add(
                    MarkMessageAsRead(
                      messageId: message.id,
                      roomId: widget.roomId,
                    ),
                  );
            }
          },
          onVisible: !isCurrentUser && message.status != MessageStatus.read
              ? () {
                  context.read<ChatBloc>().add(
                        MessageBecameVisible(
                          messageId: message.id,
                          roomId: widget.roomId,
                        ),
                      );
                }
              : null,
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: AppColors.textHint.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12.0,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _showAttachmentOptions,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8.0),
            FloatingActionButton(
              onPressed: _sendMessage,
              mini: true,
              backgroundColor: AppColors.primary,
              child: const Icon(
                Icons.send,
                color: AppColors.textOnPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowTimestamp(int index) {
    if (index == 0) return true;

    final currentMessage = _messages[index];
    final previousMessage = _messages[index - 1];

    // Show timestamp if messages are more than 5 minutes apart
    final timeDifference =
        currentMessage.timestamp.difference(previousMessage.timestamp);
    return timeDifference.inMinutes >= 5;
  }

  bool _shouldShowSenderName(int index) {
    if (index == 0) return true;

    final currentMessage = _messages[index];
    final previousMessage = _messages[index - 1];

    // Show sender name if different sender or if timestamp is shown
    return currentMessage.senderId != previousMessage.senderId ||
        _shouldShowTimestamp(index);
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    context.read<ChatBloc>().add(
          SendMessage(
            roomId: widget.roomId,
            content: content,
            type: MessageType.text,
          ),
        );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                _attachPhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('File'),
              onTap: () {
                Navigator.pop(context);
                _attachFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _attachPhoto() {
    // TODO: Implement photo attachment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo attachment coming soon!'),
      ),
    );
  }

  void _attachFile() {
    // TODO: Implement file attachment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File attachment coming soon!'),
      ),
    );
  }

  void _showRoomOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Room Info'),
              onTap: () {
                Navigator.pop(context);
                _showRoomInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Participants'),
              onTap: () {
                Navigator.pop(context);
                _showParticipants();
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Leave Room'),
              onTap: () {
                Navigator.pop(context);
                _leaveRoom();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRoomInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.roomName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${_chatRoom?.description ?? 'No description'}'),
            const SizedBox(height: 8),
            Text(
                'Created: ${_chatRoom?.createdAt.toString().split('.')[0] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Participants: ${_chatRoom?.participants.length ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showParticipants() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Participants'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _chatRoom?.participants.length ?? 0,
            itemBuilder: (context, index) {
              final participantId = _chatRoom?.participants[index] ?? '';
              return ListTile(
                leading: CircleAvatar(
                  child: Text(participantId.substring(0, 1).toUpperCase()),
                ),
                title:
                    Text('User $participantId'), // TODO: Get actual user name
                trailing: participantId == _currentUser?.id
                    ? const Text('You')
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _leaveRoom() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Room'),
        content: const Text('Are you sure you want to leave this room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to room list
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}
