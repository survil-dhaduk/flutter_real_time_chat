import 'package:equatable/equatable.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/chat_room.dart';

/// Base class for all chat events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all available chat rooms
class LoadChatRooms extends ChatEvent {
  const LoadChatRooms();
}

/// Event to create a new chat room
class CreateChatRoom extends ChatEvent {
  final String name;
  final String description;

  const CreateChatRoom({
    required this.name,
    required this.description,
  });

  @override
  List<Object> get props => [name, description];
}

/// Event to join an existing chat room
class JoinChatRoom extends ChatEvent {
  final String roomId;

  const JoinChatRoom({
    required this.roomId,
  });

  @override
  List<Object> get props => [roomId];
}

/// Event to load messages for a specific room
class LoadMessages extends ChatEvent {
  final String roomId;
  final int? limit;
  final String? lastMessageId;

  const LoadMessages({
    required this.roomId,
    this.limit,
    this.lastMessageId,
  });

  @override
  List<Object?> get props => [roomId, limit, lastMessageId];
}

/// Event to send a message to a room
class SendMessage extends ChatEvent {
  final String roomId;
  final String content;
  final MessageType type;

  const SendMessage({
    required this.roomId,
    required this.content,
    this.type = MessageType.text,
  });

  @override
  List<Object> get props => [roomId, content, type];
}

/// Event triggered when a new message is received via real-time listener
class MessageReceived extends ChatEvent {
  final Message message;

  const MessageReceived({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}

/// Event triggered when chat rooms are updated via real-time listener
class ChatRoomsUpdated extends ChatEvent {
  final List<ChatRoom> chatRooms;

  const ChatRoomsUpdated({
    required this.chatRooms,
  });

  @override
  List<Object> get props => [chatRooms];
}

/// Event to mark a message as read
class MarkMessageAsRead extends ChatEvent {
  final String messageId;
  final String roomId;

  const MarkMessageAsRead({
    required this.messageId,
    required this.roomId,
  });

  @override
  List<Object> get props => [messageId, roomId];
}

/// Event to mark all messages in a room as read
class MarkAllMessagesAsRead extends ChatEvent {
  final String roomId;

  const MarkAllMessagesAsRead({
    required this.roomId,
  });

  @override
  List<Object> get props => [roomId];
}

/// Event to start listening to real-time messages for a room
class StartListeningToMessages extends ChatEvent {
  final String roomId;

  const StartListeningToMessages({
    required this.roomId,
  });

  @override
  List<Object> get props => [roomId];
}

/// Event to stop listening to real-time messages for a room
class StopListeningToMessages extends ChatEvent {
  final String roomId;

  const StopListeningToMessages({
    required this.roomId,
  });

  @override
  List<Object> get props => [roomId];
}

/// Event to start listening to real-time chat rooms updates
class StartListeningToChatRooms extends ChatEvent {
  const StartListeningToChatRooms();
}

/// Event to stop listening to real-time chat rooms updates
class StopListeningToChatRooms extends ChatEvent {
  const StopListeningToChatRooms();
}

/// Event triggered when a message becomes visible to the user
class MessageBecameVisible extends ChatEvent {
  final String messageId;
  final String roomId;

  const MessageBecameVisible({
    required this.messageId,
    required this.roomId,
  });

  @override
  List<Object> get props => [messageId, roomId];
}

/// Event triggered when message status is updated via real-time listener
class MessageStatusUpdated extends ChatEvent {
  final Message updatedMessage;

  const MessageStatusUpdated({
    required this.updatedMessage,
  });

  @override
  List<Object> get props => [updatedMessage];
}
