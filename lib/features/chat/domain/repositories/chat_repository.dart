import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_room.dart';
import '../entities/message.dart';

/// Repository interface for chat operations
abstract class ChatRepository {
  /// Gets all available chat rooms
  ///
  /// Returns [Right<List<ChatRoom>>] on successful retrieval
  /// Returns [Left<Failure>] on retrieval failure
  Future<Either<Failure, List<ChatRoom>>> getChatRooms();

  /// Stream of real-time chat room updates
  ///
  /// Emits updated list of chat rooms when changes occur
  Stream<List<ChatRoom>> get chatRoomsStream;

  /// Creates a new chat room
  ///
  /// Returns [Right<ChatRoom>] on successful creation
  /// Returns [Left<Failure>] on creation failure
  Future<Either<Failure, ChatRoom>> createChatRoom({
    required String name,
    required String description,
  });

  /// Joins an existing chat room
  ///
  /// Returns [Right<ChatRoom>] on successful join
  /// Returns [Left<Failure>] on join failure
  Future<Either<Failure, ChatRoom>> joinChatRoom({
    required String roomId,
  });

  /// Leaves a chat room
  ///
  /// Returns [Right<void>] on successful leave
  /// Returns [Left<Failure>] on leave failure
  Future<Either<Failure, void>> leaveChatRoom({
    required String roomId,
  });

  /// Gets messages for a specific chat room with pagination
  ///
  /// Returns [Right<List<Message>>] on successful retrieval
  /// Returns [Left<Failure>] on retrieval failure
  Future<Either<Failure, List<Message>>> getMessages({
    required String roomId,
    int? limit,
    String? lastMessageId,
  });

  /// Stream of real-time messages for a specific chat room
  ///
  /// Emits updated list of messages when new messages arrive
  Stream<List<Message>> getMessagesStream({
    required String roomId,
  });

  /// Sends a message to a chat room
  ///
  /// Returns [Right<Message>] on successful send
  /// Returns [Left<Failure>] on send failure
  Future<Either<Failure, Message>> sendMessage({
    required String roomId,
    required String content,
    required MessageType type,
  });

  /// Marks a message as read by the current user
  ///
  /// Returns [Right<void>] on successful update
  /// Returns [Left<Failure>] on update failure
  Future<Either<Failure, void>> markMessageAsRead({
    required String messageId,
    required String roomId,
  });

  /// Marks all messages in a room as read by the current user
  ///
  /// Returns [Right<void>] on successful update
  /// Returns [Left<Failure>] on update failure
  Future<Either<Failure, void>> markAllMessagesAsRead({
    required String roomId,
  });

  /// Updates a message's content (if allowed)
  ///
  /// Returns [Right<Message>] on successful update
  /// Returns [Left<Failure>] on update failure
  Future<Either<Failure, Message>> updateMessage({
    required String messageId,
    required String newContent,
  });

  /// Deletes a message (if allowed)
  ///
  /// Returns [Right<void>] on successful deletion
  /// Returns [Left<Failure>] on deletion failure
  Future<Either<Failure, void>> deleteMessage({
    required String messageId,
    required String roomId,
  });

  /// Gets the count of unread messages for a specific room
  ///
  /// Returns [Right<int>] on successful count retrieval
  /// Returns [Left<Failure>] on count failure
  Future<Either<Failure, int>> getUnreadMessageCount({
    required String roomId,
  });

  /// Gets the total count of unread messages across all rooms
  ///
  /// Returns [Right<int>] on successful count retrieval
  /// Returns [Left<Failure>] on count failure
  Future<Either<Failure, int>> getTotalUnreadMessageCount();

  /// Searches for messages in a specific room
  ///
  /// Returns [Right<List<Message>>] on successful search
  /// Returns [Left<Failure>] on search failure
  Future<Either<Failure, List<Message>>> searchMessages({
    required String roomId,
    required String query,
    int? limit,
  });

  /// Gets chat room details by ID
  ///
  /// Returns [Right<ChatRoom>] on successful retrieval
  /// Returns [Left<Failure>] on retrieval failure
  Future<Either<Failure, ChatRoom>> getChatRoomById({
    required String roomId,
  });

  /// Updates chat room information (if user has permission)
  ///
  /// Returns [Right<ChatRoom>] on successful update
  /// Returns [Left<Failure>] on update failure
  Future<Either<Failure, ChatRoom>> updateChatRoom({
    required String roomId,
    String? name,
    String? description,
  });

  /// Deletes a chat room (if user has permission)
  ///
  /// Returns [Right<void>] on successful deletion
  /// Returns [Left<Failure>] on deletion failure
  Future<Either<Failure, void>> deleteChatRoom({
    required String roomId,
  });
}
