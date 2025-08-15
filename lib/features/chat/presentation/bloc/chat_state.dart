import 'package:equatable/equatable.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/chat_room.dart';

/// Base class for all chat states
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// Initial state when chat BLoC is first created
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// Loading state for various chat operations
class ChatLoading extends ChatState {
  final String? operation;

  const ChatLoading({this.operation});

  @override
  List<Object?> get props => [operation];
}

/// State when chat rooms have been successfully loaded
class ChatRoomsLoaded extends ChatState {
  final List<ChatRoom> chatRooms;
  final bool isListening;

  const ChatRoomsLoaded({
    required this.chatRooms,
    this.isListening = false,
  });

  @override
  List<Object> get props => [chatRooms, isListening];

  /// Creates a copy with updated fields
  ChatRoomsLoaded copyWith({
    List<ChatRoom>? chatRooms,
    bool? isListening,
  }) {
    return ChatRoomsLoaded(
      chatRooms: chatRooms ?? this.chatRooms,
      isListening: isListening ?? this.isListening,
    );
  }
}

/// State when a chat room has been successfully joined
class ChatRoomJoined extends ChatState {
  final ChatRoom chatRoom;
  final List<Message> messages;
  final bool isListeningToMessages;

  const ChatRoomJoined({
    required this.chatRoom,
    required this.messages,
    this.isListeningToMessages = false,
  });

  @override
  List<Object> get props => [chatRoom, messages, isListeningToMessages];

  /// Creates a copy with updated fields
  ChatRoomJoined copyWith({
    ChatRoom? chatRoom,
    List<Message>? messages,
    bool? isListeningToMessages,
  }) {
    return ChatRoomJoined(
      chatRoom: chatRoom ?? this.chatRoom,
      messages: messages ?? this.messages,
      isListeningToMessages:
          isListeningToMessages ?? this.isListeningToMessages,
    );
  }
}

/// State when messages have been successfully loaded for a room
class MessagesLoaded extends ChatState {
  final String roomId;
  final List<Message> messages;
  final bool hasMoreMessages;
  final bool isListening;

  const MessagesLoaded({
    required this.roomId,
    required this.messages,
    this.hasMoreMessages = true,
    this.isListening = false,
  });

  @override
  List<Object> get props => [roomId, messages, hasMoreMessages, isListening];

  /// Creates a copy with updated fields
  MessagesLoaded copyWith({
    String? roomId,
    List<Message>? messages,
    bool? hasMoreMessages,
    bool? isListening,
  }) {
    return MessagesLoaded(
      roomId: roomId ?? this.roomId,
      messages: messages ?? this.messages,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isListening: isListening ?? this.isListening,
    );
  }

  /// Adds a new message to the list
  MessagesLoaded addMessage(Message message) {
    final updatedMessages = List<Message>.from(messages);

    // Check if message already exists (to prevent duplicates)
    final existingIndex = updatedMessages.indexWhere((m) => m.id == message.id);
    if (existingIndex != -1) {
      // Update existing message (for status updates)
      updatedMessages[existingIndex] = message;
    } else {
      // Add new message in chronological order
      updatedMessages.add(message);
      updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    return copyWith(messages: updatedMessages);
  }

  /// Updates a message in the list
  MessagesLoaded updateMessage(Message updatedMessage) {
    final updatedMessages = messages.map((message) {
      return message.id == updatedMessage.id ? updatedMessage : message;
    }).toList();

    return copyWith(messages: updatedMessages);
  }

  /// Marks messages as read by a user
  MessagesLoaded markMessagesAsRead(String userId, List<String> messageIds) {
    final now = DateTime.now();
    final updatedMessages = messages.map((message) {
      if (messageIds.contains(message.id) && !message.isReadBy(userId)) {
        return message.markAsReadBy(userId, now);
      }
      return message;
    }).toList();

    return copyWith(messages: updatedMessages);
  }
}

/// State when a message has been successfully sent
class MessageSent extends ChatState {
  final Message message;

  const MessageSent({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}

/// State when a chat room has been successfully created
class ChatRoomCreated extends ChatState {
  final ChatRoom chatRoom;

  const ChatRoomCreated({
    required this.chatRoom,
  });

  @override
  List<Object> get props => [chatRoom];
}

/// State when messages have been marked as read
class MessagesMarkedAsRead extends ChatState {
  final String roomId;
  final List<String> messageIds;

  const MessagesMarkedAsRead({
    required this.roomId,
    required this.messageIds,
  });

  @override
  List<Object> get props => [roomId, messageIds];
}

/// Error state for chat operations
class ChatError extends ChatState {
  final String message;
  final String? operation;
  final ChatState? previousState;

  const ChatError({
    required this.message,
    this.operation,
    this.previousState,
  });

  @override
  List<Object?> get props => [message, operation, previousState];
}

/// Combined state that can hold both chat rooms and current room messages
class ChatCombinedState extends ChatState {
  final List<ChatRoom> chatRooms;
  final ChatRoom? currentRoom;
  final List<Message> currentMessages;
  final bool isListeningToChatRooms;
  final bool isListeningToMessages;

  const ChatCombinedState({
    required this.chatRooms,
    this.currentRoom,
    required this.currentMessages,
    this.isListeningToChatRooms = false,
    this.isListeningToMessages = false,
  });

  @override
  List<Object?> get props => [
        chatRooms,
        currentRoom,
        currentMessages,
        isListeningToChatRooms,
        isListeningToMessages,
      ];

  /// Creates a copy with updated fields
  ChatCombinedState copyWith({
    List<ChatRoom>? chatRooms,
    ChatRoom? currentRoom,
    List<Message>? currentMessages,
    bool? isListeningToChatRooms,
    bool? isListeningToMessages,
    bool clearCurrentRoom = false,
  }) {
    return ChatCombinedState(
      chatRooms: chatRooms ?? this.chatRooms,
      currentRoom: clearCurrentRoom ? null : (currentRoom ?? this.currentRoom),
      currentMessages: currentMessages ?? this.currentMessages,
      isListeningToChatRooms:
          isListeningToChatRooms ?? this.isListeningToChatRooms,
      isListeningToMessages:
          isListeningToMessages ?? this.isListeningToMessages,
    );
  }

  /// Adds a new message to current messages
  ChatCombinedState addMessage(Message message) {
    if (currentRoom?.id != message.roomId) return this;

    final updatedMessages = List<Message>.from(currentMessages);

    // Check if message already exists
    final existingIndex = updatedMessages.indexWhere((m) => m.id == message.id);
    if (existingIndex != -1) {
      updatedMessages[existingIndex] = message;
    } else {
      updatedMessages.add(message);
      updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    return copyWith(currentMessages: updatedMessages);
  }

  /// Updates chat rooms list
  ChatCombinedState updateChatRooms(List<ChatRoom> newChatRooms) {
    // Update current room if it exists in the new list
    ChatRoom? updatedCurrentRoom = currentRoom;
    if (currentRoom != null) {
      updatedCurrentRoom = newChatRooms.firstWhere(
        (room) => room.id == currentRoom!.id,
        orElse: () => currentRoom!,
      );
    }

    return copyWith(
      chatRooms: newChatRooms,
      currentRoom: updatedCurrentRoom,
    );
  }
}
