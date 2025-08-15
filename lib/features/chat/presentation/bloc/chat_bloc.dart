import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_chat_rooms.dart';
import '../../domain/usecases/create_chat_room.dart';
import '../../domain/usecases/join_chat_room.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/mark_message_as_read.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/chat_room.dart';
import 'chat_event.dart';
import 'chat_state.dart';

/// BLoC for managing chat functionality with real-time updates
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetChatRoomsUseCase _getChatRoomsUseCase;
  final CreateChatRoomUseCase _createChatRoomUseCase;
  final JoinChatRoomUseCase _joinChatRoomUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final GetMessagesUseCase _getMessagesUseCase;
  final MarkMessageAsReadUseCase _markMessageAsReadUseCase;

  // Stream subscriptions for real-time updates
  StreamSubscription<List<ChatRoom>>? _chatRoomsSubscription;
  StreamSubscription<List<Message>>? _messagesSubscription;

  // Current room being viewed for message listening
  String? _currentRoomId;

  ChatBloc({
    required GetChatRoomsUseCase getChatRoomsUseCase,
    required CreateChatRoomUseCase createChatRoomUseCase,
    required JoinChatRoomUseCase joinChatRoomUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required GetMessagesUseCase getMessagesUseCase,
    required MarkMessageAsReadUseCase markMessageAsReadUseCase,
  })  : _getChatRoomsUseCase = getChatRoomsUseCase,
        _createChatRoomUseCase = createChatRoomUseCase,
        _joinChatRoomUseCase = joinChatRoomUseCase,
        _sendMessageUseCase = sendMessageUseCase,
        _getMessagesUseCase = getMessagesUseCase,
        _markMessageAsReadUseCase = markMessageAsReadUseCase,
        super(const ChatInitial()) {
    // Register event handlers
    on<LoadChatRooms>(_onLoadChatRooms);
    on<CreateChatRoom>(_onCreateChatRoom);
    on<JoinChatRoom>(_onJoinChatRoom);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
    on<ChatRoomsUpdated>(_onChatRoomsUpdated);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<MarkAllMessagesAsRead>(_onMarkAllMessagesAsRead);
    on<StartListeningToMessages>(_onStartListeningToMessages);
    on<StopListeningToMessages>(_onStopListeningToMessages);
    on<StartListeningToChatRooms>(_onStartListeningToChatRooms);
    on<StopListeningToChatRooms>(_onStopListeningToChatRooms);
    on<MessageBecameVisible>(_onMessageBecameVisible);
    on<MessageStatusUpdated>(_onMessageStatusUpdated);
  }

  /// Handles loading chat rooms
  Future<void> _onLoadChatRooms(
    LoadChatRooms event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading(operation: 'Loading chat rooms'));

    final result = await _getChatRoomsUseCase();

    result.fold(
      (failure) => emit(ChatError(
        message: failure.message,
        operation: 'load_chat_rooms',
        previousState: state,
      )),
      (chatRooms) {
        if (state is ChatCombinedState) {
          final currentState = state as ChatCombinedState;
          emit(currentState.updateChatRooms(chatRooms));
        } else {
          emit(ChatCombinedState(
            chatRooms: chatRooms,
            currentMessages: const [],
          ));
        }
      },
    );
  }

  /// Handles creating a new chat room
  Future<void> _onCreateChatRoom(
    CreateChatRoom event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading(operation: 'Creating chat room'));

    final params = CreateChatRoomParams(
      name: event.name,
      description: event.description,
    );

    final result = await _createChatRoomUseCase(params);

    result.fold(
      (failure) => emit(ChatError(
        message: failure.message,
        operation: 'create_chat_room',
        previousState: state,
      )),
      (chatRoom) {
        emit(ChatRoomCreated(chatRoom: chatRoom));
        // Reload chat rooms to include the new one
        add(const LoadChatRooms());
      },
    );
  }

  /// Handles joining a chat room
  Future<void> _onJoinChatRoom(
    JoinChatRoom event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading(operation: 'Joining chat room'));

    final params = JoinChatRoomParams(roomId: event.roomId);
    final result = await _joinChatRoomUseCase(params);

    await result.fold(
      (failure) async => emit(ChatError(
        message: failure.message,
        operation: 'join_chat_room',
        previousState: state,
      )),
      (chatRoom) async {
        // Load initial messages for the room
        final messagesParams =
            GetMessagesParams(roomId: event.roomId, limit: 50);
        final messagesResult = await _getMessagesUseCase(messagesParams);

        await messagesResult.fold(
          (failure) async => emit(ChatError(
            message: failure.message,
            operation: 'load_initial_messages',
            previousState: state,
          )),
          (messages) async {
            if (emit.isDone) return;

            if (state is ChatCombinedState) {
              final currentState = state as ChatCombinedState;
              emit(currentState.copyWith(
                currentRoom: chatRoom,
                currentMessages: messages,
              ));
            } else {
              emit(ChatCombinedState(
                chatRooms: const [],
                currentRoom: chatRoom,
                currentMessages: messages,
              ));
            }

            // Note: Real-time listening should be started separately by the UI
            // add(StartListeningToMessages(roomId: event.roomId));
          },
        );
      },
    );
  }

  /// Handles loading messages for a room
  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    final previousState = state;
    emit(const ChatLoading(operation: 'Loading messages'));

    final params = GetMessagesParams(
      roomId: event.roomId,
      limit: event.limit,
      lastMessageId: event.lastMessageId,
    );

    final result = await _getMessagesUseCase(params);

    result.fold(
      (failure) => emit(ChatError(
        message: failure.message,
        operation: 'load_messages',
        previousState: previousState,
      )),
      (messages) {
        final hasMoreMessages =
            event.limit != null && messages.length == event.limit!;

        if (previousState is ChatCombinedState) {
          final currentState = previousState;
          final updatedMessages = event.lastMessageId != null
              ? [...currentState.currentMessages, ...messages]
              : messages;

          emit(currentState.copyWith(currentMessages: updatedMessages));
        } else {
          emit(MessagesLoaded(
            roomId: event.roomId,
            messages: messages,
            hasMoreMessages: hasMoreMessages,
          ));
        }
      },
    );
  }

  /// Handles sending a message
  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final params = SendMessageParams(
      roomId: event.roomId,
      content: event.content,
      type: event.type,
    );

    final result = await _sendMessageUseCase(params);

    result.fold(
      (failure) => emit(ChatError(
        message: failure.message,
        operation: 'send_message',
        previousState: state,
      )),
      (message) {
        emit(MessageSent(message: message));

        // The message will be received via real-time listener
        // so we don't need to manually add it to the state here
      },
    );
  }

  /// Handles receiving a message via real-time listener
  void _onMessageReceived(
    MessageReceived event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatCombinedState) {
      final currentState = state as ChatCombinedState;
      emit(currentState.addMessage(event.message));
    } else if (state is MessagesLoaded) {
      final currentState = state as MessagesLoaded;
      if (currentState.roomId == event.message.roomId) {
        emit(currentState.addMessage(event.message));
      }
    }
  }

  /// Handles chat rooms updates via real-time listener
  void _onChatRoomsUpdated(
    ChatRoomsUpdated event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatCombinedState) {
      final currentState = state as ChatCombinedState;
      emit(currentState.updateChatRooms(event.chatRooms));
    } else {
      emit(ChatCombinedState(
        chatRooms: event.chatRooms,
        currentMessages: const [],
      ));
    }
  }

  /// Handles marking a single message as read
  Future<void> _onMarkMessageAsRead(
    MarkMessageAsRead event,
    Emitter<ChatState> emit,
  ) async {
    final params = MarkMessageAsReadParams(
      messageId: event.messageId,
      roomId: event.roomId,
    );

    final result = await _markMessageAsReadUseCase(params);

    result.fold(
      (failure) => emit(ChatError(
        message: failure.message,
        operation: 'mark_message_as_read',
        previousState: state,
      )),
      (_) {
        emit(MessagesMarkedAsRead(
          roomId: event.roomId,
          messageIds: [event.messageId],
        ));
      },
    );
  }

  /// Handles marking all messages in a room as read
  Future<void> _onMarkAllMessagesAsRead(
    MarkAllMessagesAsRead event,
    Emitter<ChatState> emit,
  ) async {
    final params = MarkAllMessagesAsReadParams(roomId: event.roomId);
    final result =
        await _markMessageAsReadUseCase.markAllMessagesAsRead(params);

    result.fold(
      (failure) => emit(ChatError(
        message: failure.message,
        operation: 'mark_all_messages_as_read',
        previousState: state,
      )),
      (_) {
        // Get message IDs from current state
        List<String> messageIds = [];
        if (state is ChatCombinedState) {
          final currentState = state as ChatCombinedState;
          messageIds = currentState.currentMessages.map((m) => m.id).toList();
        } else if (state is MessagesLoaded) {
          final currentState = state as MessagesLoaded;
          messageIds = currentState.messages.map((m) => m.id).toList();
        }

        emit(MessagesMarkedAsRead(
          roomId: event.roomId,
          messageIds: messageIds,
        ));
      },
    );
  }

  /// Starts listening to real-time messages for a room
  void _onStartListeningToMessages(
    StartListeningToMessages event,
    Emitter<ChatState> emit,
  ) {
    // Stop previous subscription if exists
    _messagesSubscription?.cancel();
    _currentRoomId = event.roomId;

    // Update state to indicate listening
    if (state is ChatCombinedState) {
      final currentState = state as ChatCombinedState;
      emit(currentState.copyWith(isListeningToMessages: true));
    }

    // Start new subscription
    _messagesSubscription =
        _getMessagesUseCase.getMessagesStream(event.roomId).listen((messages) {
      // This will be handled by the repository implementation
      // The repository should emit individual MessageReceived events
    });
  }

  /// Stops listening to real-time messages
  void _onStopListeningToMessages(
    StopListeningToMessages event,
    Emitter<ChatState> emit,
  ) {
    if (_currentRoomId == event.roomId) {
      _messagesSubscription?.cancel();
      _messagesSubscription = null;
      _currentRoomId = null;

      // Update state to indicate not listening
      if (state is ChatCombinedState) {
        final currentState = state as ChatCombinedState;
        emit(currentState.copyWith(isListeningToMessages: false));
      } else if (state is MessagesLoaded) {
        final currentState = state as MessagesLoaded;
        emit(currentState.copyWith(isListening: false));
      }
    }
  }

  /// Starts listening to real-time chat rooms updates
  void _onStartListeningToChatRooms(
    StartListeningToChatRooms event,
    Emitter<ChatState> emit,
  ) {
    // Stop previous subscription if exists
    _chatRoomsSubscription?.cancel();

    // Start new subscription
    _chatRoomsSubscription =
        _getChatRoomsUseCase.getChatRoomsStream().listen((chatRooms) {
      add(ChatRoomsUpdated(chatRooms: chatRooms));
    });

    // Update state to indicate listening
    if (state is ChatCombinedState) {
      final currentState = state as ChatCombinedState;
      emit(currentState.copyWith(isListeningToChatRooms: true));
    }
  }

  /// Stops listening to real-time chat rooms updates
  void _onStopListeningToChatRooms(
    StopListeningToChatRooms event,
    Emitter<ChatState> emit,
  ) {
    _chatRoomsSubscription?.cancel();
    _chatRoomsSubscription = null;

    // Update state to indicate not listening
    if (state is ChatCombinedState) {
      final currentState = state as ChatCombinedState;
      emit(currentState.copyWith(isListeningToChatRooms: false));
    }
  }

  /// Handles when a message becomes visible to the user
  Future<void> _onMessageBecameVisible(
    MessageBecameVisible event,
    Emitter<ChatState> emit,
  ) async {
    // Only mark as read if the message is not from the current user
    // and hasn't been read yet
    bool shouldMarkAsRead = false;

    if (state is ChatCombinedState) {
      final currentState = state as ChatCombinedState;
      final message = currentState.currentMessages
          .where((m) => m.id == event.messageId)
          .firstOrNull;

      if (message != null && message.status != MessageStatus.read) {
        shouldMarkAsRead = true;
      }
    } else if (state is MessagesLoaded) {
      final currentState = state as MessagesLoaded;
      final message = currentState.messages
          .where((m) => m.id == event.messageId)
          .firstOrNull;

      if (message != null && message.status != MessageStatus.read) {
        shouldMarkAsRead = true;
      }
    }

    if (shouldMarkAsRead) {
      // Mark the message as read
      add(MarkMessageAsRead(
        messageId: event.messageId,
        roomId: event.roomId,
      ));
    }
  }

  /// Handles when a message status is updated via real-time listener
  void _onMessageStatusUpdated(
    MessageStatusUpdated event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatCombinedState) {
      final currentState = state as ChatCombinedState;
      final updatedMessages = currentState.currentMessages.map((message) {
        if (message.id == event.updatedMessage.id) {
          return event.updatedMessage;
        }
        return message;
      }).toList();

      emit(currentState.copyWith(currentMessages: updatedMessages));
    } else if (state is MessagesLoaded) {
      final currentState = state as MessagesLoaded;
      final updatedMessages = currentState.messages.map((message) {
        if (message.id == event.updatedMessage.id) {
          return event.updatedMessage;
        }
        return message;
      }).toList();

      emit(currentState.copyWith(messages: updatedMessages));
    }
  }

  @override
  Future<void> close() {
    // Cancel all subscriptions
    _chatRoomsSubscription?.cancel();
    _messagesSubscription?.cancel();
    return super.close();
  }
}
