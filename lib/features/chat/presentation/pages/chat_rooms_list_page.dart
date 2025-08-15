import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/loading_indicator.dart';

import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat_room_card.dart';
import 'create_chat_room_page.dart';

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
          ],
        ),
        body: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is ChatError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state is ChatRoomCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat room created successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                _chatBloc.add(const LoadChatRooms());
              },
              child: _buildBody(context, state),
            );
          },
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
      return const Center(child: LoadingIndicator());
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.error,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.error,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _chatBloc.add(const LoadChatRooms());
            },
            child: const Text(AppStrings.tryAgain),
          ),
        ],
      ),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: _chatBloc,
          child: const CreateChatRoomPage(),
        ),
      ),
    );
  }

  void _joinRoom(BuildContext context, String roomId) {
    _chatBloc.add(JoinChatRoom(roomId: roomId));

    // Navigate to chat page (this will be implemented in task 15)
    // For now, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joining room: $roomId'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}
