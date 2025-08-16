import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_real_time_chat/features/chat/domain/entities/chat_room.dart';
import '../../../../core/constants/app_colors.dart';

import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_widgets.dart';
import '../../../../core/utils/error_handler.dart';

import '../../../../core/routing/routing.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat_room_card.dart';

/// Page that displays a list of available chat rooms with real-time updates
class ChatRoomsListPage extends StatefulWidget {
  const ChatRoomsListPage({super.key});

  @override
  State<ChatRoomsListPage> createState() => _ChatRoomsListPageState();
}

class _ChatRoomsListPageState extends State<ChatRoomsListPage> {
  late ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    // ChatBloc will be accessed via context.read<ChatBloc>() when needed
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!mounted) return;

    _chatBloc = context.read<ChatBloc>();

    // Load chat rooms and start listening for real-time updates
    _chatBloc.add(const LoadChatRooms());
    _chatBloc.add(const StartListeningToChatRooms());
  }

  @override
  void dispose() {
    // Stop listening to real-time updates
    _chatBloc.add(const StopListeningToChatRooms());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat Rooms'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToCreateRoom(context),
              tooltip: 'Create Room',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  _handleSignOut(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthUnauthenticated) {
                  NavigationService.navigateToLogin();
                }
              },
            ),
            BlocListener<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is ChatError) {
                  ErrorHandler.showErrorSnackBar(
                    context,
                    state.message,
                    onRetry: () => _chatBloc.add(const LoadChatRooms()),
                    showRetry: state.operation == 'load_chat_rooms',
                  );
                } else if (state is ChatRoomCreated) {
                  ErrorHandler.showSuccessSnackBar(
                    context,
                    'Chat room created successfully!',
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  _chatBloc.add(const LoadChatRooms());
                },
                child: _buildBody(context, state),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToCreateRoom(context),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: AppColors.textOnPrimary),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ChatState state) {
    if (state is ChatLoading && state.operation == 'Loading chat rooms') {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) => const ChatRoomSkeletonLoader(),
      );
    }

    if (state is ChatError && state.previousState == null) {
      return _buildErrorState(context, state);
    }

    // Extract chat rooms from different state types
    final chatRooms = _extractChatRooms(state);

    if (chatRooms.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chatRooms.length,
      itemBuilder: (context, index) {
        final room = chatRooms[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ChatRoomCard(
            chatRoom: room,
            onTap: () => _joinRoom(context, room.id),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No chat rooms available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first chat room to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHint,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateRoom(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Room'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ChatError state) {
    return ErrorDisplay(
      message: state.message,
      onRetry: () => _chatBloc.add(const LoadChatRooms()),
    );
  }

  List<dynamic> _extractChatRooms(ChatState state) {
    if (state is ChatCombinedState) {
      return state.chatRooms;
    } else if (state is ChatRoomsLoaded) {
      return state.chatRooms;
    }
    return [];
  }

  void _navigateToCreateRoom(BuildContext context) {
    NavigationService.navigateToCreateChatRoom();
  }

  void _joinRoom(BuildContext context, String roomId) {
    // Get room name from the room data
    final chatRooms = _extractChatRooms(context.read<ChatBloc>().state);
   final room = chatRooms.firstWhere(
  (room) => room.id == roomId,
  orElse: () => ChatRoom.empty(), // define an empty/fallback ChatRoom
);

    final roomName = room?.name ?? 'Chat Room';
    NavigationService.navigateToChatRoom(roomId, roomName);
  }

  void _handleSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(const SignOutRequested());
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
